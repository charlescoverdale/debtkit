# Figure generator for the debtkit R Journal paper.
# Five PDF figures + one LaTeX table, using real FRED + World Bank data.
# Run: RSTUDIO_PANDOC=/Applications/quarto/bin/tools Rscript paper/make_figures.R

suppressPackageStartupMessages({
  devtools::load_all(".", quiet = TRUE)
  library(ggplot2)
  library(showtext)
  library(scales)
})

font_add("HelveticaNeue",
         regular = "/System/Library/Fonts/Helvetica.ttc",
         bold = "/System/Library/Fonts/Helvetica.ttc",
         italic = "/System/Library/Fonts/Helvetica.ttc")
showtext_auto()
showtext_opts(dpi = 300)

fig_dir <- "paper/figures"
tab_dir <- "paper/tables"
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)
if (!dir.exists(tab_dir)) dir.create(tab_dir, recursive = TRUE)

ok_blue   <- "#0072B2"
ok_orange <- "#E69F00"
ok_green  <- "#009E73"
ok_red    <- "#D55E00"
ok_purple <- "#CC79A7"
ok_sky    <- "#56B4E9"
ok_grey   <- "#999999"
ok_yellow <- "#F0E442"
fam <- "HelveticaNeue"

theme_wp <- function(base_size = 10) {
  theme_bw(base_size = base_size, base_family = fam) +
    theme(
      plot.title = element_blank(), plot.subtitle = element_blank(),
      plot.caption = element_blank(), panel.border = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(linewidth = 0.25, colour = "grey85"),
      axis.line = element_line(linewidth = 0.35, colour = "grey25"),
      axis.ticks = element_line(linewidth = 0.35, colour = "grey25"),
      axis.ticks.length = unit(2.5, "pt"),
      axis.text = element_text(size = base_size, colour = "grey20"),
      axis.title = element_text(size = base_size, colour = "grey20"),
      legend.position = "bottom", legend.title = element_blank(),
      legend.text = element_text(size = base_size - 1, family = fam),
      legend.key.height = unit(10, "pt"),
      legend.key.width = unit(22, "pt"),
      legend.spacing.x = unit(10, "pt"),
      legend.margin = margin(4, 0, 0, 0),
      plot.margin = margin(6, 10, 6, 6)
    )
}

tex_esc <- function(x) gsub("_", "\\\\_", as.character(x))

# -----------------------------------------------------------------------------
# Build a real-data panel for the United States from FRED, aggregated to
# annual frequency: debt / interest rate / primary balance. Years 2004-2023.
# -----------------------------------------------------------------------------
read_fred <- function(id) {
  df <- read.csv(file.path("paper/data", paste0(id, ".csv")))
  df$date <- as.Date(df$observation_date)
  data.frame(date = df$date,
             value = suppressWarnings(as.numeric(df[[id]])))
}

debt_raw <- read_fred("GFDEGDQ188S")   # Federal debt held by public / GDP
pbal_raw <- read_fred("FYFSGDA188S")   # Federal surplus+/deficit- / GDP, annual

# Annualise debt to year-end value for calendar years.
debt_raw$year <- as.integer(format(debt_raw$date, "%Y"))
debt_raw$q <- as.integer(format(debt_raw$date, "%m"))
# Take the Q4 value each year.
debt_annual <- aggregate(value ~ year, data = debt_raw[debt_raw$q == 10, ],
                         FUN = function(x) tail(x, 1))
colnames(debt_annual) <- c("year", "debt_pct")
debt_annual$debt <- debt_annual$debt_pct / 100

pbal_raw$year <- as.integer(format(pbal_raw$date, "%Y"))
pbal_annual <- pbal_raw[, c("year", "value")]
colnames(pbal_annual) <- c("year", "overall_balance_pct")
pbal_annual$primary_balance <- pbal_annual$overall_balance_pct / 100 +
  0.025   # crude adjustment: add ~2.5% interest outlay to recover PB proxy

# Effective interest rate: use the US 10-year Treasury yield as proxy.
# (Actual effective interest on federal debt runs closer to the average
# coupon + inflation compensation; 10Y is a reasonable proxy for illustration.)
treas10_raw <- read_fred("IRLTLT01GBM156N")
treas10_raw$year <- as.integer(format(treas10_raw$date, "%Y"))
treas10_annual <- aggregate(value ~ year, data = treas10_raw, FUN = mean)
colnames(treas10_annual) <- c("year", "interest_rate_pct")
treas10_annual$interest_rate <- treas10_annual$interest_rate_pct / 100

# GDP growth from BEA.
gdp_raw <- read_fred("A091RC1Q027SBEA")
gdp_raw$year <- as.integer(format(gdp_raw$date, "%Y"))
# Annual GDP: Q4 yoy growth
gdp_ann <- aggregate(value ~ year, data = gdp_raw, FUN = mean)
gdp_ann$gdp_growth <- c(NA, diff(log(gdp_ann$value)))
gdp_ann <- gdp_ann[, c("year", "gdp_growth")]

# Merge.
us <- Reduce(function(x, y) merge(x, y, by = "year"),
             list(debt_annual, pbal_annual, treas10_annual, gdp_ann))
us <- us[us$year >= 2004 & us$year <= 2023, ]
us <- us[, c("year", "debt", "interest_rate", "gdp_growth",
             "primary_balance")]
us <- us[complete.cases(us), ]
cat("US panel:", nrow(us), "rows\n"); print(head(us, 3))

# -----------------------------------------------------------------------------
# Figure 1: US debt-to-GDP 2004-2023 with decomposition into drivers.
# -----------------------------------------------------------------------------
decomp <- dk_decompose(us$debt, us$interest_rate, us$gdp_growth,
                        us$primary_balance, years = us$year)

df1 <- decomp$data
df1_long <- rbind(
  data.frame(year = df1$year, value = 100 * df1$interest_effect,
             component = "Interest"),
  data.frame(year = df1$year, value = 100 * df1$growth_effect,
             component = "Growth"),
  data.frame(year = df1$year, value = -100 * df1$primary_balance_effect,
             component = "Primary deficit"),
  data.frame(year = df1$year, value = 100 * df1$sfa,
             component = "Stock-flow adj.")
)
df1_long$component <- factor(df1_long$component,
  levels = c("Interest", "Growth", "Primary deficit", "Stock-flow adj."))

df1_total <- data.frame(year = df1$year,
                        value = 100 * df1$change)

p1 <- ggplot(df1_long, aes(x = year, y = value, fill = component)) +
  geom_col(width = 0.75) +
  geom_point(data = df1_total,
             aes(x = year, y = value), inherit.aes = FALSE,
             colour = "grey15", size = 1.6) +
  geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey60") +
  scale_fill_manual(values = c(
    Interest = ok_red, Growth = ok_green,
    `Primary deficit` = ok_orange, `Stock-flow adj.` = ok_grey)) +
  scale_x_continuous(breaks = seq(2004, 2022, 4)) +
  scale_y_continuous(labels = function(x) paste0(x, " pp")) +
  labs(x = NULL,
       y = "Contribution to annual change in debt/GDP") +
  guides(fill = guide_legend(nrow = 1)) +
  theme_wp(base_size = 10)

ggsave(file.path(fig_dir, "fig1_decompose.pdf"),
       p1, width = 5.5, height = 3.2, device = cairo_pdf)

# -----------------------------------------------------------------------------
# Figure 2: cross-country debt/GDP trajectories, 1990-2023.
# Data: FRED series (US = GFDEGDQ188S, UK = GGGDTAGBA188N, Japan = DEBTTLJPA188A).
# -----------------------------------------------------------------------------
cc <- read.csv("paper/data/fred_debt_three.csv")
cc$country <- factor(cc$country,
                     levels = c("Japan", "United States", "United Kingdom"))

p2 <- ggplot(cc, aes(x = year, y = debt_pct,
                      colour = country, linetype = country)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.3, alpha = 0.7) +
  scale_colour_manual(values = c(
    Japan = ok_orange,
    `United States` = ok_blue,
    `United Kingdom` = ok_purple)) +
  scale_linetype_manual(values = c(
    Japan = "longdash",
    `United States` = "solid",
    `United Kingdom` = "dotdash")) +
  scale_x_continuous(breaks = seq(1990, 2020, 5)) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(x = NULL, y = "Gross government debt (% of GDP)") +
  guides(colour = guide_legend(nrow = 1,
                               override.aes = list(linewidth = 0.8)),
         linetype = guide_legend(nrow = 1)) +
  theme_wp(base_size = 10)

ggsave(file.path(fig_dir, "fig2_cross_country.pdf"),
       p2, width = 5.5, height = 3.4, device = cairo_pdf)

# -----------------------------------------------------------------------------
# Figure 3: stochastic fan chart projection for US debt, 10-year horizon.
# -----------------------------------------------------------------------------
us_shocks <- dk_estimate_shocks(us$gdp_growth, us$interest_rate,
                                 us$primary_balance, method = "var",
                                 years = us$year)
# Use latest observed state as starting point.
last <- tail(us, 1)
fan <- dk_fan_chart(debt = last$debt,
                    interest_rate = last$interest_rate,
                    gdp_growth = last$gdp_growth,
                    primary_balance = last$primary_balance,
                    shocks = us_shocks,
                    n_sim = 2000, horizon = 10, seed = 42)

q <- fan$quantiles
# Rows of q correspond to confidence probabilities; columns to time 0..horizon.
years_fan <- seq(last$year, last$year + fan$horizon)
df3 <- data.frame(
  year = years_fan,
  p10 = q["q10", ], p25 = q["q25", ], p50 = q["q50", ],
  p75 = q["q75", ], p90 = q["q90", ],
  baseline = fan$baseline
)

p3 <- ggplot(df3, aes(x = year)) +
  geom_ribbon(aes(ymin = 100 * p10, ymax = 100 * p90,
                  fill = "80% band"), alpha = 0.22) +
  geom_ribbon(aes(ymin = 100 * p25, ymax = 100 * p75,
                  fill = "50% band"), alpha = 0.42) +
  geom_line(aes(y = 100 * p50, colour = "Median",
                linetype = "Median"), linewidth = 0.8) +
  geom_line(aes(y = 100 * baseline, colour = "Baseline",
                linetype = "Baseline"), linewidth = 0.6) +
  scale_fill_manual(name = NULL,
                    values = c("80% band" = ok_blue,
                               "50% band" = ok_blue)) +
  scale_colour_manual(name = NULL,
                      values = c("Median" = ok_blue,
                                 "Baseline" = ok_red)) +
  scale_linetype_manual(name = NULL,
                        values = c("Median" = "solid",
                                   "Baseline" = "longdash")) +
  scale_x_continuous(breaks = seq(2024, 2034, 2)) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(x = NULL, y = "US federal debt held by public (% of GDP)") +
  guides(fill = guide_legend(order = 1, nrow = 1,
                             override.aes = list(alpha = c(0.42, 0.22))),
         colour = guide_legend(order = 2, nrow = 1),
         linetype = guide_legend(order = 2, nrow = 1)) +
  theme_wp(base_size = 10)

ggsave(file.path(fig_dir, "fig3_fan.pdf"),
       p3, width = 5.5, height = 3.2, device = cairo_pdf)

cat(sprintf("fig3: fan P10/P50/P90 at t+10 = %.1f%% / %.1f%% / %.1f%%\n",
            100 * q["q10", ncol(q)], 100 * q["q50", ncol(q)],
            100 * q["q90", ncol(q)]))

# -----------------------------------------------------------------------------
# Figure 4: IMF stress test suite applied to the US baseline.
# -----------------------------------------------------------------------------
stress <- dk_stress_test(
  debt = last$debt,
  interest_rate = last$interest_rate,
  gdp_growth = last$gdp_growth,
  primary_balance = last$primary_balance,
  horizon = 5
)

df4_rows <- list()
for (nm in names(stress$scenarios)) {
  path <- stress$scenarios[[nm]]
  df4_rows[[nm]] <- data.frame(
    year = last$year + seq_along(path) - 1,
    debt = 100 * path,
    scenario = nm
  )
}
df4 <- do.call(rbind, df4_rows)
scen_levels <- c("baseline", "growth", "interest",
                 "primary_balance", "combined", "exchange_rate",
                 "contingent_liability")
df4$scenario <- factor(df4$scenario,
                        levels = scen_levels[scen_levels %in% unique(df4$scenario)])
scen_labels <- c(
  baseline = "Baseline",
  growth = "Growth shock (-1pp)",
  interest = "Interest shock (+2pp)",
  primary_balance = "PB shock (-1pp)",
  combined = "Combined",
  exchange_rate = "FX shock",
  contingent_liability = "Contingent liability")

pal <- c(
  baseline = "grey30",
  growth = ok_blue,
  interest = ok_red,
  primary_balance = ok_orange,
  combined = ok_purple,
  exchange_rate = ok_sky,
  contingent_liability = ok_green)

p4 <- ggplot(df4, aes(x = year, y = debt,
                       colour = scenario, linetype = scenario)) +
  geom_line(linewidth = 0.75) +
  scale_colour_manual(values = pal,
                       labels = scen_labels) +
  scale_linetype_manual(values = setNames(
    rep(c("solid", "longdash", "dotted"),
        length.out = length(levels(df4$scenario))),
    levels(df4$scenario)),
    labels = scen_labels) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(x = NULL, y = "US debt/GDP under IMF stress tests") +
  guides(colour = guide_legend(nrow = 2),
         linetype = guide_legend(nrow = 2)) +
  theme_wp(base_size = 10)

ggsave(file.path(fig_dir, "fig4_stress.pdf"),
       p4, width = 5.5, height = 3.2, device = cairo_pdf)

# -----------------------------------------------------------------------------
# Figure 5: Bohn (1998) fiscal reaction function on US data.
# -----------------------------------------------------------------------------
bohn <- dk_bohn_test(us$primary_balance, us$debt,
                      method = "ols", robust_se = TRUE)

# Bohn scatter.
df5 <- data.frame(
  debt = 100 * us$debt,
  pb   = 100 * us$primary_balance,
  year = us$year
)

beta <- bohn$coefficients[["debt_lag"]]
intercept <- bohn$coefficients[["(Intercept)"]]

p5 <- ggplot(df5, aes(x = debt, y = pb)) +
  geom_point(aes(fill = year),
             shape = 21, colour = "white", size = 2.6,
             stroke = 0.3, alpha = 0.95) +
  geom_abline(slope = beta, intercept = 100 * intercept,
              colour = ok_red, linewidth = 0.6) +
  geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey60",
             linetype = "dashed") +
  scale_fill_gradient(low = ok_sky, high = ok_red,
                      breaks = c(2005, 2015, 2023),
                      name = "Year") +
  scale_x_continuous(labels = function(x) paste0(x, "%")) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(x = "Lagged debt (% GDP)",
       y = "Primary balance (% GDP)") +
  guides(fill = guide_colourbar(barwidth = 8, barheight = 0.5,
                                 title.position = "left",
                                 title.vjust = 0.9)) +
  theme_wp(base_size = 10) +
  theme(legend.direction = "horizontal",
        legend.title = element_text(size = 9, family = fam,
                                     colour = "grey20"))

ggsave(file.path(fig_dir, "fig5_bohn.pdf"),
       p5, width = 5.5, height = 3.2, device = cairo_pdf)

cat(sprintf("fig5: Bohn beta = %.3f (HAC SE = %.3f, p = %.3f)\n",
            beta, bohn$std_errors[["debt_lag"]],
            bohn$p_values[["debt_lag"]]))

# -----------------------------------------------------------------------------
# Table: cross-country summary, latest year.
# -----------------------------------------------------------------------------
wb_latest <- do.call(rbind, lapply(split(cc, cc$country), function(g) {
  g <- g[order(g$year), ]
  data.frame(
    country = g$country[1],
    first_year = min(g$year),
    first_debt = g$debt_pct[1],
    last_year = max(g$year),
    last_debt = g$debt_pct[nrow(g)],
    change = g$debt_pct[nrow(g)] - g$debt_pct[1],
    peak_year = g$year[which.max(g$debt_pct)],
    peak_debt = max(g$debt_pct)
  )
}))
wb_latest <- wb_latest[order(wb_latest$last_debt), ]

tab_lines <- c(
  "\\begin{tabular}{lrrrr}",
  "\\toprule",
  "Country & Debt/GDP (first) & Debt/GDP (latest) & Peak (year) & Change \\\\",
  "\\midrule"
)
for (i in seq_len(nrow(wb_latest))) {
  r <- wb_latest[i, ]
  tab_lines <- c(tab_lines,
    sprintf("%s & %.1f\\%% (%d) & %.1f\\%% (%d) & %.1f\\%% (%d) & %+.1f pp \\\\",
            tex_esc(as.character(r$country)),
            r$first_debt, r$first_year,
            r$last_debt, r$last_year,
            r$peak_debt, r$peak_year,
            r$change))
}
tab_lines <- c(tab_lines, "\\bottomrule", "\\end{tabular}")
writeLines(tab_lines, file.path(tab_dir, "debt_panel.tex"))

cat("\n--- done ---\n")
