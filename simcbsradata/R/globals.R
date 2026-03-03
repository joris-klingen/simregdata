#' @import data.table
#' @importFrom haven labelled
#' @importFrom rlang enquo quo_is_null quo_get_expr
#' @importFrom tidyselect eval_select
#' @importFrom tibble as_tibble
#' @importFrom stats rlnorm setNames
NULL

# Suppress R CMD check NOTEs for data.table NSE variables
utils::globalVariables(c(
  ".N", ".I", ".SD",
  "RINOBJECTNUMMER", "SOORTOBJECTNUMMER", "RINPERSOON", "RINPERSOONS",
  "HUISHOUDNR", "TYPHH", "IMPUTATIECODEHH", "DATUMAANVANGHH",
  "HHSize", "NKids", "rank", "PLHH", "REFPERSOONHH",
  "GBAGeboorteJaar", "GBABurgerlijkeStaat", "GBAGeslachtsAanduiding",
  "AanvangWoonduur", "AantalPersonenPerHuishouden", "AantalKinderenPerHuishouden",
  "AantalPersonenPerVSL", "AantalKinderenPerVSL", "LeeftijdJongsteKindPerVSL",
  "LeeftijdRefPersoon", "AantalPersonenPerVSLKlasse", "n",
  "PandID1Jan", "PandID31Dec", "VBOWoningType1Jan",
  "Indicator_VBOIsGesloopt", "Indicator_VBOIsTransformatie",
  "Indicator_VBOIsNieuwbouw", "Indicator_VSLIsOntrokken", "Indicator_VSLIsNieuw",
  "Indicator_PersoonIsVerhuisd", "AantalKeerVerhuisd",
  "Indicator_PersoonIsGeboren", "Indicator_PersoonIsOverleden",
  "Indicator_PersoonIsGeemigreerd", "Indicator_PersoonIsGeimmigreerd",
  "Indicator_PersoonIsAdministratiefAfgevoerd", "Indicator_PersoonIsAdministratiefOpgenomen",
  "Indicator_PersoonIsAanwezig1Jan", "Indicator_PersoonIsAanwezig31Dec",
  "RINPERSOON_Ref", "RINPERSOONS_Ref", "REFPERSOONHH_Ref",
  "PLHH_Ref", "GBAGeslachtsAanduiding_Ref",
  "RINPERSOON_Ref2", "RINPERSOONS_Ref2",
  "..obj_join_cols", "..ref_obj_cols",
  ".", "GemeenteCodeJJJJ1Jan", "GemeenteCodeJJJJ31Dec",
  "WijkCodeJJJJ1Jan", "WijkCodeJJJJ31Dec",
  "BuurtCodeJJJJ1Jan", "BuurtCodeJJJJ31Dec",
  "VSLSoort1Jan", "VSLSoort31Dec",
  "VBOWoningType31Dec", "VBOBouwjaar1Jan", "VBOBouwjaar31Dec",
  "VBOOppervlakte1Jan", "VBOOppervlakte31Dec",
  "WOZWaardeObjectBAG1Jan", "WOZWaardeObjectBAG31Dec",
  "VBOStatus1Jan", "VBOStatus31Dec",
  "TypeEigenaar1Jan", "TypeEigenaar31Dec",
  "VBOBouwJaarKlasse1Jan", "VBOBouwJaarKlasse31Dec",
  "VBOOppervlakteKlasse1Jan", "VBOOppervlakteKlasse31Dec",
  "WOZWaardeObjectBAGKlasse1Jan", "WOZWaardeObjectBAGKlasse31Dec",
  "Indicator_VBOIsAanwezig1Jan", "Indicator_VBOIsAanwezig31Dec",
  "Indicator_VBOIsNieuwbouw1Jan",
  "Indicator_VSLIsAanwezig1Jan", "Indicator_VSLIsAanwezig31Dec"
))

# Session cache environment
.wb <- new.env(parent = emptyenv())
.wb$spine  <- NULL   # list(pers, hh, obj)
.wb$params <- NULL   # CBS population parameters
.wb$year   <- NULL
.wb$seed   <- NULL


# Codelist mappings ----
# Each entry: list(c2i = char->int lookup, labels = named int for haven::labelled)
# c2i maps the character codes stored in the spine -> integers for labelled class.
# labels maps human-readable label -> integer (goes into the haven labels attribute).

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
