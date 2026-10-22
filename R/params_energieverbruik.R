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


# Dwelling-level energy structure (85140NED, 81528NED) ----

# 85140NED dimensions used for the dwelling-level model, with the codes of
# the simulated characteristics they map to (woonbase VBOWoningType codes,
# lower bounds of construction-year and floor-area classes, occupants)
.ENERGY_DIMS <- list(
  woningtype = c("01" = "Vrijstaande woning", "02" = "2-onder-1-kapwoning",
                 "03" = "Hoekwoning", "04" = "Tussenwoning", "05" = "Appartement"),
  bouwjaar   = c("1000" = "1000 tot 1946", "1946" = "1946 tot 1965",
                 "1965" = "1965 tot 1975", "1975" = "1975 tot 1992",
                 "1992" = "1992 tot 2006", "2006" = "2006 tot 2015",
                 "2015" = "2015 tot heden"),
  oppervlakte = c("2" = "2 tot 50", "50" = "50 tot 75", "75" = "75 tot 100",
                  "100" = "100 tot 150", "150" = "150 tot 250", "250" = "250 tot 10 000"),
  bewoners   = c("1" = "1 persoon", "2" = "2 personen", "3" = "3 personen",
                 "4" = "4 personen", "5" = "5 personen of meer")
)
.ENERGY_DIM_KEYS <- c(woningtype = "Woningtype", bouwjaar = "Bouwjaar",
                      oppervlakte = "Gebruiksoppervlakte", bewoners = "Bewonersklasse")


#' Fetch the dwelling-level energy structure from StatLine
#'
#' Adds to `inst/config/datasets/energieverbruik/params.yaml`:
#' \itemize{
#'   \item from `81528NED` (all `years`): national mean gas (`gas_mean`) and
#'         electricity delivery (`elek_mean`) per dwelling;
#'   \item from `85140NED` (2019 onwards): a `structuur` block per year with
#'         the mean temperature-corrected gas use and electricity delivery,
#'         the share with solar panels and with district heating, per dwelling
#'         type, construction-year class, floor-area class and number of
#'         occupants, the national percentiles, and electricity delivery and
#'         net delivery for dwellings with and without solar panels.
#' }
#' The simulator draws gas and electricity per dwelling from this structure
#' (see `.build_energy()`).
#'
#' @param years Integer vector of years (default `2010:2025`).
#' @param config_dir Directory holding params.yaml.
#' @return Invisibly, the full parameter list.
#' @export
energieverbruik_update_structure <- function(years = 2010:2025,
                                             config_dir = .dataset_dir("energieverbruik")) {
  if (!requireNamespace("cbsodataR", quietly = TRUE))
    stop("Package 'cbsodataR' is required. Install with install.packages('cbsodataR').")

  yaml_path <- file.path(config_dir, "params.yaml")
  all_params <- if (file.exists(yaml_path)) yaml::read_yaml(yaml_path) else list()
  lbl <- function(dt) {
    dt <- data.table::as.data.table(cbsodataR::cbs_add_label_columns(dt))
    for (j in grep("_label$", names(dt), value = TRUE)) {
      data.table::set(dt, j = j, value = trimws(as.character(dt[[j]])))
    }
    dt
  }
  num <- function(dt, pattern) as.numeric(dt[[grep(pattern, names(dt), value = TRUE)[1L]]])

  cat("Fetching national energy use per dwelling (81528NED):\n")
  nat <- lbl(cbsodataR::cbs_get_data("81528NED", RegioS = cbsodataR::has_substring("NL01")))
  nat <- nat[Woningkenmerken_label == "Totaal woningen"]
  for (yr in years) {
    row <- nat[Perioden_label == as.character(yr)]
    if (nrow(row) == 0L) next
    yk <- as.character(yr)
    if (is.null(all_params[[yk]])) all_params[[yk]] <- list()
    all_params[[yk]]$gas_mean  <- num(row, "^GemiddeldAardgasverbruik")
    all_params[[yk]]$elek_mean <- num(row, "^GemiddeldeElektriciteitslevering")
    cat(sprintf("  %d: gas %s m3, elek %s kWh\n", yr,
                all_params[[yk]]$gas_mean, all_params[[yk]]$elek_mean))
  }

  cat("Fetching dwelling-level structure (85140NED):\n")
  for (yr in intersect(years, 2019:2100)) {
    tryCatch({
      d <- lbl(cbsodataR::cbs_get_data("85140NED", Perioden = paste0(yr, "JJ00")))
      dims <- c(.ENERGY_DIM_KEYS, solar = "HoofdverwarmingEnZonnestroom")
      is_tot <- function(dim) d[[paste0(dim, "_label")]] %in% c("Totaal", "Totaal woningen")
      one_way <- function(dim) {
        keep <- rep(TRUE, nrow(d))
        for (o in setdiff(dims, dim)) keep <- keep & is_tot(o)
        d[keep]
      }
      measures <- function(rows) list(
        gas    = num(rows, "^GemiddeldeAardgasleveringTempGecorr"),
        elek   = num(rows, "^GemiddeldeElektriciteitslevering"),
        zon    = num(rows, "^AandeelWoningenZonnestroomOpAdres") / 100,
        stadsw = num(rows, "^AandeelWoningenMetStadsverwarming") / 100)

      tot <- one_way("none")
      s <- list(totaal = lapply(measures(tot), function(x) x[1L]))
      s$gas_pct <- vapply(seq(10, 90, 10), function(p)
        num(tot, paste0("^AardgasTempGecorrPercentiel", p, "_"))[1L], numeric(1L))
      s$elek_pct <- vapply(seq(10, 90, 10), function(p)
        num(tot, paste0("^ElektriciteitsleveringPercentiel", p, "_"))[1L], numeric(1L))

      for (k in names(.ENERGY_DIM_KEYS)) {
        dim <- .ENERGY_DIM_KEYS[[k]]
        ow <- one_way(dim)
        labels <- gsub("\\s*m\u00b2$|\\s*m2$", "", ow[[paste0(dim, "_label")]])
        m <- measures(ow)
        idx <- match(.ENERGY_DIMS[[k]], labels)
        if (anyNA(idx)) stop("missing categories for ", dim, ": ",
                             paste(.ENERGY_DIMS[[k]][is.na(idx)], collapse = ", "))
        s[[k]] <- lapply(m, function(x) as.list(stats::setNames(x[idx], names(.ENERGY_DIMS[[k]]))))
      }

      sol <- one_way("HoofdverwarmingEnZonnestroom")
      sl <- sol$HoofdverwarmingEnZonnestroom_label
      for (key in c("met", "zonder")) {
        r <- sol[sl == paste("Totaal", key, "zonnestroominstallatie")]
        s$zonnestroom[[key]] <- list(
          elek  = num(r, "^GemiddeldeElektriciteitslevering")[1L],
          netto = num(r, "^NettoElektriciteitsleveringGemiddelde")[1L])
      }

      yk <- as.character(yr)
      if (is.null(all_params[[yk]])) all_params[[yk]] <- list()
      all_params[[yk]]$structuur <- s
      cat(sprintf("  %d: gas %.0f m3 (corr.), elek %.0f kWh, solar %.0f%%\n", yr,
                  s$totaal$gas, s$totaal$elek, s$totaal$zon * 100))
    }, error = function(e) cat(sprintf("  %d: FAILED (%s)\n", yr, conditionMessage(e))))
  }

  all_params <- all_params[order(as.integer(names(all_params)))]
  yaml::write_yaml(all_params, yaml_path)
  cat(sprintf("Written energieverbruik params.yaml (%d years)\n", length(all_params)))
  invisible(all_params)
}
