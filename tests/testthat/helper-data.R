# Shared test fixtures

make_sample <- function() {

  dk_sample_data("sample")
}

make_high_debt <- function() {

  dk_sample_data("high_debt")
}

make_baseline_inputs <- function() {
  list(
    debt = 0.60,
    interest_rate = 0.04,
    gdp_growth = 0.03,
    primary_balance = 0.01
  )
}
