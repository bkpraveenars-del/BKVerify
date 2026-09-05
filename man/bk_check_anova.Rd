\name{bk_check_anova}
\alias{bk_check_anova}
\title{Audit an analysis of variance table}
\usage{
bk_check_anova(data, source = "source", df = "df", ss = "ss", ms = "ms",
  f = "f", error_label = "error|residual", total_label = "total",
  decimals = NULL)
}
\arguments{
\item{data}{a data frame, one row per source of variation.}

\item{source, df, ss, ms, f}{column names in \code{data}. Any of \code{ss},
\code{ms}, \code{f} may be \code{NULL} or absent; dependent tests are then
skipped.}

\item{error_label, total_label}{case-insensitive regular expressions
identifying the error row and the total row.}

\item{decimals}{optional integer overriding inferred reporting precision for
\code{ss}, \code{ms} and \code{f}.}
}
\value{
An object of class \code{bk_result}.
}
\description{
Checks the internal algebraic structure of a published analysis of variance
table: additivity of degrees of freedom and sums of squares, the definition
of mean squares (\eqn{MS = SS/df}), and the definition of the variance ratio
(\eqn{F = MS_{source}/MS_{error}}).
}
\details{
All comparisons use rounding-interval arithmetic, so a row is flagged only
when no combination of values inside the reported rounding intervals can
satisfy the identity. Degrees of freedom are treated as exact integers,
never as rounded quantities.
}
\examples{
a <- bk_example("anova")
bk_check_anova(a)
}
\seealso{
\code{\link{bk_audit}}, \code{\link{bk_example}}
}
