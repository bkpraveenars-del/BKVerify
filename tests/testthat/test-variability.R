verdict_of <- function(res, trait, test) {
  res$verdict[res$label == trait & res$test == test]
}

test_that("a clean variability table raises nothing", {
  v <- bk_example("variability")
  clean <- v[!v$trait %in% c("Grains per spike", "Grain yield per plant (g)"), ]
  res <- bk_check_variability(clean)
  expect_false(any(res$verdict == "INCONSISTENT"))
})

test_that("a corrupted heritability is caught and localised", {
  res <- bk_check_variability(bk_example("variability"))
  # h2 was inflated by 4 points; GCV, PCV and GAM are untouched
  expect_equal(verdict_of(res, "Grains per spike", "h2_from_cv"),   "INCONSISTENT")
  expect_equal(verdict_of(res, "Grains per spike", "gam_identity"), "INCONSISTENT")
  # the test that does not involve h2 still passes -> the fault is the h2 column
  expect_equal(verdict_of(res, "Grains per spike", "gam_from_cv"),  "consistent")
})

test_that("a corrupted genetic advance is caught and localised", {
  res <- bk_check_variability(bk_example("variability"))
  expect_equal(verdict_of(res, "Grain yield per plant (g)", "h2_from_cv"),   "consistent")
  expect_equal(verdict_of(res, "Grain yield per plant (g)", "gam_identity"), "INCONSISTENT")
  expect_equal(verdict_of(res, "Grain yield per plant (g)", "gam_from_cv"),  "INCONSISTENT")
})

test_that("GCV exceeding PCV is impossible and is flagged", {
  bad <- data.frame(trait = "X", gcv = "15.00", pcv = "12.00",
                    h2 = "80.00", gam = "20.00", stringsAsFactors = FALSE)
  res <- bk_check_variability(bad)
  expect_equal(verdict_of(res, "X", "gcv_le_pcv"), "INCONSISTENT")
})

test_that("a non-default selection intensity is reconciled and reported", {
  # build a table honest under K = 1.76 (10 percent selection)
  gcv <- 14.01; pcv <- 15.20; h2 <- (gcv / pcv)^2
  gam <- 1.76 * h2 * pcv
  d <- data.frame(trait = "X", gcv = sprintf("%.2f", gcv), pcv = sprintf("%.2f", pcv),
                  h2 = sprintf("%.2f", 100 * h2), gam = sprintf("%.2f", gam),
                  stringsAsFactors = FALSE)
  res <- bk_check_variability(d, k = "auto")
  expect_equal(verdict_of(res, "X", "gam_identity"), "consistent")
  expect_true(grepl("1.76", res$k_used[res$test == "gam_identity"], fixed = TRUE))

  # forcing K = 2.06 must fail, but the note must name the K that works
  res2 <- bk_check_variability(d, k = 2.06)
  expect_equal(verdict_of(res2, "X", "gam_identity"), "INCONSISTENT")
  expect_true(grepl("1.76", res2$note[res2$test == "gam_identity"], fixed = TRUE))
})

test_that("heritability on the 0-1 scale is handled", {
  v <- bk_example("variability")[1:3, ]
  v$h2 <- sprintf("%.4f", as.numeric(v$h2) / 100)
  res <- bk_check_variability(v, h2_scale = "fraction")
  expect_false(any(res$verdict == "INCONSISTENT"))
})

test_that("missing columns degrade gracefully rather than erroring", {
  v <- bk_example("variability")[1:3, c("trait", "gcv", "pcv", "gam")]
  res <- bk_check_variability(v, h2 = NULL)
  expect_true("gam_from_cv" %in% res$test)
  expect_false("h2_from_cv" %in% res$test)
})

test_that("no false positives on simulated honest tables", {
  set.seed(2024)
  fails <- 0L
  for (i in 1:300) {
    t <- 24; r <- 3; mu <- runif(1, 20, 120)
    g <- rnorm(t, 0, runif(1, 2, 15)); b <- rnorm(r, 0, 2)
    e <- matrix(rnorm(t * r, 0, runif(1, 1, 8)), t, r)
    Y <- mu + g + rep(b, each = t) + e
    gm <- mean(Y)
    MSg <- r * sum((rowMeans(Y) - gm)^2) / (t - 1)
    SSb <- t * sum((colMeans(Y) - gm)^2)
    SSe <- sum((Y - gm)^2) - r * sum((rowMeans(Y) - gm)^2) - SSb
    MSe <- SSe / ((t - 1) * (r - 1))
    vg <- (MSg - MSe) / r
    if (vg <= 0) next
    vp <- vg + MSe / r
    d <- data.frame(
      trait = "sim",
      gcv = sprintf("%.2f", 100 * sqrt(vg) / gm),
      pcv = sprintf("%.2f", 100 * sqrt(vp) / gm),
      h2  = sprintf("%.2f", 100 * vg / vp),
      gam = sprintf("%.2f", 100 * 2.06 * sqrt(vp) * (vg / vp) / gm),
      stringsAsFactors = FALSE)
    res <- bk_check_variability(d, k = 2.06)
    fails <- fails + sum(res$verdict == "INCONSISTENT")
  }
  expect_equal(fails, 0L)
})
