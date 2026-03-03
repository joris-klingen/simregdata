# 020_simulate_woonbase.R
# Generates synthetic Woonbase microdata for all 7 CBS files, based on the
# variable documentation in data/raw/mdata_pdfs_woonbase/.
#
# Output: parquet files in data/interim/woonbase_sim/{SIM_YEAR}/
#   WoonbaseSleutel{year}V1.parquet
#   WoonbaseKenmerkenPersonen{year}V1.parquet
#   WoonbaseKenmerkenHuishoudens{year}V1.parquet
#   WoonbaseKenmerkenWoonruimten{year}V1.parquet
#   WoonbasePopulatiePersonen{year}V1.parquet
#   WoonbasePopulatieHuishoudens{year}V1.parquet
#   WoonbasePopulatieWoonruimten{year}V1.parquet

library(data.table)
library(arrow)


# Parameters ----

set.seed(42)
SIM_YEAR <- 2023L
N_HH     <- 4000L    # target households; final person count ~8-10k

out_dir <- file.path("data/interim/woonbase_sim", SIM_YEAR)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

jan1  <- as.Date(paste0(SIM_YEAR, "-01-01"))
dec31 <- as.Date(paste0(SIM_YEAR, "-12-31"))


# Helper functions ----

# Sequential zero-padded ID strings
seq_ids <- function(n, digits) formatC(seq_len(n), width = digits, flag = "0")

# Random 9-digit person IDs (unique)
rand_person_ids <- function(n) formatC(sample.int(999999999L, n, replace = FALSE), width = 9, flag = "0")

# Weighted random categorical draw
rcat <- function(n, vals, probs = NULL) sample(vals, n, replace = TRUE, prob = probs)

# YYYYMMDD date strings
yyyymmdd <- function(d) format(d, "%Y%m%d")

# Random dates (uniform) between two dates
rdate <- function(n, from, to) {
  as.Date(sample(as.integer(from):as.integer(to), n, replace = TRUE),
          origin = "1970-01-01")
}

# Write a data.table to parquet and report
write_sim <- function(dt, name) {
  path <- file.path(out_dir, paste0(name, ".parquet"))
  write_parquet(dt, path)
  cat(sprintf("  %-55s %d rows x %d cols\n", paste0(name, ".parquet"), nrow(dt), ncol(dt)))
}


# Shared value sets ----

SOORTOBJ  <- list(v = c("B","H","D","O"),        p = c(0.90,0.04,0.05,0.01))
TYPHH     <- list(v = c("1","2","3","4","5","6","7","8"),
                  p = c(0.34,0.09,0.19,0.05,0.19,0.07,0.04,0.02))
VSLSOORT  <- list(v = c("1","2","3","4","5","6"), p = c(0.88,0.02,0.03,0.01,0.04,0.02))
WONINGTYPE<- list(v = c("00","01","02","03","04","05","99"),
                  p = c(0.01,0.15,0.11,0.14,0.29,0.29,0.01))
BOUWJAAR_KL <- list(v = as.character(1:15),
                    p = c(0.05,0.06,0.07,0.08,0.10,0.12,0.12,0.10,0.10,0.09,0.05,0.04,0.01,0.005,0.005))
OPP_KL    <- list(v = c("1","2","3","4","5","6","9"), p = c(0.10,0.25,0.25,0.20,0.12,0.05,0.03))
WOZ_KL    <- list(v = c("1","2","3","4","5","6","7","9"), p = c(0.15,0.30,0.25,0.14,0.07,0.04,0.03,0.02))
EIGENAAR  <- list(v = c("C","V","E","O","9"),    p = c(0.30,0.12,0.54,0.02,0.02))
GESLACHT  <- list(v = c("1","2"),                p = c(0.50,0.50))
BSTAT     <- list(v = c("O","H","P","S","SP","W","WP","--"),
                  p = c(0.45,0.38,0.05,0.05,0.01,0.04,0.01,0.01))
IMPUTATIE <- list(v = c("0","1"),                p = c(0.95,0.05))

# Typical CBS gemeentecodes (a sample of Dutch municipalities)
GEM_CODES <- sprintf("%04d", c(363,599,518,344,503,268,307,392,398,400,
                               14,15,16,17,18,19,20,21,22,23))


# Generate objects (woonruimten) ----
cat("Generating objects...\n")

N_OBJ <- N_HH   # one object per household (simplification)

dt_obj <- data.table(
  RINOBJECTNUMMER   = seq_ids(N_OBJ, 16),
  SOORTOBJECTNUMMER = rcat(N_OBJ, SOORTOBJ$v, SOORTOBJ$p)
)

for (sfx in c("1Jan", "31Dec")) {
  gem <- rcat(N_OBJ, GEM_CODES)
  set(dt_obj, j = paste0("GemeenteCodeJJJJ", sfx), value = gem)
  set(dt_obj, j = paste0("WijkCodeJJJJ",     sfx), value = paste0(gem, sprintf("%02d", sample(1:20, N_OBJ, replace = TRUE))))
  set(dt_obj, j = paste0("BuurtCodeJJJJ",    sfx), value = paste0(gem, sprintf("%04d", sample(1:200, N_OBJ, replace = TRUE))))
  set(dt_obj, j = paste0("VSLSoort",         sfx), value = rcat(N_OBJ, VSLSOORT$v,   VSLSOORT$p))
  set(dt_obj, j = paste0("VBOWoningType",    sfx), value = rcat(N_OBJ, WONINGTYPE$v, WONINGTYPE$p))
  set(dt_obj, j = paste0("VBOBouwJaarKlasse",sfx), value = rcat(N_OBJ, BOUWJAAR_KL$v,BOUWJAAR_KL$p))
  set(dt_obj, j = paste0("VBOOppervlakteKlasse",      sfx), value = rcat(N_OBJ, OPP_KL$v, OPP_KL$p))
  set(dt_obj, j = paste0("WOZWaardeObjectBAGKlasse",  sfx), value = rcat(N_OBJ, WOZ_KL$v, WOZ_KL$p))
  set(dt_obj, j = paste0("TypeEigenaar",     sfx), value = rcat(N_OBJ, EIGENAAR$v,   EIGENAAR$p))
  # Kenmerken-specific raw values (continuous)
  set(dt_obj, j = paste0("VBOBouwjaar",         sfx), value = as.character(sample(1850:SIM_YEAR, N_OBJ, replace = TRUE)))
  set(dt_obj, j = paste0("VBOOppervlakte",      sfx), value = as.character(pmax(15L, round(rlnorm(N_OBJ, log(85), 0.45)))))
  set(dt_obj, j = paste0("WOZWaardeObjectBAG",  sfx), value = as.character(round(rlnorm(N_OBJ, log(300000), 0.5), -3)))
  set(dt_obj, j = paste0("VBOStatus",           sfx), value = rcat(N_OBJ, c("3","4","6"), c(0.10,0.85,0.05)))
  set(dt_obj, j = paste0("Indicator_VBOIsNieuwbouw", sfx), value = rcat(N_OBJ, c("-","0","1"), c(0.01,0.96,0.03)))
  set(dt_obj, j = paste0("Indicator_VBOIsAanwezig",  sfx), value = rcat(N_OBJ, c("0","1"), c(0.02,0.98)))
  set(dt_obj, j = paste0("Indicator_VSLIsAanwezig",  sfx), value = "1")
}

# Populatie-Woonruimten event indicators (whole-year, not per snapshot)
dt_obj[, Indicator_VBOIsGesloopt     := rcat(N_OBJ, c("-","0","1"), c(0.01,0.98,0.01))]
dt_obj[, Indicator_VBOIsTransformatie:= rcat(N_OBJ, c("-","0","1"), c(0.01,0.985,0.005))]
dt_obj[, Indicator_VBOIsNieuwbouw    := rcat(N_OBJ, c("-","0","1"), c(0.01,0.96,0.03))]
dt_obj[, Indicator_VSLIsOntrokken    := rcat(N_OBJ, c("-","0","1"), c(0.01,0.985,0.005))]
dt_obj[, Indicator_VSLIsNieuw        := rcat(N_OBJ, c("-","0","1"), c(0.01,0.97,0.02))]

# PandID for multi-family dwellings (meergezinswoning = woningtype "05")
dt_obj[, is_multi := VBOWoningType1Jan == "05"]
dt_obj[,  PandID1Jan  := ifelse(is_multi, seq_ids(N_OBJ, 16), strrep("9", 16))]
dt_obj[,  PandID31Dec := PandID1Jan]
dt_obj[,  is_multi    := NULL]


# Generate households ----
cat("Generating households...\n")

dt_hh <- data.table(
  HUISHOUDNR      = seq_ids(N_HH, 12),
  TYPHH           = rcat(N_HH, TYPHH$v, TYPHH$p),
  IMPUTATIECODEHH = rcat(N_HH, IMPUTATIE$v, IMPUTATIE$p),
  DATUMAANVANGHH  = yyyymmdd(rdate(N_HH, as.Date("2010-01-01"), jan1)),
  RINOBJECTNUMMER   = dt_obj$RINOBJECTNUMMER,
  SOORTOBJECTNUMMER = dt_obj$SOORTOBJECTNUMMER
)

# Household size based on type
dt_hh[TYPHH == "1",               HHSize := 1L]
dt_hh[TYPHH %in% c("2","3"),      HHSize := 2L]
dt_hh[TYPHH %in% c("4","5"),      HHSize := 2L + sample(1:3, .N, replace = TRUE, prob = c(0.50,0.35,0.15))]
dt_hh[TYPHH == "6",               HHSize := 1L + sample(1:3, .N, replace = TRUE, prob = c(0.55,0.30,0.15))]
dt_hh[TYPHH == "7",               HHSize := sample(2:5, .N, replace = TRUE)]
dt_hh[TYPHH == "8",               HHSize := sample(5:25, .N, replace = TRUE)]

dt_hh[, NKids := fcase(
  TYPHH %in% c("4","5"), pmax(0L, HHSize - 2L),
  TYPHH == "6",           pmax(0L, HHSize - 1L),
  default = 0L)]

dt_hh[, GBAGeslachtsaanduidingRefPersoon := rcat(N_HH, GESLACHT$v, GESLACHT$p)]


# Expand households to persons ----
cat("Expanding households to persons...\n")

# Returns PLHH values for each person in a household given its type
plhh_for_hh <- function(typhh, hh_size, n_kids) {
  switch(typhh,
    "1" = "2",
    "2" = rep("3", 2),
    "3" = rep("4", 2),
    "4" = c("5", "5", rep("1", n_kids)),
    "5" = c("6", "6", rep("1", n_kids)),
    "6" = c("7",      rep("1", n_kids)),
    "7" = c("8",      rep("9", hh_size - 1L)),
    "8" = rep("10", hh_size)
  )
}

rows <- mapply(function(hh_id, typhh, hh_size, n_kids) {
  plhh <- plhh_for_hh(typhh, hh_size, n_kids)
  n    <- length(plhh)

  is_kid  <- plhh == "1"
  is_inst <- typhh == "8"

  birth_yr <- ifelse(
    is_kid,  SIM_YEAR - sample(0:17, n, replace = TRUE),
    ifelse(is_inst,
      SIM_YEAR - sample(20:85, n, replace = TRUE),
      SIM_YEAR - sample(20:75, n, replace = TRUE)))

  ref_flag <- c(if (is_inst) "9" else "1", rep(if (is_inst) "9" else "0", n - 1L))

  bs <- ifelse(
    plhh %in% c("4","6"), rcat(n, c("H","P"), c(0.90,0.10)),
    ifelse(plhh == "1",   "O",
      rcat(n, c("O","H","S","W"), c(0.55,0.30,0.08,0.07))))

  data.table(
    HUISHOUDNR           = hh_id,
    PLHH                 = plhh,
    REFPERSOONHH         = ref_flag,
    GBAGeboorteJaar      = as.character(birth_yr),
    GBABurgerlijkeStaat  = bs,
    GBAGeslachtsAanduiding = rcat(n, GESLACHT$v, GESLACHT$p)
  )
},
dt_hh$HUISHOUDNR, dt_hh$TYPHH, dt_hh$HHSize, dt_hh$NKids,
SIMPLIFY = FALSE)

dt_pers <- rbindlist(rows)
N_PERS  <- nrow(dt_pers)
cat(sprintf("  %d persons in %d households\n", N_PERS, N_HH))

dt_pers[, RINPERSOON  := rand_person_ids(N_PERS)]
dt_pers[, RINPERSOONS := "R"]

# Join household fields onto persons
dt_pers <- merge(
  dt_pers,
  dt_hh[, .(HUISHOUDNR, TYPHH, IMPUTATIECODEHH, DATUMAANVANGHH,
             RINOBJECTNUMMER, SOORTOBJECTNUMMER)],
  by = "HUISHOUDNR")

# Actual household counts (may differ slightly from targets due to integer rounding)
hh_counts <- dt_pers[, .(
  AantalPersonenPerHuishouden = .N,
  AantalKinderenPerHuishouden = sum(PLHH == "1")
), by = HUISHOUDNR]

dt_pers <- merge(dt_pers, hh_counts, by = "HUISHOUDNR")
dt_hh   <- merge(dt_hh,   hh_counts, by = "HUISHOUDNR")

# Join object spatial/characteristic fields onto persons
obj_cols <- c("RINOBJECTNUMMER",
              paste0(c("GemeenteCodeJJJJ","WijkCodeJJJJ","BuurtCodeJJJJ",
                       "VSLSoort","TypeEigenaar","VBOWoningType",
                       "VBOBouwJaarKlasse","VBOOppervlakteKlasse",
                       "WOZWaardeObjectBAGKlasse"), "1Jan"),
              paste0(c("GemeenteCodeJJJJ","WijkCodeJJJJ","BuurtCodeJJJJ",
                       "VSLSoort","TypeEigenaar","VBOWoningType",
                       "VBOBouwJaarKlasse","VBOOppervlakteKlasse",
                       "WOZWaardeObjectBAGKlasse"), "31Dec"))
dt_pers <- merge(dt_pers, dt_obj[, ..obj_cols], by = "RINOBJECTNUMMER")

# Person movement indicators
dt_pers[, AanvangWoonduur            := yyyymmdd(rdate(N_PERS, as.Date("2010-01-01"), jan1))]
dt_pers[, Indicator_PersoonIsVerhuisd:= rcat(N_PERS, c("0","1"), c(0.94,0.06))]
dt_pers[, AantalKeerVerhuisd         := as.character(
  ifelse(Indicator_PersoonIsVerhuisd == "1",
         sample(1:3, N_PERS, replace = TRUE, prob = c(0.80,0.15,0.05)), 0L))]
dt_pers[, Indicator_PersoonIsGeboren                 := rcat(N_PERS, c("0","1"), c(0.988,0.012))]
dt_pers[, Indicator_PersoonIsOverleden               := rcat(N_PERS, c("0","1"), c(0.990,0.010))]
dt_pers[, Indicator_PersoonIsGeemigreerd             := rcat(N_PERS, c("0","1"), c(0.992,0.008))]
dt_pers[, Indicator_PersoonIsGeimmigreerd            := rcat(N_PERS, c("0","1"), c(0.993,0.007))]
dt_pers[, Indicator_PersoonIsAdministratiefAfgevoerd := rcat(N_PERS, c("0","1"), c(0.998,0.002))]
dt_pers[, Indicator_PersoonIsAdministratiefOpgenomen := rcat(N_PERS, c("0","1"), c(0.998,0.002))]
dt_pers[, Indicator_PersoonIsAanwezig1Jan            := rcat(N_PERS, c("0","1"), c(0.01, 0.99))]
dt_pers[, Indicator_PersoonIsAanwezig31Dec           := rcat(N_PERS, c("0","1"), c(0.01, 0.99))]

# Reference person per household (first member; for institutioneel: REFPERSOONHH="9")
dt_ref <- dt_pers[, .SD[1L], by = HUISHOUDNR]
dt_ref[, LeeftijdRefPersoon := as.character(SIM_YEAR - as.integer(GBAGeboorteJaar))]

# Join ref-person fields into dt_hh
dt_hh <- merge(dt_hh,
  dt_ref[, .(HUISHOUDNR, RINPERSOON, RINPERSOONS, PLHH,
             GBAGeslachtsAanduiding, LeeftijdRefPersoon)],
  by = "HUISHOUDNR")


# Build WoonbaseSleutel ----
cat("Building WoonbaseSleutel...\n")

REDEN_BEGIN <- c("ADR","GEB","HH","IMM","OBJ","OPN","V")
REDEN_BEGIN_P <- c(0.20,0.05,0.30,0.05,0.10,0.02,0.28)

dt_sleutel <- dt_pers[, .(
  RINPERSOONS,
  RINPERSOON,
  REFPERSOONHH,
  PLHH,
  HUISHOUDNR,
  DATUMAANVANGHH,
  TYPHH,
  IMPUTATIECODEHH,
  SOORTOBJECTNUMMER,
  RINOBJECTNUMMER,
  INVOORRAAD      = "1",
  VBOVOORRAADTYPE = "0",
  BEGINGELDIGHEID = yyyymmdd(jan1),
  EINDGELDIGHEID  = yyyymmdd(dec31),
  REDENBEGINGELDIGHEID = rcat(N_PERS, REDEN_BEGIN, REDEN_BEGIN_P),
  REDENEINDGELDIGHEID  = "NVT"
)]

write_sim(dt_sleutel, paste0("WoonbaseSleutel", SIM_YEAR, "V1"))


# Build WoonbaseKenmerkenPersonen ----
cat("Building WoonbaseKenmerkenPersonen...\n")

dt_kp <- dt_pers[, .(
  RINPERSOON,
  RINPERSOONS,
  GBABurgerlijkeStaat1Jan       = GBABurgerlijkeStaat,
  GBABurgerlijkeStaat31Dec      = GBABurgerlijkeStaat,
  GBAGeboorteJaar1Jan           = GBAGeboorteJaar,
  GBAGeboorteJaar31Dec          = GBAGeboorteJaar,
  GBAGeslachtsAanduiding1Jan    = GBAGeslachtsAanduiding,
  GBAGeslachtsAanduiding31Dec   = GBAGeslachtsAanduiding,
  GemeenteCodeJJJJ1Jan,
  WijkCodeJJJJ1Jan,
  BuurtCodeJJJJ1Jan,
  GemeenteCodeJJJJ31Dec,
  WijkCodeJJJJ31Dec,
  BuurtCodeJJJJ31Dec,
  PLHH1Jan                      = PLHH,
  PLHH31Dec                     = PLHH,
  RINOBJECTNUMMER1Jan           = RINOBJECTNUMMER,
  RINOBJECTNUMMER31Dec          = RINOBJECTNUMMER,
  SOORTOBJECTNUMMER1Jan         = SOORTOBJECTNUMMER,
  SOORTOBJECTNUMMER31Dec        = SOORTOBJECTNUMMER,
  AanvangWoonduur1Jan           = AanvangWoonduur,
  AanvangWoonduur31Dec          = AanvangWoonduur
)]

write_sim(dt_kp, paste0("WoonbaseKenmerkenPersonen", SIM_YEAR, "V1"))


# Build WoonbaseKenmerkenHuishoudens ----
cat("Building WoonbaseKenmerkenHuishoudens...\n")

dt_khh <- dt_ref[, .(
  HUISHOUDNR1Jan                   = HUISHOUDNR,
  HUISHOUDNR31Dec                  = HUISHOUDNR,
  DatumAanvangHH1Jan               = DATUMAANVANGHH,
  DatumAanvangHH31Dec              = DATUMAANVANGHH,
  IMPUTATIECODEHH1Jan              = IMPUTATIECODEHH,
  IMPUTATIECODEHH31Dec             = IMPUTATIECODEHH,
  RefPersoonHH1Jan                 = REFPERSOONHH,
  RefPersoonHH31Dec                = REFPERSOONHH,
  RINPERSOON,
  RINPERSOONS,
  TYPHH1Jan                        = TYPHH,
  TYPHH31Dec                       = TYPHH,
  AantalKinderenPerHuishouden1Jan  = as.character(AantalKinderenPerHuishouden),
  AantalKinderenPerHuishouden31Dec = as.character(AantalKinderenPerHuishouden),
  AantalPersonenPerHuishouden1Jan  = as.character(AantalPersonenPerHuishouden),
  AantalPersonenPerHuishouden31Dec = as.character(AantalPersonenPerHuishouden)
)]

write_sim(dt_khh, paste0("WoonbaseKenmerkenHuishoudens", SIM_YEAR, "V1"))


# Build WoonbaseKenmerkenWoonruimten ----
cat("Building WoonbaseKenmerkenWoonruimten...\n")

dt_kw <- dt_obj[, .(
  RINOBJECTNUMMER,
  SOORTOBJECTNUMMER,
  GemeenteCodeJJJJ1Jan,  WijkCodeJJJJ1Jan,  BuurtCodeJJJJ1Jan,
  GemeenteCodeJJJJ31Dec, WijkCodeJJJJ31Dec, BuurtCodeJJJJ31Dec,
  Indicator_VBOIsNieuwbouw1Jan,
  `Indicator_VBOIsNieuwbouwJJJJ-1` = rcat(N_OBJ, c("-","0","1"), c(0.01,0.96,0.03)),
  VSLSoort1Jan,          VSLSoort31Dec,
  VBOWoningType1Jan,     VBOWoningType31Dec,
  VBOBouwjaar1Jan,       VBOBouwjaar31Dec,
  VBOOppervlakte1Jan,    VBOOppervlakte31Dec,
  VBOStatus1Jan,         VBOStatus31Dec,
  WOZWaardeObjectBAG1Jan, WOZWaardeObjectBAG31Dec
)]

write_sim(dt_kw, paste0("WoonbaseKenmerkenWoonruimten", SIM_YEAR, "V1"))


# Build WoonbasePopulatiePersonen ----
cat("Building WoonbasePopulatiePersonen...\n")

dt_pp <- dt_pers[, .(
  RINPERSOON,
  RINPERSOONS,
  RefPersoonHH1Jan                         = REFPERSOONHH,
  RefPersoonHH31Dec                        = REFPERSOONHH,
  HUISHOUDNR1Jan                           = HUISHOUDNR,
  HUISHOUDNR31Dec                          = HUISHOUDNR,
  DATUMAANVANGHH1Jan                       = DATUMAANVANGHH,
  DATUMAANVANGHH31Dec                      = DATUMAANVANGHH,
  IMPUTATIECODEHH1Jan                      = IMPUTATIECODEHH,
  IMPUTATIECODEHH31Dec                     = IMPUTATIECODEHH,
  RINOBJECTNUMMER1Jan                      = RINOBJECTNUMMER,
  RINOBJECTNUMMER31Dec                     = RINOBJECTNUMMER,
  SOORTOBJECTNUMMER1Jan                    = SOORTOBJECTNUMMER,
  SOORTOBJECTNUMMER31Dec                   = SOORTOBJECTNUMMER,
  Indicator_PersoonIsGeboren,
  Indicator_PersoonIsOverleden,
  Indicator_PersoonIsGeemigreerd,
  Indicator_PersoonIsAdministratiefAfgevoerd,
  Indicator_PersoonIsGeimmigreerd,
  Indicator_PersoonIsAdministratiefOpgenomen,
  Indicator_PersoonIsVerhuisd,
  Indicator_PersoonIsAanwezig1Jan,
  Indicator_PersoonIsAanwezig31Dec,
  AantalKeerVerhuisd,
  PLHH1Jan                                 = PLHH,
  PLHH31Dec                                = PLHH,
  TYPHH1Jan                                = TYPHH,
  TYPHH31Dec                               = TYPHH,
  GBAGeslachtsAanduiding1Jan               = GBAGeslachtsAanduiding,
  GBAGeslachtsAanduiding31Dec              = GBAGeslachtsAanduiding,
  GBAGeboorteJaar1Jan                      = GBAGeboorteJaar,
  GBAGeboorteJaar31Dec                     = GBAGeboorteJaar,
  GBABurgerlijkeStaat1Jan                  = GBABurgerlijkeStaat,
  GBABurgerlijkeStaat31Dec                 = GBABurgerlijkeStaat,
  AantalPersonenPerHuishouden1Jan          = as.character(AantalPersonenPerHuishouden),
  AantalPersonenPerHuishouden31Dec         = as.character(AantalPersonenPerHuishouden),
  GemeenteCodeJJJJ1Jan,
  GemeenteCodeJJJJ31Dec,
  VSLSoort1Jan,          VSLSoort31Dec,
  TypeEigenaar1Jan,      TypeEigenaar31Dec,
  VBOWoningType1Jan,     VBOWoningType31Dec,
  VBOBouwJaarKlasse1Jan, VBOBouwJaarKlasse31Dec,
  VBOOppervlakteKlasse1Jan,      VBOOppervlakteKlasse31Dec,
  WOZWaardeObjectBAGKlasse1Jan,  WOZWaardeObjectBAGKlasse31Dec
)]

write_sim(dt_pp, paste0("WoonbasePopulatiePersonen", SIM_YEAR, "V1"))


# Build WoonbasePopulatieHuishoudens ----
cat("Building WoonbasePopulatieHuishoudens...\n")

# Merge object characteristics into ref-person table
ref_obj_cols <- c("RINOBJECTNUMMER",
                  paste0(c("VSLSoort","WOZWaardeObjectBAGKlasse",
                           "VBOBouwJaarKlasse","VBOOppervlakteKlasse",
                           "VBOWoningType","TypeEigenaar",
                           "GemeenteCodeJJJJ"), "1Jan"),
                  paste0(c("VSLSoort","WOZWaardeObjectBAGKlasse",
                           "VBOBouwJaarKlasse","VBOOppervlakteKlasse",
                           "VBOWoningType","TypeEigenaar",
                           "GemeenteCodeJJJJ"), "31Dec"))
dt_ref2 <- merge(dt_ref, dt_obj[, ..ref_obj_cols], by = "RINOBJECTNUMMER")

dt_ph <- dt_ref2[, .(
  HUISHOUDNR1Jan                           = HUISHOUDNR,
  HUISHOUDNR31Dec                          = HUISHOUDNR,
  DATUMAANVANGHH1Jan                       = DATUMAANVANGHH,
  DATUMAANVANGHH31Dec                      = DATUMAANVANGHH,
  IMPUTATIECODEHH1Jan                      = IMPUTATIECODEHH,
  IMPUTATIECODEHH31Dec                     = IMPUTATIECODEHH,
  RINPERSOONS,
  RINPERSOON,
  RINOBJECTNUMMER1Jan                      = RINOBJECTNUMMER,
  RINOBJECTNUMMER31Dec                     = RINOBJECTNUMMER,
  SOORTOBJECTNUMMER1Jan                    = SOORTOBJECTNUMMER,
  SOORTOBJECTNUMMER31Dec                   = SOORTOBJECTNUMMER,
  TYPHH1Jan                                = TYPHH,
  TYPHH31Dec                               = TYPHH,
  AantalPersonenPerHuishouden1Jan          = as.character(AantalPersonenPerHuishouden),
  AantalPersonenPerHuishouden31Dec         = as.character(AantalPersonenPerHuishouden),
  AantalKinderenPerHuishouden1Jan          = as.character(AantalKinderenPerHuishouden),
  AantalKinderenPerHuishouden31Dec         = as.character(AantalKinderenPerHuishouden),
  LeeftijdRefPersoon1Jan                   = LeeftijdRefPersoon,
  LeeftijdRefPersoon31Dec                  = LeeftijdRefPersoon,
  PLHHRefPersoon1Jan                       = PLHH,
  PLHHRefPersoon31Dec                      = PLHH,
  GBAGeslachtsaanduidingRefPersoon1Jan     = GBAGeslachtsAanduiding,
  GBAGeslachtsaanduidingRefPersoon31Dec    = GBAGeslachtsAanduiding,
  GemeenteCodeJJJJ1Jan,
  GemeenteCodeJJJJ31Dec,
  VSLSoort1Jan,                  VSLSoort31Dec,
  WOZWaardeObjectBAGKlasse1Jan,  WOZWaardeObjectBAGKlasse31Dec,
  VBOBouwJaarKlasse1Jan,         VBOBouwJaarKlasse31Dec,
  VBOOppervlakteKlasse1Jan,      VBOOppervlakteKlasse31Dec,
  VBOWoningType1Jan,             VBOWoningType31Dec,
  TypeEigenaar1Jan,              TypeEigenaar31Dec,
  Indicator_HHIsAanwezig1Jan  = "1",
  Indicator_HHIsAanwezig31Dec = "1"
)]

write_sim(dt_ph, paste0("WoonbasePopulatieHuishoudens", SIM_YEAR, "V1"))


# Build WoonbasePopulatieWoonruimten ----
cat("Building WoonbasePopulatieWoonruimten...\n")

# Children per object
obj_kids <- dt_pers[, .(
  AantalKinderenPerVSL      = sum(PLHH == "1"),
  LeeftijdJongsteKindPerVSL = if (any(PLHH == "1"))
    min(SIM_YEAR - as.integer(GBAGeboorteJaar[PLHH == "1"]))
  else 99L
), by = RINOBJECTNUMMER]

# Person count per object (from household size of linked household)
obj_hhinfo <- dt_hh[, .(
  RINOBJECTNUMMER,
  HUISHOUDNR,
  DATUMAANVANGHH,
  TYPHH,
  AantalPersonenPerHuishouden
)]

# Reference person IDs per household → per object
ref_ids <- dt_ref[, .(HUISHOUDNR,
                       RINPERSOONS_Ref = RINPERSOONS,
                       RINPERSOON_Ref  = RINPERSOON)]
obj_hhinfo <- merge(obj_hhinfo, ref_ids, by = "HUISHOUDNR")

dt_pw <- merge(dt_obj, obj_hhinfo,   by = "RINOBJECTNUMMER", all.x = TRUE)
dt_pw <- merge(dt_pw,  obj_kids,     by = "RINOBJECTNUMMER", all.x = TRUE)
dt_pw[is.na(AantalKinderenPerVSL),      AantalKinderenPerVSL      := 0L]
dt_pw[is.na(LeeftijdJongsteKindPerVSL), LeeftijdJongsteKindPerVSL := 99L]
dt_pw[is.na(AantalPersonenPerHuishouden), AantalPersonenPerHuishouden := 0L]

# Number-of-persons class
dt_pw[, n := AantalPersonenPerHuishouden]
dt_pw[, AantalPersonenPerVSLKlasse := fcase(
  n == 0L,            "----",
  n == 1L,            "1",
  n == 2L,            "2",
  n == 3L,            "3",
  n == 4L,            "4",
  n == 5L,            "5",
  n %between% c(6,9), "6",
  n >= 10L,           "7",
  default = "----")]
dt_pw[, n := NULL]

dt_pw_out <- dt_pw[, .(
  SOORTOBJECTNUMMER,
  RINOBJECTNUMMER,
  PandID1Jan,   PandID31Dec,
  VSLSoort1Jan, VSLSoort31Dec,
  HUISHOUDNR1Jan              = HUISHOUDNR,
  HUISHOUDNR31Dec             = HUISHOUDNR,
  DATUMAANVANGHH1jan          = DATUMAANVANGHH,
  DATUMAANVANGHH31Dec         = DATUMAANVANGHH,
  RINPERSOONS_Ref1jan         = RINPERSOONS_Ref,
  RINPERSOONS_Ref31Dec        = RINPERSOONS_Ref,
  RINPERSOON_Ref1jan          = RINPERSOON_Ref,
  RINPERSOON_Ref31Dec         = RINPERSOON_Ref,
  VBOWoningType1Jan,          VBOWoningType31Dec,
  VBOBouwJaarKlasse1Jan,      VBOBouwJaarKlasse31Dec,
  VBOOppervlakteKlasse1Jan,   VBOOppervlakteKlasse31Dec,
  WOZWaardeObjectBAGKlasse1Jan, WOZWaardeObjectBAGKlasse31Dec,
  TypeEigenaar1Jan,           TypeEigenaar31Dec,
  AantalPersonenPerVSLKlasse1Jan  = AantalPersonenPerVSLKlasse,
  AantalPersonenPerVSLKlasse31Dec = AantalPersonenPerVSLKlasse,
  AantalHuishoudensPerVSLKlasse1Jan  = "1",   # simplified: 1 HH per object
  AantalHuishoudensPerVSLKlasse31Dec = "1",
  AantalKinderenPerVSL1Jan   = as.character(AantalKinderenPerVSL),
  AantalKinderenPerVSL31Dec  = as.character(AantalKinderenPerVSL),
  LeeftijdJongsteKindPerVSL1Jan  = as.character(LeeftijdJongsteKindPerVSL),
  LeeftijdJongsteKindPerVSL31Dec = as.character(LeeftijdJongsteKindPerVSL),
  TYPHH1Jan  = TYPHH,
  TYPHH31Dec = TYPHH,
  GemeenteCodeJJJJ1Jan, GemeenteCodeJJJJ31Dec,
  Indicator_VBOIsAanwezig1Jan, Indicator_VBOIsAanwezig31Dec,
  Indicator_VSLIsAanwezig1Jan, Indicator_VSLIsAanwezig31Dec,
  Indicator_VBOIsGesloopt,
  Indicator_VSLIsOntrokken,
  Indicator_VBOIsTransformatie,
  Indicator_VBOIsNieuwbouw,
  Indicator_VSLIsNieuw
)]

write_sim(dt_pw_out, paste0("WoonbasePopulatieWoonruimten", SIM_YEAR, "V1"))

cat(sprintf("\nDone. All files saved to: %s\n", out_dir))
