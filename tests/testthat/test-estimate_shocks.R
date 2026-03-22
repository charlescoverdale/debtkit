test_that("dk_estimate_shocks returns correct class", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb)
  expect_s3_class(shocks, "dk_shocks")
})

test_that("vcov is 3x3 matrix", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb)
  expect_true(is.matrix(shocks$vcov))
  expect_equal(dim(shocks$vcov), c(3, 3))
})

test_that("vcov is positive semi-definite", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb)
  eigenvalues <- eigen(shocks$vcov, symmetric = TRUE)$values
  expect_true(all(eigenvalues >= -1e-10))
})

test_that("means has 3 elements", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb)
  expect_length(shocks$means, 3)
  expect_equal(names(shocks$means),
               c("growth", "interest_rate", "primary_balance"))
})

test_that("var method returns var_coefficients", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb, method = "var")
  expect_true(!is.null(shocks$var_coefficients))
  expect_true(is.matrix(shocks$var_coefficients))
  expect_equal(dim(shocks$var_coefficients), c(3, 3))
})

test_that("normal method works", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb, method = "normal")
  expect_s3_class(shocks, "dk_shocks")
  expect_equal(shocks$method, "normal")
  expect_null(shocks$var_coefficients)
  expect_null(shocks$residuals)
})

test_that("normal method vcov matches sample covariance", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb, method = "normal")
  expected_vcov <- cov(cbind(g, r, pb))
  expect_equal(unname(shocks$vcov), unname(expected_vcov), tolerance = 1e-10)
})

test_that("rejects mismatched lengths", {
  expect_error(
    dk_estimate_shocks(rnorm(30), rnorm(25), rnorm(30)),
    "interest_rate"
  )
})

test_that("rejects too-short inputs", {
  expect_error(
    dk_estimate_shocks(rnorm(3), rnorm(3), rnorm(3)),
    "gdp_growth"
  )
})

test_that("print runs without error", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb)
  expect_no_error(print(shocks))
})
