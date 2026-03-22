#' Estimate Joint Distribution of Macro Shocks
#'
#' Estimates the joint distribution of GDP growth, interest rate, and primary
#' balance shocks for use in stochastic debt sustainability analysis. Three
#' estimation methods are supported: a VAR(1) model (default), residual
#' bootstrap, and a simple multivariate normal fit.
#'
#' For `method = "var"`, a VAR(1) is estimated equation-by-equation via OLS
#' on the lagged system. The residual variance-covariance matrix captures the
#' joint shock distribution. For `method = "bootstrap"`, the same VAR(1) is
#' estimated and residuals are stored for block resampling. For
#' `method = "normal"`, the sample means and covariance of the raw series are
#' used directly.
#'
#' @param gdp_growth Numeric vector of historical real GDP growth rates.
#' @param interest_rate Numeric vector of historical nominal (or real)
#'   interest rates.
#' @param primary_balance Numeric vector of historical primary
#'   balance-to-GDP ratios.
#' @param method Character; one of `"var"` (default), `"bootstrap"`, or
#'   `"normal"`.
#' @param years Optional numeric vector of year labels (same length as data).
#'
#' @return An S3 object of class `dk_shocks` with components:
#' \describe{
#'   \item{vcov}{3x3 variance-covariance matrix with rows/columns named
#'     `growth`, `interest_rate`, `primary_balance`.}
#'   \item{means}{Named numeric vector of variable means.}
#'   \item{method}{The estimation method used.}
#'   \item{residuals}{Matrix of residuals (for `"var"` and `"bootstrap"`) or
#'     `NULL` (for `"normal"`).}
#'   \item{var_coefficients}{VAR(1) coefficient matrix (for `"var"`) or
#'     `NULL`.}
#'   \item{n_obs}{Number of observations used.}
#' }
#'
#' @examples
#' set.seed(1)
#' n <- 30
#' g <- rnorm(n, 0.02, 0.015)
#' r <- rnorm(n, 0.03, 0.01)
#' pb <- rnorm(n, -0.02, 0.01)
#' shocks <- dk_estimate_shocks(g, r, pb)
#' print(shocks)
#'
#' @export
dk_estimate_shocks <- function(gdp_growth,
                               interest_rate,
                               primary_balance,
                               method = c("var", "bootstrap", "normal"),
                               years = NULL) {

  method <- match.arg(method)

  validate_numeric_vector(gdp_growth, "gdp_growth", min_length = 5)
  validate_numeric_vector(interest_rate, "interest_rate", min_length = 5)
  validate_numeric_vector(primary_balance, "primary_balance", min_length = 5)

  n <- length(gdp_growth)
  if (length(interest_rate) != n) {
    cli_abort("{.arg interest_rate} must have the same length as {.arg gdp_growth} ({n}).")
  }
  if (length(primary_balance) != n) {
    cli_abort("{.arg primary_balance} must have the same length as {.arg gdp_growth} ({n}).")
  }

  if (!is.null(years)) {
    if (length(years) != n) {
      cli_abort("{.arg years} must have length {n}, not {length(years)}.")
    }
  }

  var_names <- c("growth", "interest_rate", "primary_balance")

  # Stack data into matrix: n x 3
  Y <- cbind(gdp_growth, interest_rate, primary_balance)
  colnames(Y) <- var_names

  if (method == "normal") {
    means <- colMeans(Y)
    names(means) <- var_names
    vcov_mat <- stats::cov(Y)
    rownames(vcov_mat) <- colnames(vcov_mat) <- var_names

    return(structure(
      list(
        vcov             = vcov_mat,
        means            = means,
        method           = "normal",
        residuals        = NULL,
        var_coefficients = NULL,
        n_obs            = n
      ),
      class = "dk_shocks"
    ))
  }

  # ---- VAR(1) estimation via OLS ----
  # Y(t) = C + A * Y(t-1) + e(t)
  # Estimate equation by equation

  Y_dep  <- Y[2:n, , drop = FALSE]   # t = 2,...,n
  Y_lag  <- Y[1:(n - 1), , drop = FALSE]  # t = 1,...,n-1
  n_eff  <- n - 1

  # Design matrix: [1, Y_lag]  (n_eff x 4)
  X <- cbind(intercept = 1, Y_lag)

  # OLS: beta = (X'X)^{-1} X'Y_dep
  XtX_inv <- solve(crossprod(X))
  beta <- XtX_inv %*% crossprod(X, Y_dep)  # 4 x 3

  # Fitted and residuals
  Y_hat <- X %*% beta
  resid_mat <- Y_dep - Y_hat
  colnames(resid_mat) <- var_names

  # Residual vcov (unbiased: divide by n_eff - k)
  k <- ncol(X)
  vcov_mat <- crossprod(resid_mat) / (n_eff - k)
  rownames(vcov_mat) <- colnames(vcov_mat) <- var_names

  # Coefficient matrix A (3x3): rows = equation, cols = lag variable
  A <- t(beta[2:4, , drop = FALSE])
  rownames(A) <- var_names
  colnames(A) <- var_names

  # Intercept vector
  intercepts <- beta[1, ]
  names(intercepts) <- var_names

  # Means from raw data
  means <- colMeans(Y)
  names(means) <- var_names

  structure(
    list(
      vcov             = vcov_mat,
      means            = means,
      method           = method,
      residuals        = resid_mat,
      var_coefficients = A,
      var_intercepts   = intercepts,
      n_obs            = n_eff
    ),
    class = "dk_shocks"
  )
}


#' @export
print.dk_shocks <- function(x, ...) {
  cli_h1("Macro Shock Estimates")
  cli_bullets(c(
    "*" = "Method: {x$method}",
    "*" = "Observations: {x$n_obs}"
  ))

  cli_bullets(c("*" = "Variable means:"))
  cat(sprintf(
    "    growth = %s, interest_rate = %s, primary_balance = %s\n",
    fmt_pct(x$means["growth"]),
    fmt_pct(x$means["interest_rate"]),
    fmt_pct(x$means["primary_balance"])
  ))

  cli_bullets(c("*" = "Shock std. deviations:"))
  sds <- sqrt(diag(x$vcov))
  cat(sprintf(
    "    growth = %s, interest_rate = %s, primary_balance = %s\n",
    fmt_pp(sds["growth"]),
    fmt_pp(sds["interest_rate"]),
    fmt_pp(sds["primary_balance"])
  ))

  cli_bullets(c("*" = "Shock correlation matrix:"))
  sdk_mat <- diag(1 / sds)
  cor_mat <- sdk_mat %*% x$vcov %*% sdk_mat
  rownames(cor_mat) <- colnames(cor_mat) <- names(sds)
  print(round(cor_mat, 3))

  invisible(x)
}
