test_that("decimal places are read from the printed representation", {
  expect_equal(BKVerify:::.bk_decimals(c("6.15", "6.1", "6")), c(2L, 1L, 0L))
  # character preserves trailing zeros; numeric cannot
  expect_equal(BKVerify:::.bk_decimals("88.10"), 2L)
  expect_equal(BKVerify:::.bk_decimals(88.10), 1L)
})

test_that("rounding intervals have the right width and centre", {
  iv <- bk_interval("6.15")
  expect_equal(iv[, "lo"], 6.145, tolerance = 1e-12, ignore_attr = TRUE)
  expect_equal(iv[, "hi"], 6.155, tolerance = 1e-12, ignore_attr = TRUE)
  expect_equal(diff(as.numeric(bk_interval("1.234"))), 0.001, tolerance = 1e-12)
  expect_equal(diff(as.numeric(bk_interval("1.2"))),   0.1,   tolerance = 1e-12)
})

test_that("decimals argument overrides inference", {
  iv <- bk_interval(88.1, decimals = 2)
  expect_equal(as.numeric(iv), c(88.095, 88.105), tolerance = 1e-12)
})

test_that("interval arithmetic brackets the true value", {
  set.seed(1)
  for (i in 1:200) {
    a <- runif(1, 1, 50); b <- runif(1, 1, 50)
    ia <- bk_interval(sprintf("%.2f", a)); ib <- bk_interval(sprintf("%.2f", b))
    p <- BKVerify:::.iv_mul(ia, ib)
    q <- BKVerify:::.iv_div(ia, ib)
    expect_true(p[, 1] <= a * b && a * b <= p[, 2])
    expect_true(q[, 1] <= a / b && a / b <= q[, 2])
  }
})

test_that("division by an interval spanning zero returns the whole line", {
  q <- BKVerify:::.iv_div(bk_interval("1.00"), cbind(lo = -0.01, hi = 0.01))
  expect_equal(as.numeric(q), c(-Inf, Inf))
})
