\name{bk_interval}
\alias{bk_interval}
\title{Rounding interval of a reported value}
\usage{
bk_interval(x, decimals = NULL)
}
\arguments{
\item{x}{numeric or character vector of reported values. Character input is
preferred: it preserves trailing zeros and therefore the true reporting
precision.}

\item{decimals}{optional integer. If supplied, overrides the decimal count
inferred from \code{x}. Recycled to the length of \code{x}.}
}
\value{
A two-column matrix with columns \code{lo} and \code{hi}.
}
\description{
Converts reported values into the closed intervals they actually assert.
A value printed to \code{d} decimals implies a half-width of
\code{0.5 * 10^(-d)}. Every check in \pkg{BKVerify} is decided on these
intervals, never on point values.
}
\examples{
bk_interval(c("11.04", "11.76"))
bk_interval(88.14, decimals = 2)
}
