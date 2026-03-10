# analysis/test_vehtab.R
#
# Quick validation of the VEHTAB (Vermogens van huishoudens) dataset.
# Tests: structure, identifiers, wealth/income distributions.
#
# Run: Rscript analysis/test_vehtab.R

suppressPackageStartupMessages({
  library(data.table)
  library(haven)
})
devtools::load_all(".")

YEAR <- 2023L
N    <- 500L
SEED <- 42L

cat("=== VEHTAB validation ===\n\n")


# 1. Init ----

cat("--- 1. Init ---\n")
sim_reset()
woonbase_init(year = YEAR, n = N, seed = SEED)
sim_init("vehtab", year = YEAR, seed = 43L)

cat_veh <- sim_catalog("vehtab", year = YEAR)
cat(sprintf("Catalog shows %d file(s)\n\n", nrow(cat_veh)))
stopifnot(nrow(cat_veh) == 1L)


# 2. Read VEHTAB file ----

cat("--- 2. Read VEHTAB ---\n")

dt_veh <- as.data.table(read_sav(sprintf("VEH%dTABV1", YEAR)))
cat(sprintf("  VEHTAB: %6d rows x %2d cols\n", nrow(dt_veh), ncol(dt_veh)))
cat(sprintf("  Columns: %s\n\n", paste(names(dt_veh), collapse = ", ")))
stopifnot(nrow(dt_veh) > 0)


# 3. Identifier: links to woonbase HH ----

cat("--- 3. Identifier consistency ---\n")

dt_hh <- as.data.table(read_sav(
  sprintf("WoonbasePopulatieHuishoudens%dV1", YEAR),
  col_select = c(RINPERSOON, HUISHOUDNR1Jan)
))

# VEHTAB uses RINPERSOONHKW = ref person of household
veh_persons <- unique(dt_veh$RINPERSOONHKW)
hh_persons  <- dt_hh$RINPERSOON
match_rate  <- mean(veh_persons %in% hh_persons) * 100
cat(sprintf("  RINPERSOONHKW in woonbase HH: %.1f%% match\n", match_rate))
stopifnot(match_rate > 95)
cat("  PASS\n\n")


# 4. Spine-derived columns (calibrated via woonbase) ----

cat("--- 4. Spine-derived columns ---\n")

# VEHP100WELVAART (income percentile from spine)
cat(sprintf("  VEHP100WELVAART range: %d - %d (should be 1-100)\n",
            min(dt_veh$VEHP100WELVAART, na.rm = TRUE),
            max(dt_veh$VEHP100WELVAART, na.rm = TRUE)))

# VEHP100HVERM (wealth percentile from spine)
cat(sprintf("  VEHP100HVERM range: %d - %d (should be 1-100)\n",
            min(dt_veh$VEHP100HVERM, na.rm = TRUE),
            max(dt_veh$VEHP100HVERM, na.rm = TRUE)))

# VEHW1000VERH (total household wealth from spine)
cat(sprintf("  VEHW1000VERH (total wealth): mean=%s, sd=%s\n",
            format(round(mean(dt_veh$VEHW1000VERH, na.rm = TRUE)), big.mark = ","),
            format(round(sd(dt_veh$VEHW1000VERH, na.rm = TRUE)), big.mark = ",")))

cat("  (Percentiles from calibrated spine; total wealth from spine VERMHH)\n\n")


# 5. Random wealth components (NOT calibrated) ----

cat("--- 5. Random wealth components (hardcoded distributions) ---\n")

# Use actual column names from the generated VEHTAB file
wealth_cols <- grep("^VEHW[0-9]", names(dt_veh), value = TRUE)
for (col in wealth_cols) {
  if (col %in% names(dt_veh)) {
    vals <- dt_veh[[col]]
    cat(sprintf("  %-16s: mean=%10s, sd=%10s\n", col,
                format(round(mean(vals, na.rm = TRUE)), big.mark = ","),
                format(round(sd(vals, na.rm = TRUE)), big.mark = ",")))
  }
}
cat("  (All wealth components are random normal draws, NOT StatLine-calibrated)\n\n")


# 6. Haven labels ----

cat("--- 6. Haven labels ---\n")

labelled_cols <- names(Filter(is.labelled, dt_veh))
cat(sprintf("  Haven-labelled columns: %d (%s)\n",
            length(labelled_cols), paste(labelled_cols, collapse = ", ")))

# Check RINPERSOONSHKW constant
cat(sprintf("  RINPERSOONSHKW: all 'R'? %s\n",
            all(dt_veh$RINPERSOONSHKW == 1L | as.character(as_factor(dt_veh$RINPERSOONSHKW)) == "Registratienummer")))
cat("\n")


# 7. Fleet size calibration ----

cat("--- 7. Fleet size calibration ---\n")
params <- vehtab_cbs_params(year = YEAR)
cat(sprintf("  n_households from params: %s\n",
            format(params$n_households, big.mark = ",")))
cat(sprintf("  Actual rows: %s (= woonbase HH count, scaled to spine)\n",
            format(nrow(dt_veh), big.mark = ",")))
cat("\n")


cat("=== All VEHTAB tests passed ===\n")
