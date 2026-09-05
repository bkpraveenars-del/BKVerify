# ---------------------------------------------------------------------------
# Rounding-interval engine
#
# Every check in BKVerify is decided by interval arithmetic, never by point
# arithmetic. A value printed as 88.14 is not the number 88.14; it is the
# statement "the true value lies in [88.135, 88.145)". A reported quantity is
# declared inconsistent only when NO combination of values inside the reported
# rounding intervals satisfies the identity. This is what keeps the false
# positive rate at zero and is the single most important design decision in
# the package.
# ---------------------------------------------------------------------------

#' Number of printed decimal places
#'
#' Character input is preferred because it preserves trailing zeros:
#' \code{"88.10"} carries two decimals, whereas \code{88.10} is stored as
#' \code{88.1} and can only be read as one. Under-counting decimals widens the
#' interval, which is the conservative direction (fewer flags, never more).
#'
#' @param x numeric or character vector.
#' @return integer vector of decimal counts, capped at 10.
#' @keywords internal
#' @noRd
.bk_decimals <- function(x) {
  xs <- if (is.character(x)) {
    trimws(x)
  } else {
    vapply(as.numeric(x), function(z) {
      if (is.na(z)) return(NA_character_)
      format(z, scientific = FALSE, trim = TRUE, digits = 15)
    }, character(1))
  }
  out <- vapply(xs, function(s) {
    if (is.na(s)) return(NA_integer_)
    if (!grepl(".", s, fixed = TRUE)) return(0L)
    as.integer(nchar(sub("^[^.]*\\.", "", s)))
  }, integer(1), USE.NAMES = FALSE)
  pmin(out, 10L)
}

#' Rounding interval of a reported value
#'
#' Converts reported values into the closed intervals they actually assert.
#' A value printed to \code{d} decimals implies a half-width of
#' \code{0.5 * 10^(-d)}.
#'
#' @param x numeric or character vector of reported values. Character input is
#'   preferred: it preserves trailing zeros and therefore the true reporting
#'   precision.
#' @param decimals optional integer. If supplied, overrides the decimal count
#'   inferred from \code{x}. Recycled to the length of \code{x}.
#'
#' @return A two-column matrix with columns \code{lo} and \code{hi}.
#'
#' @examples
#' bk_interval(c("11.04", "11.76"))
#' bk_interval(88.14, decimals = 2)
#'
#' @export
bk_interval <- function(x, decimals = NULL) {
  v <- suppressWarnings(as.numeric(x))
  d <- if (is.null(decimals)) .bk_decimals(x) else rep_len(as.integer(decimals), length(v))
  h <- 0.5 * 10^(-d)
  m <- cbind(lo = v - h, hi = v + h)
  m[is.na(v), ] <- NA_real_
  m
}

# --- interval arithmetic ---------------------------------------------------

.iv <- function(lo, hi) cbind(lo = lo, hi = hi)

.iv_mul <- function(a, b) {
  p1 <- a[, 1] * b[, 1]; p2 <- a[, 1] * b[, 2]
  p3 <- a[, 2] * b[, 1]; p4 <- a[, 2] * b[, 2]
  .iv(pmin(p1, p2, p3, p4), pmax(p1, p2, p3, p4))
}

.iv_div <- function(a, b) {
  spans_zero <- !is.na(b[, 1]) & !is.na(b[, 2]) & b[, 1] <= 0 & b[, 2] >= 0
  p1 <- a[, 1] / b[, 1]; p2 <- a[, 1] / b[, 2]
  p3 <- a[, 2] / b[, 1]; p4 <- a[, 2] / b[, 2]
  out <- .iv(pmin(p1, p2, p3, p4), pmax(p1, p2, p3, p4))
  out[spans_zero, ] <- c(-Inf, Inf)   # denominator interval contains 0
  out
}

.iv_scale <- function(a, k) {
  p1 <- a[, 1] * k; p2 <- a[, 2] * k
  .iv(pmin(p1, p2), pmax(p1, p2))
}

.iv_sqrt <- function(a) {
  lo <- ifelse(a[, 1] < 0, 0, a[, 1])
  .iv(sqrt(lo), sqrt(pmax(a[, 2], 0)))
}

.iv_pow2 <- function(a) {
  p1 <- a[, 1]^2; p2 <- a[, 2]^2
  crosses <- !is.na(a[, 1]) & !is.na(a[, 2]) & a[, 1] <= 0 & a[, 2] >= 0
  .iv(ifelse(crosses, 0, pmin(p1, p2)), pmax(p1, p2))
}

.iv_sum <- function(mats) {
  lo <- Reduce(`+`, lapply(mats, function(m) m[, 1]))
  hi <- Reduce(`+`, lapply(mats, function(m) m[, 2]))
  .iv(lo, hi)
}

#' Do two intervals overlap?
#' @return logical; NA propagates.
#' @keywords internal
#' @noRd
.iv_overlap <- function(a, b) {
  ok <- !(a[, 2] < b[, 1] | a[, 1] > b[, 2])
  ok[is.na(a[, 1]) | is.na(b[, 1])] <- NA
  ok
}

#' Turn an overlap test into a verdict label
#' @keywords internal
#' @noRd
.verdict <- function(ok) {
  ifelse(is.na(ok), "not_applicable", ifelse(ok, "consistent", "INCONSISTENT"))
}

#' Assemble one block of result rows
#' @keywords internal
#' @noRd
.bk_rows <- function(label, test, identity, reported, implied, k_used = NA_character_,
                     note = NA_character_) {
  n <- nrow(reported)
  data.frame(
    label       = rep_len(label, n),
    test        = rep_len(test, n),
    identity    = rep_len(identity, n),
    reported_lo = reported[, 1],
    reported_hi = reported[, 2],
    implied_lo  = implied[, 1],
    implied_hi  = implied[, 2],
    k_used      = rep_len(k_used, n),
    verdict     = .verdict(.iv_overlap(reported, implied)),
    note        = rep_len(note, n),
    stringsAsFactors = FALSE,
    row.names   = NULL
  )
}
