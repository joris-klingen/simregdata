# analysis/benchmark_loading.R
#
# Profile different dataset loading scenarios to identify speed bottlenecks.
# Covers: spine build, enrichment, assembly, col_select, multi-dataset init.
# Run: Rscript analysis/benchmark_loading.R

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(haven)
})
devtools::load_all(".")

fmt <- function(x) format(x, big.mark = ",")
log_msg <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), paste0(...)))

YEAR <- 2023L
SEED <- 42L
SIZES <- c(1e4, 1e5, 5e5)

results <- data.table(
  scenario = character(),
  n = integer(),
  seconds = numeric(),
  detail = character()
)

add <- function(scenario, n, seconds, detail = "") {
  results <<- rbind(results, data.table(
    scenario = scenario, n = as.integer(n),
    seconds = round(seconds, 3), detail = detail
  ))
}


# Spine build at different sizes ----

log_msg("Benchmarking spine build...")
for (sz in SIZES) {
  sim_reset()
  gc(verbose = FALSE)
  t <- system.time(sim_init("woonbase", year = YEAR, n = sz, seed = SEED))
  add("spine_build", sz, t[["elapsed"]])
  log_msg(sprintf("  n=%s: %.2f s", fmt(sz), t[["elapsed"]]))
}


# Enrichment cost ----

log_msg("Benchmarking lazy enrichment...")
N_ENRICH <- 1e5L
sim_reset()
sim_init("woonbase", year = YEAR, n = N_ENRICH, seed = SEED)

# First read triggers enrichment; second read uses cache
files_with_enrichment <- c(
  "WoonbaseKenmerkenPersonen2023V1",
  "WoonbasePopulatiePersonen2023V1",
  "WOONBASEEKHuishoudensWV2023V1"
)

for (f in files_with_enrichment) {
  # Cold: forces enrichment
  sim_reset()
  sim_init("woonbase", year = YEAR, n = N_ENRICH, seed = SEED)
  gc(verbose = FALSE)
  t_cold <- system.time(read_sav(f))
  add("enrich_cold", N_ENRICH, t_cold[["elapsed"]], f)

  # Warm: enrichment already cached
  gc(verbose = FALSE)
  t_warm <- system.time(read_sav(f))
  add("enrich_warm", N_ENRICH, t_warm[["elapsed"]], f)

  log_msg(sprintf("  %s: cold=%.3f s, warm=%.3f s",
                  basename(f), t_cold[["elapsed"]], t_warm[["elapsed"]]))
}


# Assembly: full file vs col_select ----

log_msg("Benchmarking col_select impact...")
N_COL <- 1e5L
sim_reset()
sim_init("woonbase", year = YEAR, n = N_COL, seed = SEED)

# Warm up enrichment
invisible(read_sav("WoonbasePopulatiePersonen2023V1",
                   col_select = c(RINPERSOON)))

# Full file (all columns)
gc(verbose = FALSE)
t_full <- system.time(dt_full <- read_sav("WoonbasePopulatiePersonen2023V1"))
add("assembly_full", N_COL, t_full[["elapsed"]],
    sprintf("%d cols", ncol(dt_full)))

# 2 columns
gc(verbose = FALSE)
t_2col <- system.time(
  dt_2 <- read_sav("WoonbasePopulatiePersonen2023V1",
                    col_select = c(RINPERSOON, GBAGeboorteJaar1Jan))
)
add("assembly_2col", N_COL, t_2col[["elapsed"]], "2 cols")

# 5 columns
gc(verbose = FALSE)
t_5col <- system.time(
  dt_5 <- read_sav("WoonbasePopulatiePersonen2023V1",
                    col_select = c(RINPERSOON, GBAGeboorteJaar1Jan,
                                   GBAGeslachtsAanduiding1Jan, TYPHH1Jan,
                                   HUISHOUDNR1Jan))
)
add("assembly_5col", N_COL, t_5col[["elapsed"]], "5 cols")

log_msg(sprintf("  full=%d cols: %.3f s | 5 cols: %.3f s | 2 cols: %.3f s",
                ncol(dt_full), t_full[["elapsed"]],
                t_5col[["elapsed"]], t_2col[["elapsed"]]))


# Per-file assembly times (all woonbase files) ----

log_msg("Benchmarking all woonbase file types...")
N_FILE <- 1e5L
sim_reset()
sim_init("woonbase", year = YEAR, n = N_FILE, seed = SEED)
# Pre-warm enrichment
invisible(read_sav("WoonbasePopulatiePersonen2023V1",
                   col_select = c(RINPERSOON)))

wb_files <- c(
  "WoonbaseSleutelbestand2023V1",
  "WoonbaseKenmerkenPersonen2023V1",
  "WoonbaseKenmerkenHuishoudens2023V1",
  "WoonbaseKenmerkenWoonruimten2023V1",
  "WoonbasePopulatiePersonen2023V1",
  "WoonbasePopulatieHuishoudens2023V1",
  "WoonbasePopulatieWoonruimten2023V1",
  "WOONBASEEKHuishoudensWV2023V1",
  "ExtraKenmerkenPanden2023V1"
)

for (f in wb_files) {
  gc(verbose = FALSE)
  t <- system.time(dt <- read_sav(f))
  add("woonbase_file", N_FILE, t[["elapsed"]],
      sprintf("%s (%s x %d)", basename(f), fmt(nrow(dt)), ncol(dt)))
  log_msg(sprintf("  %s: %.3f s (%s x %d)",
                  basename(f), t[["elapsed"]], fmt(nrow(dt)), ncol(dt)))
}


# Non-woonbase datasets: init + read ----

log_msg("Benchmarking non-woonbase datasets...")
other_datasets <- list(
  rdw    = "RDWNPACT2023TABV1",
  spolis = "SPOLISBUS2023V1",
  vehtab = "VEH2023TABV1",
  energieverbruik = "ENERGIEVERBRUIK2023TABV1",
  gba    = "GBAPERSOONTAB2023TABV1"
)

N_OTHER <- 1e5L
# Ensure shared spine exists
sim_reset()
sim_init("woonbase", year = YEAR, n = N_OTHER, seed = SEED)

for (ds in names(other_datasets)) {
  f <- other_datasets[[ds]]

  # Init cost (spine already built, measures dataset-specific init only)
  gc(verbose = FALSE)
  t_init <- system.time(sim_init(ds, year = YEAR, n = N_OTHER, seed = SEED))
  add("dataset_init", N_OTHER, t_init[["elapsed"]], ds)

  # Read cost
  gc(verbose = FALSE)
  t_read <- system.time(dt <- read_sav(f))
  add("dataset_read", N_OTHER, t_read[["elapsed"]],
      sprintf("%s (%s x %d)", ds, fmt(nrow(dt)), ncol(dt)))

  log_msg(sprintf("  %s: init=%.3f s, read=%.3f s (%s x %d)",
                  ds, t_init[["elapsed"]], t_read[["elapsed"]],
                  fmt(nrow(dt)), ncol(dt)))
}


# Multi-dataset init from scratch ----

log_msg("Benchmarking full multi-dataset init from scratch...")
N_MULTI <- 1e5L
all_datasets <- c("woonbase", "rdw", "spolis", "vehtab", "energieverbruik", "gba")

sim_reset()
gc(verbose = FALSE)
t_multi <- system.time({
  for (ds in all_datasets) {
    sim_init(ds, year = YEAR, n = N_MULTI, seed = SEED)
  }
})
add("multi_init_all", N_MULTI, t_multi[["elapsed"]],
    paste(all_datasets, collapse = "+"))
log_msg(sprintf("  All 6 datasets: %.2f s", t_multi[["elapsed"]]))


# Repeated reads (test caching) ----

log_msg("Benchmarking repeated reads (cache effectiveness)...")
N_REPEAT <- 1e5L
sim_reset()
sim_init("woonbase", year = YEAR, n = N_REPEAT, seed = SEED)

timings <- numeric(5)
for (i in seq_along(timings)) {
  gc(verbose = FALSE)
  t <- system.time(read_sav("WoonbasePopulatiePersonen2023V1",
                            col_select = c(RINPERSOON, GBAGeboorteJaar1Jan,
                                           GBAGeslachtsAanduiding1Jan)))
  timings[i] <- t[["elapsed"]]
}
add("repeated_read_1st", N_REPEAT, timings[1], "first call")
add("repeated_read_avg", N_REPEAT, mean(timings[-1]), "mean of calls 2-5")
log_msg(sprintf("  1st: %.3f s, avg(2-5): %.3f s", timings[1], mean(timings[-1])))


# Scaling: read time vs n ----

log_msg("Benchmarking read time scaling with n...")
for (sz in SIZES) {
  sim_reset()
  sim_init("woonbase", year = YEAR, n = sz, seed = SEED)
  gc(verbose = FALSE)
  t <- system.time(read_sav("WoonbasePopulatiePersonen2023V1",
                            col_select = c(RINPERSOON, GBAGeboorteJaar1Jan,
                                           TYPHH1Jan)))
  add("scaling_read_3col", sz, t[["elapsed"]])
  log_msg(sprintf("  n=%s: %.3f s", fmt(sz), t[["elapsed"]]))
}


# Summary plot ----

theme_set(theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey45", size = 9)))

dt_wb <- results[scenario == "woonbase_file"]
dt_wb[, file := sub(" \\(.*", "", detail)]
dt_wb[, file := factor(file, levels = rev(file))]

p <- ggplot(dt_wb, aes(file, seconds)) +
  geom_col(fill = "#2166AC", width = 0.7) +
  geom_text(aes(label = sprintf("%.3fs", seconds)), hjust = -0.1, size = 3) +
  coord_flip() +
  labs(title = "Woonbase file assembly times",
       subtitle = sprintf("All 9 file types, warm cache, n=%s", fmt(N_FILE)),
       x = NULL, y = "Seconds") +
  expand_limits(x = 0)

print(p)


# Raw results table ----

cat("\n\n")
cat("========================================\n")
cat("  RAW BENCHMARK RESULTS\n")
cat("========================================\n\n")
print(results, row.names = FALSE)
log_msg("Done.")
