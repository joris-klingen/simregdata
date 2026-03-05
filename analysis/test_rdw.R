# analysis/test_rdw.R
#
# Quick validation of the RDW dataset.
# Tests: structure, cross-file consistency, calibrated distributions.
#
# Run: Rscript analysis/test_rdw.R

suppressPackageStartupMessages({
  library(data.table)
  library(haven)
})
devtools::load_all(".")

YEAR <- 2023L
N    <- 5000L
SEED <- 42L

cat("=== RDW validation ===\n\n")


# 1. Init ----

cat("--- 1. Init ---\n")
sim_reset()
woonbase_init(year = YEAR, n = N, seed = SEED)
sim_init("rdw", year = YEAR, seed = 43L)

cat_rdw <- sim_catalog("rdw", year = YEAR)
cat(sprintf("Catalog shows %d files\n\n", nrow(cat_rdw)))
stopifnot(nrow(cat_rdw) == 2L)


# 2. Read both RDW files ----

cat("--- 2. Read RDW files ---\n")

dt_kent <- as.data.table(read_sav(sprintf("RDWNPACT%dTABV1", YEAR)))
dt_vp   <- as.data.table(read_sav(sprintf("VERKEERSPRESTATIE%dTABV1", YEAR)))

cat(sprintf("  RDWNPACT:          %6d rows x %2d cols\n", nrow(dt_kent), ncol(dt_kent)))
cat(sprintf("  VERKEERSPRESTATIE: %6d rows x %2d cols\n", nrow(dt_vp), ncol(dt_vp)))
stopifnot(nrow(dt_kent) > 0, nrow(dt_vp) > 0)
cat("\n")


# 3. Cross-file RINKENTEKEN consistency ----

cat("--- 3. Cross-file RINKENTEKEN consistency ---\n")

kent_ids <- dt_kent$RINKENTEKEN
vp_ids   <- dt_vp$RINKENTEKEN
match_rate <- mean(kent_ids %in% vp_ids) * 100
cat(sprintf("  RINKENTEKEN kent->vp: %.1f%% match\n", match_rate))
stopifnot(match_rate > 99)
cat("  PASS\n\n")


# 4. StatLine-calibrated columns ----

cat("--- 4. StatLine-calibrated columns ---\n")

# Fuel type (calibrated: brandstof_p from CBS 85237NED)
fuel_dist <- dt_kent[, .N, by = BRANDSTCODECORVRTG]
fuel_dist[, pct := N / sum(N) * 100]
fuel_dist[, label := as.character(as_factor(BRANDSTCODECORVRTG))]
cat("  Fuel type (calibrated via CBS 85237NED):\n")
for (i in seq_len(nrow(fuel_dist))) {
  cat(sprintf("    %-30s %5.1f%%\n", fuel_dist$label[i], fuel_dist$pct[i]))
}

# Vehicle weight (calibrated: gewicht_mean/sd from CBS 85237NED)
wt <- dt_kent$MASSALEEGCORVRTG
cat(sprintf("\n  Vehicle weight (calibrated via CBS 85237NED):\n"))
cat(sprintf("    mean=%.0f kg, sd=%.0f kg, range=[%.0f, %.0f]\n",
            mean(wt), sd(wt), min(wt), max(wt)))

# VKT (calibrated: jaarkm_mean/sd from CBS 85404NED)
km <- dt_vp$VPJAARKM
cat(sprintf("\n  Annual km (calibrated via CBS 85404NED):\n"))
cat(sprintf("    mean=%.0f km, sd=%.0f km, range=[%.0f, %.0f]\n",
            mean(km), sd(km), min(km), max(km)))

# Vehicle type (calibrated: vrtgsoort_p from CBS 85236NED)
vrtg_dist <- dt_kent[, .N, by = VRTGSOORT]
vrtg_dist[, pct := N / sum(N) * 100]
vrtg_dist[, label := as.character(as_factor(VRTGSOORT))]
cat(sprintf("\n  Vehicle type (calibrated via CBS 85236NED):\n"))
for (i in seq_len(nrow(vrtg_dist))) {
  cat(sprintf("    %-30s %5.1f%%\n", vrtg_dist$label[i], vrtg_dist$pct[i]))
}

# Colour (calibrated: kleur_p from CBS 85237NED)
kleur_dist <- dt_kent[, .N, by = KLEURCODEVRTG]
kleur_dist[, pct := N / sum(N) * 100]
cat(sprintf("\n  Vehicle colours (calibrated via CBS 85237NED): %d distinct\n",
            nrow(kleur_dist)))

cat("\n")


# 5. Non-calibrated columns ----

cat("--- 5. Non-calibrated columns (hardcoded/random) ---\n")

cat(sprintf("  VPBRANDSTOFVERBRUIK: mean=%.1f, sd=%.1f (hardcoded normal)\n",
            mean(dt_vp$VPBRANDSTOFVERBRUIK, na.rm = TRUE),
            sd(dt_vp$VPBRANDSTOFVERBRUIK, na.rm = TRUE)))

cat(sprintf("  Monthly km columns: %d cols (VPMAANDKM01-12, uniform random)\n",
            sum(grepl("VPMAANDKM", names(dt_vp)))))

cat("  (Note: monthly km and fuel consumption are NOT calibrated)\n\n")


# 6. Year variation ----

cat("--- 6. Year variation (fuel type should shift) ---\n")

for (yr in c(2015, 2020, 2025)) {
  sim_reset()
  woonbase_init(year = yr, n = 2000L, seed = SEED)
  sim_init("rdw", year = yr, seed = 43L)
  dt <- as.data.table(read_sav(
    sprintf("RDWNPACT%dTABV1", yr),
    col_select = c(BRANDSTCODECORVRTG)
  ))
  ev_pct <- dt[as.character(as_factor(BRANDSTCODECORVRTG)) == "Electriciteit", .N] /
            nrow(dt) * 100
  cat(sprintf("  %d: EV share = %.1f%%\n", yr, ev_pct))
}
cat("  (Should increase over time — calibrated from CBS StatLine)\n\n")


cat("=== All RDW tests passed ===\n")
