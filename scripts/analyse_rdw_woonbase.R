# scripts/analyse_rdw_woonbase.R
#
# Joins Woonbase + RDW (kentekens + verkeersprestatie) to explore
# car ownership and VKT across time, space, and housing indicators.
#
# Plots produced:
#   p1 — Fuel type shares over time (2020–2023)
#   p2 — Cars per household by dwelling type and household type
#   p3 — Map: car ownership rate per gemeente
#   p4 — Map: average annual km per household per gemeente
#   p5 — Scatter: gemeente-level VKT vs WOZ value

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(haven)
  library(glue)
})
devtools::load_all(".")  # must come AFTER library(haven) to avoid masking read_sav

dir.create("plots", showWarnings = FALSE)
log_msg <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), paste0(...)))

YEARS  <- c(2010:2025)
N_PERS <- 1e6
BLUE   <- "#2166AC"

theme_set(
  theme_minimal(base_size = 11) +
    theme(plot.subtitle = element_text(colour = "grey45", size = 9),
          plot.caption  = element_text(colour = "grey60", size = 7),
          plot.title    = element_text(face = "bold"))
)


# Plot 1: Fuel type shares over time ----

log_msg("Building fuel type time series (", min(YEARS), "-", max(YEARS), ")")

fuel_list <- list()

for (yr in YEARS) {
  log_msg("  year ", yr)
  sim_reset()
  woonbase_init(year = yr, n = N_PERS, seed = 42L)
  sim_init("rdw", year = yr, seed = 43L)

  dt_k <- as.data.table(read_sav(
    glue("RDWNPACT{yr}TABV1"),
    col_select = c(BRANDSTCODECORVRTG)
  ))

  counts <- dt_k[, .N, by = BRANDSTCODECORVRTG]
  counts[, pct  := N / sum(N) * 100]
  counts[, year := yr]
  counts[, fuel := as.character(as_factor(BRANDSTCODECORVRTG))]
  fuel_list[[as.character(yr)]] <- counts
}

fuel_ts <- rbindlist(fuel_list)

# Keep the main fuel types for readability
main_fuels <- fuel_ts[, .(total = sum(N)), by = fuel][order(-total)][1:6, fuel]
fuel_ts_sub <- fuel_ts[fuel %in% main_fuels]

p1 <- ggplot(fuel_ts_sub,
             aes(x = factor(year), y = pct, fill = fuel)) +
  geom_col(position = "dodge", width = 0.7) +
  scale_fill_brewer(palette = "Set2", name = NULL) +
  scale_y_continuous(labels = \(x) paste0(x, "%")) +
  labs(title    = "Brandstoftype personenauto's",
       subtitle = glue("Aandeel per brandstofsoort, {min(YEARS)}\u2013{max(YEARS)}"),
       caption  = "Data: CBS RDW (gesimuleerd, gekalibreerd op CBS StatLine 85237NED)",
       x = NULL, y = "Aandeel (%)") +
  theme(legend.position = "bottom")

print(p1)
ggsave("plots/rdw_p1_brandstof_tijd.png", p1, width = 8, height = 5, dpi = 150)
log_msg("p1 saved")


# Re-init at latest year for remaining plots ----

YEAR <- max(YEARS)
sim_reset()
log_msg("Initializing spines for ", YEAR)
woonbase_init(year = YEAR, n = N_PERS, seed = 42L)
sim_init("rdw", year = YEAR, seed = 43L)


# Load Woonbase files ----

log_msg("Reading Woonbase files")
dt_pers <- as.data.table(read_sav(
  glue("WoonbasePopulatiePersonen{YEAR}V1"),
  col_select = c(RINPERSOON, HUISHOUDNR1Jan, TYPHH1Jan,
                 RINOBJECTNUMMER1Jan, VBOWoningType1Jan,
                 TypeEigenaar1Jan, AantalPersonenPerHuishouden1Jan)
))

dt_woon <- as.data.table(read_sav(
  glue("WoonbaseKenmerkenWoonruimten{YEAR}V1"),
  col_select = c(RINOBJECTNUMMER, GEMEENTECODEJJJJ1Jan,
                 WOZWaardeObjectBAG1Jan, VBOOppervlakte1Jan)
))


# Load RDW files ----

log_msg("Reading RDW files")
dt_kent <- as.data.table(read_sav(
  glue("RDWNPACT{YEAR}TABV1"),
  col_select = c(RINPERSOON, VRTGSOORT, BRANDSTCODECORVRTG, MASSALEEGCORVRTG)
))

dt_vp <- as.data.table(read_sav(
  glue("VERKEERSPRESTATIE{YEAR}TABV1"),
  col_select = c(RinpersoonVP, VPJAARKM)
))


# Joins ----

log_msg("Joining datasets")

# Add gemeente + WOZ to persons via dwelling
dt_pers[dt_woon,
        on = c("RINOBJECTNUMMER1Jan" = "RINOBJECTNUMMER"),
        `:=`(gem_code = i.GEMEENTECODEJJJJ1Jan,
             WOZ      = i.WOZWaardeObjectBAG1Jan,
             opp_m2   = i.VBOOppervlakte1Jan)]

# Count cars per person
cars_per_pers <- dt_kent[, .(n_cars = .N), by = RINPERSOON]
dt_pers[cars_per_pers, on = "RINPERSOON", n_cars := i.n_cars]
dt_pers[is.na(n_cars), n_cars := 0L]

# Add VKT per person
vkt_per_pers <- dt_vp[, .(total_km = sum(VPJAARKM, na.rm = TRUE)), by = RinpersoonVP]
dt_pers[vkt_per_pers, on = c("RINPERSOON" = "RinpersoonVP"), total_km := i.total_km]
dt_pers[is.na(total_km), total_km := 0]

# Factor labels
dt_pers[, typhh_f      := as_factor(TYPHH1Jan)]
dt_pers[, woningtype_f := as_factor(VBOWoningType1Jan)]
dt_pers[, eigenaar_f   := as_factor(TypeEigenaar1Jan)]

# Household-level aggregation (exclude institutional HH — no private car ownership)
dt_hh <- dt_pers[!is.na(gem_code) & !grepl("nstitut", typhh_f),
                 .(hh_cars  = sum(n_cars),
                   hh_km    = sum(total_km),
                   hh_size  = as.integer(AantalPersonenPerHuishouden1Jan[1]),
                   typhh_f  = typhh_f[1],
                   woningtype_f = woningtype_f[1],
                   eigenaar_f   = eigenaar_f[1],
                   WOZ      = WOZ[1],
                   opp_m2   = opp_m2[1]),
                 by = .(HUISHOUDNR1Jan, gem_code)]


# Plot 2: Cars per household by dwelling type and HH type ----

log_msg("Plotting p2: car ownership by housing indicators")

# Panel A: by dwelling type
p2a_data <- dt_hh[!is.na(woningtype_f) & !grepl("nbekend", woningtype_f),
                  .(avg_cars = mean(hh_cars)), by = woningtype_f]

p2a <- ggplot(p2a_data, aes(x = reorder(woningtype_f, avg_cars), y = avg_cars)) +
  geom_col(fill = BLUE, width = 0.65) +
  geom_text(aes(label = sprintf("%.2f", avg_cars)), hjust = -0.1, size = 3.2) +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Autobezit naar woningtype",
       subtitle = glue("Gem. personenauto's per huishouden, {YEAR}"),
       x = NULL, y = "Auto's per huishouden")

# Panel B: by household type
p2b_data <- dt_hh[!is.na(typhh_f),
                  .(avg_cars = mean(hh_cars)), by = typhh_f]

p2b <- ggplot(p2b_data, aes(x = reorder(typhh_f, avg_cars), y = avg_cars)) +
  geom_col(fill = "#D6604D", width = 0.65) +
  geom_text(aes(label = sprintf("%.2f", avg_cars)), hjust = -0.1, size = 3.2) +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Autobezit naar huishoudtype",
       subtitle = glue("Gem. personenauto's per huishouden, {YEAR}"),
       x = NULL, y = "Auto's per huishouden")

p2 <- patchwork::wrap_plots(p2a, p2b, ncol = 2) +
  patchwork::plot_annotation(
    caption = "Data: CBS Woonbase + RDW (gesimuleerd)")

print(p2)
ggsave("plots/rdw_p2_autobezit_woning_hh.png", p2, width = 12, height = 5, dpi = 150)
log_msg("p2 saved")


# Load gemeente boundaries ----

log_msg("Loading gemeente boundaries")
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

if (is.null(gem_sf)) {
  log_msg("Maps skipped (gemeente shapefile unavailable)")
  q(save = "no")
}

gem_sf <- setDT(gem_sf)[, GemCode4 := sub("^GM", "", statcode)]
gem_sf <- sf::st_as_sf(gem_sf)

map_theme <- theme_void(base_size = 11) +
  theme(plot.title    = element_text(face = "bold", size = 13,
                                     margin = margin(b = 4)),
        plot.subtitle = element_text(colour = "grey45", size = 9,
                                     margin = margin(b = 8)),
        plot.caption  = element_text(colour = "grey60", size = 7),
        legend.position = "right")


# Gemeente-level aggregates ----

gem_stats <- dt_hh[, .(avg_cars  = mean(hh_cars),
                       avg_km_hh = mean(hh_km),
                       avg_woz_k = mean(WOZ, na.rm = TRUE) / 1e3,
                       n_hh      = .N),
                   by = gem_code]


# Plot 3: Map — car ownership rate per gemeente ----

log_msg("Plotting p3: map car ownership")

map3_sf <- merge(gem_sf, gem_stats, by.x = "GemCode4", by.y = "gem_code",
                 all.x = TRUE)

p3 <- ggplot(map3_sf) +
  geom_sf(aes(fill = avg_cars), colour = "white", linewidth = 0.1) +
  scale_fill_distiller(palette  = "YlGnBu", direction = 1,
                       na.value = "grey88",
                       name     = "Auto's\nper HH") +
  labs(title    = "Autobezit per huishouden",
       subtitle = glue("Per gemeente, {YEAR}"),
       caption  = glue("Data: CBS Woonbase + RDW (gesimuleerd)\n",
                        "Gemeentegrenzen: CBS {YEAR} via cartomap.github.io")) +
  map_theme

print(p3)
ggsave("plots/rdw_p3_map_autobezit.png", p3, width = 6.5, height = 9, dpi = 150)
log_msg("p3 saved")


# Plot 4: Map — average annual km per household per gemeente ----

log_msg("Plotting p4: map VKT per household")

p4 <- ggplot(map3_sf) +
  geom_sf(aes(fill = avg_km_hh), colour = "white", linewidth = 0.1) +
  scale_fill_distiller(palette  = "YlOrRd", direction = 1,
                       na.value = "grey88",
                       name     = "km/jaar",
                       labels   = \(x) format(round(x), big.mark = ",")) +
  labs(title    = "Jaarkilometers per huishouden",
       subtitle = glue("Per gemeente, {YEAR}"),
       caption  = glue("Data: CBS Woonbase + RDW Verkeersprestatie (gesimuleerd)\n",
                        "Gemeentegrenzen: CBS {YEAR} via cartomap.github.io")) +
  map_theme

print(p4)
ggsave("plots/rdw_p4_map_vkt.png", p4, width = 6.5, height = 9, dpi = 150)
log_msg("p4 saved")


# Plot 5: Scatter — gemeente VKT vs WOZ ----

log_msg("Plotting p5: scatter VKT vs WOZ")

p5_data <- gem_stats[n_hh >= 10 & !is.na(avg_woz_k) & avg_woz_k > 0]

p5 <- ggplot(p5_data, aes(x = avg_woz_k, y = avg_km_hh / 1000, size = n_hh)) +
  geom_point(alpha = 0.5, colour = BLUE) +
  geom_smooth(method = "lm", se = TRUE, colour = "#D6604D",
              linewidth = 0.8, show.legend = FALSE) +
  scale_x_continuous(labels = \(x) paste0("\u20ac", round(x), "k")) +
  scale_y_continuous(labels = \(x) paste0(x, "k")) +
  scale_size_continuous(name = "Huishoudens", range = c(1, 6),
                        labels = scales::comma) +
  labs(title    = "Jaarkilometers vs. WOZ-waarde",
       subtitle = glue("Per gemeente, {YEAR} (gemeenten met \u226510 huishoudens)"),
       caption  = "Data: CBS Woonbase + RDW (gesimuleerd)",
       x = "Gemiddelde WOZ-waarde",
       y = "Gemiddelde km/jaar per HH (\u00d71.000)") +
  theme(legend.position = c(0.85, 0.80))

print(p5)
ggsave("plots/rdw_p5_scatter_vkt_woz.png", p5, width = 7, height = 6, dpi = 150)
log_msg("p5 saved")

log_msg("Done \u2014 all figures saved to plots/")

