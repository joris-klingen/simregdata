# Test longitudinal consistency across years
suppressPackageStartupMessages({
  library(data.table)
  library(haven)
})
devtools::load_all(".")

cat("=== Longitudinal consistency tests ===\n\n")

N    <- 500L
SEED <- 42L

# Test 1: Same seed + same n + different year → same RINPERSOONs ----
cat("--- 1. Cross-year RINPERSOON consistency ---\n")
sim_reset()
sim_init("woonbase", year = 2020L, n = N, seed = SEED)
dt_2020 <- as.data.table(read_sav("WoonbasePopulatiePersonen2020V1",
  col_select = c("RINPERSOON", "RINPERSOONS", "GBAGeboorteJaar", "GBAGeslachtsAanduiding")))

sim_reset()
sim_init("woonbase", year = 2023L, n = N, seed = SEED)
dt_2023 <- as.data.table(read_sav("WoonbasePopulatiePersonen2023V1",
  col_select = c("RINPERSOON", "RINPERSOONS", "GBAGeboorteJaar", "GBAGeslachtsAanduiding")))

# Same persons
rp_2020 <- sort(dt_2020$RINPERSOON)
rp_2023 <- sort(dt_2023$RINPERSOON)
stopifnot(identical(rp_2020, rp_2023))
cat("  Same RINPERSOONs: PASS\n")

# Same birth years (absolute, year-invariant)
dt_m <- merge(dt_2020, dt_2023, by = "RINPERSOON", suffixes = c("_20", "_23"))
stopifnot(all(dt_m$GBAGeboorteJaar_20 == dt_m$GBAGeboorteJaar_23))
cat("  Same birth years: PASS\n")

# Same sex
stopifnot(all(dt_m$GBAGeslachtsAanduiding_20 == dt_m$GBAGeslachtsAanduiding_23))
cat("  Same sex: PASS\n")


# Test 2: Year-varying attributes should differ ----
cat("\n--- 2. Year-varying attributes differ ---\n")
sim_reset()
sim_init("woonbase", year = 2020L, n = N, seed = SEED)
obj_2020 <- as.data.table(read_sav("WoonbaseKenmerkenWoonruimten2020V1",
  col_select = c("RINOBJECTNUMMER", "WOZWaardeObjectBAG1Jan", "GemeenteCodeJJJJ1Jan")))

sim_reset()
sim_init("woonbase", year = 2023L, n = N, seed = SEED)
obj_2023 <- as.data.table(read_sav("WoonbaseKenmerkenWoonruimten2023V1",
  col_select = c("RINOBJECTNUMMER", "WOZWaardeObjectBAG1Jan", "GemeenteCodeJJJJ1Jan")))

# Same objects
stopifnot(identical(sort(obj_2020$RINOBJECTNUMMER), sort(obj_2023$RINOBJECTNUMMER)))
cat("  Same RINOBJECTNUMMERs: PASS\n")

# WOZ values should differ between years
obj_m <- merge(obj_2020, obj_2023, by = "RINOBJECTNUMMER", suffixes = c("_20", "_23"))
woz_differ <- sum(obj_m$WOZWaardeObjectBAG1Jan_20 != obj_m$WOZWaardeObjectBAG1Jan_23)
cat(sprintf("  WOZ values differ: %d / %d (%.0f%%)\n",
            woz_differ, nrow(obj_m), 100 * woz_differ / nrow(obj_m)))
stopifnot(woz_differ > 0)
cat("  Year-varying WOZ: PASS\n")

# Gemeente may differ too
gem_differ <- sum(obj_m$GemeenteCodeJJJJ1Jan_20 != obj_m$GemeenteCodeJJJJ1Jan_23)
cat(sprintf("  Gemeente differs: %d / %d (%.0f%%)\n",
            gem_differ, nrow(obj_m), 100 * gem_differ / nrow(obj_m)))


# Test 3: Same seed + same year → identical output ----
cat("\n--- 3. Reproducibility (same seed + same year) ---\n")
sim_reset()
sim_init("woonbase", year = 2023L, n = N, seed = SEED)
dt_a <- as.data.table(read_sav("WoonbasePopulatiePersonen2023V1"))

sim_reset()
sim_init("woonbase", year = 2023L, n = N, seed = SEED)
dt_b <- as.data.table(read_sav("WoonbasePopulatiePersonen2023V1"))

stopifnot(identical(dt_a, dt_b))
cat("  Identical output: PASS\n")


# Test 4: Household consistency ----
cat("\n--- 4. Cross-year household consistency ---\n")
sim_reset()
sim_init("woonbase", year = 2020L, n = N, seed = SEED)
hh_2020 <- as.data.table(read_sav("WoonbaseSleutelbestand2020V1",
  col_select = c("RINPERSOON", "HUISHOUDNR", "TYPHH", "PLHH")))

sim_reset()
sim_init("woonbase", year = 2023L, n = N, seed = SEED)
hh_2023 <- as.data.table(read_sav("WoonbaseSleutelbestand2023V1",
  col_select = c("RINPERSOON", "HUISHOUDNR", "TYPHH", "PLHH")))

hh_m <- merge(hh_2020, hh_2023, by = "RINPERSOON", suffixes = c("_20", "_23"))
stopifnot(all(hh_m$HUISHOUDNR_20 == hh_m$HUISHOUDNR_23))
cat("  Same HUISHOUDNRs: PASS\n")
stopifnot(all(hh_m$TYPHH_20 == hh_m$TYPHH_23))
cat("  Same TYPHH: PASS\n")
stopifnot(all(hh_m$PLHH_20 == hh_m$PLHH_23))
cat("  Same PLHH: PASS\n")


# Test 5: Cross-dataset longitudinal (RDW) ----
cat("\n--- 5. Cross-dataset longitudinal (RDW) ---\n")
sim_reset()
sim_init("rdw", year = 2020L, n = N, seed = SEED)
rdw_2020 <- as.data.table(read_sav("RDWNPACT2020TABV1",
  col_select = c("RINPERSOON", "RINKENTEKEN")))

sim_reset()
sim_init("rdw", year = 2023L, n = N, seed = SEED)
rdw_2023 <- as.data.table(read_sav("RDWNPACT2023TABV1",
  col_select = c("RINPERSOON", "RINKENTEKEN")))

# RDW samples from the shared spine — same spine persons should appear
overlap <- length(intersect(rdw_2020$RINPERSOON, rdw_2023$RINPERSOON))
cat(sprintf("  Person overlap: %d / %d (%.0f%%)\n",
            overlap, nrow(rdw_2020), 100 * overlap / nrow(rdw_2020)))
# With same n and seed, the shared spine is identical, so generic sampling
# with set.seed(seed) should produce the same person selection
stopifnot(overlap > 0)
cat("  Cross-year person overlap: PASS\n")


# Test 6: Natural aging ----
cat("\n--- 6. Natural aging ---\n")
sim_reset()
sim_init("woonbase", year = 2020L, n = N, seed = SEED)
age_2020 <- as.data.table(read_sav("WoonbaseKenmerkenPersonen2020V1",
  col_select = c("RINPERSOON", "GBAGeboorteJaar")))

sim_reset()
sim_init("woonbase", year = 2023L, n = N, seed = SEED)
age_2023 <- as.data.table(read_sav("WoonbaseKenmerkenPersonen2023V1",
  col_select = c("RINPERSOON", "GBAGeboorteJaar")))

age_m <- merge(age_2020, age_2023, by = "RINPERSOON")
# Birth years should be identical (age = year - birth_year)
stopifnot(all(age_m$GBAGeboorteJaar.x == age_m$GBAGeboorteJaar.y))
# So a person's age in 2023 is 3 years more than in 2020
age_2020_val <- 2020L - age_m$GBAGeboorteJaar.x
age_2023_val <- 2023L - age_m$GBAGeboorteJaar.y
stopifnot(all(age_2023_val - age_2020_val == 3L))
cat("  Age increases by 3 years (2020 -> 2023): PASS\n")


cat("\n=== All longitudinal consistency tests passed ===\n")
