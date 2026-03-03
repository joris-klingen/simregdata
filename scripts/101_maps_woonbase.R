# scripts/101_maps_woonbase.R
#
# Municipality choropleths from Woonbase 2020:
#   map1 — Population per gemeente
#   map2 — Population density per gemeente (persons / km²)

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(haven)
  library(simcbsradata)
  library(glue)
})

YEAR <- 2020L
log_message <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), paste0(...)))

# Inspect catalog ----

woonbase_catalog(year = YEAR)


# Load data ----

log_message("Loading Woonbase files")

woonbase_init(year = YEAR, n = NULL, seed = 42L)

log_message("Reading PopulatieHuishoudens")
dt_hh <- as.data.table(read_sav(
  file       = glue("WoonbasePopulatieHuishoudens{YEAR}V1"),
  col_select = c(RINPERSOON, RINOBJECTNUMMER1Jan, VBOWoningType1Jan)
))

log_message("Reading KenmerkenWoonruimten")
dt_woon <- as.data.table(read_sav(
  file       = glue("WoonbaseKenmerkenWoonruimten{YEAR}V1"),
  col_select = c(RINOBJECTNUMMER, GemeenteCodeJJJJ1Jan)
))

# Join gemeente onto households via object key
log_message("Joining gemeente onto households")
dt_hh[dt_woon,
      on = c("RINOBJECTNUMMER1Jan" = "RINOBJECTNUMMER"),
      GemeenteCodeJJJJ1Jan := i.GemeenteCodeJJJJ1Jan]

# Aggregate: persons per gemeente
gem_pop <- dt_hh[!is.na(GemeenteCodeJJJJ1Jan),
                 .(n_personen = .N),
                 by = .(GemCode4 = GemeenteCodeJJJJ1Jan)]


# Load gemeente boundaries ----

log_message("Loading gemeente boundaries")

sf::sf_use_s2(FALSE)   # cartomap GeoJSON has minor topology issues

gem_sf <- tryCatch(
  sf::st_read(
    glue("https://cartomap.github.io/nl/wgs84/gemeente_{YEAR}.geojson"),
    quiet = TRUE),
  error = function(e) {
    log_message("Could not load shapefile: ", conditionMessage(e))
    NULL
  }
)

if (is.null(gem_sf)) {
  log_message("Maps skipped (gemeente shapefile unavailable)")
  q(save = "no")
}

# statcode in cartomap is "GM0363"; strip prefix → "0363" to match our codes
gem_sf <- setDT(gem_sf)[, GemCode4 := sub("^GM", "", statcode)]
gem_sf <- sf::st_as_sf(gem_sf)

# Compute area in km² from geometry
gem_sf$area_km2 <- as.numeric(sf::st_area(gem_sf)) / 1e6

map_sf <- merge(gem_sf, gem_pop, by = "GemCode4", all.x = TRUE)
map_sf$dichtheid <- map_sf$n_personen / map_sf$area_km2

map_theme <- theme_void(base_size = 11) +
  theme(plot.title    = element_text(face = "bold", size = 13,
                                     margin = margin(b = 4)),
        plot.subtitle = element_text(colour = "grey45", size = 9,
                                     margin = margin(b = 8)),
        plot.caption  = element_text(colour = "grey60", size = 7),
        legend.position = "right")


# Map 1: population per gemeente ----

log_message("Plotting map1: bevolking per gemeente")

map1 <- ggplot(map_sf) +
  geom_sf(aes(fill = n_personen), colour = "white", linewidth = 0.1) +
  scale_fill_distiller(palette  = "Blues", direction = 1,
                       na.value = "grey88", name = "Personen",
                       labels   = \(x) format(round(x), big.mark = ",")) +
  labs(title    = "Bevolking per gemeente",
       subtitle = glue("Personen in Woonbase, 1 januari {YEAR}"),
       caption  = glue("Gemeentegrenzen: CBS {YEAR} via cartomap.github.io\nData: CBS Woonbase (gesimuleerd)")) +
  map_theme

print(map1)
ggsave("output/figures/101_map1_bevolking_gemeente.png",
       map1, width = 6.5, height = 9, dpi = 150)
log_message("map1 saved")


# Map 2: population density per gemeente ----

log_message("Plotting map2: bevolkingsdichtheid per gemeente")

map2 <- ggplot(map_sf) +
  geom_sf(aes(fill = dichtheid), colour = "white", linewidth = 0.1) +
  scale_fill_distiller(palette  = "YlOrRd", direction = 1,
                       na.value = "grey88",
                       name     = "Personen\nper km\u00b2",
                       labels   = \(x) format(round(x), big.mark = ",")) +
  labs(title    = "Bevolkingsdichtheid per gemeente",
       subtitle = glue("Personen per km\u00b2, 1 januari {YEAR}"),
       caption  = glue("Gemeentegrenzen: CBS {YEAR} via cartomap.github.io\nData: CBS Woonbase (gesimuleerd)")) +
  map_theme

print(map2)
ggsave("output/figures/101_map2_dichtheid_gemeente.png",
       map2, width = 6.5, height = 9, dpi = 150)
log_message("map2 saved")

log_message("Done — figures saved to output/figures/")
