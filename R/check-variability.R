# ---------------------------------------------------------------------------
# Genetic variability table: the over-determined core of BKVerify
#
# The four quantities printed in almost every variability table -- GCV, PCV,
# broad-sense heritability and genetic advance as percent of mean -- carry only
# two degrees of freedom. They are linked by two exact identities that hold
# whatever definition of phenotypic variance the author adopted, because the
# definition cancels:
#
#     h^2  = (GCV / PCV)^2
#     GAM  = K * h^2 * PCV          (h^2 as a fraction)
#     GAM  = K * GCV^2 / PCV        (the two combined)
#
# No variance components are required. No assumption about sigma^2_p is
# required. This is what makes the module safe to point at published work.
# ---------------------------------------------------------------------------

#' Audit a genetic variability table
#'
#' Tests the internal arithmetic of a genotypic/phenotypic coefficient of
#' variation, heritability and genetic advance table using rounding-interval
#' arithmetic.
#'
#' The identities used hold irrespective of which phenotypic variance
#' definition the author used, because \eqn{\sigma^2_p} cancels. A flagged row
#' therefore indicates arithmetic inconsistency, not methodological
#' disagreement. Values are declared inconsistent only when no combination of
#' values inside the reported rounding intervals satisfies the identity.
#'
#' Supplying the columns as character vectors is strongly preferred: it
#' preserves trailing zeros and hence the true reporting precision. Numeric
#' input loses them and yields wider intervals, which is conservative.
#'
#' @param data a data frame holding one row per trait.
#' @param trait,gcv,pcv,h2,gam column names in \code{data}. Set any of
#'   \code{gcv}, \code{pcv}, \code{h2}, \code{gam} to \code{NULL} if the
#'   quantity was not reported; tests requiring it are skipped.
#' @param k either a numeric selection differential, or \code{"auto"} (default)
#'   to test the standard family returned by \code{\link{bk_k}} and report
#'   which member reconciles each trait.
#' @param h2_scale \code{"percent"} (default) if heritability is reported on a
#'   0-100 scale, \code{"fraction"} if on a 0-1 scale.
#' @param decimals optional integer or integer vector overriding the inferred
#'   reporting precision.
#'
#' @return An object of class \code{bk_result}: a data frame with one row per
#'   trait per test, carrying the reported interval, the implied interval and a
#'   verdict of \code{"consistent"}, \code{"INCONSISTENT"} or
#'   \code{"not_applicable"}.
#'
#' @seealso \code{\link{bk_audit}}, \code{\link{bk_k}}
#'
#' @examples
#' v <- bk_example("variability")
#' bk_check_variability(v)
#'
#' @export
bk_check_variability <- function(data,
                                 trait = "trait",
                                 gcv   = "gcv",
                                 pcv   = "pcv",
                                 h2    = "h2",
                                 gam   = "gam",
                                 k     = "auto",
                                 h2_scale = c("percent", "fraction"),
                                 decimals = NULL) {

  stopifnot(is.data.frame(data))
  h2_scale <- match.arg(h2_scale)

  grab <- function(nm) {
    if (is.null(nm)) return(NULL)
    if (!nm %in% names(data)) return(NULL)
    data[[nm]]
  }
  lab <- if (!is.null(trait) && trait %in% names(data)) {
    as.character(data[[trait]])
  } else {
    paste0("row", seq_len(nrow(data)))
  }

  GCV <- grab(gcv); PCV <- grab(pcv); H2 <- grab(h2); GAM <- grab(gam)

  i_gcv <- if (!is.null(GCV)) bk_interval(GCV, decimals) else NULL
  i_pcv <- if (!is.null(PCV)) bk_interval(PCV, decimals) else NULL
  i_h2  <- if (!is.null(H2))  bk_interval(H2,  decimals) else NULL
  i_gam <- if (!is.null(GAM)) bk_interval(GAM, decimals) else NULL

  # heritability as a fraction, whatever it was reported as
  i_h2f <- if (!is.null(i_h2)) {
    if (h2_scale == "percent") .iv_scale(i_h2, 1 / 100) else i_h2
  } else NULL

  out <- list()

  ## ---- Test 1: GCV <= PCV (an inequality, not an identity) ---------------
  if (!is.null(i_gcv) && !is.null(i_pcv)) {
    ok <- i_gcv[, 1] <= i_pcv[, 2]
    ok[is.na(i_gcv[, 1]) | is.na(i_pcv[, 1])] <- NA
    out[[length(out) + 1L]] <- data.frame(
      label = lab, test = "gcv_le_pcv",
      identity = "GCV <= PCV",
      reported_lo = i_gcv[, 1], reported_hi = i_gcv[, 2],
      implied_lo = -Inf, implied_hi = i_pcv[, 2],
      k_used = NA_character_,
      verdict = .verdict(ok),
      note = ifelse(!is.na(ok) & !ok,
                    "genotypic variance exceeds phenotypic variance; impossible by construction",
                    NA_character_),
      stringsAsFactors = FALSE, row.names = NULL
    )
  }

  ## ---- Test 2: h2 = (GCV / PCV)^2 ----------------------------------------
  if (!is.null(i_gcv) && !is.null(i_pcv) && !is.null(i_h2)) {
    implied <- .iv_pow2(.iv_div(i_gcv, i_pcv))
    if (h2_scale == "percent") implied <- .iv_scale(implied, 100)
    out[[length(out) + 1L]] <- .bk_rows(
      lab, "h2_from_cv", "h2 = (GCV/PCV)^2", i_h2, implied,
      note = "definition-free: sigma^2_p cancels"
    )
  }

  ## ---- Test 3: GAM = K * h2 * PCV ----------------------------------------
  if (!is.null(i_h2f) && !is.null(i_pcv) && !is.null(i_gam)) {
    base <- .iv_mul(i_h2f, i_pcv)
    rec  <- .reconcile_k(i_gam, base, k)
    out[[length(out) + 1L]] <- .bk_rows(
      lab, "gam_identity", "GAM = K * h2 * PCV", i_gam, rec$implied,
      k_used = rec$k_label, note = rec$note
    )
  }

  ## ---- Test 4: GAM = K * GCV^2 / PCV (usable when h2 is absent) ----------
  if (!is.null(i_gcv) && !is.null(i_pcv) && !is.null(i_gam)) {
    # GAM = K * h2 * PCV and h2 = (GCV/PCV)^2 give GAM = K * GCV^2 / PCV.
    # GCV and PCV are both percentages of the same mean, so the scale cancels
    # and no further factor of 100 is required.
    base <- .iv_div(.iv_pow2(i_gcv), i_pcv)
    rec  <- .reconcile_k(i_gam, base, k)
    out[[length(out) + 1L]] <- .bk_rows(
      lab, "gam_from_cv", "GAM = K * GCV^2 / PCV", i_gam, rec$implied,
      k_used = rec$k_label, note = rec$note
    )
  }

  if (!length(out)) {
    stop("No testable combination of columns found. ",
         "Supply at least two of gcv, pcv, h2, gam.", call. = FALSE)
  }
  .as_bk_result(do.call(rbind, out), module = "variability")
}


#' Find which selection differential reconciles a genetic advance value
#'
#' \code{base} is the interval of \eqn{h^2 \times PCV} (or \eqn{GCV^2/PCV/100}),
#' i.e. everything except K. If \code{k} is numeric the answer is a single
#' scaling; if \code{"auto"}, the standard family is tried and the first member
#' that reconciles is reported.
#'
#' @keywords internal
#' @noRd
.reconcile_k <- function(i_target, base, k) {
  n <- nrow(base)

  if (is.numeric(k)) {
    implied <- .iv_scale(base, k)
    ok <- .iv_overlap(i_target, implied)
    note <- rep(NA_character_, n)
    # even with a fixed K, say so if a different standard K would have worked
    fam <- bk_k()
    alt <- vapply(seq_len(n), function(i) {
      if (is.na(ok[i]) || isTRUE(ok[i])) return(NA_character_)
      for (nm in names(fam)) {
        im <- .iv_scale(base[i, , drop = FALSE], fam[[nm]])
        if (isTRUE(.iv_overlap(i_target[i, , drop = FALSE], im))) {
          return(sprintf("reconciles under K = %.2f (%s selection), not the K supplied",
                         fam[[nm]], nm))
        }
      }
      NA_character_
    }, character(1))
    note[!is.na(alt)] <- alt[!is.na(alt)]
    return(list(implied = implied,
                k_label = rep(sprintf("%.2f", k), n),
                note = note))
  }

  if (!identical(k, "auto")) {
    stop("`k` must be numeric or \"auto\".", call. = FALSE)
  }

  fam <- bk_k()
  implied <- matrix(NA_real_, n, 2, dimnames = list(NULL, c("lo", "hi")))
  klab <- rep(NA_character_, n)
  note <- rep(NA_character_, n)

  for (i in seq_len(n)) {
    if (is.na(base[i, 1]) || is.na(i_target[i, 1])) next
    hit <- NA_character_
    for (nm in names(fam)) {
      im <- .iv_scale(base[i, , drop = FALSE], fam[[nm]])
      if (isTRUE(.iv_overlap(i_target[i, , drop = FALSE], im))) {
        hit <- nm
        implied[i, ] <- im
        break
      }
    }
    if (is.na(hit)) {
      # no member reconciles: report the 5% case so the gap is visible
      implied[i, ] <- .iv_scale(base[i, , drop = FALSE], fam[["5%"]])
      klab[i] <- "none"
      note[i] <- "no standard selection differential reconciles this row"
    } else {
      klab[i] <- sprintf("%.2f (%s)", fam[[hit]], hit)
      if (hit != "5%") {
        note[i] <- sprintf("reconciles only at %s selection intensity; confirm against the text", hit)
      }
    }
  }
  list(implied = implied, k_label = klab, note = note)
}
