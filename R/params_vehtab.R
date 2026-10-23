# VEHTAB parameter loading ----

# Path to VEHTAB params YAML
.vehtab_params_yaml <- function() {
  file.path(.dataset_dir("vehtab"), "params.yaml")
}


#' Load cached VEHTAB parameters for a given year
#'
#' Reads year-specific household wealth parameters from
#' `inst/config/datasets/vehtab/params.yaml`.
#'
#' @param year Integer year (default 2023).
#' @return A named list of wealth parameters.
#' @export
vehtab_cbs_params <- function(year = 2023L) {

  yaml_path <- .vehtab_params_yaml()
  if (!nzchar(yaml_path) || !file.exists(yaml_path))
    stop("VEHTAB parameter file not found. ",
         "Ensure simregdata is properly installed.",
         "\nExpected: inst/config/datasets/vehtab/params.yaml")

  all_params <- yaml::read_yaml(yaml_path)
  yr_key <- as.character(year)

  if (yr_key %in% names(all_params)) {
    yr_data <- all_params[[yr_key]]
  } else {
    avail <- sort(as.integer(names(all_params)))
    nearest <- avail[which.min(abs(avail - year))]
    warning(sprintf("Year %d not in vehtab params.yaml; using nearest year %d.", year, nearest))
    yr_data <- all_params[[as.character(nearest)]]
  }

  p <- list(year = as.integer(year))
  p$n_households <- as.integer(yr_data$n_households)

  # Wealth component means and sds
  wealth_keys <- c("bezh", "finh", "banh", "effh", "onrh", "wonh", "ogoh",
                   "ondh", "abeh", "oveh", "stoh", "shyh", "ssth", "sovh",
                   "verexewh")
  for (k in wealth_keys) {
    mk <- paste0(k, "_mean")
    sk <- paste0(k, "_sd")
    if (!is.null(yr_data[[mk]])) p[[mk]] <- as.numeric(yr_data[[mk]])
    if (!is.null(yr_data[[sk]])) p[[sk]] <- as.numeric(yr_data[[sk]])
  }

  message(sprintf("VEHTAB params %d: %s households",
                  year, format(p$n_households, big.mark = ",")))
  p
}


#' Fetch CBS StatLine wealth data and write VEHTAB params.yaml
#'
#' Queries CBS StatLine table 83834NED (Vermogen van huishoudens;
#' huishoudenskenmerken) for calibrated mean wealth component values.
#' Standard deviations are estimated using empirical CV ratios appropriate
#' for the highly right-skewed wealth distribution.
#'
#' @param years Integer vector of years to fetch (default `2006:2024`).
#' @param config_dir Directory to write params.yaml into.
#' @return Invisibly, the full parameter list.
#' @export
vehtab_update_params <- function(years = 2006:2024,
                                  config_dir = .dataset_dir("vehtab")) {
  if (!requireNamespace("cbsodataR", quietly = TRUE))
    stop("Package 'cbsodataR' is required. Install with install.packages('cbsodataR').")

  yaml_path <- file.path(config_dir, "params.yaml")

  # Load existing YAML if present (preserves n_households etc.)

  if (file.exists(yaml_path)) {
    all_params <- yaml::read_yaml(yaml_path)
  } else {
    all_params <- list()
  }

  # Mapping: Vermogensbestanddelen code -> param key
  verm_map <- c(
    "1021410" = "bezh",
    "1021420" = "finh",
    "1021421" = "banh",
    "1021470" = "effh",
    "1021430" = "onrh",
    "1021431" = "wonh",
    "1021432" = "ogoh",
    "1021450" = "ondh",
    "1021424" = "abeh",
    "1021440" = "oveh",
    "1021460" = "stoh",
    "1021461" = "shyh",
    "1021426" = "ssth",
    "1021462" = "sovh",
    "1021480" = "verexewh")

  # CV ratios for sd estimation (wealth is very right-skewed)
  cv_ratios <- stats::setNames(
    rep(1.5, length(verm_map)),
    verm_map)
  cv_ratios["shyh"] <- 0.8      # mortgage: less skewed
  cv_ratios["ssth"] <- 1.0      # student debt: moderate skew

  cat("Fetching CBS StatLine 83834NED wealth parameters:\n")

  for (yr in years) {
    yr_code <- paste0(yr, "JJ00")
    cat(sprintf("  %d: ", yr))

    tryCatch({
      # Fetch data for total households (1050010) for this year
      t834 <- cbsodataR::cbs_get_data(
        "83834NED",
        KenmerkenVanHuishoudens = "1050010",
        Perioden = yr_code)

      if (nrow(t834) == 0L) {
        cat("no data\n")
        next
      }

      yr_key <- as.character(yr)
      yr_data <- all_params[[yr_key]] %||% list()

      n_set <- 0L
      for (vcode in names(verm_map)) {
        pkey <- verm_map[[vcode]]
        row <- t834[trimws(t834$Vermogensbestanddelen) == vcode, ]
        if (nrow(row) == 0L) next

        mean_x1000 <- as.numeric(row$GemiddeldVermogen_3[1L])
        if (is.na(mean_x1000)) next

        mean_eur <- mean_x1000 * 1000
        sd_eur <- round(abs(mean_eur) * cv_ratios[[pkey]])

        yr_data[[paste0(pkey, "_mean")]] <- round(mean_eur)
        yr_data[[paste0(pkey, "_sd")]]   <- sd_eur
        n_set <- n_set + 1L
      }

      all_params[[yr_key]] <- yr_data

      bezh_val <- yr_data$bezh_mean %||% NA
      stoh_val <- yr_data$stoh_mean %||% NA
      cat(sprintf("%d components, bezh_mean=%s, stoh_mean=%s\n",
                  n_set,
                  format(bezh_val, big.mark = ","),
                  format(stoh_val, big.mark = ",")))

    }, error = function(e) {
      cat(sprintf("FAILED (%s)\n", conditionMessage(e)))
    })
  }

  # Sort and write YAML
  all_params <- all_params[order(as.integer(names(all_params)))]
  dir.create(config_dir, recursive = TRUE, showWarnings = FALSE)
  yaml::write_yaml(all_params, yaml_path)
  cat(sprintf("Written vehtab params.yaml (%d years)\n", length(all_params)))

  invisible(all_params)
}
