#' Bohn's Fiscal Reaction Function Test
#'
#' Estimates the fiscal reaction function following Bohn (1998):
#' `pb(t) = rho * d(t-1) + alpha * Z(t) + epsilon(t)`,
#' where `pb` is the primary balance-to-GDP ratio, `d` is lagged
#' debt-to-GDP, and `Z` is a matrix of control variables.
#'
#' A positive and statistically significant `rho` indicates that the
#' government systematically raises the primary surplus in response to
#' rising debt, satisfying a sufficient condition for debt sustainability.
#'
#' @param primary_balance Numeric vector of primary balance-to-GDP ratios.
#' @param debt Numeric vector of lagged debt-to-GDP ratios (same length as
#'   `primary_balance`).
#' @param controls Optional data.frame of control variables (same number of
#'   rows as `primary_balance`). Each column enters the regression as a
#'   separate regressor.
#' @param method Character; `"ols"` (default) for a single OLS regression over
#'   the full sample, `"rolling"` for rolling-window regressions, or
#'   `"quadratic"` for a non-linear specification that includes a squared debt
#'   term to detect fiscal fatigue (Ghosh et al. 2013).
#' @param window Integer; rolling window size. Required when
#'   `method = "rolling"`, ignored otherwise.
#' @param robust_se Logical; if `TRUE`, compute Newey-West HAC standard errors
#'   using a Bartlett kernel with automatic bandwidth
#'   `floor(4*(n/100)^(2/9))`. This corrects for serial correlation in
#'   fiscal data. Default `FALSE`.
#'
#' @return An S3 object of class `dk_bohn` with components:
#' \describe{
#'   \item{rho}{Estimated fiscal response coefficient (full sample or last
#'     rolling window).}
#'   \item{rho_se}{Standard error of `rho`.}
#'   \item{rho_pvalue}{p-value for the test H0: rho = 0.}
#'   \item{sustainable}{Logical; `TRUE` if `rho > 0` and `rho_pvalue < 0.05`.}
#'   \item{model}{The `lm` object from the full-sample (OLS/quadratic) or
#'     last-window (rolling) regression.}
#'   \item{method}{The method used (`"ols"`, `"rolling"`, or `"quadratic"`).}
#'   \item{rho_ts}{A data.frame with columns `index`, `rho`, `rho_lower`,
#'     `rho_upper` if `method = "rolling"`; `NULL` otherwise.}
#'   \item{robust_se}{Logical; whether HAC standard errors were used.}
#'   \item{rho2}{Coefficient on debt squared (only for `method = "quadratic"`).}
#'   \item{rho2_se}{Standard error of `rho2` (quadratic only).}
#'   \item{rho2_pvalue}{p-value for `rho2` (quadratic only).}
#'   \item{turning_point}{Debt level where fiscal response peaks,
#'     `-rho/(2*rho2)` (quadratic only).}
#' }
#'
#' @references
#' Bohn, H. (1998). "The Behavior of U.S. Public Debt and
#'   Deficits." \emph{Quarterly Journal of Economics}, 113(3), 949--963.
#'   \doi{10.1162/003355398555793}
#'
#' Ghosh, A.R., Kim, J.I., Mendoza, E.G., Ostry, J.D. and Qureshi, M.S.
#'   (2013). "Fiscal Fatigue, Fiscal Space and Debt Sustainability in Advanced
#'   Economies." \emph{The Economic Journal}, 123(566), F4--F30.
#'
#' @examples
#' # Simulate data with positive fiscal response
#' set.seed(42)
#' n <- 50
#' debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
#' pb <- 0.04 * debt + rnorm(n, 0, 0.005)
#' result <- dk_bohn_test(pb, debt)
#' print(result)
#'
#' @export
dk_bohn_test <- function(primary_balance,
                         debt,
                         controls = NULL,
                         method = c("ols", "rolling", "quadratic"),
                         window = NULL,
                         robust_se = FALSE) {


  method <- match.arg(method)


  validate_numeric_vector(primary_balance, "primary_balance", min_length = 3)
  validate_numeric_vector(debt, "debt", min_length = 3)

  n <- length(primary_balance)
  if (length(debt) != n) {
    cli_abort("{.arg debt} must have the same length as {.arg primary_balance} ({n}).")
  }


  if (!is.null(controls)) {
    if (!is.data.frame(controls)) {
      cli_abort("{.arg controls} must be a data.frame or NULL.")
    }
    if (nrow(controls) != n) {
      cli_abort("{.arg controls} must have {n} rows, not {nrow(controls)}.")
    }
  }


  if (method == "rolling") {
    if (is.null(window)) {
      cli_abort("{.arg window} is required when {.arg method} is {.val rolling}.")
    }
    validate_positive_integer(window, "window")
    if (window > n) {
      cli_abort("{.arg window} ({window}) must not exceed sample size ({n}).")
    }
    if (window < 5) {
      cli_warn("{.arg window} is very small ({window}); estimates may be unreliable.")
    }
  }

  # ---- HAC (Newey-West) helper ----
  compute_hac <- function(fit, n_obs) {
    X <- stats::model.matrix(fit)
    e <- stats::residuals(fit)
    k <- ncol(X)
    bandwidth <- floor(4 * (n_obs / 100)^(2/9))

    # Gamma_0
    S <- crossprod(X * e) / n_obs

    # Add lagged cross-products with Bartlett weights
    if (bandwidth > 0) {
      for (j in seq_len(bandwidth)) {
        w_j <- 1 - j / (bandwidth + 1)
        Gamma_j <- crossprod(X[(j + 1):n_obs, , drop = FALSE] * e[(j + 1):n_obs],
                             X[1:(n_obs - j), , drop = FALSE] * e[1:(n_obs - j)]) / n_obs
        S <- S + w_j * (Gamma_j + t(Gamma_j))
      }
    }

    XtX_inv <- solve(crossprod(X))
    V_hac <- n_obs * XtX_inv %*% S %*% XtX_inv
    sqrt(diag(V_hac))
  }

  # ---- Build regression data ----
  reg_data <- data.frame(pb = primary_balance, debt = debt)
  if (!is.null(controls)) {
    reg_data <- cbind(reg_data, controls)
  }

  # ---- Quadratic method ----
  if (method == "quadratic") {
    reg_data$debt2 <- debt^2
    fit <- stats::lm(pb ~ ., data = reg_data)
    smry <- summary(fit)
    coef_tbl <- smry$coefficients

    rho <- unname(coef_tbl["debt", "Estimate"])
    rho2 <- unname(coef_tbl["debt2", "Estimate"])

    if (robust_se) {
      hac_se <- compute_hac(fit, n)
      # Map names to positions
      idx_debt <- which(names(stats::coef(fit)) == "debt")
      idx_debt2 <- which(names(stats::coef(fit)) == "debt2")
      rho_se <- hac_se[idx_debt]
      rho2_se <- hac_se[idx_debt2]
      df_resid <- fit$df.residual
      rho_tstat <- rho / rho_se
      rho2_tstat <- rho2 / rho2_se
      rho_pvalue <- 2 * stats::pt(abs(rho_tstat), df = df_resid, lower.tail = FALSE)
      rho2_pvalue <- 2 * stats::pt(abs(rho2_tstat), df = df_resid, lower.tail = FALSE)
    } else {
      rho_se <- unname(coef_tbl["debt", "Std. Error"])
      rho_pvalue <- unname(coef_tbl["debt", "Pr(>|t|)"])
      rho2_se <- unname(coef_tbl["debt2", "Std. Error"])
      rho2_pvalue <- unname(coef_tbl["debt2", "Pr(>|t|)"])
    }

    turning_point <- if (abs(rho2) > 1e-15) -rho / (2 * rho2) else NA_real_

    return(structure(
      list(
        rho          = rho,
        rho_se       = rho_se,
        rho_pvalue   = rho_pvalue,
        sustainable  = (rho > 0) && (rho_pvalue < 0.05),
        model        = fit,
        method       = "quadratic",
        rho_ts       = NULL,
        n_obs        = n,
        robust_se    = robust_se,
        rho2         = rho2,
        rho2_se      = rho2_se,
        rho2_pvalue  = rho2_pvalue,
        turning_point = turning_point
      ),
      class = "dk_bohn"
    ))
  }

  # ---- OLS method ----
  if (method == "ols") {
    fit <- stats::lm(pb ~ ., data = reg_data)
    smry <- summary(fit)
    coef_tbl <- smry$coefficients

    rho <- unname(coef_tbl["debt", "Estimate"])

    if (robust_se) {
      hac_se <- compute_hac(fit, n)
      idx_debt <- which(names(stats::coef(fit)) == "debt")
      rho_se <- hac_se[idx_debt]
      df_resid <- fit$df.residual
      rho_tstat <- rho / rho_se
      rho_pvalue <- 2 * stats::pt(abs(rho_tstat), df = df_resid, lower.tail = FALSE)
    } else {
      rho_se <- unname(coef_tbl["debt", "Std. Error"])
      rho_pvalue <- unname(coef_tbl["debt", "Pr(>|t|)"])
    }

    out <- structure(
      list(
        rho        = rho,
        rho_se     = rho_se,
        rho_pvalue = rho_pvalue,
        sustainable = (rho > 0) && (rho_pvalue < 0.05),
        model      = fit,
        method     = "ols",
        rho_ts     = NULL,
        n_obs      = n,
        robust_se  = robust_se
      ),
      class = "dk_bohn"
    )
    return(out)
  }

  # ---- Rolling method ----
  n_windows <- n - window + 1
  rho_vec   <- numeric(n_windows)
  se_vec    <- numeric(n_windows)
  pval_vec  <- numeric(n_windows)

  last_fit <- NULL

  for (i in seq_len(n_windows)) {
    idx <- i:(i + window - 1)
    win_data <- reg_data[idx, , drop = FALSE]
    fit_i <- stats::lm(pb ~ ., data = win_data)
    smry_i <- summary(fit_i)
    coef_tbl_i <- smry_i$coefficients

    rho_vec[i]  <- unname(coef_tbl_i["debt", "Estimate"])
    se_vec[i]   <- unname(coef_tbl_i["debt", "Std. Error"])
    pval_vec[i] <- unname(coef_tbl_i["debt", "Pr(>|t|)"])

    last_fit <- fit_i
  }

  # 95% confidence band
  rho_lower <- rho_vec - 1.96 * se_vec
  rho_upper <- rho_vec + 1.96 * se_vec

  rho_ts <- data.frame(
    index     = seq(window, n),
    rho       = rho_vec,
    rho_lower = rho_lower,
    rho_upper = rho_upper
  )

  # Use last window for headline results
  rho_last   <- rho_vec[n_windows]
  se_last    <- se_vec[n_windows]
  pval_last  <- pval_vec[n_windows]

  structure(
    list(
      rho        = rho_last,
      rho_se     = se_last,
      rho_pvalue = pval_last,
      sustainable = (rho_last > 0) && (pval_last < 0.05),
      model      = last_fit,
      method     = "rolling",
      rho_ts     = rho_ts,
      n_obs      = n,
      window     = window,
      robust_se  = FALSE
    ),
    class = "dk_bohn"
  )
}


#' @export
print.dk_bohn <- function(x, ...) {
  cli_h1("Bohn Fiscal Reaction Function")
  se_label <- if (isTRUE(x$robust_se)) " (HAC)" else ""
  cli_bullets(c(
    "*" = "Method: {x$method}{se_label}",
    "*" = "Observations: {x$n_obs}"
  ))
  if (x$method == "rolling") {
    cli_bullets(c("*" = "Window size: {x$window}"))
  }
  cli_bullets(c(
    "*" = "rho = {round(x$rho, 4)} (SE = {round(x$rho_se, 4)}, p = {format.pval(x$rho_pvalue, digits = 3)})"
  ))
  if (x$method == "quadratic" && !is.null(x$rho2)) {
    cli_bullets(c(
      "*" = "rho2 = {round(x$rho2, 6)} (SE = {round(x$rho2_se, 6)}, p = {format.pval(x$rho2_pvalue, digits = 3)})"
    ))
    if (!is.na(x$turning_point)) {
      cli_bullets(c(
        "*" = "Turning point (debt/GDP): {round(x$turning_point, 3)}"
      ))
    }
    if (x$rho2 < 0 && x$rho2_pvalue < 0.05) {
      cli_bullets(c("!" = "Fiscal fatigue detected: negative and significant rho2."))
    }
  }
  if (x$sustainable) {
    cli_bullets(c("v" = "Sustainable: rho > 0 and significant at 5% level."))
  } else {
    cli_bullets(c("x" = "Not sustainable: rho {ifelse(x$rho <= 0, '<= 0', '> 0 but not significant at 5%')}."))
  }
  invisible(x)
}


#' @export
plot.dk_bohn <- function(x, ...) {
  if (x$method == "rolling") {
    # Rolling rho with confidence band
    ts <- x$rho_ts
    y_range <- range(c(ts$rho_lower, ts$rho_upper), na.rm = TRUE)
    y_pad <- diff(y_range) * 0.1
    y_lim <- c(y_range[1] - y_pad, y_range[2] + y_pad)

    plot(
      ts$index, ts$rho,
      type = "n",
      xlab = "End of window (observation index)",
      ylab = expression(hat(rho)),
      ylim = y_lim,
      main = "Rolling Bohn Fiscal Response Coefficient",
      ...
    )
    grid(col = "grey90")

    polygon(
      c(ts$index, rev(ts$index)),
      c(ts$rho_lower, rev(ts$rho_upper)),
      col = adjustcolor("steelblue", alpha.f = 0.25),
      border = NA
    )
    lines(ts$index, ts$rho, col = "steelblue", lwd = 2)
    abline(h = 0, lty = 2, col = "red", lwd = 1.5)
    legend(
      "topright",
      legend = c(expression(hat(rho)), "95% CI", expression(rho == 0)),
      col = c("steelblue", adjustcolor("steelblue", 0.25), "red"),
      lwd = c(2, 8, 1.5),
      lty = c(1, 1, 2),
      bty = "n"
    )
  } else {
    # OLS / quadratic: coefficient + CI bar
    ci <- stats::confint(x$model)["debt", ]
    rho <- x$rho
    method_label <- if (x$method == "quadratic") "Quadratic" else "OLS"

    old_par <- par(mar = c(4, 4.5, 3, 1))
    on.exit(par(old_par))

    plot(
      1, rho,
      xlim = c(0.5, 1.5),
      ylim = range(c(ci, 0)) * c(1.2, 1.2),
      pch = 19, cex = 1.5,
      col = "steelblue",
      xaxt = "n",
      xlab = "",
      ylab = expression(hat(rho)),
      main = paste0("Bohn Fiscal Response Coefficient (", method_label, ")"),
      ...
    )
    grid(col = "grey90")
    arrows(1, ci[1], 1, ci[2], angle = 90, code = 3, length = 0.15,
           col = "steelblue", lwd = 2)
    abline(h = 0, lty = 2, col = "red", lwd = 1.5)
    legend(
      "topright",
      legend = c(expression(hat(rho) %+-% "95% CI"), expression(rho == 0)),
      col = c("steelblue", "red"),
      lwd = c(2, 1.5),
      lty = c(1, 2),
      pch = c(19, NA),
      bty = "n"
    )
  }
  invisible(x)
}
