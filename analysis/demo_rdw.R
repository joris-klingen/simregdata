# analysis/demo_rdw.R
#
# RDW visualisation: EV adoption curve, fuel type stacked area,
# weight vs km scatter.
# Run: Rscript analysis/demo_rdw.R

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(haven)
})
devtools::load_all(".")

dir.create("plots", showWarnings = FALSE)

YEARS <- seq(2010, 2025, by = 1)
N     <- 5000L

theme_set(theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey45", size = 9)))


# Load data ----

fuel_list <- list()
wt_list   <- list()

for (yr in YEARS) {
  sim_reset()
  sim_init("rdw", year = yr, n = N, seed = 42L)

  dt_k <- as.data.table(read_sav(
    sprintf("RDWNPACT%dTABV1", yr),
    col_select = c(BRANDSTCODECORVRTG, MASSALEEGCORVRTG, RINKENTEKEN)
  ))

  fc <- dt_k[, .N, by = BRANDSTCODECORVRTG]
  fc[, `:=`(pct = N / sum(N) * 100, year = yr,
            fuel = as.character(as_factor(BRANDSTCODECORVRTG)))]
  fuel_list[[as.character(yr)]] <- fc

  # Only collect weight/km for a few years to keep scatter manageable
  if (yr %in% c(2015, 2020, 2025)) {
    dt_vp <- as.data.table(read_sav(
      sprintf("VERKEERSPRESTATIE%dTABV1", yr),
      col_select = c(RINKENTEKEN, VPJAARKM)
    ))
    dt_merged <- merge(dt_k, dt_vp, by = "RINKENTEKEN")
    dt_merged[, fuel := as.character(as_factor(BRANDSTCODECORVRTG))]
    wt_list[[as.character(yr)]] <- data.table(
      year = yr,
      weight = as.numeric(dt_merged$MASSALEEGCORVRTG),
      km = as.numeric(dt_merged$VPJAARKM),
      fuel = dt_merged$fuel)
  }
}

fuel_ts <- rbindlist(fuel_list)


# EV adoption curve ----
ev_share <- fuel_ts[grepl("Electriciteit|Electric", fuel),
                    .(ev_pct = sum(pct)), by = year]
# Fill in zeros for years with no EV
all_years <- data.table(year = YEARS)
ev_share <- merge(all_years, ev_share, by = "year", all.x = TRUE)
ev_share[is.na(ev_pct), ev_pct := 0]

latest <- ev_share[year == max(year)]

p1 <- ggplot(ev_share, aes(year, ev_pct)) +
  geom_line(linewidth = 1.2, colour = "#2ca02c") +
  geom_point(size = 2, colour = "#2ca02c") +
  geom_area(alpha = 0.15, fill = "#2ca02c") +
  annotate("text", x = latest$year - 0.5, y = latest$ev_pct + 1.5,
           label = sprintf("%.1f%%", latest$ev_pct),
           fontface = "bold", size = 4.5, colour = "#2ca02c") +
  scale_x_continuous(breaks = seq(2010, 2025, 2)) +
  scale_y_continuous(labels = \(x) paste0(x, "%"),
                     limits = c(0, max(ev_share$ev_pct) * 1.3)) +
  labs(title = "Aandeel elektrische voertuigen in het wagenpark",
       subtitle = "CBS 85237NED (StatLine-gekalibreerd), exponential groei sinds 2015",
       x = NULL, y = "Aandeel EV")

print(p1)
ggsave("plots/demo_rdw_p1_ev_adoptie.png", p1, width = 8, height = 4.5, dpi = 150)


# Fuel type stacked area ----

# Simplify fuel categories
fuel_ts[, fuel_cat := fcase(
  grepl("Benzine", fuel), "Benzine",
  grepl("Diesel", fuel), "Diesel",
  grepl("Electriciteit|Electric", fuel), "Elektrisch",
  grepl("Hybride|PHEV|HEV", fuel), "Hybride",
  grepl("LPG", fuel), "LPG",
  default = "Overig"
)]
fuel_agg <- fuel_ts[, .(pct = sum(pct)), by = .(year, fuel_cat)]

cat_order <- c("Benzine", "Diesel", "LPG", "Hybride", "Elektrisch", "Overig")
fuel_agg[, fuel_cat := factor(fuel_cat, levels = rev(cat_order))]

cat_cols <- c(
  "Benzine"     = "#1f77b4",
  "Diesel"      = "#2ca02c",
  "LPG"         = "#ff7f0e",
  "Hybride"     = "#9467bd",
  "Elektrisch"  = "#17becf",
  "Overig"      = "#aec7e8"
)

p2 <- ggplot(fuel_agg, aes(year, pct, fill = fuel_cat)) +
  geom_area(alpha = 0.85, colour = "white", linewidth = 0.3) +
  scale_fill_manual(values = cat_cols, name = NULL,
                    guide = guide_legend(reverse = TRUE)) +
  scale_x_continuous(breaks = seq(2010, 2025, 2)) +
  scale_y_continuous(labels = \(x) paste0(x, "%")) +
  labs(title = "Brandstofmix Nederlands wagenpark",
       subtitle = sprintf("CBS 85237NED, %d\u2013%d -- diesel krimpt, elektrisch groeit",
                          min(YEARS), max(YEARS)),
       x = NULL, y = "Aandeel") +
  theme(legend.position = "bottom")

print(p2)
ggsave("plots/demo_rdw_p2_brandstofmix.png", p2, width = 9, height = 5, dpi = 150)


# Weight vs annual km scatter ----
wt_all <- rbindlist(wt_list)
wt_all[, fuel_cat := fcase(
  grepl("Benzine", fuel), "Benzine",
  grepl("Diesel", fuel), "Diesel",
  grepl("Electriciteit|Electric", fuel), "Elektrisch",
  grepl("Hybride|PHEV|HEV", fuel), "Hybride",
  default = "Overig"
)]
wt_all[, fuel_cat := factor(fuel_cat, levels = cat_order)]
# Subsample for readability
set.seed(1)
wt_sub <- wt_all[sample(.N, min(.N, 5000))]

p3 <- ggplot(wt_sub[weight > 400 & weight < 3500 & km > 0 & km < 50000],
             aes(weight, km, colour = fuel_cat)) +
  geom_point(alpha = 0.35, size = 1) +
  facet_wrap(~ year, ncol = 3) +
  scale_colour_manual(values = cat_cols, name = NULL) +
  scale_x_continuous(labels = \(x) paste0(x / 1000, "t")) +
  scale_y_continuous(labels = \(x) paste0(x / 1000, "k")) +
  labs(title = "Voertuiggewicht vs. jaarkilometrage per brandstof",
       subtitle = "EV's clusteren bij zwaarder gewicht; minder km in recente jaren",
       x = "Leeggewicht (kg)", y = "Jaarkilometrage") +
  theme(legend.position = "bottom",
        strip.text = element_text(face = "bold"))

print(p3)
ggsave("plots/demo_rdw_p3_gewicht_km.png", p3, width = 12, height = 5.5, dpi = 150)

cat("Saved 3 plots to plots/\n")
