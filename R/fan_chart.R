#' Stochastic Debt Fan Chart
#'
#' Projects debt-to-GDP paths via Monte Carlo simulation using the standard
#' debt dynamics equation. At each step, correlated shocks to growth, the
#' interest rate, and the primary balance are drawn from a multivariate
#' normal distribution and added to the baseline paths. The result is a fan
#' chart showing the distribution of projected debt paths.
#'
#' @param debt Numeric scalar; initial debt-to-GDP ratio.
#' @param interest_rate Numeric scalar or vector of length `horizon`;
#'   baseline interest rate path.
#' @param gdp_growth Numeric scalar or vector of length `horizon`;
#'   baseline GDP growth path.
#' @param primary_balance Numeric scalar or vector of length `horizon`;
#'   baseline primary balance-to-GDP path.
#' @param shocks A `dk_shocks` object (from [dk_estimate_shocks()]) providing
#'   the shock distribution, or `NULL`.
#' @param shock_vcov Optional 3x3 variance-covariance matrix (alternative to
#'   `shocks`). Rows/columns ordered: growth, interest_rate, primary_balance.
#'   Ignored if `shocks` is provided.
#' @param n_sim Integer; number of Monte Carlo simulations (default 1000).
#' @param horizon Integer; projection horizon in years (default 5).
#' @param confidence Numeric vector of quantile levels for fan bands
#'   (default `c(0.10, 0.25, 0.50, 0.75, 0.90)`).
#' @param seed Optional integer seed for reproducibility.
#'
#' @return An S3 object of class `dk_fan` with components:
#' \describe{
#'   \item{simulations}{Matrix of dimension `n_sim` x (`horizon` + 1)
#'     containing all simulated debt paths.}
#'   \item{quantiles}{Matrix of quantiles at each time step, with rows
#'     corresponding to the `confidence` levels.}
#'   \item{baseline}{Numeric vector of length `horizon` + 1; the
#'     deterministic baseline debt path.}
#'   \item{confidence}{The quantile levels used.}
#'   \item{horizon}{The projection horizon.}
#'   \item{prob_above}{Named list with the probability of debt exceeding
#'     60 percent, 90 percent, and 120 percent of GDP at the terminal year.}
#' }
#'
#' @examples
#' set.seed(1)
#' n <- 30
#' g <- rnorm(n, 0.02, 0.015)
#' r <- rnorm(n, 0.03, 0.01)
#' pb <- rnorm(n, -0.02, 0.01)
#' shocks <- dk_estimate_shocks(g, r, pb)
#'
#' fan <- dk_fan_chart(
#'   debt = 0.90,
#'   interest_rate = 0.03,
#'   gdp_growth = 0.02,
#'   primary_balance = -0.02,
#'   shocks = shocks,
#'   n_sim = 500,
#'   horizon = 10,
#'   seed = 42
#' )
#' print(fan)
#'
#' @export
dk_fan_chart <- function(debt,
                         interest_rate,
                         gdp_growth,
                         primary_balance,
                         shocks = NULL,
                         shock_vcov = NULL,
                         n_sim = 1000L,
                         horizon = 5L,
                         confidence = c(0.10, 0.25, 0.50, 0.75, 0.90),
                         seed = NULL) {

  # ---- Validation ----
  validate_scalar(debt, "debt")
  validate_positive_integer(n_sim, "n_sim")
  validate_positive_integer(horizon, "horizon")

  validate_numeric_vector(interest_rate, "interest_rate")
  validate_numeric_vector(gdp_growth, "gdp_growth")
  validate_numeric_vector(primary_balance, "primary_balance")

  r_path  <- recycle_input(interest_rate, horizon, "interest_rate")
  g_path  <- recycle_input(gdp_growth, horizon, "gdp_growth")
  pb_path <- recycle_input(primary_balance, horizon, "primary_balance")

  validate_numeric_vector(confidence, "confidence")
  if (any(confidence <= 0 | confidence >= 1)) {
    cli_abort("{.arg confidence} values must be between 0 and 1 (exclusive).")
  }

  # ---- Resolve shock vcov ----
  has_shocks <- !is.null(shocks)
  has_vcov   <- !is.null(shock_vcov)

  if (has_shocks) {
    if (!inherits(shocks, "dk_shocks")) {
      cli_abort("{.arg shocks} must be a {.cls dk_shocks} object.")
    }
    vcov_mat <- shocks$vcov
  } else if (has_vcov) {
    if (!is.matrix(shock_vcov) || !all(dim(shock_vcov) == c(3, 3))) {
      cli_abort("{.arg shock_vcov} must be a 3x3 matrix.")
    }
    vcov_mat <- shock_vcov
  } else {
    vcov_mat <- NULL
  }

  # ---- Set seed ----
  if (!is.null(seed)) {
    set.seed(seed)
  }

  # ---- Generate shocks ----
  use_bootstrap <- has_shocks && isTRUE(shocks$bootstrap) &&
    !is.null(shocks$residuals)

  if (use_bootstrap) {
    # Bootstrap: resample rows of the residual matrix with replacement
    n_resid <- nrow(shocks$residuals)
    idx <- sample.int(n_resid, size = n_sim * horizon, replace = TRUE)
    shock_draws <- shocks$residuals[idx, , drop = FALSE]
    dim(shock_draws) <- c(n_sim, horizon, 3)
  } else if (!is.null(vcov_mat)) {
    # Cholesky decomposition: vcov = L %*% t(L)
    L <- t(chol(vcov_mat))  # lower triangular
    # Draw standard normal: (n_sim * horizon) x 3
    Z <- matrix(stats::rnorm(n_sim * horizon * 3), nrow = n_sim * horizon, ncol = 3)
    # Transform to correlated shocks
    shock_draws <- Z %*% t(L)  # (n_sim*horizon) x 3
    # Reshape into array: n_sim x horizon x 3
    dim(shock_draws) <- c(n_sim, horizon, 3)
  } else {
    shock_draws <- array(0, dim = c(n_sim, horizon, 3))
  }

  # ---- Baseline path (no shocks) ----
  baseline <- numeric(horizon + 1)
  baseline[1] <- debt
  for (t in seq_len(horizon)) {
    baseline[t + 1] <- baseline[t] * (1 + r_path[t]) / (1 + g_path[t]) - pb_path[t]
  }

  # ---- Simulate ----
  sim_mat <- matrix(NA_real_, nrow = n_sim, ncol = horizon + 1)
  sim_mat[, 1] <- debt

  for (t in seq_len(horizon)) {
    g_shock  <- shock_draws[, t, 1]
    r_shock  <- shock_draws[, t, 2]
    pb_shock <- shock_draws[, t, 3]

    g_t  <- g_path[t]  + g_shock
    r_t  <- r_path[t]  + r_shock
    pb_t <- pb_path[t] + pb_shock

    sim_mat[, t + 1] <- sim_mat[, t] * (1 + r_t) / (1 + g_t) - pb_t
  }

  # ---- Quantiles ----
  q_mat <- apply(sim_mat, 2, stats::quantile, probs = sort(confidence))
  if (length(confidence) == 1) {
    q_mat <- matrix(q_mat, nrow = 1)
  }
  rownames(q_mat) <- paste0("q", sort(confidence) * 100)
  colnames(q_mat) <- paste0("t", 0:horizon)

  # ---- Probability of exceeding thresholds at terminal year ----
  terminal <- sim_mat[, horizon + 1]
  prob_above <- list(
    "60%"  = mean(terminal > 0.60),
    "90%"  = mean(terminal > 0.90),
    "120%" = mean(terminal > 1.20)
  )

  structure(
    list(
      simulations = sim_mat,
      quantiles   = q_mat,
      baseline    = baseline,
      confidence  = sort(confidence),
      horizon     = horizon,
      prob_above  = prob_above,
      n_sim       = n_sim
    ),
    class = "dk_fan"
  )
}


#' @export
print.dk_fan <- function(x, ...) {
  cli_h1("Stochastic Debt Fan Chart")
  cli_bullets(c(
    "*" = "Simulations: {x$n_sim}",
    "*" = "Horizon: {x$horizon} years",
    "*" = "Initial debt: {fmt_pct(x$baseline[1])} of GDP",
    "*" = "Baseline terminal debt: {fmt_pct(x$baseline[x$horizon + 1])} of GDP"
  ))

  cli_bullets(c("*" = "Median terminal debt: {fmt_pct(stats::quantile(x$simulations[, x$horizon + 1], 0.5))} of GDP"))

  cli_bullets(c("*" = "Probability debt exceeds thresholds at horizon:"))
  for (nm in names(x$prob_above)) {
    cat(sprintf("    %s of GDP: %s\n", nm, fmt_pct(x$prob_above[[nm]])))
  }
  invisible(x)
}


#' @export
plot.dk_fan <- function(x, ...) {
  h <- x$horizon
  tt <- 0:h
  q <- x$quantiles
  conf <- x$confidence

  # Determine y range
  y_range <- range(q, x$baseline, na.rm = TRUE)
  y_pad <- diff(y_range) * 0.05
  y_lim <- c(y_range[1] - y_pad, y_range[2] + y_pad)

  plot(
    tt, x$baseline,
    type = "n",
    xlab = "Year",
    ylab = "Debt / GDP",
    ylim = y_lim,
    main = "Stochastic Debt Projection",
    xaxt = "n",
    ...
  )
  axis(1, at = tt)
  grid(col = "grey90")

  # Draw shaded fan bands (symmetric pairs from outer to inner)
  n_q <- length(conf)
  # Pair quantiles: (1st, last), (2nd, 2nd-last), etc.
  # Colors go from light to dark for inner bands
  band_colours <- c(
    adjustcolor("steelblue", alpha.f = 0.15),
    adjustcolor("steelblue", alpha.f = 0.25),
    adjustcolor("steelblue", alpha.f = 0.35),
    adjustcolor("steelblue", alpha.f = 0.45),
    adjustcolor("steelblue", alpha.f = 0.55)
  )

  # Find symmetric pairs
  mid <- ceiling(n_q / 2)
  pair_idx <- 1
  for (i in seq_len(mid)) {
    j <- n_q - i + 1
    if (i >= j) break
    lower_row <- i
    upper_row <- j
    col_idx <- min(pair_idx, length(band_colours))
    polygon(
      c(tt, rev(tt)),
      c(q[lower_row, ], rev(q[upper_row, ])),
      col = band_colours[col_idx],
      border = NA
    )
    pair_idx <- pair_idx + 1
  }

  # Draw median if present
  median_row <- which(abs(conf - 0.5) < 1e-8)
  if (length(median_row) == 1) {
    lines(tt, q[median_row, ], col = "steelblue", lwd = 2, lty = 2)
  }

  # Draw baseline
  lines(tt, x$baseline, col = "black", lwd = 2.5)

  # Reference lines
  abline(h = 0.60, lty = 3, col = "darkgreen", lwd = 1)
  abline(h = 0.90, lty = 3, col = "orange", lwd = 1)
  if (y_lim[2] > 1.15) {
    abline(h = 1.20, lty = 3, col = "red", lwd = 1)
  }

  # Legend
  legend_labels <- c("Baseline", "Median")
  legend_cols   <- c("black", "steelblue")
  legend_lwd    <- c(2.5, 2)
  legend_lty    <- c(1, 2)

  legend(
    "topleft",
    legend = legend_labels,
    col = legend_cols,
    lwd = legend_lwd,
    lty = legend_lty,
    bty = "n"
  )

  invisible(x)
}
