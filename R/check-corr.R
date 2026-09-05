# ---------------------------------------------------------------------------
# Admissibility of a reported correlation matrix
#
# A correlation matrix must be positive semi-definite. Published matrices
# frequently are not, because coefficients are computed pairwise on different
# subsets of observations, transcribed by hand, or assembled from several
# sources. This is a definition-free error: no modelling choice can make a
# non-PSD correlation matrix legitimate.
#
# Rounding is handled rigorously rather than heuristically. For a symmetric
# perturbation E with zero diagonal and |E_ij| <= delta, Weyl's inequality gives
#
#     lambda_min(R + E)  <=  lambda_min(R) + ||E||_2  <=  lambda_min(R) + delta * sqrt(n^2 - n)
#
# so if lambda_min(R) + delta * sqrt(n^2 - n) < 0, then NO matrix inside the
# reported rounding box is positive semi-definite. That is a proof, not a
# heuristic. When lambda_min(R) is negative but the bound does not clear, the
# verdict is "indeterminate" and the package says so rather than guessing.
# ---------------------------------------------------------------------------

#' Audit a reported correlation matrix
#'
#' Checks symmetry, unit diagonal, coefficient range and positive
#' semi-definiteness. Non-definiteness is reported as \code{"INCONSISTENT"} only
#' when it is provable given the reporting precision; otherwise the verdict is
#' \code{"indeterminate"}.
#'
#' @param R a square numeric or character matrix of correlation coefficients.
#'   Character input preserves reporting precision and is preferred.
#' @param decimals optional integer overriding the inferred reporting precision.
#' @param symmetry_tol tolerance for the symmetry check. Default \code{1e-8}.
#'
#' @return An object of class \code{bk_result}.
#'
#' @examples
#' bk_check_corr(bk_example("corr"))
#'
#' @export
bk_check_corr <- function(R, decimals = NULL, symmetry_tol = 1e-8) {

  if (is.data.frame(R)) R <- as.matrix(R)
  if (!is.matrix(R) || nrow(R) != ncol(R)) {
    stop("`R` must be a square matrix.", call. = FALSE)
  }
  n <- nrow(R)
  nms <- colnames(R)
  if (is.null(nms)) nms <- paste0("V", seq_len(n))

  d <- if (is.null(decimals)) {
    off <- R[upper.tri(R)]
    dd <- .bk_decimals(off)
    max(dd[!is.na(dd)], 0L)
  } else as.integer(decimals)
  delta <- 0.5 * 10^(-d)

  Rn <- matrix(suppressWarnings(as.numeric(R)), n, n, dimnames = list(nms, nms))
  out <- list()

  mk <- function(test, identity, verdict, note, rl = NA_real_, rh = NA_real_,
                 il = NA_real_, ih = NA_real_, label = "MATRIX") {
    data.frame(label = label, test = test, identity = identity,
               reported_lo = rl, reported_hi = rh,
               implied_lo = il, implied_hi = ih,
               k_used = NA_character_, verdict = verdict, note = note,
               stringsAsFactors = FALSE, row.names = NULL)
  }

  ## ---- unit diagonal ------------------------------------------------------
  dg <- diag(Rn)
  bad_dg <- which(!is.na(dg) & abs(dg - 1) > delta)
  out[[length(out) + 1L]] <- mk(
    "unit_diagonal", "diag(R) = 1",
    if (length(bad_dg)) "INCONSISTENT" else "consistent",
    if (length(bad_dg)) paste0("non-unit diagonal at: ",
                               paste(nms[bad_dg], collapse = ", ")) else NA_character_
  )

  ## ---- symmetry -----------------------------------------------------------
  asym <- max(abs(Rn - t(Rn)), na.rm = TRUE)
  out[[length(out) + 1L]] <- mk(
    "symmetry", "R = t(R)",
    if (is.finite(asym) && asym > max(symmetry_tol, 2 * delta)) "INCONSISTENT" else "consistent",
    if (is.finite(asym) && asym > max(symmetry_tol, 2 * delta))
      sprintf("maximum asymmetry %.4g exceeds rounding allowance", asym) else NA_character_
  )

  ## ---- coefficient range --------------------------------------------------
  off <- Rn[upper.tri(Rn)]
  bad_r <- sum(!is.na(off) & abs(off) - delta > 1)
  out[[length(out) + 1L]] <- mk(
    "coefficient_range", "|r| <= 1",
    if (bad_r > 0) "INCONSISTENT" else "consistent",
    if (bad_r > 0) sprintf("%d coefficient(s) exceed unity beyond rounding", bad_r) else NA_character_
  )

  ## ---- positive semi-definiteness ----------------------------------------
  Rs <- (Rn + t(Rn)) / 2
  if (anyNA(Rs)) {
    out[[length(out) + 1L]] <- mk("positive_semidefinite",
      "min eigenvalue(R) >= 0", "not_applicable",
      "matrix contains missing values")
  } else {
    lam <- min(eigen(Rs, symmetric = TRUE, only.values = TRUE)$values)
    bound <- delta * sqrt(n^2 - n)
    verdict <- if (lam >= 0) "consistent" else if (lam + bound < 0) "INCONSISTENT" else "indeterminate"
    note <- switch(verdict,
      consistent = NA_character_,
      INCONSISTENT = sprintf(
        "provably non-PSD: min eigenvalue %.4f, rounding cannot exceed %.4f (Weyl bound at %d dp)",
        lam, bound, d),
      indeterminate = sprintf(
        "min eigenvalue %.4f is negative but within the %.4f rounding allowance; not provable at %d dp",
        lam, bound, d))
    out[[length(out) + 1L]] <- mk("positive_semidefinite", "min eigenvalue(R) >= 0",
                                  verdict, note, il = lam, ih = lam + bound)
  }

  .as_bk_result(do.call(rbind, out), module = "correlation")
}
