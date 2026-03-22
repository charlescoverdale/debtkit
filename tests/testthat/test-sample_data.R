test_that("dk_sample_data returns list with correct names", {
  d <- dk_sample_data()
  expected_names <- c("years", "debt", "interest_rate", "gdp_growth",
                      "primary_balance")
  expect_equal(names(d), expected_names)
})

test_that("sample vectors have correct lengths", {
  d <- dk_sample_data("sample")
  n <- length(d$years)
  expect_equal(n, 20)
  expect_length(d$debt, n)
  expect_length(d$interest_rate, n)
  expect_length(d$gdp_growth, n)
  expect_length(d$primary_balance, n)
})

test_that("high_debt option works", {
  d <- dk_sample_data("high_debt")
  expect_true(is.list(d))
  expect_equal(names(d), c("years", "debt", "interest_rate", "gdp_growth",
                           "primary_balance"))
  expect_equal(length(d$years), 10)
})

test_that("high_debt has higher debt levels than sample", {
  d_sample <- dk_sample_data("sample")
  d_high <- dk_sample_data("high_debt")
  expect_true(mean(d_high$debt) > mean(d_sample$debt))
})

test_that("all values are numeric", {
  d <- dk_sample_data()
  expect_true(is.numeric(d$years))
  expect_true(is.numeric(d$debt))
  expect_true(is.numeric(d$interest_rate))
  expect_true(is.numeric(d$gdp_growth))
  expect_true(is.numeric(d$primary_balance))
})
