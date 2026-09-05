# BKVerify

**Consistency auditing of reported plant breeding statistics.**

Psychology has [statcheck](https://CRAN.R-project.org/package=statcheck), which
recomputes *p*-values from reported test statistics; when journals began running
it during peer review, reporting inconsistencies fell sharply (Nuijten &
Wicherts 2024). Quantitative genetics has no equivalent, despite our tables
being *more* auditable: the numbers printed in a variability table are not
independent, they are linked by exact algebraic identities.

`BKVerify` recomputes every derivable quantity and reports whether the printed
values can be reconciled.

---

## The identities

The four columns printed in almost every variability table carry only **two**
degrees of freedom:

| Identity | Requires | Definition-dependent? |
|---|---|---|
| `h² = (GCV / PCV)²` | GCV, PCV, h² | **No** — σ²p cancels |
| `GAM = K · h² · PCV` | h², PCV, GAM, K | **No** — σ²p cancels |
| `GAM = K · GCV² / PCV` | GCV, PCV, GAM, K | **No** — σ²p cancels |
| `GCV ≤ PCV` | GCV, PCV | **No** — true by construction |

And the ANOVA table is over-determined by three more:

| Identity | Requires |
|---|---|
| `Σ df components = df total` | df column |
| `Σ SS components = SS total` | SS column |
| `MS = SS / df` | SS, df, MS |
| `F = MS source / MS error` | MS, F |
| `CV% = 100 √MSe / mean` | MSe, mean, CV |
| `SEm = √(MSe / r)` | MSe, r, SEm |
| `CD = t(α, dfe) · SEm · √2` | SEm, CD, dfe — **no MSe needed** |

Plus admissibility of any reported correlation matrix (symmetry, unit diagonal,
|r| ≤ 1, positive semi-definiteness).

**Every identity above is independent of which phenotypic variance definition
the author adopted.** That is deliberate, and it is the whole design constraint
of the package — see *What this does not do*.

---

## Quick start

```r
library(BKVerify)

v <- bk_example("variability")   # 7 traits; 2 rows deliberately corrupted
bk_check_variability(v)
```

```
BKVerify audit <variability>
--------------------------------------------------------------
  28 checks: 25 consistent, 3 INCONSISTENT, 0 indeterminate, 0 n/a

  [INCONSISTENT] Grains per spike  h2 = (GCV/PCV)^2
        reported [89.045, 89.055]   implied [84.81, 85.11]
        note: definition-free: sigma^2_p cancels
  [INCONSISTENT] Grains per spike  GAM = K * h2 * PCV
        reported [26.615, 26.625]   implied [27.87, 27.90]
        note: no standard selection differential reconciles this row
  [INCONSISTENT] Grain yield per plant (g)  GAM = K * h2 * PCV
        reported [34.385, 34.395]   implied [29.88, 29.91]
        note: no standard selection differential reconciles this row
--------------------------------------------------------------
```

Audit a whole paper at once:

```r
bk_audit(
  bk_check_variability(bk_example("variability")),
  bk_check_anova(bk_example("anova")),
  bk_check_corr(bk_example("corr"))
)
```

---

## The failure *pattern* localises the error

Because the identities overlap, which tests fail tells you **which printed
number is wrong** — not merely that something is:

| | `h2_from_cv` | `gam_identity` | `gam_from_cv` | Diagnosis |
|---|---|---|---|---|
| Grains per spike | ✗ | ✗ | **✓** | h² column is wrong |
| Grain yield per plant | **✓** | ✗ | ✗ | GAM column is wrong |

`gam_from_cv` never touches h². `h2_from_cv` never touches GAM. The row that
passes tells you where the fault is not.

---

## Rounding is handled rigorously, not tolerantly

A value printed as `88.14` is not the number 88.14; it asserts the interval
`[88.135, 88.145)`. Every check is an **interval** comparison, and a value is
flagged only when *no* combination of values inside the reported intervals can
satisfy the identity.

Validated on 20,000 simulated RCBD trials (24 genotypes, 3 replications):

| Reporting precision | False-positive rate | h² error detected in ≥95% of tables |
|---|---|---|
| 1 decimal | **0.00 %** | 1.0 points |
| 2 decimals | **0.00 %** | 0.1 points |
| 3 decimals | **0.00 %** | 0.05 points |

For the correlation matrix, non-definiteness is declared only when it is
*provable* at the reported precision, via Weyl's inequality:
λ<sub>min</sub>(R) + δ√(n²−n) < 0 ⟹ no matrix inside the rounding box is
positive semi-definite. Otherwise the verdict is `indeterminate`, and the
package says so rather than guessing.

---

## Selection intensity

A paper that omits its selection intensity is indistinguishable from one that
used a different intensity. With `k = "auto"` (the default), `BKVerify` tests
the whole family (K = 2.64, 2.06, 1.76, 1.40) and reports which member
reconciles each trait:

```
k_used = "1.76 (10%)"
note   = "reconciles only at 10% selection intensity; confirm against the text"
```

That is a *reporting* observation, not an arithmetic accusation, and it is
labelled as such.

---

## What this does not do

This is the most important section.

- **It does not recompute heritability from mean squares.** σ²p is defined at
  least three defensible ways in the literature (σ²g + σ²e; σ²g + σ²e/r; forms
  carrying a genotype × environment term), and authors seldom state which they
  used. Flagging on that basis would confuse methodological disagreement with
  arithmetic error. Every identity implemented here survives that ambiguity.
- **It does not flag |path coefficient| > 1 as impossible.** Direct effects
  exceeding unity are a legitimate consequence of multicollinearity. They belong
  under diagnostics, not under impossibility. (Planned for Tier 3.)
- **It does not read PDFs.** Input is a clean data frame. Table extraction is a
  separate, much messier problem and mixing it in would import its error rate.
- **It does not judge the analysis.** A `consistent` verdict means the printed
  numbers can be reconciled. It says nothing about whether the design was sound,
  the model appropriate, or any discrepancy deliberate.

---

## Roadmap

- **Tier 1 — implemented.** Zero-ambiguity identities: ANOVA structure,
  precision statistics, the variability identities, matrix admissibility.
- **Tier 2 — formula-family reconciliation.** Given mean squares, report *which*
  σ²p definition reproduces the reported h², rather than asserting one. Output
  is "consistent under σ²g + σ²e/r", never "error".
- **Tier 3 — model validity.** Detect algebraically dependent traits in path and
  correlation input (grain yield = biological yield × harvest index makes the
  system singular and the direct effects meaningless), plus VIF and condition
  number diagnostics.

---

## Development

The package has no dependencies beyond **stats**. After editing roxygen
comments:

```r
devtools::document()   # regenerate man/ and NAMESPACE
devtools::test()
devtools::check()      # must be clean before submission
```

## References

Burton, G. W. & DeVane, E. H. (1953). Estimating heritability in tall fescue
from replicated clonal material. *Agronomy Journal* 45, 478–481.

Johnson, H. W., Robinson, H. F. & Comstock, R. E. (1955). Estimates of genetic
and environmental variability in soybeans. *Agronomy Journal* 47, 314–318.

Nuijten, M. B. & Wicherts, J. M. (2024). Implementing statcheck during peer
review is related to a steep decline in statistical-reporting inconsistencies.
*Advances in Methods and Practices in Psychological Science* 7.

## Licence

GPL-3
