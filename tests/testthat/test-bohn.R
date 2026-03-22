test_that("dk_bohn_test returns correct class", {
  set.seed(42)
  n <- 50
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  pb <- 0.04 * debt + rnorm(n, 0, 0.005)
  result <- dk_bohn_test(pb, debt)
  expect_s3_class(result, "dk_bohn")
})

test_that("rho is numeric scalar", {
  set.seed(42)
  n <- 50
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  pb <- 0.04 * debt + rnorm(n, 0, 0.005)
  result <- dk_bohn_test(pb, debt)
  expect_true(is.numeric(result$rho))
  expect_length(result$rho, 1)
})

test_that("sustainable is logical", {
  set.seed(42)
  n <- 50
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  pb <- 0.04 * debt + rnorm(n, 0, 0.005)
  result <- dk_bohn_test(pb, debt)
  expect_true(is.logical(result$sustainable))
  expect_length(result$sustainable, 1)
})

test_that("with positively correlated pb and debt, rho > 0", {
  set.seed(42)
  n <- 100
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  pb <- 0.05 * debt + rnorm(n, 0, 0.002)
  result <- dk_bohn_test(pb, debt)
  expect_true(result$rho > 0)
})

test_that("with controls, model has correct number of coefficients", {
  set.seed(42)
  n <- 50
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  gap <- rnorm(n, 0, 0.01)
  pb <- 0.04 * debt + 0.5 * gap + rnorm(n, 0, 0.005)
  controls <- data.frame(output_gap = gap)
  result <- dk_bohn_test(pb, debt, controls = controls)
  # intercept + debt + output_gap = 3 coefficients
  expect_length(coef(result$model), 3)
})

test_that("rolling method returns rho_ts", {
  set.seed(42)
  n <- 50
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  pb <- 0.04 * debt + rnorm(n, 0, 0.005)
  result <- dk_bohn_test(pb, debt, method = "rolling", window = 20)
  expect_true(!is.null(result$rho_ts))
  expect_true(is.data.frame(result$rho_ts))
  expect_true("rho" %in% names(result$rho_ts))
  expect_true("rho_lower" %in% names(result$rho_ts))
  expect_true("rho_upper" %in% names(result$rho_ts))
})

test_that("rolling window gives correct number of windows", {
  set.seed(42)
  n <- 50
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  pb <- 0.04 * debt + rnorm(n, 0, 0.005)
  window <- 20
  result <- dk_bohn_test(pb, debt, method = "rolling", window = window)
  expect_equal(nrow(result$rho_ts), n - window + 1)
})

test_that("rolling window rejects too-large window", {
  set.seed(42)
  n <- 10
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  pb <- 0.04 * debt + rnorm(n, 0, 0.005)
  expect_error(
    dk_bohn_test(pb, debt, method = "rolling", window = 20),
    "window"
  )
})

test_that("rejects mismatched lengths", {
  expect_error(
    dk_bohn_test(c(0.01, 0.02, 0.03), c(0.5, 0.6)),
    "debt"
  )
})

test_that("OLS method has rho_ts = NULL", {
  set.seed(42)
  n <- 50
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  pb <- 0.04 * debt + rnorm(n, 0, 0.005)
  result <- dk_bohn_test(pb, debt, method = "ols")
  expect_null(result$rho_ts)
})

test_that("print runs without error", {
  set.seed(42)
  n <- 50
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  pb <- 0.04 * debt + rnorm(n, 0, 0.005)
  result <- dk_bohn_test(pb, debt)
  expect_no_error(print(result))
})

test_that("plot runs without error for ols", {
  set.seed(42)
  n <- 50
  debt <- cumsum(rnorm(n, 0.01, 0.02)) + 0.6
  pb <- 0.04 * debt + rnorm(n, 0, 0.005)
  result <- dk_bohn_test(pb, debt, method = "ols")
  expect_no_error(plot(result))
})
