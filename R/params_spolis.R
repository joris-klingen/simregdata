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
         "ensure simregdata is properly installed.",
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
  p$basisloon_mean   <- as.numeric(yr_data$basisloon_mean)
  p$basisloon_sd     <- as.numeric(yr_data$basisloon_sd)
  p$bijzbeloning_mean <- as.numeric(yr_data$bijzbeloning_mean)
  p$bijzbeloning_sd  <- as.numeric(yr_data$bijzbeloning_sd)
  p$autozaak_mean    <- as.numeric(yr_data$autozaak_mean)
  p$autozaak_sd      <- as.numeric(yr_data$autozaak_sd)
  p$basisuren_mean   <- as.numeric(yr_data$basisuren_mean)
  p$basisuren_sd     <- as.numeric(yr_data$basisuren_sd)
  p$reguliereuren_mean <- as.numeric(yr_data$reguliereuren_mean)
  p$reguliereuren_sd <- as.numeric(yr_data$reguliereuren_sd)
  p$lnlbph_mean      <- as.numeric(yr_data$lnlbph_mean)
  p$lnlbph_sd        <- as.numeric(yr_data$lnlbph_sd)
  p$lnsv_mean        <- as.numeric(yr_data$lnsv_mean)
  p$lnsv_sd          <- as.numeric(yr_data$lnsv_sd)
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
      yr_data <- all_params[[as.character(yr)]] %||% list()

      # --- 81431NED: Banen werknemers; economische activiteit ---
      t431 <- cbsodataR::cbs_get_data("81431NED", Perioden = yr_code)

      # Total row: BedrijfstakkenBranchesSBI2008 = T001081 (Totaal)
      tot <- t431[trimws(t431$BedrijfstakkenBranchesSBI2008) == "T001081", ]

      # Total row: Totaal SBI x Totaal kenmerken
      tot_row <- tot[trimws(tot$KenmerkenBaanWerknemerBedrijf) == "T001098", ]
      if (nrow(tot_row) == 0L) tot_row <- tot[1L, , drop = FALSE]

      if (nrow(tot_row) > 0L) {
        row <- tot_row[1L, ]

        # Total number of jobs (x1000 in table)
        n_total <- as.numeric(row$Banen_1)
        if (!is.na(n_total) && n_total > 0) {
          yr_data$n_jobs <- as.integer(n_total * 1000)
        }

        # Full-time / part-time ratio (from dimension KenmerkenBaanWerknemerBedrijf)
        ft_row <- tot[trimws(tot$KenmerkenBaanWerknemerBedrijf) == "2021240", ]
        pt_row <- tot[trimws(tot$KenmerkenBaanWerknemerBedrijf) == "2021209", ]
        ft <- if (nrow(ft_row) > 0L) as.numeric(ft_row$Banen_1[1L]) else NA
        pt <- if (nrow(pt_row) > 0L) as.numeric(pt_row$Banen_1[1L]) else NA
        if (!is.na(ft) && !is.na(pt) && (ft + pt) > 0) {
          total_ftpt <- ft + pt
          yr_data$dienstverband_p <- list(
            "1" = round(ft / total_ftpt, 2),
            "2" = round(pt / total_ftpt, 2))
        }

        # Average monthly wage (loon in geld, incl overwerk)
        loon <- as.numeric(row$MaandloonInclusiefOverwerk_4)
        if (!is.na(loon) && loon > 0) {
          yr_data$loon_mean <- round(loon)
          yr_data$loon_sd <- round(loon * 0.55)
        }

        # Basisloon (maandloon excl. overwerk)
        basisloon <- as.numeric(row$MaandloonExclusiefOverwerk_5)
        if (!is.na(basisloon) && basisloon > 0) {
          yr_data$basisloon_mean <- round(basisloon)
          yr_data$basisloon_sd   <- round(basisloon * 0.55)
        }

        # Bijzondere beloning (annual, convert to monthly)
        bijzbel <- as.numeric(row$BijzondereBeloning_8)
        if (!is.na(bijzbel) && bijzbel > 0) {
          bijzbel_m <- bijzbel / 12
          yr_data$bijzbeloning_mean <- round(bijzbel_m)
          yr_data$bijzbeloning_sd   <- round(bijzbel_m * 1.2)
        }

        # Auto van de zaak (annual, convert to monthly)
        autozaak <- as.numeric(row$BijtellingAutoVanDeZaak_9)
        if (!is.na(autozaak) && autozaak > 0) {
          autozaak_m <- autozaak / 12
          yr_data$autozaak_mean <- round(autozaak_m)
          yr_data$autozaak_sd   <- round(autozaak_m * 2.0)
        }

        # Basisuren (weekly excl. overwerk → monthly: * 52/12)
        wkuren <- as.numeric(row$PerBaanPerWeekExclusiefOverwerk_11)
        if (!is.na(wkuren) && wkuren > 0) {
          basisuren_m <- wkuren * 52 / 12
          yr_data$basisuren_mean <- round(basisuren_m, 1)
          yr_data$basisuren_sd   <- round(basisuren_m * 0.3, 1)
        }

        # Reguliere uren (annual → monthly: / 12)
        jaaruren <- as.numeric(row$PerBaanPerJaar_12)
        if (!is.na(jaaruren) && jaaruren > 0) {
          reguren_m <- jaaruren / 12
          yr_data$reguliereuren_mean <- round(reguren_m, 1)
          yr_data$reguliereuren_sd   <- round(reguren_m * 0.3, 1)
        }

        # Loon incl. bijzondere beloning (annual → monthly)
        jaarloon_incl <- as.numeric(row$JaarloonInclusiefBijzondereBeloning_6)
        if (!is.na(jaarloon_incl) && jaarloon_incl > 0) {
          lnlbph_m <- jaarloon_incl / 12
          yr_data$lnlbph_mean <- round(lnlbph_m)
          yr_data$lnlbph_sd   <- round(lnlbph_m * 0.55)
        }

        # SV-loon (jaarloon excl. bijzondere beloning → monthly)
        jaarloon_excl <- as.numeric(row$JaarloonExclusiefBijzondereBeloning_7)
        if (!is.na(jaarloon_excl) && jaarloon_excl > 0) {
          lnsv_m <- jaarloon_excl / 12
          yr_data$lnsv_mean <- round(lnsv_m)
          yr_data$lnsv_sd   <- round(lnsv_m * 0.55)
        }
      }

      # Sector breakdown from non-total SBI rows (Totaal kenmerken only)
      tot_kenmerk <- t431[trimws(t431$KenmerkenBaanWerknemerBedrijf) == "T001098", ]
      sect_rows <- tot_kenmerk[!grepl("^T", trimws(tot_kenmerk$BedrijfstakkenBranchesSBI2008)), ]
      if (nrow(sect_rows) > 0L) {
        sect_n <- as.numeric(sect_rows$Banen_1)
        sect_n[is.na(sect_n)] <- 0
        sect_total <- sum(sect_n)
        if (sect_total > 0) {
          sect_p <- round(sect_n / sect_total, 4)
          sect_labels <- trimws(sect_rows$BedrijfstakkenBranchesSBI2008)
          # Keep top sectors only for compact YAML
          keep <- sect_p >= 0.02
          if (sum(keep) > 0) {
            yr_data$sbi_p <- as.list(stats::setNames(sect_p[keep], sect_labels[keep]))
          }
        }
      }

      # Weekly working hours class distribution (from KenmerkenBaanWerknemerBedrijf)
      arbduur_codes <- c("2021210", "2021220", "B000075", "B000076", "B000077", "2021234")
      arbduur_labels <- as.character(1:6)
      arbduur_sbi_tot <- t431[trimws(t431$BedrijfstakkenBranchesSBI2008) == "T001081", ]
      arbduur_n <- vapply(arbduur_codes, function(code) {
        r <- arbduur_sbi_tot[trimws(arbduur_sbi_tot$KenmerkenBaanWerknemerBedrijf) == code, ]
        if (nrow(r) > 0L) as.numeric(r$Banen_1[1L]) else 0
      }, numeric(1L))
      arbduur_n[is.na(arbduur_n)] <- 0
      if (sum(arbduur_n) > 0) {
        arbduur_p <- round(arbduur_n / sum(arbduur_n), 4)
        yr_data$wekarbduur_p <- as.list(stats::setNames(unname(arbduur_p), arbduur_labels))
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
