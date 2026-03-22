test_that("dk_fan_chart returns correct class", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb)
  fan <- dk_fan_chart(0.90, 0.03, 0.02, -0.02, shocks = shocks,
                      n_sim = 100, horizon = 5, seed = 42)
  expect_s3_class(fan, "dk_fan")
})

test_that("simulations matrix has correct dimensions", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb)
  n_sim <- 200
  horizon <- 7
  fan <- dk_fan_chart(0.90, 0.03, 0.02, -0.02, shocks = shocks,
                      n_sim = n_sim, horizon = horizon, seed = 42)
  expect_equal(dim(fan$simulations), c(n_sim, horizon + 1))
})

test_that("quantiles matrix has correct dimensions", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb)
  conf <- c(0.10, 0.25, 0.50, 0.75, 0.90)
  horizon <- 5
  fan <- dk_fan_chart(0.90, 0.03, 0.02, -0.02, shocks = shocks,
                      n_sim = 100, horizon = horizon, confidence = conf,
                      seed = 42)
  expect_equal(dim(fan$quantiles), c(length(conf), horizon + 1))
})

test_that("baseline has correct length", {
  fan <- dk_fan_chart(0.90, 0.03, 0.02, -0.02, n_sim = 50, horizon = 8,
                      seed = 42)
  expect_length(fan$baseline, 9)
})

test_that("with seed, results are reproducible", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb)
  fan1 <- dk_fan_chart(0.90, 0.03, 0.02, -0.02, shocks = shocks,
                       n_sim = 100, horizon = 5, seed = 123)
  fan2 <- dk_fan_chart(0.90, 0.03, 0.02, -0.02, shocks = shocks,
                       n_sim = 100, horizon = 5, seed = 123)
  expect_equal(fan1$simulations, fan2$simulations)
})

test_that("with no shocks provided, all paths equal baseline (zero variance)", {
  fan <- dk_fan_chart(0.90, 0.03, 0.02, -0.02, shocks = NULL,
                      shock_vcov = NULL, n_sim = 50, horizon = 5, seed = 42)
  for (i in seq_len(50)) {
    expect_equal(fan$simulations[i, ], fan$baseline, tolerance = 1e-10)
  }
})

test_that("with no shocks at all, all paths equal baseline", {
  fan <- dk_fan_chart(0.90, 0.03, 0.02, -0.02,
                      n_sim = 50, horizon = 5, seed = 42)
  for (i in seq_len(50)) {
    expect_equal(fan$simulations[i, ], fan$baseline, tolerance = 1e-10)
  }
})

test_that("prob_above values are between 0 and 1", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb)
  fan <- dk_fan_chart(0.90, 0.03, 0.02, -0.02, shocks = shocks,
                      n_sim = 200, horizon = 5, seed = 42)
  for (nm in names(fan$prob_above)) {
    expect_true(fan$prob_above[[nm]] >= 0)
    expect_true(fan$prob_above[[nm]] <= 1)
  }
})

test_that("all simulations start at initial debt", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb)
  fan <- dk_fan_chart(0.75, 0.03, 0.02, -0.02, shocks = shocks,
                      n_sim = 100, horizon = 5, seed = 42)
  expect_true(all(fan$simulations[, 1] == 0.75))
})

test_that("baseline starts at initial debt", {
  fan <- dk_fan_chart(0.60, 0.03, 0.02, -0.02, n_sim = 10, horizon = 5,
                      seed = 42)
  expect_equal(fan$baseline[1], 0.60)
})

test_that("print runs without error", {
  fan <- dk_fan_chart(0.90, 0.03, 0.02, -0.02, n_sim = 50, horizon = 5,
                      seed = 42)
  expect_no_error(print(fan))
})

test_that("plot runs without error", {
  set.seed(1)
  n <- 30
  g <- rnorm(n, 0.02, 0.015)
  r <- rnorm(n, 0.03, 0.01)
  pb <- rnorm(n, -0.02, 0.01)
  shocks <- dk_estimate_shocks(g, r, pb)
  fan <- dk_fan_chart(0.90, 0.03, 0.02, -0.02, shocks = shocks,
                      n_sim = 100, horizon = 5, seed = 42)
  expect_no_error(plot(fan))
})
