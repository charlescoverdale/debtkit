#' Decompose Historical Debt Changes
#'
#' Breaks down observed year-on-year changes in the debt-to-GDP ratio into
#' four components:
#'
#' \enumerate{
#'   \item **Interest effect**: \eqn{r_t / (1 + g_t) \cdot d_{t-1}}{r(t) / (1 + g(t)) * d(t-1)}
#'   \item **Growth effect**: \eqn{-g_t / (1 + g_t) \cdot d_{t-1}}{-g(t) / (1 + g(t)) * d(t-1)}
#'   \item **Primary balance effect**: \eqn{-pb_t}{-pb(t)}
#'   \item **Stock-flow adjustment (residual)**: actual change minus the sum of
#'     the three identified components.
#' }
#'
#' This is the standard decomposition used by the IMF (2013) and European
#' Commission. The SFA residual captures privatisation receipts, exchange-rate
#' valuation changes, below-the-line operations, and any measurement error.
#'
#' @param debt Numeric vector of historical debt-to-GDP ratios.
#' @param interest_rate Numeric vector of effective interest rates on
#'   government debt. Must be the same length as `debt`.
#' @param gdp_growth Numeric vector of nominal GDP growth rates. Must be the
#'   same length as `debt`.
#' @param primary_balance Numeric vector of primary balance-to-GDP ratios
#'   (positive = surplus). Must be the same length as `debt`.
#' @param years Optional integer vector of year labels. Must be the same
#'   length as `debt`. If `NULL` (default), years are numbered sequentially.
#'
#' @return An S3 object of class `dk_decomposition` containing:
#' \describe{
#'   \item{data}{A `data.frame` with columns `year`, `debt`, `change`,
#'     `interest_effect`, `growth_effect`, `snowball_effect`,
#'     `primary_balance_effect`, and `sfa`.}
#'   \item{years}{The year labels used.}
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
#' dec <- dk_decompose(
#'   debt = d$debt,
#'   interest_rate = d$interest_rate,
#'   gdp_growth = d$gdp_growth,
#'   primary_balance = d$primary_balance,
#'   years = d$years
#' )
#' dec
#' plot(dec)
dk_decompose <- function(debt,
                         interest_rate,
                         gdp_growth,
                         primary_balance,
                         years = NULL) {

  # -- Validate inputs --------------------------------------------------------
  validate_numeric_vector(debt, "debt", min_length = 2)
  validate_numeric_vector(interest_rate, "interest_rate")
  validate_numeric_vector(gdp_growth, "gdp_growth")
  validate_numeric_vector(primary_balance, "primary_balance")

  n <- length(debt)

  if (length(interest_rate) != n) {
    cli_abort(
      "{.arg interest_rate} must be the same length as {.arg debt} ({n})."
    )
  }
  if (length(gdp_growth) != n) {
    cli_abort(
      "{.arg gdp_growth} must be the same length as {.arg debt} ({n})."
    )
  }
  if (length(primary_balance) != n) {
    cli_abort(
      "{.arg primary_balance} must be the same length as {.arg debt} ({n})."
    )
  }

  if (any(gdp_growth <= -1)) {
    cli_abort("{.arg gdp_growth} must be greater than -1 (100% contraction).")
  }

  if (is.null(years)) {
    years <- seq_len(n)
  } else {
    validate_numeric_vector(years, "years", min_length = n)
    if (length(years) != n) {
      cli_abort("{.arg years} must be the same length as {.arg debt} ({n}).")
    }
    years <- as.integer(years)
  }


  # -- Compute decomposition for t = 2..n ------------------------------------
  # (first observation is the base; decomposition starts from the second)

  m <- n - 1
  interest_effect <- numeric(m)
  growth_effect   <- numeric(m)
  pb_effect       <- numeric(m)
  actual_change   <- numeric(m)

  for (i in seq_len(m)) {
    t <- i + 1
    d_prev <- debt[t - 1]
    r <- interest_rate[t]
    g <- gdp_growth[t]
    pb <- primary_balance[t]

    interest_effect[i] <- (r / (1 + g)) * d_prev
    growth_effect[i]   <- (-g / (1 + g)) * d_prev
    pb_effect[i]       <- -pb
    actual_change[i]   <- debt[t] - d_prev
  }

  snowball_effect <- interest_effect + growth_effect
  sfa <- actual_change - (interest_effect + growth_effect + pb_effect)

  decomp <- data.frame(
    year                   = years[-1],
    debt                   = debt[-1],
    change                 = actual_change,
    interest_effect        = interest_effect,
    growth_effect          = growth_effect,
    snowball_effect        = snowball_effect,
    primary_balance_effect = pb_effect,
    sfa                    = sfa
  )

  structure(
    list(
      data  = decomp,
      years = years
    ),
    class = "dk_decomposition"
  )
}


# -- print method -------------------------------------------------------------

#' @export
print.dk_decomposition <- function(x, ...) {
  n_periods <- nrow(x$data)
  yr_range <- range(x$data$year)

  cli_h1("Debt Decomposition")
  cli_bullets(c(
    "*" = "Periods: {n_periods} ({yr_range[1]}\u2013{yr_range[2]})",
    "*" = "Cumulative change: {fmt_pp(sum(x$data$change))}",
    "*" = "  Interest effect: {fmt_pp(sum(x$data$interest_effect))}",
    "*" = "  Growth effect: {fmt_pp(sum(x$data$growth_effect))}",
    "*" = "  Primary balance: {fmt_pp(sum(x$data$primary_balance_effect))}",
    "*" = "  Stock-flow adj.: {fmt_pp(sum(x$data$sfa))}"
  ))

  invisible(x)
}


# -- summary method -----------------------------------------------------------

#' @export
summary.dk_decomposition <- function(object, ...) {
  print.dk_decomposition(object)

  cat("\nYear-by-year decomposition:\n\n")
  tbl <- object$data
  fmt <- data.frame(
    year     = tbl$year,
    debt     = fmt_pct(tbl$debt),
    change   = fmt_pp(tbl$change),
    interest = fmt_pp(tbl$interest_effect),
    growth   = fmt_pp(tbl$growth_effect),
    pb       = fmt_pp(tbl$primary_balance_effect),
    sfa      = fmt_pp(tbl$sfa)
  )
  print(fmt, row.names = FALSE, right = FALSE)

  invisible(object)
}


# -- plot method (stacked bar chart) ------------------------------------------

#' @export
plot.dk_decomposition <- function(x, ...) {
  tbl <- x$data

  # Build matrix for stacked bar: rows = components, cols = years
  components <- rbind(
    tbl$interest_effect * 100,
    tbl$growth_effect * 100,
    tbl$primary_balance_effect * 100,
    tbl$sfa * 100
  )

  # Separate positive and negative for proper stacking
  pos <- components
  pos[pos < 0] <- 0
  neg <- components
  neg[neg > 0] <- 0

  years <- tbl$year
  n <- length(years)

  y_max <- max(colSums(pos)) * 1.3
  y_min <- min(colSums(neg)) * 1.3
  if (y_max < 5) y_max <- 5
  if (y_min > -5) y_min <- -5

  colours <- c(
    "#D95F02",  # interest (orange)
    "#1B9E77",  # growth (teal)
    "#7570B3",  # primary balance (purple)
    "#999999"   # SFA (grey)
  )

  old_par <- par(mar = c(4, 4.5, 3, 1))
  on.exit(par(old_par))

  # Create blank plot
  plot(
    NULL,
    xlim = c(0.5, n + 0.5),
    ylim = c(y_min, y_max),
    xlab = "Year",
    ylab = "Contribution (pp of GDP)",
    main = "Decomposition of Debt Changes",
    xaxt = "n",
    ...
  )

  grid(lty = 3, col = "grey80")
  abline(h = 0, col = "black", lwd = 1)

  # Custom x-axis
  axis(1, at = seq_len(n), labels = years, las = 2, cex.axis = 0.8)

  bar_width <- 0.6

  # Draw stacked bars for each year

  for (j in seq_len(n)) {
    # Positive stack
    y_bottom <- 0
    for (i in seq_len(4)) {
      val <- pos[i, j]
      if (val > 0) {
        rect(
          j - bar_width / 2, y_bottom,
          j + bar_width / 2, y_bottom + val,
          col = colours[i], border = NA
        )
        y_bottom <- y_bottom + val
      }
    }

    # Negative stack
    y_top <- 0
    for (i in seq_len(4)) {
      val <- neg[i, j]
      if (val < 0) {
        rect(
          j - bar_width / 2, y_top + val,
          j + bar_width / 2, y_top,
          col = colours[i], border = NA
        )
        y_top <- y_top + val
      }
    }
  }

  # Net change markers
  points(
    seq_len(n), tbl$change * 100,
    pch = 18, col = "black", cex = 1.2
  )

  legend(
    "topright",
    legend = c("Interest", "Growth", "Primary balance", "SFA", "Net change"),
    fill = c(colours, NA),
    border = c(rep("grey30", 4), NA),
    pch = c(NA, NA, NA, NA, 18),
    col = c(rep(NA, 4), "black"),
    bg = "white",
    cex = 0.75
  )

  invisible(x)
}
