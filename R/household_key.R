# Household key (HKW) generation ----
#
# Maps HUISHOUDNR -> RINPERSOONHKW for linking person-level data
# to household-level income/wealth files (INPATAB, INHATAB, VEHTAB).
# The HKW is the RINPERSOON of the household's main earner (hoofdkostwinner).

# Generate deterministic HKW IDs from household numbers ----
# Same HUISHOUDNR always produces the same RINPERSOONHKW.
# Vectorized multiplicative hash (no per-element R loop).
.deterministic_hkw_id <- function(huishoudnr) {
  hh_num <- as.double(huishoudnr)
  mod <- 2147483647  # 2^31 - 1
  mixed <- (hh_num * 48271 + 12345) %% mod
  # Second mix for better distribution
  mixed <- (mixed * 69069 + 1) %% mod
  sprintf("%09d", as.integer(mixed %% 1e9))
}

# Add RINPERSOONHKW to a person spine table ----
# Maps each person's HUISHOUDNR to a deterministic HKW ID.
.add_hkw_to_spine <- function(pers_dt) {
  if ("RINPERSOONHKW" %in% names(pers_dt)) return(pers_dt)
  if (!("HUISHOUDNR" %in% names(pers_dt))) return(pers_dt)

  hh_ids <- unique(pers_dt$HUISHOUDNR)
  hkw_map <- data.table(
    HUISHOUDNR = hh_ids,
    RINPERSOONHKW = .deterministic_hkw_id(hh_ids)
  )
  pers_dt <- merge(pers_dt, hkw_map, by = "HUISHOUDNR", sort = FALSE)
  pers_dt
}
