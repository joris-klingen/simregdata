# Quick test of all new datasets
suppressPackageStartupMessages({
  library(data.table)
  library(haven)
})
devtools::load_all(".")

cat("=== Testing new datasets ===\n\n")

sim_reset()

# Test 1: HOOGSTEOPLTAB ----
cat("--- HOOGSTEOPLTAB ---\n")
sim_init("hoogsteopltab", year = 2023L, n = 100L, seed = 42L)
dt <- as.data.table(read_sav("HOOGSTEOPL2023TABV1"))
cat(sprintf("  Rows: %d, Cols: %d\n", nrow(dt), ncol(dt)))
cat(sprintf("  Columns: %s\n", paste(names(dt), collapse = ", ")))
stopifnot(nrow(dt) > 0)
stopifnot("RINPERSOON" %in% names(dt))
stopifnot("OPLNIVSOI2021AGG4HBmetNIRWO" %in% names(dt))
cat("  PASS\n\n")

# Test 2: INPATAB ----
cat("--- INPATAB ---\n")
sim_init("inpatab", year = 2023L, n = 100L, seed = 42L)
dt <- as.data.table(read_sav("INPA2023TABV1"))
cat(sprintf("  Rows: %d, Cols: %d\n", nrow(dt), ncol(dt)))
cat(sprintf("  Columns: %s\n", paste(names(dt), collapse = ", ")))
stopifnot(nrow(dt) > 0)
stopifnot("INPPERSINK" %in% names(dt))
cat("  PASS\n\n")

# Test 3: SECMBUS ----
cat("--- SECMBUS ---\n")
sim_init("secmbus", year = 2023L, n = 100L, seed = 42L)
dt <- as.data.table(read_sav("SECMBUS2023V1"))
cat(sprintf("  Rows: %d, Cols: %d\n", nrow(dt), ncol(dt)))
cat(sprintf("  Columns: %s\n", paste(names(dt), collapse = ", ")))
stopifnot(nrow(dt) >= 100)  # should be >= n due to multi-period expansion
stopifnot("SECM" %in% names(dt))
stopifnot("AANVSECM" %in% names(dt))
cat("  PASS\n\n")

# Test 4: INHATAB ----
cat("--- INHATAB ---\n")
sim_init("inhatab", year = 2023L, n = 100L, seed = 42L)
dt <- as.data.table(read_sav("INHA2023TABV1"))
cat(sprintf("  Rows: %d, Cols: %d\n", nrow(dt), ncol(dt)))
cat(sprintf("  Columns: %s\n", paste(names(dt), collapse = ", ")))
stopifnot(nrow(dt) > 0)
stopifnot("INHBESTINKH" %in% names(dt))
cat("  PASS\n\n")

# Test 5: VEHTAB (vermogen) ----
cat("--- VEHTAB_VERMOGEN ---\n")
sim_init("vehtab_vermogen", year = 2023L, n = 100L, seed = 42L)
dt <- as.data.table(read_sav("VEH2023TABV1"))
cat(sprintf("  Rows: %d, Cols: %d\n", nrow(dt), ncol(dt)))
cat(sprintf("  Columns: %s\n", paste(names(dt), collapse = ", ")))
stopifnot(nrow(dt) > 0)
stopifnot("VEHW1000VERH" %in% names(dt))
cat("  PASS\n\n")

# Test 6: BETAB ----
cat("--- BETAB ---\n")
sim_init("betab", year = 2023L, n = 100L, seed = 42L)
dt <- as.data.table(read_sav("BE2023TABV1"))
cat(sprintf("  Rows: %d, Cols: %d\n", nrow(dt), ncol(dt)))
cat(sprintf("  Columns: %s\n", paste(names(dt), collapse = ", ")))
stopifnot(nrow(dt) > 0)
stopifnot("BEID" %in% names(dt))
stopifnot("SBI2008VJJJJ" %in% names(dt))
cat("  PASS\n\n")

# Test 7: sim_catalog shows all datasets ----
cat("--- sim_catalog ---\n")
sim_catalog()

cat("\n=== All tests passed ===\n")
