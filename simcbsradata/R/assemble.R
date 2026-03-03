# Recognised file types (normalised to a key)
.WB_FILES <- c(
  sleutel        = "WoonbaseSleutelbestand",
  kenmerken_pers = "WoonbaseKenmerkenPersonen",
  kenmerken_hh   = "WoonbaseKenmerkenHuishoudens",
  kenmerken_obj  = "WoonbaseKenmerkenWoonruimten",
  populatie_pers = "WoonbasePopulatiePersonen",
  populatie_hh   = "WoonbasePopulatieHuishoudens",
  populatie_obj  = "WoonbasePopulatieWoonruimten"
)

.wb_parse_file <- function(file) {
  base <- tools::file_path_sans_ext(basename(file))
  # Extract year from {DatasetName}{YYYY}V{N} pattern
  m <- regmatches(base, regexec("^(.+?)(\\d{4})V\\d+$", base))[[1L]]
  if (length(m) == 3L) {
    dataset_name <- m[2L]
    file_year    <- as.integer(m[3L])
  } else {
    dataset_name <- base
    file_year    <- NULL
  }
  # Exact match against the 7 CBS dataset names (case-sensitive)
  idx <- match(dataset_name, .WB_FILES)
  if (!is.na(idx)) return(list(type = names(.WB_FILES)[idx], year = file_year))
  NULL
}

.wb_unit <- function(file_type) {
  switch(file_type,
    sleutel        = , kenmerken_pers = , populatie_pers = "person",
    kenmerken_hh   = , populatie_hh   =                   "household",
    kenmerken_obj  = , populatie_obj  =                   "object")
}


.wb_assemble <- function(file_type, spine, col_q = NULL) {

  p  <- spine$pers
  h  <- spine$hh
  o  <- spine$obj
  yr <- spine$year
  j1 <- .yyyymmdd(spine$jan1)
  d31<- .yyyymmdd(spine$dec31)

  # Trim dt to only the requested columns; no-op when col_q is NULL.
  .subset_cols <- function(dt) {
    if (is.null(col_q) || rlang::quo_is_null(col_q)) return(dt)
    sel <- tryCatch(
      names(tidyselect::eval_select(col_q, dt)),
      error = function(e) {
        cs <- eval(rlang::quo_get_expr(col_q))
        intersect(as.character(cs), names(dt))
      })
    dt[, sel, with = FALSE]
  }

  switch(file_type,

    # ---- Sleutelbestand -------------------------------------------------------
    sleutel = {
      REDEN_B <- c("ADR","GEB","HH","IMM","OBJ","OPN","V")
      REDEN_P <- c(0.20,0.05,0.30,0.05,0.10,0.02,0.28)
      dt <- p[, .(RINPERSOONS, RINPERSOON, REFPERSOONHH, PLHH, HUISHOUDNR,
                  DATUMAANVANGHH, TYPHH, IMPUTATIECODEHH,
                  SOORTOBJECTNUMMER, RINOBJECTNUMMER,
                  INVOORRAAD="1", VBOVOORRAADTYPE="0",
                  BEGINGELDIGHEID=j1, EINDGELDIGHEID=d31,
                  REDENBEGINGELDIGHEID=.rcat(.N, REDEN_B, REDEN_P),
                  REDENEINDGELDIGHEID="NVT")]
      dt <- .subset_cols(dt)
      .lbl_if(dt, "TYPHH",           .M$TYPHH,           "Type huishouden")
      .lbl_if(dt, "PLHH",            .M$PLHH,            "Plaats in huishouden")
      .lbl_if(dt, "REFPERSOONHH",    .M$REFPERSOONHH,    "Referentiepersoon")
      .lbl_if(dt, "IMPUTATIECODEHH", .M$IMPUTATIECODEHH, "Huishouden geimputeerd")
      .lbl_if(dt, "INVOORRAAD",      .M$INVOORRAAD,      "In de voorraad")
      .lbl_if(dt, "VBOVOORRAADTYPE", .M$VBOVOORRAADTYPE, "Voorraadtype VBO")
      dt
    },

    # ---- KenmerkenPersonen ----------------------------------------------------
    kenmerken_pers = {
      dt <- p[, .(RINPERSOON, RINPERSOONS,
                  GBABurgerlijkeStaat1Jan=GBABurgerlijkeStaat, GBABurgerlijkeStaat31Dec=GBABurgerlijkeStaat,
                  GBAGeboorteJaar1Jan=GBAGeboorteJaar, GBAGeboorteJaar31Dec=GBAGeboorteJaar,
                  GBAGeslachtsAanduiding1Jan=GBAGeslachtsAanduiding, GBAGeslachtsAanduiding31Dec=GBAGeslachtsAanduiding,
                  GemeenteCodeJJJJ1Jan, WijkCodeJJJJ1Jan, BuurtCodeJJJJ1Jan,
                  GemeenteCodeJJJJ31Dec, WijkCodeJJJJ31Dec, BuurtCodeJJJJ31Dec,
                  PLHH1Jan=PLHH, PLHH31Dec=PLHH,
                  RINOBJECTNUMMER1Jan=RINOBJECTNUMMER, RINOBJECTNUMMER31Dec=RINOBJECTNUMMER,
                  SOORTOBJECTNUMMER1Jan=SOORTOBJECTNUMMER, SOORTOBJECTNUMMER31Dec=SOORTOBJECTNUMMER,
                  AanvangWoonduur1Jan=AanvangWoonduur, AanvangWoonduur31Dec=AanvangWoonduur)]
      dt <- .subset_cols(dt)
      for (sfx in c("1Jan","31Dec")) {
        .lbl_if(dt, paste0("GBAGeslachtsAanduiding",sfx), .M$GESLACHT, "Geslachtsaanduiding GBA")
        .lbl_if(dt, paste0("PLHH",sfx), .M$PLHH, "Plaats in het huishouden")
      }
      dt
    },

    # ---- KenmerkenHuishoudens -------------------------------------------------
    kenmerken_hh = {
      dt <- h[, .(HUISHOUDNR1Jan=HUISHOUDNR, HUISHOUDNR31Dec=HUISHOUDNR,
                  DatumAanvangHH1Jan=DATUMAANVANGHH, DatumAanvangHH31Dec=DATUMAANVANGHH,
                  IMPUTATIECODEHH1Jan=IMPUTATIECODEHH, IMPUTATIECODEHH31Dec=IMPUTATIECODEHH,
                  RefPersoonHH1Jan=REFPERSOONHH_Ref, RefPersoonHH31Dec=REFPERSOONHH_Ref,
                  RINPERSOON=RINPERSOON_Ref, RINPERSOONS=RINPERSOONS_Ref,
                  TYPHH1Jan=TYPHH, TYPHH31Dec=TYPHH,
                  AantalKinderenPerHuishouden1Jan=AantalKinderenPerHuishouden,
                  AantalKinderenPerHuishouden31Dec=AantalKinderenPerHuishouden,
                  AantalPersonenPerHuishouden1Jan=AantalPersonenPerHuishouden,
                  AantalPersonenPerHuishouden31Dec=AantalPersonenPerHuishouden)]
      dt <- .subset_cols(dt)
      for (sfx in c("1Jan","31Dec")) {
        .lbl_if(dt, paste0("TYPHH",sfx), .M$TYPHH, "Type huishouden")
        .lbl_if(dt, paste0("IMPUTATIECODEHH",sfx), .M$IMPUTATIECODEHH, "Huishouden geimputeerd")
        .lbl_if(dt, paste0("RefPersoonHH",sfx), .M$REFPERSOONHH, "Referentiepersoon")
      }
      dt
    },

    # ---- KenmerkenWoonruimten -------------------------------------------------
    kenmerken_obj = {
      dt <- o[, .(RINOBJECTNUMMER, SOORTOBJECTNUMMER,
                  GemeenteCodeJJJJ1Jan, WijkCodeJJJJ1Jan, BuurtCodeJJJJ1Jan,
                  GemeenteCodeJJJJ31Dec, WijkCodeJJJJ31Dec, BuurtCodeJJJJ31Dec,
                  Indicator_VBOIsNieuwbouw1Jan, `Indicator_VBOIsNieuwbouwJJJJ-1`=Indicator_VBOIsNieuwbouw1Jan,
                  VSLSoort1Jan, VSLSoort31Dec,
                  VBOWoningType1Jan, VBOWoningType31Dec,
                  VBOBouwjaar1Jan, VBOBouwjaar31Dec,
                  VBOOppervlakte1Jan, VBOOppervlakte31Dec,
                  WOZWaardeObjectBAG1Jan, WOZWaardeObjectBAG31Dec,
                  VBOStatus1Jan, VBOStatus31Dec)]
      dt <- .subset_cols(dt)
      for (sfx in c("1Jan","31Dec")) {
        .lbl_if(dt, paste0("VSLSoort",sfx), .M$VSLSOORT, "Soort VSL")
        .lbl_if(dt, paste0("VBOWoningType",sfx), .M$WONINGTYPE, "Woningtype VBO")
        .lbl_if(dt, paste0("VBOStatus",sfx), .M$VBOSTATUS, "Status VBO")
      }
      # Indicator_VBOIsNieuwbouw has only 1Jan and JJJJ-1 variants in this file
      .lbl_if(dt, "Indicator_VBOIsNieuwbouw1Jan", .M$INDICATOR, "VBO is nieuwbouw")
      .lbl_if(dt, "Indicator_VBOIsNieuwbouwJJJJ-1", .M$INDICATOR, "VBO is nieuwbouw (vorig jaar)")
      dt
    },

    # ---- PopulatiePersonen ----------------------------------------------------
    populatie_pers = {
      dt <- p[, .(RINPERSOON, RINPERSOONS,
                  RefPersoonHH1Jan=REFPERSOONHH, RefPersoonHH31Dec=REFPERSOONHH,
                  HUISHOUDNR1Jan=HUISHOUDNR, HUISHOUDNR31Dec=HUISHOUDNR,
                  DATUMAANVANGHH1Jan=DATUMAANVANGHH, DATUMAANVANGHH31Dec=DATUMAANVANGHH,
                  IMPUTATIECODEHH1Jan=IMPUTATIECODEHH, IMPUTATIECODEHH31Dec=IMPUTATIECODEHH,
                  RINOBJECTNUMMER1Jan=RINOBJECTNUMMER, RINOBJECTNUMMER31Dec=RINOBJECTNUMMER,
                  SOORTOBJECTNUMMER1Jan=SOORTOBJECTNUMMER, SOORTOBJECTNUMMER31Dec=SOORTOBJECTNUMMER,
                  Indicator_PersoonIsGeboren, Indicator_PersoonIsOverleden,
                  Indicator_PersoonIsGeemigreerd, Indicator_PersoonIsAdministratiefAfgevoerd,
                  Indicator_PersoonIsGeimmigreerd, Indicator_PersoonIsAdministratiefOpgenomen,
                  Indicator_PersoonIsVerhuisd, Indicator_PersoonIsAanwezig1Jan, Indicator_PersoonIsAanwezig31Dec,
                  AantalKeerVerhuisd,
                  PLHH1Jan=PLHH, PLHH31Dec=PLHH, TYPHH1Jan=TYPHH, TYPHH31Dec=TYPHH,
                  GBAGeslachtsAanduiding1Jan=GBAGeslachtsAanduiding, GBAGeslachtsAanduiding31Dec=GBAGeslachtsAanduiding,
                  GBAGeboorteJaar1Jan=GBAGeboorteJaar, GBAGeboorteJaar31Dec=GBAGeboorteJaar,
                  GBABurgerlijkeStaat1Jan=GBABurgerlijkeStaat, GBABurgerlijkeStaat31Dec=GBABurgerlijkeStaat,
                  AantalPersonenPerHuishouden1Jan=AantalPersonenPerHuishouden,
                  AantalPersonenPerHuishouden31Dec=AantalPersonenPerHuishouden,
                  GemeenteCodeJJJJ1Jan, GemeenteCodeJJJJ31Dec,
                  VSLSoort1Jan, VSLSoort31Dec, TypeEigenaar1Jan, TypeEigenaar31Dec,
                  VBOWoningType1Jan, VBOWoningType31Dec, VBOBouwJaarKlasse1Jan, VBOBouwJaarKlasse31Dec,
                  VBOOppervlakteKlasse1Jan, VBOOppervlakteKlasse31Dec,
                  WOZWaardeObjectBAGKlasse1Jan, WOZWaardeObjectBAGKlasse31Dec)]
      dt <- .subset_cols(dt)
      ind_cols <- grep("^Indicator_", names(dt), value=TRUE)
      for (sfx in c("1Jan","31Dec")) {
        .lbl_if(dt, paste0("PLHH",sfx),   .M$PLHH,    "Plaats in het huishouden")
        .lbl_if(dt, paste0("TYPHH",sfx),  .M$TYPHH,   "Type huishouden")
        .lbl_if(dt, paste0("GBAGeslachtsAanduiding",sfx), .M$GESLACHT, "Geslachtsaanduiding GBA")
        .lbl_if(dt, paste0("IMPUTATIECODEHH",sfx), .M$IMPUTATIECODEHH, "Huishouden geimputeerd")
        .lbl_if(dt, paste0("RefPersoonHH",sfx), .M$REFPERSOONHH, "Referentiepersoon")
        .lbl_if(dt, paste0("VSLSoort",sfx), .M$VSLSOORT, "Soort VSL")
        .lbl_if(dt, paste0("VBOWoningType",sfx), .M$WONINGTYPE, "Woningtype VBO")
        .lbl_if(dt, paste0("VBOBouwJaarKlasse",sfx), .M$BOUWJAARKLASSE, "Bouwjaarklass VBO")
        .lbl_if(dt, paste0("VBOOppervlakteKlasse",sfx), .M$OPPKLASSE, "Oppervlakteklasse VBO")
        .lbl_if(dt, paste0("WOZWaardeObjectBAGKlasse",sfx), .M$WOZKLASSE, "WOZ waardeklasse")
        .lbl_if(dt, paste0("TypeEigenaar",sfx), .M$TYPEIGENAAR, "Type eigenaar")
      }
      for (ic in ind_cols)
        data.table::set(dt, j=ic, value=.lbl(dt[[ic]], .M$INDICATOR, gsub("_"," ",ic)))
      dt
    },

    # ---- PopulatieHuishoudens -------------------------------------------------
    populatie_hh = {
      dt <- h[, .(HUISHOUDNR1Jan=HUISHOUDNR, HUISHOUDNR31Dec=HUISHOUDNR,
                  DATUMAANVANGHH1Jan=DATUMAANVANGHH, DATUMAANVANGHH31Dec=DATUMAANVANGHH,
                  IMPUTATIECODEHH1Jan=IMPUTATIECODEHH, IMPUTATIECODEHH31Dec=IMPUTATIECODEHH,
                  RINPERSOONS=RINPERSOONS_Ref, RINPERSOON=RINPERSOON_Ref,
                  RINOBJECTNUMMER1Jan=RINOBJECTNUMMER, RINOBJECTNUMMER31Dec=RINOBJECTNUMMER,
                  SOORTOBJECTNUMMER1Jan=SOORTOBJECTNUMMER, SOORTOBJECTNUMMER31Dec=SOORTOBJECTNUMMER,
                  TYPHH1Jan=TYPHH, TYPHH31Dec=TYPHH,
                  AantalPersonenPerHuishouden1Jan=AantalPersonenPerHuishouden,
                  AantalPersonenPerHuishouden31Dec=AantalPersonenPerHuishouden,
                  AantalKinderenPerHuishouden1Jan=AantalKinderenPerHuishouden,
                  AantalKinderenPerHuishouden31Dec=AantalKinderenPerHuishouden,
                  LeeftijdRefPersoon1Jan=LeeftijdRefPersoon, LeeftijdRefPersoon31Dec=LeeftijdRefPersoon,
                  PLHHRefPersoon1Jan=PLHH_Ref, PLHHRefPersoon31Dec=PLHH_Ref,
                  GBAGeslachtsaanduidingRefPersoon1Jan=GBAGeslachtsAanduiding_Ref,
                  GBAGeslachtsaanduidingRefPersoon31Dec=GBAGeslachtsAanduiding_Ref,
                  GemeenteCodeJJJJ1Jan, GemeenteCodeJJJJ31Dec,
                  VSLSoort1Jan, VSLSoort31Dec,
                  WOZWaardeObjectBAGKlasse1Jan, WOZWaardeObjectBAGKlasse31Dec,
                  VBOBouwJaarKlasse1Jan, VBOBouwJaarKlasse31Dec,
                  VBOOppervlakteKlasse1Jan, VBOOppervlakteKlasse31Dec,
                  VBOWoningType1Jan, VBOWoningType31Dec,
                  TypeEigenaar1Jan, TypeEigenaar31Dec,
                  Indicator_HHIsAanwezig1Jan="1", Indicator_HHIsAanwezig31Dec="1")]
      dt <- .subset_cols(dt)
      for (sfx in c("1Jan","31Dec")) {
        .lbl_if(dt, paste0("TYPHH",sfx), .M$TYPHH, "Type huishouden")
        .lbl_if(dt, paste0("IMPUTATIECODEHH",sfx), .M$IMPUTATIECODEHH, "Huishouden geimputeerd")
        .lbl_if(dt, paste0("PLHHRefPersoon",sfx), .M$PLHH, "Plaats ref persoon")
        .lbl_if(dt, paste0("GBAGeslachtsaanduidingRefPersoon",sfx), .M$GESLACHT, "Geslacht ref persoon")
        .lbl_if(dt, paste0("VSLSoort",sfx), .M$VSLSOORT, "Soort VSL")
        .lbl_if(dt, paste0("WOZWaardeObjectBAGKlasse",sfx), .M$WOZKLASSE, "WOZ waardeklasse")
        .lbl_if(dt, paste0("VBOBouwJaarKlasse",sfx), .M$BOUWJAARKLASSE, "Bouwjaarklass VBO")
        .lbl_if(dt, paste0("VBOOppervlakteKlasse",sfx), .M$OPPKLASSE, "Oppervlakteklasse VBO")
        .lbl_if(dt, paste0("VBOWoningType",sfx), .M$WONINGTYPE, "Woningtype VBO")
        .lbl_if(dt, paste0("TypeEigenaar",sfx), .M$TYPEIGENAAR, "Type eigenaar")
        .lbl_if(dt, paste0("Indicator_HHIsAanwezig",sfx), .M$INDICATOR, "HH aanwezig")
      }
      dt
    },

    # ---- PopulatieWoonruimten -------------------------------------------------
    populatie_obj = {
      o2 <- data.table::copy(o)
      o2[, n := AantalPersonenPerVSL]
      o2[, AantalPersonenPerVSLKlasse := data.table::fcase(
        n==0L,            "----", n==1L, "1", n==2L, "2",
        n==3L,            "3",    n==4L, "4", n==5L, "5",
        n %between% c(6,9),"6",   n>=10L,"7", default="----")]
      o2[, n := NULL]

      dt <- o2[, .(SOORTOBJECTNUMMER, RINOBJECTNUMMER,
                   PandID1Jan, PandID31Dec,
                   VSLSoort1Jan, VSLSoort31Dec,
                   HUISHOUDNR1Jan=HUISHOUDNR, HUISHOUDNR31Dec=HUISHOUDNR,
                   DATUMAANVANGHH1Jan=DATUMAANVANGHH, DATUMAANVANGHH31Dec=DATUMAANVANGHH,
                   RINPERSOONS_Ref1Jan=RINPERSOONS_Ref2, RINPERSOONS_Ref31Dec=RINPERSOONS_Ref2,
                   RINPERSOON_Ref1Jan=RINPERSOON_Ref2,  RINPERSOON_Ref31Dec=RINPERSOON_Ref2,
                   VBOWoningType1Jan, VBOWoningType31Dec,
                   VBOBouwJaarKlasse1Jan, VBOBouwJaarKlasse31Dec,
                   VBOOppervlakteKlasse1Jan, VBOOppervlakteKlasse31Dec,
                   WOZWaardeObjectBAGKlasse1Jan, WOZWaardeObjectBAGKlasse31Dec,
                   TypeEigenaar1Jan, TypeEigenaar31Dec,
                   AantalPersonenPerVSLKlasse1Jan=AantalPersonenPerVSLKlasse,
                   AantalPersonenPerVSLKlasse31Dec=AantalPersonenPerVSLKlasse,
                   AantalHuishoudensPerVSLKlasse1Jan="1", AantalHuishoudensPerVSLKlasse31Dec="1",
                   AantalKinderenPerVSL1Jan=AantalKinderenPerVSL,
                   AantalKinderenPerVSL31Dec=AantalKinderenPerVSL,
                   LeeftijdJongsteKindPerVSL1Jan=LeeftijdJongsteKindPerVSL,
                   LeeftijdJongsteKindPerVSL31Dec=LeeftijdJongsteKindPerVSL,
                   TYPHH1Jan=TYPHH, TYPHH31Dec=TYPHH,
                   GemeenteCodeJJJJ1Jan, GemeenteCodeJJJJ31Dec,
                   Indicator_VBOIsAanwezig1Jan, Indicator_VBOIsAanwezig31Dec,
                   Indicator_VSLIsAanwezig1Jan, Indicator_VSLIsAanwezig31Dec,
                   Indicator_VBOIsGesloopt, Indicator_VSLIsOntrokken,
                   Indicator_VBOIsTransformatie, Indicator_VBOIsNieuwbouw, Indicator_VSLIsNieuw)]
      dt <- .subset_cols(dt)
      ind_cols <- grep("^Indicator_", names(dt), value=TRUE)
      for (sfx in c("1Jan","31Dec")) {
        .lbl_if(dt, paste0("VSLSoort",sfx), .M$VSLSOORT, "Soort VSL")
        .lbl_if(dt, paste0("VBOWoningType",sfx), .M$WONINGTYPE, "Woningtype VBO")
        .lbl_if(dt, paste0("VBOBouwJaarKlasse",sfx), .M$BOUWJAARKLASSE, "Bouwjaarklass VBO")
        .lbl_if(dt, paste0("VBOOppervlakteKlasse",sfx), .M$OPPKLASSE, "Oppervlakteklasse VBO")
        .lbl_if(dt, paste0("WOZWaardeObjectBAGKlasse",sfx), .M$WOZKLASSE, "WOZ waardeklasse")
        .lbl_if(dt, paste0("TypeEigenaar",sfx), .M$TYPEIGENAAR, "Type eigenaar")
        .lbl_if(dt, paste0("TYPHH",sfx), .M$TYPHH, "Type huishouden")
        .lbl_if(dt, paste0("AantalPersonenPerVSLKlasse",sfx), .M$PERSKLASSE, "Aantal personen per VSL klasse")
        .lbl_if(dt, paste0("AantalHuishoudensPerVSLKlasse",sfx), .M$HHKLASSE, "Aantal HH per VSL klasse")
      }
      for (ic in ind_cols)
        data.table::set(dt, j=ic, value=.lbl(dt[[ic]], .M$INDICATOR, gsub("_"," ",ic)))
      dt
    }
  )
}
