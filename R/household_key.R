# Household key (HKW) generation ----
#
# Maps HUISHOUDNR -> RINPERSOONHKW for linking person-level data
# to household-level income/wealth files (INPATAB, INHATAB, VEHTAB).
# In real CBS data the HKW is the RINPERSOON of the household's main earner;
# here it is a synthetic 9-digit id that is stable and unique per household.

# Generate deterministic HKW IDs from household numbers ----
# Same HUISHOUDNR always produces the same RINPERSOONHKW.
# HUISHOUDNR is a sequential integer (< 1e9 for any realistic population), so a
# multiplicative hash by a constant coprime to 1e9 is a *bijection* on
# residues mod 1e9 -- distinct households never collide (unlike a wrapping
# hash into a 1e9 space, which produced ~n^2/2e9 collisions at full scale).
.deterministic_hkw_id <- function(huishoudnr) {
  hh_num <- as.double(huishoudnr)
  # 386201 is odd and not divisible by 5 -> coprime to 1e9 = 2^9 * 5^9.
  # hh_num < 1e9 keeps hh_num * 386201 < 3.9e17; well under 2^53 for the
  # ~8M households of a full national population.
  mixed <- (hh_num * 386201) %% 1e9
  sprintf("%09d", as.integer(mixed))
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
  pers_dt[hkw_map, RINPERSOONHKW := RINPERSOONHKW, on = "HUISHOUDNR"]
  pers_dt
}
