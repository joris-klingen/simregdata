# scripts/check_rdw.R
#
# Quick validation plots for simulated RDW data.
# Checks whether fuel type transitions, VKT levels, and weight
# trends match expectations from CBS StatLine calibration.
#
# Plots produced:
#   p1 — Fuel type shares over time (stacked area, 2010–2025)
#   p2 — Mean annual km over time (line + sd ribbon)
#   p3 — Mean vehicle weight over time (line + sd ribbon)
#   p4 — Weight distribution by era (overlaid densities)
#   p5 — Map: electric drivetrain share per gemeente (latest year)

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(haven)
  library(glue)
})
devtools::load_all(".")  # must come AFTER library(haven) to avoid masking read_sav

dir.create("plots", showWarnings = FALSE)
log_msg <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), paste0(...)))

YEARS  <- 2010:2025
N_PERS <- 1e5

theme_set(
  theme_minimal(base_size = 11) +
    theme(plot.subtitle = element_text(colour = "grey45", size = 9),
          plot.caption  = element_text(colour = "grey60", size = 7),
          plot.title    = element_text(face = "bold"))
)


# Time series: loop over years ----

log_msg("Building time series across ", min(YEARS), "-", max(YEARS))

fuel_list   <- list()
weight_list <- list()
vkt_list    <- list()

# Cache data during main loop for plots 4 & 5
snap_years <- c(2010, 2015, 2020, 2025)
wt_samples <- list()

for (yr in YEARS) {
  log_msg("  year ", yr)
  sim_reset()
  woonbase_init(year = yr, n = N_PERS, seed = 42L)
  sim_init("rdw", year = yr, seed = 43L)

  # Include RINPERSOON for plot 5 map (used on last iteration)
  dt_k <- as.data.table(read_sav(
    glue("RDWNPACT{yr}TABV1"),
    col_select = c(RINPERSOON, BRANDSTCODECORVRTG, MASSALEEGCORVRTG)
  ))
  dt_vp <- as.data.table(read_sav(
    glue("VERKEERSPRESTATIE{yr}TABV1"),
    col_select = c(VPJAARKM)
  ))

  # Fuel type counts
  fc <- dt_k[, .N, by = BRANDSTCODECORVRTG]
  fc[, pct  := N / sum(N) * 100]
  fc[, year := yr]
  fc[, fuel := as.character(as_factor(BRANDSTCODECORVRTG))]
  fuel_list[[as.character(yr)]] <- fc

  # Weight summary
  weight_list[[as.character(yr)]] <- data.table(
    year    = yr,
    mean_wt = mean(dt_k$MASSALEEGCORVRTG, na.rm = TRUE),
    sd_wt   = sd(dt_k$MASSALEEGCORVRTG, na.rm = TRUE))

  # VKT summary
  vkt_list[[as.character(yr)]] <- data.table(
    year    = yr,
    mean_km = mean(dt_vp$VPJAARKM, na.rm = TRUE),
    sd_km   = sd(dt_vp$VPJAARKM, na.rm = TRUE))

  # Stash weight samples for plot 4 snapshot years
  if (yr %in% snap_years) {
    wt_samples[[as.character(yr)]] <- data.table(
      year = yr, weight = dt_k$MASSALEEGCORVRTG)
  }
}

# After loop: dt_k holds last year's data (with RINPERSOON), woonbase spine still active
YEAR <- max(YEARS)

fuel_ts   <- rbindlist(fuel_list)
weight_ts <- rbindlist(weight_list)
vkt_ts    <- rbindlist(vkt_list)


# Plot 1: Fuel type shares over time (stacked area) ----

log_msg("Plotting p1: fuel type shares")

fuel_order <- c("Benzine", "Diesel", "LPG", "CNG (aardgas)",
                "Hybride (HEV)", "Plug-in hybride (PHEV)", "Electriciteit")
fuel_colors <- c(
  "Benzine"                = "#4393C3",
  "Diesel"                 = "#878787",
  "LPG"                    = "#F4A582",
  "CNG (aardgas)"          = "#B2ABD2",
  "Hybride (HEV)"          = "#A6D96A",
  "Plug-in hybride (PHEV)" = "#1A9850",
  "Electriciteit"          = "#006837")

# Fill missing fuel×year combinations with 0
fuel_ts_full <- fuel_ts[CJ(fuel = fuel_order, year = YEARS), on = .(fuel, year)]
fuel_ts_full[is.na(N), N := 0L]
fuel_ts_full[, fuel := factor(fuel, levels = fuel_order)]

p1 <- ggplot(fuel_ts_full,
             aes(x = year, y = N, fill = fuel)) +
  geom_area(alpha = 0.85, colour = "white", linewidth = 0.2) +
  scale_fill_manual(values = fuel_colors, name = NULL) +
  scale_y_continuous(labels = scales::label_comma()) +
  scale_x_continuous(breaks = seq(2010, 2025, 5)) +
  labs(title    = "Brandstoftype personenauto\u2019s",
       subtitle = glue("Aantal per brandstofsoort, {min(YEARS)}\u2013{max(YEARS)}"),
       caption  = "Data: gesimuleerd, gekalibreerd op CBS StatLine 85237NED",
       x = NULL, y = "Aantal voertuigen") +
  theme(legend.position = "bottom",
        legend.text = element_text(size = 8))

print(p1)
ggsave("plots/check_rdw_p1_brandstof.png", p1, width = 9, height = 5, dpi = 150)
log_msg("p1 saved")


# Plot 2: Mean annual km over time ----

log_msg("Plotting p2: mean VKT over time")

p2 <- ggplot(vkt_ts, aes(x = year, y = mean_km)) +
  geom_ribbon(aes(ymin = mean_km - sd_km, ymax = mean_km + sd_km),
              fill = "#2166AC", alpha = 0.15) +
  geom_line(colour = "#2166AC", linewidth = 1) +
  geom_point(colour = "#2166AC", size = 2) +
  scale_x_continuous(breaks = seq(2010, 2025, 5)) +
  scale_y_continuous(labels = \(x) format(round(x), big.mark = ",")) +
  labs(title    = "Gemiddeld jaarkilometrage",
       subtitle = glue("Per voertuig, {min(YEARS)}\u2013{max(YEARS)} (lint = \u00b11 sd)"),
       caption  = "Data: gesimuleerd, gekalibreerd op CBS StatLine 85404NED",
       x = NULL, y = "km / jaar")

print(p2)
ggsave("plots/check_rdw_p2_vkt.png", p2, width = 8, height = 5, dpi = 150)
log_msg("p2 saved")


# Plot 3: Mean vehicle weight over time ----

log_msg("Plotting p3: mean weight over time")

p3 <- ggplot(weight_ts, aes(x = year, y = mean_wt)) +
  geom_ribbon(aes(ymin = mean_wt - sd_wt, ymax = mean_wt + sd_wt),
              fill = "#D6604D", alpha = 0.15) +
  geom_line(colour = "#D6604D", linewidth = 1) +
  geom_point(colour = "#D6604D", size = 2) +
  scale_x_continuous(breaks = seq(2010, 2025, 5)) +
  labs(title    = "Gemiddeld leeggewicht personenauto\u2019s",
       subtitle = glue("Per voertuig, {min(YEARS)}\u2013{max(YEARS)} (lint = \u00b11 sd)"),
       caption  = "Data: gesimuleerd, gekalibreerd op CBS StatLine 85237NED",
       x = NULL, y = "Leeggewicht (kg)")

print(p3)
ggsave("plots/check_rdw_p3_gewicht.png", p3, width = 8, height = 5, dpi = 150)
log_msg("p3 saved")


# Plot 4: Weight distribution by era ----

log_msg("Plotting p4: weight distributions")

# Use cached wt_samples from the main loop (no re-simulation needed)
wt_all <- rbindlist(wt_samples)
wt_all[, year_f := factor(year)]

p4 <- ggplot(wt_all, aes(x = weight, fill = year_f, colour = year_f)) +
  geom_density(alpha = 0.25, linewidth = 0.6) +
  scale_fill_brewer(palette = "RdYlBu", direction = -1, name = "Jaar") +
  scale_colour_brewer(palette = "RdYlBu", direction = -1, name = "Jaar") +
  scale_x_continuous(limits = c(500, 3000),
                     labels = \(x) format(x, big.mark = ",")) +
  labs(title    = "Verdeling leeggewicht personenauto\u2019s",
       subtitle = "Verschuiving naar zwaardere voertuigen (o.a. EV\u2019s)",
       caption  = "Data: gesimuleerd, gekalibreerd op CBS StatLine 85237NED",
       x = "Leeggewicht (kg)", y = "Dichtheid") +
  theme(legend.position = c(0.88, 0.75))

print(p4)
ggsave("plots/check_rdw_p4_gewicht_dist.png", p4, width = 8, height = 5, dpi = 150)
log_msg("p4 saved")


# Plot 5: Map — EV drivetrain share per gemeente ----

log_msg("Plotting p5: map EV share")

# Reuse dt_k from last iteration (already has RINPERSOON + BRANDSTCODECORVRTG)
dt_k[, fuel := as.character(as_factor(BRANDSTCODECORVRTG))]
dt_k[, is_ev := fuel %in% c("Electriciteit", "Plug-in hybride (PHEV)", "Hybride (HEV)")]

# Woonbase spine is still active from last loop iteration — no re-init needed
dt_pers <- as.data.table(read_sav(
  glue("WoonbasePopulatiePersonen{YEAR}V1"),
  col_select = c(RINPERSOON, RINOBJECTNUMMER1Jan)
))
dt_woon <- as.data.table(read_sav(
  glue("WoonbaseKenmerkenWoonruimten{YEAR}V1"),
  col_select = c(RINOBJECTNUMMER, GEMEENTECODEJJJJ1Jan)
))

# Join: person → dwelling → gemeente
dt_pers[dt_woon, on = c("RINOBJECTNUMMER1Jan" = "RINOBJECTNUMMER"),
        gem_code := i.GEMEENTECODEJJJJ1Jan]

# Join: kenteken → person → gemeente
dt_k[dt_pers, on = "RINPERSOON", gem_code := i.gem_code]

# Gemeente-level EV share
gem_ev <- dt_k[!is.na(gem_code),
               .(ev_share = mean(is_ev) * 100, n_veh = .N),
               by = gem_code]

# Load gemeente boundaries
sf::sf_use_s2(FALSE)
gem_sf <- tryCatch(
  sf::st_read(
    glue("https://cartomap.github.io/nl/wgs84/gemeente_{YEAR}.geojson"),
    quiet = TRUE),
  error = function(e) {
    log_msg("Could not load shapefile: ", conditionMessage(e))
    NULL
  }
)

if (!is.null(gem_sf)) {
  gem_sf <- setDT(gem_sf)[, GemCode4 := sub("^GM", "", statcode)]
  gem_sf <- sf::st_as_sf(gem_sf)

  map_sf <- merge(gem_sf, gem_ev, by.x = "GemCode4", by.y = "gem_code",
                  all.x = TRUE)

  map_theme <- theme_void(base_size = 11) +
    theme(plot.title    = element_text(face = "bold", size = 13,
                                       margin = margin(b = 4)),
          plot.subtitle = element_text(colour = "grey45", size = 9,
                                       margin = margin(b = 8)),
          plot.caption  = element_text(colour = "grey60", size = 7),
          legend.position = "right")

  p5 <- ggplot(map_sf) +
    geom_sf(aes(fill = ev_share), colour = "white", linewidth = 0.1) +
    scale_fill_distiller(palette  = "Greens", direction = 1,
                         na.value = "grey88",
                         name     = "EV %",
                         labels   = \(x) paste0(round(x), "%")) +
    labs(title    = "Aandeel elektrisch aangedreven voertuigen",
         subtitle = glue("BEV + PHEV + HEV per gemeente, {YEAR}"),
         caption  = glue("Data: gesimuleerd, gekalibreerd op CBS StatLine\n",
                          "Gemeentegrenzen: CBS {YEAR} via cartomap.github.io")) +
    map_theme

  print(p5)
  ggsave("plots/check_rdw_p5_map_ev.png", p5, width = 6.5, height = 9, dpi = 150)
  log_msg("p5 saved")
} else {
  log_msg("p5 skipped (shapefile unavailable)")
}

log_msg("Done \u2014 all figures saved to plots/")
