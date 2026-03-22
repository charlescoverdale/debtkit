#' Compare Debt Projections
#'
#' Produces a side-by-side comparison of multiple debt-to-GDP projections,
#' aligning them by year and computing terminal values.
#'
#' @param ... Named `dk_projection` objects to compare. Names are used as
#'   scenario labels.
#' @param metric Character. The metric to compare. Currently only `"debt"`
#'   is supported. Default `"debt"`.
#'
#' @return An S3 object of class `dk_comparison` containing:
#' \describe{
#'   \item{paths}{A `data.frame` with a `year` column and one column per
#'     scenario, giving the debt-to-GDP path.}
#'   \item{terminal}{Named numeric vector of terminal debt-to-GDP ratios.}
#' }
#'
#' @export
#' @examples
#' d <- dk_sample_data()
#' base <- dk_project(tail(d$debt, 1), 0.03, 0.04, 0.01, horizon = 5)
#' austerity <- dk_project(tail(d$debt, 1), 0.03, 0.04, 0.03, horizon = 5)
#' stimulus <- dk_project(tail(d$debt, 1), 0.03, 0.05, -0.01, horizon = 5)
#'
#' comp <- dk_compare(
#'   Baseline = base,
#'   Austerity = austerity,
#'   Stimulus = stimulus
#' )
#' comp
#' plot(comp)
dk_compare <- function(..., metric = "debt") {

  dots <- list(...)

  # -- Validate inputs --------------------------------------------------------
  if (length(dots) == 0) {
    cli_abort("At least one {.cls dk_projection} object must be supplied.")
  }

  scenario_names <- names(dots)
  if (is.null(scenario_names) || any(scenario_names == "")) {
    cli_abort("All arguments must be named (scenario labels).")
  }

  for (nm in scenario_names) {
    if (!inherits(dots[[nm]], "dk_projection")) {
      cli_abort("Argument {.val {nm}} must be a {.cls dk_projection} object.")
    }
  }

  metric <- match.arg(metric, choices = "debt")

  # -- Extract debt paths and align by year -----------------------------------
  # Find the longest horizon to set the year column
  horizons <- vapply(dots, function(x) as.integer(x$horizon), integer(1))
  max_horizon <- max(horizons)

  # Build a data.frame with year and one column per scenario
  paths <- data.frame(year = seq(0, max_horizon))

  terminal <- numeric(length(dots))
  names(terminal) <- scenario_names

  for (i in seq_along(dots)) {
    nm <- scenario_names[i]
    proj <- dots[[i]]
    debt_path <- proj$debt_path

    # Pad shorter projections with NA
    if (length(debt_path) < max_horizon + 1) {
      debt_path <- c(debt_path,
                     rep(NA_real_, max_horizon + 1 - length(debt_path)))
    }

    paths[[nm]] <- debt_path
    terminal[nm] <- proj$debt_path[proj$horizon + 1]
  }

  # Use actual years if projections have dates
  first_date <- dots[[1]]$inputs$date
  if (!is.null(first_date)) {
    start_year <- as.integer(format(first_date, "%Y"))
    paths$year <- start_year + paths$year
  }

  structure(
    list(
      paths    = paths,
      terminal = terminal
    ),
    class = "dk_comparison"
  )
}


# -- print method -------------------------------------------------------------

#' @export
print.dk_comparison <- function(x, ...) {
  n_scenarios <- ncol(x$paths) - 1
  scenario_names <- names(x$terminal)

  cli_h1("Debt Projection Comparison")
  cli_bullets(c(
    "*" = "{n_scenarios} scenario{?s}: {.val {scenario_names}}"
  ))

  cat("\nTerminal debt/GDP:\n")
  for (nm in scenario_names) {
    cat(sprintf("  %-20s %s\n", nm, fmt_pct(x$terminal[nm])))
  }

  invisible(x)
}


# -- plot method --------------------------------------------------------------

#' @export
plot.dk_comparison <- function(x, ...) {
  paths <- x$paths
  years <- paths$year
  scenario_names <- names(x$terminal)
  n <- length(scenario_names)

  # Collect all debt values for axis limits
  all_vals <- unlist(paths[, -1, drop = FALSE]) * 100
  all_vals <- all_vals[!is.na(all_vals)]

  y_min <- min(0, min(all_vals) - 5)
  y_max <- max(all_vals) + 10

  # Colours for up to 8 scenarios
  palette <- c("black", "firebrick", "steelblue", "darkorange",
               "purple4", "darkgreen", "goldenrod3", "deeppink3")
  cols <- rep_len(palette, n)

  old_par <- par(mar = c(4, 4.5, 3, 1))
  on.exit(par(old_par))

  plot(
    years, rep(NA, length(years)),
    type = "n",
    xlab = "Year",
    ylab = "Debt / GDP (%)",
    ylim = c(y_min, y_max),
    main = "Debt Projection Comparison",
    ...
  )

  grid(lty = 3, col = "grey80")

  # Reference lines
  abline(h = 60, lty = 2, col = "grey60", lwd = 1)
  abline(h = 90, lty = 2, col = "grey60", lwd = 1)

  for (i in seq_along(scenario_names)) {
    nm <- scenario_names[i]
    vals <- paths[[nm]] * 100
    valid <- !is.na(vals)
    lines(years[valid], vals[valid], col = cols[i], lwd = 2)
    points(years[valid], vals[valid], col = cols[i], pch = 19, cex = 0.6)
  }

  legend(
    "topleft",
    legend = scenario_names,
    col = cols[seq_len(n)],
    lwd = 2,
    pch = 19,
    pt.cex = 0.6,
    bg = "white",
    cex = 0.8
  )

  invisible(x)
}
