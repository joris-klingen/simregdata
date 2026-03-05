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
#'     \item{column}{Column name pattern (may include `{sfx}` for suffixed columns)}
#'     \item{level}{Calibration level: `"statline-calibrated"`, `"spine-derived"`,
#'       `"codelist-hardcoded"`, `"random-normal"`, `"random-uniform"`,
#'       `"constant"`, `"random-id"`, `"computed"`}
#'     \item{source}{Human-readable source description, e.g.
#'       `"params: loon_mean (81431NED)"` or `"spine.pers.RINPERSOON"`}
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
        info <- .classify_column(col, sl_table)
        rows[[length(rows) + 1L]] <- data.table::data.table(
          dataset = ds,
          file    = fkey,
          column  = col$name,
          level   = info$level,
          source  = info$source
        )
      }
    }
  }
  data.table::rbindlist(rows)
}


# Classify a single column spec into level + source description
.classify_column <- function(col, sl_table) {

  # Spine-derived
  if (!is.null(col$source) && grepl("^spine\\.", col$source)) {
    return(list(level = "spine-derived", source = col$source))
  }

  # Constant / template
  if (!is.null(col$value)) {
    return(list(level = "constant", source = paste0("value: ", col$value)))
  }
  if (!is.null(col$template)) {
    return(list(level = "constant", source = paste0("template: ", col$template)))
  }

  # Random categorical
  if (!is.null(col$random_categorical)) {
    rc <- col$random_categorical
    if (!is.null(rc$from_params)) {
      src <- paste0("params: ", rc$from_params)
      if (!is.na(sl_table)) src <- paste0(src, " (", sl_table, ")")
      return(list(level = "statline-calibrated", source = src))
    }
    cl <- col$codelist %||% ""
    src <- if (nzchar(cl)) paste0("codelist: ", cl) else "hardcoded probs"
    return(list(level = "codelist-hardcoded", source = src))
  }

  # Random numeric
  if (!is.null(col$random_numeric)) {
    rn <- col$random_numeric
    if (!is.null(rn$mean_from_params) || !is.null(rn$sd_from_params)) {
      param_key <- rn$mean_from_params %||% rn$sd_from_params
      src <- paste0("params: ", param_key)
      if (!is.na(sl_table)) src <- paste0(src, " (", sl_table, ")")
      return(list(level = "statline-calibrated", source = src))
    }
    dist <- rn$distribution %||% "normal"
    if (identical(dist, "uniform")) {
      src <- sprintf("uniform [%s, %s]", rn$min, rn$max)
      return(list(level = "random-uniform", source = src))
    }
    src <- sprintf("normal (mean=%s, sd=%s)", rn$mean, rn$sd)
    return(list(level = "random-normal", source = src))
  }

  # Random ID
  if (!is.null(col$random_id)) {
    return(list(level = "random-id",
                source = paste0("random hex, width=", col$random_id$width)))
  }

  # Computed
  if (!is.null(col$source) && grepl("^computed\\.", col$source)) {
    return(list(level = "computed", source = col$source))
  }

  list(level = "other", source = "")
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
