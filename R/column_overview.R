# Column overview ----

#' Column overview with calibration levels
#'
#' Scans all column YAML specs across registered datasets and returns a
#' `data.table` describing each column's calibration level and data source.
#'
#' @return A `data.table` with columns:
#'   \describe{
#'     \item{dataset}{Dataset identifier (e.g. `"woonbase"`, `"rdw"`)}
#'     \item{file}{File type key (e.g. `"kenmerken_pers"`, `"kentekens"`)}
#'     \item{column}{Column name (suffixed columns are expanded, e.g. `"AGHT1Jan, AGHT31Dec"`)}
#'     \item{level}{Calibration level: `"statline-calibrated"`, `"spine-derived"`,
#'       `"codelist-hardcoded"`, `"random-normal"`, `"random-uniform"`,
#'       `"constant"`, `"random-id"`, `"computed"`}
#'     \item{source}{Human-readable source description, e.g.
#'       `"params: loon_mean (81431NED)"` or `"spine.pers.RINPERSOON"`}
#'     \item{codelist}{Codelist name if applicable, `NA` otherwise}
#'     \item{spatial}{Spatial calibration level: `"gemeente"`, `"NL"`, or `NA`}
#'   }
#' @export
sim_column_overview <- function() {

  # StatLine table mapping: dataset -> table IDs used for calibration
  statline_tables <- list(
    woonbase        = "37230ned",
    rdw             = "85237NED, 85236NED, 85404NED",
    spolis          = "81431NED",
    vehtab          = "83834NED",
    energieverbruik = "Kerncijfers wijken en buurten",
    gba             = NA_character_

  )

  datasets <- c("woonbase", "rdw", "spolis", "vehtab", "energieverbruik", "gba")
  base <- .dataset_base_dir()

  rows <- list()
  for (ds in datasets) {
    col_dir <- file.path(base, ds, "columns")
    if (!dir.exists(col_dir)) next
    sl_table <- statline_tables[[ds]] %||% NA_character_

    for (f in list.files(col_dir, "\\.yaml$", full.names = TRUE)) {
      spec <- yaml::read_yaml(f)
      fkey <- tools::file_path_sans_ext(basename(f))

      for (col in spec$columns) {
        info <- .classify_column(col, sl_table, ds)
        # Expand {sfx} templates into concrete column names
        col_name <- col$name
        sfxs <- unlist(col[["suffixes"]])
        if (length(sfxs) > 0L && grepl("\\{sfx\\}", col_name)) {
          col_name <- paste(vapply(sfxs, function(s) sub("\\{sfx\\}", s, col_name),
                                   character(1L)), collapse = ", ")
        }
        rows[[length(rows) + 1L]] <- data.table::data.table(
          dataset  = ds,
          file     = fkey,
          column   = col_name,
          level    = info$level,
          source   = info$source,
          codelist = col$codelist %||% NA_character_,
          spatial  = info$spatial
        )
      }
    }
  }
  data.table::rbindlist(rows)
}


# Classify a single column spec into level + source + spatial description
.classify_column <- function(col, sl_table, dataset) {

  # Spine fields that are calibrated at gemeente level
  # (population weights, WOZ means, vehicle weights are per-gemeente)
  gem_spine_fields <- c(
    "GemeenteCodeJJJJ", "WijkCodeJJJJ", "BuurtCodeJJJJ",
    "WOZWaardeObjectBAG", "WOZWaardeObjectBAGKlasse",
    "RINOBJECTNUMMER", "SOORTOBJECTNUMMER"
  )

  # Spine-derived
  if (!is.null(col$source) && grepl("^spine\\.", col$source)) {
    field <- sub("^spine\\.[a-z]+\\.", "", col$source)
    # Strip suffixes like _Ref, 1Jan, 31Dec, {sfx} for matching
    field_base <- sub("(_Ref|1Jan|31Dec|\\{sfx\\})$", "", field)
    sp <- if (field_base %in% gem_spine_fields) "gemeente" else "NL"
    return(list(level = "spine-derived", source = col$source, spatial = sp))
  }

  # Constant / template
  if (!is.null(col$value)) {
    return(list(level = "constant", source = paste0("value: ", col$value),
                spatial = NA_character_))
  }
  if (!is.null(col$template)) {
    return(list(level = "constant", source = paste0("template: ", col$template),
                spatial = NA_character_))
  }

  # Random categorical
  if (!is.null(col$random_categorical)) {
    rc <- col$random_categorical
    if (!is.null(rc$from_params)) {
      src <- paste0("params: ", rc$from_params)
      if (!is.na(sl_table)) src <- paste0(src, " (", sl_table, ")")
      return(list(level = "statline-calibrated", source = src, spatial = "NL"))
    }
    cl <- col$codelist %||% ""
    src <- if (nzchar(cl)) paste0("codelist: ", cl) else "hardcoded probs"
    return(list(level = "codelist-hardcoded", source = src, spatial = NA_character_))
  }

  # Random numeric
  if (!is.null(col$random_numeric)) {
    rn <- col$random_numeric
    if (!is.null(rn$mean_from_params) || !is.null(rn$sd_from_params)) {
      param_key <- rn$mean_from_params %||% rn$sd_from_params
      src <- paste0("params: ", param_key)
      if (!is.na(sl_table)) src <- paste0(src, " (", sl_table, ")")
      return(list(level = "statline-calibrated", source = src, spatial = "NL"))
    }
    dist <- rn$distribution %||% "normal"
    if (identical(dist, "uniform")) {
      src <- sprintf("uniform [%s, %s]", rn$min, rn$max)
      return(list(level = "random-uniform", source = src, spatial = NA_character_))
    }
    src <- sprintf("normal (mean=%s, sd=%s)", rn$mean, rn$sd)
    return(list(level = "random-normal", source = src, spatial = NA_character_))
  }

  # Random ID
  if (!is.null(col$random_id)) {
    return(list(level = "random-id",
                source = paste0("random hex, width=", col$random_id$width),
                spatial = NA_character_))
  }

  # Computed
  if (!is.null(col$source) && grepl("^computed\\.", col$source)) {
    # GemeenteCode computed fields are gemeente-level
    sp <- if (grepl("Gemeente", col$source)) "gemeente" else NA_character_
    return(list(level = "computed", source = col$source, spatial = sp))
  }

  list(level = "other", source = "", spatial = NA_character_)
}


# Base directory for all dataset configs
.dataset_base_dir <- function() {
  # When installed as a package
  pkg <- system.file("config/datasets", package = "simcbsradata")
  if (nzchar(pkg)) return(pkg)
  # When running from source (devtools::load_all)
  if (dir.exists("inst/config/datasets")) return("inst/config/datasets")
  stop("Cannot find dataset config directory")
}
