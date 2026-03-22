#' Sample Fiscal Data
#'
#' Provides built-in sample datasets for running examples and tests without
#' requiring external data.
#'
#' @param country Character. Which sample dataset to return. Options:
#'   `"sample"` (default) provides a synthetic 20-year history for a
#'   mid-income country; `"high_debt"` provides a high-debt scenario.
#'
#' @return A list with components:
#'   \describe{
#'     \item{years}{Integer vector of years.}
#'     \item{debt}{Numeric vector of debt-to-GDP ratios.}
#'     \item{interest_rate}{Numeric vector of effective interest rates on
#'       government debt.}
#'     \item{gdp_growth}{Numeric vector of nominal GDP growth rates.}
#'     \item{primary_balance}{Numeric vector of primary balance-to-GDP ratios
#'       (positive = surplus).}
#'   }
#'
#' @export
#' @examples
#' d <- dk_sample_data()
#' d$debt
#' d$years
dk_sample_data <- function(country = c("sample", "high_debt")) {
  country <- match.arg(country)

  if (country == "sample") {
    list(
      years = 2004:2023,
      debt = c(0.45, 0.44, 0.42, 0.41, 0.55, 0.60, 0.62, 0.60, 0.58,
               0.56, 0.55, 0.54, 0.55, 0.53, 0.52, 0.72, 0.75, 0.73,
               0.71, 0.69),
      interest_rate = c(0.045, 0.043, 0.042, 0.044, 0.040, 0.035, 0.033,
                        0.030, 0.028, 0.025, 0.022, 0.020, 0.018, 0.020,
                        0.022, 0.015, 0.018, 0.025, 0.035, 0.038),
      gdp_growth = c(0.055, 0.050, 0.060, 0.045, -0.020, 0.030, 0.035,
                     0.040, 0.038, 0.042, 0.045, 0.035, 0.040, 0.042,
                     0.050, -0.035, 0.065, 0.055, 0.045, 0.040),
      primary_balance = c(0.010, 0.012, 0.015, 0.008, -0.040, -0.035,
                          -0.025, -0.015, -0.010, -0.005, 0.000, 0.005,
                          0.003, 0.008, 0.010, -0.060, -0.045, -0.020,
                          -0.010, -0.005)
    )
  } else {
    list(
      years = 2014:2023,
      debt = c(1.30, 1.32, 1.33, 1.35, 1.34, 1.32, 1.55, 1.60, 1.52,
               1.48),
      interest_rate = c(0.035, 0.032, 0.028, 0.025, 0.022, 0.020, 0.015,
                        0.018, 0.030, 0.035),
      gdp_growth = c(0.010, 0.012, 0.015, 0.020, 0.018, 0.015, -0.080,
                     0.070, 0.040, 0.025),
      primary_balance = c(-0.010, -0.005, 0.005, 0.010, 0.015, 0.010,
                          -0.070, -0.050, -0.020, -0.010)
    )
  }
}
