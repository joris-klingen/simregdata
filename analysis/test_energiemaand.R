devtools::load_all(".")
sim_reset()

cat("=== ENERGIEVERBRUIKMAANDTAB tests ===\n\n")

cat("--- 1. Basic generation ---\n")
sim_init("energieverbruik", year = 2023L, n = 200L, seed = 42L)
dt <- read_sav("ENERGIEVERBRUIKMAAND2023TABV1")
cat(sprintf("  Rows: %d, Cols: %d\n", nrow(dt), ncol(dt)))
stopifnot(ncol(dt) == 62L)
stopifnot(nrow(dt) > 0L)
cat("  PASS\n\n")

cat("--- 2. Column names ---\n")
expected <- c("SOORTOBJECTNUMMER", "RINOBJECTNUMMER",
              paste0("GASLEV", sprintf("%02d", 1:12)),
              paste0("ELKLEV", sprintf("%02d", 1:12)),
              paste0("ELKTLV", sprintf("%02d", 1:12)),
              paste0("ELKLEVLAAG", sprintf("%02d", 1:12)),
              paste0("ELKTLVLAAG", sprintf("%02d", 1:12)))
missing <- setdiff(expected, names(dt))
if (length(missing) > 0) {
  cat("  MISSING:", paste(missing, collapse = ", "), "\n")
  stop("Missing columns")
}
cat("  All 62 columns present\n  PASS\n\n")

cat("--- 3. Gas seasonal pattern ---\n")
gas_means <- sapply(1:12, function(m) mean(dt[[paste0("GASLEV", sprintf("%02d", m))]]))
cat(sprintf("  Gas means: %s\n", paste(round(gas_means, 1), collapse = ", ")))
stopifnot(gas_means[1] > gas_means[7])  # Jan > Jul
stopifnot(gas_means[12] > gas_means[6])  # Dec > Jun
cat("  PASS: winter > summer\n\n")

cat("--- 4. Cross-link with annual energieverbruik ---\n")
library(data.table)
dt_annual <- as.data.table(read_sav("ENERGIEVERBRUIK2023TABV1",
                                     col_select = c(RINOBJECTNUMMER, GAS, ELEK)))
dt_month <- as.data.table(dt)
joined <- merge(dt_month, dt_annual, by = "RINOBJECTNUMMER")
cat(sprintf("  Monthly: %d, Annual: %d, Joined: %d (%.0f%%)\n",
            nrow(dt_month), nrow(dt_annual), nrow(joined),
            nrow(joined) / nrow(dt_month) * 100))
stopifnot(nrow(joined) == nrow(dt_month))  # same objects
cat("  PASS: 100%% match\n\n")

cat("--- 5. col_select ---\n")
dt_sel <- read_sav("ENERGIEVERBRUIKMAAND2023TABV1",
                    col_select = c(RINOBJECTNUMMER, GASLEV01, GASLEV07))
stopifnot(ncol(dt_sel) == 3L)
cat("  PASS\n\n")

cat("--- 6. Reproducibility ---\n")
sim_reset()
sim_init("energieverbruik", year = 2023L, n = 200L, seed = 42L)
dt2 <- read_sav("ENERGIEVERBRUIKMAAND2023TABV1")
stopifnot(identical(dt[["GASLEV01"]], dt2[["GASLEV01"]]))
cat("  PASS\n\n")

cat("=== All ENERGIEVERBRUIKMAANDTAB tests passed ===\n")
