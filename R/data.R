# ---------------------------------------------------------------------------
# Worked examples
#
# These tables were generated from simulated randomised complete block trials
# (24 genotypes, 3 replications) and then rounded to the precision typical of a
# published paper, so every identity holds exactly before rounding. Two rows of
# the variability table were then deliberately corrupted, which is what makes
# them useful for teaching: the pattern of which tests fail localises which
# printed number is wrong.
# ---------------------------------------------------------------------------

#' Example tables for auditing
#'
#' Returns small worked examples in the shape the \code{bk_check_*} functions
#' expect. Values are stored as character strings so that trailing zeros, and
#' therefore the true reporting precision, are preserved.
#'
#' The \code{"variability"} table carries two planted errors:
#' \describe{
#'   \item{Grains per spike}{heritability inflated by 4 points. The
#'     \code{h2_from_cv} and \code{gam_identity} tests fail while
#'     \code{gam_from_cv} passes, which localises the fault to the reported
#'     heritability rather than to GCV, PCV or genetic advance.}
#'   \item{Grain yield per plant}{genetic advance inflated by 15 percent. Here
#'     \code{h2_from_cv} passes and both genetic advance tests fail, localising
#'     the fault to the genetic advance column.}
#' }
#'
#' @param what one of \code{"variability"}, \code{"anova"}, \code{"precision"},
#'   \code{"corr"} or \code{"corr_impossible"}.
#'
#' @return A data frame, matrix or list, depending on \code{what}.
#'
#' @examples
#' bk_example("variability")
#' bk_check_variability(bk_example("variability"))
#'
#' @export
bk_example <- function(what = c("variability", "anova", "precision",
                                "corr", "corr_impossible")) {
  what <- match.arg(what)

  switch(what,

    variability = data.frame(
      trait = c("Days to flowering", "Plant height (cm)", "Tillers per plant",
                "Spike length (cm)", "Grains per spike", "1000-grain weight (g)",
                "Grain yield per plant (g)"),
      gcv = c("6.15", "14.98", "22.08", "6.56", "14.01", "11.42", "17.08"),
      pcv = c("6.43", "15.68", "23.60", "8.86", "15.20", "11.86", "20.10"),
      # 89.05 is the planted error (true value 85.05)
      h2  = c("91.48", "91.34", "87.58", "54.83", "89.05", "92.59", "72.20"),
      # 34.39 is the planted error (true value 29.90)
      gam = c("12.12", "29.50", "42.58", "10.01", "26.62", "22.63", "34.39"),
      stringsAsFactors = FALSE
    ),

    anova = data.frame(
      source = c("Replication", "Genotype", "Error", "Total"),
      df = c(2, 23, 46, 71),
      ss = c("168.57", "10585.66", "2164.11", "12918.34"),
      ms = c("84.28", "460.25", "47.05", NA),
      f  = c("1.79", "9.78", NA, NA),
      stringsAsFactors = FALSE
    ),

    precision = list(
      mse = "47.05", r = 3, grand_mean = "95.72", df_error = 46,
      cv = "7.17", sem = "3.96", cd = "11.27"
    ),

    corr = {
      m <- matrix(c(
        "1.00",  "0.13",  "0.08", "-0.14", "-0.12",
        "0.13",  "1.00",  "0.05", "-0.07",  "0.04",
        "0.08",  "0.05",  "1.00", "-0.07",  "0.00",
       "-0.14", "-0.07", "-0.07",  "1.00", "-0.07",
       "-0.12",  "0.04",  "0.00", "-0.07",  "1.00"), 5, 5, byrow = TRUE)
      dimnames(m) <- list(paste0("T", 1:5), paste0("T", 1:5))
      m
    },

    corr_impossible = {
      # T1 and T2 both strongly positive with T3, yet strongly negative with
      # each other: no data set can produce this.
      m <- matrix(c(
        "1.00",  "-0.90", "0.90",
       "-0.90",   "1.00", "0.90",
        "0.90",   "0.90", "1.00"), 3, 3, byrow = TRUE)
      dimnames(m) <- list(paste0("T", 1:3), paste0("T", 1:3))
      m
    }
  )
}
