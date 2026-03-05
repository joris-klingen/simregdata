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
  p$stadsverwarming_pct <- as.numeric(yr_data$stadsverwarming_pct %||% 0)

  # Derived categorical probability vectors for from_params columns
  pv <- p$solar_pv_share
  p$solar_pv_categorical <- list("0" = round(1 - pv, 4), "1" = round(pv, 4))

  sw <- p$stadsverwarming_pct / 100
  p$stadsverwarming_categorical <- list("0" = round(1 - sw, 4), "1" = round(sw, 4))

  message(sprintf("ENERGIEVERBRUIK params %d: %s dwellings, gas_mean=%.0f m3, elek_mean=%.0f kWh, solar=%.0f%%, stadsvw=%.1f%%",
                  year, format(p$n_dwellings, big.mark = ","),
                  p$gas_mean, p$elek_mean, p$solar_pv_share * 100,
                  p$stadsverwarming_pct))
  p
}


#' Fetch CBS Kerncijfers wijken en buurten and update energieverbruik params.yaml
#'
#' Queries CBS StatLine "Kerncijfers wijken en buurten" tables for national
#' averages of gas consumption, electricity consumption, district heating
#' share, and dwelling count. The table ID changes each year.
#'
#' @param years Integer vector of years to fetch (default `2017:2023`).
#' @param config_dir Directory to write params.yaml into.
#' @return Invisibly, the full parameter list.
#' @export
energieverbruik_update_params <- function(years = 2017:2023,
                                          config_dir = .dataset_dir("energieverbruik")) {
  if (!requireNamespace("cbsodataR", quietly = TRUE))
    stop("Package 'cbsodataR' is required. Install with install.packages('cbsodataR').")

  yaml_path <- file.path(config_dir, "params.yaml")

  # Load existing YAML if present
  if (file.exists(yaml_path)) {
    all_params <- yaml::read_yaml(yaml_path)
  } else {
    all_params <- list()
  }

  # Table IDs per year (Kerncijfers wijken en buurten)
  table_ids <- list(
    "2017" = "83765NED",
    "2018" = "84286NED",
    "2019" = "84583NED",
    "2020" = "84799NED",
    "2021" = "85039NED",
    "2022" = "85318NED",
    "2023" = "85618NED"
  )

  # NL00 national aggregate, padded to 10 chars
  nl_code <- "NL00      "

  cat("Fetching CBS Kerncijfers wijken en buurten (energieverbruik):\n")

  for (yr in years) {
    yr_str <- as.character(yr)
    cat(sprintf("  %d: ", yr))

    if (!yr_str %in% names(table_ids)) {
      cat("SKIPPED (no table ID known)\n")
      next
    }

    tryCatch({
      tid <- table_ids[[yr_str]]
      tbl <- cbsodataR::cbs_get_data(tid, WijkenEnBuurten = nl_code)

      if (nrow(tbl) == 0L) {
        cat("SKIPPED (no NL00 row)\n")
        next
      }

      row <- tbl[1L, ]

      # Existing params for this year (preserve solar_pv_share etc.)
      yr_data <- all_params[[yr_str]]
      if (is.null(yr_data)) yr_data <- list()

      # Find columns by pattern (suffix number varies across years)
      cnames <- names(row)

      # Gas mean
      gas_col <- grep("^GemiddeldAardgasverbruikTotaal_", cnames, value = TRUE)
      if (length(gas_col) > 0L) {
        gas_val <- as.numeric(row[[gas_col[1L]]])
        if (!is.na(gas_val) && gas_val > 0) {
          yr_data$gas_mean <- round(gas_val)
          yr_data$gas_sd   <- round(gas_val * 0.5)
        }
      }

      # Electricity mean (available from 2021+)
      elek_col <- grep("^GemiddeldeElektriciteitsleveringTotaal_", cnames, value = TRUE)
      if (length(elek_col) > 0L) {
        elek_val <- as.numeric(row[[elek_col[1L]]])
        if (!is.na(elek_val) && elek_val > 0) {
          yr_data$elek_mean <- round(elek_val)
          yr_data$elek_sd   <- round(elek_val * 0.45)
        }
      }

      # District heating percentage
      sw_col <- grep("^PercentageWoningenMetStadsverwarming_", cnames, value = TRUE)
      if (length(sw_col) > 0L) {
        sw_val <- as.numeric(row[[sw_col[1L]]])
        if (!is.na(sw_val)) {
          yr_data$stadsverwarming_pct <- round(sw_val, 1)
        }
      }

      # Number of dwellings
      dw_col <- grep("^Woningvoorraad_", cnames, value = TRUE)
      if (length(dw_col) > 0L) {
        dw_val <- as.numeric(row[[dw_col[1L]]])
        if (!is.na(dw_val) && dw_val > 0) {
          yr_data$n_dwellings <- as.integer(dw_val)
        }
      }

      all_params[[yr_str]] <- yr_data

      cat(sprintf("gas=%s, elek=%s, stadsvw=%s%%, n=%s\n",
                  yr_data$gas_mean %||% "NA",
                  yr_data$elek_mean %||% "NA",
                  yr_data$stadsverwarming_pct %||% "NA",
                  format(yr_data$n_dwellings %||% NA, big.mark = ",")))

    }, error = function(e) {
      cat(sprintf("FAILED (%s)\n", conditionMessage(e)))
    })
  }

  # Sort and write YAML
  all_params <- all_params[order(as.integer(names(all_params)))]
  dir.create(config_dir, recursive = TRUE, showWarnings = FALSE)
  yaml::write_yaml(all_params, yaml_path)
  cat(sprintf("Written energieverbruik params.yaml (%d years)\n", length(all_params)))

  invisible(all_params)
}
