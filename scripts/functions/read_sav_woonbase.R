# scripts/functions/read_sav_woonbase.R
#
# Provides read_sav() that intercepts CBS Woonbase file names and returns
# synthetic microdata generated on the spot, with the same interface as
# haven::read_sav().  For all other file paths, falls through to haven::read_sav().
#
# Key properties:
#   - Consistent RINPERSOON / RINOBJECTNUMMER / HUISHOUDNR across all file types
#     within a session (spine is cached; joins between files always succeed)
#   - Correct Dutch population sizes when n_max = Inf (via cbsodataR + fallback)
#   - CBS-realistic value distributions calibrated to StatLine 2023 figures
#   - Returns a haven-compatible tibble: integer categoricals carry haven::labelled
#     value labels, just like reading a real .sav file
#   - Supports col_select (tidyselect) and n_max / skip, identical to haven
#
# Usage:
#   source("scripts/functions/read_sav_woonbase.R")
#   woonbase_init(year = 2023, n = 100000)           # optional explicit init
#   dt <- read_sav("WoonbaseKenmerkenHuishoudens2023V1")
#   dt <- read_sav("woonbasepopulatiepersonen",
#                  n_max = 5000, col_select = c(RINPERSOON, TYPHH1Jan))

suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(tibble)
  library(rlang)
  library(tidyselect)
})


# Session cache ----

.wb <- new.env(parent = emptyenv())
.wb$spine  <- NULL   # list(pers, hh, obj)
.wb$params <- NULL   # CBS population parameters
.wb$year   <- NULL
.wb$seed   <- NULL


# Codelist mappings ----
# Each entry: list(c2i = char→int lookup, labels = named int for haven::labelled)
# c2i maps the character codes stored in the spine → integers for labelled class.
# labels maps human-readable label → integer (goes into the haven labels attribute).

.M <- local({

  lm <- function(c2i_vec, labels_vec) list(c2i = c2i_vec, labels = labels_vec)

  list(

    TYPHH = lm(
      c2i    = c("-"=NA_integer_,"1"=1L,"2"=2L,"3"=3L,"4"=4L,"5"=5L,"6"=6L,"7"=7L,"8"=8L,"9"=9L),
      labels = c("Eenpersoonshuishouden"=1L,"Niet-gehuwd paar zonder kinderen"=2L,
                 "Gehuwd paar zonder kinderen"=3L,"Niet-gehuwd paar met kinderen"=4L,
                 "Gehuwd paar met kinderen"=5L,"Eenouderhuishouden"=6L,
                 "Overig huishouden"=7L,"Institutioneel huishouden"=8L,"Meerdere huishoudens"=9L)),

    PLHH = lm(
      c2i    = c("-"=NA_integer_,"1"=1L,"2"=2L,"3"=3L,"4"=4L,"5"=5L,"6"=6L,"7"=7L,"8"=8L,"9"=9L,"10"=10L,"99"=99L),
      labels = c("Thuiswonend kind"=1L,"Alleenstaande"=2L,
                 "Partner niet-gehuwd paar zonder k"=3L,"Partner gehuwd paar zonder k"=4L,
                 "Partner niet-gehuwd paar met k"=5L,"Partner gehuwd paar met k"=6L,
                 "Ouder in eenouderhuishouden"=7L,"Ref persoon overig huishouden"=8L,
                 "Overig lid van huishouden"=9L,"Lid institutioneel huishouden"=10L,"Onbekend"=99L)),

    REFPERSOONHH = lm(
      c2i    = c("0"=0L,"1"=1L,"9"=9L),
      labels = c("Nee"=0L,"Ja"=1L,"Nee, persoon in institutioneel huishouden"=9L)),

    IMPUTATIECODEHH = lm(
      c2i    = c("0"=0L,"1"=1L),
      labels = c("Niet geimputeerd"=0L,"Geimputeerd"=1L)),

    GESLACHT = lm(
      c2i    = c("-"=NA_integer_,"1"=1L,"2"=2L),
      labels = c("Mannen"=1L,"Vrouwen"=2L)),

    VSLSOORT = lm(
      c2i    = c("-"=NA_integer_,"1"=1L,"2"=2L,"3"=3L,"4"=4L,"5"=5L,"6"=6L,"9"=9L),
      labels = c("VBO voorraad woonfunctie"=1L,"VBO voorraad niet-woonfunctie"=2L,
                 "VBO niet-voorraad woonfunctie"=3L,"VBO niet-voorraad niet-woonfunctie"=4L,
                 "Bewoonde Standplaats"=5L,"Bewoonde Ligplaats"=6L,"Onbekend"=9L)),

    WONINGTYPE = lm(
      c2i    = c("--"=NA_integer_,"00"=0L,"01"=1L,"02"=2L,"03"=3L,"04"=4L,"05"=5L,"99"=99L),
      labels = c("Eengezinswoning onbekend"=0L,"Vrijstaande woning"=1L,
                 "Twee-onder-een-kapwoning"=2L,"Hoekwoning"=3L,
                 "Tussenwoning"=4L,"Meergezinswoning"=5L,"Onbekend"=99L)),

    BOUWJAARKLASSE = lm(
      c2i    = setNames(c(NA_integer_, 1L:15L, 99L),
                        c("-","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","99")),
      labels = c("<1905"=1L,"1905-1925"=2L,"1925-1945"=3L,"1945-1955"=4L,"1955-1965"=5L,
                 "1965-1975"=6L,"1975-1985"=7L,"1985-1995"=8L,"1995-2005"=9L,"2005-2015"=10L,
                 "2015-2020"=11L,"2020-2025"=12L,"2025-2030"=13L,"2030-2035"=14L,">=2035"=15L,"Onbekend"=99L)),

    OPPKLASSE = lm(
      c2i    = c("-"=NA_integer_,"1"=1L,"2"=2L,"3"=3L,"4"=4L,"5"=5L,"6"=6L,"9"=9L),
      labels = c("<50 m2"=1L,"50-75 m2"=2L,"75-100 m2"=3L,"100-150 m2"=4L,"150-250 m2"=5L,">=250 m2"=6L,"Onbekend"=9L)),

    WOZKLASSE = lm(
      c2i    = c("-"=NA_integer_,"1"=1L,"2"=2L,"3"=3L,"4"=4L,"5"=5L,"6"=6L,"7"=7L,"9"=9L),
      labels = c("<150k"=1L,"150-250k"=2L,"250-350k"=3L,"350-450k"=4L,"450-550k"=5L,"550-650k"=6L,">=650k"=7L,"Onbekend"=9L)),

    TYPEIGENAAR = lm(
      c2i    = c("-"=NA_integer_,"C"=1L,"V"=2L,"E"=3L,"O"=4L,"9"=9L),
      labels = c("Woningcorporatie"=1L,"Verhuurder anders"=2L,"Eigenaar-gebruiker"=3L,"Onbekend"=4L,"Onbekend (niet gevonden)"=9L)),

    VBOSTATUS = lm(
      c2i    = c("-"=NA_integer_,"3"=3L,"4"=4L,"6"=6L),
      labels = c("In gebruik (niet ingemeten)"=3L,"In gebruik"=4L,"Buiten gebruik"=6L)),

    INVOORRAAD = lm(
      c2i    = c("-"=NA_integer_,"0"=0L,"1"=1L),
      labels = c("Niet in de voorraad"=0L,"In de voorraad"=1L)),

    VBOVOORRAADTYPE = lm(
      c2i    = c("-"=NA_integer_,"0"=0L,"1"=1L),
      labels = c("Woonfunctie"=0L,"Niet-woonfunctie"=1L)),

    INDICATOR = lm(
      c2i    = c("-"=NA_integer_,"0"=0L,"1"=1L),
      labels = c("Nee"=0L,"Ja"=1L)),

    PERSKLASSE = lm(
      c2i    = c("----"=NA_integer_,"1"=1L,"2"=2L,"3"=3L,"4"=4L,"5"=5L,"6"=6L,"7"=7L),
      labels = c("1"=1L,"2"=2L,"3"=3L,"4"=4L,"5"=5L,"6-9"=6L,">=10"=7L)),

    HHKLASSE = lm(
      c2i    = c("-"=NA_integer_,"1"=1L,"2"=2L,"3"=3L,"4"=4L),
      labels = c("1"=1L,"2"=2L,"3-9"=3L,">=10"=4L))
  )
})

# Apply a codelist mapping to a character vector → haven::labelled integer
.lbl <- function(x, mapping, var_label = NULL) {
  iv <- unname(mapping$c2i[as.character(x)])
  haven::labelled(iv, labels = mapping$labels, label = var_label)
}

# Label column in-place only if it is still present in dt (no-op otherwise)
.lbl_if <- function(dt, col, mapping, var_label = NULL) {
  if (col %in% names(dt))
    set(dt, j = col, value = .lbl(dt[[col]], mapping, var_label))
  invisible(dt)
}


# CBS population parameters ----

# Hardcoded 2023 figures (CBS StatLine; used as fallback)
.wb_fallback <- function(year = 2023L) {
  list(
    year       = year,
    n_persons  = 17890220L,    # Bevolking op 1 jan 2023 (37230ned)
    n_hh       = 8358000L,     # Particuliere + institutionele HH (71488ned)
    n_obj      = 8133000L,     # Woningvoorraad (82249NED)
    avg_hh_size = 2.145,

    # TYPHH proportions (CBS 71488ned, 2023)
    typhh_p = c("1"=0.387,"2"=0.093,"3"=0.188,"4"=0.050,"5"=0.175,"6"=0.070,"7"=0.023,"8"=0.014),

    # TypeEigenaar (CBS 83625NED, 2023)
    eigenaar_p = c(C=0.295, V=0.121, E=0.559, O=0.015, `9`=0.010),

    # VBOWoningType (BAG/CBS 2023)
    woningtype_p = c("00"=0.010,"01"=0.138,"02"=0.112,"03"=0.143,"04"=0.281,"05"=0.306,"99"=0.010),

    # VBOBouwJaarKlasse 1-15 (CBS bouwjaarstatistieken 2023)
    bouwjaar_p = c(0.048,0.063,0.070,0.085,0.103,0.121,0.121,0.101,0.097,0.088,0.050,0.036,0.010,0.004,0.003),

    # WOZWaardeObjectBAGKlasse (CBS WOZ statistieken 2023)
    woz_p = c("1"=0.096,"2"=0.241,"3"=0.248,"4"=0.176,"5"=0.103,"6"=0.064,"7"=0.058,"9"=0.014),

    # VBOOppervlakteKlasse (CBS 2023)
    opp_p = c("1"=0.082,"2"=0.228,"3"=0.256,"4"=0.224,"5"=0.142,"6"=0.058,"9"=0.010),

    geslacht_p  = c("1"=0.495,"2"=0.505),
    soortobj_p  = c(B=0.900,H=0.040,D=0.050,O=0.010),
    vslsoort_p  = c("1"=0.878,"2"=0.022,"3"=0.032,"4"=0.012,"5"=0.041,"6"=0.015),

    # Sample of Dutch gemeente codes for geographic realism
    gem_codes = sprintf("%04d", c(363,599,518,344,503,268,307,392,398,400,
                                   14,15,16,17,18,19,20,21,22,23,
                                   106,114,153,163,171,175,180,193,196,200))
  )
}

#' Fetch Dutch population parameters from CBS StatLine via cbsodataR.
#' Falls back to hardcoded 2023 values if the API is unavailable.
#'
#' Tables used:
#'   37230ned  – Bevolkingsontwikkeling; regio           (population on 1 Jan)
#'   71486ned  – Huishoudens; samenstelling, grootte, regio (HH counts + TYPHH)
#'
#' NOTE: cbsodataR v1.x named-argument dimension filters (e.g. RegioS = "NL01")
#' fail when combined on the CBS OData endpoint.  We therefore fetch the full
#' annual table and apply all dimension filters in R.
woonbase_cbs_params <- function(year = 2023L) {
  result <- tryCatch({
    if (!requireNamespace("cbsodataR", quietly = TRUE))
      stop("cbsodataR not installed")

    yr_code <- paste0(year, "JJ00")

    # ---- Population on 1 January (table 37230ned) ----------------------------
    # Column: BevolkingAanHetBeginVanDePeriode_1 (absolute count, not thousands)
    pop_all <- cbsodataR::cbs_get_data("37230ned", Perioden = yr_code)
    pop <- pop_all[trimws(pop_all$RegioS) == "NL01", ]
    if (nrow(pop) == 0L) stop("37230ned: no NL01 row found for year ", year)
    n_pers <- as.integer(pop$BevolkingAanHetBeginVanDePeriode_1[[1]])

    # ---- Households: count + TYPHH proportions (table 71486ned) --------------
    # Particuliere huishoudens; samenstelling en grootte, regio
    # Dimension LeeftijdReferentiepersoon == "10000" is the all-ages total row.
    hh_all <- cbsodataR::cbs_get_data("71486ned", Perioden = yr_code)
    hh <- hh_all[trimws(hh_all$RegioS) == "NL01" &
                 trimws(hh_all$LeeftijdReferentiepersoon) == "10000", ]
    if (nrow(hh) == 0L) stop("71486ned: no NL01/totaal row found for year ", year)

    n_hh <- as.integer(hh$TotaalParticuliereHuishoudens_1[[1]])

    # Map 71486ned columns to TYPHH codes (particuliere HH only; excl type 8/9)
    hh_1  <- as.numeric(hh$Eenpersoonshuishouden_2[[1]])          # Type 1
    hh_2  <- as.numeric(hh$k_0Kinderen_7[[1]])                    # Type 2 (niet-geh paar z.k.)
    hh_3  <- as.numeric(hh$k_0Kinderen_12[[1]])                   # Type 3 (geh paar z.k.)
    hh_4  <- as.numeric(hh$TotaalNietGehuwdeParen_6[[1]]) - hh_2  # Type 4 (niet-geh paar m.k.)
    hh_5  <- as.numeric(hh$TotaalGehuwdeParen_11[[1]])  - hh_3    # Type 5 (geh paar m.k.)
    hh_6  <- as.numeric(hh$TotaalEenouderhuishoudens_16[[1]])      # Type 6
    hh_7  <- as.numeric(hh$OverigHuishouden_20[[1]])               # Type 7

    hh_tot_known <- hh_1 + hh_2 + hh_3 + hh_4 + hh_5 + hh_6 + hh_7

    # Type 8 (institutioneel) is not in 71486ned; keep 2023 estimate and rescale
    typhh_raw <- c("1"=hh_1,"2"=hh_2,"3"=hh_3,"4"=hh_4,"5"=hh_5,"6"=hh_6,"7"=hh_7)
    typhh_p8  <- c(typhh_raw / hh_tot_known * (1 - 0.014), "8" = 0.014)

    if (anyNA(c(n_pers, n_hh))) stop("missing values in CBS response")

    p <- .wb_fallback(year)
    p$n_persons <- n_pers
    p$n_hh      <- n_hh
    p$n_obj     <- round(n_hh * 1.035)
    p$typhh_p   <- typhh_p8
    message(sprintf("CBS population %d: %s persons, %s households",
                    year, format(n_pers, big.mark=","), format(n_hh, big.mark=",")))
    p
  }, error = function(e) {
    message("CBS API unavailable (", conditionMessage(e), "). Using hardcoded values for ", year, ".")
    .wb_fallback(year)
  })
  result
}


# Low-level ID generators ----

# Option B: sprintf is ~3-5x faster than formatC for zero-padded integers
.seq_id  <- function(n, w)    sprintf(paste0("%0", w, "d"), seq_len(n))
.rand_id <- function(n, w) {
  # For widths ≤ 9 use sample.int; wider: combine two ranges
  if (w <= 9L) {
    pool <- 10^w - 1L
    unique <- n <= pool
    if (!unique)
      warning(sprintf(".rand_id: n=%d > pool=%d for width %d; IDs will not be unique", n, pool, w))
    sprintf(paste0("%0", w, "d"), sample.int(pool, n, replace = !unique))
  } else {
    h <- ceiling(w / 2L)
    paste0(sprintf(paste0("%0", h,   "d"), sample.int(10^h       - 1L, n, replace = TRUE)),
           sprintf(paste0("%0", w-h, "d"), sample.int(10^(w - h) - 1L, n, replace = TRUE)))
  }
}
.rcat    <- function(n, v, p = NULL) sample(v, n, replace = TRUE, prob = p)
# Option C: avoid format.Date S3 dispatch overhead; POSIXlt decomposition + sprintf is faster
.yyyymmdd <- function(d) {
  lt <- as.POSIXlt(d)
  sprintf("%04d%02d%02d", lt$year + 1900L, lt$mon + 1L, lt$mday)
}
.rdate   <- function(n, from, to)
  as.Date(sample(as.integer(from):as.integer(to), n, replace = TRUE), origin = "1970-01-01")


# Spine generation ----


.wb_build_spine <- function(n_persons, params, seed, year) {
  set.seed(seed)

  jan1  <- as.Date(paste0(year, "-01-01"))
  dec31 <- as.Date(paste0(year, "-12-31"))

  # ---- Objects ----------------------------------------------------------------
  N_HH <- round(n_persons / params$avg_hh_size)
  N_OBJ <- N_HH

  message(sprintf("  Building spine: %s persons / %s households / %s objects ...",
                  format(n_persons, big.mark=","),
                  format(N_HH, big.mark=","),
                  format(N_OBJ, big.mark=",")))

  dt_obj <- data.table(
    RINOBJECTNUMMER   = .rand_id(N_OBJ, 16L),
    SOORTOBJECTNUMMER = .rcat(N_OBJ, names(params$soortobj_p), params$soortobj_p)
  )

  for (sfx in c("1Jan","31Dec")) {
    gem <- .rcat(N_OBJ, params$gem_codes)
    set(dt_obj, j = paste0("GemeenteCodeJJJJ",       sfx), value = gem)
    set(dt_obj, j = paste0("WijkCodeJJJJ",           sfx), value = paste0(gem, sprintf("%02d", sample(1:20, N_OBJ, replace=TRUE))))
    set(dt_obj, j = paste0("BuurtCodeJJJJ",          sfx), value = paste0(gem, sprintf("%04d", sample(1:200,N_OBJ, replace=TRUE))))
    set(dt_obj, j = paste0("VSLSoort",               sfx), value = .rcat(N_OBJ, names(params$vslsoort_p),  params$vslsoort_p))
    set(dt_obj, j = paste0("VBOWoningType",          sfx), value = .rcat(N_OBJ, names(params$woningtype_p),params$woningtype_p))
    set(dt_obj, j = paste0("VBOBouwJaarKlasse",      sfx), value = .rcat(N_OBJ, as.character(1:15),        params$bouwjaar_p))
    set(dt_obj, j = paste0("VBOOppervlakteKlasse",   sfx), value = .rcat(N_OBJ, names(params$opp_p),       params$opp_p))
    set(dt_obj, j = paste0("WOZWaardeObjectBAGKlasse",sfx),value = .rcat(N_OBJ, names(params$woz_p),       params$woz_p))
    set(dt_obj, j = paste0("TypeEigenaar",           sfx), value = .rcat(N_OBJ, names(params$eigenaar_p),  params$eigenaar_p))
    set(dt_obj, j = paste0("VBOBouwjaar",            sfx), value = sample(1850L:year, N_OBJ, replace=TRUE))
    set(dt_obj, j = paste0("VBOOppervlakte",         sfx), value = as.integer(pmax(15L, round(rlnorm(N_OBJ, log(85), 0.45)))))
    set(dt_obj, j = paste0("WOZWaardeObjectBAG",     sfx), value = round(rlnorm(N_OBJ, log(300000), 0.50), -3L))
    set(dt_obj, j = paste0("VBOStatus",              sfx), value = .rcat(N_OBJ, c("3","4","6"), c(0.10,0.85,0.05)))
    set(dt_obj, j = paste0("Indicator_VBOIsNieuwbouw",sfx),value = .rcat(N_OBJ, c("-","0","1"), c(0.01,0.96,0.03)))
    set(dt_obj, j = paste0("Indicator_VBOIsAanwezig", sfx),value = .rcat(N_OBJ, c("0","1"), c(0.02,0.98)))
    set(dt_obj, j = paste0("Indicator_VSLIsAanwezig", sfx),value = "1")
  }
  dt_obj[, PandID1Jan  := ifelse(VBOWoningType1Jan == "05", .rand_id(N_OBJ,16L), strrep("9",16L))]
  dt_obj[, PandID31Dec := PandID1Jan]
  dt_obj[, Indicator_VBOIsGesloopt      := .rcat(N_OBJ, c("-","0","1"), c(0.01,0.98,0.01))]
  dt_obj[, Indicator_VBOIsTransformatie := .rcat(N_OBJ, c("-","0","1"), c(0.01,0.985,0.005))]
  dt_obj[, Indicator_VBOIsNieuwbouw     := .rcat(N_OBJ, c("-","0","1"), c(0.01,0.96,0.03))]
  dt_obj[, Indicator_VSLIsOntrokken     := .rcat(N_OBJ, c("-","0","1"), c(0.01,0.985,0.005))]
  dt_obj[, Indicator_VSLIsNieuw         := .rcat(N_OBJ, c("-","0","1"), c(0.01,0.97,0.02))]
  setkey(dt_obj, RINOBJECTNUMMER)

  # ---- Households -------------------------------------------------------------
  dt_hh <- data.table(
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
  dt_hh[, NKids := fcase(
    TYPHH %in% c("4","5"), pmax(0L, HHSize - 2L),
    TYPHH == "6",           pmax(0L, HHSize - 1L),
    default = 0L)]
  setkey(dt_hh, HUISHOUDNR)

  # ---- Persons (vectorized) ---------------------------------------------------
  # Expand: repeat each HH row once per person it contains
  dt_pers <- dt_hh[rep(seq_len(N_HH), times = dt_hh$HHSize)]
  dt_pers[, rank := rowid(HUISHOUDNR)]
  N_PERS_actual <- nrow(dt_pers)

  # PLHH (positie in huishouden) derived from TYPHH and rank within household
  dt_pers[, PLHH := fcase(
    TYPHH == "1",                       "2",   # alleenstaande
    TYPHH == "2",                       "3",   # niet-geh paar z.k.
    TYPHH == "3",                       "4",   # geh paar z.k.
    TYPHH == "4" & rank <= 2L,          "5",   # niet-geh paar m.k. — partners
    TYPHH == "5" & rank <= 2L,          "6",   # geh paar m.k. — partners
    TYPHH %in% c("4","5") & rank > 2L,  "1",   # kinderen
    TYPHH == "6" & rank == 1L,          "7",   # eenouder
    TYPHH == "6" & rank > 1L,           "1",   # kinderen
    TYPHH == "7" & rank == 1L,          "8",   # ref overig huishouden
    TYPHH == "7" & rank > 1L,           "9",   # overig lid
    TYPHH == "8",                       "10"   # institutioneel lid
  )]

  # Reference person: first in non-institutional HH; all institutional = "9"
  dt_pers[, REFPERSOONHH := fcase(
    TYPHH == "8",  "9",
    rank == 1L,    "1",
    default =      "0"
  )]

  # Option D: subset-then-sample; avoids generating N_PERS_actual values per
  # branch that fcase() would eagerly evaluate even for non-matching rows.

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

  # Household sizes from the expanded person table
  hh_sz <- dt_pers[, .(
    AantalPersonenPerHuishouden = .N,
    AantalKinderenPerHuishouden = sum(PLHH == "1")
  ), by = HUISHOUDNR]
  dt_pers <- merge(dt_pers, hh_sz, by = "HUISHOUDNR")
  dt_hh   <- merge(dt_hh,   hh_sz, by = "HUISHOUDNR")
  setkey(dt_pers, RINPERSOON)

  # Join spatial/characteristic object columns onto persons
  obj_join_cols <- c("RINOBJECTNUMMER",
    paste0(c("GemeenteCodeJJJJ","WijkCodeJJJJ","BuurtCodeJJJJ","VSLSoort",
             "TypeEigenaar","VBOWoningType","VBOBouwJaarKlasse",
             "VBOOppervlakteKlasse","WOZWaardeObjectBAGKlasse"), "1Jan"),
    paste0(c("GemeenteCodeJJJJ","WijkCodeJJJJ","BuurtCodeJJJJ","VSLSoort",
             "TypeEigenaar","VBOWoningType","VBOBouwJaarKlasse",
             "VBOOppervlakteKlasse","WOZWaardeObjectBAGKlasse"), "31Dec"))
  dt_pers <- merge(dt_pers, dt_obj[, ..obj_join_cols], by="RINOBJECTNUMMER")

  # Option E: .I[1L] extracts row indices without copying .SD per group (~5x faster)
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

  message(sprintf("  Spine ready: %s persons, %s households, %s objects.",
                  format(N_PERS_actual, big.mark=","),
                  format(N_HH, big.mark=","),
                  format(N_OBJ, big.mark=",")))

  list(pers=dt_pers, hh=dt_hh2, obj=dt_obj2,
       year=year, jan1=jan1, dec31=dec31)
}


# File name parsing ----

# Recognised file types (normalised to a key)
.WB_FILES <- c(
  sleutel           = "woonbasesleutel",
  kenmerken_pers    = "woonbasekenmerkenpers",
  kenmerken_hh      = "woonbasekenmerkenhuis",
  kenmerken_obj     = "woonbasekenmerkenwoon",
  populatie_pers    = "woonbasepopulatieperso",
  populatie_hh      = "woonbasepopulatiehuis",
  populatie_obj     = "woonbasepopulatiewoon"
)

.wb_parse_file <- function(file) {
  base <- tolower(tools::file_path_sans_ext(basename(file)))
  base <- gsub("[_ \\-]", "", base)            # strip separators
  base <- gsub("(\\d{4})(v\\d+)?$", "", base) # strip year + version suffix
  for (key in names(.WB_FILES)) {
    if (startsWith(base, .WB_FILES[[key]])) return(key)
  }
  NULL
}

.wb_unit <- function(file_type) {
  switch(file_type,
    sleutel        = , kenmerken_pers = , populatie_pers = "person",
    kenmerken_hh   = , populatie_hh   =                   "household",
    kenmerken_obj  = , populatie_obj  =                   "object")
}


# File assembly ----

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
        set(dt, j=ic, value=.lbl(dt[[ic]], .M$INDICATOR, gsub("_"," ",ic)))
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
      o2 <- copy(o)
      o2[, n := AantalPersonenPerVSL]
      o2[, AantalPersonenPerVSLKlasse := fcase(
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
        set(dt, j=ic, value=.lbl(dt[[ic]], .M$INDICATOR, gsub("_"," ",ic)))
      dt
    }
  )
}


# Exported helpers ----

#' Pre-build the Woonbase spine and cache it for the session.
#' Call this once before using read_sav() on Woonbase files.
#'
#' @param year  Simulation year (default 2023).
#' @param n     Number of persons to generate.  NULL → fetch from CBS and use
#'              the actual Dutch population count for \code{year}.
#' @param seed  RNG seed for reproducibility (default 42).
woonbase_init <- function(year = 2023L, n = NULL, seed = 42L) {
  params <- woonbase_cbs_params(year)
  n_pers <- if (is.null(n)) params$n_persons else as.integer(n)
  .wb$spine  <- .wb_build_spine(n_pers, params, seed, year)
  .wb$params <- params
  .wb$year   <- year
  .wb$seed   <- seed
  invisible(NULL)
}

#' Clear the cached spine (forces rebuild on next read_sav call).
woonbase_reset <- function() { .wb$spine <- NULL; invisible(NULL) }


# Main read_sav wrapper ----

#' Read a CBS Woonbase file (synthetic) or any other .sav file (via haven).
#'
#' Supports the same arguments as \code{haven::read_sav()}: \code{n_max},
#' \code{skip}, \code{col_select} (tidyselect or character vector).
#' Extra arguments (\code{year}, \code{seed}) control the simulation when
#' no spine has been pre-built with \code{woonbase_init()}.
#'
#' @examples
#' # Quick usage (auto-initialises a small spine)
#' dt <- read_sav("WoonbaseKenmerkenHuishoudens2023V1", n_max = 1000)
#'
#' # Full Dutch population (slow; needs memory)
#' woonbase_init(year = 2023)
#' dt_pers <- read_sav("woonbasepopulatiepersonen")
#' dt_hh   <- read_sav("woonbasepopulatiehuishoudens")
#' # → RINPERSOON / HUISHOUDNR join correctly between the two files
#'
#' # Column selection (tidyselect)
#' dt <- read_sav("woonbasepopulatiepersonen", n_max = 5000,
#'                col_select = c(RINPERSOON, TYPHH1Jan, GBAGeboorteJaar1Jan))
read_sav <- function(file,
                     encoding     = NULL,
                     user_na      = FALSE,
                     col_select   = NULL,
                     skip         = 0L,
                     n_max        = Inf,
                     .name_repair = "unique",
                     year         = 2023L,
                     seed         = 42L,
                     ...) {

  col_q     <- enquo(col_select)
  file_type <- .wb_parse_file(file)

  # Fall through to haven for non-Woonbase files
  if (is.null(file_type)) {
    return(haven::read_sav(file, encoding=encoding, user_na=user_na,
                           col_select=!!col_q, skip=skip, n_max=n_max,
                           .name_repair=.name_repair, ...))
  }

  # Auto-initialise spine if needed
  if (is.null(.wb$spine) || (!is.null(.wb$year) && .wb$year != year)) {
    if (is.infinite(n_max)) {
      message("n_max = Inf: fetching CBS population count for ", year, " and generating full spine.")
      woonbase_init(year=year, n=NULL, seed=seed)
    } else {
      unit   <- .wb_unit(file_type)
      n_pers <- switch(unit,
        person    = ceiling(n_max * 1.05),
        household = ceiling(n_max * 2.4),
        object    = ceiling(n_max * 2.4))
      message(sprintf("Auto-initialising spine with %s persons for '%s'. Call woonbase_init() explicitly for reproducible cross-file joins.",
                      format(n_pers, big.mark=","), file_type))
      woonbase_init(year=year, n=n_pers, seed=seed)
    }
  }

  # Assemble the requested file (col_select applied inside)
  dt <- .wb_assemble(file_type, .wb$spine, col_q = col_q)

  # Apply skip and n_max
  if (skip > 0L) {
    dt <- dt[seq_len(nrow(dt)) > min(skip, nrow(dt))]
  }
  if (!is.infinite(n_max) && n_max < nrow(dt)) {
    dt <- dt[seq_len(as.integer(n_max))]
  }

  # Return as tibble (matches haven::read_sav output class)
  as_tibble(dt)
}
