# debtkit

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

**Government debt sustainability analysis for R.**

To our knowledge, `debtkit` is the first open-source R package for comprehensive debt sustainability analysis.

## Why does this package exist?

Every central bank, finance ministry, and international institution runs debt sustainability analysis (DSA). The IMF does it for every country it reviews. The European Commission does it to enforce fiscal rules. Rating agencies do it to assess sovereign creditworthiness. Academic economists do it to study fiscal policy.

Yet there is no standard tool for this. Analysts typically work in Excel spreadsheets or write one-off scripts that implement the same equations from scratch. The result is duplicated effort, inconsistent implementations, and analyses that are hard to reproduce.

The core question in DSA is deceptively simple: *will the government be able to pay its debts?* But answering it rigorously requires chaining together several pieces of non-trivial analysis:

- **Debt dynamics projections.** The debt-to-GDP ratio evolves according to `d(t+1) = [(1+r)/(1+g)] * d(t) - pb(t)`, where `r` is the interest rate, `g` is GDP growth, and `pb` is the primary balance. Small differences in r-g compound dramatically over a 10-year horizon.

- **Historical decomposition.** What drove debt changes in the past? Was it high interest rates, slow growth, large deficits, or one-off events (bank bailouts, exchange rate shocks)? This requires separating the snowball effect `(r-g)/(1+g) * d` from discretionary fiscal policy.

- **Fiscal reaction functions.** Does the government systematically raise surpluses when debt rises? Bohn (1998) showed this is a sufficient condition for sustainability. Estimating the fiscal response coefficient `rho` requires regression analysis with appropriate controls.

- **Stochastic simulations.** Deterministic projections assume you know the future. In reality, growth, interest rates, and fiscal policy are all uncertain. Fan charts show the distribution of possible debt paths by drawing correlated shocks from historical data.

- **Stress tests.** What happens if growth drops by 1pp? If interest rates spike 200bp? If a banking crisis adds 10% of GDP to public debt? The IMF defines six standardised scenarios.

- **Sustainability gaps.** The European Commission's S1 and S2 indicators measure how much fiscal adjustment is needed to bring debt to 60% of GDP (S1) or stabilise it over an infinite horizon (S2).

`debtkit` puts all of this into clean, tested R functions that work together. You bring fiscal data from any source (the IMF, OECD, your own government's statistics) and the package handles the analysis.

## Installation

Install the development version from GitHub:

```r
# install.packages("devtools")
devtools::install_github("charlescoverdale/debtkit")
```

## Quick start

The package includes built-in sample data so you can try everything immediately, with no data download required.

```r
library(debtkit)

# Built-in sample data: 20 years of fiscal history for a synthetic country
d <- dk_sample_data()
str(d)
#> List of 5
#>  $ years          : int [1:20] 2004 2005 2006 ... 2023
#>  $ debt           : num [1:20] 0.45 0.44 0.42 ... 0.69
#>  $ interest_rate  : num [1:20] 0.045 0.043 0.042 ... 0.038
#>  $ gdp_growth     : num [1:20] 0.055 0.050 0.060 ... 0.040
#>  $ primary_balance: num [1:20] 0.010 0.012 0.015 ... -0.005
```

### Conventions

All values are expressed as **decimals**:

- `debt = 0.90` means 90% of GDP
- `interest_rate = 0.04` means 4%
- `primary_balance = 0.01` means a 1% of GDP **surplus**; `-0.03` means a 3% **deficit**

The sign convention follows the standard in public finance: **positive primary balance = surplus, negative = deficit**.

## Examples

### Project a debt path

```r
library(debtkit)

# Start with 90% debt-to-GDP, project 10 years forward
proj <- dk_project(
  debt = 0.90,
  interest_rate = 0.04,   # 4% effective interest rate
  gdp_growth = 0.03,      # 3% nominal GDP growth
  primary_balance = 0.01, # 1% of GDP primary surplus
  horizon = 10
)
proj
#> -- Debt Projection --
#> * Horizon: 10 years
#> * Initial debt/GDP: 90%
#> * Terminal debt/GDP: 82.6%     <-- debt falls because surplus > stabilising PB
#> * Debt-stabilising primary balance: 0.9%

plot(proj)
```

### Decompose historical debt changes

What drove debt up or down in each year? The decomposition separates the automatic "snowball" effect of interest and growth from discretionary fiscal policy.

```r
d <- dk_sample_data()
decomp <- dk_decompose(d$debt, d$interest_rate, d$gdp_growth,
                        d$primary_balance, years = d$years)
decomp
#> -- Debt Decomposition --
#> * Period: 2005 to 2023 (19 years)
#> * Total debt change: +24 pp
#> * Interest effect: +55.4 pp     <-- interest payments pushed debt up
#> * Growth effect: -59.6 pp       <-- GDP growth reduced the ratio
#> * Primary balance: +19.5 pp     <-- deficits added to debt on net
#> * Stock-flow adjustment: +8.7 pp

plot(decomp)  # Stacked bar chart showing what drove debt changes each year
```

### Stochastic fan chart

Deterministic projections assume you know the future. Fan charts show the range of possible outcomes by running thousands of simulations with random shocks.

```r
d <- dk_sample_data()

# Estimate shock distribution from historical data
shocks <- dk_estimate_shocks(d$gdp_growth, d$interest_rate, d$primary_balance)

# Monte Carlo simulation: 1000 paths, 10 years forward
fan <- dk_fan_chart(
  debt = 0.90,
  interest_rate = 0.035,
  gdp_growth = 0.03,
  primary_balance = -0.01, # Starting from a 1% deficit
  shocks = shocks,
  n_sim = 1000,
  horizon = 10,
  seed = 42
)
fan
#> -- Stochastic Debt Fan Chart --
#> * Simulations: 1000
#> * Horizon: 10 years
#> * Initial debt: 90% of GDP
#> * Baseline terminal debt: 103.8% of GDP
#> * Median terminal debt: 103.5% of GDP
#> * Probability debt exceeds thresholds at horizon:
#>     60% of GDP: 100%
#>     90% of GDP: 95.3%
#>     120% of GDP: 12.8%

plot(fan)  # Fan chart with shaded confidence bands
```

### IMF stress tests

Six standardised scenarios that test how debt responds to adverse shocks.

```r
stress <- dk_stress_test(
  debt = 0.90,
  interest_rate = 0.04,
  gdp_growth = 0.03,
  primary_balance = 0.01,
  horizon = 5
)
stress
#> -- IMF Stress Tests --
#> * Baseline terminal debt: 86.3%
#> * Scenarios (terminal debt/GDP):
#>     Growth shock: 95.2%
#>     Interest rate shock: 91.7%
#>     Exchange rate shock: 95.8%
#>     Primary balance shock: 90.8%
#>     Combined shock: 101.4%
#>     Contingent liability: 96.3%

plot(stress)  # Six scenarios on one chart

# Calibrate shock sizes from historical data instead of using fixed defaults
d <- dk_sample_data()
stress_cal <- dk_stress_test(
  debt = 0.90,
  interest_rate = 0.04,
  gdp_growth = 0.03,
  primary_balance = 0.01,
  calibrate = list(
    gdp_growth_hist = d$gdp_growth,
    interest_rate_hist = d$interest_rate,
    primary_balance_hist = d$primary_balance
  )
)
```

### Test fiscal sustainability (Bohn regression)

Does the government systematically raise surpluses when debt rises? A positive and statistically significant `rho` suggests the government responds to rising debt with fiscal discipline, a necessary condition for long-run sustainability.

```r
d <- dk_sample_data()
bohn <- dk_bohn_test(d$primary_balance, d$debt)
bohn
#> -- Bohn Fiscal Reaction Function (OLS) --
#> * rho (fiscal response): 0.15 (p = 0.02)
#> * Interpretation: Sustainable (rho > 0, p < 0.05)

# Use HAC (Newey-West) standard errors to correct for serial correlation
bohn_hac <- dk_bohn_test(d$primary_balance, d$debt, robust_se = TRUE)
```

### Detect fiscal fatigue (quadratic Bohn test)

At high debt levels, governments may lose the ability or willingness to raise surpluses further. The quadratic specification (Ghosh et al. 2013) tests for this by including a squared debt term. A negative and significant coefficient on the squared term indicates fiscal fatigue: the fiscal response weakens as debt rises, with a turning point beyond which it reverses.

```r
d <- dk_sample_data()
fatigue <- dk_bohn_test(d$primary_balance, d$debt, method = "quadratic")
fatigue
#> -- Bohn Fiscal Reaction Function --
#> * Method: quadratic
#> * rho (linear debt term): 0.45 (p = 0.01)
#> * rho2 (squared debt term): -0.003 (p = 0.04)
#> * Turning point (debt/GDP): 0.75
#> * Fiscal fatigue detected: negative and significant rho2.
```

### EC sustainability gaps

How much does fiscal policy need to adjust to put debt on a sustainable path?

```r
dk_sustainability_gap(
  debt = 0.90,
  interest_rate = 0.04,
  gdp_growth = 0.03,
  primary_balance = -0.01
)
#> -- Sustainability Gap Indicators --
#> * S1 (adjustment to reach 60% debt in 15y): 2.8 pp of GDP
#> * S2 (adjustment to stabilise debt indefinitely): 1.9 pp of GDP
```

## Where do I get fiscal data?

`debtkit` is a pure computation package. It does not download data. You supply vectors of debt ratios, interest rates, growth rates, and primary balances as decimals. Common sources:

| Source | Coverage | Free? | How to get into R | Key variables |
|--------|----------|-------|-------------------|---------------|
| IMF World Economic Outlook | 190+ countries | Yes | Download CSV from imf.org | GGXWDG_NGDP (debt), NGDP_RPCH (growth) |
| IMF Fiscal Monitor | 190+ countries | Yes | Download CSV from imf.org | GGR_NGDP (revenue), GGX_NGDP (expenditure) |
| OECD Economic Outlook | 38 OECD members | Yes | [readoecd](https://cran.r-project.org/package=readoecd) | GGFLQ (debt), NLGQ (net lending) |
| FRED (US) | United States | Yes | [fred](https://cran.r-project.org/package=fred) | FYFSGDA188S (surplus), GFDEGDQ188S (debt) |
| Eurostat | EU members | Yes | eurostat package | gov_10dd_edpt1 |
| World Bank WDI | 200+ countries | Yes | WDI package | GC.DOD.TOTL.GD.ZS (debt) |
| AMECO (EC) | EU members | Yes | Download from ec.europa.eu | UDGG (debt), UBLG (balance) |

Or just type your data in directly. All you need are numeric vectors:

```r
# Your own data
proj <- dk_project(
  debt = 0.65,           # 65% of GDP
  interest_rate = 0.035,  # 3.5%
  gdp_growth = 0.045,     # 4.5%
  primary_balance = -0.02, # 2% deficit
  horizon = 10
)
```

## Functions

| Function | Description |
|----------|-------------|
| `dk_project()` | Project debt-to-GDP paths forward |
| `dk_decompose()` | Decompose historical debt changes |
| `dk_rg()` | Interest rate-growth differential |
| `dk_bohn_test()` | Bohn fiscal reaction function (OLS, rolling, quadratic; optional HAC SEs) |
| `dk_estimate_shocks()` | Estimate shock distributions (VAR, bootstrap, normal) |
| `dk_fan_chart()` | Stochastic debt fan charts (multivariate normal or bootstrap resampling) |
| `dk_stress_test()` | Six standardised IMF stress tests (fixed or data-driven calibration) |
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
