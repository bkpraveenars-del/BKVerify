# ---------------------------------------------------------------------------
# Analysis of variance: five reported quantities, three exact constraints
#
#   df additivity :  sum(df_components)  = df_total
#   SS additivity :  sum(SS_components)  = SS_total
#   MS definition :  MS = SS / df                (every row)
#   F definition  :  F  = MS_source / MS_error   (every non-error row)
#
# None of these depend on any modelling choice. Degrees of freedom are treated
# as exact integers, never as rounded quantities.
# ---------------------------------------------------------------------------

#' Audit an analysis of variance table
#'
#' Checks the internal algebraic structure of a published ANOVA table:
#' additivity of degrees of freedom and sums of squares, the definition of mean
#' squares, and the definition of the variance ratio. All comparisons use
#' rounding-interval arithmetic, so a row is flagged only when no combination of
#' values inside the reported rounding intervals can satisfy the identity.
#'
#' @param data a data frame, one row per source of variation.
#' @param source,df,ss,ms,f column names in \code{data}. Any of \code{ss},
#'   \code{ms}, \code{f} may be \code{NULL} or absent; dependent tests are then
#'   skipped.
#' @param error_label,total_label case-insensitive regular expressions
#'   identifying the error row and the total row.
#' @param decimals optional integer overriding inferred reporting precision for
#'   \code{ss}, \code{ms} and \code{f}.
#'
#' @return An object of class \code{bk_result}.
#'
#' @examples
#' a <- bk_example("anova")
#' bk_check_anova(a)
#'
#' @export
bk_check_anova <- function(data,
                           source = "source",
                           df     = "df",
                           ss     = "ss",
                           ms     = "ms",
                           f      = "f",
                           error_label = "error|residual",
                           total_label = "total",
                           decimals = NULL) {

  stopifnot(is.data.frame(data))
  has <- function(nm) !is.null(nm) && nm %in% names(data)

  lab <- if (has(source)) as.character(data[[source]]) else paste0("row", seq_len(nrow(data)))
  is_total <- grepl(total_label, lab, ignore.case = TRUE)
  is_error <- grepl(error_label, lab, ignore.case = TRUE)

  # degrees of freedom are exact integers, not rounded measurements
  i_df <- if (has(df)) {
    v <- suppressWarnings(as.numeric(data[[df]])); cbind(lo = v, hi = v)
  } else NULL
  i_ss <- if (has(ss)) bk_interval(data[[ss]], decimals) else NULL
  i_ms <- if (has(ms)) bk_interval(data[[ms]], decimals) else NULL
  i_f  <- if (has(f))  bk_interval(data[[f]],  decimals) else NULL

  out <- list()

  ## ---- df additivity ------------------------------------------------------
  if (!is.null(i_df) && any(is_total)) {
    comp <- which(!is_total)
    tot  <- which(is_total)[1]
    # strip every attribute before comparing: all.equal() reports a
    # difference for attribute mismatches even when the numbers are equal,
    # which produced a false INCONSISTENT on a perfectly clean table
    s  <- as.vector(sum(as.vector(i_df[comp, 1]), na.rm = TRUE))
    tv <- as.vector(i_df[tot, 1])
    ok <- is.finite(s) && is.finite(tv) && abs(s - tv) < 1e-8
    out[[length(out) + 1L]] <- data.frame(
      label = "TABLE", test = "df_additivity",
      identity = "sum(df components) = df total",
      reported_lo = tv, reported_hi = tv,
      implied_lo = s, implied_hi = s,
      k_used = NA_character_,
      verdict = if (ok) "consistent" else "INCONSISTENT",
      note = if (ok) NA_character_ else
        sprintf("components sum to %.10g, total reported as %.10g", s, tv),
      stringsAsFactors = FALSE, row.names = NULL
    )
  }

  ## ---- SS additivity ------------------------------------------------------
  if (!is.null(i_ss) && any(is_total)) {
    comp <- which(!is_total)
    tot  <- which(is_total)[1]
    implied <- cbind(lo = sum(i_ss[comp, 1], na.rm = TRUE),
                     hi = sum(i_ss[comp, 2], na.rm = TRUE))
    out[[length(out) + 1L]] <- .bk_rows(
      "TABLE", "ss_additivity", "sum(SS components) = SS total",
      i_ss[tot, , drop = FALSE], implied
    )
  }

  ## ---- MS = SS / df -------------------------------------------------------
  if (!is.null(i_ss) && !is.null(i_ms) && !is.null(i_df)) {
    keep <- !is_total & !is.na(i_df[, 1]) & i_df[, 1] > 0
    if (any(keep)) {
      implied <- .iv_div(i_ss[keep, , drop = FALSE], i_df[keep, , drop = FALSE])
      out[[length(out) + 1L]] <- .bk_rows(
        lab[keep], "ms_from_ss_df", "MS = SS / df",
        i_ms[keep, , drop = FALSE], implied
      )
    }
  }

  ## ---- F = MS source / MS error -------------------------------------------
  if (!is.null(i_ms) && !is.null(i_f) && any(is_error)) {
    err <- which(is_error)[1]
    keep <- !is_error & !is_total & !is.na(i_f[, 1])
    if (any(keep)) {
      denom <- i_ms[rep(err, sum(keep)), , drop = FALSE]
      implied <- .iv_div(i_ms[keep, , drop = FALSE], denom)
      out[[length(out) + 1L]] <- .bk_rows(
        lab[keep], "f_from_ms", "F = MS source / MS error",
        i_f[keep, , drop = FALSE], implied
      )
    }
  }

  if (!length(out)) {
    stop("Nothing testable. An ANOVA audit needs at least df with ss and ms, ",
         "or ms with f and an identifiable error row.", call. = FALSE)
  }
  .as_bk_result(do.call(rbind, out), module = "anova")
}
