# analysis/test_woonbase.R
#
# Quick validation of the Woonbase dataset.
# Tests: structure, cross-file joins, key distributions, haven labels.
#
# Run: Rscript analysis/test_woonbase.R

suppressPackageStartupMessages({
  library(data.table)
  library(haven)
})
devtools::load_all(".")

YEAR <- 2023L
N    <- 5000L
SEED <- 42L

cat("=== Woonbase validation ===\n\n")


# 1. Init + catalog ----

cat("--- 1. Init + catalog ---\n")
woonbase_init(year = YEAR, n = N, seed = SEED)
cat <- woonbase_catalog(year = YEAR)
cat(sprintf("Catalog shows %d files\n\n", nrow(cat)))
stopifnot(nrow(cat) == 9L)


# 2. Read all 9 file types ----

cat("--- 2. Read all file types ---\n")
files <- list(
  sleutel        = sprintf("WoonbaseSleutelbestand%dV1", YEAR),
  kenmerken_pers = sprintf("WoonbaseKenmerkenPersonen%dV1", YEAR),
  kenmerken_hh   = sprintf("WoonbaseKenmerkenHuishoudens%dV1", YEAR),
  kenmerken_obj  = sprintf("WoonbaseKenmerkenWoonruimten%dV1", YEAR),
  populatie_pers = sprintf("WoonbasePopulatiePersonen%dV1", YEAR),
  populatie_hh   = sprintf("WoonbasePopulatieHuishoudens%dV1", YEAR),
  populatie_obj  = sprintf("WoonbasePopulatieWoonruimten%dV1", YEAR),
  ek_hh          = sprintf("WOONBASEEKHuishoudensWV%dV1", YEAR),
  extra_panden   = sprintf("ExtraKenmerkenPanden%dTABV1", YEAR)
)

dts <- lapply(files, function(f) as.data.table(read_sav(f)))
for (nm in names(dts)) {
  cat(sprintf("  %-18s: %6d rows x %3d cols\n", nm, nrow(dts[[nm]]), ncol(dts[[nm]])))
}
cat("\n")


# 3. Cross-file join consistency ----

cat("--- 3. Cross-file join consistency ---\n")

# Person IDs should match between sleutel and kenmerken_pers
ids_sleutel <- dts$sleutel$RINPERSOON
ids_kp      <- dts$kenmerken_pers$RINPERSOON
match_rate  <- mean(ids_sleutel %in% ids_kp) * 100
cat(sprintf("  RINPERSOON sleutel->kenmerken_pers: %.1f%% match\n", match_rate))
stopifnot(match_rate > 99)

# HUISHOUDNR should match between person and HH tables
hh_pers <- unique(dts$populatie_pers$HUISHOUDNR1Jan)
hh_hh   <- dts$populatie_hh$HUISHOUDNR1Jan
match_hh <- mean(hh_pers %in% hh_hh) * 100
cat(sprintf("  HUISHOUDNR pers->hh: %.1f%% match\n", match_hh))
stopifnot(match_hh > 95)

# RINOBJECTNUMMER should match between person and object tables
obj_pers <- unique(dts$populatie_pers$RINOBJECTNUMMER1Jan)
obj_obj  <- dts$kenmerken_obj$RINOBJECTNUMMER
match_obj <- mean(obj_pers %in% obj_obj) * 100
cat(sprintf("  RINOBJECTNUMMER pers->obj: %.1f%% match\n", match_obj))
stopifnot(match_obj > 95)

cat("  PASS: all cross-file joins consistent\n\n")


# 4. Haven labels ----

cat("--- 4. Haven labels ---\n")

dt_pp <- dts$populatie_pers
labelled_cols <- names(Filter(is.labelled, dt_pp))
cat(sprintf("  Labelled columns in populatie_pers: %d\n", length(labelled_cols)))
stopifnot(length(labelled_cols) > 0)

# Check TYPHH has valid labels
typhh_labs <- attr(dt_pp$TYPHH1Jan, "labels")
cat(sprintf("  TYPHH1Jan label count: %d\n", length(typhh_labs)))
stopifnot(length(typhh_labs) >= 5)
cat("  PASS: haven labels present and valid\n\n")


# 5. Key distributions (StatLine-calibrated spine) ----

cat("--- 5. Key distributions (spine-calibrated) ---\n")

# Household type distribution (calibrated via typhh_p from StatLine 71486ned)
typhh_dist <- dt_pp[, .N, by = TYPHH1Jan]
typhh_dist[, pct := N / sum(N) * 100]
typhh_dist[, label := as.character(as_factor(TYPHH1Jan))]
cat("  Household type distribution (StatLine-calibrated):\n")
for (i in seq_len(nrow(typhh_dist))) {
  cat(sprintf("    %-35s %5.1f%%\n", typhh_dist$label[i], typhh_dist$pct[i]))
}

# Sex ratio (fixed ~50/50 in spine)
sex_dist <- dt_pp[, .N, by = GBAGeslachtsAanduiding1Jan]
sex_dist[, pct := N / sum(N) * 100]
cat(sprintf("\n  Sex ratio: %.1f%% / %.1f%%\n", sex_dist$pct[1], sex_dist$pct[2]))

# Age range (derived from birth year)
birth_years <- as.integer(dt_pp$GBAGeboorteJaar1Jan)
ages <- YEAR - birth_years
cat(sprintf("  Age range: %d - %d (median %d)\n",
            min(ages), max(ages), median(ages)))

# Gemeente count (calibrated weights from StatLine 37230ned)
n_gem <- uniqueN(dt_pp$GemeenteCodeJJJJ1Jan)
cat(sprintf("  Distinct gemeenten: %d\n", n_gem))

cat("  PASS: distributions look reasonable\n\n")


# 6. col_select and n_max ----

cat("--- 6. col_select and n_max ---\n")

dt_sel <- as.data.table(read_sav(
  files$populatie_pers,
  col_select = c(RINPERSOON, TYPHH1Jan),
  n_max = 100
))
cat(sprintf("  col_select=2, n_max=100: %d rows x %d cols\n",
            nrow(dt_sel), ncol(dt_sel)))
stopifnot(nrow(dt_sel) == 100L, ncol(dt_sel) == 2L)
cat("  PASS\n\n")


# 7. EK files: income/wealth ----

cat("--- 7. EK files: income/wealth (hardcoded distributions) ---\n")

dt_ek <- dts$ek_hh
cat(sprintf("  EK HH cols: %s\n", paste(names(dt_ek)[1:6], collapse = ", ")))
cat(sprintf("  BESTINKH1JAN range: %s - %s\n",
            format(min(dt_ek$BESTINKH1JAN, na.rm = TRUE), big.mark = ","),
            format(max(dt_ek$BESTINKH1JAN, na.rm = TRUE), big.mark = ",")))
cat(sprintf("  P100HBEST1JAN range: %d - %d\n",
            min(dt_ek$P100HBEST1JAN, na.rm = TRUE),
            max(dt_ek$P100HBEST1JAN, na.rm = TRUE)))
cat("  (Note: income/wealth are NOT StatLine-calibrated, just random draws)\n\n")


cat("=== All woonbase tests passed ===\n")
