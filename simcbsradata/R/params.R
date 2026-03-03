# Fixed distributions that do not vary by year in the YAML.
.wb_fixed_params <- function(year) {
  list(
    year        = year,
    avg_hh_size = 2.145,
    eigenaar_p  = c(C=0.295, V=0.121, E=0.559, O=0.015, `9`=0.010),
    woningtype_p = c("00"=0.010,"01"=0.138,"02"=0.112,"03"=0.143,"04"=0.281,"05"=0.306,"99"=0.010),
    bouwjaar_p  = c(0.048,0.063,0.070,0.085,0.103,0.121,0.121,0.101,0.097,0.088,0.050,0.036,0.010,0.004,0.003),
    woz_p       = c("1"=0.096,"2"=0.241,"3"=0.248,"4"=0.176,"5"=0.103,"6"=0.064,"7"=0.058,"9"=0.014),
    opp_p       = c("1"=0.082,"2"=0.228,"3"=0.256,"4"=0.224,"5"=0.142,"6"=0.058,"9"=0.010),
    geslacht_p  = c("1"=0.495,"2"=0.505),
    soortobj_p  = c(B=0.900,H=0.040,D=0.050,O=0.010),
    vslsoort_p  = c("1"=0.878,"2"=0.022,"3"=0.032,"4"=0.012,"5"=0.041,"6"=0.015),
    gem_codes   = NULL,   # populated from YAML (all municipalities with weights)
    gem_probs   = NULL
  )
}

#' Load CBS population parameters for a given year
#'
#' Reads year-specific parameters (n_persons, n_hh, typhh_p, gem_weights)
#' from the bundled `woonbase_params.yaml`.  Fixed distributions (eigenaar,
#' woningtype, bouwjaar, etc.) are appended from internal defaults.
#'
#' If the requested year is missing from the YAML, the nearest available year
#' is used with a warning.
#'
#' @param year Integer year (default 2023).
#' @return A named list of population parameters.
#' @export
woonbase_cbs_params <- function(year = 2023L) {
  yaml_path <- .wb_params_yaml()
  if (!nzchar(yaml_path) || !file.exists(yaml_path))
    stop("Parameter file not found. Ensure simcbsradata is properly installed.",
         "\nExpected: inst/config/woonbase_params.yaml")

  all_params <- yaml::read_yaml(yaml_path)
  yr_key     <- as.character(year)

  if (yr_key %in% names(all_params)) {
    yr_data <- all_params[[yr_key]]
  } else {
    avail   <- sort(as.integer(names(all_params)))
    nearest <- avail[which.min(abs(avail - year))]
    warning(sprintf("Year %d not in woonbase_params.yaml; using nearest year %d.", year, nearest))
    yr_data <- all_params[[as.character(nearest)]]
  }

  p <- .wb_fixed_params(year)
  p$n_persons  <- as.integer(yr_data$n_persons)
  p$n_hh       <- as.integer(yr_data$n_hh)
  p$n_obj      <- round(p$n_hh * 1.035)
  p$avg_hh_size <- p$n_persons / p$n_hh
  p$typhh_p    <- unlist(yr_data$typhh_p)

  # Gemeente weights (code -> population proportion)
  gw <- unlist(yr_data$gem_weights)
  if (!is.null(gw) && length(gw) > 0L) {
    p$gem_codes <- names(gw)
    p$gem_probs <- as.numeric(gw)
  } else {
    # Fallback: 30 large municipalities, uniform
    p$gem_codes <- sprintf("%04d", c(363,599,518,344,503,268,307,392,398,400,
                                      14,15,16,17,18,19,20,21,22,23,
                                      106,114,153,163,171,175,180,193,196,200))
    p$gem_probs <- NULL
  }

  message(sprintf("CBS population %d: %s persons, %s households, %d gemeenten (from YAML)",
                  year, format(p$n_persons, big.mark=","),
                  format(p$n_hh, big.mark=","), length(p$gem_codes)))
  p
}

#' Fetch CBS StatLine data and write to woonbase_params.yaml
#'
#' Queries CBS StatLine via `cbsodataR` for population and household counts
#' for the requested years, and writes the results to a YAML file.  Run once
#' (or whenever CBS publishes new data) to refresh the parameters.
#'
#' @param years Integer vector of years to fetch (default `2016:2024`).
#' @param path  Path to write the YAML file.  Defaults to the package's
#'   bundled copy (useful during development).  Pass a custom path when the
#'   package is installed read-only.
#' @return Invisibly, the full parameter list.
#' @export
woonbase_update_params <- function(years = 2016:2024, path = .wb_params_yaml()) {
  if (!requireNamespace("cbsodataR", quietly = TRUE))
    stop("Package 'cbsodataR' is required. Install with install.packages('cbsodataR').")

  # Load existing YAML if present (merge new years into it)
  if (file.exists(path)) {
    all_params <- yaml::read_yaml(path)
  } else {
    all_params <- list()
  }

  cat("Fetching CBS StatLine parameters (not data generation):\n")

  for (yr in years) {
    yr_code <- paste0(yr, "JJ00")
    cat(sprintf("  %d: ", yr))

    tryCatch({
      # Population on 1 January (table 37230ned)
      pop_all <- cbsodataR::cbs_get_data("37230ned", Perioden = yr_code)
      pop <- pop_all[trimws(pop_all$RegioS) == "NL01", ]
      if (nrow(pop) == 0L) stop("no NL01 row")
      n_pers <- as.integer(pop$BevolkingAanHetBeginVanDePeriode_1[[1]])

      # Households (table 71486ned)
      hh_all <- cbsodataR::cbs_get_data("71486ned", Perioden = yr_code)
      hh <- hh_all[trimws(hh_all$RegioS) == "NL01" &
                   trimws(hh_all$LeeftijdReferentiepersoon) == "10000", ]
      if (nrow(hh) == 0L) stop("no NL01/totaal row")
      n_hh <- as.integer(hh$TotaalParticuliereHuishoudens_1[[1]])

      # TYPHH proportions
      hh_1 <- as.numeric(hh$Eenpersoonshuishouden_2[[1]])
      hh_2 <- as.numeric(hh$k_0Kinderen_7[[1]])
      hh_3 <- as.numeric(hh$k_0Kinderen_12[[1]])
      hh_4 <- as.numeric(hh$TotaalNietGehuwdeParen_6[[1]]) - hh_2
      hh_5 <- as.numeric(hh$TotaalGehuwdeParen_11[[1]]) - hh_3
      hh_6 <- as.numeric(hh$TotaalEenouderhuishoudens_16[[1]])
      hh_7 <- as.numeric(hh$OverigHuishouden_20[[1]])
      hh_tot <- hh_1 + hh_2 + hh_3 + hh_4 + hh_5 + hh_6 + hh_7
      pct   <- round(c(hh_1, hh_2, hh_3, hh_4, hh_5, hh_6, hh_7) / hh_tot * (1 - 0.014), 4)

      typhh <- as.list(setNames(pct, as.character(1:7)))
      typhh[["8"]] <- 0.014

      # Gemeente population weights from the same 37230ned table
      gem_rows <- pop_all[grepl("^GM", trimws(pop_all$RegioS)), ]
      gem_rows$code <- sub("^GM", "", trimws(gem_rows$RegioS))
      gem_rows$pop  <- as.numeric(gem_rows$BevolkingAanHetBeginVanDePeriode_1)
      gem_rows <- gem_rows[!is.na(gem_rows$pop) & gem_rows$pop > 0, ]
      gem_weights <- as.list(setNames(
        round(gem_rows$pop / sum(gem_rows$pop), 6),
        gem_rows$code
      ))

      all_params[[as.character(yr)]] <- list(
        n_persons   = n_pers,
        n_hh        = n_hh,
        typhh_p     = typhh,
        gem_weights = gem_weights
      )
      cat(sprintf("%s persons, %s households, %d gemeenten\n",
                  format(n_pers, big.mark = ","), format(n_hh, big.mark = ","),
                  length(gem_weights)))
    }, error = function(e) {
      cat(sprintf("FAILED (%s)\n", conditionMessage(e)))
    })
  }

  # Sort by year and write
  all_params <- all_params[order(as.integer(names(all_params)))]

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  yaml::write_yaml(all_params, path)
  cat(sprintf("Written to %s (%d years)\n", path, length(all_params)))
  invisible(all_params)
}
