test_that("dk_stress_test returns correct class", {
  st <- dk_stress_test(0.90, 0.03, 0.04, 0.01)
  expect_s3_class(st, "dk_stress")
})

test_that("scenarios data.frame has correct columns", {
  st <- dk_stress_test(0.90, 0.03, 0.04, 0.01)
  expected_cols <- c("year", "baseline", "growth", "interest_rate",
                     "exchange_rate", "primary_balance", "combined",
                     "contingent")
  expect_equal(names(st$scenarios), expected_cols)
})

test_that("scenarios has correct number of rows", {
  horizon <- 5
  st <- dk_stress_test(0.90, 0.03, 0.04, 0.01, horizon = horizon)
  expect_equal(nrow(st$scenarios), horizon + 1)
})

test_that("terminal is named vector with 7 elements", {
  st <- dk_stress_test(0.90, 0.03, 0.04, 0.01)
  expect_length(st$terminal, 7)
  expected_names <- c("baseline", "growth", "interest_rate", "exchange_rate",
                      "primary_balance", "combined", "contingent")
  expect_equal(names(st$terminal), expected_names)
})

test_that("baseline scenario matches dk_project", {
  debt <- 0.90
  r <- 0.03
  g <- 0.04
  pb <- 0.01
  horizon <- 5
  st <- dk_stress_test(debt, r, g, pb, horizon = horizon)
  proj <- dk_project(debt, r, g, pb, horizon = horizon)
  expect_equal(st$scenarios$baseline, proj$debt_path, tolerance = 1e-10)
})

test_that("growth shock gives higher terminal debt than baseline", {
  st <- dk_stress_test(0.90, 0.03, 0.04, 0.01)
  expect_true(st$terminal["growth"] > st$terminal["baseline"])
})

test_that("interest shock gives higher terminal debt than baseline", {
  st <- dk_stress_test(0.90, 0.03, 0.04, 0.01)
  expect_true(st$terminal["interest_rate"] > st$terminal["baseline"])
})

test_that("contingent liability shock shows immediate debt increase", {
  st <- dk_stress_test(0.90, 0.03, 0.04, 0.01, contingent_shock = 0.10)
  # At year 1, contingent path should be higher than baseline
  expect_true(st$scenarios$contingent[2] > st$scenarios$baseline[2])
})

test_that("with fx_share=0, exchange rate shock has no effect", {
  st <- dk_stress_test(0.90, 0.03, 0.04, 0.01, fx_share = 0)
  expect_equal(st$scenarios$exchange_rate, st$scenarios$baseline,
               tolerance = 1e-10)
})

test_that("with fx_share>0, exchange rate shock increases debt", {
  st <- dk_stress_test(0.90, 0.03, 0.04, 0.01, fx_share = 0.20,
                       exchange_shock = 0.15)
  expect_true(st$terminal["exchange_rate"] > st$terminal["baseline"])
})

test_that("all scenarios start at same initial debt", {
  st <- dk_stress_test(0.90, 0.03, 0.04, 0.01)
  row1 <- as.numeric(st$scenarios[1, -1])
  expect_true(all(row1 == 0.90))
})

test_that("print runs without error", {
  st <- dk_stress_test(0.90, 0.03, 0.04, 0.01)
  expect_no_error(print(st))
})

test_that("plot runs without error", {
  st <- dk_stress_test(0.90, 0.03, 0.04, 0.01)
  expect_no_error(plot(st))
})
