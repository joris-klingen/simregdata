# Test parquet export + read-back round-trip
library(data.table)
library(haven)
devtools::load_all(".")

cat("=== Test 1: sim_export() — all datasets ===\n")
out_dir <- file.path(tempdir(), "test_export")
sim_export(out_dir, year = 2023, n = 500, seed = 42)

# Check files exist
pq_files <- list.files(out_dir, pattern = "\\.parquet$", recursive = TRUE)
cat(sprintf("\nFound %d parquet files:\n", length(pq_files)))
for (f in pq_files) cat(sprintf("  %s\n", f))
# 12 original + 5 tier1/2 + 1 solar = 18+ files
stopifnot(length(pq_files) >= 18L)

cat("\n=== Test 2: read_sav() from parquet ===\n")
sim_set_data_root(out_dir)
cat(sprintf("Data root: %s\n", sim_get_data_root()))

# Read woonbase sleutel
dt_pq <- read_sav("WoonbaseSleutelbestand2023V1")
cat(sprintf("Woonbase sleutel from parquet: %d rows x %d cols\n",
            nrow(dt_pq), ncol(dt_pq)))
stopifnot(nrow(dt_pq) > 0, ncol(dt_pq) == 16L)

# Read with col_select
dt_sel <- read_sav("WoonbaseSleutelbestand2023V1",
                    col_select = c(RINPERSOON, RINPERSOONS))
cat(sprintf("col_select result: %d rows x %d cols (%s)\n",
            nrow(dt_sel), ncol(dt_sel), paste(names(dt_sel), collapse = ", ")))
stopifnot(ncol(dt_sel) == 2L)

# Read RDW (TAB pattern)
dt_rdw <- read_sav("RDWNPACT2023TABV1")
cat(sprintf("RDW from parquet: %d rows x %d cols\n",
            nrow(dt_rdw), ncol(dt_rdw)))
stopifnot(ncol(dt_rdw) == 13L)

# Read SPOLIS
dt_sp <- read_sav("SPOLISBUS2023V1")
cat(sprintf("SPOLIS from parquet: %d rows x %d cols\n",
            nrow(dt_sp), ncol(dt_sp)))
stopifnot(ncol(dt_sp) == 133L)

cat("\n=== Test 3: Equivalence — single-dataset export ===\n")
sim_set_data_root(NULL)
sim_reset()

# Export woonbase only
out_dir2 <- file.path(tempdir(), "test_export_wb")
sim_export(out_dir2, dataset = "woonbase", year = 2023, n = 500, seed = 42)

# Re-init woonbase with same params, then assemble with same per-file seed
sim_reset()
sim_init("woonbase", year = 2023, n = 500, seed = 42)
file_seed <- bitwXor(42L, sum(utf8ToInt("woonbase/sleutel")))
set.seed(file_seed)
dt_fly <- read_sav("WoonbaseSleutelbestand2023V1")

sim_set_data_root(out_dir2)
dt_pq2 <- read_sav("WoonbaseSleutelbestand2023V1")

eq <- all.equal(dt_fly, dt_pq2)
if (isTRUE(eq)) {
  cat("PASS: on-the-fly == parquet round-trip\n")
} else {
  cat("DIFFERENCES:\n")
  print(eq)
}

cat("\n=== Test 4: skip + n_max ===\n")
dt_skip <- read_sav("WoonbaseSleutelbestand2023V1", skip = 10, n_max = 5)
cat(sprintf("skip=10, n_max=5: %d rows (expect 5)\n", nrow(dt_skip)))
stopifnot(nrow(dt_skip) == 5L)

cat("\n=== Test 5: Haven labels preserved ===\n")
dt_full <- read_sav("WoonbaseSleutelbestand2023V1")
labelled_cols <- names(Filter(haven::is.labelled, dt_full))
cat(sprintf("Haven-labelled columns: %d\n", length(labelled_cols)))
if (length(labelled_cols) > 0) {
  col1 <- labelled_cols[1]
  labs <- attr(dt_full[[col1]], "labels")
  cat(sprintf("  %s has %d labels\n", col1, length(labs)))
  stopifnot(length(labs) > 0)
  cat("PASS: labels preserved through parquet\n")
}

# Cleanup
sim_set_data_root(NULL)
unlink(out_dir, recursive = TRUE)
unlink(out_dir2, recursive = TRUE)
cat("\nAll tests passed.\n")
