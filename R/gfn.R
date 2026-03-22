#' Gross Financing Needs
#'
#' Computes gross financing needs (GFN) as a share of GDP over a projection
#' horizon. GFN represents the total amount of new borrowing a government
#' requires each year to cover its primary deficit, interest payments, and
#' maturing debt:
#'
#' \deqn{GFN_t = -pb_t + r_t \cdot d_t + m_t}{GFN(t) = -pb(t) + r(t) * d(t) + m(t)}
#'
#' where \eqn{pb} is the primary balance (positive = surplus), \eqn{r} is the
#' effective interest rate, \eqn{d} is debt-to-GDP, and \eqn{m} is maturing
#' debt as a share of GDP.
#'
#' @param debt Numeric scalar. Initial debt-to-GDP ratio.
#' @param interest_rate Numeric scalar or vector of length `horizon`. Effective
#'   nominal interest rate on government debt.
#' @param maturity_profile Numeric vector or scalar. If a vector, gives the
#'   share of GDP maturing in each year of the horizon. If a scalar, interpreted
#'   as the average maturity in years; debt is assumed to mature uniformly at
#'   `debt / maturity_profile` per year.
#' @param primary_balance Numeric scalar or vector of length `horizon`. Primary
#'   balance as a share of GDP (positive = surplus).
#' @param horizon Integer scalar. Projection horizon in years. Default `5`.
#'
#' @return A `data.frame` with columns:
#' \describe{
#'   \item{year}{Year index (1 to `horizon`).}
#'   \item{primary_deficit}{Primary deficit (negative of primary balance).}
#'   \item{interest_payments}{Interest payments as a share of GDP.}
#'   \item{maturing_debt}{Maturing debt as a share of GDP.}
#'   \item{gfn}{Total gross financing needs as a share of GDP.}
#' }
#'
#' @references
#' International Monetary Fund (2013). *Staff Guidance Note for Public Debt
#' Sustainability Analysis in Market-Access Countries*. IMF Policy Paper.
#'
#' @export
#' @examples
#' # Scalar average maturity of 7 years
#' dk_gfn(debt = 0.90, interest_rate = 0.03,
#'        maturity_profile = 7, primary_balance = -0.02)
#'
#' # Explicit maturity profile
#' dk_gfn(debt = 0.90, interest_rate = 0.03,
#'        maturity_profile = c(0.15, 0.12, 0.10, 0.08, 0.05),
#'        primary_balance = -0.02)
dk_gfn <- function(debt,
                   interest_rate,
                   maturity_profile,
                   primary_balance,
                   horizon = 5) {

  # -- Validate inputs --------------------------------------------------------
  validate_scalar(debt, "debt")
  validate_positive_integer(horizon, "horizon")
  validate_numeric_vector(interest_rate, "interest_rate")
  validate_numeric_vector(primary_balance, "primary_balance")
  validate_numeric_vector(maturity_profile, "maturity_profile")

  # -- Recycle to horizon length ----------------------------------------------
  r  <- recycle_input(interest_rate, horizon, "interest_rate")
  pb <- recycle_input(primary_balance, horizon, "primary_balance")

  # -- Interpret maturity profile ---------------------------------------------
  if (length(maturity_profile) == 1) {
    if (maturity_profile <= 0) {
      cli_abort("{.arg maturity_profile} must be positive when scalar.")
    }
    mat <- rep(debt / maturity_profile, horizon)
  } else {
    mat <- recycle_input(maturity_profile, horizon, "maturity_profile")
  }

  # -- Compute GFN for each year ----------------------------------------------
  # Use a simple rolling debt for interest calculation:
  # debt evolves based on primary balance and maturing/re-issued debt
  d <- numeric(horizon)
  d[1] <- debt

  primary_deficit   <- numeric(horizon)
  interest_payments <- numeric(horizon)
  maturing_debt     <- numeric(horizon)
  gfn               <- numeric(horizon)

  for (t in seq_len(horizon)) {
    d_t <- if (t == 1) debt else d[t]

    primary_deficit[t]   <- -pb[t]
    interest_payments[t] <- r[t] * d_t
    maturing_debt[t]     <- mat[t]
    gfn[t]               <- primary_deficit[t] + interest_payments[t] +
      maturing_debt[t]

    # Update debt for next period (debt grows by deficit + interest - rollover
    # is neutral since maturing debt is refinanced)
    if (t < horizon) {
      d[t + 1] <- d_t + primary_deficit[t] + interest_payments[t]
    }
  }

  data.frame(
    year             = seq_len(horizon),
    primary_deficit  = primary_deficit,
    interest_payments = interest_payments,
    maturing_debt    = maturing_debt,
    gfn              = gfn
  )
}
