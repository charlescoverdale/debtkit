#' S1 and S2 Sustainability Gap Indicators
#'
#' Computes the S1 and S2 fiscal sustainability gap indicators used by the
#' European Commission to assess the size of the permanent budgetary adjustment
#' required to ensure debt sustainability.
#'
#' **S1** measures the permanent adjustment in the structural primary balance
#' needed to bring the debt-to-GDP ratio to `target_debt` in `target_year`
#' years, taking into account projected increases in age-related expenditure.
#'
#' **S2** measures the permanent adjustment needed to stabilise the debt-to-GDP
#' ratio over an infinite horizon, incorporating the full net present value of
#' future increases in age-related spending.
#'
#' @param debt Numeric scalar. Current debt-to-GDP ratio.
#' @param structural_balance Numeric scalar. Current structural primary
#'   balance as a share of GDP (positive = surplus).
#' @param gdp_growth Numeric scalar. Real GDP growth rate.
#' @param interest_rate Numeric scalar. Real interest rate.
#' @param ageing_costs Numeric scalar. Projected increase in age-related
#'   expenditure as percentage points of GDP. Default `0`.
#' @param target_debt Numeric scalar. Target debt-to-GDP ratio for S1.
#'   Default `0.60`.
#' @param target_year Integer scalar. Number of years to reach the target
#'   debt ratio. Default `20`.
#' @param indicator Character. Which indicator to compute: `"S1"`, `"S2"`, or
#'   `"both"` (default).
#'
#' @return An S3 object of class `dk_sgap` containing:
#' \describe{
#'   \item{S1}{The S1 sustainability gap (or `NA` if not requested).}
#'   \item{S2}{The S2 sustainability gap (or `NA` if not requested).}
#'   \item{risk_S1}{Risk classification for S1: `"low"`, `"medium"`, or
#'     `"high"`.}
#'   \item{risk_S2}{Risk classification for S2: `"low"`, `"medium"`, or
#'     `"high"`.}
#'   \item{required_pb}{The required structural primary balance implied by S1.}
#'   \item{current_pb}{The current structural primary balance.}
#'   \item{inputs}{A list storing all input parameters.}
#' }
#'
#' @references
#' European Commission (2012). *Fiscal Sustainability Report 2012*. European
#' Economy 8/2012, Directorate-General for Economic and Financial Affairs.
#'
#' @export
#' @examples
#' dk_sustainability_gap(
#'   debt = 0.90,
#'   structural_balance = -0.01,
#'   gdp_growth = 0.015,
#'   interest_rate = 0.025,
#'   ageing_costs = 0.02
#' )
dk_sustainability_gap <- function(debt,
                                  structural_balance,
                                  gdp_growth,
                                  interest_rate,
                                  ageing_costs = 0,
                                  target_debt = 0.60,
                                  target_year = 20,
                                  indicator = c("both", "S1", "S2")) {

  # -- Validate inputs --------------------------------------------------------
  validate_scalar(debt, "debt")
  validate_scalar(structural_balance, "structural_balance")
  validate_scalar(gdp_growth, "gdp_growth")
  validate_scalar(interest_rate, "interest_rate")
  validate_scalar(ageing_costs, "ageing_costs")
  validate_scalar(target_debt, "target_debt")
  validate_positive_integer(target_year, "target_year")

  indicator <- match.arg(indicator)

  # -- Interest-growth differential -------------------------------------------
  r <- interest_rate
  g <- gdp_growth
  ig_diff <- (r - g) / (1 + g)

  # -- Risk classification helper ---------------------------------------------
  classify_gap <- function(gap) {
    gap_abs <- abs(gap)
    if (is.na(gap)) return(NA_character_)
    if (gap < 0.02) return("low")
    if (gap < 0.06) return("medium")
    "high"
  }

  # -- S1 indicator -----------------------------------------------------------
  S1 <- NA_real_
  required_pb <- NA_real_
  risk_S1 <- NA_character_

  if (indicator %in% c("both", "S1")) {
    # Required average primary balance to reduce debt from current to target
    # over target_year periods, using the debt dynamics recurrence:
    #
    # d(T) = [(1+r)/(1+g)]^T * d(0) - pb * sum_{t=0}^{T-1} [(1+r)/(1+g)]^t
    #
    # Solving for pb:
    # pb = {[(1+r)/(1+g)]^T * d(0) - d(T)} / sum_{t=0}^{T-1} [(1+r)/(1+g)]^t

    snowball <- (1 + r) / (1 + g)

    if (abs(snowball - 1) < 1e-10) {
      # When r == g, the sum simplifies
      geometric_sum <- target_year
    } else {
      geometric_sum <- (snowball^target_year - 1) / (snowball - 1)
    }

    required_pb <- (snowball^target_year * debt - target_debt) / geometric_sum

    # Ageing cost adjustment: spread evenly over target_year
    ageing_adjustment <- ageing_costs / 2

    S1 <- required_pb - structural_balance + ageing_adjustment
    risk_S1 <- classify_gap(S1)
  }

  # -- S2 indicator -----------------------------------------------------------
  S2 <- NA_real_
  risk_S2 <- NA_character_

  if (indicator %in% c("both", "S2")) {
    # S2 = (r-g)/(1+g) * d - structural_balance + NPV of ageing costs
    # NPV of ageing costs = ageing_costs * (1+g) / (r-g) when r > g

    debt_stabilising_pb <- ig_diff * debt

    if (abs(r - g) < 1e-10) {
      # When r == g, the NPV of ageing costs is infinite if ageing_costs > 0
      if (ageing_costs > 0) {
        cli_warn(paste0(
          "With {.arg interest_rate} approximately equal to {.arg gdp_growth}, ",
          "the NPV of ageing costs is unbounded. S2 is set to {.val Inf}."
        ))
        S2 <- Inf
      } else {
        S2 <- debt_stabilising_pb - structural_balance
      }
    } else if (r < g) {
      # When r < g, debt is sustainable without adjustment, but ageing costs
      # NPV uses the same formula (negative denominator means costs reduce S2)
      npv_ageing <- ageing_costs * (1 + g) / (r - g)
      S2 <- debt_stabilising_pb - structural_balance + npv_ageing
    } else {
      npv_ageing <- ageing_costs * (1 + g) / (r - g)
      S2 <- debt_stabilising_pb - structural_balance + npv_ageing
    }

    risk_S2 <- classify_gap(S2)
  }

  structure(
    list(
      S1          = S1,
      S2          = S2,
      risk_S1     = risk_S1,
      risk_S2     = risk_S2,
      required_pb = required_pb,
      current_pb  = structural_balance,
      inputs      = list(
        debt               = debt,
        structural_balance = structural_balance,
        gdp_growth         = gdp_growth,
        interest_rate      = interest_rate,
        ageing_costs       = ageing_costs,
        target_debt        = target_debt,
        target_year        = target_year,
        indicator          = indicator
      )
    ),
    class = "dk_sgap"
  )
}


# -- print method -------------------------------------------------------------

#' @export
print.dk_sgap <- function(x, ...) {
  cli_h1("Sustainability Gap Indicators")

  cli_bullets(c(
    "*" = "Current debt/GDP: {fmt_pct(x$inputs$debt)}",
    "*" = "Current structural PB: {fmt_pct(x$current_pb)}",
    "*" = "Interest rate: {fmt_pct(x$inputs$interest_rate)}",
    "*" = "GDP growth: {fmt_pct(x$inputs$gdp_growth)}"
  ))

  colour_risk <- function(risk) {
    switch(risk,
      low    = cli::col_green(toupper(risk)),
      medium = cli::col_yellow(toupper(risk)),
      high   = cli::col_red(toupper(risk)),
      risk
    )
  }

  if (!is.na(x$S1)) {
    cat("\n")
    cli_h2("S1 Indicator")
    cli_bullets(c(
      "*" = "Required PB adjustment: {fmt_pp(x$S1)}",
      "*" = "Required structural PB: {fmt_pct(x$required_pb)}",
      "*" = "Target debt/GDP: {fmt_pct(x$inputs$target_debt)} in {x$inputs$target_year} years"
    ))
    cat(sprintf("  Risk: %s\n", colour_risk(x$risk_S1)))
  }

  if (!is.na(x$S2)) {
    cat("\n")
    cli_h2("S2 Indicator")
    cli_bullets(c(
      "*" = "Required PB adjustment: {fmt_pp(x$S2)}",
      "*" = "Ageing costs: {fmt_pp(x$inputs$ageing_costs)}"
    ))
    cat(sprintf("  Risk: %s\n", colour_risk(x$risk_S2)))
  }

  invisible(x)
}
