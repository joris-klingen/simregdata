# scripts/check_rdw_profiled.R
#
# Profiled version of check_rdw.R — identical output but with
# per-step timing instrumentation to identify bottlenecks.
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

# Timing infrastructure ----

timings <- list()
tic <- function(label) {
  timings[[label]] <<- list(start = proc.time()[["elapsed"]])
}
toc <- function(label) {
  timings[[label]]$end <<- proc.time()[["elapsed"]]
  timings[[label]]$elapsed <<- timings[[label]]$end - timings[[label]]$start
}


# Time series: loop over years ----

log_msg("Building time series across ", min(YEARS), "-", max(YEARS))
tic("main_loop_total")

fuel_list   <- list()
weight_list <- list()
vkt_list    <- list()

for (yr in YEARS) {
  yr_c <- as.character(yr)
  log_msg("  year ", yr)

  tic(paste0("yr", yr, "_reset"))
  sim_reset()
  toc(paste0("yr", yr, "_reset"))

  tic(paste0("yr", yr, "_wb_init"))
  woonbase_init(year = yr, n = N_PERS, seed = 42L)
  toc(paste0("yr", yr, "_wb_init"))

  tic(paste0("yr", yr, "_rdw_init"))
  sim_init("rdw", year = yr, seed = 43L)
  toc(paste0("yr", yr, "_rdw_init"))

  tic(paste0("yr", yr, "_read_kentekens"))
  dt_k <- as.data.table(read_sav(
    glue("RDWNPACT{yr}TABV1"),
    col_select = c(BRANDSTCODECORVRTG, MASSALEEGCORVRTG)
  ))
  toc(paste0("yr", yr, "_read_kentekens"))

  tic(paste0("yr", yr, "_read_vp"))
  dt_vp <- as.data.table(read_sav(
    glue("VERKEERSPRESTATIE{yr}TABV1"),
    col_select = c(VPJAARKM)
  ))
  toc(paste0("yr", yr, "_read_vp"))

  # Fuel type counts
  fc <- dt_k[, .N, by = BRANDSTCODECORVRTG]
  fc[, pct  := N / sum(N) * 100]
  fc[, year := yr]
  fc[, fuel := as.character(as_factor(BRANDSTCODECORVRTG))]
  fuel_list[[yr_c]] <- fc

  # Weight summary
  weight_list[[yr_c]] <- data.table(
    year    = yr,
    mean_wt = mean(dt_k$MASSALEEGCORVRTG, na.rm = TRUE),
    sd_wt   = sd(dt_k$MASSALEEGCORVRTG, na.rm = TRUE))

  # VKT summary
  vkt_list[[yr_c]] <- data.table(
    year    = yr,
    mean_km = mean(dt_vp$VPJAARKM, na.rm = TRUE),
    sd_km   = sd(dt_vp$VPJAARKM, na.rm = TRUE))
}

toc("main_loop_total")

fuel_ts   <- rbindlist(fuel_list)
weight_ts <- rbindlist(weight_list)
vkt_ts    <- rbindlist(vkt_list)


# Plot 1: Fuel type shares over time (stacked area) ----

log_msg("Plotting p1: fuel type shares")
tic("plot1")

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

toc("plot1")
log_msg("p1 saved")


# Plot 2: Mean annual km over time ----

log_msg("Plotting p2: mean VKT over time")
tic("plot2")

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

toc("plot2")
log_msg("p2 saved")


# Plot 3: Mean vehicle weight over time ----

log_msg("Plotting p3: mean weight over time")
tic("plot3")

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

toc("plot3")
log_msg("p3 saved")


# Plot 4: Weight distribution by era ----

log_msg("Plotting p4: weight distributions")
tic("plot4_sim")

# Re-simulate 4 snapshot years and collect vehicle weights
snap_years <- c(2010, 2015, 2020, 2025)
wt_samples <- list()
for (yr in snap_years) {
  tic(paste0("p4_yr", yr, "_total"))

  tic(paste0("p4_yr", yr, "_reset"))
  sim_reset()
  toc(paste0("p4_yr", yr, "_reset"))

  tic(paste0("p4_yr", yr, "_wb_init"))
  woonbase_init(year = yr, n = N_PERS, seed = 42L)
  toc(paste0("p4_yr", yr, "_wb_init"))

  tic(paste0("p4_yr", yr, "_rdw_init"))
  sim_init("rdw", year = yr, seed = 43L)
  toc(paste0("p4_yr", yr, "_rdw_init"))

  tic(paste0("p4_yr", yr, "_read"))
  dt_k <- as.data.table(read_sav(
    glue("RDWNPACT{yr}TABV1"),
    col_select = c(MASSALEEGCORVRTG)
  ))
  toc(paste0("p4_yr", yr, "_read"))

  wt_samples[[as.character(yr)]] <- data.table(
    year = yr, weight = dt_k$MASSALEEGCORVRTG)

  toc(paste0("p4_yr", yr, "_total"))
}
toc("plot4_sim")

tic("plot4_render")
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

toc("plot4_render")
log_msg("p4 saved")


# Plot 5: Map — EV drivetrain share per gemeente ----

log_msg("Plotting p5: map EV share")
tic("plot5_total")

YEAR <- max(YEARS)

tic("p5_reset")
sim_reset()
toc("p5_reset")

tic("p5_wb_init")
woonbase_init(year = YEAR, n = N_PERS, seed = 42L)
toc("p5_wb_init")

tic("p5_rdw_init")
sim_init("rdw", year = YEAR, seed = 43L)
toc("p5_rdw_init")

# Load kentekens with fuel type + person ID
tic("p5_read_kentekens")
dt_k <- as.data.table(read_sav(
  glue("RDWNPACT{YEAR}TABV1"),
  col_select = c(RINPERSOON, BRANDSTCODECORVRTG)
))
toc("p5_read_kentekens")

dt_k[, fuel := as.character(as_factor(BRANDSTCODECORVRTG))]
dt_k[, is_ev := fuel %in% c("Electriciteit", "Plug-in hybride (PHEV)", "Hybride (HEV)")]

# Load woonbase person → dwelling → gemeente
tic("p5_read_woonbase")
dt_pers <- as.data.table(read_sav(
  glue("WoonbasePopulatiePersonen{YEAR}V1"),
  col_select = c(RINPERSOON, RINOBJECTNUMMER1Jan)
))
dt_woon <- as.data.table(read_sav(
  glue("WoonbaseKenmerkenWoonruimten{YEAR}V1"),
  col_select = c(RINOBJECTNUMMER, GEMEENTECODEJJJJ1Jan)
))
toc("p5_read_woonbase")

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
tic("p5_shapefile")
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
toc("p5_shapefile")

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

  tic("p5_render")
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
  toc("p5_render")
  log_msg("p5 saved")
} else {
  log_msg("p5 skipped (shapefile unavailable)")
}

toc("plot5_total")


# Timing summary ----

log_msg("Done \u2014 all figures saved to plots/")
cat("\n\n=== TIMING SUMMARY ===\n\n")

# Per-year breakdown
cat("--- Main loop: per-year breakdown ---\n")
cat(sprintf("%-8s  %8s  %8s  %8s  %8s  %8s\n",
            "Year", "reset", "wb_init", "rdw_init", "kenteken", "verkprest"))
for (yr in YEARS) {
  cat(sprintf("%-8d  %7.2fs  %7.2fs  %7.2fs  %7.2fs  %7.2fs\n",
              yr,
              timings[[paste0("yr", yr, "_reset")]]$elapsed,
              timings[[paste0("yr", yr, "_wb_init")]]$elapsed,
              timings[[paste0("yr", yr, "_rdw_init")]]$elapsed,
              timings[[paste0("yr", yr, "_read_kentekens")]]$elapsed,
              timings[[paste0("yr", yr, "_read_vp")]]$elapsed))
}
cat(sprintf("\nMain loop total: %.2fs\n\n", timings$main_loop_total$elapsed))

# Plot 4 re-simulation breakdown
cat("--- Plot 4: re-simulation per snapshot year ---\n")
cat(sprintf("%-8s  %8s  %8s  %8s  %8s  %8s\n",
            "Year", "reset", "wb_init", "rdw_init", "read", "total"))
for (yr in snap_years) {
  cat(sprintf("%-8d  %7.2fs  %7.2fs  %7.2fs  %7.2fs  %7.2fs\n",
              yr,
              timings[[paste0("p4_yr", yr, "_reset")]]$elapsed,
              timings[[paste0("p4_yr", yr, "_wb_init")]]$elapsed,
              timings[[paste0("p4_yr", yr, "_rdw_init")]]$elapsed,
              timings[[paste0("p4_yr", yr, "_read")]]$elapsed,
              timings[[paste0("p4_yr", yr, "_total")]]$elapsed))
}
cat(sprintf("\nPlot 4 simulation total: %.2fs\n", timings$plot4_sim$elapsed))
cat(sprintf("Plot 4 render: %.2fs\n\n", timings$plot4_render$elapsed))

# Plot 5 breakdown
cat("--- Plot 5: map ---\n")
cat(sprintf("  reset:          %7.2fs\n", timings$p5_reset$elapsed))
cat(sprintf("  woonbase_init:  %7.2fs\n", timings$p5_wb_init$elapsed))
cat(sprintf("  rdw_init:       %7.2fs\n", timings$p5_rdw_init$elapsed))
cat(sprintf("  read_kentekens: %7.2fs\n", timings$p5_read_kentekens$elapsed))
cat(sprintf("  read_woonbase:  %7.2fs\n", timings$p5_read_woonbase$elapsed))
cat(sprintf("  shapefile:      %7.2fs\n", timings$p5_shapefile$elapsed))
if (!is.null(timings$p5_render))
  cat(sprintf("  render:         %7.2fs\n", timings$p5_render$elapsed))
cat(sprintf("\nPlot 5 total: %.2fs\n\n", timings$plot5_total$elapsed))

# Plot 1-3 render times
cat("--- Plot render times ---\n")
cat(sprintf("  p1 (fuel area):    %7.2fs\n", timings$plot1$elapsed))
cat(sprintf("  p2 (VKT line):     %7.2fs\n", timings$plot2$elapsed))
cat(sprintf("  p3 (weight line):  %7.2fs\n", timings$plot3$elapsed))

# Grand totals
total_main <- timings$main_loop_total$elapsed
total_p4   <- timings$plot4_sim$elapsed + timings$plot4_render$elapsed
total_p5   <- timings$plot5_total$elapsed
total_plot <- timings$plot1$elapsed + timings$plot2$elapsed + timings$plot3$elapsed
grand      <- total_main + total_plot + total_p4 + total_p5

cat(sprintf("\n--- Grand totals ---\n"))
cat(sprintf("  Main loop (16 yrs):  %7.2fs  (%4.1f%%)\n", total_main, total_main/grand*100))
cat(sprintf("  Plots 1-3 render:    %7.2fs  (%4.1f%%)\n", total_plot, total_plot/grand*100))
cat(sprintf("  Plot 4 (re-sim):     %7.2fs  (%4.1f%%)\n", total_p4,   total_p4/grand*100))
cat(sprintf("  Plot 5 (map):        %7.2fs  (%4.1f%%)\n", total_p5,   total_p5/grand*100))
cat(sprintf("  GRAND TOTAL:         %7.2fs\n", grand))

# Highlight wasted work
cat(sprintf("\n--- Wasted re-simulation ---\n"))
cat(sprintf("  Plot 4 re-sim (4 yrs already in main loop): %.2fs\n", timings$plot4_sim$elapsed))
cat(sprintf("  Plot 5 re-sim (1 yr already in main loop):  %.2fs\n",
            timings$p5_reset$elapsed + timings$p5_wb_init$elapsed +
            timings$p5_rdw_init$elapsed + timings$p5_read_kentekens$elapsed))
cat(sprintf("  Total wasted: ~%.1fs (%.0f%% of grand total)\n",
            timings$plot4_sim$elapsed + timings$p5_reset$elapsed +
            timings$p5_wb_init$elapsed + timings$p5_rdw_init$elapsed +
            timings$p5_read_kentekens$elapsed,
            (timings$plot4_sim$elapsed + timings$p5_reset$elapsed +
             timings$p5_wb_init$elapsed + timings$p5_rdw_init$elapsed +
             timings$p5_read_kentekens$elapsed) / grand * 100))
