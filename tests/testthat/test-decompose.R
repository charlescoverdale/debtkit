test_that("dk_decompose returns correct class", {
  d <- make_sample()
  dec <- dk_decompose(d$debt, d$interest_rate, d$gdp_growth,
                      d$primary_balance, d$years)
  expect_s3_class(dec, "dk_decomposition")
})

test_that("correct number of periods (n-1)", {
  d <- make_sample()
  dec <- dk_decompose(d$debt, d$interest_rate, d$gdp_growth,
                      d$primary_balance, d$years)
  expect_equal(nrow(dec$data), length(d$debt) - 1)
})

test_that("interest + growth + pb + sfa = actual debt change", {
  d <- make_sample()
  dec <- dk_decompose(d$debt, d$interest_rate, d$gdp_growth,
                      d$primary_balance, d$years)
  reconstructed <- dec$data$interest_effect + dec$data$growth_effect +
    dec$data$primary_balance_effect + dec$data$sfa
  expect_equal(reconstructed, dec$data$change, tolerance = 1e-10)
})

test_that("snowball_effect equals interest + growth", {
  d <- make_sample()
  dec <- dk_decompose(d$debt, d$interest_rate, d$gdp_growth,
                      d$primary_balance, d$years)
  expect_equal(dec$data$snowball_effect,
               dec$data$interest_effect + dec$data$growth_effect,
               tolerance = 1e-10)
})

test_that("flat curve (r=g, pb=0) gives zero changes from snowball/pb", {
  n <- 10
  debt <- rep(0.50, n)
  r <- rep(0.03, n)
  g <- rep(0.03, n)
  pb <- rep(0, n)
  dec <- dk_decompose(debt, r, g, pb)
  expect_equal(dec$data$interest_effect + dec$data$growth_effect,
               rep(0, n - 1), tolerance = 1e-10)
  expect_equal(dec$data$primary_balance_effect,
               rep(0, n - 1), tolerance = 1e-10)
})

test_that("years labels default to sequential integers", {
  debt <- c(0.50, 0.52, 0.54)
  dec <- dk_decompose(debt, c(0.03, 0.03, 0.03), c(0.02, 0.02, 0.02),
                      c(-0.01, -0.01, -0.01))
  expect_equal(dec$data$year, c(2, 3))
})

test_that("years labels are passed through", {
  debt <- c(0.50, 0.52, 0.54)
  dec <- dk_decompose(debt, c(0.03, 0.03, 0.03), c(0.02, 0.02, 0.02),
                      c(-0.01, -0.01, -0.01), years = c(2020, 2021, 2022))
  expect_equal(dec$data$year, c(2021L, 2022L))
})

test_that("rejects mismatched lengths", {
  expect_error(
    dk_decompose(c(0.5, 0.6), c(0.03, 0.03, 0.03), c(0.02, 0.02),
                 c(0.01, 0.01)),
    "interest_rate"
  )
})

test_that("rejects debt of length 1", {
  expect_error(
    dk_decompose(0.5, 0.03, 0.02, 0.01),
    "debt"
  )
})

test_that("rejects non-numeric inputs", {
  expect_error(
    dk_decompose("a", 0.03, 0.02, 0.01),
    "debt"
  )
})

test_that("rejects gdp_growth <= -1", {
  expect_error(
    dk_decompose(c(0.5, 0.6), c(0.03, 0.03), c(-1, 0.02), c(0.01, 0.01)),
    "gdp_growth"
  )
})

test_that("data column contains actual debt values", {
  d <- make_sample()
  dec <- dk_decompose(d$debt, d$interest_rate, d$gdp_growth,
                      d$primary_balance, d$years)
  expect_equal(dec$data$debt, d$debt[-1])
})

test_that("print runs without error", {
  d <- make_sample()
  dec <- dk_decompose(d$debt, d$interest_rate, d$gdp_growth,
                      d$primary_balance, d$years)
  expect_no_error(print(dec))
})

test_that("summary runs without error", {
  d <- make_sample()
  dec <- dk_decompose(d$debt, d$interest_rate, d$gdp_growth,
                      d$primary_balance, d$years)
  expect_no_error(summary(dec))
})

test_that("plot runs without error", {
  d <- make_sample()
  dec <- dk_decompose(d$debt, d$interest_rate, d$gdp_growth,
                      d$primary_balance, d$years)
  expect_no_error(plot(dec))
})
