test_that("dk_project returns correct class", {
  inp <- make_baseline_inputs()
  proj <- dk_project(inp$debt, inp$interest_rate, inp$gdp_growth,
                     inp$primary_balance)
  expect_s3_class(proj, "dk_projection")
})

test_that("debt_path has length horizon + 1", {
  inp <- make_baseline_inputs()
  proj <- dk_project(inp$debt, inp$interest_rate, inp$gdp_growth,
                     inp$primary_balance, horizon = 10)
  expect_length(proj$debt_path, 11)
})

test_that("debt_path[1] equals initial debt", {
  inp <- make_baseline_inputs()
  proj <- dk_project(inp$debt, inp$interest_rate, inp$gdp_growth,
                     inp$primary_balance)
  expect_equal(proj$debt_path[1], inp$debt)
})

test_that("with r=g and pb=0, debt stays constant", {
  proj <- dk_project(debt = 0.80, interest_rate = 0.03, gdp_growth = 0.03,
                     primary_balance = 0, horizon = 5)
  expect_equal(proj$debt_path, rep(0.80, 6), tolerance = 1e-10)
})

test_that("with r>g and pb=0, debt grows", {
  proj <- dk_project(debt = 0.80, interest_rate = 0.05, gdp_growth = 0.03,
                     primary_balance = 0, horizon = 5)
  expect_true(all(diff(proj$debt_path) > 0))
})

test_that("with primary surplus, debt declines", {
  proj <- dk_project(debt = 0.80, interest_rate = 0.03, gdp_growth = 0.03,
                     primary_balance = 0.05, horizon = 5)
  expect_true(all(diff(proj$debt_path) < 0))
})

test_that("decomposition effects sum to change", {
  inp <- make_baseline_inputs()
  proj <- dk_project(inp$debt, inp$interest_rate, inp$gdp_growth,
                     inp$primary_balance, horizon = 5)
  dec <- proj$decomposition
  reconstructed <- dec$interest_effect + dec$growth_effect +
    dec$primary_balance_effect + dec$sfa_effect
  expect_equal(reconstructed, dec$change, tolerance = 1e-10)
})

test_that("snowball_effect equals interest + growth effects", {
  inp <- make_baseline_inputs()
  proj <- dk_project(inp$debt, inp$interest_rate, inp$gdp_growth,
                     inp$primary_balance, horizon = 5)
  dec <- proj$decomposition
  expect_equal(dec$snowball_effect, dec$interest_effect + dec$growth_effect,
               tolerance = 1e-10)
})

test_that("scalar inputs recycled correctly", {
  proj <- dk_project(debt = 0.60, interest_rate = 0.04, gdp_growth = 0.03,
                     primary_balance = 0.01, horizon = 5)
  expect_length(proj$inputs$interest_rate, 5)
  expect_true(all(proj$inputs$interest_rate == 0.04))
})

test_that("vector inputs work", {
  r <- c(0.03, 0.04, 0.05, 0.04, 0.03)
  g <- c(0.02, 0.03, 0.04, 0.03, 0.02)
  pb <- c(0.01, 0.01, 0.02, 0.01, 0.01)
  proj <- dk_project(debt = 0.60, interest_rate = r, gdp_growth = g,
                     primary_balance = pb, horizon = 5)
  expect_s3_class(proj, "dk_projection")
  expect_length(proj$debt_path, 6)
})

test_that("SFA affects debt path", {
  proj_no_sfa <- dk_project(0.60, 0.04, 0.03, 0.01, sfa = 0, horizon = 5)
  proj_sfa <- dk_project(0.60, 0.04, 0.03, 0.01, sfa = 0.02, horizon = 5)
  expect_true(proj_sfa$debt_path[6] > proj_no_sfa$debt_path[6])
})

test_that("date parameter stores and uses years", {
  proj <- dk_project(0.60, 0.04, 0.03, 0.01, horizon = 5,
                     date = as.Date("2020-01-01"))
  expect_equal(proj$decomposition$year, 2021:2025)
})

test_that("rejects non-numeric debt", {
  expect_error(
    dk_project("a", 0.04, 0.03, 0.01),
    "debt"
  )
})

test_that("rejects negative horizon", {
  expect_error(
    dk_project(0.60, 0.04, 0.03, 0.01, horizon = -1),
    "horizon"
  )
})

test_that("rejects wrong-length vector inputs", {
  expect_error(
    dk_project(0.60, c(0.04, 0.05), 0.03, 0.01, horizon = 5),
    "interest_rate"
  )
})

test_that("rejects gdp_growth <= -1", {
  expect_error(
    dk_project(0.60, 0.04, -1, 0.01, horizon = 5),
    "gdp_growth"
  )
})

test_that("decomposition has correct number of rows", {
  proj <- dk_project(0.60, 0.04, 0.03, 0.01, horizon = 7)
  expect_equal(nrow(proj$decomposition), 7)
})

test_that("print runs without error", {
  proj <- dk_project(0.60, 0.04, 0.03, 0.01)
  expect_no_error(print(proj))
})

test_that("summary runs without error", {
  proj <- dk_project(0.60, 0.04, 0.03, 0.01)
  expect_no_error(summary(proj))
})

test_that("plot runs without error", {
  proj <- dk_project(0.60, 0.04, 0.03, 0.01)
  expect_no_error(plot(proj))
})
