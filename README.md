# debtkit

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

**Government debt sustainability analysis for R.**

## Why does this package exist?

Every central bank, finance ministry, and international institution runs debt sustainability analysis (DSA). The IMF does it for every country it reviews. The European Commission does it to enforce fiscal rules. Rating agencies do it to assess sovereign creditworthiness. Academic economists do it to study fiscal policy.

Yet there is no standard tool for this. Analysts typically work in Excel spreadsheets or write one-off scripts that implement the same equations from scratch. The result: duplicated effort, inconsistent implementations, and analyses that are hard to reproduce.

The core question in DSA is deceptively simple: *will the government be able to pay its debts?* But answering it rigorously requires chaining together several pieces of non-trivial analysis:

- **Debt dynamics projections** — The debt-to-GDP ratio evolves according to `d(t+1) = [(1+r)/(1+g)] * d(t) - pb(t)`, where `r` is the interest rate, `g` is GDP growth, and `pb` is the primary balance. Small differences in r-g compound dramatically over a 10-year horizon.

- **Historical decomposition** — What drove debt changes in the past? Was it high interest rates, slow growth, large deficits, or one-off events (bank bailouts, exchange rate shocks)? This requires separating the snowball effect `(r-g)/(1+g) * d` from discretionary fiscal policy.

- **Fiscal reaction functions** — Does the government systematically raise surpluses when debt rises? Bohn (1998) showed this is a sufficient condition for sustainability. Estimating the fiscal response coefficient `rho` requires regression analysis with appropriate controls.

- **Stochastic simulations** — Deterministic projections assume you know the future. In reality, growth, interest rates, and fiscal policy are all uncertain. Fan charts show the distribution of possible debt paths by drawing correlated shocks from historical data.

- **Stress tests** — What happens if growth drops by 1pp? If interest rates spike 200bp? If a banking crisis adds 10% of GDP to public debt? The IMF defines six standardised scenarios.

- **Sustainability gaps** — The European Commission's S1 and S2 indicators measure how much fiscal adjustment is needed to bring debt to 60% of GDP (S1) or stabilise it over an infinite horizon (S2).

`debtkit` puts all of this into clean, tested R functions that work together. You bring fiscal data from any source — the IMF, OECD, your own government's statistics — and the package handles the analysis.

## Where do I get fiscal data?

`debtkit` is a pure computation package — it does not download data. You supply vectors of debt ratios, interest rates, growth rates, and primary balances. Common sources:

| Source | Coverage | Free? | How to get into R |
|--------|----------|-------|-------------------|
| IMF World Economic Outlook | 190+ countries | Yes | Download CSV from imf.org |
| IMF Fiscal Monitor | 190+ countries | Yes | Download CSV from imf.org |
| OECD Economic Outlook | 38 OECD members | Yes | [readoecd](https://cran.r-project.org/package=readoecd) |
| FRED (US) | United States | Yes | [fred](https://cran.r-project.org/package=fred) |
| Eurostat | EU members | Yes | eurostat package |
| World Bank WDI | 200+ countries | Yes | WDI package |
| AMECO (EC) | EU members | Yes | Download from ec.europa.eu |

Or just type your data in directly — all you need are numeric vectors.

## Installation

Install the development version from GitHub:

```r
# install.packages("devtools")
devtools::install_github("charlescoverdale/debtkit")
```

## Examples

### Project a debt path

```r
library(debtkit)

# Start with 90% debt-to-GDP, project 10 years forward
proj <- dk_project(
  debt = 0.90,
  interest_rate = 0.04,
  gdp_growth = 0.03,
  primary_balance = 0.01,
  horizon = 10
)
proj
#> -- Debt Projection --
#> * Horizon: 10 years
#> * Initial debt/GDP: 90%
#> * Terminal debt/GDP: 82.6%
#> * Debt-stabilising primary balance: 0.9%

plot(proj)
```

### Decompose historical debt changes

```r
d <- dk_sample_data()
decomp <- dk_decompose(d$debt, d$interest_rate, d$gdp_growth,
                        d$primary_balance, years = d$years)
plot(decomp)  # Stacked bar chart showing what drove debt changes
```

### Stochastic fan chart

```r
# Estimate shock distribution from historical data
shocks <- dk_estimate_shocks(d$gdp_growth, d$interest_rate, d$primary_balance)

# Monte Carlo simulation
fan <- dk_fan_chart(
  debt = 0.90,
  interest_rate = 0.035,
  gdp_growth = 0.03,
  primary_balance = -0.01,
  shocks = shocks,
  n_sim = 1000,
  horizon = 10,
  seed = 42
)
plot(fan)  # Fan chart with confidence bands
```

### IMF stress tests

```r
stress <- dk_stress_test(
  debt = 0.90,
  interest_rate = 0.04,
  gdp_growth = 0.03,
  primary_balance = 0.01,
  horizon = 5
)
plot(stress)  # Six scenarios on one chart
```

### Test fiscal sustainability (Bohn regression)

```r
d <- dk_sample_data()
bohn <- dk_bohn_test(d$primary_balance, d$debt)
bohn
#> -- Bohn Fiscal Reaction Function (OLS) --
#> * rho (fiscal response): 0.15 (p = 0.02)
#> * Interpretation: Sustainable (rho > 0, p < 0.05)
```

## Functions

| Function | Description |
|----------|-------------|
| `dk_project()` | Project debt-to-GDP paths forward |
| `dk_decompose()` | Decompose historical debt changes |
| `dk_rg()` | Interest rate-growth differential |
| `dk_bohn_test()` | Bohn fiscal reaction function |
| `dk_estimate_shocks()` | Estimate shock distributions for stochastic DSA |
| `dk_fan_chart()` | Stochastic debt fan charts |
| `dk_stress_test()` | Six standardised IMF stress tests |
| `dk_heat_map()` | IMF-style risk heat map |
| `dk_gfn()` | Gross financing needs |
| `dk_sustainability_gap()` | EC S1/S2 sustainability gap indicators |
| `dk_compare()` | Compare multiple projection scenarios |
| `dk_sample_data()` | Built-in sample fiscal data |

## Academic references

The package implements methods from:

- Blanchard, O.J. (1990). "Suggestions for a New Set of Fiscal Indicators." *OECD Economics Department Working Papers*.
- Bohn, H. (1998). "The Behavior of U.S. Public Debt and Deficits." *Quarterly Journal of Economics*, 113(3), 949-963.
- Celasun, O., Debrun, X. & Ostry, J. (2006). "Primary Surplus Behavior and Risks to Fiscal Sustainability in Emerging Market Countries." *IMF Staff Papers*, 53(3).
- Ghosh, A.R. et al. (2013). "Fiscal Fatigue, Fiscal Space and Debt Sustainability in Advanced Economies." *Economic Journal*, 123(566).
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
