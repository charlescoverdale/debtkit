# Bohn's Fiscal Reaction Function Test

Estimates the fiscal reaction function following Bohn (1998):
`pb(t) = rho * d(t-1) + alpha * Z(t) + epsilon(t)`, where `pb` is the
primary balance-to-GDP ratio, `d` is lagged debt-to-GDP, and `Z` is a
matrix of control variables.

## Usage

``` r
dk_bohn_test(
  primary_balance,
  debt,
  controls = NULL,
  method = c("ols", "rolling", "quadratic"),
  window = NULL,
  robust_se = FALSE
)
```

## Arguments

- primary_balance:

  Numeric vector of primary balance-to-GDP ratios.

- debt:

  Numeric vector of lagged debt-to-GDP ratios (same length as
  `primary_balance`).

- controls:

  Optional data.frame of control variables (same number of rows as
  `primary_balance`). Each column enters the regression as a separate
  regressor.

- method:

  Character; `"ols"` (default) for a single OLS regression over the full
  sample, `"rolling"` for rolling-window regressions, or `"quadratic"`
  for a non-linear specification that includes a squared debt term to
  detect fiscal fatigue (Ghosh et al. 2013).

- window:

  Integer; rolling window size. Required when `method = "rolling"`,
  ignored otherwise.

- robust_se:

  Logical; if `TRUE`, compute Newey-West HAC standard errors using a
  Bartlett kernel with automatic bandwidth `floor(4*(n/100)^(2/9))`.
  This corrects for serial correlation in fiscal data. Default `FALSE`.

## Value

An S3 object of class `dk_bohn` with components:

- rho:

  Estimated fiscal response coefficient (full sample or last rolling
  window).

- rho_se:

  Standard error of `rho`.

- rho_pvalue:

  p-value for the test H0: rho = 0.

- sustainable:

  Logical; `TRUE` if `rho > 0` and `rho_pvalue < 0.05`.

- model:

  The `lm` object from the full-sample (OLS/quadratic) or last-window
  (rolling) regression.

- method:

  The method used (`"ols"`, `"rolling"`, or `"quadratic"`).

- rho_ts:

  A data.frame with columns `index`, `rho`, `rho_lower`, `rho_upper` if
  `method = "rolling"`; `NULL` otherwise.

- robust_se:

  Logical; whether HAC standard errors were used.

- rho2:

  Coefficient on debt squared (only for `method = "quadratic"`).

- rho2_se:

  Standard error of `rho2` (quadratic only).

- rho2_pvalue:

  p-value for `rho2` (quadratic only).

- turning_point:

  Debt level where fiscal response peaks, `-rho/(2*rho2)` (quadratic
  only).

## Details

A positive and statistically significant `rho` indicates that the
government systematically raises the primary surplus in response to
rising debt, satisfying a sufficient condition for debt sustainability.

## References

Bohn, H. (1998). "The Behavior of U.S. Public Debt and Deficits."
*Quarterly Journal of Economics*, 113(3), 949–963.
[doi:10.1162/003355398555793](https://doi.org/10.1162/003355398555793)

Ghosh, A.R., Kim, J.I., Mendoza, E.G., Ostry, J.D. and Qureshi, M.S.
(2013). "Fiscal Fatigue, Fiscal Space and Debt Sustainability in
Advanced Economies." *The Economic Journal*, 123(566), F4–F30.

## Examples

``` r
# Simulate data with positive fiscal response
set.seed(42)
n <- 50
debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
pb <- 0.04 * debt + rnorm(n, 0, 0.005)
result <- dk_bohn_test(pb, debt)
print(result)
#> 
#> ── Bohn Fiscal Reaction Function ───────────────────────────────────────────────
#> • Method: ols
#> • Observations: 50
#> • rho = 0.0365 (SE = 0.0058, p = 8.47e-08)
#> ✔ Sustainable: rho > 0 and significant at 5% level.
```
