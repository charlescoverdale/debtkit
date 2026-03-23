# Tests for v0.2.0 features

# ---- HAC (Newey-West) standard errors ----

test_that("HAC SEs differ from OLS SEs for autocorrelated data", {
  set.seed(42)
  n <- 100
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  # Generate autocorrelated errors
  e <- numeric(n)
  e[1] <- rnorm(1, 0, 0.01)
  for (i in 2:n) e[i] <- 0.7 * e[i - 1] + rnorm(1, 0, 0.005)
  pb <- 0.04 * debt + e

  ols_result <- dk_bohn_test(pb, debt, robust_se = FALSE)
  hac_result <- dk_bohn_test(pb, debt, robust_se = TRUE)

  # Same point estimate

  expect_equal(ols_result$rho, hac_result$rho, tolerance = 1e-10)
  # Different standard errors
  expect_false(isTRUE(all.equal(ols_result$rho_se, hac_result$rho_se)))
  # HAC flag stored
  expect_true(hac_result$robust_se)
  expect_false(ols_result$robust_se)
})

test_that("HAC SEs work with controls", {
  set.seed(42)
  n <- 100
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  gap <- rnorm(n, 0, 0.01)
  pb <- 0.04 * debt + 0.5 * gap + rnorm(n, 0, 0.005)
  controls <- data.frame(output_gap = gap)
  result <- dk_bohn_test(pb, debt, controls = controls, robust_se = TRUE)
  expect_s3_class(result, "dk_bohn")
  expect_true(result$robust_se)
})

test_that("backward compatibility: robust_se = FALSE by default", {
  set.seed(42)
  n <- 50
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  pb <- 0.04 * debt + rnorm(n, 0, 0.005)
  result <- dk_bohn_test(pb, debt)
  expect_false(result$robust_se)
})

test_that("HAC works with quadratic method", {
  set.seed(42)
  n <- 100
  debt <- seq(0.3, 1.2, length.out = n)
  pb <- 0.08 * debt - 0.04 * debt^2 + rnorm(n, 0, 0.003)
  result <- dk_bohn_test(pb, debt, method = "quadratic", robust_se = TRUE)
  expect_s3_class(result, "dk_bohn")
  expect_true(result$robust_se)
  expect_true(!is.null(result$rho2))
})


# ---- Data-driven stress test calibration ----

test_that("calibrate produces different shock sizes than defaults", {
  set.seed(42)
  hist_g  <- rnorm(30, 0.02, 0.03)
  hist_r  <- rnorm(30, 0.04, 0.015)
  hist_pb <- rnorm(30, -0.01, 0.02)

  st_default <- dk_stress_test(0.90, 0.03, 0.04, 0.01)
  st_calib <- dk_stress_test(0.90, 0.03, 0.04, 0.01,
    calibrate = list(
      gdp_growth_hist = hist_g,
      interest_rate_hist = hist_r,
      primary_balance_hist = hist_pb
    )
  )

  # Terminal debt values should differ
  expect_false(isTRUE(all.equal(
    st_default$terminal["growth"],
    st_calib$terminal["growth"]
  )))
})

test_that("calibrate uses historical SDs correctly", {
  set.seed(42)
  hist_g  <- rnorm(50, 0.02, 0.03)
  hist_r  <- rnorm(50, 0.04, 0.015)
  hist_pb <- rnorm(50, -0.01, 0.02)

  # The growth shock should be -1 * sd(hist_g)
  expected_growth_shock <- -1 * sd(hist_g)
  expected_interest_shock <- 1 * sd(hist_r)

  st_calib <- dk_stress_test(0.90, 0.03, 0.04, 0.01,
    calibrate = list(
      gdp_growth_hist = hist_g,
      interest_rate_hist = hist_r,
      primary_balance_hist = hist_pb
    )
  )

  # Stored growth_shock should match
  expect_equal(st_calib$inputs$growth_shock, expected_growth_shock,
               tolerance = 1e-10)
  expect_equal(st_calib$inputs$interest_shock, expected_interest_shock,
               tolerance = 1e-10)
})

test_that("calibrate = NULL preserves defaults", {
  st <- dk_stress_test(0.90, 0.03, 0.04, 0.01, calibrate = NULL)
  expect_equal(st$inputs$growth_shock, -0.01)
  expect_equal(st$inputs$interest_shock, 0.02)
  expect_equal(st$inputs$pb_shock, -0.01)
})

test_that("calibrate rejects invalid input", {
  expect_error(
    dk_stress_test(0.90, 0.03, 0.04, 0.01, calibrate = list(gdp_growth_hist = 1:5)),
    "calibrate"
  )
})


# ---- Quadratic Bohn test ----

test_that("quadratic method recovers known rho2", {
  set.seed(42)
  n <- 200
  debt <- seq(0.3, 1.5, length.out = n)
  # pb = 0.10 * debt - 0.05 * debt^2 + noise
  pb <- 0.10 * debt - 0.05 * debt^2 + rnorm(n, 0, 0.002)
  result <- dk_bohn_test(pb, debt, method = "quadratic")
  expect_equal(result$method, "quadratic")
  # rho2 should be close to -0.05

  expect_true(abs(result$rho2 - (-0.05)) < 0.02)
  # rho should be close to 0.10
  expect_true(abs(result$rho - 0.10) < 0.02)
  # Turning point should be around -0.10 / (2 * -0.05) = 1.0
  expect_true(abs(result$turning_point - 1.0) < 0.2)
  # rho2 should be significant
  expect_true(result$rho2_pvalue < 0.05)
})

test_that("quadratic method returns all expected fields", {
  set.seed(42)
  n <- 100
  debt <- seq(0.3, 1.2, length.out = n)
  pb <- 0.08 * debt - 0.04 * debt^2 + rnorm(n, 0, 0.003)
  result <- dk_bohn_test(pb, debt, method = "quadratic")
  expect_true(!is.null(result$rho2))
  expect_true(!is.null(result$rho2_se))
  expect_true(!is.null(result$rho2_pvalue))
  expect_true(!is.null(result$turning_point))
  expect_equal(result$method, "quadratic")
})

test_that("quadratic with controls works", {
  set.seed(42)
  n <- 100
  debt <- seq(0.3, 1.2, length.out = n)
  gap <- rnorm(n, 0, 0.01)
  pb <- 0.08 * debt - 0.04 * debt^2 + 0.5 * gap + rnorm(n, 0, 0.003)
  controls <- data.frame(output_gap = gap)
  result <- dk_bohn_test(pb, debt, controls = controls, method = "quadratic")
  expect_s3_class(result, "dk_bohn")
  # intercept + debt + debt2 + output_gap = 4 coefficients
  expect_length(coef(result$model), 4)
})

test_that("quadratic print runs without error", {
  set.seed(42)
  n <- 100
  debt <- seq(0.3, 1.2, length.out = n)
  pb <- 0.08 * debt - 0.04 * debt^2 + rnorm(n, 0, 0.003)
  result <- dk_bohn_test(pb, debt, method = "quadratic")
  expect_no_error(print(result))
})

test_that("quadratic plot runs without error", {
  set.seed(42)
  n <- 100
  debt <- seq(0.3, 1.2, length.out = n)
  pb <- 0.08 * debt - 0.04 * debt^2 + rnorm(n, 0, 0.003)
  result <- dk_bohn_test(pb, debt, method = "quadratic")
  expect_no_error(plot(result))
})


# ---- Bootstrap resampling ----

test_that("bootstrap shocks produce valid fan chart output", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb, method = "bootstrap")
  expect_true(isTRUE(shocks$bootstrap))
  expect_true(!is.null(shocks$residuals))

  fan <- dk_fan_chart(
    debt = 0.90,
    interest_rate = 0.03,
    gdp_growth = 0.02,
    primary_balance = -0.02,
    shocks = shocks,
    n_sim = 200,
    horizon = 5,
    seed = 42
  )
  expect_s3_class(fan, "dk_fan")
  expect_equal(dim(fan$simulations), c(200, 6))
  # All simulations start at initial debt
  expect_true(all(fan$simulations[, 1] == 0.90))
})

test_that("bootstrap fan chart differs from VAR normal draws", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)

  shocks_var <- dk_estimate_shocks(g, r, pb, method = "var")
  shocks_boot <- dk_estimate_shocks(g, r, pb, method = "bootstrap")

  fan_var <- dk_fan_chart(0.90, 0.03, 0.02, -0.02,
    shocks = shocks_var, n_sim = 500, horizon = 5, seed = 42)
  fan_boot <- dk_fan_chart(0.90, 0.03, 0.02, -0.02,
    shocks = shocks_boot, n_sim = 500, horizon = 5, seed = 42)

  # Terminal distributions should differ (different drawing methods)
  expect_false(isTRUE(all.equal(
    fan_var$simulations[, 6],
    fan_boot$simulations[, 6]
  )))
})

test_that("bootstrap shocks with seed are reproducible", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb, method = "bootstrap")

  fan1 <- dk_fan_chart(0.90, 0.03, 0.02, -0.02,
    shocks = shocks, n_sim = 100, horizon = 5, seed = 123)
  fan2 <- dk_fan_chart(0.90, 0.03, 0.02, -0.02,
    shocks = shocks, n_sim = 100, horizon = 5, seed = 123)
  expect_equal(fan1$simulations, fan2$simulations)
})

test_that("VAR method does not set bootstrap flag", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb, method = "var")
  expect_false(isTRUE(shocks$bootstrap))
})


# ---- Backward compatibility ----

test_that("existing OLS Bohn test without new params still works", {
  set.seed(42)
  n <- 50
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  pb <- 0.04 * debt + rnorm(n, 0, 0.005)
  result <- dk_bohn_test(pb, debt)
  expect_s3_class(result, "dk_bohn")
  expect_equal(result$method, "ols")
  expect_true(is.numeric(result$rho))
})

test_that("existing stress test without calibrate still works", {
  st <- dk_stress_test(0.90, 0.03, 0.04, 0.01)
  expect_s3_class(st, "dk_stress")
  expect_equal(st$inputs$growth_shock, -0.01)
})

test_that("existing fan chart with VAR shocks still works", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb, method = "var")
  fan <- dk_fan_chart(0.90, 0.03, 0.02, -0.02, shocks = shocks,
                      n_sim = 50, horizon = 5, seed = 42)
  expect_s3_class(fan, "dk_fan")
})
