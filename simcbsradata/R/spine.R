.wb_build_spine <- function(n_persons, params, seed, year) {
  year <- as.integer(year)
  set.seed(seed)
  t0 <- proc.time()[["elapsed"]]
  .stage <- function(i, n, label) {
    message(sprintf("  [%d/%d] %s ...", i, n, label))
  }

  jan1  <- as.Date(paste0(year, "-01-01"))
  dec31 <- as.Date(paste0(year, "-12-31"))

  # ---- Objects ----------------------------------------------------------------
  N_HH <- round(n_persons / params$avg_hh_size)
  N_OBJ <- N_HH

  message(sprintf("  Building spine: %s persons / %s households / %s objects",
                  format(n_persons, big.mark=","),
                  format(N_HH, big.mark=","),
                  format(N_OBJ, big.mark=",")))
  .stage(1L, 5L, "Objects")

  dt_obj <- data.table::data.table(
    RINOBJECTNUMMER   = .rand_id(N_OBJ, 16L),
    SOORTOBJECTNUMMER = .rcat(N_OBJ, names(params$soortobj_p), params$soortobj_p)
  )

  for (sfx in c("1Jan","31Dec")) {
    gem <- .rcat(N_OBJ, params$gem_codes, params$gem_probs)
    data.table::set(dt_obj, j = paste0("GemeenteCodeJJJJ",       sfx), value = gem)
    data.table::set(dt_obj, j = paste0("WijkCodeJJJJ",           sfx), value = paste0(gem, sprintf("%02d", sample(1:20, N_OBJ, replace=TRUE))))
    data.table::set(dt_obj, j = paste0("BuurtCodeJJJJ",          sfx), value = paste0(gem, sprintf("%04d", sample(1:200,N_OBJ, replace=TRUE))))
    data.table::set(dt_obj, j = paste0("VSLSoort",               sfx), value = .rcat(N_OBJ, names(params$vslsoort_p),  params$vslsoort_p))
    data.table::set(dt_obj, j = paste0("VBOWoningType",          sfx), value = .rcat(N_OBJ, names(params$woningtype_p),params$woningtype_p))
    data.table::set(dt_obj, j = paste0("VBOBouwJaarKlasse",      sfx), value = .rcat(N_OBJ, as.character(1:15),        params$bouwjaar_p))
    data.table::set(dt_obj, j = paste0("VBOOppervlakteKlasse",   sfx), value = .rcat(N_OBJ, names(params$opp_p),       params$opp_p))
    data.table::set(dt_obj, j = paste0("WOZWaardeObjectBAGKlasse",sfx),value = .rcat(N_OBJ, names(params$woz_p),       params$woz_p))
    data.table::set(dt_obj, j = paste0("TypeEigenaar",           sfx), value = .rcat(N_OBJ, names(params$eigenaar_p),  params$eigenaar_p))
    data.table::set(dt_obj, j = paste0("VBOBouwjaar",            sfx), value = sample(1850L:year, N_OBJ, replace=TRUE))
    data.table::set(dt_obj, j = paste0("VBOOppervlakte",         sfx), value = as.integer(pmax(15L, round(stats::rlnorm(N_OBJ, log(85), 0.45)))))
    data.table::set(dt_obj, j = paste0("WOZWaardeObjectBAG",     sfx), value = round(stats::rlnorm(N_OBJ, log(300000), 0.50), -3L))
    data.table::set(dt_obj, j = paste0("VBOStatus",              sfx), value = .rcat(N_OBJ, c("3","4","6"), c(0.10,0.85,0.05)))
    data.table::set(dt_obj, j = paste0("Indicator_VBOIsNieuwbouw",sfx),value = .rcat(N_OBJ, c("-","0","1"), c(0.01,0.96,0.03)))
    data.table::set(dt_obj, j = paste0("Indicator_VBOIsAanwezig", sfx),value = .rcat(N_OBJ, c("0","1"), c(0.02,0.98)))
    data.table::set(dt_obj, j = paste0("Indicator_VSLIsAanwezig", sfx),value = "1")
  }
  dt_obj[, PandID1Jan  := ifelse(VBOWoningType1Jan == "05", .rand_id(.N,16L), strrep("9",16L))]
  dt_obj[, PandID31Dec := PandID1Jan]
  dt_obj[, Indicator_VBOIsGesloopt      := .rcat(.N, c("-","0","1"), c(0.01,0.98,0.01))]
  dt_obj[, Indicator_VBOIsTransformatie := .rcat(.N, c("-","0","1"), c(0.01,0.985,0.005))]
  dt_obj[, Indicator_VBOIsNieuwbouw     := .rcat(.N, c("-","0","1"), c(0.01,0.96,0.03))]
  dt_obj[, Indicator_VSLIsOntrokken     := .rcat(.N, c("-","0","1"), c(0.01,0.985,0.005))]
  dt_obj[, Indicator_VSLIsNieuw         := .rcat(.N, c("-","0","1"), c(0.01,0.97,0.02))]
  data.table::setkey(dt_obj, RINOBJECTNUMMER)

  # ---- Households -------------------------------------------------------------
  .stage(2L, 5L, "Households")
  dt_hh <- data.table::data.table(
    HUISHOUDNR        = .seq_id(N_HH, 12L),
    TYPHH             = .rcat(N_HH, names(params$typhh_p), params$typhh_p),
    IMPUTATIECODEHH   = .rcat(N_HH, c("0","1"), c(0.95,0.05)),
    DATUMAANVANGHH    = .yyyymmdd(.rdate(N_HH, as.Date("2010-01-01"), jan1)),
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

  # ---- Persons (vectorized) ---------------------------------------------------
  .stage(3L, 5L, "Persons")
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

  # Birth year by person role
  dt_pers[,           GBAGeboorteJaar := year - sample(20L:75L, .N, replace = TRUE)]
  dt_pers[PLHH == "1", GBAGeboorteJaar := year - sample(0L:17L,  .N, replace = TRUE)]
  dt_pers[TYPHH == "8", GBAGeboorteJaar := year - sample(20L:85L, .N, replace = TRUE)]

  # Civil status by position in household
  dt_pers[,                          GBABurgerlijkeStaat := .rcat(.N, c("O","H","S","W"), c(0.55,0.30,0.08,0.07))]
  dt_pers[PLHH %in% c("4","6"),     GBABurgerlijkeStaat := .rcat(.N, c("H","P"), c(0.90,0.10))]
  dt_pers[PLHH == "1",              GBABurgerlijkeStaat := "O"]

  dt_pers[, GBAGeslachtsAanduiding := .rcat(N_PERS_actual, names(params$geslacht_p), params$geslacht_p)]
  dt_pers[, RINPERSOON  := .rand_id(N_PERS_actual, 9L)]
  dt_pers[, RINPERSOONS := "R"]
  dt_pers[, AanvangWoonduur := .yyyymmdd(.rdate(N_PERS_actual, as.Date("2010-01-01"), jan1))]

  # Movement indicators
  dt_pers[, Indicator_PersoonIsVerhuisd                := .rcat(N_PERS_actual, c("0","1"), c(0.94,0.06))]
  dt_pers[, AantalKeerVerhuisd                         := as.integer(
    ifelse(Indicator_PersoonIsVerhuisd=="1", sample(1:3, N_PERS_actual, replace=TRUE, prob=c(0.80,0.15,0.05)), 0L))]
  dt_pers[, Indicator_PersoonIsGeboren                 := .rcat(N_PERS_actual, c("0","1"), c(0.988,0.012))]
  dt_pers[, Indicator_PersoonIsOverleden               := .rcat(N_PERS_actual, c("0","1"), c(0.990,0.010))]
  dt_pers[, Indicator_PersoonIsGeemigreerd             := .rcat(N_PERS_actual, c("0","1"), c(0.992,0.008))]
  dt_pers[, Indicator_PersoonIsGeimmigreerd            := .rcat(N_PERS_actual, c("0","1"), c(0.993,0.007))]
  dt_pers[, Indicator_PersoonIsAdministratiefAfgevoerd := .rcat(N_PERS_actual, c("0","1"), c(0.998,0.002))]
  dt_pers[, Indicator_PersoonIsAdministratiefOpgenomen := .rcat(N_PERS_actual, c("0","1"), c(0.998,0.002))]
  dt_pers[, Indicator_PersoonIsAanwezig1Jan            := .rcat(N_PERS_actual, c("0","1"), c(0.01,0.99))]
  dt_pers[, Indicator_PersoonIsAanwezig31Dec           := .rcat(N_PERS_actual, c("0","1"), c(0.01,0.99))]

  # Drop internal HH expansion columns not needed on persons
  dt_pers[, c("HHSize", "NKids", "rank") := NULL]

  # ---- Aggregation + joins ----------------------------------------------------
  .stage(4L, 5L, "Aggregation + joins")
  # Household sizes from the expanded person table
  hh_sz <- dt_pers[, .(
    AantalPersonenPerHuishouden = .N,
    AantalKinderenPerHuishouden = sum(PLHH == "1")
  ), by = HUISHOUDNR]
  dt_pers <- merge(dt_pers, hh_sz, by = "HUISHOUDNR")
  dt_hh   <- merge(dt_hh,   hh_sz, by = "HUISHOUDNR")
  data.table::setkey(dt_pers, RINPERSOON)

  # Join spatial/characteristic object columns onto persons
  obj_join_cols <- c("RINOBJECTNUMMER",
    paste0(c("GemeenteCodeJJJJ","WijkCodeJJJJ","BuurtCodeJJJJ","VSLSoort",
             "TypeEigenaar","VBOWoningType","VBOBouwJaarKlasse",
             "VBOOppervlakteKlasse","WOZWaardeObjectBAGKlasse"), "1Jan"),
    paste0(c("GemeenteCodeJJJJ","WijkCodeJJJJ","BuurtCodeJJJJ","VSLSoort",
             "TypeEigenaar","VBOWoningType","VBOBouwJaarKlasse",
             "VBOOppervlakteKlasse","WOZWaardeObjectBAGKlasse"), "31Dec"))
  dt_pers <- merge(dt_pers, dt_obj[, ..obj_join_cols], by="RINOBJECTNUMMER")

  # ---- Reference persons + final assembly ------------------------------------
  .stage(5L, 5L, "Reference persons + final assembly")
  dt_ref <- dt_pers[dt_pers[, .I[1L], by = HUISHOUDNR]$V1]
  dt_ref[, LeeftijdRefPersoon := as.integer(year - GBAGeboorteJaar)]

  # Build spine$hh: HH + ref-person + object data, one row per HUISHOUDNR
  ref_for_hh <- dt_ref[, .(HUISHOUDNR,
    RINPERSOON_Ref = RINPERSOON, RINPERSOONS_Ref = RINPERSOONS,
    REFPERSOONHH_Ref = REFPERSOONHH,
    PLHH_Ref = PLHH, GBAGeslachtsAanduiding_Ref = GBAGeslachtsAanduiding,
    LeeftijdRefPersoon)]
  dt_hh2 <- merge(dt_hh, ref_for_hh, by="HUISHOUDNR")

  ref_obj_cols <- c("RINOBJECTNUMMER",
    paste0(c("VSLSoort","WOZWaardeObjectBAGKlasse","VBOBouwJaarKlasse",
             "VBOOppervlakteKlasse","VBOWoningType","TypeEigenaar","GemeenteCodeJJJJ"), "1Jan"),
    paste0(c("VSLSoort","WOZWaardeObjectBAGKlasse","VBOBouwJaarKlasse",
             "VBOOppervlakteKlasse","VBOWoningType","TypeEigenaar","GemeenteCodeJJJJ"), "31Dec"))
  dt_hh2 <- merge(dt_hh2, dt_obj[, ..ref_obj_cols], by="RINOBJECTNUMMER")

  # Build spine$obj: object + children + ref-person + HH link
  obj_kids <- dt_pers[, .(
    AantalKinderenPerVSL = sum(PLHH=="1"),
    LeeftijdJongsteKindPerVSL = if (any(PLHH=="1"))
      min(as.integer(year) - GBAGeboorteJaar[PLHH=="1"]) else 99L,
    AantalPersonenPerVSL = .N
  ), by=RINOBJECTNUMMER]

  ref_for_obj <- dt_ref[, .(RINOBJECTNUMMER,
    HUISHOUDNR, DATUMAANVANGHH, TYPHH, AantalPersonenPerHuishouden,
    RINPERSOON_Ref2 = RINPERSOON, RINPERSOONS_Ref2 = RINPERSOONS)]
  dt_obj2 <- merge(dt_obj, obj_kids,    by="RINOBJECTNUMMER", all.x=TRUE)
  dt_obj2 <- merge(dt_obj2, ref_for_obj, by="RINOBJECTNUMMER", all.x=TRUE)
  dt_obj2[is.na(AantalKinderenPerVSL), AantalKinderenPerVSL := 0L]
  dt_obj2[is.na(LeeftijdJongsteKindPerVSL), LeeftijdJongsteKindPerVSL := 99L]
  dt_obj2[is.na(AantalPersonenPerVSL), AantalPersonenPerVSL := 0L]

  elapsed <- proc.time()[["elapsed"]] - t0
  message(sprintf("  Spine ready: %s persons, %s households, %s objects (%.1f s)",
                  format(N_PERS_actual, big.mark=","),
                  format(N_HH, big.mark=","),
                  format(N_OBJ, big.mark=","),
                  elapsed))

  list(pers=dt_pers, hh=dt_hh2, obj=dt_obj2,
       year=year, jan1=jan1, dec31=dec31)
}
