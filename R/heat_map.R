#' IMF-Style Risk Heat Map
#'
#' Classifies sovereign debt risk as low, medium, or high based on IMF (2013)
#' thresholds for debt-to-GDP, gross financing needs, and optional debt-profile
#' indicators. Advanced economies and emerging markets use different thresholds.
#'
#' @param debt Numeric scalar. Debt-to-GDP ratio.
#' @param gross_financing_needs Numeric scalar. Gross financing needs as a share
#'   of GDP.
#' @param debt_profile Optional named list of debt-profile indicators (all as
#'   ratios):
#'   \describe{
#'     \item{share_st_debt}{Share of short-term debt in total debt.}
#'     \item{fx_share}{Share of foreign-currency-denominated debt.}
#'     \item{nonresident_share}{Share of debt held by non-residents.}
#'     \item{bank_share}{Share of debt held by domestic banks.}
#'     \item{change_st_debt}{Year-on-year change in the share of short-term
#'       debt (in percentage points of GDP).}
#'   }
#' @param country_type Character. Either `"ae"` (advanced economy, default) or
#'   `"em"` (emerging market).
#'
#' @return An S3 object of class `dk_heatmap` containing:
#' \describe{
#'   \item{ratings}{Named list of risk ratings (`"low"`, `"medium"`, or
#'     `"high"`) for each indicator.}
#'   \item{overall}{Character. Overall risk level: `"high"` if any indicator is
#'     high, `"medium"` if any is medium, otherwise `"low"`.}
#'   \item{values}{Named list of input values.}
#'   \item{thresholds}{The thresholds used for classification.}
#'   \item{country_type}{The country type used.}
#' }
#'
#' @references
#' International Monetary Fund (2013). *Staff Guidance Note for Public Debt
#' Sustainability Analysis in Market-Access Countries*. IMF Policy Paper.
#'
#' @export
#' @examples
#' hm <- dk_heat_map(
#'   debt = 0.90,
#'   gross_financing_needs = 0.18,
#'   debt_profile = list(fx_share = 0.30, share_st_debt = 0.15),
#'   country_type = "ae"
#' )
#' hm
dk_heat_map <- function(debt,
                        gross_financing_needs,
                        debt_profile = NULL,
                        country_type = c("ae", "em")) {

  # -- Validate inputs --------------------------------------------------------
  validate_scalar(debt, "debt")
  validate_scalar(gross_financing_needs, "gross_financing_needs")
  country_type <- match.arg(country_type)

  if (!is.null(debt_profile)) {
    if (!is.list(debt_profile)) {
      cli_abort("{.arg debt_profile} must be a named list or {.val NULL}.")
    }
    valid_names <- c("share_st_debt", "fx_share", "nonresident_share",
                     "bank_share", "change_st_debt")
    unknown <- setdiff(names(debt_profile), valid_names)
    if (length(unknown) > 0) {
      cli_warn("Unknown {.arg debt_profile} element{?s}: {.val {unknown}}.")
    }
    for (nm in names(debt_profile)) {
      validate_scalar(debt_profile[[nm]], paste0("debt_profile$", nm))
    }
  }

  # -- Define thresholds ------------------------------------------------------
  if (country_type == "ae") {
    thresholds <- list(
      debt = c(medium = 0.60, high = 0.85),
      gfn  = c(medium = 0.15, high = 0.20),
      # Debt profile thresholds (IMF 2013 benchmarks for AEs)
      share_st_debt    = c(medium = 0.10, high = 0.15),
      fx_share         = c(medium = 0.15, high = 0.25),
      nonresident_share = c(medium = 0.45, high = 0.65),
      bank_share       = c(medium = 0.15, high = 0.25),
      change_st_debt   = c(medium = 0.01, high = 0.02)
    )
  } else {
    thresholds <- list(
      debt = c(medium = 0.50, high = 0.70),
      gfn  = c(medium = 0.10, high = 0.15),
      share_st_debt    = c(medium = 0.10, high = 0.15),
      fx_share         = c(medium = 0.30, high = 0.45),
      nonresident_share = c(medium = 0.30, high = 0.45),
      bank_share       = c(medium = 0.15, high = 0.25),
      change_st_debt   = c(medium = 0.005, high = 0.01)
    )
  }

  # -- Classification helper --------------------------------------------------
  classify <- function(value, thresh) {
    if (value >= thresh["high"]) return("high")
    if (value >= thresh["medium"]) return("medium")
    "low"
  }

  # -- Rate each indicator ----------------------------------------------------
  ratings <- list()
  values  <- list()

  ratings$debt <- classify(debt, thresholds$debt)
  values$debt  <- debt

  ratings$gross_financing_needs <- classify(gross_financing_needs,
                                            thresholds$gfn)
  values$gross_financing_needs  <- gross_financing_needs

  if (!is.null(debt_profile)) {
    profile_indicators <- c("share_st_debt", "fx_share", "nonresident_share",
                            "bank_share", "change_st_debt")
    for (nm in profile_indicators) {
      if (!is.null(debt_profile[[nm]])) {
        ratings[[nm]] <- classify(debt_profile[[nm]], thresholds[[nm]])
        values[[nm]]  <- debt_profile[[nm]]
      }
    }
  }

  # -- Overall risk -----------------------------------------------------------
  all_ratings <- unlist(ratings)
  if (any(all_ratings == "high")) {
    overall <- "high"
  } else if (any(all_ratings == "medium")) {
    overall <- "medium"
  } else {
    overall <- "low"
  }

  structure(
    list(
      ratings      = ratings,
      overall      = overall,
      values       = values,
      thresholds   = thresholds,
      country_type = country_type
    ),
    class = "dk_heatmap"
  )
}


# -- print method -------------------------------------------------------------

#' @export
print.dk_heatmap <- function(x, ...) {
  type_label <- if (x$country_type == "ae") "Advanced Economy" else
    "Emerging Market"

  cli_h1("IMF Risk Heat Map ({type_label})")

  # Colour-coded risk labels
  colour_rating <- function(rating) {
    switch(rating,
      low    = cli::col_green("LOW"),
      medium = cli::col_yellow("MEDIUM"),
      high   = cli::col_red("HIGH")
    )
  }

  # Pretty indicator names
  pretty_name <- function(nm) {
    switch(nm,
      debt                 = "Debt / GDP",
      gross_financing_needs = "Gross financing needs / GDP",
      share_st_debt        = "Short-term debt share",
      fx_share             = "Foreign currency share",
      nonresident_share    = "Non-resident share",
      bank_share           = "Domestic bank share",
      change_st_debt       = "Change in ST debt share",
      nm
    )
  }

  cat("\n")
  for (nm in names(x$ratings)) {
    label <- pretty_name(nm)
    val   <- fmt_pct(x$values[[nm]])
    rating <- colour_rating(x$ratings[[nm]])
    cat(sprintf("  %-30s %8s    %s\n", label, val, rating))
  }

  cat("\n")
  cli_rule()
  overall_col <- colour_rating(x$overall)
  cat(sprintf("  Overall risk:                             %s\n", overall_col))

  invisible(x)
}
