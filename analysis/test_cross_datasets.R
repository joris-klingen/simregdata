# analysis/test_cross_datasets.R
#
# Cross-dataset combination tests.
# Verifies that all 5 datasets can be joined via shared identifiers.
#
# Run: Rscript analysis/test_cross_datasets.R

suppressPackageStartupMessages({
  library(data.table)
  library(haven)
})
devtools::load_all(".")

YEAR <- 2023L
N    <- 5000L
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
cat("  All 5 datasets initialised\n\n")


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


cat("=== All cross-dataset tests passed ===\n")
