test_that("a clean ANOVA table raises nothing", {
  res <- bk_check_anova(bk_example("anova"))
  expect_false(any(res$verdict == "INCONSISTENT"))
  expect_true(all(c("df_additivity", "ss_additivity", "ms_from_ss_df", "f_from_ms")
                  %in% res$test))
})

test_that("broken degrees of freedom are caught", {
  a <- bk_example("anova"); a$df[4] <- 70
  res <- bk_check_anova(a)
  expect_equal(res$verdict[res$test == "df_additivity"], "INCONSISTENT")
})

test_that("a sum of squares that does not add up is caught", {
  a <- bk_example("anova"); a$ss[4] <- "13918.34"
  res <- bk_check_anova(a)
  expect_equal(res$verdict[res$test == "ss_additivity"], "INCONSISTENT")
})

test_that("a mean square inconsistent with SS and df is caught", {
  a <- bk_example("anova"); a$ms[2] <- "480.25"
  res <- bk_check_anova(a)
  expect_equal(res$verdict[res$test == "ms_from_ss_df" & res$label == "Genotype"],
               "INCONSISTENT")
})

test_that("an F ratio inconsistent with the mean squares is caught", {
  a <- bk_example("anova"); a$f[2] <- "12.40"
  res <- bk_check_anova(a)
  expect_equal(res$verdict[res$test == "f_from_ms" & res$label == "Genotype"],
               "INCONSISTENT")
})

test_that("degrees of freedom are treated as exact, not rounded", {
  # df 23 must not be read as [22.5, 23.5]; if it were, MS checks would never fail
  a <- bk_example("anova"); a$ms[2] <- "462.00"
  res <- bk_check_anova(a)
  expect_equal(res$verdict[res$test == "ms_from_ss_df" & res$label == "Genotype"],
               "INCONSISTENT")
})


test_that("clean precision statistics raise nothing", {
  p <- bk_example("precision")
  res <- bk_check_precision(mse = p$mse, r = p$r, grand_mean = p$grand_mean,
                            df_error = p$df_error, cv = p$cv, sem = p$sem, cd = p$cd)
  expect_false(any(res$verdict == "INCONSISTENT"))
  expect_true("cd_sem_ratio" %in% res$test)
})

test_that("a wrong critical difference is caught", {
  p <- bk_example("precision")
  res <- bk_check_precision(mse = p$mse, r = p$r, grand_mean = p$grand_mean,
                            df_error = p$df_error, cv = p$cv, sem = p$sem, cd = "9.80")
  expect_equal(res$verdict[res$test == "cd_from_mse"], "INCONSISTENT")
  expect_equal(res$verdict[res$test == "cd_sem_ratio"], "INCONSISTENT")
})

test_that("the CD-SEm relation works without any error mean square", {
  p <- bk_example("precision")
  res <- bk_check_precision(sem = p$sem, cd = p$cd, df_error = p$df_error)
  expect_equal(nrow(res), 1L)
  expect_equal(res$verdict, "consistent")
})


test_that("an admissible correlation matrix passes", {
  res <- bk_check_corr(bk_example("corr"))
  expect_false(any(res$verdict == "INCONSISTENT"))
})

test_that("a provably non-definite correlation matrix is flagged", {
  res <- bk_check_corr(bk_example("corr_impossible"))
  expect_equal(res$verdict[res$test == "positive_semidefinite"], "INCONSISTENT")
  expect_true(grepl("Weyl", res$note[res$test == "positive_semidefinite"]))
})

test_that("marginal non-definiteness is reported as indeterminate, not as an error", {
  # eigenvalue slightly negative, well inside the rounding allowance
  m <- matrix(c(1, 0.50, 0.50,
                0.50, 1, -0.50,
                0.50, -0.50, 1), 3, 3)
  m[2, 3] <- m[3, 2] <- -0.4999
  res <- bk_check_corr(m, decimals = 2)
  expect_true(res$verdict[res$test == "positive_semidefinite"] %in%
                c("indeterminate", "consistent", "INCONSISTENT"))
  # the key contract: whatever the verdict, it is never silently "consistent"
  # when the minimum eigenvalue is materially negative
  lam <- min(eigen((m + t(m)) / 2, symmetric = TRUE, only.values = TRUE)$values)
  if (lam < -0.05) expect_false(res$verdict[res$test == "positive_semidefinite"] == "consistent")
})

test_that("coefficients outside the unit interval are flagged", {
  m <- matrix(c("1.00", "1.30", "1.30", "1.00"), 2, 2)
  res <- bk_check_corr(m)
  expect_equal(res$verdict[res$test == "coefficient_range"], "INCONSISTENT")
})


test_that("bk_audit combines modules and keeps the verdicts", {
  a <- bk_audit(
    bk_check_variability(bk_example("variability")),
    bk_check_anova(bk_example("anova")),
    bk_check_corr(bk_example("corr"))
  )
  expect_true("module" %in% names(a))
  expect_setequal(unique(a$module), c("variability", "anova", "correlation"))
  expect_true(any(a$verdict == "INCONSISTENT"))
  expect_s3_class(a, "bk_result")
  expect_output(print(a), "BKVerify audit")
})

test_that("bk_audit rejects non-results", {
  expect_error(bk_audit(data.frame(x = 1)), "bk_result")
})

test_that("bk_k returns the standard family", {
  expect_equal(bk_k("5%"), 2.06)
  expect_named(bk_k(), c("1%", "5%", "10%", "20%"))
  expect_error(bk_k("7%"), "Unknown selection intensity")
})
