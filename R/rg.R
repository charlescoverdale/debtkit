#' Interest Rate-Growth Differential and Debt-Stabilising Primary Balance
#'
#' Computes the interest rate-growth differential (\eqn{r - g}), a key
#' indicator of debt sustainability. When \eqn{r > g}, debt grows faster than
#' the economy (the "snowball effect" is adverse) and a primary surplus is
#' needed to stabilise the debt ratio. When \eqn{r < g}, the government can
#' run a primary deficit and still see the debt ratio fall.
#'
#' If `debt` is supplied, the function also computes the **debt-stabilising
#' primary balance**: the primary surplus (as a share of GDP) required to hold
#' the debt-to-GDP ratio constant at its current level. This is given by:
#'
#' \deqn{pb^* = \frac{r - g}{1 + g} \cdot d}{pb* = [(r - g) / (1 + g)] * d}
#'
#' If `inflation` is supplied, the function computes the **real** \eqn{r - g}
#' differential by deflating both the interest rate and GDP growth:
#' \eqn{r_{real} = (1 + r)/(1 + \pi) - 1} and
#' \eqn{g_{real} = (1 + g)/(1 + \pi) - 1}.
#'
#' @param interest_rate Numeric. Effective nominal interest rate on government
#'   debt. Scalar or vector.
#' @param gdp_growth Numeric. Nominal GDP growth rate. Scalar or vector (same
#'   length as `interest_rate`).
#' @param inflation Numeric or `NULL`. If supplied, the inflation rate used to
#'   compute the real \eqn{r - g}. Scalar or same length as `interest_rate`.
#'   Default `NULL`.
#' @param debt Numeric or `NULL`. If supplied, the debt-to-GDP ratio used to
#'   compute the debt-stabilising primary balance. Scalar or same length as
#'   `interest_rate`. Default `NULL`.
#'
#' @return A named list with:
#' \describe{
#'   \item{rg_differential}{Numeric vector. The nominal \eqn{r - g}
#'     differential.}
#'   \item{real_rg}{Numeric vector. The real \eqn{r - g} differential.
#'     Only present if `inflation` was supplied.}
#'   \item{debt_stabilising_pb}{Numeric vector. The debt-stabilising primary
#'     balance as a share of GDP. Only present if `debt` was supplied.}
#' }
#'
#' @references
#' Blanchard, O.J. (1990). Suggestions for a New Set of Fiscal Indicators.
#' *OECD Economics Department Working Papers*, No. 79.
#' \doi{10.1787/budget-v2-art12-en}
#'
#' Barrett, P. (2018). Interest-Growth Differentials and Debt Limits in
#' Advanced Economies. *IMF Working Paper*, WP/18/82.
#'
#' @export
#' @examples
#' # Simple scalar case
#' dk_rg(interest_rate = 0.04, gdp_growth = 0.03)
#'
#' # With debt — compute stabilising primary balance
#' dk_rg(interest_rate = 0.04, gdp_growth = 0.03, debt = 0.90)
#'
#' # With inflation — compute real r-g
#' dk_rg(interest_rate = 0.04, gdp_growth = 0.05, inflation = 0.02)
#'
#' # Vector case using sample data
#' d <- dk_sample_data()
#' dk_rg(
#'   interest_rate = d$interest_rate,
#'   gdp_growth = d$gdp_growth,
#'   debt = d$debt
#' )
dk_rg <- function(interest_rate,
                  gdp_growth,
                  inflation = NULL,
                  debt = NULL) {

  # -- Validate inputs --------------------------------------------------------
  validate_numeric_vector(interest_rate, "interest_rate")
  validate_numeric_vector(gdp_growth, "gdp_growth")

  n <- length(interest_rate)

  if (length(gdp_growth) != n) {
    cli_abort(
      "{.arg gdp_growth} must be the same length as {.arg interest_rate} ({n})."
    )
  }

  if (any(gdp_growth <= -1)) {
    cli_abort("{.arg gdp_growth} must be greater than -1 (100% contraction).")

  }

  if (!is.null(inflation)) {
    validate_numeric_vector(inflation, "inflation")
    if (length(inflation) == 1 && n > 1) {
      inflation <- rep(inflation, n)
    }
    if (length(inflation) != n) {
      cli_abort(
        "{.arg inflation} must be length 1 or {n}, not {length(inflation)}."
      )
    }
    if (any(inflation <= -1)) {
      cli_abort("{.arg inflation} must be greater than -1.")
    }
  }

  if (!is.null(debt)) {
    validate_numeric_vector(debt, "debt")
    if (length(debt) == 1 && n > 1) {
      debt <- rep(debt, n)
    }
    if (length(debt) != n) {
      cli_abort(
        "{.arg debt} must be length 1 or {n}, not {length(debt)}."
      )
    }
  }


  # -- Compute nominal r - g --------------------------------------------------
  rg <- interest_rate - gdp_growth

  result <- list(rg_differential = rg)


  # -- Compute real r - g if inflation supplied --------------------------------
  if (!is.null(inflation)) {
    r_real <- (1 + interest_rate) / (1 + inflation) - 1
    g_real <- (1 + gdp_growth) / (1 + inflation) - 1
    result$real_rg <- r_real - g_real
  }


  # -- Compute debt-stabilising primary balance if debt supplied ---------------
  if (!is.null(debt)) {
    result$debt_stabilising_pb <- ((interest_rate - gdp_growth) /
                                     (1 + gdp_growth)) * debt
  }

  result
}
