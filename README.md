# debtkit

<!-- badges: start -->
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

**debtkit** is an R package for government debt sustainability analysis. It answers the questions that finance ministries, central banks, and fiscal policy researchers ask every day: will the debt ratio stabilise or spiral? What happens if interest rates rise? How much fiscal adjustment is needed?

## Installation

```r
# install.packages("devtools")
devtools::install_github("charlescoverdale/debtkit")
```

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
```

---

## Why debt sustainability analysis?

Every government borrows. The question is whether the debt is on a sustainable path or heading for trouble. Debt sustainability analysis (DSA) is the standard framework for answering this, used by the IMF, the European Commission, treasuries, and central banks worldwide.

The core idea is the **debt dynamics equation**: next year's debt ratio depends on today's debt, the interest rate, GDP growth, and the government's primary balance (revenue minus non-interest spending). When interest rates exceed growth, debt tends to snowball. When growth exceeds interest rates, debt stabilises more easily.

In practice, DSA involves several connected analyses:

- **Debt projections.** Given current fiscal settings, where is the debt ratio heading? What primary balance would stabilise debt at its current level?
- **Historical decomposition.** What drove debt changes in the past: interest costs, growth, or fiscal policy?
- **Stress tests.** What happens under adverse scenarios (recession, interest rate spike, exchange rate shock)?
- **Stochastic simulations.** Instead of testing a few scenarios, simulate thousands of possible paths using estimated shock distributions. The result is a fan chart showing the range of plausible debt outcomes.
- **Fiscal reaction functions.** Does the government systematically respond to rising debt by tightening fiscal policy? This is the Bohn (1998) test for fiscal sustainability.
- **Sustainability gaps.** How much fiscal adjustment (in percentage points of GDP) is needed to hit a debt target? The European Commission's S1 and S2 indicators are the standard measures.

These analyses are well-established but tedious to implement from scratch. `debtkit` puts them all into clean R functions so you can go from raw fiscal data to a complete DSA in a few lines of code.

---

## Examples

### Project debt forward

Where is the debt ratio heading under current settings?

```r
library(debtkit)

proj <- dk_project(debt = 0.90, interest_rate = 0.04,
                   gdp_growth = 0.03, primary_balance = 0.01, horizon = 10)
proj
#> -- Debt Projection --
#> * Initial debt/GDP: 90%
#> * Terminal debt/GDP: 82.6%
#> * Debt-stabilising primary balance: 0.9%

plot(proj)
```

### Decompose historical debt changes

What drove the debt ratio over time: interest costs, growth, or the primary balance?

```r
d <- dk_sample_data()
decomp <- dk_decompose(d$debt, d$interest_rate, d$gdp_growth,
                        d$primary_balance, years = d$years)
plot(decomp)  # Stacked bar chart of contributions
```

### Stochastic fan chart

Simulate 1,000 possible debt paths using estimated shock distributions.

```r
d <- dk_sample_data()
shocks <- dk_estimate_shocks(d$gdp_growth, d$interest_rate, d$primary_balance)
fan <- dk_fan_chart(debt = 0.90, interest_rate = 0.035, gdp_growth = 0.03,
                    primary_balance = -0.01, shocks = shocks,
                    n_sim = 1000, horizon = 10, seed = 42)
plot(fan)  # Fan chart with 10th-90th percentile bands
```

### IMF stress tests

Run six standardised adverse scenarios (growth shock, interest rate shock, primary balance shock, combined, exchange rate, and contingent liabilities).

```r
stress <- dk_stress_test(debt = 0.90, interest_rate = 0.04,
                         gdp_growth = 0.03, primary_balance = 0.01)
plot(stress)
```

### Bohn fiscal reaction function

Does the government respond to rising debt by running larger surpluses? A positive, statistically significant coefficient means fiscal policy is stabilising.

```r
d <- dk_sample_data()
bohn <- dk_bohn_test(d$primary_balance, d$debt, robust_se = TRUE)
bohn
#> -- Bohn Fiscal Reaction Function (OLS) --
#> * rho (fiscal response): 0.15 (p = 0.02)
#> * Interpretation: Sustainable (rho > 0, p < 0.05)
```

### EC sustainability gaps

How much fiscal adjustment is needed? S1 measures the adjustment to reach 60% debt in 15 years. S2 measures the adjustment to stabilise debt indefinitely.

```r
dk_sustainability_gap(debt = 0.90, interest_rate = 0.04,
                      gdp_growth = 0.03, primary_balance = -0.01)
#> * S1 (reach 60% debt in 15y): 2.8 pp of GDP
#> * S2 (stabilise indefinitely): 1.9 pp of GDP
```

---

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

---

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

---

## Academic references

- Blanchard (1990). "Suggestions for a New Set of Fiscal Indicators." *OECD Working Papers*.
- Bohn (1998). "The Behavior of U.S. Public Debt and Deficits." *QJE*, 113(3).
- Ghosh et al. (2013). "Fiscal Fatigue, Fiscal Space and Debt Sustainability." *Economic Journal*, 123(566).
- IMF (2013). *Staff Guidance Note for Public Debt Sustainability Analysis*.
- IMF (2022). *Staff Guidance Note on the Sovereign Risk and Debt Sustainability Framework*.
- European Commission (2024). *Fiscal Sustainability Report*.

---

## Related packages

| Package | Description | CRAN |
|---------|-------------|------|
| [yieldcurves](https://github.com/charlescoverdale/yieldcurves) | Yield curve fitting and analysis | Coming soon |
| [inflationkit](https://github.com/charlescoverdale/inflationkit) | Inflation analysis and core measures | Coming soon |
| [fred](https://github.com/charlescoverdale/fred) | Federal Reserve Economic Data | [![CRAN](https://www.r-pkg.org/badges/version/fred)](https://cran.r-project.org/package=fred) |
| [readoecd](https://github.com/charlescoverdale/readoecd) | OECD data access | [![CRAN](https://www.r-pkg.org/badges/version/readoecd)](https://cran.r-project.org/package=readoecd) |

---

## Issues

Found a bug or have a feature request? Please [open an issue](https://github.com/charlescoverdale/debtkit/issues) on GitHub.

r, r-package, debt-sustainability, fiscal-policy, public-debt, macroeconomics, imf, sovereign-risk, fan-chart, stress-test
