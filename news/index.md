# Changelog

## debtkit 0.1.3

- [`dk_gfn()`](https://charlescoverdale.github.io/debtkit/reference/dk_gfn.md)
  now returns an S3 object of class `dk_gfn` with dedicated
  [`print()`](https://rdrr.io/r/base/print.html) and
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods,
  consistent with other debtkit functions.

## debtkit 0.1.2

CRAN release: 2026-03-31

- Removed `.GlobalEnv` modification in
  [`dk_fan_chart()`](https://charlescoverdale.github.io/debtkit/reference/dk_fan_chart.md)
  seed handling, per CRAN policy.

## debtkit 0.1.1

- Fixed Bohn (1998) DOI: replaced defunct JSTOR DOI with QJE publisher
  DOI (10.1162/003355398555793).

## debtkit 0.1.0

- Initial release.
- Deterministic debt projections via
  [`dk_project()`](https://charlescoverdale.github.io/debtkit/reference/dk_project.md)
  using the standard debt dynamics equation.
- Historical decomposition of debt changes into interest, growth,
  primary balance, and stock-flow adjustment effects via
  [`dk_decompose()`](https://charlescoverdale.github.io/debtkit/reference/dk_decompose.md).
- Interest rate-growth differential and debt-stabilising primary balance
  via
  [`dk_rg()`](https://charlescoverdale.github.io/debtkit/reference/dk_rg.md).
- Bohn (1998) fiscal reaction function estimation with OLS,
  rolling-window, and quadratic methods via
  [`dk_bohn_test()`](https://charlescoverdale.github.io/debtkit/reference/dk_bohn_test.md).
  HAC (Newey-West) standard errors via `robust_se = TRUE`.
- Stochastic debt fan charts via Monte Carlo simulation using
  [`dk_fan_chart()`](https://charlescoverdale.github.io/debtkit/reference/dk_fan_chart.md)
  and
  [`dk_estimate_shocks()`](https://charlescoverdale.github.io/debtkit/reference/dk_estimate_shocks.md).
  Supports bootstrap residual resampling.
- Six standardised IMF stress tests via
  [`dk_stress_test()`](https://charlescoverdale.github.io/debtkit/reference/dk_stress_test.md),
  with optional data-driven calibration.
- IMF-style heat map risk assessment via
  [`dk_heat_map()`](https://charlescoverdale.github.io/debtkit/reference/dk_heat_map.md).
- Gross financing needs projection via
  [`dk_gfn()`](https://charlescoverdale.github.io/debtkit/reference/dk_gfn.md).
- European Commission S1/S2 sustainability gap indicators via
  [`dk_sustainability_gap()`](https://charlescoverdale.github.io/debtkit/reference/dk_sustainability_gap.md).
- Scenario comparison via
  [`dk_compare()`](https://charlescoverdale.github.io/debtkit/reference/dk_compare.md).
- Built-in sample data via
  [`dk_sample_data()`](https://charlescoverdale.github.io/debtkit/reference/dk_sample_data.md).
