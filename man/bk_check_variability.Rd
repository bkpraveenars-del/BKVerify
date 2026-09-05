\name{bk_check_variability}
\alias{bk_check_variability}
\title{Audit a genetic variability table}
\usage{
bk_check_variability(data, trait = "trait", gcv = "gcv", pcv = "pcv",
  h2 = "h2", gam = "gam", k = "auto",
  h2_scale = c("percent", "fraction"), decimals = NULL)
}
\arguments{
\item{data}{a data frame holding one row per trait.}

\item{trait, gcv, pcv, h2, gam}{column names in \code{data}. Set any of
\code{gcv}, \code{pcv}, \code{h2}, \code{gam} to \code{NULL} if the quantity
was not reported; tests requiring it are skipped.}

\item{k}{either a numeric selection differential, or \code{"auto"} (default)
to test the standard family returned by \code{\link{bk_k}} and report which
member reconciles each trait.}

\item{h2_scale}{\code{"percent"} (default) if heritability is reported on a
0--100 scale, \code{"fraction"} if on a 0--1 scale.}

\item{decimals}{optional integer or integer vector overriding the inferred
reporting precision.}
}
\value{
An object of class \code{bk_result}: a data frame with one row per trait per
test, carrying the reported interval, the implied interval and a verdict of
\code{"consistent"}, \code{"INCONSISTENT"} or \code{"not_applicable"}.
}
\description{
Tests the internal arithmetic of a genotypic/phenotypic coefficient of
variation, heritability and genetic advance table using rounding-interval
arithmetic. The identities used are \eqn{h^2 = (GCV/PCV)^2},
\eqn{GAM = K h^2 PCV}, \eqn{GAM = K \, GCV^2 / PCV} and
\eqn{GCV \le PCV}.
}
\details{
The identities hold irrespective of which phenotypic variance definition the
author used, because \eqn{\sigma^2_p} cancels. A flagged row therefore
indicates arithmetic inconsistency, not methodological disagreement. Values
are declared inconsistent only when no combination of values inside the
reported rounding intervals satisfies the identity.

Supplying the columns as character vectors is strongly preferred: it
preserves trailing zeros and hence the true reporting precision. Numeric
input loses them and yields wider intervals, which is conservative.

Because the identities overlap, the pattern of failures localises the fault:
a wrong heritability fails \code{h2_from_cv} and \code{gam_identity} while
\code{gam_from_cv} passes; a wrong genetic advance fails both genetic
advance tests while \code{h2_from_cv} passes.
}
\examples{
v <- bk_example("variability")
bk_check_variability(v)
}
\seealso{
\code{\link{bk_audit}}, \code{\link{bk_k}}, \code{\link{bk_example}}
}
