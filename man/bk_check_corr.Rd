\name{bk_check_corr}
\alias{bk_check_corr}
\title{Audit a reported correlation matrix}
\usage{
bk_check_corr(R, decimals = NULL, symmetry_tol = 1e-08)
}
\arguments{
\item{R}{a square numeric or character matrix of correlation coefficients.
Character input preserves reporting precision and is preferred.}

\item{decimals}{optional integer overriding the inferred reporting
precision.}

\item{symmetry_tol}{tolerance for the symmetry check. Default \code{1e-8}.}
}
\value{
An object of class \code{bk_result}.
}
\description{
Checks symmetry, unit diagonal, coefficient range and positive
semi-definiteness of a reported correlation matrix. A correlation matrix
that is not positive semi-definite cannot arise from any data set; published
matrices nevertheless fail this because coefficients are computed pairwise
on different subsets, transcribed by hand, or assembled from several
sources.
}
\details{
Rounding is handled rigorously. For a symmetric perturbation \eqn{E} with
zero diagonal and entries bounded by the rounding half-width \eqn{\delta},
Weyl's inequality bounds the eigenvalue movement by
\eqn{\delta \sqrt{n^2 - n}}. Non-definiteness is reported as
\code{"INCONSISTENT"} only when
\eqn{\lambda_{min}(R) + \delta \sqrt{n^2 - n} < 0}, i.e. when no matrix
inside the reported rounding box is positive semi-definite. When the minimum
eigenvalue is negative but within the rounding allowance, the verdict is
\code{"indeterminate"}.
}
\examples{
bk_check_corr(bk_example("corr"))
bk_check_corr(bk_example("corr_impossible"))
}
\seealso{
\code{\link{bk_audit}}, \code{\link{bk_example}}
}
