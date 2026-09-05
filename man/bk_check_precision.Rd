\name{bk_check_precision}
\alias{bk_check_precision}
\title{Audit precision statistics (CV, SEm, CD)}
\usage{
bk_check_precision(mse = NULL, r = NULL, grand_mean = NULL,
  df_error = NULL, cv = NULL, sem = NULL, cd = NULL, alpha = 0.05,
  label = NULL, decimals = NULL)
}
\arguments{
\item{mse}{error mean square. May be \code{NULL} if only \code{cd},
\code{sem} and \code{df_error} are available.}

\item{r}{number of replications.}

\item{grand_mean}{grand mean of the trait.}

\item{df_error}{error degrees of freedom (treated as exact).}

\item{cv, sem, cd}{the reported values to be tested. Any may be \code{NULL}.}

\item{alpha}{significance level used for the critical difference. Default
\code{0.05}.}

\item{label}{optional character vector naming each trait.}

\item{decimals}{optional integer overriding inferred reporting precision.}
}
\value{
An object of class \code{bk_result}.
}
\description{
Recomputes the coefficient of variation
(\eqn{CV\% = 100 \sqrt{MSe} / \bar{x}}), standard error of the mean
(\eqn{SEm = \sqrt{MSe/r}}) and critical difference
(\eqn{CD = t \sqrt{2 MSe / r}}) from the error mean square, and additionally
checks the relation \eqn{CD = t \times SEm \times \sqrt{2}}, which requires
only the two printed values and the error degrees of freedom.
}
\details{
All arguments may be vectors of equal length, one element per trait. The
\eqn{CD = t \, SEm \sqrt{2}} relation is useful in practice because many
papers print CD and SEm but not the error mean square.
}
\examples{
bk_check_precision(mse = "10.03", r = 3, grand_mean = "45.16",
                   df_error = 38, cv = "7.01", sem = "1.83", cd = "5.24")
}
\seealso{
\code{\link{bk_audit}}
}
