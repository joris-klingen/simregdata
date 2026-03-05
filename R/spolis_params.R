# SPOLIS parameter loading and StatLine calibration ----

# Path to SPOLIS params YAML
.spolis_params_yaml <- function() {
  file.path(.dataset_dir("spolis"), "params.yaml")
}


#' Load cached SPOLIS parameters for a given year
#'
#' Reads year-specific employment parameters from
#' `inst/config/datasets/spolis/params.yaml`.
#'
#' @param year Integer year (default 2023).
#' @return A named list of employment parameters.
#' @export
spolis_cbs_params <- function(year = 2023L) {

  yaml_path <- .spolis_params_yaml()
  if (!nzchar(yaml_path) || !file.exists(yaml_path))
    stop("SPOLIS parameter file not found. Run spolis_update_params() first, or ",
         "ensure simcbsradata is properly installed.",
         "\nExpected: inst/config/datasets/spolis/params.yaml")

  all_params <- yaml::read_yaml(yaml_path)
  yr_key <- as.character(year)

  if (yr_key %in% names(all_params)) {
    yr_data <- all_params[[yr_key]]
  } else {
    avail <- sort(as.integer(names(all_params)))
    nearest <- avail[which.min(abs(avail - year))]
    warning(sprintf("Year %d not in spolis params.yaml; using nearest year %d.", year, nearest))
    yr_data <- all_params[[as.character(nearest)]]
  }

  p <- list(year = as.integer(year))
  p$n_jobs           <- as.integer(yr_data$n_jobs)
  p$dienstverband_p  <- unlist(yr_data$dienstverband_p)
  p$loon_mean        <- as.numeric(yr_data$loon_mean)
  p$loon_sd          <- as.numeric(yr_data$loon_sd)
  p$wekarbduur_p     <- unlist(yr_data$wekarbduur_p)
  p$soortbaan_p      <- unlist(yr_data$soortbaan_p)
  p$ssect_p          <- unlist(yr_data$ssect_p)

  message(sprintf("SPOLIS params %d: %s jobs, loon_mean=%.0f, FT=%.0f%%",
                  year, format(p$n_jobs, big.mark = ","), p$loon_mean,
                  (p$dienstverband_p[["1"]] %||% 0) * 100))
  p
}


#' Fetch CBS StatLine data and write SPOLIS params.yaml
#'
#' Queries CBS StatLine for employment data:
#' \itemize{
#'   \item `81431NED` — Banen van werknemers; economische activiteit (SBI2008)
#'         (job counts, FT/PT ratio, sector breakdown)
#' }
#'
#' @param years Integer vector of years to fetch (default `2019:2025`).
#' @param config_dir Directory to write params.yaml into.
#' @return Invisibly, the full parameter list.
#' @export
spolis_update_params <- function(years = 2019:2025,
                                 config_dir = .dataset_dir("spolis")) {
  if (!requireNamespace("cbsodataR", quietly = TRUE))
    stop("Package 'cbsodataR' is required. Install with install.packages('cbsodataR').")

  yaml_path <- file.path(config_dir, "params.yaml")

  # Load existing YAML if present
  if (file.exists(yaml_path)) {
    all_params <- yaml::read_yaml(yaml_path)
  } else {
    all_params <- list()
  }

  cat("Fetching CBS StatLine SPOLIS parameters:\n")

  for (yr in years) {
    yr_code <- paste0(yr, "JJ00")
    cat(sprintf("  %d: ", yr))

    tryCatch({
      yr_data <- list()

      # --- 81431NED: Banen werknemers; economische activiteit ---
      t431 <- cbsodataR::cbs_get_data("81431NED", Perioden = yr_code)

      # Total row: SBI2008 = T001081 (Totaal)
      tot <- t431[trimws(t431$SBI2008) == "T001081", ]

      if (nrow(tot) > 0L) {
        row <- tot[1L, ]

        # Total number of jobs
        n_total <- as.numeric(row$BanenVanWerknemers_1)
        if (!is.na(n_total) && n_total > 0) {
          yr_data$n_jobs <- as.integer(n_total * 1000)  # CBS reports in 1000s
        }

        # Full-time / part-time ratio
        ft <- as.numeric(row$Voltijd_2)
        pt <- as.numeric(row$Deeltijd_3)
        if (!is.na(ft) && !is.na(pt) && (ft + pt) > 0) {
          total_ftpt <- ft + pt
          yr_data$dienstverband_p <- list(
            "1" = round(ft / total_ftpt, 2),
            "2" = round(pt / total_ftpt, 2))
        }

        # Average monthly wage (loon in geld)
        loon <- as.numeric(row$GemiddeldMaandloonInclusiefBijzondereB_4)
        if (!is.na(loon) && loon > 0) {
          yr_data$loon_mean <- round(loon)
          yr_data$loon_sd <- round(loon * 0.55)  # empirical CV ~0.55
        }
      }

      # Sector breakdown from non-total rows
      sect_rows <- t431[!grepl("^T", trimws(t431$SBI2008)), ]
      if (nrow(sect_rows) > 0L) {
        sect_n <- as.numeric(sect_rows$BanenVanWerknemers_1)
        sect_n[is.na(sect_n)] <- 0
        sect_total <- sum(sect_n)
        if (sect_total > 0) {
          sect_p <- round(sect_n / sect_total, 4)
          sect_labels <- trimws(sect_rows$SBI2008)
          # Keep top sectors only for compact YAML
          keep <- sect_p >= 0.02
          if (sum(keep) > 0) {
            yr_data$sbi_p <- as.list(stats::setNames(sect_p[keep], sect_labels[keep]))
          }
        }
      }

      all_params[[as.character(yr)]] <- yr_data

      cat(sprintf("%s jobs, FT=%.0f%%, loon=%d\n",
                  format(yr_data$n_jobs %||% 0L, big.mark = ","),
                  (yr_data$dienstverband_p[["1"]] %||% 0) * 100,
                  yr_data$loon_mean %||% 0L))

    }, error = function(e) {
      cat(sprintf("FAILED (%s)\n", conditionMessage(e)))
    })
  }

  # Sort and write YAML
  all_params <- all_params[order(as.integer(names(all_params)))]
  dir.create(config_dir, recursive = TRUE, showWarnings = FALSE)
  yaml::write_yaml(all_params, yaml_path)
  cat(sprintf("Written spolis params.yaml (%d years)\n", length(all_params)))

  invisible(all_params)
}
