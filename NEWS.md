# BKVerify 0.1.1

* Removed the URL and BugReports fields from DESCRIPTION: they pointed at a
  repository that does not exist and returned 404 in CRAN's URL check.
* Fixed a false INCONSISTENT verdict in the degrees-of-freedom additivity
  check of `bk_check_anova()`. The comparison used
  `isTRUE(all.equal())`, which reported a difference on attribute mismatch
  even when the two totals were numerically identical; it now compares
  attribute-stripped numeric values against a tolerance.

# BKVerify 0.1.0

* Initial release.
* Four audit modules, all restricted to definition-free identities:
  * `bk_check_variability()` — GCV/PCV/heritability/genetic-advance identities
    (h2 = (GCV/PCV)^2; GAM = K * h2 * PCV; GAM = K * GCV^2 / PCV; GCV <= PCV).
  * `bk_check_anova()` — df and SS additivity, MS = SS/df, F = MS/MSe.
  * `bk_check_precision()` — CV%, SEm, CD from MSe, and CD = t * SEm * sqrt(2).
  * `bk_check_corr()` — symmetry, unit diagonal, |r| <= 1, and positive
    semi-definiteness with a rigorous Weyl rounding bound.
* `bk_audit()` combines module results; `print()` and `summary()` methods.
* All comparisons use rounding-interval arithmetic: a value is flagged only
  when no combination of values inside the reported rounding intervals can
  satisfy the identity.
* `k = "auto"` reconciles genetic advance against the standard selection
  differential family (2.64, 2.06, 1.76, 1.40) and reports which member fits.
* Worked examples via `bk_example()`, including two planted errors that
  demonstrate error localisation.
