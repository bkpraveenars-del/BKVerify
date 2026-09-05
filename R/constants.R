# ---------------------------------------------------------------------------
# Selection differential constants
# ---------------------------------------------------------------------------

#' Selection differential constants (K) used in genetic advance
#'
#' Genetic advance is computed as \eqn{GA = K \sigma_p h^2}, where \eqn{K} is
#' the standardised selection differential for the chosen selection intensity
#' (Lush 1949; Johnson, Robinson and Comstock 1955). Authors overwhelmingly
#' report the conventional rounded values below rather than exact normal-curve
#' quantiles, so those conventional values are what \code{BKVerify} tests
#' against.
#'
#' Because a paper that omits its selection intensity is indistinguishable from
#' one that used a different intensity, \code{k = "auto"} in
#' \code{\link{bk_check_variability}} tests the whole family and reports which
#' member reconciles the table. A trait reconciled by K = 1.76 when the text
#' claims 5 percent selection is a reporting problem, not an arithmetic one,
#' and the package labels it accordingly.
#'
#' @param intensity optional character; one of \code{"1%"}, \code{"5%"},
#'   \code{"10%"}, \code{"20%"}. If \code{NULL}, the full named vector is
#'   returned.
#'
#' @return A named numeric vector, or a single value if \code{intensity} is given.
#'
#' @references
#' Johnson, H. W., Robinson, H. F. and Comstock, R. E. (1955). Estimates of
#' genetic and environmental variability in soybeans. \emph{Agronomy Journal}
#' 47, 314-318.
#'
#' @examples
#' bk_k()
#' bk_k("5%")
#'
#' @export
bk_k <- function(intensity = NULL) {
  tbl <- c(`1%` = 2.64, `5%` = 2.06, `10%` = 1.76, `20%` = 1.40)
  if (is.null(intensity)) return(tbl)
  intensity <- as.character(intensity)
  if (!intensity %in% names(tbl)) {
    stop("Unknown selection intensity: ", intensity,
         ". Available: ", paste(names(tbl), collapse = ", "), call. = FALSE)
  }
  tbl[[intensity]]
}
