# Fixed distributions that do not vary by year.
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
    gem_codes   = NULL,   # populated from gem_weights.csv
    gem_probs   = NULL
  )
}

#' Load CBS population parameters for a given year
#'
#' Reads year-specific aggregate parameters (n_persons, n_hh, typhh_p) from
#' `params.yaml` and municipality weights from `gem_weights.csv`.  Fixed
#' distributions (eigenaar, woningtype, bouwjaar, etc.) are appended from
#' internal defaults.
#'
#' If the requested year is missing from the YAML, the nearest available year
#' is used with a warning.
#'
#' @param year Integer year (default 2023).
#' @return A named list of population parameters.
#' @export
woonbase_cbs_params <- function(year = 2023L) {

  # ---- Annual aggregates (YAML) ----
  yaml_path <- .wb_annual_yaml()
  if (!nzchar(yaml_path) || !file.exists(yaml_path))
    stop("Parameter file not found. Ensure simcbsradata is properly installed.",
         "\nExpected: inst/config/datasets/woonbase/params.yaml")

  all_params <- yaml::read_yaml(yaml_path)
  yr_key     <- as.character(year)

  if (yr_key %in% names(all_params)) {
    yr_data <- all_params[[yr_key]]
  } else {
    avail   <- sort(as.integer(names(all_params)))
    nearest <- avail[which.min(abs(avail - year))]
    warning(sprintf("Year %d not in params.yaml; using nearest year %d.", year, nearest))
    yr_data <- all_params[[as.character(nearest)]]
  }

  p <- .wb_fixed_params(year)
  p$n_persons   <- as.integer(yr_data$n_persons)
  p$n_hh        <- as.integer(yr_data$n_hh)
  p$n_obj       <- round(p$n_hh * 1.035)
  p$avg_hh_size <- p$n_persons / p$n_hh
  p$typhh_p     <- unlist(yr_data$typhh_p)

  # ---- Gemeente weights (CSV) ----
  csv_path <- .wb_gem_weights_csv()
  if (nzchar(csv_path) && file.exists(csv_path)) {
    gw_all <- data.table::fread(csv_path, colClasses = c("character", "integer", "numeric"))
    yr_filter <- as.integer(year)
    gw <- gw_all[year == yr_filter]
    if (nrow(gw) == 0L) {
      # Fall back to nearest year in CSV
      avail_csv <- sort(unique(gw_all$year))
      nearest_csv <- avail_csv[which.min(abs(avail_csv - yr_filter))]
      warning(sprintf("Year %d not in gem_weights.csv; using nearest year %d.", yr_filter, nearest_csv))
      gw <- gw_all[year == nearest_csv]
    }
    p$gem_codes <- gw$gem_code
    p$gem_probs <- gw$weight
  } else {
    # Fallback: 30 large municipalities, uniform
    p$gem_codes <- sprintf("%04d", c(363,599,518,344,503,268,307,392,398,400,
                                      14,15,16,17,18,19,20,21,22,23,
                                      106,114,153,163,171,175,180,193,196,200))
    p$gem_probs <- NULL
  }

  # ---- WOZ means per gemeente (CSV) ----
  woz_csv <- .wb_woz_means_csv()
  if (nzchar(woz_csv) && file.exists(woz_csv)) {
    woz_all <- data.table::fread(woz_csv, colClasses = c("character", "integer", "numeric"))
    yr_filter <- as.integer(year)
    woz <- woz_all[year == yr_filter]
    if (nrow(woz) == 0L) {
      avail_woz <- sort(unique(woz_all$year))
      nearest_woz <- avail_woz[which.min(abs(avail_woz - yr_filter))]
      warning(sprintf("Year %d not in woz_means.csv; using nearest year %d.", yr_filter, nearest_woz))
      woz <- woz_all[year == nearest_woz]
    }
    # Named vector: gem_code → mean WOZ in euros
    p$woz_gem_means <- stats::setNames(woz$woz_mean, woz$gem_code)
    p$woz_national_mean <- mean(woz$woz_mean, na.rm = TRUE)
  } else {
    p$woz_gem_means <- NULL
    p$woz_national_mean <- 300000
  }

  message(sprintf("CBS population %d: %s persons, %s households, %d gemeenten",
                  year, format(p$n_persons, big.mark=","),
                  format(p$n_hh, big.mark=","), length(p$gem_codes)))
  p
}

#' Fetch CBS StatLine data and write to params.yaml and gem_weights.csv
#'
#' Queries CBS StatLine via `cbsodataR` for population and household counts
#' for the requested years, and writes the results to two files:
#' \itemize{
#'   \item `params.yaml` — n_persons, n_hh, typhh_p per year
#'   \item `gem_weights.csv` — gemeente population weights per year
#' }
#' Run once (or whenever CBS publishes new data) to refresh the parameters.
#'
#' @param years Integer vector of years to fetch (default `2016:2024`).
#' @param config_dir  Directory to write files into.  Defaults to the package's
#'   bundled `inst/config/` (useful during development).
#' @return Invisibly, the full annual parameter list.
#' @export
woonbase_update_params <- function(years = 2016:2024,
                                   config_dir = dirname(.wb_annual_yaml())) {
  if (!requireNamespace("cbsodataR", quietly = TRUE))
    stop("Package 'cbsodataR' is required. Install with install.packages('cbsodataR').")

  yaml_path <- file.path(config_dir, "params.yaml")
  csv_path  <- file.path(config_dir, "gem_weights.csv")
  woz_path  <- file.path(config_dir, "woz_means.csv")

  # Load existing YAML if present (merge new years into it)
  if (file.exists(yaml_path)) {
    all_annual <- yaml::read_yaml(yaml_path)
  } else {
    all_annual <- list()
  }

  # Load existing CSV if present
  if (file.exists(csv_path)) {
    gw_all <- data.table::fread(csv_path, colClasses = c("character", "integer", "numeric"))
  } else {
    gw_all <- data.table::data.table(gem_code = character(), year = integer(), weight = numeric())
  }

  # Load existing WOZ means CSV if present
  if (file.exists(woz_path)) {
    woz_all <- data.table::fread(woz_path, colClasses = c("character", "integer", "numeric"))
  } else {
    woz_all <- data.table::data.table(gem_code = character(), year = integer(), woz_mean = numeric())
  }

  cat("Fetching CBS StatLine parameters:\n")

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

      # Store annual aggregates
      all_annual[[as.character(yr)]] <- list(
        n_persons = n_pers,
        n_hh      = n_hh,
        typhh_p   = typhh
      )

      # Gemeente population weights from the same 37230ned table
      gem_rows <- pop_all[grepl("^GM", trimws(pop_all$RegioS)), ]
      gem_rows$code <- sub("^GM", "", trimws(gem_rows$RegioS))
      gem_rows$pop  <- as.numeric(gem_rows$BevolkingAanHetBeginVanDePeriode_1)
      gem_rows <- gem_rows[!is.na(gem_rows$pop) & gem_rows$pop > 0, ]
      weights <- round(gem_rows$pop / sum(gem_rows$pop), 6)

      # Replace this year's rows in the data.table
      gw_all <- gw_all[year != yr]
      gw_new <- data.table::data.table(gem_code = gem_rows$code, year = yr, weight = weights)
      gw_all <- data.table::rbindlist(list(gw_all, gw_new))

      # WOZ means per gemeente (table 70072ned)
      woz_raw <- cbsodataR::cbs_get_data(
        "70072ned", Perioden = yr_code,
        select = c("RegioS", "Perioden", "GemiddeldeWOZWaardeVanWoningen_98"))
      woz_gem <- woz_raw[grepl("^GM", trimws(woz_raw$RegioS)), ]
      woz_gem$code <- sub("^GM", "", trimws(woz_gem$RegioS))
      woz_gem$woz  <- as.numeric(woz_gem$GemiddeldeWOZWaardeVanWoningen_98) * 1000
      woz_gem <- woz_gem[!is.na(woz_gem$woz) & woz_gem$woz > 0, ]

      woz_all <- woz_all[year != yr]
      woz_new <- data.table::data.table(gem_code = woz_gem$code, year = yr, woz_mean = woz_gem$woz)
      woz_all <- data.table::rbindlist(list(woz_all, woz_new))

      cat(sprintf("%s persons, %s households, %d gemeenten, %d WOZ\n",
                  format(n_pers, big.mark = ","), format(n_hh, big.mark = ","),
                  nrow(gem_rows), nrow(woz_gem)))
    }, error = function(e) {
      cat(sprintf("FAILED (%s)\n", conditionMessage(e)))
    })
  }

  # Sort and write YAML
  all_annual <- all_annual[order(as.integer(names(all_annual)))]
  dir.create(config_dir, recursive = TRUE, showWarnings = FALSE)
  yaml::write_yaml(all_annual, yaml_path)
  cat(sprintf("Written params.yaml (%d years)\n", length(all_annual)))

  # Sort and write CSV
  data.table::setorder(gw_all, year, gem_code)
  data.table::fwrite(gw_all, csv_path)
  cat(sprintf("Written gem_weights.csv (%d rows)\n", nrow(gw_all)))

  # Sort and write WOZ means CSV
  data.table::setorder(woz_all, year, gem_code)
  data.table::fwrite(woz_all, woz_path)
  cat(sprintf("Written woz_means.csv (%d rows)\n", nrow(woz_all)))

  invisible(all_annual)
}
