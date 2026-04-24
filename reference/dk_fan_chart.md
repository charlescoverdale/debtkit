# Stochastic Debt Fan Chart

Projects debt-to-GDP paths via Monte Carlo simulation using the standard
debt dynamics equation. At each step, correlated shocks to growth, the
interest rate, and the primary balance are drawn from a multivariate
normal distribution and added to the baseline paths. The result is a fan
chart showing the distribution of projected debt paths.

## Usage

``` r
dk_fan_chart(
  debt,
  interest_rate,
  gdp_growth,
  primary_balance,
  shocks = NULL,
  shock_vcov = NULL,
  n_sim = 1000L,
  horizon = 5L,
  confidence = c(0.1, 0.25, 0.5, 0.75, 0.9),
  seed = NULL
)
```

## Arguments

- debt:

  Numeric scalar; initial debt-to-GDP ratio.

- interest_rate:

  Numeric scalar or vector of length `horizon`; baseline interest rate
  path.

- gdp_growth:

  Numeric scalar or vector of length `horizon`; baseline GDP growth
  path.

- primary_balance:

  Numeric scalar or vector of length `horizon`; baseline primary
  balance-to-GDP path.

- shocks:

  A `dk_shocks` object (from
  [`dk_estimate_shocks()`](https://charlescoverdale.github.io/debtkit/reference/dk_estimate_shocks.md))
  providing the shock distribution, or `NULL`.

- shock_vcov:

  Optional 3x3 variance-covariance matrix (alternative to `shocks`).
  Rows/columns ordered: growth, interest_rate, primary_balance. Ignored
  if `shocks` is provided.

- n_sim:

  Integer; number of Monte Carlo simulations (default 1000).

- horizon:

  Integer; projection horizon in years (default 5).

- confidence:

  Numeric vector of quantile levels for fan bands (default
  `c(0.10, 0.25, 0.50, 0.75, 0.90)`).

- seed:

  Optional integer seed for reproducibility.

## Value

An S3 object of class `dk_fan` with components:

- simulations:

  Matrix of dimension `n_sim` x (`horizon` + 1) containing all simulated
  debt paths.

- quantiles:

  Matrix of quantiles at each time step, with rows corresponding to the
  `confidence` levels.

- baseline:

  Numeric vector of length `horizon` + 1; the deterministic baseline
  debt path.

- confidence:

  The quantile levels used.

- horizon:

  The projection horizon.

- prob_above:

  Named list with the probability of debt exceeding 60 percent, 90
  percent, and 120 percent of GDP at the terminal year.

## Examples

``` r
set.seed(1)
n <- 30
g <- rnorm(n, 0.02, 0.015)
r <- rnorm(n, 0.03, 0.01)
pb <- rnorm(n, -0.02, 0.01)
shocks <- dk_estimate_shocks(g, r, pb)

fan <- dk_fan_chart(
  debt = 0.90,
  interest_rate = 0.03,
  gdp_growth = 0.02,
  primary_balance = -0.02,
  shocks = shocks,
  n_sim = 500,
  horizon = 10,
  seed = 42
)
print(fan)
#> 
#> ── Stochastic Debt Fan Chart ───────────────────────────────────────────────────
#> • Simulations: 500
#> • Horizon: 10 years
#> • Initial debt: 90% of GDP
#> • Baseline terminal debt: 120.1% of GDP
#> • Median terminal debt: 120.3% of GDP
#> • Probability debt exceeds thresholds at horizon:
#>     60% of GDP: 100%
#>     90% of GDP: 100%
#>     120% of GDP: 51.6%
```
