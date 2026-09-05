#' BKVerify: consistency auditing of reported plant breeding statistics
#'
#' @description
#' \code{BKVerify} recomputes every quantity that is algebraically derivable
#' from a published or draft breeding table and reports whether the printed
#' values can be reconciled.
#'
#' @section What the package deliberately does not do:
#' \code{BKVerify} restricts itself to relationships that hold irrespective of
#' which variance-component definition an author adopted. Broad-sense
#' heritability is not recomputed from mean squares, because
#' \eqn{\sigma^2_p} is defined in at least three defensible ways in the plant
#' breeding literature (\eqn{\sigma^2_g + \sigma^2_e},
#' \eqn{\sigma^2_g + \sigma^2_e/r}, and forms including a genotype by
#' environment term) and authors seldom state which they used. Flagging on that
#' basis would confuse methodological disagreement with arithmetic error. The
#' identities used here survive that ambiguity because the phenotypic variance
#' cancels.
#'
#' The package makes no claim about whether an analysis was appropriate, whether
#' the design was sound, or whether any error was deliberate. A verdict of
#' \code{"consistent"} means only that the printed numbers can be reconciled.
#'
#' @section Rounding:
#' Every comparison is an interval comparison. A value printed to two decimal
#' places asserts an interval of width 0.01, not a point. A quantity is declared
#' inconsistent only when no combination of values inside the reported rounding
#' intervals satisfies the identity. On simulated randomised complete block
#' trials this yields no false positives at one, two or three decimal places,
#' while detecting heritability misstatements of 1.0, 0.1 and 0.05 percentage
#' points respectively in at least 95 percent of tables.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{bk_check_variability}}}{GCV, PCV, heritability, genetic advance.}
#'   \item{\code{\link{bk_check_anova}}}{Degrees of freedom, sums of squares, mean squares, variance ratio.}
#'   \item{\code{\link{bk_check_precision}}}{Coefficient of variation, standard error of mean, critical difference.}
#'   \item{\code{\link{bk_check_corr}}}{Admissibility and definiteness of a correlation matrix.}
#'   \item{\code{\link{bk_audit}}}{Combine several checks into one report.}
#' }
#'
#' @references
#' Burton, G. W. and DeVane, E. H. (1953). Estimating heritability in tall
#' fescue from replicated clonal material. \emph{Agronomy Journal} 45, 478-481.
#'
#' Johnson, H. W., Robinson, H. F. and Comstock, R. E. (1955). Estimates of
#' genetic and environmental variability in soybeans. \emph{Agronomy Journal}
#' 47, 314-318.
#'
#' Nuijten, M. B. and Wicherts, J. M. (2024). Implementing statcheck during peer
#' review is related to a steep decline in statistical-reporting
#' inconsistencies. \emph{Advances in Methods and Practices in Psychological
#' Science} 7.
#'
#' @keywords internal
"_PACKAGE"
