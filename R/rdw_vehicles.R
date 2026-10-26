# RDW vehicle structure ----
#
# RDWNPACT has one row per vehicle. Owners can have several vehicles, the file
# also holds dropped (uitval) and business-stock (bedrijfsvoorraad) passenger
# cars, and vehicles owned by companies or by persons outside the GBA carry an
# owner id that does not link to the population. VERKEERSPRESTATIE covers only
# active passenger cars of natural persons. These attributes are fixed on the
# RDW spine so both files agree whichever columns are read.

# Vehicles per owner (assumption, not from StatLine; see provenance article)
.RDW_VEHICLES_PER_OWNER <- c("1" = 0.68, "2" = 0.20, "3" = 0.07, "4" = 0.03,
                             "5" = 0.02)
.RDW_MEAN_VEHICLES <- sum(as.integer(names(.RDW_VEHICLES_PER_OWNER)) *
                            .RDW_VEHICLES_PER_OWNER)

# Shares of passenger cars that are dropped or in business stock (assumption)
.RDW_CAR_UITVAL <- 0.03
.RDW_CAR_BEDRIJFSVOORRAAD <- 0.02

# Owner type (SRTREFVRTG) per vehicle; N = natural person
.RDW_SRTREF <- c(B = 0.05, I = 0.02, N = 0.75, R = 0.15, H = 0.03)
# Natural persons not in the GBA (RINPERSOONS S)
.RDW_SHARE_S <- 0.02

# Repeat each sampled owner by their number of vehicles (stable per person)
# and add the vehicle's slot; keeps the first `n_records` rows
.rdw_expand_owners <- function(pers, n_records) {
  n_veh <- as.integer(.deterministic_categorical(
    as.character(pers$RINPERSOON), names(.RDW_VEHICLES_PER_OWNER),
    .RDW_VEHICLES_PER_OWNER, salt = "n_vehicles"))
  out <- pers[rep(seq_len(nrow(pers)), n_veh)]
  out[, slot := sequence(n_veh)]
  out[seq_len(min(nrow(out), n_records))]
}

# Numeric key per vehicle: the owner's id for the first vehicle (so existing
# plates are unchanged), a hash of owner and slot for further vehicles
.rdw_vehicle_key <- function(rinpersoon, slot) {
  rp <- as.double(rinpersoon)
  if (is.null(slot)) return(rp)
  fifelse(slot == 1L, rp,
          (rp * 16807 + slot * 2147483 + 7919) %% 2147483647)
}

# Vehicle type, status, owner type, owner id and colour, fixed per plate
.rdw_vehicle_structure <- function(veh, params) {
  kt <- veh$RINKENTEKEN

  soort_p <- params$vrtgsoort_p
  if (is.null(soort_p)) {
    soort_p <- c("0" = 0.038, "1" = 0.074, "2" = 0.012, "3" = 0.005,
                 "4" = 0.004, "5" = 0.003, "6" = 0.720, "7" = 0.048,
                 "8" = 0.073, "9" = 0.023)
  }
  # same salt as the former column spec, so plates keep their vehicle type
  soort <- .deterministic_categorical(kt, names(soort_p), as.numeric(soort_p),
                                      salt = "VRTGSOORT")
  u <- .hash_to_uniform(kt, "status")
  soort[soort == "6" & u < .RDW_CAR_UITVAL] <- "F"
  soort[soort == "6" & u >= .RDW_CAR_UITVAL &
          u < .RDW_CAR_UITVAL + .RDW_CAR_BEDRIJFSVOORRAAD] <- "P"

  srtref <- .deterministic_categorical(kt, names(.RDW_SRTREF), .RDW_SRTREF,
                                       salt = "SRTREFVRTG")

  # Owners outside the GBA get an id that does not link to the population:
  # companies (K) per vehicle owner draw, persons with a sofinummer (S) per person
  rp <- as.character(veh$RINPERSOON)
  is_s <- .hash_to_uniform(rp, "rinpersoons_s") < .RDW_SHARE_S
  rinpersoons <- fifelse(srtref != "N", "K", fifelse(is_s, "S", "R"))
  outside <- rinpersoons != "R"
  if (any(outside)) {
    rp[outside] <- sprintf("%09.0f", floor(
      .hash_to_uniform(paste0(rp[outside], rinpersoons[outside]), "owner") * 1e9))
  }

  # Colour is recorded for passenger cars only; 99 = not applicable
  kleur_p <- params$kleur_p
  if (is.null(kleur_p)) {
    kleur_p <- c("--" = 0.005, "00" = 0.003, "01" = 0.005, "02" = 0.072,
                 "03" = 0.148, "04" = 0.086, "05" = 0.035, "06" = 0.012,
                 "07" = 0.298, "08" = 0.018, "09" = 0.004, "10" = 0.005,
                 "11" = 0.004, "12" = 0.238, "13" = 0.030)
  }
  kleur_p <- kleur_p[names(kleur_p) != "99"]
  kleur <- .deterministic_categorical(kt, names(kleur_p), as.numeric(kleur_p),
                                      salt = "KLEURCODEVRTG")
  kleur[!soort %in% c("6", "F", "P")] <- "99"

  veh[, `:=`(RINPERSOON = rp, RINPERSOONS = rinpersoons,
             VRTGSOORT = soort, SRTREFVRTG = srtref, KLEURCODEVRTG = kleur)]
  veh[]
}

# Plates in VERKEERSPRESTATIE: active passenger cars of natural persons
.rdw_verkeersprestatie <- function(veh) {
  veh[VRTGSOORT == "6" & SRTREFVRTG == "N"]
}

# Year parameters as named vectors, nearest year without a warning
.load_rdw_params <- function(year) {
  path <- .rdw_params_yaml()
  if (!file.exists(path)) return(list())
  all_p <- yaml::read_yaml(path)
  avail <- as.integer(names(all_p))
  yd <- all_p[[as.character(avail[which.min(abs(avail - year))])]]
  lapply(yd, function(x) if (is.list(x)) unlist(x) else x)
}
