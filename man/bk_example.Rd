\name{bk_example}
\alias{bk_example}
\title{Example tables for auditing}
\usage{
bk_example(what = c("variability", "anova", "precision", "corr",
  "corr_impossible"))
}
\arguments{
\item{what}{one of \code{"variability"}, \code{"anova"}, \code{"precision"},
\code{"corr"} or \code{"corr_impossible"}.}
}
\value{
A data frame, matrix or list, depending on \code{what}.
}
\description{
Returns small worked examples in the shape the \code{bk_check_*} functions
expect. Values are stored as character strings so that trailing zeros, and
therefore the true reporting precision, are preserved. The tables derive
from simulated randomised complete block trials (24 genotypes, 3
replications) rounded to typical published precision.
}
\details{
The \code{"variability"} table carries two planted errors, useful for
teaching error localisation:
\describe{
\item{Grains per spike}{heritability inflated by 4 points. The
\code{h2_from_cv} and \code{gam_identity} tests fail while
\code{gam_from_cv} passes, localising the fault to the heritability
column.}
\item{Grain yield per plant}{genetic advance inflated by 15 percent. Here
\code{h2_from_cv} passes and both genetic advance tests fail, localising
the fault to the genetic advance column.}
}
}
\examples{
bk_example("variability")
bk_check_variability(bk_example("variability"))
}
