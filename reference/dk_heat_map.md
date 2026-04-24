# IMF-Style Risk Heat Map

Classifies sovereign debt risk as low, medium, or high based on IMF
(2013) thresholds for debt-to-GDP, gross financing needs, and optional
debt-profile indicators. Advanced economies and emerging markets use
different thresholds.

## Usage

``` r
dk_heat_map(
  debt,
  gross_financing_needs,
  debt_profile = NULL,
  country_type = c("ae", "em")
)
```

## Arguments

- debt:

  Numeric scalar. Debt-to-GDP ratio.

- gross_financing_needs:

  Numeric scalar. Gross financing needs as a share of GDP.

- debt_profile:

  Optional named list of debt-profile indicators (all as ratios):

  share_st_debt

  :   Share of short-term debt in total debt.

  fx_share

  :   Share of foreign-currency-denominated debt.

  nonresident_share

  :   Share of debt held by non-residents.

  bank_share

  :   Share of debt held by domestic banks.

  change_st_debt

  :   Year-on-year change in the share of short-term debt (in percentage
      points of GDP).

- country_type:

  Character. Either `"ae"` (advanced economy, default) or `"em"`
  (emerging market).

## Value

An S3 object of class `dk_heatmap` containing:

- ratings:

  Named list of risk ratings (`"low"`, `"medium"`, or `"high"`) for each
  indicator.

- overall:

  Character. Overall risk level: `"high"` if any indicator is high,
  `"medium"` if any is medium, otherwise `"low"`.

- values:

  Named list of input values.

- thresholds:

  The thresholds used for classification.

- country_type:

  The country type used.

## References

International Monetary Fund (2013). *Staff Guidance Note for Public Debt
Sustainability Analysis in Market-Access Countries*. IMF Policy Paper.

International Monetary Fund (2022). *Staff Guidance Note on the
Sovereign Risk and Debt Sustainability Framework for Market Access
Countries*. IMF Policy Paper.

## Examples

``` r
hm <- dk_heat_map(
  debt = 0.90,
  gross_financing_needs = 0.18,
  debt_profile = list(fx_share = 0.30, share_st_debt = 0.15),
  country_type = "ae"
)
hm
#> 
#> ── IMF Risk Heat Map (Advanced Economy) ────────────────────────────────────────
#> 
#>   Debt / GDP                          90%    HIGH
#>   Gross financing needs / GDP         18%    MEDIUM
#>   Short-term debt share               15%    HIGH
#>   Foreign currency share              30%    HIGH
#> 
#> ────────────────────────────────────────────────────────────────────────────────
#>   Overall risk:                             HIGH
```
