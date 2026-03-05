# ENERGIEVERBRUIKTAB parameter loading ----

# Path to energieverbruik params YAML
.energieverbruik_params_yaml <- function() {
  file.path(.dataset_dir("energieverbruik"), "params.yaml")
}


#' Load cached ENERGIEVERBRUIKTAB parameters for a given year
#'
#' Reads year-specific energy consumption parameters from
#' `inst/config/datasets/energieverbruik/params.yaml`.
#'
#' @param year Integer year (default 2023).
#' @return A named list of energy parameters.
#' @export
energieverbruik_cbs_params <- function(year = 2023L) {

  yaml_path <- .energieverbruik_params_yaml()
  if (!nzchar(yaml_path) || !file.exists(yaml_path))
    stop("ENERGIEVERBRUIKTAB parameter file not found. ",
         "Ensure simcbsradata is properly installed.",
         "\nExpected: inst/config/datasets/energieverbruik/params.yaml")

  all_params <- yaml::read_yaml(yaml_path)
  yr_key <- as.character(year)

  if (yr_key %in% names(all_params)) {
    yr_data <- all_params[[yr_key]]
  } else {
    avail <- sort(as.integer(names(all_params)))
    nearest <- avail[which.min(abs(avail - year))]
    warning(sprintf("Year %d not in energieverbruik params.yaml; using nearest year %d.", year, nearest))
    yr_data <- all_params[[as.character(nearest)]]
  }

  p <- list(year = as.integer(year))
  p$n_dwellings       <- as.integer(yr_data$n_dwellings)
  p$gas_mean           <- as.numeric(yr_data$gas_mean)
  p$gas_sd             <- as.numeric(yr_data$gas_sd)
  p$elek_mean          <- as.numeric(yr_data$elek_mean)
  p$elek_sd            <- as.numeric(yr_data$elek_sd)
  p$solar_pv_share     <- as.numeric(yr_data$solar_pv_share)

  message(sprintf("ENERGIEVERBRUIK params %d: %s dwellings, gas_mean=%.0f m3, elek_mean=%.0f kWh, solar=%.0f%%",
                  year, format(p$n_dwellings, big.mark = ","),
                  p$gas_mean, p$elek_mean, p$solar_pv_share * 100))
  p
}
