## Resubmission

This is a resubmission. In the previous version I was asked to fix two
invalid URLs in DESCRIPTION:

    https://github.com/bkpraveen/BKVerify         (404)
    https://github.com/bkpraveen/BKVerify/issues  (404)

Both pointed at a repository that does not exist. I have removed the URL and
BugReports fields from DESCRIPTION entirely rather than substituting another
address, and I have removed the corresponding install link from README.md.
The package now contains no URL that is not verified to resolve.

Thank you for catching this.

## R CMD check results

0 errors | 0 warnings | 1 note

* The only NOTE is local: README.md/NEWS.md cannot be checked without
  pandoc. CRAN's build machines have pandoc.

## Submission comments

* The package audits the internal arithmetic consistency of reported plant
  breeding statistics (ANOVA tables, precision statistics, genetic variability
  parameters, correlation matrices) using rounding-interval arithmetic.
* It deliberately restricts itself to algebraic identities that hold
  irrespective of the author's variance-component definition, so that flags
  reflect arithmetic inconsistency rather than methodological disagreement.
* All examples run in well under 5 seconds and write nothing to disk.
* The reference in DESCRIPTION uses the <doi:...> form and has been verified
  to resolve.
* No compiled code; the only dependency is stats.
