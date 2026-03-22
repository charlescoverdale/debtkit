test_that("dk_gfn returns data.frame with correct columns", {
  result <- dk_gfn(debt = 0.90, interest_rate = 0.03,
                   maturity_profile = 7, primary_balance = -0.02)
  expect_true(is.data.frame(result))
  expected_cols <- c("year", "primary_deficit", "interest_payments",
                     "maturing_debt", "gfn")
  expect_equal(names(result), expected_cols)
})

test_that("result has correct number of rows", {
  horizon <- 5
  result <- dk_gfn(debt = 0.90, interest_rate = 0.03,
                   maturity_profile = 7, primary_balance = -0.02,
                   horizon = horizon)
  expect_equal(nrow(result), horizon)
})

test_that("GFN = primary deficit + interest + maturing debt", {
  result <- dk_gfn(debt = 0.90, interest_rate = 0.03,
                   maturity_profile = 7, primary_balance = -0.02)
  reconstructed <- result$primary_deficit + result$interest_payments +
    result$maturing_debt
  expect_equal(result$gfn, reconstructed, tolerance = 1e-10)
})

test_that("with scalar maturity_profile, converts correctly", {
  debt <- 0.90
  avg_maturity <- 7
  horizon <- 5
  result <- dk_gfn(debt = debt, interest_rate = 0.03,
                   maturity_profile = avg_maturity,
                   primary_balance = -0.02, horizon = horizon)
  # First year maturing debt should be debt / avg_maturity
  expect_equal(result$maturing_debt[1], debt / avg_maturity,
               tolerance = 1e-10)
})

test_that("zero primary deficit and zero maturing debt gives GFN = interest only", {
  # Very long maturity so maturing debt is near zero
  result <- dk_gfn(debt = 0.90, interest_rate = 0.03,
                   maturity_profile = c(0, 0, 0, 0, 0),
                   primary_balance = 0, horizon = 5)
  # With zero maturing debt and pb=0 (deficit=0), GFN = interest only
  expect_equal(result$gfn[1], 0.03 * 0.90, tolerance = 1e-10)
  expect_equal(result$maturing_debt[1], 0, tolerance = 1e-10)
})

test_that("explicit maturity profile vector works", {
  mat <- c(0.15, 0.12, 0.10, 0.08, 0.05)
  result <- dk_gfn(debt = 0.90, interest_rate = 0.03,
                   maturity_profile = mat, primary_balance = -0.02,
                   horizon = 5)
  expect_equal(result$maturing_debt[1], 0.15, tolerance = 1e-10)
  expect_equal(result$maturing_debt[5], 0.05, tolerance = 1e-10)
})

test_that("primary deficit is negative of primary balance", {
  result <- dk_gfn(debt = 0.90, interest_rate = 0.03,
                   maturity_profile = 7, primary_balance = -0.02,
                   horizon = 5)
  expect_equal(result$primary_deficit[1], 0.02, tolerance = 1e-10)
})

test_that("rejects non-positive scalar maturity_profile", {
  expect_error(
    dk_gfn(debt = 0.90, interest_rate = 0.03, maturity_profile = 0,
           primary_balance = -0.02),
    "maturity_profile"
  )
})
