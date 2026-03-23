# debtkit

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

**Government debt sustainability analysis for R.**

`debtkit` provides the standard toolkit for debt sustainability analysis (DSA): debt projections, historical decomposition, fiscal reaction functions, stochastic fan charts, IMF stress tests, and EC sustainability gaps. All inputs are decimals (`0.90` = 90% of GDP). Positive primary balance = surplus.

## Installation

```r
# install.packages("devtools")
devtools::install_github("charlescoverdale/debtkit")
```

## Examples

```r
library(debtkit)

# Project debt forward 10 years
proj <- dk_project(debt = 0.90, interest_rate = 0.04,
                   gdp_growth = 0.03, primary_balance = 0.01, horizon = 10)
proj
#> -- Debt Projection --
#> * Initial debt/GDP: 90%
#> * Terminal debt/GDP: 82.6%
#> * Debt-stabilising primary balance: 0.9%

# Decompose what drove debt changes historically
d <- dk_sample_data()
decomp <- dk_decompose(d$debt, d$interest_rate, d$gdp_growth,
                        d$primary_balance, years = d$years)
plot(decomp)

# Stochastic fan chart (Monte Carlo with correlated shocks)
shocks <- dk_estimate_shocks(d$gdp_growth, d$interest_rate, d$primary_balance)
fan <- dk_fan_chart(debt = 0.90, interest_rate = 0.035, gdp_growth = 0.03,
                    primary_balance = -0.01, shocks = shocks,
                    n_sim = 1000, horizon = 10, seed = 42)
plot(fan)

# IMF stress tests (six standardised scenarios)
stress <- dk_stress_test(debt = 0.90, interest_rate = 0.04,
                         gdp_growth = 0.03, primary_balance = 0.01)
plot(stress)

# Bohn fiscal reaction function
bohn <- dk_bohn_test(d$primary_balance, d$debt, robust_se = TRUE)
bohn
#> -- Bohn Fiscal Reaction Function (OLS) --
#> * rho (fiscal response): 0.15 (p = 0.02)
#> * Interpretation: Sustainable (rho > 0, p < 0.05)

# EC sustainability gaps
dk_sustainability_gap(debt = 0.90, interest_rate = 0.04,
                      gdp_growth = 0.03, primary_balance = -0.01)
#> * S1 (reach 60% debt in 15y): 2.8 pp of GDP
#> * S2 (stabilise indefinitely): 1.9 pp of GDP
```

## Where do I get fiscal data?

`debtkit` does not download data. You supply numeric vectors. Common sources:

| Source | Coverage | How to get into R |
|--------|----------|-------------------|
| IMF WEO | 190+ countries | Download CSV from imf.org |
| OECD | 38 members | [readoecd](https://cran.r-project.org/package=readoecd) |
| FRED (US) | United States | [fred](https://cran.r-project.org/package=fred) |
| Eurostat | EU members | eurostat package |
| World Bank | 200+ countries | WDI package |

Or use the built-in sample data: `dk_sample_data()`.

## Functions

| Function | Description |
|----------|-------------|
| `dk_project()` | Project debt-to-GDP paths forward |
| `dk_decompose()` | Decompose historical debt changes |
| `dk_rg()` | Interest rate-growth differential |
| `dk_bohn_test()` | Bohn fiscal reaction function (OLS, rolling, quadratic; optional HAC SEs) |
| `dk_estimate_shocks()` | Estimate shock distributions (VAR, bootstrap, normal) |
| `dk_fan_chart()` | Stochastic debt fan charts |
| `dk_stress_test()` | IMF stress tests (fixed or data-driven calibration) |
| `dk_heat_map()` | IMF-style risk heat map |
| `dk_gfn()` | Gross financing needs |
| `dk_sustainability_gap()` | EC S1/S2 sustainability gap indicators |
| `dk_compare()` | Compare multiple projection scenarios |
| `dk_sample_data()` | Built-in sample fiscal data |

## Academic references

- Blanchard (1990). "Suggestions for a New Set of Fiscal Indicators." *OECD Working Papers*.
- Bohn (1998). "The Behavior of U.S. Public Debt and Deficits." *QJE*, 113(3).
- Ghosh et al. (2013). "Fiscal Fatigue, Fiscal Space and Debt Sustainability." *Economic Journal*, 123(566).
- IMF (2013). *Staff Guidance Note for Public Debt Sustainability Analysis*.
- IMF (2022). *Staff Guidance Note on the Sovereign Risk and Debt Sustainability Framework*.
- European Commission (2024). *Fiscal Sustainability Report*.

## Related packages

| Package | Description | CRAN |
|---------|-------------|------|
| [yieldcurves](https://github.com/charlescoverdale/yieldcurves) | Yield curve fitting and analysis | Coming soon |
| [fred](https://github.com/charlescoverdale/fred) | Federal Reserve Economic Data | [![CRAN](https://www.r-pkg.org/badges/version/fred)](https://cran.r-project.org/package=fred) |
| [readoecd](https://github.com/charlescoverdale/readoecd) | OECD data access | [![CRAN](https://www.r-pkg.org/badges/version/readoecd)](https://cran.r-project.org/package=readoecd) |

r, r-package, debt-sustainability, fiscal-policy, public-debt, macroeconomics, imf, sovereign-risk, fan-chart, stress-test
