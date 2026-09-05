# ---------------------------------------------------------------------------
# Precision statistics printed under every field-trial table
#
#   CV%   = 100 * sqrt(MSe) / grand mean
#   SEm   = sqrt(MSe / r)
#   CD    = t(1 - alpha/2, df_error) * sqrt(2 * MSe / r)
#   CD    = t * SEm * sqrt(2)        <- needs no MSe, no r, no mean
#
# The last relation is the useful one in practice, because a great many papers
# print CD and SEm but not the error mean square.
# ---------------------------------------------------------------------------

#' Audit precision statistics (CV, SEm, CD)
#'
#' Recomputes the coefficient of variation, standard error of the mean and
#' critical difference from the error mean square, and additionally checks the
#' \eqn{CD = t \times SEm \times \sqrt{2}} relation, which requires only the two
#' printed values and the error degrees of freedom.
#'
#' All arguments may be vectors of equal length, one element per trait.
#'
#' @param mse error mean square. May be \code{NULL} if only \code{cd},
#'   \code{sem} and \code{df_error} are available.
#' @param r number of replications.
#' @param grand_mean grand mean of the trait.
#' @param df_error error degrees of freedom (treated as exact).
#' @param cv,sem,cd the reported values to be tested. Any may be \code{NULL}.
#' @param alpha significance level used for the critical difference. Default
#'   \code{0.05}.
#' @param label optional character vector naming each trait.
#' @param decimals optional integer overriding inferred reporting precision.
#'
#' @return An object of class \code{bk_result}.
#'
#' @examples
#' bk_check_precision(mse = "10.03", r = 3, grand_mean = "45.16",
#'                    df_error = 38, cv = "7.01", sem = "1.83", cd = "5.24")
#'
#' @export
bk_check_precision <- function(mse = NULL, r = NULL, grand_mean = NULL,
                               df_error = NULL,
                               cv = NULL, sem = NULL, cd = NULL,
                               alpha = 0.05, label = NULL, decimals = NULL) {

  n <- max(vapply(list(mse, r, grand_mean, df_error, cv, sem, cd),
                  function(z) if (is.null(z)) 0L else length(z), integer(1)))
  if (n == 0L) stop("Nothing supplied.", call. = FALSE)
  if (is.null(label)) label <- if (n == 1L) "trait" else paste0("trait", seq_len(n))
  label <- rep_len(label, n)

  iv <- function(z) if (is.null(z)) NULL else bk_interval(rep_len(z, n), decimals)
  exact <- function(z) if (is.null(z)) NULL else {
    v <- rep_len(suppressWarnings(as.numeric(z)), n); cbind(lo = v, hi = v)
  }

  i_mse <- iv(mse); i_gm <- iv(grand_mean)
  i_r   <- exact(r); i_dfe <- exact(df_error)
  i_cv  <- iv(cv); i_sem <- iv(sem); i_cd <- iv(cd)

  out <- list()

  ## ---- CV% = 100 * sqrt(MSe) / grand mean --------------------------------
  if (!is.null(i_mse) && !is.null(i_gm) && !is.null(i_cv)) {
    implied <- .iv_scale(.iv_div(.iv_sqrt(i_mse), i_gm), 100)
    out[[length(out) + 1L]] <- .bk_rows(
      label, "cv_from_mse", "CV% = 100 * sqrt(MSe) / mean", i_cv, implied
    )
  }

  ## ---- SEm = sqrt(MSe / r) ------------------------------------------------
  if (!is.null(i_mse) && !is.null(i_r) && !is.null(i_sem)) {
    implied <- .iv_sqrt(.iv_div(i_mse, i_r))
    out[[length(out) + 1L]] <- .bk_rows(
      label, "sem_from_mse", "SEm = sqrt(MSe / r)", i_sem, implied
    )
  }

  ## ---- CD = t * sqrt(2 * MSe / r) ----------------------------------------
  if (!is.null(i_mse) && !is.null(i_r) && !is.null(i_dfe) && !is.null(i_cd)) {
    tcrit <- stats::qt(1 - alpha / 2, i_dfe[, 1])
    implied <- .iv_sqrt(.iv_scale(.iv_div(i_mse, i_r), 2))
    implied <- cbind(lo = implied[, 1] * tcrit, hi = implied[, 2] * tcrit)
    out[[length(out) + 1L]] <- .bk_rows(
      label, "cd_from_mse", "CD = t * sqrt(2 * MSe / r)", i_cd, implied,
      note = sprintf("alpha = %.3g", alpha)
    )
  }

  ## ---- CD = t * SEm * sqrt(2)  (no MSe required) -------------------------
  if (!is.null(i_sem) && !is.null(i_cd) && !is.null(i_dfe)) {
    tcrit <- stats::qt(1 - alpha / 2, i_dfe[, 1])
    implied <- .iv_scale(i_sem, sqrt(2))
    implied <- cbind(lo = implied[, 1] * tcrit, hi = implied[, 2] * tcrit)
    out[[length(out) + 1L]] <- .bk_rows(
      label, "cd_sem_ratio", "CD = t * SEm * sqrt(2)", i_cd, implied,
      note = "requires no error mean square"
    )
  }

  if (!length(out)) {
    stop("No testable combination. Supply either (mse, r, grand_mean) with a ",
         "reported statistic, or (sem, cd, df_error).", call. = FALSE)
  }
  .as_bk_result(do.call(rbind, out), module = "precision")
}
