# Input validation helpers

validate_numeric_vector <- function(x, name, min_length = 1) {
  if (!is.numeric(x)) {
    cli_abort("{.arg {name}} must be numeric.")
  }
  if (any(is.na(x))) {
    cli_abort("{.arg {name}} must not contain NA values.")
  }
  if (length(x) < min_length) {
    cli_abort("{.arg {name}} must have at least {min_length} element{?s}.")
  }
}

validate_ratio <- function(x, name) {
  validate_numeric_vector(x, name)
}

validate_positive_scalar <- function(x, name) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x <= 0) {
    cli_abort("{.arg {name}} must be a single positive number.")
  }
}

validate_scalar <- function(x, name) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x)) {
    cli_abort("{.arg {name}} must be a single number.")
  }
}

validate_positive_integer <- function(x, name) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x < 1 ||
      x != as.integer(x)) {
    cli_abort("{.arg {name}} must be a single positive integer.")
  }
}

# Recycle a scalar or vector to match a target length
recycle_input <- function(x, n, name) {
  if (length(x) == 1) {
    return(rep(x, n))
  }
  if (length(x) != n) {
    cli_abort("{.arg {name}} must be length 1 or {n}, not {length(x)}.")
  }
  x
}

# Format a ratio as percentage string
fmt_pct <- function(x, digits = 1) {
  paste0(round(x * 100, digits), "%")
}

# Format a ratio as percentage points string
fmt_pp <- function(x, digits = 1) {
 paste0(round(x * 100, digits), " pp")
}
