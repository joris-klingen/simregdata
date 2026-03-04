# RDW parameter loading and StatLine calibration ----

# Path to RDW params YAML
.rdw_params_yaml <- function() {
  file.path(.dataset_dir("rdw"), "params.yaml")
}

# Path to RDW gemeente vehicle weights CSV
.rdw_gem_vehicle_weights_csv <- function() {
  file.path(.dataset_dir("rdw"), "gem_vehicle_weights.csv")
}

# Load gemeente vehicle weights from CSV (internal helper)
# Returns a data.table with gem_code, year, veh_weight or NULL
.load_gem_vehicle_weights <- function(dataset_id, year) {
  csv_path <- .rdw_gem_vehicle_weights_csv()
  if (!nzchar(csv_path) || !file.exists(csv_path)) return(NULL)

  gw_all <- data.table::fread(csv_path,
    colClasses = c("character", "integer", "numeric"))
  yr_filter <- as.integer(year)
  gw <- gw_all[year == yr_filter]
  if (nrow(gw) == 0L) {
    avail_csv <- sort(unique(gw_all$year))
    nearest_csv <- avail_csv[which.min(abs(avail_csv - yr_filter))]
    warning(sprintf("Year %d not in gem_vehicle_weights.csv; using nearest year %d.",
                    yr_filter, nearest_csv))
    gw <- gw_all[year == nearest_csv]
  }
  gw
}


#' Load cached RDW parameters for a given year
#'
#' Reads year-specific vehicle parameters from
#' `inst/config/datasets/rdw/params.yaml`.
#'
#' @param year Integer year (default 2023).
#' @return A named list of vehicle parameters.
#' @export
rdw_cbs_params <- function(year = 2023L) {

  yaml_path <- .rdw_params_yaml()
  if (!nzchar(yaml_path) || !file.exists(yaml_path))
    stop("RDW parameter file not found. Run rdw_update_params() first, or ",
         "ensure simcbsradata is properly installed.",
         "\nExpected: inst/config/datasets/rdw/params.yaml")

  all_params <- yaml::read_yaml(yaml_path)
  yr_key <- as.character(year)

  if (yr_key %in% names(all_params)) {
    yr_data <- all_params[[yr_key]]
  } else {
    avail <- sort(as.integer(names(all_params)))
    nearest <- avail[which.min(abs(avail - year))]
    warning(sprintf("Year %d not in rdw params.yaml; using nearest year %d.", year, nearest))
    yr_data <- all_params[[as.character(nearest)]]
  }

  p <- list(year = as.integer(year))
  p$n_vehicles     <- as.integer(yr_data$n_vehicles)
  p$brandstof_p    <- unlist(yr_data$brandstof_p)
  p$kleur_p        <- unlist(yr_data$kleur_p)
  p$bouwjaar_p     <- unlist(yr_data$bouwjaar_p)
  p$vrtgsoort_p    <- unlist(yr_data$vrtgsoort_p)
  p$gewicht_mean   <- as.numeric(yr_data$gewicht_mean)
  p$gewicht_sd     <- as.numeric(yr_data$gewicht_sd)
  p$jaarkm_mean    <- as.numeric(yr_data$jaarkm_mean)
  p$jaarkm_sd      <- as.numeric(yr_data$jaarkm_sd)

  message(sprintf("RDW params %d: %s vehicles, jaarkm_mean=%.0f",
                  year, format(p$n_vehicles, big.mark = ","), p$jaarkm_mean))
  p
}


#' Fetch CBS StatLine data and write RDW params.yaml
#'
#' Queries CBS StatLine for vehicle stock and traffic performance data:
#' \itemize{
#'   \item `85237NED` — Personenauto's actief; voertuigkenmerken
#'         (fuel, color, weight, construction year)
#'   \item `85236NED` — Motorvoertuigen actief; voertuigtype, regio
#'         (vehicle type breakdown, total vehicle count)
#'   \item `85404NED` — Verkeersprestaties personenauto's; km, brandstof
#'         (average annual mileage)
#' }
#'
#' @param years Integer vector of years to fetch (default `2019:2024`).
#' @param config_dir Directory to write params.yaml into.
#' @return Invisibly, the full parameter list.
#' @export
rdw_update_params <- function(years = 2019:2025,
                               config_dir = .dataset_dir("rdw")) {
  if (!requireNamespace("cbsodataR", quietly = TRUE))
    stop("Package 'cbsodataR' is required. Install with install.packages('cbsodataR').")

  yaml_path <- file.path(config_dir, "params.yaml")

  # Load existing YAML if present
  if (file.exists(yaml_path)) {
    all_params <- yaml::read_yaml(yaml_path)
  } else {
    all_params <- list()
  }

  cat("Fetching CBS StatLine RDW parameters:\n")

  for (yr in years) {
    yr_code <- paste0(yr, "JJ00")
    cat(sprintf("  %d: ", yr))

    tryCatch({
      yr_data <- list()

      # --- 85237NED: Personenauto's actief, voertuigkenmerken ---
      # Structure: rows = Bouwjaar x Perioden; measures = fuel, color, weight
      # Use Bouwjaar = T001378 (Totaal alle bouwjaren) for marginals
      t237 <- cbsodataR::cbs_get_data("85237NED", Perioden = yr_code)
      tot <- t237[trimws(t237$Bouwjaar) == "T001378", ]

      if (nrow(tot) > 0L) {
        row <- tot[1L, ]

        # Fuel type → mapped to our BRANDSTOF codelist codes
        # CBS 85237NED classifies hybrids under primary fuel (Benzine).
        # We split PHEV (A) and HEV (B) from Benzine using fleet estimates.
        fuel_raw <- c(
          Benzine_15 = as.numeric(row$Benzine_15),
          Diesel_16  = as.numeric(row$Diesel_16),
          LPG_17     = as.numeric(row$LPG_17),
          Elek_18    = as.numeric(row$Elektriciteit_18),
          CNG_19     = as.numeric(row$CNG_19),
          Overig_20  = as.numeric(row$OverigOnbekend_20))
        fuel_raw <- fuel_raw[!is.na(fuel_raw) & fuel_raw > 0]
        fuel_total <- sum(fuel_raw)
        fuel_p <- round(fuel_raw / fuel_total, 4)

        # PHEV and HEV fleet shares by year (split from CBS Benzine total)
        # PHEV: CBS "Meer dan 1 miljoen stekkerauto's" (2025) + "Wie rijdt
        #   er elektrisch?" (2023) — exact BEV/PHEV counts per 1 Jan
        # HEV: CBS reports ~700k in 2023, +24%/yr growth; earlier years
        #   estimated from RAI Kerncijfers / fleet composition reports
        phev_hev <- list(
          "2018" = c(A = 0.0090, B = 0.0120),
          "2019" = c(A = 0.0111, B = 0.0200),
          "2020" = c(A = 0.0105, B = 0.0280),
          "2021" = c(A = 0.0113, B = 0.0380),
          "2022" = c(A = 0.0160, B = 0.0500),
          "2023" = c(A = 0.0205, B = 0.0600),
          "2024" = c(A = 0.0292, B = 0.0750),
          "2025" = c(A = 0.0403, B = 0.0900),
          "2026" = c(A = 0.0500, B = 0.1050))
        yr_str <- as.character(yr)
        if (yr_str %in% names(phev_hev)) {
          ab <- phev_hev[[yr_str]]
        } else {
          # Extrapolate from nearest available year
          avail_ab <- sort(as.integer(names(phev_hev)))
          nearest_ab <- avail_ab[which.min(abs(avail_ab - yr))]
          ab <- phev_hev[[as.character(nearest_ab)]]
        }
        benz_pure <- max(unname(fuel_p["Benzine_15"]) - ab["A"] - ab["B"], 0)

        yr_data$brandstof_p <- list(
          "1" = round(benz_pure, 4),
          "2" = unname(fuel_p["Diesel_16"]),
          "3" = unname(fuel_p["LPG_17"]),
          "4" = unname(fuel_p["Elek_18"]),
          "5" = unname(fuel_p["CNG_19"]),
          "A" = unname(ab["A"]),
          "B" = unname(ab["B"]))

        # Color → mapped to KLEURCODE codelist codes
        color_raw <- c(
          Oranje  = as.numeric(row$Oranje_63),
          Roze    = as.numeric(row$Roze_66),
          Rood    = as.numeric(row$Rood_65),
          Wit     = as.numeric(row$Wit_67),
          Blauw   = as.numeric(row$Blauw_57),
          Groen   = as.numeric(row$Groen_62),
          Geel    = as.numeric(row$Geel_60),
          Grijs   = as.numeric(row$Grijs_61),
          Bruin   = as.numeric(row$Bruin_58),
          Beige   = as.numeric(row$Beige_56),
          Creme   = as.numeric(row$Creme_59),
          Paars   = as.numeric(row$Paars_64),
          Zwart   = as.numeric(row$Zwart_68),
          Overig  = as.numeric(row$OverigeKleuren_69))
        color_raw[is.na(color_raw)] <- 0
        # Map CBS color names → codelist codes
        color_codes <- c("00","01","02","03","04","05","06","07","08","09","10","11","12","13")
        color_p <- round(color_raw / sum(color_raw), 4)
        yr_data$kleur_p <- as.list(stats::setNames(unname(color_p), color_codes))

        # Weight class distribution → compute mean/sd
        wt_cols <- c("k_0450Kg_33","k_451550Kg_34","k_551650Kg_35",
                     "k_651750Kg_36","k_751850Kg_37","k_851950Kg_38",
                     "k_9511050Kg_39","k_10511150Kg_40","k_11511250Kg_41",
                     "k_12511350Kg_42","k_13511450Kg_43","k_14511550Kg_44",
                     "k_15511650Kg_45","k_16511750Kg_46","k_17511850Kg_47",
                     "k_18511950Kg_48","k_19512050Kg_49","k_20512150Kg_50",
                     "k_21512250Kg_51","k_22512350Kg_52","k_23512450Kg_53",
                     "k_2451KgEnMeer_54")
        wt_midpoints <- c(225, 500, 600, 700, 800, 900, 1000, 1100, 1200,
                          1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000,
                          2100, 2200, 2300, 2400, 2600)
        wt_counts <- vapply(wt_cols, function(c) {
          v <- as.numeric(row[[c]]); if (is.na(v)) 0 else v
        }, numeric(1L))
        wt_props <- wt_counts / sum(wt_counts)
        yr_data$gewicht_mean <- round(sum(wt_midpoints * wt_props))
        yr_data$gewicht_sd <- round(sqrt(sum(wt_props * (wt_midpoints -
                                    yr_data$gewicht_mean)^2)))

        # Construction year distribution from per-Bouwjaar rows
        bj_rows <- t237[!grepl("^T|^A044145", trimws(t237$Bouwjaar)), ]
        if (nrow(bj_rows) > 0L) {
          bj_n <- as.numeric(bj_rows$TotaalNederland_1)
          bj_n[is.na(bj_n)] <- 0
          # Get bouwjaar labels from CBS metadata
          bj_labels <- tryCatch({
            meta <- cbsodataR::cbs_get_meta("85237NED")
            bj_dim <- meta$Bouwjaar
            codes <- trimws(bj_rows$Bouwjaar)
            matched <- bj_dim$Title[match(codes, trimws(bj_dim$Key))]
            # Extract 4-digit year from title like "Bouwjaar 2015"
            yrs <- as.integer(gsub(".*?(\\d{4}).*", "\\1", matched))
            yrs
          }, error = function(e) NULL)

          if (!is.null(bj_labels) && !all(is.na(bj_labels))) {
            keep <- !is.na(bj_labels) & bj_n > 0
            bj_n <- bj_n[keep]
            bj_labels <- bj_labels[keep]
            # Aggregate into 5-year bins for compact YAML
            bins <- as.character(bj_labels - (bj_labels %% 5L))
            agg <- tapply(bj_n, bins, sum)
            agg_p <- round(agg / sum(agg), 4)
            yr_data$bouwjaar_p <- as.list(agg_p)
          }
        }

        n_pers_auto <- as.integer(row$TotaalNederland_1)
      }

      # --- 85236NED: vehicle types + total count (national) ---
      t236 <- cbsodataR::cbs_get_data("85236NED", Perioden = yr_code)
      nl_row <- t236[trimws(t236$RegioS) == "NL01", ]
      if (nrow(nl_row) > 0L) {
        r <- nl_row[1L, ]
        vtype_raw <- c(
          "0" = as.numeric(r$AlleVoertuigenMetBromfietskenteken_14),
          "1" = as.numeric(r$Bestelauto_5),
          "2" = as.numeric(r$VrachtautoExclTrekkerVoorOplegger_6),
          "3" = as.numeric(r$TrekkerVoorOplegger_7),
          "4" = as.numeric(r$SpeciaalVoertuig_8),
          "5" = as.numeric(r$Bus_9),
          "6" = as.numeric(r$Personenauto_2),
          "7" = as.numeric(r$Motorfiets_13),
          "8" = as.numeric(r$Aanhangwagen_11),
          "9" = as.numeric(r$Oplegger_12))
        vtype_raw[is.na(vtype_raw)] <- 0
        vtype_p <- round(vtype_raw / sum(vtype_raw), 4)
        yr_data$vrtgsoort_p <- as.list(vtype_p)

        yr_data$n_vehicles <- as.integer(r$TotaalWegvoertuigen_1)
      }

      # --- 85404NED: traffic performance ---
      t404 <- cbsodataR::cbs_get_data("85404NED", Perioden = yr_code)
      # Total row: all fuel types, all ages, all ownership
      tot_row <- t404[trimws(t404$Brandstofsoort) == "T001051" &
                      trimws(t404$LeeftijdVoertuig) == "10000" &
                      trimws(t404$Eigendomssituatie) == "T001191", ]
      if (nrow(tot_row) > 0L) {
        km_mean <- as.numeric(tot_row$TotaalGemiddeldJaarkilometrage_7[1L])
        if (!is.na(km_mean) && km_mean > 0) {
          yr_data$jaarkm_mean <- round(km_mean)
          # Estimate sd from fuel-type variation
          fuel_rows <- t404[trimws(t404$LeeftijdVoertuig) == "10000" &
                            trimws(t404$Eigendomssituatie) == "T001191" &
                            !grepl("^T", trimws(t404$Brandstofsoort)), ]
          if (nrow(fuel_rows) > 1L) {
            km_vals <- as.numeric(fuel_rows$TotaalGemiddeldJaarkilometrage_7)
            n_vals  <- as.numeric(fuel_rows$NederlandsePersonenautoSInGebruik_10)
            km_vals <- km_vals[!is.na(km_vals)]
            n_vals  <- n_vals[!is.na(n_vals)]
            if (length(km_vals) > 1L && length(n_vals) == length(km_vals)) {
              # Weighted sd across fuel types
              wm <- sum(km_vals * n_vals) / sum(n_vals)
              yr_data$jaarkm_sd <- round(sqrt(sum(n_vals * (km_vals - wm)^2) /
                                              sum(n_vals)))
            } else {
              yr_data$jaarkm_sd <- round(km_mean * 0.45)
            }
          } else {
            yr_data$jaarkm_sd <- round(km_mean * 0.45)
          }
        }
      }

      all_params[[as.character(yr)]] <- yr_data

      cat(sprintf("%s vehicles, benz=%.1f%% elek=%.1f%% PHEV=%.1f%% HEV=%.1f%%, jaarkm=%d\n",
                  format(yr_data$n_vehicles, big.mark = ","),
                  (yr_data$brandstof_p[["1"]] %||% 0) * 100,
                  (yr_data$brandstof_p[["4"]] %||% 0) * 100,
                  (yr_data$brandstof_p[["A"]] %||% 0) * 100,
                  (yr_data$brandstof_p[["B"]] %||% 0) * 100,
                  yr_data$jaarkm_mean %||% 0L))

    }, error = function(e) {
      cat(sprintf("FAILED (%s)\n", conditionMessage(e)))
    })
  }

  # Sort and write YAML
  all_params <- all_params[order(as.integer(names(all_params)))]
  dir.create(config_dir, recursive = TRUE, showWarnings = FALSE)
  yaml::write_yaml(all_params, yaml_path)
  cat(sprintf("Written rdw params.yaml (%d years)\n", length(all_params)))

  # --- Gemeente vehicle ownership weights ---
  csv_path <- file.path(config_dir, "gem_vehicle_weights.csv")
  if (file.exists(csv_path)) {
    gw_all <- data.table::fread(csv_path,
      colClasses = c("character", "integer", "numeric"))
  } else {
    gw_all <- data.table::data.table(
      gem_code = character(), year = integer(), veh_weight = numeric())
  }

  cat("Fetching gemeente vehicle ownership weights:\n")

  for (yr in years) {
    yr_code <- paste0(yr, "JJ00")
    cat(sprintf("  %d: ", yr))

    tryCatch({
      # Vehicles per gemeente (85236NED: Personenauto_2 by GM####)
      t236 <- cbsodataR::cbs_get_data("85236NED", Perioden = yr_code)
      gem_veh <- t236[grepl("^GM", trimws(t236$RegioS)), ]
      gem_veh$code <- sub("^GM", "", trimws(gem_veh$RegioS))
      gem_veh$vehicles <- as.numeric(gem_veh$Personenauto_2)
      gem_veh <- gem_veh[!is.na(gem_veh$vehicles) & gem_veh$vehicles > 0,
                         c("code", "vehicles")]

      # Population per gemeente (37230ned)
      pop_all <- cbsodataR::cbs_get_data("37230ned", Perioden = yr_code)
      gem_pop <- pop_all[grepl("^GM", trimws(pop_all$RegioS)), ]
      gem_pop$code <- sub("^GM", "", trimws(gem_pop$RegioS))
      gem_pop$pop <- as.numeric(gem_pop$BevolkingAanHetBeginVanDePeriode_1)
      gem_pop <- gem_pop[!is.na(gem_pop$pop) & gem_pop$pop > 0,
                         c("code", "pop")]

      # Merge and compute weights
      merged <- merge(
        data.table::as.data.table(gem_veh),
        data.table::as.data.table(gem_pop),
        by = "code")
      total_veh <- sum(merged$vehicles)
      total_pop <- sum(merged$pop)
      merged[, veh_weight := round(
        (vehicles / total_veh) / (pop / total_pop), 4)]

      # Replace this year's rows
      gw_all <- gw_all[year != yr]
      gw_new <- data.table::data.table(
        gem_code = merged$code, year = yr, veh_weight = merged$veh_weight)
      gw_all <- data.table::rbindlist(list(gw_all, gw_new))

      cat(sprintf("%d gemeenten, weight range %.2f-%.2f\n",
                  nrow(merged),
                  min(merged$veh_weight), max(merged$veh_weight)))
    }, error = function(e) {
      cat(sprintf("FAILED (%s)\n", conditionMessage(e)))
    })
  }

  data.table::setorder(gw_all, year, gem_code)
  data.table::fwrite(gw_all, csv_path)
  cat(sprintf("Written gem_vehicle_weights.csv (%d rows)\n", nrow(gw_all)))

  invisible(all_params)
}
