# Sample Fiscal Data

Provides built-in sample datasets for running examples and tests without
requiring external data.

## Usage

``` r
dk_sample_data(country = c("sample", "high_debt"))
```

## Arguments

- country:

  Character. Which sample dataset to return. Options: `"sample"`
  (default) provides a synthetic 20-year history for a mid-income
  country; `"high_debt"` provides a high-debt scenario.

## Value

A list with components:

- years:

  Integer vector of years.

- debt:

  Numeric vector of debt-to-GDP ratios.

- interest_rate:

  Numeric vector of effective interest rates on government debt.

- gdp_growth:

  Numeric vector of nominal GDP growth rates.

- primary_balance:

  Numeric vector of primary balance-to-GDP ratios (positive = surplus).

## Examples

``` r
d <- dk_sample_data()
d$debt
#>  [1] 0.45 0.44 0.42 0.41 0.55 0.60 0.62 0.60 0.58 0.56 0.55 0.54 0.55 0.53 0.52
#> [16] 0.72 0.75 0.73 0.71 0.69
d$years
#>  [1] 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018
#> [16] 2019 2020 2021 2022 2023
```
