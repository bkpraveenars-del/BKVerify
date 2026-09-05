# Tests run only when testthat is available. CRAN's check machines have
# testthat installed, so the suite always runs there; locally, a library
# without testthat skips the tests instead of failing R CMD check.
if (requireNamespace("testthat", quietly = TRUE)) {
  library(testthat)
  library(BKVerify)
  test_check("BKVerify")
}
