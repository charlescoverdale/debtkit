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
