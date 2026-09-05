# ---------------------------------------------------------------------------
# The bk_result object
# ---------------------------------------------------------------------------

#' @keywords internal
#' @noRd
.as_bk_result <- function(df, module) {
  cols <- c("label", "test", "identity", "reported_lo", "reported_hi",
            "implied_lo", "implied_hi", "k_used", "verdict", "note")
  for (cc in setdiff(cols, names(df))) df[[cc]] <- NA
  df <- df[, cols, drop = FALSE]
  rownames(df) <- NULL
  attr(df, "module") <- module
  class(df) <- c("bk_result", "data.frame")
  df
}

#' Combine audit results
#'
#' Binds the output of several \code{bk_check_*} calls into a single audit
#' object with a module column.
#'
#' @param ... objects of class \code{bk_result}, or a single list of them.
#'
#' @return An object of class \code{bk_result} carrying an additional
#'   \code{module} column.
#'
#' @examples
#' bk_audit(
#'   bk_check_variability(bk_example("variability")),
#'   bk_check_anova(bk_example("anova")),
#'   bk_check_corr(bk_example("corr"))
#' )
#'
#' @export
bk_audit <- function(...) {
  parts <- list(...)
  if (length(parts) == 1L && is.list(parts[[1]]) && !inherits(parts[[1]], "bk_result")) {
    parts <- parts[[1]]
  }
  if (!length(parts)) stop("Nothing to combine.", call. = FALSE)
  if (!all(vapply(parts, inherits, logical(1), "bk_result"))) {
    stop("All arguments must be bk_result objects returned by bk_check_*().",
         call. = FALSE)
  }
  pieces <- lapply(parts, function(p) {
    m <- attr(p, "module")
    d <- as.data.frame(p)
    d$module <- if (is.null(m)) NA_character_ else m
    d[, c("module", setdiff(names(d), "module")), drop = FALSE]
  })
  out <- do.call(rbind, pieces)
  rownames(out) <- NULL
  attr(out, "module") <- "audit"
  class(out) <- c("bk_result", "data.frame")
  out
}

# signature must match the as.data.frame generic exactly, or R CMD check
# raises "checking S3 generic/method consistency"
#' @export
as.data.frame.bk_result <- function(x, row.names = NULL, optional = FALSE, ...) {
  y <- x
  attr(y, "module") <- NULL
  class(y) <- "data.frame"
  if (!is.null(row.names)) rownames(y) <- row.names
  y
}

#' @export
print.bk_result <- function(x, ...) {
  m <- attr(x, "module")
  bad <- x$verdict == "INCONSISTENT"
  ind <- x$verdict == "indeterminate"
  na_ <- x$verdict == "not_applicable"
  ok  <- x$verdict == "consistent"

  cat("BKVerify audit", if (!is.null(m)) paste0(" <", m, ">") else "", "\n", sep = "")
  cat(strrep("-", 62), "\n", sep = "")
  cat(sprintf("  %d checks: %d consistent, %d INCONSISTENT, %d indeterminate, %d n/a\n",
              nrow(x), sum(ok, na.rm = TRUE), sum(bad, na.rm = TRUE),
              sum(ind, na.rm = TRUE), sum(na_, na.rm = TRUE)))

  show <- x[bad | ind, , drop = FALSE]
  if (nrow(show)) {
    cat("\n")
    for (i in seq_len(nrow(show))) {
      r <- show[i, ]
      cat(sprintf("  [%s] %s  %s\n", r$verdict, r$label, r$identity))
      if (is.finite(r$reported_lo) && is.finite(r$implied_lo)) {
        cat(sprintf("        reported [%.4g, %.4g]   implied [%.4g, %.4g]\n",
                    r$reported_lo, r$reported_hi, r$implied_lo, r$implied_hi))
      }
      if (!is.na(r$note)) cat(sprintf("        note: %s\n", r$note))
    }
  } else {
    cat("\n  No inconsistencies detected.\n")
  }
  cat(strrep("-", 62), "\n", sep = "")
  cat("  A 'consistent' verdict means the reported values are arithmetically\n")
  cat("  reconcilable. It is not a judgement on the underlying analysis.\n")
  invisible(x)
}

#' @export
summary.bk_result <- function(object, ...) {
  tb <- table(test = object$test, verdict = object$verdict)
  cat("BKVerify audit summary\n")
  print(tb)
  invisible(as.data.frame(tb))
}
