# debtkit 0.2.0

* HAC (Newey-West) standard errors for `dk_bohn_test()` via `robust_se = TRUE`.
  Uses a Bartlett kernel with automatic bandwidth selection to correct for
  serial correlation in fiscal data.
* Non-linear Bohn test (`method = "quadratic"`) for fiscal fatigue detection
  following Ghosh et al. (2013). Includes a squared debt term, with the
  estimated turning point reported when significant.
* Data-driven stress test calibration from historical data via the `calibrate`
  parameter in `dk_stress_test()`. When provided, shock sizes are set to one
  standard deviation of each historical series instead of fixed defaults.
* Bootstrap residual resampling in `dk_fan_chart()` when using
  `dk_estimate_shocks(method = "bootstrap")`. Residual rows are resampled
  with replacement instead of drawing from a multivariate normal.
* Added IMF SRDSF (2022) references to stress test documentation.
* Removed unused dead code in sustainability gap calculation.

# debtkit 0.1.0

* Initial release.
* Deterministic debt projections via `dk_project()` using the standard debt
  dynamics equation.
* Historical decomposition of debt changes into interest, growth, primary
  balance, and stock-flow adjustment effects via `dk_decompose()`.
* Interest rate-growth differential and debt-stabilising primary balance via
  `dk_rg()`.
* Bohn (1998) fiscal reaction function estimation with OLS and rolling-window
  methods via `dk_bohn_test()`.
* Stochastic debt fan charts via Monte Carlo simulation using `dk_fan_chart()`
  and `dk_estimate_shocks()`.
* Six standardised IMF stress tests via `dk_stress_test()`.
* IMF-style heat map risk assessment via `dk_heat_map()`.
* Gross financing needs projection via `dk_gfn()`.
* European Commission S1/S2 sustainability gap indicators via
  `dk_sustainability_gap()`.
* Scenario comparison via `dk_compare()`.
* Built-in sample data via `dk_sample_data()`.
