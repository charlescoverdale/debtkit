#' Project Debt-to-GDP Path
#'
#' Projects a debt-to-GDP ratio forward using the standard debt dynamics
#' equation:
#'
#' \deqn{d_{t+1} = \frac{1 + r_t}{1 + g_t} d_t - pb_t + sfa_t}{d(t+1) = [(1 + r(t)) / (1 + g(t))] * d(t) - pb(t) + sfa(t)}
#'
#' where \eqn{d} is the debt-to-GDP ratio, \eqn{r} is the effective nominal
#' interest rate on government debt, \eqn{g} is nominal GDP growth,
#' \eqn{pb} is the primary balance as a share of GDP (positive = surplus),
#' and \eqn{sfa} captures stock-flow adjustments (e.g. privatisation receipts,
#' exchange-rate valuation changes, below-the-line operations).
#'
#' @param debt Numeric scalar. Initial debt-to-GDP ratio (e.g., `0.90` for
#'   90 per cent of GDP).
#' @param interest_rate Numeric scalar or vector of length `horizon`. Nominal
#'   effective interest rate on government debt.
#' @param gdp_growth Numeric scalar or vector of length `horizon`. Nominal GDP
#'   growth rate.
#' @param primary_balance Numeric scalar or vector of length `horizon`. Primary
#'   balance as a share of GDP. Positive values denote a surplus; negative
#'   values a deficit.
#' @param sfa Numeric scalar or vector of length `horizon`. Stock-flow
#'   adjustment as a share of GDP. Default `0`.
#' @param horizon Integer scalar. Number of years to project forward. Default
#'   `10`.
#' @param date Optional `Date`. If supplied, the projection is anchored to
#'   this date (stored in the output for labelling purposes).
#'
#' @return An S3 object of class `dk_projection` containing:
#' \describe{
#'   \item{debt_path}{Numeric vector of length `horizon + 1`, giving the
#'     debt-to-GDP ratio from the initial period through the terminal period.}
#'   \item{decomposition}{A `data.frame` with columns `year`, `debt`,
#'     `interest_effect`, `growth_effect`, `snowball_effect`,
#'     `primary_balance_effect`, `sfa_effect`, and `change`.}
#'   \item{horizon}{The projection horizon.}
#'   \item{inputs}{A list storing all input parameters.}
#' }
#'
#' @references
#' Blanchard, O.J. (1990). Suggestions for a New Set of Fiscal Indicators.
#' *OECD Economics Department Working Papers*, No. 79.
#' \doi{10.1787/budget-v2-art12-en}
#'
#' International Monetary Fund (2013). *Staff Guidance Note for Public Debt
#' Sustainability Analysis in Market-Access Countries*. IMF Policy Paper.
#'
#' @export
#' @examples
#' d <- dk_sample_data()
#' proj <- dk_project(
#'   debt = tail(d$debt, 1),
#'   interest_rate = 0.03,
#'   gdp_growth = 0.04,
#'   primary_balance = 0.01
#' )
#' proj
#' plot(proj)
dk_project <- function(debt,
                       interest_rate,
                       gdp_growth,
                       primary_balance,
                       sfa = 0,
                       horizon = 10,
                       date = NULL) {


  # -- Validate inputs --------------------------------------------------------
  validate_scalar(debt, "debt")
  validate_positive_integer(horizon, "horizon")
  validate_numeric_vector(interest_rate, "interest_rate")
  validate_numeric_vector(gdp_growth, "gdp_growth")
  validate_numeric_vector(primary_balance, "primary_balance")
  validate_numeric_vector(sfa, "sfa")

  if (!is.null(date) && !inherits(date, "Date")) {
    cli_abort("{.arg date} must be a {.cls Date} or {.val NULL}.")
  }


  # -- Recycle scalar inputs to horizon length --------------------------------
  r  <- recycle_input(interest_rate, horizon, "interest_rate")
  g  <- recycle_input(gdp_growth, horizon, "gdp_growth")
  pb <- recycle_input(primary_balance, horizon, "primary_balance")
  sf <- recycle_input(sfa, horizon, "sfa")


  # -- Check for pathological growth rates ------------------------------------
  if (any(g <= -1)) {
    cli_abort("{.arg gdp_growth} must be greater than -1 (100% contraction).")
  }


  # -- Project debt path ------------------------------------------------------
  debt_path <- numeric(horizon + 1)
  debt_path[1] <- debt

  interest_effect <- numeric(horizon)
  growth_effect   <- numeric(horizon)
  pb_effect       <- numeric(horizon)
  sfa_effect      <- numeric(horizon)

  for (t in seq_len(horizon)) {
    d_prev <- debt_path[t]
    snowball_factor <- (1 + r[t]) / (1 + g[t])

    debt_path[t + 1] <- snowball_factor * d_prev - pb[t] + sf[t]

    # Decompose the change
    interest_effect[t] <- (r[t] / (1 + g[t])) * d_prev
    growth_effect[t]   <- (-g[t] / (1 + g[t])) * d_prev
    pb_effect[t]       <- -pb[t]
    sfa_effect[t]      <- sf[t]
  }

  snowball_effect <- interest_effect + growth_effect
  change <- diff(debt_path)

  decomposition <- data.frame(
    year                   = seq_len(horizon),
    debt                   = debt_path[-1],
    interest_effect        = interest_effect,
    growth_effect          = growth_effect,
    snowball_effect        = snowball_effect,
    primary_balance_effect = pb_effect,
    sfa_effect             = sfa_effect,
    change                 = change
  )

  if (!is.null(date)) {
    start_year <- as.integer(format(date, "%Y"))
    decomposition$year <- start_year + decomposition$year
  }

  structure(
    list(
      debt_path     = debt_path,
      decomposition = decomposition,
      horizon       = horizon,
      inputs        = list(
        debt            = debt,
        interest_rate   = r,
        gdp_growth      = g,
        primary_balance = pb,
        sfa             = sf,
        horizon         = horizon,
        date            = date
      )
    ),
    class = "dk_projection"
  )
}


# -- print method -------------------------------------------------------------

#' @export
print.dk_projection <- function(x, ...) {
  initial <- x$debt_path[1]
  terminal <- x$debt_path[x$horizon + 1]

  # Debt-stabilising primary balance: [(r - g) / (1 + g)] * d
  # Use average r, g over the horizon and terminal debt

  r_avg <- mean(x$inputs$interest_rate)
  g_avg <- mean(x$inputs$gdp_growth)
  dk_pb <- ((r_avg - g_avg) / (1 + g_avg)) * terminal

  cli_h1("Debt Sustainability Projection")
  cli_bullets(c(
    "*" = "Horizon: {x$horizon} year{?s}",
    "*" = "Initial debt/GDP: {fmt_pct(initial)}",
    "*" = "Terminal debt/GDP: {fmt_pct(terminal)}",
    "*" = "Change: {fmt_pp(terminal - initial)}",
    "*" = "Debt-stabilising primary balance: {fmt_pct(dk_pb)}"
  ))

  invisible(x)
}


# -- summary method -----------------------------------------------------------

#' @export
summary.dk_projection <- function(object, ...) {
  print.dk_projection(object)

  cat("\nDecomposition of debt changes:\n\n")

  tbl <- object$decomposition
  fmt <- data.frame(
    year      = tbl$year,
    debt      = fmt_pct(tbl$debt),
    interest  = fmt_pp(tbl$interest_effect),
    growth    = fmt_pp(tbl$growth_effect),
    snowball  = fmt_pp(tbl$snowball_effect),
    pb        = fmt_pp(tbl$primary_balance_effect),
    sfa       = fmt_pp(tbl$sfa_effect),
    change    = fmt_pp(tbl$change)
  )
  print(fmt, row.names = FALSE, right = FALSE)

  invisible(object)
}


# -- plot method --------------------------------------------------------------

#' @export
plot.dk_projection <- function(x, ...) {
  n <- x$horizon + 1
  years <- seq_len(n) - 1
  if (!is.null(x$inputs$date)) {
    start_year <- as.integer(format(x$inputs$date, "%Y"))
    years <- start_year + years
  }

  debt_pct <- x$debt_path * 100
  y_min <- min(0, min(debt_pct) - 5)
  y_max <- max(100, max(debt_pct) + 10)

  old_par <- par(mar = c(4, 4.5, 3, 1))
  on.exit(par(old_par))

  plot(
    years, debt_pct,
    type = "n",
    xlab = "Year",
    ylab = "Debt / GDP (%)",
    ylim = c(y_min, y_max),
    main = "Debt-to-GDP Projection",
    ...
  )

  grid(lty = 3, col = "grey80")

  # Reference lines at 60% and 90%
  abline(h = 60, lty = 2, col = "steelblue", lwd = 1.5)
  abline(h = 90, lty = 2, col = "firebrick", lwd = 1.5)

  lines(years, debt_pct, col = "black", lwd = 2.5)
  points(years, debt_pct, pch = 19, col = "black", cex = 0.8)

  legend(
    "topright",
    legend = c("Debt path", "60% reference", "90% reference"),
    col = c("black", "steelblue", "firebrick"),
    lty = c(1, 2, 2),
    lwd = c(2.5, 1.5, 1.5),
    pch = c(19, NA, NA),
    bg = "white",
    cex = 0.8
  )

  invisible(x)
}
