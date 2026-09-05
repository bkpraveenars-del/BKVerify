\name{bk_k}
\alias{bk_k}
\title{Selection differential constants (K) used in genetic advance}
\usage{
bk_k(intensity = NULL)
}
\arguments{
\item{intensity}{optional character; one of \code{"1\%"}, \code{"5\%"},
\code{"10\%"}, \code{"20\%"}. If \code{NULL}, the full named vector is
returned.}
}
\value{
A named numeric vector, or a single value if \code{intensity} is given.
}
\description{
Genetic advance is computed as \eqn{GA = K \sigma_p h^2}, where \eqn{K} is
the standardised selection differential for the chosen selection intensity
(Johnson, Robinson and Comstock 1955). Authors overwhelmingly report the
conventional rounded values (2.64, 2.06, 1.76, 1.40) rather than exact
normal-curve quantiles, so those conventional values are what
\pkg{BKVerify} tests against.
}
\details{
Because a paper that omits its selection intensity is indistinguishable from
one that used a different intensity, \code{k = "auto"} in
\code{\link{bk_check_variability}} tests the whole family and reports which
member reconciles the table.
}
\references{
Johnson, H. W., Robinson, H. F. and Comstock, R. E. (1955). Estimates of
genetic and environmental variability in soybeans. \emph{Agronomy Journal}
47, 314--318.
}
\examples{
bk_k()
bk_k("5\%")
}
