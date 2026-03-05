# analysis/test_gba.R
#
# Validation of the GBA (population register) dataset.
# Tests: structure, identifiers, cross-file consistency, labels.
#
# Run: Rscript analysis/test_gba.R

suppressPackageStartupMessages({
  library(data.table)
  library(haven)
})
devtools::load_all(".")

YEAR <- 2023L
N    <- 5000L
SEED <- 42L

cat("=== GBA validation ===\n\n")


# 1. Init ----

cat("--- 1. Init ---\n")
sim_reset()
sim_init("gba", year = YEAR, n = N, seed = SEED)

cat_gba <- sim_catalog("gba", year = YEAR)
cat(sprintf("Catalog shows 3 file(s)\n\n"))


# 2. Read all GBA files ----

cat("--- 2. Read GBA files ---\n")

dt_pers <- as.data.table(read_sav(sprintf("GBAPERSOONKTAB%dTABV1", YEAR)))
cat(sprintf("  GBAPERSOONKTAB:    %6d rows x %2d cols\n", nrow(dt_pers), ncol(dt_pers)))

dt_adres <- as.data.table(read_sav(sprintf("GBAADRESOBJECTBUS%dV1", YEAR)))
cat(sprintf("  GBAADRESOBJECTBUS: %6d rows x %2d cols\n", nrow(dt_adres), ncol(dt_adres)))

dt_hh <- as.data.table(read_sav(sprintf("GBAHUISHOUDENSBUS%dV1", YEAR)))
cat(sprintf("  GBAHUISHOUDENSBUS: %6d rows x %2d cols\n\n", nrow(dt_hh), ncol(dt_hh)))

stopifnot(nrow(dt_pers) > 0, nrow(dt_adres) > 0, nrow(dt_hh) > 0)


# 3. Cross-file join: RINPERSOON ----

cat("--- 3. Cross-file RINPERSOON consistency ---\n")
match_adres <- mean(dt_adres$RINPERSOON %in% dt_pers$RINPERSOON) * 100
match_hh    <- mean(dt_hh$RINPERSOON %in% dt_pers$RINPERSOON) * 100
cat(sprintf("  ADRESOBJECT -> PERSOONKTAB: %.1f%% match\n", match_adres))
cat(sprintf("  HUISHOUDENS -> PERSOONKTAB: %.1f%% match\n", match_hh))
stopifnot(match_adres > 99, match_hh > 99)
cat("  PASS\n\n")


# 4. Key columns in PERSOONKTAB ----

cat("--- 4. Key PERSOONKTAB columns ---\n")
cat(sprintf("  Columns: %s\n", paste(names(dt_pers), collapse = ", ")))
stopifnot(ncol(dt_pers) == 6)

# Birth year range
cat(sprintf("  GBAGEBOORTEJAAR range: %d - %d\n",
            min(as.integer(dt_pers$GBAGEBOORTEJAAR)),
            max(as.integer(dt_pers$GBAGEBOORTEJAAR))))

# Sex
sex <- dt_pers[, .N, by = GBAGESLACHT]
sex[, pct := N / sum(N) * 100]
cat(sprintf("  Sex ratio: %s\n",
            paste(sprintf("%s=%.1f%%", as.character(as_factor(sex$GBAGESLACHT)), sex$pct),
                  collapse = ", ")))

# Birth month (should be uniform 1-12)
cat(sprintf("  GBAGEBOORTEMAAND range: %s - %s\n",
            min(as.integer(dt_pers$GBAGEBOORTEMAAND)),
            max(as.integer(dt_pers$GBAGEBOORTEMAAND))))

# GBAGEBOORTEDAG (always "01")
cat(sprintf("  GBAGEBOORTEDAG unique values: %s\n",
            paste(unique(dt_pers$GBAGEBOORTEDAG), collapse = ", ")))
stopifnot(all(dt_pers$GBAGEBOORTEDAG == "01"))
cat("\n")


# 5. ADRESOBJECTBUS: address links ----

cat("--- 5. Address links ---\n")
cat(sprintf("  Columns: %s\n", paste(names(dt_adres), collapse = ", ")))
cat(sprintf("  Distinct gemeenten: %d\n",
            length(unique(dt_adres$GBAGEMEENTEVANINSCHRIJVING))))
cat(sprintf("  Mean address occupants: %.1f\n",
            mean(as.numeric(dt_adres$GBAAANTALINGESCHREVENENOPNUMMERAANDUIDING), na.rm = TRUE)))
cat("\n")


# 6. HUISHOUDENSBUS: household composition ----

cat("--- 6. Household composition ---\n")
cat(sprintf("  Columns: %s\n", paste(names(dt_hh), collapse = ", ")))
hh_type <- dt_hh[, .N, by = TYPHH]
hh_type[, pct := N / sum(N) * 100]
hh_type[, label := as.character(as_factor(TYPHH))]
cat("  Household type:\n")
for (i in seq_len(nrow(hh_type))) {
  cat(sprintf("    %-40s %5.1f%%\n", hh_type$label[i], hh_type$pct[i]))
}
cat("\n")


# 7. Haven labels ----

cat("--- 7. Haven labels ---\n")
labelled_pers  <- names(Filter(is.labelled, dt_pers))
labelled_adres <- names(Filter(is.labelled, dt_adres))
labelled_hh    <- names(Filter(is.labelled, dt_hh))
cat(sprintf("  PERSOONKTAB labelled:    %d (%s)\n", length(labelled_pers), paste(labelled_pers, collapse = ", ")))
cat(sprintf("  ADRESOBJECTBUS labelled: %d (%s)\n", length(labelled_adres), paste(labelled_adres, collapse = ", ")))
cat(sprintf("  HUISHOUDENSBUS labelled: %d (%s)\n", length(labelled_hh), paste(labelled_hh, collapse = ", ")))
cat("\n")


# 8. GBA + Woonbase cross-link ----

cat("--- 8. GBA + Woonbase cross-link ---\n")
dt_wb <- as.data.table(read_sav(
  sprintf("WoonbasePopulatiePersonen%dV1", YEAR),
  col_select = c(RINPERSOON)
))
gba_in_wb <- mean(dt_pers$RINPERSOON %in% dt_wb$RINPERSOON) * 100
cat(sprintf("  GBA persons in woonbase: %.1f%% (should be 100%%)\n", gba_in_wb))
stopifnot(gba_in_wb > 99)
cat("  PASS\n\n")


cat("=== All GBA tests passed ===\n")
