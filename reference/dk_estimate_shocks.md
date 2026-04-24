# Estimate Joint Distribution of Macro Shocks

Estimates the joint distribution of GDP growth, interest rate, and
primary balance shocks for use in stochastic debt sustainability
analysis. Three estimation methods are supported: a VAR(1) model
(default), residual bootstrap, and a simple multivariate normal fit.

## Usage

``` r
dk_estimate_shocks(
  gdp_growth,
  interest_rate,
  primary_balance,
  method = c("var", "bootstrap", "normal"),
  years = NULL
)
```

## Arguments

- gdp_growth:

  Numeric vector of historical real GDP growth rates.

- interest_rate:

  Numeric vector of historical nominal (or real) interest rates.

- primary_balance:

  Numeric vector of historical primary balance-to-GDP ratios.

- method:

  Character; one of `"var"` (default), `"bootstrap"`, or `"normal"`.

- years:

  Optional numeric vector of year labels (same length as data).

## Value

An S3 object of class `dk_shocks` with components:

- vcov:

  3x3 variance-covariance matrix with rows/columns named `growth`,
  `interest_rate`, `primary_balance`.

- means:

  Named numeric vector of variable means.

- method:

  The estimation method used.

- residuals:

  Matrix of residuals (for `"var"` and `"bootstrap"`) or `NULL` (for
  `"normal"`).

- var_coefficients:

  VAR(1) coefficient matrix (for `"var"`) or `NULL`.

- n_obs:

  Number of observations used.

## Details

For `method = "var"`, a VAR(1) is estimated equation-by-equation via OLS
on the lagged system. The residual variance-covariance matrix captures
the joint shock distribution. For `method = "bootstrap"`, the same
VAR(1) is estimated and residuals are stored for block resampling. For
`method = "normal"`, the sample means and covariance of the raw series
are used directly.

## Examples

``` r
set.seed(1)
n <- 30
g <- rnorm(n, 0.02, 0.015)
r <- rnorm(n, 0.03, 0.01)
pb <- rnorm(n, -0.02, 0.01)
shocks <- dk_estimate_shocks(g, r, pb)
print(shocks)
#> 
#> ── Macro Shock Estimates ───────────────────────────────────────────────────────
#> • Method: var
#> • Observations: 29
#> • Variable means:
#>     growth = 2.1%, interest_rate = 3.1%, primary_balance = -1.9%
#> • Shock std. deviations:
#>     growth = 1.4 pp, interest_rate = 0.8 pp, primary_balance = 0.9 pp
#> • Shock correlation matrix:
#>                 growth interest_rate primary_balance
#> growth           1.000         0.068           0.041
#> interest_rate    0.068         1.000           0.388
#> primary_balance  0.041         0.388           1.000
```
