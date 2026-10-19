# Demographic dynamics across years (births / deaths / migration) ----
#
# The spine's Phase 1 assigns each person a stable identity (RINPERSOON, sex,
# household position). This module layers a *year-invariant* life course on top
# of that identity: a birth year, a death year, and optional emigration /
# immigration years. Because every event is derived deterministically from the
# person's RINPERSOON (via `.hash_to_uniform()`), a given seed produces the same
# life course regardless of which simulation year is being built — so panels
# become genuinely unbalanced across years (persons enter and leave) while
# staying fully reproducible.
#
# Population-snapshot files (woonbase WoonbasePopulatiePersonen, the GBA
# person/address/household bus files) then show only the persons present in the
# simulation year; the indicator columns (IsGeboren, IsOverleden, IsGeemigreerd,
# IsGeimmigreerd, IsAanwezig1Jan/31Dec) are derived from these life events rather
# than drawn independently, so a person flagged as deceased in year Y is absent
# in year Y+1.
#
# Rates below are approximate and centred on `.REF_YEAR` so that typical
# simulation years (roughly .REF_YEAR +/- window_half) see realistic inflow and
# outflow. Precise calibration to CBS StatLine is deliberately out of scope here
# (tracked separately as the cbsodataR calibration benchmark).

.DEMOG <- list(
  window_half     = 12L,   # entry/exit events fall within .REF_YEAR +/- this
  life_mean_men   = 80,    # mean lifespan, years (male)
  life_mean_women = 83,    # mean lifespan, years (female)
  life_sd         = 11,    # lifespan spread, years
  p_emigrant      = 0.05,  # share of persons who emigrate within the window
  p_immigrant     = 0.06   # share of persons who immigrated within the window
)

# Sentinels for "no such event" kept as integers so the min()/max() interval
# arithmetic below never has to deal with Inf.
.DEMOG_NEVER <- 9999L    # exit sentinel: effectively never leaves
.DEMOG_ALWAYS <- -9999L  # entry sentinel: effectively always present

# Draw a deterministic calendar year within .REF_YEAR +/- window_half from a
# unit-interval hash.
.demog_window_year <- function(u, ref_year, wh) {
  ref_year - wh + as.integer(floor(u * (2L * wh + 1L)))
}

# Assign a year-invariant life course to every person in the spine.
#
# Mutates `dt_pers` by reference, adding DemogEntryYear, DemogExitYear,
# DemogEntryType, DemogExitType, and overwriting GBAGeboorteJaar for children so
# that each simulation year has a genuine birth cohort. Uses only RINPERSOON
# hashing (no RNG), so it neither consumes the Phase 1 RNG stream nor varies with
# the simulation year.
.assign_life_events <- function(dt_pers, ref_year) {
  ref_year <- as.integer(ref_year)
  wh <- .DEMOG$window_half
  id <- dt_pers$RINPERSOON

  # --- Birth year -----------------------------------------------------------
  # Children (PLHH == "1") get a deterministic birth year spanning from the
  # oldest child age back to a little past the window, so that for any given
  # simulation year some children are "born this year" (cohort entry). Adults
  # keep their Phase 1 birth years (all historical, so they have always been
  # present).
  is_child <- dt_pers$PLHH == "1"
  u_birth <- .hash_to_uniform(id, "demog_birthyear")
  span_lo <- ref_year - 17L
  span_hi <- ref_year + wh
  child_birth <- span_lo + as.integer(floor(u_birth * (span_hi - span_lo + 1L)))
  birth <- as.integer(dt_pers$GBAGeboorteJaar)
  birth[is_child] <- child_birth[is_child]

  # --- Death year -----------------------------------------------------------
  women <- dt_pers$GBAGeslachtsAanduiding == "2"
  life_mean <- ifelse(women, .DEMOG$life_mean_women, .DEMOG$life_mean_men)
  u_life <- .hash_to_uniform(id, "demog_lifespan")
  u_life <- pmin(pmax(u_life, 1e-9), 1 - 1e-9)
  lifespan <- stats::qnorm(u_life, mean = life_mean, sd = .DEMOG$life_sd)
  lifespan <- pmax(1, lifespan)
  death_year <- birth + as.integer(round(lifespan))

  # --- Emigration (leaves at emig_year) -------------------------------------
  u_emig_sel <- .hash_to_uniform(id, "demog_emig_sel")
  u_emig_yr  <- .hash_to_uniform(id, "demog_emig_year")
  emig_year <- pmax(.demog_window_year(u_emig_yr, ref_year, wh), birth)
  emig_year[u_emig_sel >= .DEMOG$p_emigrant] <- .DEMOG_NEVER

  # --- Immigration (absent before immig_year) -------------------------------
  # Children are modelled as born in NL, so they are not immigrants.
  u_immig_sel <- .hash_to_uniform(id, "demog_immig_sel")
  u_immig_yr  <- .hash_to_uniform(id, "demog_immig_year")
  immig_year <- pmax(.demog_window_year(u_immig_yr, ref_year, wh), birth)
  is_immig <- (u_immig_sel < .DEMOG$p_immigrant) & !is_child
  immig_year[!is_immig] <- .DEMOG_ALWAYS

  # --- Presence interval + event typing -------------------------------------
  entry_year <- pmax(birth, immig_year)
  exit_year  <- pmin(death_year, emig_year)
  exit_year  <- pmax(exit_year, entry_year)  # guard degenerate intervals

  entry_type <- ifelse(is_immig & immig_year > birth, "immig", "birth")
  exit_type  <- ifelse(emig_year < death_year, "emig", "death")

  dt_pers[, GBAGeboorteJaar := birth]
  dt_pers[, DemogEntryYear := entry_year]
  dt_pers[, DemogExitYear  := exit_year]
  dt_pers[, DemogEntryType := entry_type]
  dt_pers[, DemogExitType  := exit_type]
  invisible(dt_pers)
}

# Derive the year-specific life-event indicators + presence mask for a given
# simulation year from the year-invariant life course assigned above.
#
# Returns a named list: `present` (logical, which persons are in the population
# this year) plus the six "0"/"1" indicator vectors.
.demographic_indicators <- function(dt_pers, year) {
  year <- as.integer(year)
  ey <- dt_pers$DemogEntryYear
  xy <- dt_pers$DemogExitYear
  et <- dt_pers$DemogEntryType
  xt <- dt_pers$DemogExitType
  b01 <- function(x) as.character(as.integer(x))

  list(
    # Present during the year = entered on/before it and not yet left.
    present = ey <= year & xy >= year,

    Indicator_PersoonIsGeboren       = b01(ey == year & et == "birth"),
    Indicator_PersoonIsGeimmigreerd  = b01(ey == year & et == "immig"),
    Indicator_PersoonIsOverleden     = b01(xy == year & xt == "death"),
    Indicator_PersoonIsGeemigreerd   = b01(xy == year & xt == "emig"),
    # Present at the start of the year = entered in a prior year, still here.
    Indicator_PersoonIsAanwezig1Jan  = b01(ey <  year & xy >= year),
    # Present at year-end = already here and surviving past the year.
    Indicator_PersoonIsAanwezig31Dec = b01(ey <= year & xy >  year)
  )
}

# Repair household bookkeeping after a population-snapshot file has been
# restricted to the persons present in the simulation year: recompute household
# member/child counts on the survivors and promote a surviving member to
# reference person where the original reference person has left. Operates on the
# already-subset table by reference.
.repair_active_households <- function(dt) {
  if (!"HUISHOUDNR" %in% names(dt)) return(dt)

  if ("AantalPersonenPerHuishouden" %in% names(dt)) {
    dt[, AantalPersonenPerHuishouden := .N, by = HUISHOUDNR]
  }
  if (all(c("AantalKinderenPerHuishouden", "PLHH") %in% names(dt))) {
    dt[, AantalKinderenPerHuishouden := sum(PLHH == "1"), by = HUISHOUDNR]
  }
  if ("REFPERSOONHH" %in% names(dt)) {
    dt[, demog_has_ref := any(REFPERSOONHH == "1"), by = HUISHOUDNR]
    if (any(!dt$demog_has_ref)) {
      dt[demog_has_ref == FALSE,
         REFPERSOONHH := replace(REFPERSOONHH, 1L, "1"), by = HUISHOUDNR]
    }
    dt[, demog_has_ref := NULL]
  }
  dt
}
