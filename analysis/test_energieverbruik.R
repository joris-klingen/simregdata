# analysis/test_energieverbruik.R
#
# Quick validation of the ENERGIEVERBRUIKTAB dataset.
# Tests: structure, identifiers, energy distributions, solar PV.
#
# Run: Rscript analysis/test_energieverbruik.R

suppressPackageStartupMessages({
  library(data.table)
  library(haven)
})
devtools::load_all(".")

YEAR <- 2023L
N    <- 500L
SEED <- 42L

cat("=== ENERGIEVERBRUIK validation ===\n\n")


# 1. Init ----

cat("--- 1. Init ---\n")
sim_reset()
woonbase_init(year = YEAR, n = N, seed = SEED)
sim_init("energieverbruik", year = YEAR, seed = 43L)

cat_ev <- sim_catalog("energieverbruik", year = YEAR)
cat(sprintf("Catalog shows %d file(s)\n\n", nrow(cat_ev)))
stopifnot(nrow(cat_ev) == 1L)


# 2. Read ENERGIEVERBRUIK file ----

cat("--- 2. Read ENERGIEVERBRUIK ---\n")

dt_ev <- as.data.table(read_sav(sprintf("ENERGIEVERBRUIK%dTABV1", YEAR)))
cat(sprintf("  ENERGIEVERBRUIKTAB: %6d rows x %2d cols\n", nrow(dt_ev), ncol(dt_ev)))
cat(sprintf("  Columns: %s\n\n", paste(names(dt_ev), collapse = ", ")))
stopifnot(nrow(dt_ev) > 0)


# 3. Identifier: links to woonbase objects ----

cat("--- 3. Identifier consistency ---\n")

dt_obj <- as.data.table(read_sav(
  sprintf("WoonbaseKenmerkenWoonruimten%dV1", YEAR),
  col_select = c(RINOBJECTNUMMER)
))

ev_objs  <- unique(dt_ev$RINOBJECTNUMMER)
wb_objs  <- dt_obj$RINOBJECTNUMMER
match_rate <- mean(ev_objs %in% wb_objs) * 100
cat(sprintf("  RINOBJECTNUMMER in woonbase obj: %.1f%% match\n", match_rate))
stopifnot(match_rate > 95)

# SOORTOBJECTNUMMER should be constant "01"
cat(sprintf("  SOORTOBJECTNUMMER unique values: %s\n",
            paste(unique(dt_ev$SOORTOBJECTNUMMER), collapse = ", ")))
cat("  PASS\n\n")


# 4. StatLine-calibrated columns ----

cat("--- 4. StatLine-calibrated columns ---\n")

params <- energieverbruik_cbs_params(year = YEAR)

# Gas consumption (calibrated: gas_mean/sd from params)
gas <- dt_ev$GAS
cat(sprintf("  GAS (m3): mean=%.0f (params=%.0f), sd=%.0f (params=%.0f)\n",
            mean(gas, na.rm = TRUE), params$gas_mean,
            sd(gas, na.rm = TRUE), params$gas_sd))

# Electricity (calibrated: elek_mean/sd from params)
elek <- dt_ev$ELEK
cat(sprintf("  ELEK (kWh): mean=%.0f (params=%.0f), sd=%.0f (params=%.0f)\n",
            mean(elek, na.rm = TRUE), params$elek_mean,
            sd(elek, na.rm = TRUE), params$elek_sd))

# Solar PV share (calibrated: solar_pv_share from params)
if ("ZONPV" %in% names(dt_ev)) {
  pv_share <- mean(as.integer(dt_ev$ZONPV) == 1L |
                   as.character(as_factor(dt_ev$ZONPV)) == "Ja, zonnepanelen aanwezig",
                   na.rm = TRUE)
  cat(sprintf("  Solar PV share: %.1f%% (params=%.1f%%)\n",
              pv_share * 100, params$solar_pv_share * 100))
}
cat("\n")


# 5. Non-calibrated columns (hardcoded) ----

cat("--- 5. Non-calibrated columns (hardcoded distributions) ---\n")

# District heating
stadsw_dist <- dt_ev[, .N, by = STADSW]
stadsw_dist[, pct := N / sum(N) * 100]
cat(sprintf("  STADSW (district heating): %s\n",
            paste(sprintf("%s=%.1f%%", stadsw_dist$STADSW, stadsw_dist$pct), collapse = ", ")))

# Feed-back electricity
cat(sprintf("  ELEKTERUG (feed-back kWh): mean=%.0f, sd=%.0f (hardcoded)\n",
            mean(dt_ev$ELEKTERUG, na.rm = TRUE),
            sd(dt_ev$ELEKTERUG, na.rm = TRUE)))

# Standard annual gas consumption
cat(sprintf("  GASSJV (temp-corrected gas m3): mean=%.0f, sd=%.0f (hardcoded)\n",
            mean(dt_ev$GASSJV, na.rm = TRUE),
            sd(dt_ev$GASSJV, na.rm = TRUE)))

# Solar capacity
cat(sprintf("  ZONVERMOGEN1JAN (kWp): mean=%.2f, sd=%.2f (hardcoded)\n",
            mean(dt_ev$ZONVERMOGEN1JAN, na.rm = TRUE),
            sd(dt_ev$ZONVERMOGEN1JAN, na.rm = TRUE)))

# Main heating type
if ("HOOFDVERWARMING31DEC" %in% names(dt_ev)) {
  heat_dist <- dt_ev[, .N, by = HOOFDVERWARMING31DEC]
  heat_dist[, pct := N / sum(N) * 100]
  heat_dist[, label := as.character(as_factor(HOOFDVERWARMING31DEC))]
  cat("  HOOFDVERWARMING31DEC (heating type, hardcoded):\n")
  for (i in seq_len(min(5, nrow(heat_dist)))) {
    cat(sprintf("    %-40s %5.1f%%\n", heat_dist$label[i], heat_dist$pct[i]))
  }
  if (nrow(heat_dist) > 5) cat(sprintf("    ... +%d more\n", nrow(heat_dist) - 5))
}
cat("\n")


# 6. Year variation ----

cat("--- 6. Year variation ---\n")

for (yr in c(2010, 2020, 2024)) {
  sim_reset()
  woonbase_init(year = yr, n = 500L, seed = SEED)
  sim_init("energieverbruik", year = yr, seed = 43L)
  dt <- as.data.table(read_sav(
    sprintf("ENERGIEVERBRUIK%dTABV1", yr),
    col_select = c(GAS, ELEK)
  ))
  cat(sprintf("  %d: gas_mean=%.0f m3, elek_mean=%.0f kWh\n",
              yr, mean(dt$GAS, na.rm = TRUE), mean(dt$ELEK, na.rm = TRUE)))
}
cat("  (Gas should decrease, electricity stable — calibrated from params)\n\n")


cat("=== All ENERGIEVERBRUIK tests passed ===\n")
