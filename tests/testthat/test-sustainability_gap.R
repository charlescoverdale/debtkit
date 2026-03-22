test_that("dk_sustainability_gap returns correct class", {
  sg <- dk_sustainability_gap(
    debt = 0.90, structural_balance = -0.01,
    gdp_growth = 0.015, interest_rate = 0.025
  )
  expect_s3_class(sg, "dk_sgap")
})

test_that("returns both S1 and S2 by default", {
  sg <- dk_sustainability_gap(
    debt = 0.90, structural_balance = -0.01,
    gdp_growth = 0.015, interest_rate = 0.025
  )
  expect_true(!is.na(sg$S1))
  expect_true(!is.na(sg$S2))
})

test_that("S1 and S2 are numeric scalars", {
  sg <- dk_sustainability_gap(
    debt = 0.90, structural_balance = -0.01,
    gdp_growth = 0.015, interest_rate = 0.025
  )
  expect_true(is.numeric(sg$S1))
  expect_length(sg$S1, 1)
  expect_true(is.numeric(sg$S2))
  expect_length(sg$S2, 1)
})

test_that("when current pb is very large surplus, gaps are negative", {
  sg <- dk_sustainability_gap(
    debt = 0.30, structural_balance = 0.10,
    gdp_growth = 0.03, interest_rate = 0.02
  )
  # With very low debt, high surplus, and r < g, gaps should be negative
  expect_true(sg$S1 < 0)
  expect_true(sg$S2 < 0)
})

test_that("risk classification: gap < 0.02 is low", {
  sg <- dk_sustainability_gap(
    debt = 0.30, structural_balance = 0.05,
    gdp_growth = 0.03, interest_rate = 0.02
  )
  # With low debt and surplus, S1 should be small
  expect_equal(sg$risk_S1, "low")
})

test_that("with ageing_costs > 0, gaps increase", {
  sg_no_ageing <- dk_sustainability_gap(
    debt = 0.90, structural_balance = -0.01,
    gdp_growth = 0.015, interest_rate = 0.025,
    ageing_costs = 0
  )
  sg_ageing <- dk_sustainability_gap(
    debt = 0.90, structural_balance = -0.01,
    gdp_growth = 0.015, interest_rate = 0.025,
    ageing_costs = 0.03
  )
  expect_true(sg_ageing$S1 > sg_no_ageing$S1)
  expect_true(sg_ageing$S2 > sg_no_ageing$S2)
})

test_that("indicator='S1' returns S2 as NA", {
  sg <- dk_sustainability_gap(
    debt = 0.90, structural_balance = -0.01,
    gdp_growth = 0.015, interest_rate = 0.025,
    indicator = "S1"
  )
  expect_true(!is.na(sg$S1))
  expect_true(is.na(sg$S2))
})

test_that("indicator='S2' returns S1 as NA", {
  sg <- dk_sustainability_gap(
    debt = 0.90, structural_balance = -0.01,
    gdp_growth = 0.015, interest_rate = 0.025,
    indicator = "S2"
  )
  expect_true(is.na(sg$S1))
  expect_true(!is.na(sg$S2))
})

test_that("required_pb is stored", {
  sg <- dk_sustainability_gap(
    debt = 0.90, structural_balance = -0.01,
    gdp_growth = 0.015, interest_rate = 0.025
  )
  expect_true(is.numeric(sg$required_pb))
  expect_length(sg$required_pb, 1)
})

test_that("print runs without error", {
  sg <- dk_sustainability_gap(
    debt = 0.90, structural_balance = -0.01,
    gdp_growth = 0.015, interest_rate = 0.025,
    ageing_costs = 0.02
  )
  expect_no_error(print(sg))
})
