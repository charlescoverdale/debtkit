test_that("dk_compare returns correct class", {
  base <- dk_project(0.60, 0.03, 0.04, 0.01, horizon = 5)
  alt <- dk_project(0.60, 0.03, 0.04, 0.03, horizon = 5)
  comp <- dk_compare(Baseline = base, Austerity = alt)
  expect_s3_class(comp, "dk_comparison")
})

test_that("paths has correct columns", {
  base <- dk_project(0.60, 0.03, 0.04, 0.01, horizon = 5)
  alt <- dk_project(0.60, 0.03, 0.04, 0.03, horizon = 5)
  comp <- dk_compare(Baseline = base, Austerity = alt)
  expect_true("year" %in% names(comp$paths))
  expect_true("Baseline" %in% names(comp$paths))
  expect_true("Austerity" %in% names(comp$paths))
})

test_that("terminal matches individual projection terminal debt", {
  base <- dk_project(0.60, 0.03, 0.04, 0.01, horizon = 5)
  alt <- dk_project(0.60, 0.03, 0.04, 0.03, horizon = 5)
  comp <- dk_compare(Baseline = base, Austerity = alt)
  expect_equal(unname(comp$terminal["Baseline"]), base$debt_path[6],
               tolerance = 1e-10)
  expect_equal(unname(comp$terminal["Austerity"]), alt$debt_path[6],
               tolerance = 1e-10)
})

test_that("multiple scenarios work", {
  base <- dk_project(0.60, 0.03, 0.04, 0.01, horizon = 5)
  alt1 <- dk_project(0.60, 0.03, 0.04, 0.03, horizon = 5)
  alt2 <- dk_project(0.60, 0.03, 0.05, -0.01, horizon = 5)
  comp <- dk_compare(Baseline = base, Austerity = alt1, Stimulus = alt2)
  expect_length(comp$terminal, 3)
  expect_equal(ncol(comp$paths), 4)
})

test_that("different horizons padded with NA", {
  short <- dk_project(0.60, 0.03, 0.04, 0.01, horizon = 3)
  long <- dk_project(0.60, 0.03, 0.04, 0.01, horizon = 5)
  comp <- dk_compare(Short = short, Long = long)
  # Short path should have NAs at the end
  expect_true(is.na(comp$paths$Short[6]))
  expect_true(!is.na(comp$paths$Long[6]))
})

test_that("rejects unnamed arguments", {
  base <- dk_project(0.60, 0.03, 0.04, 0.01, horizon = 5)
  expect_error(dk_compare(base), "named")
})

test_that("rejects non-projection objects", {
  expect_error(dk_compare(A = "not a projection"), "dk_projection")
})

test_that("print runs without error", {
  base <- dk_project(0.60, 0.03, 0.04, 0.01, horizon = 5)
  alt <- dk_project(0.60, 0.03, 0.04, 0.03, horizon = 5)
  comp <- dk_compare(Baseline = base, Austerity = alt)
  expect_no_error(print(comp))
})

test_that("plot runs without error", {
  base <- dk_project(0.60, 0.03, 0.04, 0.01, horizon = 5)
  alt <- dk_project(0.60, 0.03, 0.04, 0.03, horizon = 5)
  comp <- dk_compare(Baseline = base, Austerity = alt)
  expect_no_error(plot(comp))
})
