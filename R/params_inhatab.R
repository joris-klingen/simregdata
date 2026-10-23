# Household income parameters and simulation (INHATAB, woonbase) ----

# Path to INHATAB params YAML
.inhatab_params_yaml <- function() {
  file.path(.dataset_dir("inhatab"), "params.yaml")
}

# Household types of 83932NED (KenmerkenVanHuishoudens) used to calibrate
# income, keyed as in params.yaml
.INCOME_TYPES <- c(
  totaal           = "Particuliere huishoudens",
  eenpersoons_jong = "Type: Alleenstaande onder AOW-lft",
  eenpersoons_aow  = "Type: Alleenstaande vanaf AOW-lft",
  eenouder         = "Type: Eenoudergezin",
  paar_zonder_jong = "Type: Paar, zonder kind, onder AOW-lft",
  paar_zonder_aow  = "Type: Paar, zonder kind, vanaf AOW-lft",
  paar_met         = "Type: Paar, met kind(eren)",
  overig           = "Type: Meerpersoonshuishouden, overig"
)

# Income concepts of 83932NED (Inkomensbegrippen), keyed as in params.yaml
.INCOME_CONCEPTS <- c(
  primair           = "Primair inkomen",
  bruto             = "Bruto inkomen",
  besteedbaar       = "Besteedbaar inkomen",
  gestandaardiseerd = "Gestandaardiseerd inkomen"
)


#' Load cached household income parameters for a given year
#'
#' Reads the mean and median household income per income concept and
#' household type from `inst/config/datasets/inhatab/params.yaml`
#' (StatLine 83932NED). Years outside the table use the nearest year.
#'
#' @param year Integer year (default 2023).
#' @return A named list (one element per household type) of named lists
#'   (one per income concept) with `mean` and `median` in euro.
#' @export
inhatab_cbs_params <- function(year = 2023L) {
  yaml_path <- .inhatab_params_yaml()
  if (!nzchar(yaml_path) || !file.exists(yaml_path))
    stop("INHATAB parameter file not found. Run inhatab_update_params() first.",
         "\nExpected: inst/config/datasets/inhatab/params.yaml")

  all_params <- yaml::read_yaml(yaml_path)
  yr_key <- as.character(year)
  if (!yr_key %in% names(all_params)) {
    avail <- sort(as.integer(names(all_params)))
    yr_key <- as.character(avail[which.min(abs(avail - year))])
  }
  all_params[[yr_key]]
}


#' Fetch CBS StatLine household income data and write INHATAB params.yaml
#'
#' Queries StatLine table `83932NED` (Inkomen huishoudens; inkomensklassen)
#' for the mean and median household income per income concept (primary,
#' gross, disposable, standardised) and household type. The simulator draws
#' household income from these (see `.simulate_hh_income()`), which feeds
#' both woonbase (`BESTINKH1JAN` etc.) and INHATAB.
#'
#' @param years Integer vector of years to fetch (default `2011:2024`).
#' @param config_dir Directory to write params.yaml into.
#' @return Invisibly, the full parameter list.
#' @export
inhatab_update_params <- function(years = 2011:2024,
                                  config_dir = .dataset_dir("inhatab")) {
  if (!requireNamespace("cbsodataR", quietly = TRUE))
    stop("Package 'cbsodataR' is required. Install with install.packages('cbsodataR').")

  yaml_path <- file.path(config_dir, "params.yaml")
  all_params <- if (file.exists(yaml_path)) yaml::read_yaml(yaml_path) else list()

  cat("Fetching CBS StatLine household income (83932NED):\n")
  for (yr in years) {
    cat(sprintf("  %d: ", yr))
    tryCatch({
      dt <- data.table::as.data.table(cbsodataR::cbs_add_label_columns(
        cbsodataR::cbs_get_data("83932NED", Perioden = paste0(yr, "JJ00"))))
      dt <- dt[trimws(as.character(Inkomensklassen_label)) == "Totaal"]
      dt[, `:=`(
        type    = trimws(as.character(KenmerkenVanHuishoudens_label)),
        concept = trimws(as.character(Inkomensbegrippen_label))
      )]

      yr_data <- list()
      for (tk in names(.INCOME_TYPES)) {
        for (ck in names(.INCOME_CONCEPTS)) {
          row <- dt[type == .INCOME_TYPES[[tk]] & concept == .INCOME_CONCEPTS[[ck]]]
          if (nrow(row) == 0L) stop("no row for ", tk, " / ", ck)
          yr_data[[tk]][[ck]] <- list(
            mean   = round(as.numeric(row$GemiddeldInkomen_4[1L]) * 1000),
            median = round(as.numeric(row$MediaanInkomen_5[1L]) * 1000))
        }
      }
      all_params[[as.character(yr)]] <- yr_data
      cat(sprintf("besteedbaar mean %s, median %s\n",
                  format(yr_data$totaal$besteedbaar$mean, big.mark = ","),
                  format(yr_data$totaal$besteedbaar$median, big.mark = ",")))
    }, error = function(e) {
      cat(sprintf("FAILED (%s)\n", conditionMessage(e)))
    })
  }

  all_params <- all_params[order(as.integer(names(all_params)))]
  dir.create(config_dir, recursive = TRUE, showWarnings = FALSE)
  writeLines(c("# Household income by income concept and household type (euro)",
               "# Source: StatLine 83932NED, written by inhatab_update_params()",
               yaml::as.yaml(all_params)), yaml_path)
  cat(sprintf("Written inhatab params.yaml (%d years)\n", length(all_params)))
  invisible(all_params)
}


# AOW (state pension) age, rounded to whole years
.aow_age <- function(year) {
  data.table::fcase(year < 2013L, 65L, year < 2022L, 66L, default = 67L)
}

# Map spine household type (TYPHH) and reference-person age to the
# 83932NED household types in .INCOME_TYPES. Institutional and multiple
# households (8, 9) are not in 83932NED and get the national distribution.
.income_type <- function(typhh, ref_age, year) {
  aow <- ref_age >= .aow_age(year)
  data.table::fcase(
    typhh == "1" & !aow,            "eenpersoons_jong",
    typhh == "1" & aow,             "eenpersoons_aow",
    typhh %in% c("2", "3") & !aow,  "paar_zonder_jong",
    typhh %in% c("2", "3") & aow,   "paar_zonder_aow",
    typhh %in% c("4", "5"),         "paar_met",
    typhh == "6",                   "eenouder",
    typhh == "7",                   "overig",
    default =                       "totaal"
  )
}

# Lognormal parameters from a mean and median: median = exp(mu),
# mean = exp(mu + sigma^2 / 2)
# Share of households with negative disposable income (assumption)
.HH_INCOME_LOSS_SHARE <- 0.01
# Share of private households whose income is unknown in INHATAB (assumption)
.HH_INCOME_UNKNOWN_SHARE <- 0.01

.lnorm_from_mean_median <- function(mean, median) {
  list(mu = log(median), sigma = sqrt(2 * log(pmax(mean / median, 1.001))))
}

# Simulate household income for the spine.
#
# Disposable income (BESTINKH) is lognormal per household type, with mean and
# median from 83932NED, and correlated with the WOZ value of the dwelling
# through a Gaussian copula (`rho`). The other concepts are derived from it:
# gross and primary income scale disposable income by the type's ratio of
# medians with some household-level noise, and standardised income divides it
# by the type's equivalence factor (ratio of disposable to standardised
# median), so the concepts stay consistent per household.
#
# Returns a data.table with BESTINKH, BRUTINKH, PRIMINKH and GESTINKH, one
# row per element of `typhh`.
.simulate_hh_income <- function(typhh, ref_age, woz_rank, year, rho = 0.5) {
  p <- inhatab_cbs_params(year)
  type <- .income_type(typhh, ref_age, year)
  n <- length(type)

  z <- rho * stats::qnorm(woz_rank) + sqrt(1 - rho^2) * stats::rnorm(n)

  get <- function(concept, stat) {
    vapply(p[type], function(tp) as.numeric(tp[[concept]][[stat]]), numeric(1L))
  }
  ln_best <- .lnorm_from_mean_median(get("besteedbaar", "mean"),
                                     get("besteedbaar", "median"))
  best <- exp(ln_best$mu + ln_best$sigma * z)
  # A small share of households (mostly self-employed) has a loss, so
  # disposable income below zero (share assumed, not from StatLine)
  loss <- stats::runif(n) < .HH_INCOME_LOSS_SHARE
  best[loss] <- -exp(stats::rnorm(sum(loss), log(5000), 1))

  med_best <- get("besteedbaar", "median")
  bruto  <- best * get("bruto", "median") / med_best * exp(stats::rnorm(n, 0, 0.10))
  prim   <- best * get("primair", "median") / med_best * exp(stats::rnorm(n, 0, 0.35))
  gest   <- best * get("gestandaardiseerd", "median") / med_best

  data.table::data.table(
    BESTINKH = as.integer(round(best, -2L)),
    BRUTINKH = as.integer(round(pmax(bruto, best), -2L)),
    PRIMINKH = as.integer(round(prim, -2L)),
    GESTINKH = as.integer(round(gest, -2L))
  )
}


# One row per household for INHATAB: the first present member stands in as
# RINPERSOON, RINPERSOONHKW is derived from HUISHOUDNR as for INPATAB, and the
# income columns come from the household spine. INC_STATUS marks
# institutional households (I) and private households with unknown income
# (U), which carry special codes in INHATAB (columns/inhatab.yaml).
.build_inhatab_households <- function(spine) {
  pers <- spine$pers
  if (!is.null(spine$pers_present)) pers <- pers[spine$pers_present]
  hh_pers <- pers[, .(RINPERSOON = RINPERSOON[1L], INHAHL = .N), by = HUISHOUDNR]

  inc_cols <- c("BESTINKH", "BRUTINKH", "PRIMINKH", "GESTINKH",
                "P100HBEST", "P100HBRUT", "P100HPRIM", "P100HGEST")
  hh_pers[spine$hh, on = "HUISHOUDNR", (inc_cols) := mget(paste0("i.", inc_cols))]
  hh_pers[, RINPERSOONHKW := .deterministic_hkw_id(HUISHOUDNR)]
  hh_pers[spine$hh, on = "HUISHOUDNR", TYPHH := i.TYPHH]
  hh_pers[, INC_STATUS := fifelse(TYPHH %in% "8", "I", fifelse(
    .hash_to_uniform(as.character(HUISHOUDNR), "income_unknown") <
      .HH_INCOME_UNKNOWN_SHARE, "U", "P"))]
  hh_pers[]
}
