# analysis/test_cross_datasets.R
#
# Cross-dataset combination tests.
# Verifies that all datasets can be joined across shared keys.
#
# Run: Rscript analysis/test_cross_datasets.R

suppressPackageStartupMessages({
  library(data.table)
  library(haven)
})
devtools::load_all(".")

YEAR <- 2023L
N    <- 500L
SEED <- 42L

cat("=== Cross-dataset combination tests ===\n\n")


# 1. Init all datasets ----

cat("--- 1. Init all datasets ---\n")
sim_reset()
woonbase_init(year = YEAR, n = N, seed = SEED)
sim_init("rdw",              year = YEAR, seed = 43L)
sim_init("spolis",           year = YEAR, seed = 44L)
sim_init("vehtab",           year = YEAR, seed = 45L)
sim_init("energieverbruik",  year = YEAR, seed = 46L)
sim_init("hoogsteopltab",    year = YEAR, seed = 47L)
sim_init("inpatab",          year = YEAR, seed = 48L)
sim_init("secmbus",          year = YEAR, seed = 49L)
sim_init("inhatab",          year = YEAR, seed = 50L)
sim_init("betab",            year = YEAR, seed = 51L)
sim_init("burennetwerktab",  year = YEAR, seed = 52L)
sim_init("colleganetwerktab", year = YEAR, seed = 53L)
sim_init("familienetwerktab", year = YEAR, seed = 54L)
cat("  All 13 datasets initialised\n\n")


# 2. Load key tables ----

cat("--- 2. Load key tables ---\n")

cat("  Reading woonbase persons...\n")
dt_pers <- as.data.table(read_sav(
  sprintf("WoonbasePopulatiePersonen%dV1", YEAR),
  col_select = c(RINPERSOON, HUISHOUDNR1Jan, RINOBJECTNUMMER1Jan,
                 TYPHH1Jan, VBOWoningType1Jan, GemeenteCodeJJJJ1Jan)
))

cat("  Reading RDW kentekens...\n")
dt_kent <- as.data.table(read_sav(
  sprintf("RDWNPACT%dTABV1", YEAR),
  col_select = c(RINPERSOON, RINKENTEKEN, BRANDSTCODECORVRTG)
))

cat("  Reading RDW verkeersprestatie...\n")
dt_vp <- as.data.table(read_sav(
  sprintf("VERKEERSPRESTATIE%dTABV1", YEAR),
  col_select = c(RINKENTEKEN, VPJAARKM)
))

cat("  Reading SPOLIS...\n")
dt_sp <- as.data.table(read_sav(sprintf("SPOLISBUS%dV1", YEAR)))
dt_sp <- dt_sp[, .(RINPERSOON, SVLOON = as.numeric(SBASISLOON))]

cat("  Reading VEHTAB...\n")
dt_veh <- as.data.table(read_sav(
  sprintf("VEH%dTABV1", YEAR),
  col_select = c(RINPERSOONHKW, VEHW1000VERH, VEHP100WELVAART)
))

cat("  Reading ENERGIEVERBRUIK...\n")
dt_ev <- as.data.table(read_sav(
  sprintf("ENERGIEVERBRUIK%dTABV1", YEAR),
  col_select = c(RINOBJECTNUMMER, GAS, ELEK)
))

cat(sprintf("  Persons: %d, Vehicles: %d, Jobs: %d, HH-wealth: %d, Dwellings-energy: %d\n\n",
            nrow(dt_pers), nrow(dt_kent), nrow(dt_sp), nrow(dt_veh), nrow(dt_ev)))


# 3. Woonbase + RDW: cars per person ----

cat("--- 3. Woonbase + RDW ---\n")

cars_pp <- dt_kent[, .(n_cars = .N), by = RINPERSOON]
dt_pers[cars_pp, on = "RINPERSOON", n_cars := i.n_cars]
dt_pers[is.na(n_cars), n_cars := 0L]

car_rate <- mean(dt_pers$n_cars > 0) * 100
cat(sprintf("  Car ownership rate: %.1f%% of persons own >= 1 car\n", car_rate))

# Add VKT via kenteken
dt_kent[dt_vp, on = "RINKENTEKEN", vpjaarkm := i.VPJAARKM]
vkt_pp <- dt_kent[, .(total_km = sum(vpjaarkm, na.rm = TRUE)), by = RINPERSOON]
dt_pers[vkt_pp, on = "RINPERSOON", total_km := i.total_km]
dt_pers[is.na(total_km), total_km := 0]

cat(sprintf("  Mean VKT (car owners): %s km/yr\n",
            format(round(mean(dt_pers[n_cars > 0, total_km])), big.mark = ",")))
cat("  PASS: woonbase + RDW join works\n\n")


# 4. Woonbase + SPOLIS: income per person ----

cat("--- 4. Woonbase + SPOLIS ---\n")

income_pp <- dt_sp[, .(total_wage = sum(SVLOON, na.rm = TRUE)), by = RINPERSOON]
dt_pers[income_pp, on = "RINPERSOON", wage := i.total_wage]
dt_pers[is.na(wage), wage := 0]

employed_rate <- mean(dt_pers$wage > 0) * 100
cat(sprintf("  Employment rate: %.1f%% of persons have SPOLIS wage > 0\n", employed_rate))
cat(sprintf("  Mean wage (employed): EUR %s\n",
            format(round(mean(dt_pers[wage > 0, wage])), big.mark = ",")))
cat("  PASS: woonbase + SPOLIS join works\n\n")


# 5. Woonbase + VEHTAB: wealth per household ----

cat("--- 5. Woonbase + VEHTAB ---\n")

# Get ref person per HH from woonbase
dt_hh <- as.data.table(read_sav(
  sprintf("WoonbasePopulatieHuishoudens%dV1", YEAR),
  col_select = c(HUISHOUDNR1Jan, RINPERSOON)
))

dt_hh[dt_veh, on = c("RINPERSOON" = "RINPERSOONHKW"),
      `:=`(wealth = i.VEHW1000VERH, welvaart_pct = i.VEHP100WELVAART)]

wealth_match <- mean(!is.na(dt_hh$wealth)) * 100
cat(sprintf("  Wealth match rate: %.1f%%\n", wealth_match))
cat(sprintf("  Mean HH wealth: EUR %s\n",
            format(round(mean(dt_hh$wealth, na.rm = TRUE)), big.mark = ",")))
cat("  PASS: woonbase + VEHTAB join works\n\n")


# 6. Woonbase + ENERGIEVERBRUIK: energy per dwelling ----

cat("--- 6. Woonbase + ENERGIEVERBRUIK ---\n")

# Join energy data to persons via RINOBJECTNUMMER
dt_pers[dt_ev, on = c("RINOBJECTNUMMER1Jan" = "RINOBJECTNUMMER"),
        `:=`(gas = i.GAS, elek = i.ELEK)]

energy_match <- mean(!is.na(dt_pers$gas)) * 100
cat(sprintf("  Energy match rate: %.1f%%\n", energy_match))
cat(sprintf("  Mean gas: %.0f m3, mean elek: %.0f kWh\n",
            mean(dt_pers$gas, na.rm = TRUE),
            mean(dt_pers$elek, na.rm = TRUE)))
cat("  PASS: woonbase + ENERGIEVERBRUIK join works\n\n")


# 7. Full 5-way join: HH-level summary ----

cat("--- 7. Full 5-way household summary ---\n")

# Aggregate person-level to HH
hh_summary <- dt_pers[, .(
  n_pers   = .N,
  n_cars   = sum(n_cars),
  total_km = sum(total_km),
  total_wage = sum(wage),
  gas      = gas[1],
  elek     = elek[1],
  typhh    = as.character(as_factor(TYPHH1Jan))[1],
  gem_code = GemeenteCodeJJJJ1Jan[1]
), by = HUISHOUDNR1Jan]

# Add wealth from VEHTAB
hh_summary[dt_hh[, .(HUISHOUDNR1Jan, wealth, welvaart_pct)],
           on = "HUISHOUDNR1Jan",
           `:=`(wealth = i.wealth, welvaart_pct = i.welvaart_pct)]

cat(sprintf("  Households: %d\n", nrow(hh_summary)))
cat(sprintf("  Columns: %s\n", paste(names(hh_summary), collapse = ", ")))
cat(sprintf("  Complete cases (all 5 datasets): %d (%.0f%%)\n",
            sum(complete.cases(hh_summary)),
            mean(complete.cases(hh_summary)) * 100))

# Quick cross-tabulation: cars by HH type
cat("\n  Cars per HH by household type:\n")
by_typhh <- hh_summary[, .(avg_cars = mean(n_cars),
                            avg_wage = mean(total_wage),
                            avg_gas  = mean(gas, na.rm = TRUE),
                            n = .N),
                        by = typhh]
setorder(by_typhh, -avg_cars)
for (i in seq_len(min(6, nrow(by_typhh)))) {
  cat(sprintf("    %-35s cars=%.1f  wage=%6s  gas=%4.0f m3  (n=%d)\n",
              by_typhh$typhh[i], by_typhh$avg_cars[i],
              format(round(by_typhh$avg_wage[i]), big.mark = ","),
              by_typhh$avg_gas[i], by_typhh$n[i]))
}

cat("\n")


# 8. Gemeente-level: all datasets combined ----

cat("--- 8. Gemeente-level aggregation ---\n")

gem <- hh_summary[!is.na(gem_code), .(
  n_hh     = .N,
  avg_cars = mean(n_cars),
  avg_km   = mean(total_km),
  avg_wage = mean(total_wage),
  avg_wealth = mean(wealth, na.rm = TRUE),
  avg_gas  = mean(gas, na.rm = TRUE),
  avg_elek = mean(elek, na.rm = TRUE)
), by = gem_code]

cat(sprintf("  Gemeenten with data: %d\n", nrow(gem)))
cat(sprintf("  Example (first gemeente): cars=%.1f, km=%s, wage=%s, wealth=%s, gas=%.0f, elek=%.0f\n",
            gem$avg_cars[1],
            format(round(gem$avg_km[1]), big.mark = ","),
            format(round(gem$avg_wage[1]), big.mark = ","),
            format(round(gem$avg_wealth[1]), big.mark = ","),
            gem$avg_gas[1], gem$avg_elek[1]))
cat("  PASS: full 5-way gemeente aggregation works\n\n")


# 9. Woonbase + HOOGSTEOPLTAB: education per person ----

cat("--- 9. Woonbase + HOOGSTEOPLTAB ---\n")

dt_opl <- as.data.table(read_sav(
  sprintf("HOOGSTEOPL%dTABV1", YEAR),
  col_select = c(RINPERSOON, OPLNIVSOI2021AGG4HBmetNIRWO)
))

dt_pers[dt_opl, on = "RINPERSOON",
        opl_niveau := as.character(i.OPLNIVSOI2021AGG4HBmetNIRWO)]

opl_match <- mean(!is.na(dt_pers$opl_niveau)) * 100
cat(sprintf("  Education match rate: %.1f%%\n", opl_match))
cat("  PASS: woonbase + HOOGSTEOPLTAB join works\n\n")


# 10. Woonbase + INPATAB: personal income ----

cat("--- 10. Woonbase + INPATAB ---\n")

dt_inpa <- as.data.table(read_sav(
  sprintf("INPA%dTABV1", YEAR),
  col_select = c(RINPERSOON, INPPERSINK, RINPERSOONHKW)
))

dt_pers[dt_inpa, on = "RINPERSOON", pers_ink := i.INPPERSINK]
inpa_match <- mean(!is.na(dt_pers$pers_ink)) * 100
cat(sprintf("  INPATAB match rate: %.1f%%\n", inpa_match))
cat(sprintf("  Mean personal income: EUR %s\n",
            format(round(mean(dt_pers$pers_ink, na.rm = TRUE)), big.mark = ",")))
cat("  PASS: woonbase + INPATAB join works\n\n")


# 11. INPATAB + INHATAB: person income → household income via HKW ----

cat("--- 11. INPATAB + INHATAB (via HKW) ---\n")

dt_inha <- as.data.table(read_sav(
  sprintf("INHA%dTABV1", YEAR),
  col_select = c(RINPERSOONHKW, INHBESTINKH)
))

dt_inpa[dt_inha, on = "RINPERSOONHKW", hh_ink := i.INHBESTINKH]
hkw_match <- mean(!is.na(dt_inpa$hh_ink)) * 100
cat(sprintf("  HKW link match rate: %.1f%%\n", hkw_match))
stopifnot(hkw_match > 0)
cat("  PASS: INPATAB + INHATAB HKW join works\n\n")


# 12. Woonbase + SECMBUS: socioeconomic category ----

cat("--- 12. Woonbase + SECMBUS ---\n")

dt_secm <- as.data.table(read_sav(
  sprintf("SECMBUS%dV1", YEAR),
  col_select = c(RINPERSOON, SECM, AANVSECM, EINDSECM)
))

cat(sprintf("  SECMBUS rows: %d (persons: %d)\n",
            nrow(dt_secm), uniqueN(dt_secm$RINPERSOON)))

# Join first SECM per person to woonbase
secm_first <- dt_secm[, .(SECM = SECM[1]), by = RINPERSOON]
dt_pers[secm_first, on = "RINPERSOON",
        secm := as.character(i.SECM)]

secm_match <- mean(!is.na(dt_pers$secm)) * 100
cat(sprintf("  SECM match rate: %.1f%%\n", secm_match))
cat("  PASS: woonbase + SECMBUS join works\n\n")


# 13. SPOLIS + BETAB: jobs → business register ----

cat("--- 13. SPOLIS + BETAB ---\n")

dt_be <- as.data.table(read_sav(
  sprintf("BE%dTABV1", YEAR),
  col_select = c(BEID, SBI2008VJJJJ, GKSBS)
))

dt_sp2 <- as.data.table(read_sav(
  sprintf("SPOLISBUS%dV1", YEAR),
  col_select = c(RINPERSOON, SBEID)
))

dt_sp2[dt_be, on = c("SBEID" = "BEID"),
       `:=`(sbi = as.character(i.SBI2008VJJJJ),
            gk  = as.character(i.GKSBS))]

be_match <- mean(!is.na(dt_sp2$sbi)) * 100
cat(sprintf("  SPOLIS-BETAB match rate: %.1f%%\n", be_match))
cat(sprintf("  Unique SBI codes in matched records: %d\n",
            uniqueN(dt_sp2$sbi[!is.na(dt_sp2$sbi)])))
cat("  PASS: SPOLIS + BETAB join works\n\n")


# 14. Woonbase + network datasets ----

cat("--- 14. Woonbase + network datasets ---\n")

dt_buren <- as.data.table(read_sav(
  sprintf("BURENNETWERK%dTABV1", YEAR),
  col_select = c(RINPERSOON, RINPERSOONRELATIE, RELATIE)
))

dt_collega <- as.data.table(read_sav(
  sprintf("COLLEGANETWERK%dTABV1", YEAR),
  col_select = c(RINPERSOON, RINPERSOONRELATIE, RELATIE)
))

dt_familie <- as.data.table(read_sav(
  sprintf("FAMILIENETWERK%dTABV1", YEAR),
  col_select = c(RINPERSOON, RINPERSOONRELATIE, RELATIE)
))

cat(sprintf("  Buren rows: %s, Collega rows: %s, Familie rows: %s\n",
            format(nrow(dt_buren), big.mark = ","),
            format(nrow(dt_collega), big.mark = ","),
            format(nrow(dt_familie), big.mark = ",")))

# All ego persons should exist in woonbase
buren_match <- mean(unique(dt_buren$RINPERSOON) %in% dt_pers$RINPERSOON) * 100
collega_match <- mean(unique(dt_collega$RINPERSOON) %in% dt_pers$RINPERSOON) * 100
familie_match <- mean(unique(dt_familie$RINPERSOON) %in% dt_pers$RINPERSOON) * 100
cat(sprintf("  Spine match: buren=%.0f%%, collega=%.0f%%, familie=%.0f%%\n",
            buren_match, collega_match, familie_match))
stopifnot(buren_match == 100, collega_match == 100, familie_match == 100)

# Both ego and alter persons should come from the spine
alter_match <- mean(unique(dt_buren$RINPERSOONRELATIE) %in% dt_pers$RINPERSOON) * 100
cat(sprintf("  Alter match (buren): %.0f%%\n", alter_match))
stopifnot(alter_match == 100)
cat("  PASS: woonbase + network datasets join works\n\n")


cat("=== All cross-dataset tests passed ===\n")
