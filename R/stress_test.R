#' IMF Standardised Stress Tests
#'
#' Applies six standardised IMF stress-test scenarios to a baseline debt
#' projection using the debt dynamics equation:
#'
#' \deqn{d_{t+1} = \frac{1 + r_t}{1 + g_t} d_t - pb_t + sfa_t}{d(t+1) = [(1 + r(t)) / (1 + g(t))] * d(t) - pb(t) + sfa(t)}
#'
#' The six scenarios are:
#' \enumerate{
#'   \item **Growth shock**: GDP growth reduced by `growth_shock` for the first
#'     two years.
#'   \item **Interest rate shock**: interest rate increased by `interest_shock`
#'     for the full horizon.
#'   \item **Exchange rate shock**: debt increases by
#'     `debt * fx_share * exchange_shock` in year 1 (one-off stock-flow
#'     adjustment from currency depreciation).
#'   \item **Primary balance shock**: primary balance reduced by `pb_shock` for
#'     the first two years.
#'   \item **Combined shock**: simultaneous growth shock of `growth_shock / 2`
#'     and interest rate shock of `interest_shock / 2`.
#'   \item **Contingent liabilities**: one-off debt increase of
#'     `contingent_shock` in year 1.
#' }
#'
#' @param debt Numeric scalar. Initial debt-to-GDP ratio.
#' @param interest_rate Numeric scalar or vector of length `horizon`. Baseline
#'   nominal effective interest rate.
#' @param gdp_growth Numeric scalar or vector of length `horizon`. Baseline
#'   nominal GDP growth rate.
#' @param primary_balance Numeric scalar or vector of length `horizon`. Baseline
#'   primary balance as a share of GDP (positive = surplus).
#' @param horizon Integer scalar. Projection horizon in years. Default `5`.
#' @param growth_shock Numeric scalar. Percentage-point reduction in GDP growth
#'   applied in the first two years. Default `-0.01` (1 pp lower growth).
#' @param interest_shock Numeric scalar. Percentage-point increase in the
#'   interest rate. Default `0.02` (200 basis points).
#' @param exchange_shock Numeric scalar. Depreciation fraction applied to
#'   foreign-currency debt. Default `0.15` (15 per cent depreciation).
#' @param fx_share Numeric scalar. Share of debt denominated in foreign
#'   currency. Default `0`.
#' @param pb_shock Numeric scalar. Percentage-point deterioration in primary
#'   balance in the first two years. Default `-0.01`.
#' @param contingent_shock Numeric scalar. One-off increase in debt-to-GDP from
#'   contingent liabilities materialising. Default `0.10`.
#' @param calibrate Optional named list for data-driven shock calibration.
#'   Should contain numeric vectors `gdp_growth_hist`, `interest_rate_hist`,
#'   and `primary_balance_hist`. When provided, shock sizes are computed as
#'   one standard deviation of each historical series, replacing the fixed
#'   defaults. When `NULL` (default), the fixed defaults are used.
#'
#' @references
#' International Monetary Fund (2013). *Staff Guidance Note for Public Debt
#' Sustainability Analysis in Market-Access Countries*. IMF Policy Paper.
#'
#' International Monetary Fund (2022). *Staff Guidance Note on the Sovereign
#' Risk and Debt Sustainability Framework for Market Access Countries*.
#' IMF Policy Paper.
#'
#' @return An S3 object of class `dk_stress` containing:
#' \describe{
#'   \item{scenarios}{A `data.frame` with columns `year`, `baseline`, `growth`,
#'     `interest_rate`, `exchange_rate`, `primary_balance`, `combined`, and
#'     `contingent`.}
#'   \item{terminal}{Named numeric vector of terminal debt-to-GDP under each
#'     scenario.}
#'   \item{inputs}{A list storing all input parameters.}
#' }
#'
#' @export
#' @examples
#' st <- dk_stress_test(
#'   debt = 0.90,
#'   interest_rate = 0.03,
#'   gdp_growth = 0.04,
#'   primary_balance = 0.01,
#'   fx_share = 0.20
#' )
#' st
#' plot(st)
dk_stress_test <- function(debt,
                           interest_rate,
                           gdp_growth,
                           primary_balance,
                           horizon = 5,
                           growth_shock = -0.01,
                           interest_shock = 0.02,
                           exchange_shock = 0.15,
                           fx_share = 0,
                           pb_shock = -0.01,
                           contingent_shock = 0.10,
                           calibrate = NULL) {

  # -- Validate inputs --------------------------------------------------------

  validate_scalar(debt, "debt")
  validate_positive_integer(horizon, "horizon")
  validate_numeric_vector(interest_rate, "interest_rate")
  validate_numeric_vector(gdp_growth, "gdp_growth")
  validate_numeric_vector(primary_balance, "primary_balance")
  validate_scalar(growth_shock, "growth_shock")
  validate_scalar(interest_shock, "interest_shock")
  validate_scalar(exchange_shock, "exchange_shock")
  validate_scalar(fx_share, "fx_share")
  validate_scalar(pb_shock, "pb_shock")
  validate_scalar(contingent_shock, "contingent_shock")

  # -- Data-driven calibration ------------------------------------------------
  if (!is.null(calibrate)) {
    if (!is.list(calibrate)) {
      cli_abort("{.arg calibrate} must be a named list or {.val NULL}.")
    }
    required <- c("gdp_growth_hist", "interest_rate_hist", "primary_balance_hist")
    missing_fields <- setdiff(required, names(calibrate))
    if (length(missing_fields) > 0) {
      cli_abort("{.arg calibrate} must contain: {.val {missing_fields}}.")
    }
    validate_numeric_vector(calibrate$gdp_growth_hist, "calibrate$gdp_growth_hist",
                            min_length = 3)
    validate_numeric_vector(calibrate$interest_rate_hist, "calibrate$interest_rate_hist",
                            min_length = 3)
    validate_numeric_vector(calibrate$primary_balance_hist, "calibrate$primary_balance_hist",
                            min_length = 3)

    growth_shock    <- -1 * stats::sd(calibrate$gdp_growth_hist)
    interest_shock  <- 1 * stats::sd(calibrate$interest_rate_hist)
    pb_shock        <- -1 * stats::sd(calibrate$primary_balance_hist)
  }

  # -- Recycle to horizon length ----------------------------------------------
  r  <- recycle_input(interest_rate, horizon, "interest_rate")
  g  <- recycle_input(gdp_growth, horizon, "gdp_growth")
  pb <- recycle_input(primary_balance, horizon, "primary_balance")

  # -- Helper: project a debt path given r, g, pb, sfa vectors ----------------
  project_path <- function(r_vec, g_vec, pb_vec, sfa_vec) {
    path <- numeric(horizon + 1)
    path[1] <- debt
    for (t in seq_len(horizon)) {
      path[t + 1] <- ((1 + r_vec[t]) / (1 + g_vec[t])) * path[t] -
        pb_vec[t] + sfa_vec[t]
    }
    path
  }

  sfa_zero <- rep(0, horizon)

  # 0. Baseline
  baseline <- project_path(r, g, pb, sfa_zero)

  # 1. Growth shock: g reduced by growth_shock for first 2 years
  g_shock <- g
  shock_years <- min(2, horizon)
  g_shock[seq_len(shock_years)] <- g_shock[seq_len(shock_years)] + growth_shock
  growth_path <- project_path(r, g_shock, pb, sfa_zero)

  # 2. Interest rate shock: r increased by interest_shock for full horizon
  r_shock <- r + interest_shock
  interest_path <- project_path(r_shock, g, pb, sfa_zero)

  # 3. Exchange rate shock: one-off SFA in year 1
  sfa_fx <- sfa_zero
  sfa_fx[1] <- debt * fx_share * exchange_shock
  fx_path <- project_path(r, g, pb, sfa_fx)

  # 4. Primary balance shock: pb reduced by pb_shock for first 2 years
  pb_shock_vec <- pb
  pb_shock_vec[seq_len(shock_years)] <- pb_shock_vec[seq_len(shock_years)] +
    pb_shock
  pb_path <- project_path(r, g, pb_shock_vec, sfa_zero)

  # 5. Combined: half growth shock + half interest shock
  g_combined <- g
  g_combined[seq_len(shock_years)] <- g_combined[seq_len(shock_years)] +
    growth_shock / 2
  r_combined <- r + interest_shock / 2
  combined_path <- project_path(r_combined, g_combined, pb, sfa_zero)

  # 6. Contingent liabilities: one-off debt increase in year 1
  sfa_cont <- sfa_zero
  sfa_cont[1] <- contingent_shock
  contingent_path <- project_path(r, g, pb, sfa_cont)

  # -- Assemble output --------------------------------------------------------
  years <- seq(0, horizon)

  scenarios <- data.frame(
    year            = years,
    baseline        = baseline,
    growth          = growth_path,
    interest_rate   = interest_path,
    exchange_rate   = fx_path,
    primary_balance = pb_path,
    combined        = combined_path,
    contingent      = contingent_path
  )

  terminal <- c(
    baseline        = baseline[horizon + 1],
    growth          = growth_path[horizon + 1],
    interest_rate   = interest_path[horizon + 1],
    exchange_rate   = fx_path[horizon + 1],
    primary_balance = pb_path[horizon + 1],
    combined        = combined_path[horizon + 1],
    contingent      = contingent_path[horizon + 1]
  )

  structure(
    list(
      scenarios = scenarios,
      terminal  = terminal,
      inputs    = list(
        debt             = debt,
        interest_rate    = r,
        gdp_growth       = g,
        primary_balance  = pb,
        horizon          = horizon,
        growth_shock     = growth_shock,
        interest_shock   = interest_shock,
        exchange_shock   = exchange_shock,
        fx_share         = fx_share,
        pb_shock         = pb_shock,
        contingent_shock = contingent_shock
      )
    ),
    class = "dk_stress"
  )
}


# -- print method -------------------------------------------------------------

#' @export
print.dk_stress <- function(x, ...) {
  cli_h1("IMF Stress Test Scenarios")
  cli_bullets(c(
    "*" = "Horizon: {x$inputs$horizon} year{?s}",
    "*" = "Initial debt/GDP: {fmt_pct(x$inputs$debt)}"
  ))

  cat("\nTerminal debt/GDP by scenario:\n\n")

  labels <- c(
    "Baseline", "Growth shock", "Interest rate shock",
    "Exchange rate shock", "Primary balance shock",
    "Combined shock", "Contingent liabilities"
  )
  vals <- fmt_pct(x$terminal)
  diffs <- fmt_pp(x$terminal - x$terminal["baseline"])

  tbl <- data.frame(
    Scenario = labels,
    Terminal = vals,
    Diff     = diffs,
    stringsAsFactors = FALSE
  )
  print(tbl, row.names = FALSE, right = FALSE)

  invisible(x)
}


# -- plot method --------------------------------------------------------------

#' @export
plot.dk_stress <- function(x, ...) {
  sc <- x$scenarios
  years <- sc$year

  # Collect all debt paths (exclude year column)
  paths <- as.matrix(sc[, -1])
  debt_pct <- paths * 100

  y_min <- min(0, min(debt_pct) - 5)
  y_max <- max(debt_pct) + 10

  cols <- c(
    "black", "firebrick", "steelblue", "darkorange",
    "purple4", "darkgreen", "goldenrod3"
  )
  labels <- c(
    "Baseline", "Growth", "Interest rate",
    "Exchange rate", "Primary balance",
    "Combined", "Contingent"
  )

  old_par <- par(mar = c(4, 4.5, 3, 1))
  on.exit(par(old_par))

  plot(
    years, debt_pct[, 1],
    type = "n",
    xlab = "Year",
    ylab = "Debt / GDP (%)",
    ylim = c(y_min, y_max),
    main = "IMF Stress Test Scenarios",
    ...
  )

  grid(lty = 3, col = "grey80")

  for (i in seq_len(ncol(debt_pct))) {
    lwd_i <- if (i == 1) 2.5 else 1.5
    lty_i <- if (i == 1) 1 else 2
    lines(years, debt_pct[, i], col = cols[i], lwd = lwd_i, lty = lty_i)
  }

  legend(
    "topleft",
    legend = labels,
    col = cols,
    lty = c(1, rep(2, 6)),
    lwd = c(2.5, rep(1.5, 6)),
    bg = "white",
    cex = 0.7
  )

  invisible(x)
}
