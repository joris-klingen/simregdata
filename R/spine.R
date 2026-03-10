# Reference household type distribution (average across 2016-2024 CBS data).
# Used in Phase 1 (identity) so that the same seed always produces the same
# household structure regardless of simulation year.
.REF_TYPHH_P <- c("1"=0.381, "2"=0.073, "3"=0.205, "4"=0.055,
                   "5"=0.194, "6"=0.072, "7"=0.005, "8"=0.014)

# Fixed average household size for identity-phase N_HH calculation.
# Same n + same seed → same N_HH → same persons across years.
.FIXED_AVG_HH_SIZE <- 2.15

# Reference year for absolute birth year generation.
# Person ages are computed as simulation_year - GBAGeboorteJaar.
.REF_YEAR <- 2020L


.build_spine <- function(n_persons, params, seed, year) {
  year <- as.integer(year)
  t0 <- proc.time()[["elapsed"]]
  .stage <- function(i, n, label) {
    message(sprintf("  [%d/%d] %s ...", i, n, label))
  }

  jan1  <- as.Date(paste0(year, "-01-01"))
  dec31 <- as.Date(paste0(year, "-12-31"))

  N_HH <- round(n_persons / .FIXED_AVG_HH_SIZE)
  N_OBJ <- N_HH

  message(sprintf("  Building spine: %s persons / %s households / %s objects",
                  format(n_persons, big.mark=","),
                  format(N_HH, big.mark=","),
                  format(N_OBJ, big.mark=",")))

  # ==== PHASE 1: Year-invariant identity =====================================
  # Same seed always produces the same persons, IDs, birth years, sex,
  # household structure — regardless of simulation year.
  set.seed(seed)

  # ---- Objects (identity) ----
  .stage(1L, 3L, "Objects")

  dt_obj <- data.table::data.table(
    RINOBJECTNUMMER   = .rand_id(N_OBJ, 16L),
    SOORTOBJECTNUMMER = .rcat(N_OBJ, names(params$soortobj_p), params$soortobj_p)
  )

  # ---- Households (identity) ----
  .stage(2L, 3L, "Households")
  dt_hh <- data.table::data.table(
    HUISHOUDNR        = .seq_id(N_HH, 12L),
    TYPHH             = .rcat(N_HH, names(.REF_TYPHH_P), .REF_TYPHH_P),
    IMPUTATIECODEHH   = .rcat(N_HH, c("0","1"), c(0.95,0.05)),
    DATUMAANVANGHH    = .yyyymmdd(.rdate(N_HH, as.Date("2005-01-01"),
                                         as.Date("2020-01-01"))),
    RINOBJECTNUMMER   = dt_obj$RINOBJECTNUMMER,   # 1:1 mapping (simplified)
    SOORTOBJECTNUMMER = dt_obj$SOORTOBJECTNUMMER
  )

  dt_hh[TYPHH=="1",               HHSize := 1L]
  dt_hh[TYPHH %in% c("2","3"),    HHSize := 2L]
  dt_hh[TYPHH %in% c("4","5"),    HHSize := 2L + sample(1:3, .N, replace=TRUE, prob=c(0.50,0.35,0.15))]
  dt_hh[TYPHH=="6",               HHSize := 1L + sample(1:3, .N, replace=TRUE, prob=c(0.55,0.30,0.15))]
  dt_hh[TYPHH=="7",               HHSize := sample(2:5, .N, replace=TRUE)]
  dt_hh[TYPHH=="8",               HHSize := sample(5:25,.N, replace=TRUE)]
  dt_hh[, NKids := data.table::fcase(
    TYPHH %in% c("4","5"), pmax(0L, HHSize - 2L),
    TYPHH == "6",           pmax(0L, HHSize - 1L),
    default = 0L)]
  data.table::setkey(dt_hh, HUISHOUDNR)

  # ---- Persons (identity) ----
  .stage(3L, 3L, "Persons")
  # Expand: repeat each HH row once per person it contains
  dt_pers <- dt_hh[rep(seq_len(N_HH), times = dt_hh$HHSize)]
  dt_pers[, rank := data.table::rowid(HUISHOUDNR)]
  N_PERS_actual <- nrow(dt_pers)

  # PLHH (positie in huishouden) derived from TYPHH and rank within household
  dt_pers[, PLHH := data.table::fcase(
    TYPHH == "1",                       "2",   # alleenstaande
    TYPHH == "2",                       "3",   # niet-geh paar z.k.
    TYPHH == "3",                       "4",   # geh paar z.k.
    TYPHH == "4" & rank <= 2L,          "5",   # niet-geh paar m.k. -- partners
    TYPHH == "5" & rank <= 2L,          "6",   # geh paar m.k. -- partners
    TYPHH %in% c("4","5") & rank > 2L,  "1",   # kinderen
    TYPHH == "6" & rank == 1L,          "7",   # eenouder
    TYPHH == "6" & rank > 1L,           "1",   # kinderen
    TYPHH == "7" & rank == 1L,          "8",   # ref overig huishouden
    TYPHH == "7" & rank > 1L,           "9",   # overig lid
    TYPHH == "8",                       "10"   # institutioneel lid
  )]

  # Reference person: first in non-institutional HH; all institutional = "9"
  dt_pers[, REFPERSOONHH := data.table::fcase(
    TYPHH == "8",  "9",
    rank == 1L,    "1",
    default =      "0"
  )]

  # Birth year: absolute (year-invariant) using REF_YEAR as anchor.
  # Age in any simulation year = year - GBAGeboorteJaar.
  dt_pers[,            GBAGeboorteJaar := .REF_YEAR - sample(20L:75L, .N, replace = TRUE)]
  dt_pers[PLHH == "1", GBAGeboorteJaar := .REF_YEAR - sample(0L:17L,  .N, replace = TRUE)]
  dt_pers[TYPHH == "8", GBAGeboorteJaar := .REF_YEAR - sample(20L:85L, .N, replace = TRUE)]

  # Civil status by position in household
  dt_pers[,                          GBABurgerlijkeStaat := .rcat(.N, c("O","H","S","W"), c(0.55,0.30,0.08,0.07))]
  dt_pers[PLHH %in% c("4","6"),     GBABurgerlijkeStaat := .rcat(.N, c("H","P"), c(0.90,0.10))]
  dt_pers[PLHH == "1",              GBABurgerlijkeStaat := "O"]

  dt_pers[, GBAGeslachtsAanduiding := .rcat(N_PERS_actual, names(params$geslacht_p), params$geslacht_p)]
  dt_pers[, RINPERSOON  := .rand_id(N_PERS_actual, 9L)]
  dt_pers[, RINPERSOONS := "R"]
  dt_pers[, AanvangWoonduur := .yyyymmdd(.rdate(N_PERS_actual,
                                                 as.Date("2005-01-01"),
                                                 as.Date("2020-01-01")))]

  # Drop internal HH expansion columns not needed on persons
  dt_pers[, c("HHSize", "NKids", "rank") := NULL]

  # Lightweight aggregation (identity-phase: person counts are year-invariant)
  dt_pers[, AantalPersonenPerHuishouden := .N, by = HUISHOUDNR]
  dt_pers[, AantalKinderenPerHuishouden := sum(PLHH == "1"), by = HUISHOUDNR]
  hh_sz <- unique(dt_pers[, .(HUISHOUDNR, AantalPersonenPerHuishouden,
                               AantalKinderenPerHuishouden)])
  agg_cols <- c("AantalPersonenPerHuishouden", "AantalKinderenPerHuishouden")
  dt_hh[hh_sz, (agg_cols) := mget(agg_cols), on = "HUISHOUDNR"]


  # ==== PHASE 2: Year-specific attributes ====================================
  # Year-dependent seed: same person gets different gemeente, WOZ, indicators
  # each simulation year, but persons themselves are stable.
  set.seed(seed + year * 1000L)

  # ---- Object attributes (year-varying) ----
  woz_sd <- 0.45

  for (sfx in c("1Jan","31Dec")) {
    gem <- .rcat(N_OBJ, params$gem_codes, params$gem_probs)
    data.table::set(dt_obj, j = paste0("GemeenteCodeJJJJ",       sfx), value = gem)
    data.table::set(dt_obj, j = paste0("WijkCodeJJJJ",           sfx), value = paste0(gem, sprintf("%02d", sample(1:20, N_OBJ, replace=TRUE))))
    data.table::set(dt_obj, j = paste0("BuurtCodeJJJJ",          sfx), value = paste0(gem, sprintf("%04d", sample(1:200,N_OBJ, replace=TRUE))))
    data.table::set(dt_obj, j = paste0("VSLSoort",               sfx), value = .rcat(N_OBJ, names(params$vslsoort_p),  params$vslsoort_p))
    data.table::set(dt_obj, j = paste0("VBOWoningType",          sfx), value = .rcat(N_OBJ, names(params$woningtype_p),params$woningtype_p))
    data.table::set(dt_obj, j = paste0("VBOBouwJaarKlasse",      sfx), value = .rcat(N_OBJ, as.character(1:15),        params$bouwjaar_p))
    data.table::set(dt_obj, j = paste0("VBOOppervlakteKlasse",   sfx), value = .rcat(N_OBJ, names(params$opp_p),       params$opp_p))
    data.table::set(dt_obj, j = paste0("TypeEigenaar",           sfx), value = .rcat(N_OBJ, names(params$eigenaar_p),  params$eigenaar_p))
    data.table::set(dt_obj, j = paste0("VBOBouwjaar",            sfx), value = sample(1850L:year, N_OBJ, replace=TRUE))
    opp_vec <- as.integer(pmax(15L, round(stats::rlnorm(N_OBJ, log(85), 0.45))))
    data.table::set(dt_obj, j = paste0("VBOOppervlakte",         sfx), value = opp_vec)

    # WOZ: per-municipality mean from StatLine, conditional on dwelling size
    if (!is.null(params$woz_gem_means)) {
      woz_mean <- params$woz_gem_means[gem]
      woz_mean[is.na(woz_mean)] <- params$woz_national_mean
      woz_mu <- log(woz_mean) - woz_sd^2 / 2
    } else {
      woz_mu <- rep(log(params$woz_national_mean) - woz_sd^2 / 2, N_OBJ)
    }
    woz_mu <- woz_mu + 0.8 * log(opp_vec / 85)
    woz_val <- round(stats::rlnorm(N_OBJ, woz_mu, woz_sd * 0.7), -3L)
    data.table::set(dt_obj, j = paste0("WOZWaardeObjectBAG",      sfx), value = woz_val)
    data.table::set(dt_obj, j = paste0("WOZWaardeObjectBAGKlasse", sfx), value = .woz_to_klasse(woz_val))

    data.table::set(dt_obj, j = paste0("VBOStatus",              sfx), value = .rcat(N_OBJ, c("3","4","6"), c(0.10,0.85,0.05)))
    data.table::set(dt_obj, j = paste0("Indicator_VBOIsNieuwbouw",sfx),value = .rcat(N_OBJ, c("-","0","1"), c(0.01,0.96,0.03)))
    data.table::set(dt_obj, j = paste0("Indicator_VBOIsAanwezig", sfx),value = .rcat(N_OBJ, c("0","1"), c(0.02,0.98)))
    data.table::set(dt_obj, j = paste0("Indicator_VSLIsAanwezig", sfx),value = "1")
  }
  dt_obj[, PandID1Jan := strrep("9", 16L)]
  dt_obj[VBOWoningType1Jan == "05", PandID1Jan := .rand_id(.N, 16L)]
  dt_obj[, PandID31Dec := PandID1Jan]
  dt_obj[, Indicator_VBOIsGesloopt      := .rcat(.N, c("-","0","1"), c(0.01,0.98,0.01))]
  dt_obj[, Indicator_VBOIsTransformatie := .rcat(.N, c("-","0","1"), c(0.01,0.985,0.005))]
  dt_obj[, Indicator_VBOIsNieuwbouw     := .rcat(.N, c("-","0","1"), c(0.01,0.96,0.03))]
  dt_obj[, Indicator_VSLIsOntrokken     := .rcat(.N, c("-","0","1"), c(0.01,0.985,0.005))]
  dt_obj[, Indicator_VSLIsNieuw         := .rcat(.N, c("-","0","1"), c(0.01,0.97,0.02))]
  data.table::setkey(dt_obj, RINOBJECTNUMMER)

  # ---- Person indicators (year-varying) ----
  ind_specs <- list(
    c("Indicator_PersoonIsVerhuisd",                0.06),
    c("Indicator_PersoonIsGeboren",                 0.012),
    c("Indicator_PersoonIsOverleden",               0.010),
    c("Indicator_PersoonIsGeemigreerd",             0.008),
    c("Indicator_PersoonIsGeimmigreerd",            0.007),
    c("Indicator_PersoonIsAdministratiefAfgevoerd", 0.002),
    c("Indicator_PersoonIsAdministratiefOpgenomen", 0.002),
    c("Indicator_PersoonIsAanwezig1Jan",            0.99),
    c("Indicator_PersoonIsAanwezig31Dec",           0.99)
  )
  for (sp in ind_specs) {
    data.table::set(dt_pers, j = sp[[1L]],
      value = as.character(rbinom(N_PERS_actual, 1L, as.numeric(sp[[2L]]))))
  }

  # AantalKeerVerhuisd: sample only for the ~6% who moved
  dt_pers[, AantalKeerVerhuisd := 0L]
  dt_pers[Indicator_PersoonIsVerhuisd == "1",
    AantalKeerVerhuisd := sample(1:3, .N, replace = TRUE, prob = c(0.80, 0.15, 0.05))]

  # ---- Income & wealth (year-varying, correlated with WOZ) ----
  woz <- dt_obj$WOZWaardeObjectBAG1Jan
  woz_rank <- data.table::frank(woz, ties.method = "random") / (N_HH + 1)

  # BESTINKH: disposable income
  dt_hh[, BESTINKH := as.integer(pmax(5000L, pmin(250000L, round(
    stats::qlnorm(woz_rank, meanlog = 10.45, sdlog = 0.45) *
    exp(stats::rnorm(.N, 0, 0.25)), -2L))))]

  # BELIH: taxable income (higher than disposable)
  dt_hh[, BELIH := as.integer(round(BESTINKH * stats::runif(.N, 1.1, 1.4), -2L))]

  # GESTINKH: standardized income (equivalized by HH size)
  dt_hh[, GESTINKH := as.integer(round(
    BESTINKH / sqrt(pmax(1L, AantalPersonenPerHuishouden)), -2L))]

  # VERMHH: household wealth — correlated with WOZ rank, wider distribution
  verm_rank <- pmax(0.001, pmin(0.999, woz_rank + stats::rnorm(N_HH, 0, 0.15)))
  dt_hh[, VERMHH := as.integer(round(
    stats::qlnorm(verm_rank, meanlog = 11.0, sdlog = 0.8) - 50000, -2L))]

  # VROMHH: freely available wealth (fraction of total)
  dt_hh[, VROMHH := as.integer(round(VERMHH * stats::runif(.N, 0.3, 0.8), -2L))]

  # Percentile ranks (1-100)
  dt_hh[, P100HBEST := as.integer(ceiling(
    data.table::frank(BESTINKH, ties.method = "random") / .N * 100))]
  dt_hh[, P100HGEST := as.integer(ceiling(
    data.table::frank(GESTINKH, ties.method = "random") / .N * 100))]
  dt_hh[, P100HVERM := as.integer(ceiling(
    data.table::frank(VERMHH, ties.method = "random") / .N * 100))]
  dt_hh[, P100WELVAART := as.integer(ceiling(data.table::frank(
    data.table::frank(BESTINKH) + data.table::frank(VERMHH),
    ties.method = "random") / .N * 100))]

  # Reference persons (precomputed for lazy hh/obj enrichment)
  dt_ref <- dt_pers[dt_pers[, .I[1L], by = HUISHOUDNR]$V1]
  dt_ref[, LeeftijdRefPersoon := as.integer(year - GBAGeboorteJaar)]

  # Lightweight gemeente lookup for weighted sampling (avoids full obj->pers join)
  pers_gemeente <- dt_obj$GemeenteCodeJJJJ1Jan[
    match(dt_pers$RINOBJECTNUMMER, dt_obj$RINOBJECTNUMMER)]

  elapsed <- proc.time()[["elapsed"]] - t0
  message(sprintf("  Spine ready: %s persons, %s households, %s objects (%.1f s)",
                  format(N_PERS_actual, big.mark=","),
                  format(N_HH, big.mark=","),
                  format(N_OBJ, big.mark=","),
                  elapsed))

  list(pers = dt_pers, hh = dt_hh, obj = dt_obj,
       obj_raw = dt_obj, dt_ref = dt_ref,
       pers_gemeente = pers_gemeente,
       year = year, jan1 = jan1, dec31 = dec31,
       pers_spatial_enriched = FALSE,
       hh_enriched = FALSE,
       obj_enriched = FALSE)
}


# Columns added to dt_pers by the obj->pers spatial join
.PERS_SPATIAL_PREFIXES <- c(
  "GemeenteCodeJJJJ", "WijkCodeJJJJ", "BuurtCodeJJJJ",
  "VSLSoort", "TypeEigenaar", "VBOWoningType",
  "VBOBouwJaarKlasse", "VBOOppervlakteKlasse", "WOZWaardeObjectBAGKlasse")

# Check if a file spec needs pers_spatial enrichment
.spec_needs_pers_spatial <- function(spec) {
  if (spec$spine_table != "pers") return(FALSE)
  pats <- paste0("spine.pers.", .PERS_SPATIAL_PREFIXES)
  for (cs in c(spec$columns, spec$pre_compute)) {
    if (is.null(cs$source)) next
    for (p in pats) {
      if (startsWith(cs$source, p)) return(TRUE)
    }
  }
  FALSE
}

# Columns added to dt_hh by hh enrichment (ref-person + object merge)
.HH_ENRICHED_PREFIXES <- c(
  "RINPERSOON_Ref", "RINPERSOONS_Ref", "REFPERSOONHH_Ref",
  "PLHH_Ref", "GBAGeslachtsAanduiding_Ref", "LeeftijdRefPersoon",
  "VSLSoort", "WOZWaardeObjectBAGKlasse", "VBOBouwJaarKlasse",
  "VBOOppervlakteKlasse", "VBOWoningType", "TypeEigenaar", "GemeenteCodeJJJJ")

# Check if a file spec needs hh enrichment
.spec_needs_hh_enriched <- function(spec) {
  if (spec$spine_table != "hh") return(FALSE)
  pats <- paste0("spine.hh.", .HH_ENRICHED_PREFIXES)
  for (cs in c(spec$columns, spec$pre_compute)) {
    if (is.null(cs$source)) next
    for (p in pats) {
      if (startsWith(cs$source, p)) return(TRUE)
    }
  }
  FALSE
}

# Columns added to dt_obj by obj enrichment (kids + ref-person merge)
.OBJ_ENRICHED_COLS <- c(
  "AantalKinderenPerVSL", "LeeftijdJongsteKindPerVSL", "AantalPersonenPerVSL",
  "HUISHOUDNR", "DATUMAANVANGHH", "TYPHH", "AantalPersonenPerHuishouden",
  "RINPERSOON_Ref2", "RINPERSOONS_Ref2")

# Check if a file spec needs obj enrichment
.spec_needs_obj_enriched <- function(spec) {
  if (spec$spine_table != "obj") return(FALSE)
  pats <- paste0("spine.obj.", .OBJ_ENRICHED_COLS)
  for (cs in c(spec$columns, spec$pre_compute)) {
    if (is.null(cs$source)) next
    for (p in pats) {
      if (startsWith(cs$source, p)) return(TRUE)
    }
  }
  FALSE
}


# Lazy enrichment: build enriched spine tables on first access
.ensure_enriched <- function(which) {
  spine <- .sim_cache$spine
  if (is.null(spine)) stop("Spine not initialized")

  if (which == "pers_spatial" && !isTRUE(spine$pers_spatial_enriched)) {
    message("  [lazy] Object \u2192 person spatial join ...")
    dt_obj <- spine$obj_raw
    obj_value_cols <- c(
      paste0(c("GemeenteCodeJJJJ","WijkCodeJJJJ","BuurtCodeJJJJ","VSLSoort",
               "TypeEigenaar","VBOWoningType","VBOBouwJaarKlasse",
               "VBOOppervlakteKlasse","WOZWaardeObjectBAGKlasse"), "1Jan"),
      paste0(c("GemeenteCodeJJJJ","WijkCodeJJJJ","BuurtCodeJJJJ","VSLSoort",
               "TypeEigenaar","VBOWoningType","VBOBouwJaarKlasse",
               "VBOOppervlakteKlasse","WOZWaardeObjectBAGKlasse"), "31Dec"))
    spine$pers[dt_obj, (obj_value_cols) := mget(obj_value_cols),
               on = "RINOBJECTNUMMER"]
    spine$pers_spatial_enriched <- TRUE
  }

  if (which == "hh" && !isTRUE(spine$hh_enriched)) {
    message("  [lazy] Household enrichment (ref-person + object) ...")
    dt_ref <- spine$dt_ref
    dt_obj <- spine$obj_raw
    dt_hh  <- spine$hh

    # Join ref-person columns onto hh by reference
    ref_for_hh <- dt_ref[, .(HUISHOUDNR,
      RINPERSOON_Ref = RINPERSOON, RINPERSOONS_Ref = RINPERSOONS,
      REFPERSOONHH_Ref = REFPERSOONHH,
      PLHH_Ref = PLHH, GBAGeslachtsAanduiding_Ref = GBAGeslachtsAanduiding,
      LeeftijdRefPersoon)]
    ref_cols <- c("RINPERSOON_Ref", "RINPERSOONS_Ref", "REFPERSOONHH_Ref",
                  "PLHH_Ref", "GBAGeslachtsAanduiding_Ref", "LeeftijdRefPersoon")
    dt_hh[ref_for_hh, (ref_cols) := mget(ref_cols), on = "HUISHOUDNR"]

    # Join object columns onto hh by reference
    obj_value_cols <- c(
      paste0(c("VSLSoort","WOZWaardeObjectBAGKlasse","VBOBouwJaarKlasse",
               "VBOOppervlakteKlasse","VBOWoningType","TypeEigenaar",
               "GemeenteCodeJJJJ"), "1Jan"),
      paste0(c("VSLSoort","WOZWaardeObjectBAGKlasse","VBOBouwJaarKlasse",
               "VBOOppervlakteKlasse","VBOWoningType","TypeEigenaar",
               "GemeenteCodeJJJJ"), "31Dec"))
    dt_hh[dt_obj, (obj_value_cols) := mget(obj_value_cols),
           on = "RINOBJECTNUMMER"]

    spine$hh <- dt_hh
    spine$hh_enriched <- TRUE
  }

  if (which == "obj" && !isTRUE(spine$obj_enriched)) {
    message("  [lazy] Object enrichment (kids + ref-person) ...")
    dt_pers <- spine$pers
    dt_obj  <- data.table::copy(spine$obj_raw)
    dt_ref  <- spine$dt_ref
    year    <- spine$year

    obj_kids <- dt_pers[, .(
      AantalKinderenPerVSL = sum(PLHH == "1"),
      LeeftijdJongsteKindPerVSL = if (any(PLHH == "1"))
        min(as.integer(year) - GBAGeboorteJaar[PLHH == "1"]) else 99L,
      AantalPersonenPerVSL = .N
    ), by = RINOBJECTNUMMER]

    # Join kids aggregation onto obj by reference
    kids_cols <- c("AantalKinderenPerVSL", "LeeftijdJongsteKindPerVSL",
                   "AantalPersonenPerVSL")
    dt_obj[obj_kids, (kids_cols) := mget(kids_cols), on = "RINOBJECTNUMMER"]
    dt_obj[is.na(AantalKinderenPerVSL), AantalKinderenPerVSL := 0L]
    dt_obj[is.na(LeeftijdJongsteKindPerVSL), LeeftijdJongsteKindPerVSL := 99L]
    dt_obj[is.na(AantalPersonenPerVSL), AantalPersonenPerVSL := 0L]

    # Join ref-person columns onto obj by reference
    ref_for_obj <- dt_ref[, .(RINOBJECTNUMMER,
      HUISHOUDNR, DATUMAANVANGHH, TYPHH, AantalPersonenPerHuishouden,
      RINPERSOON_Ref2 = RINPERSOON, RINPERSOONS_Ref2 = RINPERSOONS)]
    ref_cols <- c("HUISHOUDNR", "DATUMAANVANGHH", "TYPHH",
                  "AantalPersonenPerHuishouden",
                  "RINPERSOON_Ref2", "RINPERSOONS_Ref2")
    dt_obj[ref_for_obj, (ref_cols) := mget(ref_cols), on = "RINOBJECTNUMMER"]

    spine$obj <- dt_obj
    spine$obj_enriched <- TRUE
  }

  .sim_cache$spine <- spine
  .wb$spine <- spine
  spine
}
