# analysis/test_spolis.R
#
# Quick validation of the SPOLIS dataset.
# Tests: structure, identifier consistency, key columns.
#
# Run: Rscript analysis/test_spolis.R

suppressPackageStartupMessages({
  library(data.table)
  library(haven)
})
devtools::load_all(".")

YEAR <- 2023L
N    <- 5000L
SEED <- 42L

cat("=== SPOLIS validation ===\n\n")


# 1. Init ----

cat("--- 1. Init ---\n")
sim_reset()
woonbase_init(year = YEAR, n = N, seed = SEED)
sim_init("spolis", year = YEAR, seed = 43L)

cat_sp <- sim_catalog("spolis", year = YEAR)
cat(sprintf("Catalog shows %d file(s)\n\n", nrow(cat_sp)))
stopifnot(nrow(cat_sp) == 1L)


# 2. Read SPOLIS file ----

cat("--- 2. Read SPOLIS ---\n")

dt_sp <- as.data.table(read_sav(sprintf("SPOLISBUS%dV1", YEAR)))
cat(sprintf("  SPOLISBUS: %6d rows x %3d cols\n\n", nrow(dt_sp), ncol(dt_sp)))
stopifnot(nrow(dt_sp) > 0, ncol(dt_sp) > 100)


# 3. Identifier consistency with woonbase ----

cat("--- 3. Identifier consistency with woonbase ---\n")

dt_pers <- as.data.table(read_sav(
  sprintf("WoonbasePopulatiePersonen%dV1", YEAR),
  col_select = c(RINPERSOON)
))

sp_persons <- unique(dt_sp$RINPERSOON)
wb_persons <- dt_pers$RINPERSOON
match_rate <- mean(sp_persons %in% wb_persons) * 100
cat(sprintf("  SPOLIS persons in woonbase: %.1f%%\n", match_rate))
stopifnot(match_rate > 95)
cat("  PASS\n\n")


# 4. Key numeric columns ----

cat("--- 4. Key numeric columns ---\n")

# Wages (random draws, not StatLine-calibrated)
# Some SPOLIS columns may be haven::labelled; coerce to numeric for summaries
sbasisloon <- as.numeric(dt_sp$SBASISLOON)
cat(sprintf("  SBASISLOON: mean=%s, sd=%s\n",
            format(round(mean(sbasisloon, na.rm = TRUE)), big.mark = ","),
            format(round(sd(sbasisloon, na.rm = TRUE)), big.mark = ",")))

sdagenmet <- as.numeric(dt_sp$SDAGENMET)
cat(sprintf("  SDAGENMET: mean=%.0f, sd=%.0f (days with pay)\n",
            mean(sdagenmet, na.rm = TRUE),
            sd(sdagenmet, na.rm = TRUE)))

cat("  (Note: all wage/hours columns use hardcoded distributions, NOT StatLine)\n\n")


# 5. Categorical columns (labelled) ----

cat("--- 5. Categorical columns ---\n")

labelled_cols <- names(Filter(is.labelled, dt_sp))
cat(sprintf("  Haven-labelled columns: %d\n", length(labelled_cols)))

# CAO indicator
if ("SCAO" %in% names(dt_sp)) {
  cao_dist <- dt_sp[, .N, by = SCAO]
  cat(sprintf("  SCAO (CAO indicator): %d distinct values\n", nrow(cao_dist)))
}

# Contract type
if ("SCONTRACTSOORT" %in% names(dt_sp)) {
  contract_dist <- dt_sp[, .N, by = SCONTRACTSOORT]
  contract_dist[, pct := N / sum(N) * 100]
  contract_dist[, label := as.character(as_factor(SCONTRACTSOORT))]
  cat("  Contract type:\n")
  for (i in seq_len(nrow(contract_dist))) {
    cat(sprintf("    %-40s %5.1f%%\n", contract_dist$label[i], contract_dist$pct[i]))
  }
}

cat("\n")


# 6. Fleet size calibration ----

cat("--- 6. Fleet size calibration ---\n")
params <- spolis_cbs_params(year = YEAR)
cat(sprintf("  n_jobs from params: %s\n",
            format(params$n_jobs, big.mark = ",")))
cat(sprintf("  Actual rows: %s (scaled to spine)\n",
            format(nrow(dt_sp), big.mark = ",")))
cat("  (Row count is calibrated to CBS; column distributions are not)\n\n")


cat("=== All SPOLIS tests passed ===\n")
