test_that("r > g gives positive differential", {
  result <- dk_rg(interest_rate = 0.05, gdp_growth = 0.03)
  expect_true(result$rg_differential > 0)
})

test_that("r < g gives negative differential", {
  result <- dk_rg(interest_rate = 0.02, gdp_growth = 0.04)
  expect_true(result$rg_differential < 0)
})

test_that("known values: r=0.04, g=0.03 gives rg = 0.01", {
  result <- dk_rg(interest_rate = 0.04, gdp_growth = 0.03)
  expect_equal(result$rg_differential, 0.01)
})

test_that("with debt provided, debt-stabilising pb is correct", {
  result <- dk_rg(interest_rate = 0.04, gdp_growth = 0.03, debt = 0.90)
  expected_pb <- ((0.04 - 0.03) / (1 + 0.03)) * 0.90
  expect_equal(result$debt_stabilising_pb, expected_pb, tolerance = 1e-10)
})

test_that("debt-stabilising pb formula: (r-g)/(1+g) * d", {
  r <- 0.05
  g <- 0.02
  d <- 0.80
  result <- dk_rg(interest_rate = r, gdp_growth = g, debt = d)
  expected <- ((r - g) / (1 + g)) * d
  expect_equal(result$debt_stabilising_pb, expected, tolerance = 1e-10)
})

test_that("with inflation, real rg computed", {
  result <- dk_rg(interest_rate = 0.04, gdp_growth = 0.05, inflation = 0.02)
  expect_true("real_rg" %in% names(result))
  # Real r = (1.04/1.02) - 1, real g = (1.05/1.02) - 1
  r_real <- (1.04 / 1.02) - 1
  g_real <- (1.05 / 1.02) - 1
  expect_equal(result$real_rg, r_real - g_real, tolerance = 1e-10)
})

test_that("without inflation, real_rg is absent", {
  result <- dk_rg(interest_rate = 0.04, gdp_growth = 0.03)
  expect_null(result$real_rg)
})

test_that("without debt, debt_stabilising_pb is absent", {
  result <- dk_rg(interest_rate = 0.04, gdp_growth = 0.03)
  expect_null(result$debt_stabilising_pb)
})

test_that("vector inputs work", {
  r <- c(0.04, 0.05, 0.03)
  g <- c(0.03, 0.02, 0.04)
  result <- dk_rg(interest_rate = r, gdp_growth = g)
  expect_length(result$rg_differential, 3)
  expect_equal(result$rg_differential, r - g)
})

test_that("rejects mismatched lengths", {
  expect_error(
    dk_rg(interest_rate = c(0.04, 0.05), gdp_growth = c(0.03, 0.02, 0.04)),
    "gdp_growth"
  )
})
