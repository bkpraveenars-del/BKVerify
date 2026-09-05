\name{BKVerify-package}
\alias{BKVerify-package}
\alias{BKVerify}
\docType{package}
\title{BKVerify: Consistency Auditing of Reported Plant Breeding Statistics}
\description{
Audits published or draft plant breeding tables for internal arithmetic
consistency. Analysis of variance tables, precision statistics and genetic
variability parameters are jointly over-determined by exact algebraic
identities; \pkg{BKVerify} recomputes every derivable quantity using
rounding-interval arithmetic and reports a value as inconsistent only when
no combination of values inside the reported rounding intervals can satisfy
the identity.
}
\details{
The package deliberately restricts itself to relationships that hold
irrespective of which variance-component definition an author adopted.
Broad-sense heritability is not recomputed from mean squares, because the
phenotypic variance is defined in several defensible ways in the plant
breeding literature and authors seldom state which they used. The identities
used here survive that ambiguity because the phenotypic variance cancels.

The package makes no claim about whether an analysis was appropriate,
whether the design was sound, or whether any discrepancy was deliberate. A
verdict of \code{"consistent"} means only that the printed numbers can be
reconciled.

Main functions: \code{\link{bk_check_variability}},
\code{\link{bk_check_anova}}, \code{\link{bk_check_precision}},
\code{\link{bk_check_corr}}, \code{\link{bk_audit}},
\code{\link{bk_example}}, \code{\link{bk_interval}}, \code{\link{bk_k}}.
}
\references{
Burton, G. W. and DeVane, E. H. (1953). Estimating heritability in tall
fescue from replicated clonal material. \emph{Agronomy Journal} 45,
478--481.

Johnson, H. W., Robinson, H. F. and Comstock, R. E. (1955). Estimates of
genetic and environmental variability in soybeans. \emph{Agronomy Journal}
47, 314--318.

Nuijten, M. B. and Wicherts, J. M. (2024). Implementing statcheck during
peer review is related to a steep decline in statistical-reporting
inconsistencies. \emph{Advances in Methods and Practices in Psychological
Science} 7.
}
\author{
Praveen Kumar \email{bkpraveenars@gmail.com}
}
