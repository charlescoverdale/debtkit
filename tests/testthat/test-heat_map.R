test_that("dk_heat_map returns correct class", {
  hm <- dk_heat_map(debt = 0.50, gross_financing_needs = 0.10)
  expect_s3_class(hm, "dk_heatmap")
})

test_that("AE: debt < 0.60 is low risk", {
  hm <- dk_heat_map(debt = 0.50, gross_financing_needs = 0.10,
                    country_type = "ae")
  expect_equal(hm$ratings$debt, "low")
})

test_that("AE: debt between 0.60 and 0.85 is medium risk", {
  hm <- dk_heat_map(debt = 0.70, gross_financing_needs = 0.10,
                    country_type = "ae")
  expect_equal(hm$ratings$debt, "medium")
})

test_that("AE: debt > 0.85 is high risk", {
  hm <- dk_heat_map(debt = 0.90, gross_financing_needs = 0.10,
                    country_type = "ae")
  expect_equal(hm$ratings$debt, "high")
})

test_that("EM: different thresholds apply", {
  # EM high threshold is 0.70, so 0.75 is high for EM but medium for AE
  hm_em <- dk_heat_map(debt = 0.75, gross_financing_needs = 0.08,
                       country_type = "em")
  hm_ae <- dk_heat_map(debt = 0.75, gross_financing_needs = 0.08,
                       country_type = "ae")
  expect_equal(hm_em$ratings$debt, "high")
  expect_equal(hm_ae$ratings$debt, "medium")
})

test_that("overall is high if any indicator is high", {
  hm <- dk_heat_map(debt = 0.90, gross_financing_needs = 0.10,
                    country_type = "ae")
  expect_equal(hm$overall, "high")
})

test_that("overall is medium if none high but some medium", {
  hm <- dk_heat_map(debt = 0.70, gross_financing_needs = 0.10,
                    country_type = "ae")
  expect_equal(hm$overall, "medium")
})

test_that("overall is low if all indicators low", {
  hm <- dk_heat_map(debt = 0.40, gross_financing_needs = 0.08,
                    country_type = "ae")
  expect_equal(hm$overall, "low")
})

test_that("with debt_profile, additional indicators rated", {
  hm <- dk_heat_map(
    debt = 0.50,
    gross_financing_needs = 0.10,
    debt_profile = list(fx_share = 0.30, share_st_debt = 0.05),
    country_type = "ae"
  )
  expect_true("fx_share" %in% names(hm$ratings))
  expect_true("share_st_debt" %in% names(hm$ratings))
})

test_that("print runs without error", {
  hm <- dk_heat_map(debt = 0.90, gross_financing_needs = 0.18,
                    debt_profile = list(fx_share = 0.30),
                    country_type = "ae")
  expect_no_error(print(hm))
})
