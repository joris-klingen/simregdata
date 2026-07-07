#' @import data.table
#' @importFrom haven labelled
#' @importFrom rlang enquo quo_is_null quo_get_expr "%||%"
#' @importFrom tidyselect eval_select
#' @importFrom tibble as_tibble
#' @importFrom stats rbinom rlnorm rnorm runif setNames
#' @importFrom utils globalVariables
NULL

# Suppress R CMD check NOTEs for data.table NSE variables
globalVariables(c(
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
  "..obj_join_cols", "..ref_obj_cols", "..pers_cols",
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
  "Indicator_VSLIsAanwezig1Jan", "Indicator_VSLIsAanwezig31Dec",
  "BESTINKH", "BELIH", "GESTINKH", "VERMHH",
  "VROMHH", "P100HBEST", "P100HGEST", "P100HVERM", "P100WELVAART",
  "veh_weight", "vehicles", "pop",
  "gem_code", "RINKENTEKEN", "..hh_cols", "..obj_cols",
  "job_group", "month", "period_start", "period_end",
  "ikv_start", "ikv_end", "ikv_start_prev",
  "IKVID", "SBEID", "RINPERSOONS",
  "RINPERSOONHKW", "RINPERSOONSHKW", "HUISHOUDNR",
  "SECM", "period_group", "n_periods", "BEID",
  "BRANDSTCODECORVRTG", "pct_apartment", "pct_owner",
  "RINPERSOONRELATIE", "RINPERSOONSRELATIE", "RELATIE"
))

# Session cache environment — per-dataset spine + config caches
.sim_cache <- new.env(parent = emptyenv())

# Legacy .wb accessor (points into .sim_cache for backward compat)
.wb <- new.env(parent = emptyenv())
.wb$spine  <- NULL
.wb$params <- NULL
.wb$year   <- NULL
.wb$seed   <- NULL

# Get codelists for a dataset (loaded from YAML on first use)
.get_codelists <- function(dataset_id = "woonbase") {
  .load_codelists(dataset_id)
}
