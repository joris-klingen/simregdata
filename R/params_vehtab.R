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
         "Ensure simcbsradata is properly installed.",
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

  message(sprintf("VEHTAB params %d: %s households",
                  year, format(p$n_households, big.mark = ",")))
  p
}
