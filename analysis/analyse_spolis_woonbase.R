# scripts/analyse_spolis_woonbase.R
#
# Joins Woonbase + SPOLIS to explore employment across space and housing.
#
# Plots produced:
#   p1 — Map: jobs per 1,000 residents per gemeente, 2023
#   p2 — Time series: share of persons with a job, by dwelling type (2016–2024)

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(haven)
  library(glue)
})
devtools::load_all(".")  # must come AFTER library(haven)

dir.create("plots", showWarnings = FALSE)
log_msg <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), paste0(...)))

N_PERS <- 1e4
BLUE   <- "#2166AC"

theme_set(
  theme_minimal(base_size = 11) +
    theme(plot.subtitle = element_text(colour = "grey45", size = 9),
          plot.caption  = element_text(colour = "grey60", size = 7),
          plot.title    = element_text(face = "bold"))
)


# Plot 1: Jobs per gemeente (2023) ----

YEAR <- 2023L
log_msg("Initialising spines for ", YEAR)
sim_reset()
woonbase_init(year = YEAR, n = N_PERS, seed = 42L)
sim_init("spolis", year = YEAR, seed = 43L)

log_msg("Reading SPOLIS")
dt_jobs <- as.data.table(read_sav(
  glue("SPOLISBUS{YEAR}V1"),
  col_select = c(RINPERSOON)
))

log_msg("Reading Woonbase (object-level)")
dt_obj <- as.data.table(read_sav(
  glue("WoonbaseKenmerkenWoonruimten{YEAR}V1"),
  col_select = c(RINOBJECTNUMMER, GEMEENTECODEJJJJ1Jan)
))

log_msg("Reading Woonbase (person-level)")
dt_pers <- as.data.table(read_sav(
  glue("WoonbasePopulatiePersonen{YEAR}V1"),
  col_select = c(RINPERSOON, RINOBJECTNUMMER1Jan)
))

# Link person → gemeente via dwelling
dt_pers[dt_obj, on = c("RINOBJECTNUMMER1Jan" = "RINOBJECTNUMMER"),
        gem_code := i.GEMEENTECODEJJJJ1Jan]

# Count distinct jobs per gemeente (via person link)
jobs_per_pers <- dt_jobs[, .(n_jobs = .N), by = RINPERSOON]
dt_pers[jobs_per_pers, on = "RINPERSOON", n_jobs := i.n_jobs]
dt_pers[is.na(n_jobs), n_jobs := 0L]

gem_jobs <- dt_pers[!is.na(gem_code),
                    .(total_jobs = sum(n_jobs), n_pers = .N),
                    by = gem_code]
gem_jobs[, jobs_per_1k := total_jobs / n_pers * 1000]

# Load gemeente boundaries
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

# Map: jobs per 1,000 residents per gemeente
map1_sf <- merge(gem_sf, gem_jobs, by.x = "GemCode4", by.y = "gem_code",
                 all.x = TRUE)

p1 <- ggplot(map1_sf) +
  geom_sf(aes(fill = jobs_per_1k), colour = "white", linewidth = 0.1) +
  scale_fill_distiller(palette  = "YlGnBu", direction = 1,
                       na.value = "grey88",
                       name     = "Banen\nper 1.000\ninwoners") +
  labs(title    = "Banen per 1.000 inwoners",
       subtitle = glue("Per gemeente, {YEAR}"),
       caption  = glue("Data: CBS Woonbase + SPOLIS (gesimuleerd)\n",
                        "Gemeentegrenzen: CBS {YEAR} via cartomap.github.io")) +
  map_theme

print(p1)
ggsave("plots/spolis_p1_map_banen_gemeente.png", p1, width = 6.5, height = 9, dpi = 150)
log_msg("p1 saved")


# Plot 2: Employment rate by dwelling type over time ----

YEARS <- 2016:2024
log_msg("Building employment-by-dwelling time series (", min(YEARS), "-", max(YEARS), ")")

ts_list <- list()

for (yr in YEARS) {
  log_msg("  year ", yr)
  sim_reset()
  woonbase_init(year = yr, n = N_PERS, seed = 42L)
  sim_init("spolis", year = yr, seed = 43L)

  # Persons with dwelling type (object-level, no enrichment needed)
  dt_vbo <- as.data.table(read_sav(
    sprintf("WoonbaseKenmerkenWoonruimten%dV1", yr),
    col_select = c(RINOBJECTNUMMER, VBOWoningType1Jan)
  ))

  # Person → dwelling link
  dt_p <- as.data.table(read_sav(
    sprintf("WoonbasePopulatiePersonen%dV1", yr),
    col_select = c(RINPERSOON, RINOBJECTNUMMER1Jan)
  ))

  # SPOLIS: which persons have at least one job?
  dt_sp <- as.data.table(read_sav(
    sprintf("SPOLISBUS%dV1", yr),
    col_select = c(RINPERSOON)
  ))
  has_job <- unique(dt_sp$RINPERSOON)

  # Link dwelling type to persons
  dt_p[dt_vbo, on = c("RINOBJECTNUMMER1Jan" = "RINOBJECTNUMMER"),
       woningtype := i.VBOWoningType1Jan]

  dt_p[, has_job := RINPERSOON %in% has_job]
  dt_p[, wtype_f := as.character(as_factor(woningtype))]

  # Drop unknown / NA
  dt_p <- dt_p[!is.na(wtype_f) & !grepl("nbekend", wtype_f, ignore.case = TRUE)]

  agg <- dt_p[, .(pct_job = mean(has_job) * 100, n = .N), by = wtype_f]
  agg[, year := yr]
  ts_list[[as.character(yr)]] <- agg
}

ts_dt <- rbindlist(ts_list)

KLEUREN <- c("#004699", "#6cbd74", "#bed200", "#ff9100", "#009dec")

p2 <- ggplot(ts_dt, aes(x = year, y = pct_job, colour = wtype_f)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.5) +
  scale_x_continuous(breaks = YEARS) +
  scale_y_continuous(labels = \(x) paste0(x, "%")) +
  scale_colour_manual(values = KLEUREN, name = NULL) +
  labs(title    = "Aandeel personen met een baan, naar woningtype",
       subtitle = glue("% inwoners met \u22651 SPOLIS-baan, {min(YEARS)}\u2013{max(YEARS)}"),
       caption  = "Data: CBS Woonbase + SPOLIS (gesimuleerd)",
       x = NULL, y = "Aandeel met baan (%)") +
  theme(legend.position = "bottom",
        axis.text.x = element_text(angle = 45, hjust = 1))

print(p2)
ggsave("plots/spolis_p2_werkzaam_woningtype.png", p2, width = 9, height = 5.5, dpi = 150)
log_msg("p2 saved")

log_msg("Done \u2014 all figures saved to plots/")
