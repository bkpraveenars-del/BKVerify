\name{bk_audit}
\alias{bk_audit}
\alias{print.bk_result}
\alias{summary.bk_result}
\alias{as.data.frame.bk_result}
\title{Combine audit results}
\usage{
bk_audit(...)

\method{print}{bk_result}(x, ...)

\method{summary}{bk_result}(object, ...)

\method{as.data.frame}{bk_result}(x, row.names = NULL, optional = FALSE, ...)
}
\arguments{
\item{...}{objects of class \code{bk_result}, or a single list of them. For
the methods, further arguments (ignored).}

\item{x, object}{an object of class \code{bk_result}.}

\item{row.names, optional}{as in \code{\link[base]{as.data.frame}}.}
}
\value{
\code{bk_audit} returns an object of class \code{bk_result} carrying an
additional \code{module} column. The \code{print} method returns its input
invisibly; \code{summary} returns a verdict-by-test table invisibly;
\code{as.data.frame} returns a plain data frame.
}
\description{
Binds the output of several \code{bk_check_*} calls into a single audit
object. The \code{print} method shows only inconsistent and indeterminate
rows, together with a reminder that a \code{"consistent"} verdict means the
reported values are arithmetically reconcilable, not that the underlying
analysis was appropriate.
}
\examples{
bk_audit(
  bk_check_variability(bk_example("variability")),
  bk_check_anova(bk_example("anova")),
  bk_check_corr(bk_example("corr"))
)
}
