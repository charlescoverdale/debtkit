# Gross Financing Needs

Computes gross financing needs (GFN) as a share of GDP over a projection
horizon. GFN represents the total amount of new borrowing a government
requires each year to cover its primary deficit, interest payments, and
maturing debt:

## Usage

``` r
dk_gfn(debt, interest_rate, maturity_profile, primary_balance, horizon = 5)
```

## Arguments

- debt:

  Numeric scalar. Initial debt-to-GDP ratio.

- interest_rate:

  Numeric scalar or vector of length `horizon`. Effective nominal
  interest rate on government debt.

- maturity_profile:

  Numeric vector or scalar. If a vector, gives the share of GDP maturing
  in each year of the horizon. If a scalar, interpreted as the average
  maturity in years; debt is assumed to mature uniformly at
  `debt / maturity_profile` per year.

- primary_balance:

  Numeric scalar or vector of length `horizon`. Primary balance as a
  share of GDP (positive = surplus).

- horizon:

  Integer scalar. Projection horizon in years. Default `5`.

## Value

A `data.frame` with columns:

- year:

  Year index (1 to `horizon`).

- primary_deficit:

  Primary deficit (negative of primary balance).

- interest_payments:

  Interest payments as a share of GDP.

- maturing_debt:

  Maturing debt as a share of GDP.

- gfn:

  Total gross financing needs as a share of GDP.

## Details

\$\$GFN_t = -pb_t + r_t \cdot d_t + m_t\$\$

where \\pb\\ is the primary balance (positive = surplus), \\r\\ is the
effective interest rate, \\d\\ is debt-to-GDP, and \\m\\ is maturing
debt as a share of GDP.

## References

International Monetary Fund (2013). *Staff Guidance Note for Public Debt
Sustainability Analysis in Market-Access Countries*. IMF Policy Paper.

## Examples

``` r
# Scalar average maturity of 7 years
dk_gfn(debt = 0.90, interest_rate = 0.03,
       maturity_profile = 7, primary_balance = -0.02)
#>   year primary_deficit interest_payments maturing_debt       gfn
#> 1    1            0.02        0.02700000     0.1285714 0.1755714
#> 2    2            0.02        0.02841000     0.1285714 0.1769814
#> 3    3            0.02        0.02986230     0.1285714 0.1784337
#> 4    4            0.02        0.03135817     0.1285714 0.1799296
#> 5    5            0.02        0.03289891     0.1285714 0.1814703

# Explicit maturity profile
dk_gfn(debt = 0.90, interest_rate = 0.03,
       maturity_profile = c(0.15, 0.12, 0.10, 0.08, 0.05),
       primary_balance = -0.02)
#>   year primary_deficit interest_payments maturing_debt       gfn
#> 1    1            0.02        0.02700000          0.15 0.1970000
#> 2    2            0.02        0.02841000          0.12 0.1684100
#> 3    3            0.02        0.02986230          0.10 0.1498623
#> 4    4            0.02        0.03135817          0.08 0.1313582
#> 5    5            0.02        0.03289891          0.05 0.1028989
```
