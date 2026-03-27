## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* macOS (local), R 4.4.x
* Win-builder (R-devel)

## Resubmission

Removed `.GlobalEnv` modification in `dk_fan_chart()` seed handling, as flagged
by Konstanze Lauseker. `set.seed()` is now called directly without
save/restore of `.Random.seed`.
