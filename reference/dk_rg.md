# Interest Rate-Growth Differential and Debt-Stabilising Primary Balance

Computes the interest rate-growth differential (\\r - g\\), a key
indicator of debt sustainability. When \\r \> g\\, debt grows faster
than the economy (the "snowball effect" is adverse) and a primary
surplus is needed to stabilise the debt ratio. When \\r \< g\\, the
government can run a primary deficit and still see the debt ratio fall.

## Usage

``` r
dk_rg(interest_rate, gdp_growth, inflation = NULL, debt = NULL)
```

## Arguments

- interest_rate:

  Numeric. Effective nominal interest rate on government debt. Scalar or
  vector.

- gdp_growth:

  Numeric. Nominal GDP growth rate. Scalar or vector (same length as
  `interest_rate`).

- inflation:

  Numeric or `NULL`. If supplied, the inflation rate used to compute the
  real \\r - g\\. Scalar or same length as `interest_rate`. Default
  `NULL`.

- debt:

  Numeric or `NULL`. If supplied, the debt-to-GDP ratio used to compute
  the debt-stabilising primary balance. Scalar or same length as
  `interest_rate`. Default `NULL`.

## Value

A named list with:

- rg_differential:

  Numeric vector. The nominal \\r - g\\ differential.

- real_rg:

  Numeric vector. The real \\r - g\\ differential. Only present if
  `inflation` was supplied.

- debt_stabilising_pb:

  Numeric vector. The debt-stabilising primary balance as a share of
  GDP. Only present if `debt` was supplied.

## Details

If `debt` is supplied, the function also computes the **debt-stabilising
primary balance**: the primary surplus (as a share of GDP) required to
hold the debt-to-GDP ratio constant at its current level. This is given
by:

\$\$pb^\* = \frac{r - g}{1 + g} \cdot d\$\$

If `inflation` is supplied, the function computes the **real** \\r - g\\
differential by deflating both the interest rate and GDP growth:
\\r\_{real} = (1 + r)/(1 + \pi) - 1\\ and \\g\_{real} = (1 + g)/(1 +
\pi) - 1\\.

## References

Blanchard, O.J. (1990). Suggestions for a New Set of Fiscal Indicators.
*OECD Economics Department Working Papers*, No. 79.
[doi:10.1787/budget-v2-art12-en](https://doi.org/10.1787/budget-v2-art12-en)

Barrett, P. (2018). Interest-Growth Differentials and Debt Limits in
Advanced Economies. *IMF Working Paper*, WP/18/82.

## Examples

``` r
# Simple scalar case
dk_rg(interest_rate = 0.04, gdp_growth = 0.03)
#> $rg_differential
#> [1] 0.01
#> 

# With debt: compute stabilising primary balance
dk_rg(interest_rate = 0.04, gdp_growth = 0.03, debt = 0.90)
#> $rg_differential
#> [1] 0.01
#> 
#> $debt_stabilising_pb
#> [1] 0.008737864
#> 

# With inflation: compute real r-g
dk_rg(interest_rate = 0.04, gdp_growth = 0.05, inflation = 0.02)
#> $rg_differential
#> [1] -0.01
#> 
#> $real_rg
#> [1] -0.009803922
#> 

# Vector case using sample data
d <- dk_sample_data()
dk_rg(
  interest_rate = d$interest_rate,
  gdp_growth = d$gdp_growth,
  debt = d$debt
)
#> $rg_differential
#>  [1] -0.010 -0.007 -0.018 -0.001  0.060  0.005 -0.002 -0.010 -0.010 -0.017
#> [11] -0.023 -0.015 -0.022 -0.022 -0.028  0.050 -0.047 -0.030 -0.010 -0.002
#> 
#> $debt_stabilising_pb
#>  [1] -0.0042654028 -0.0029333333 -0.0071320755 -0.0003923445  0.0336734694
#>  [6]  0.0029126214 -0.0011980676 -0.0057692308 -0.0055876686 -0.0091362764
#> [11] -0.0121052632 -0.0078260870 -0.0116346154 -0.0111900192 -0.0138666667
#> [16]  0.0373056995 -0.0330985915 -0.0207582938 -0.0067942584 -0.0013269231
#> 
```
