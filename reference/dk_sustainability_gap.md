# S1 and S2 Sustainability Gap Indicators

Computes the S1 and S2 fiscal sustainability gap indicators used by the
European Commission to assess the size of the permanent budgetary
adjustment required to ensure debt sustainability.

## Usage

``` r
dk_sustainability_gap(
  debt,
  structural_balance,
  gdp_growth,
  interest_rate,
  ageing_costs = 0,
  target_debt = 0.6,
  target_year = 20,
  indicator = c("both", "S1", "S2")
)
```

## Arguments

- debt:

  Numeric scalar. Current debt-to-GDP ratio.

- structural_balance:

  Numeric scalar. Current structural primary balance as a share of GDP
  (positive = surplus).

- gdp_growth:

  Numeric scalar. Real GDP growth rate.

- interest_rate:

  Numeric scalar. Real interest rate.

- ageing_costs:

  Numeric scalar. Projected increase in age-related expenditure as
  percentage points of GDP. Default `0`.

- target_debt:

  Numeric scalar. Target debt-to-GDP ratio for S1. Default `0.60`.

- target_year:

  Integer scalar. Number of years to reach the target debt ratio.
  Default `20`.

- indicator:

  Character. Which indicator to compute: `"S1"`, `"S2"`, or `"both"`
  (default).

## Value

An S3 object of class `dk_sgap` containing:

- S1:

  The S1 sustainability gap (or `NA` if not requested).

- S2:

  The S2 sustainability gap (or `NA` if not requested).

- risk_S1:

  Risk classification for S1: `"low"`, `"medium"`, or `"high"`.

- risk_S2:

  Risk classification for S2: `"low"`, `"medium"`, or `"high"`.

- required_pb:

  The required structural primary balance implied by S1.

- current_pb:

  The current structural primary balance.

- inputs:

  A list storing all input parameters.

## Details

**S1** measures the permanent adjustment in the structural primary
balance needed to bring the debt-to-GDP ratio to `target_debt` in
`target_year` years, taking into account projected increases in
age-related expenditure.

**S2** measures the permanent adjustment needed to stabilise the
debt-to-GDP ratio over an infinite horizon, incorporating the full net
present value of future increases in age-related spending.

## References

European Commission (2012). *Fiscal Sustainability Report 2012*.
European Economy 8/2012, Directorate-General for Economic and Financial
Affairs.

## Examples

``` r
dk_sustainability_gap(
  debt = 0.90,
  structural_balance = -0.01,
  gdp_growth = 0.015,
  interest_rate = 0.025,
  ageing_costs = 0.02
)
#> 
#> ── Sustainability Gap Indicators ───────────────────────────────────────────────
#> • Current debt/GDP: 90%
#> • Current structural PB: -1%
#> • Interest rate: 2.5%
#> • GDP growth: 1.5%
#> 
#> 
#> ── S1 Indicator ──
#> 
#> • Required PB adjustment: 4.3 pp
#> • Required structural PB: 2.3%
#> • Target debt/GDP: 60% in 20 years
#>   Risk: MEDIUM
#> 
#> 
#> ── S2 Indicator ──
#> 
#> • Required PB adjustment: 204.9 pp
#> • Ageing costs: 2 pp
#>   Risk: HIGH
```
