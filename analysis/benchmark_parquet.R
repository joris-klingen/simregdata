# Benchmark: on-the-fly generation vs pre-exported parquet
library(data.table)
library(haven)
devtools::load_all(".")

N <- 1e4L
YEAR <- 2023L
SEED <- 42L
out_dir <- file.path(tempdir(), "bench_export")

# Step 1: Export all datasets to parquet ----

cat("=== Step 1: Export 1M-person spine to parquet ===\n\n")
t_export <- system.time({
  sim_export(out_dir, year = YEAR, n = N, seed = SEED)
})
cat(sprintf("\nExport time: %.1f s\n", t_export[["elapsed"]]))

pq_files <- list.files(out_dir, pattern = "\\.parquet$", recursive = TRUE)
sizes <- file.size(file.path(out_dir, pq_files))
cat(sprintf("Total on disk: %.1f MB across %d files\n\n",
            sum(sizes) / 1e6, length(pq_files)))

# Step 2: Benchmark reads ----

cat("=== Step 2: Read speed comparison ===\n\n")

files_to_test <- c(
  "WoonbaseSleutelbestand2023V1",
  "WoonbaseKenmerkenPersonen2023V1",
  "WoonbasePopulatiePersonen2023V1",
  "RDWNPACT2023TABV1",
  "SPOLISBUS2023V1"
)

results <- data.table(
  file = character(),
  method = character(),
  rows = integer(),
  cols = integer(),
  seconds = numeric()
)

for (f in files_to_test) {
  cat(sprintf("--- %s ---\n", f))

  # On-the-fly: reset spine, re-init, then read
  sim_set_data_root(NULL)
  sim_reset()
  t_fly <- system.time({
    sim_init("woonbase", year = YEAR, n = N, seed = SEED)
    # Parse to find which dataset this belongs to
    parsed <- simcbsradata:::.parse_file_registry(f)
    if (parsed$dataset_id != "woonbase") {
      sim_init(parsed$dataset_id, year = YEAR, n = N, seed = SEED)
    }
    dt_fly <- read_sav(f)
  })
  cat(sprintf("  on-the-fly:  %6.2f s  (%s rows x %d cols)\n",
              t_fly[["elapsed"]], format(nrow(dt_fly), big.mark = ","),
              ncol(dt_fly)))

  # Parquet: just read from disk
  sim_set_data_root(out_dir)
  t_pq <- system.time({
    dt_pq <- read_sav(f)
  })
  cat(sprintf("  parquet:     %6.2f s  (%s rows x %d cols)\n",
              t_pq[["elapsed"]], format(nrow(dt_pq), big.mark = ","),
              ncol(dt_pq)))

  speedup <- t_fly[["elapsed"]] / max(t_pq[["elapsed"]], 0.001)
  cat(sprintf("  speedup:     %.0fx\n\n", speedup))

  results <- rbind(results, data.table(
    file = f, method = "on-the-fly",
    rows = nrow(dt_fly), cols = ncol(dt_fly),
    seconds = t_fly[["elapsed"]]
  ))
  results <- rbind(results, data.table(
    file = f, method = "parquet",
    rows = nrow(dt_pq), cols = ncol(dt_pq),
    seconds = t_pq[["elapsed"]]
  ))
}

# Step 3: col_select benchmark ----

cat("=== Step 3: Column selection (2 cols from 50-col file) ===\n\n")

sim_set_data_root(NULL)
sim_reset()
t_fly2 <- system.time({
  sim_init("woonbase", year = YEAR, n = N, seed = SEED)
  dt1 <- read_sav("WoonbasePopulatiePersonen2023V1",
                   col_select = c(RINPERSOON, RINPERSOONS))
})
cat(sprintf("  on-the-fly:  %6.2f s  (%d cols)\n",
            t_fly2[["elapsed"]], ncol(dt1)))

sim_set_data_root(out_dir)
t_pq2 <- system.time({
  dt2 <- read_sav("WoonbasePopulatiePersonen2023V1",
                   col_select = c(RINPERSOON, RINPERSOONS))
})
cat(sprintf("  parquet:     %6.2f s  (%d cols)\n",
            t_pq2[["elapsed"]], ncol(dt2)))
cat(sprintf("  speedup:     %.0fx\n", t_fly2[["elapsed"]] / max(t_pq2[["elapsed"]], 0.001)))

# Summary ----

cat("\n=== Summary ===\n\n")
res_wide <- dcast(results, file ~ method, value.var = "seconds")
res_wide[, speedup := round(`on-the-fly` / pmax(parquet, 0.001), 0)]
print(res_wide)

# Cleanup
sim_set_data_root(NULL)
unlink(out_dir, recursive = TRUE)
cat("\nDone.\n")
