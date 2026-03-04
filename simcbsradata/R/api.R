#' Initialize a dataset spine and cache it for the session
#'
#' Builds the shared person/household/object spine for a dataset and caches
#' it so that subsequent [read_sav()] calls can assemble files without
#' rebuilding.
#'
#' @param dataset  Dataset identifier (default `"woonbase"`).
#' @param year  Simulation year (default 2023).
#' @param n     Number of persons to generate.
#'   `NULL` (the default) fetches the actual population count from bundled
#'   parameters for `year`.
#' @param seed  RNG seed for reproducibility (default 42).
#' @return Invisibly `NULL`.
#' @export
sim_init <- function(dataset = "woonbase", year = 2023L, n = NULL, seed = 42L) {
  .load_dataset_registry()
  ds <- .sim_cache$datasets[[dataset]]
  if (is.null(ds)) stop("Unknown dataset: ", dataset)

  # Dispatch to the appropriate spine builder
  builder <- ds$spine_builder
  if (identical(builder, "woonbase")) {
    params <- woonbase_cbs_params(year)
    n_pers <- if (is.null(n)) params$n_persons else as.integer(n)
    spine  <- .wb_build_spine(n_pers, params, seed, year)
    # Cache under the dataset id
    .sim_cache[[paste0("spine_", dataset)]] <- spine
    .sim_cache[[paste0("params_", dataset)]] <- params
    .sim_cache[[paste0("year_", dataset)]] <- year
    .sim_cache[[paste0("seed_", dataset)]] <- seed
    # Keep .wb in sync for backward compat
    .wb$spine  <- spine
    .wb$params <- params
    .wb$year   <- year
    .wb$seed   <- seed
  } else if (identical(builder, "generic")) {
    # Generic spine: just sample RINPERSOON from the woonbase person spine
    wb_spine <- .sim_cache$spine_woonbase
    if (is.null(wb_spine))
      stop("Woonbase spine must be initialized first for linked datasets. ",
           "Call sim_init('woonbase', ...) first.")
    n_records <- if (is.null(n)) nrow(wb_spine$pers) else as.integer(n)
    set.seed(seed)
    idx <- sample.int(nrow(wb_spine$pers), n_records, replace = n_records > nrow(wb_spine$pers))
    spine <- list(
      pers = wb_spine$pers[idx],
      year = as.integer(year),
      jan1 = as.Date(paste0(year, "-01-01")),
      dec31 = as.Date(paste0(year, "-12-31"))
    )
    .sim_cache[[paste0("spine_", dataset)]] <- spine
    .sim_cache[[paste0("year_", dataset)]] <- year
    .sim_cache[[paste0("seed_", dataset)]] <- seed
  } else {
    stop("Unknown spine builder: ", builder)
  }

  invisible(NULL)
}

#' Pre-build the Woonbase spine and cache it for the session
#'
#' Call this once before using [read_sav()] on Woonbase files.  The spine
#' (shared person / household / object identifiers) is cached so that
#' cross-file joins always succeed.
#'
#' @param year  Simulation year (default 2023).
#' @param n     Number of persons to generate.
#'   `NULL` (the default) fetches the actual Dutch population count from
#'   the bundled YAML for `year`.
#' @param seed  RNG seed for reproducibility (default 42).
#' @return Invisibly `NULL`.
#' @export
woonbase_init <- function(year = 2023L, n = NULL, seed = 42L) {
  sim_init(dataset = "woonbase", year = year, n = n, seed = seed)
}

#' Clear the cached spine
#'
#' Forces a rebuild on the next [read_sav()] call.
#'
#' @param dataset Dataset to reset (default `NULL` resets all).
#' @return Invisibly `NULL`.
#' @export
sim_reset <- function(dataset = NULL) {
  if (is.null(dataset)) {
    # Reset everything
    rm(list = ls(.sim_cache), envir = .sim_cache)
    .wb$spine <- NULL
    .wb$params <- NULL
    .wb$year <- NULL
    .wb$seed <- NULL
  } else {
    for (prefix in c("spine_", "params_", "year_", "seed_")) {
      key <- paste0(prefix, dataset)
      if (exists(key, envir = .sim_cache)) rm(list = key, envir = .sim_cache)
    }
    if (dataset == "woonbase") {
      .wb$spine <- NULL
      .wb$params <- NULL
      .wb$year <- NULL
      .wb$seed <- NULL
    }
  }
  invisible(NULL)
}

#' @rdname sim_reset
#' @export
woonbase_reset <- function() sim_reset("woonbase")


#' Print a catalog of available synthetic datasets and files
#'
#' @param dataset Dataset identifier, or `NULL` for all datasets.
#' @param year  Year to display in example file names (default 2023).
#' @return Invisibly `NULL`.
#' @export
sim_catalog <- function(dataset = NULL, year = 2023L) {
  .load_dataset_registry()
  ds_list <- .sim_cache$datasets
  if (!is.null(dataset)) {
    ds_list <- ds_list[dataset]
  }

  cat("\n")
  cat("  simcbsradata \u2014 synthetic file catalog\n")
  cat("  ======================================\n\n")

  for (ds_id in names(ds_list)) {
    ds <- ds_list[[ds_id]]
    cat(sprintf("  Dataset: %s (%s)\n", if (!is.null(ds$label)) ds$label else ds_id, ds_id))
    cat(sprintf("  %-30s  %-10s  %s\n",
                "CBS name", "Entity", "read_sav() file argument"))
    cat(sprintf("  %-30s  %-10s  %s\n",
                "------------------------------", "----------",
                "----------------------------------------"))

    for (fkey in names(ds$files)) {
      fi <- ds$files[[fkey]]
      filename <- sprintf("%s%dV1", fi$cbs_name, year)
      cat(sprintf("  %-30s  %-10s  %s\n", fi$cbs_name, fi$entity, filename))
    }
    cat("\n")
  }
  invisible(NULL)
}

#' @rdname sim_catalog
#' @param year  Year to display in example file names (default 2023).
#' @export
woonbase_catalog <- function(year = 2023L) {
  sim_catalog(dataset = "woonbase", year = year)
}


#' Read a CBS file (synthetic) or any other .sav file (via haven)
#'
#' Drop-in replacement for [haven::read_sav()] that intercepts registered CBS
#' dataset file names and returns synthetic microdata.  For all other file
#' paths, falls through to `haven::read_sav()`.
#'
#' @param file  File name or path.  For simulated files, use the exact CBS
#'   CamelCase name (e.g. `"WoonbasePopulatiePersonen2023V1"`).
#' @param encoding  Passed to `haven::read_sav()` (non-simulated files only).
#' @param user_na   Passed to `haven::read_sav()` (non-simulated files only).
#' @param col_select  Column selection (tidyselect expressions or character
#'   vector).
#' @param skip  Number of rows to skip (default 0).
#' @param n_max  Maximum number of rows to return (default `Inf`).
#' @param .name_repair  Passed to `haven::read_sav()` (non-simulated files
#'   only).
#' @param year  Simulation year used for auto-init (default 2023).
#' @param seed  RNG seed used for auto-init (default 42).
#' @param ...   Additional arguments passed to `haven::read_sav()`.
#' @return A tibble.
#' @export
read_sav <- function(file,
                     encoding     = NULL,
                     user_na      = FALSE,
                     col_select   = NULL,
                     skip         = 0L,
                     n_max        = Inf,
                     .name_repair = "unique",
                     year         = 2023L,
                     seed         = 42L,
                     ...) {

  col_q  <- rlang::enquo(col_select)
  parsed <- .parse_file_registry(file)

  # Fall through to haven for unregistered files
  if (is.null(parsed)) {
    return(haven::read_sav(file, encoding=encoding, user_na=user_na,
                           col_select=!!col_q, skip=skip, n_max=n_max,
                           .name_repair=.name_repair, ...))
  }

  dataset_id <- parsed$dataset_id
  file_key   <- parsed$file_key
  entity     <- parsed$entity
  # Year inferred from filename takes precedence
  if (!is.null(parsed$year)) year <- parsed$year

  # Auto-initialise spine if needed
  spine_key <- paste0("spine_", dataset_id)
  year_key  <- paste0("year_", dataset_id)
  cached_spine <- .sim_cache[[spine_key]]
  cached_year  <- .sim_cache[[year_key]]

  if (is.null(cached_spine) || (!is.null(cached_year) && cached_year != year)) {
    if (is.infinite(n_max)) {
      message("n_max = Inf: fetching population count for ", year, " and generating full spine.")
      sim_init(dataset = dataset_id, year = year, n = NULL, seed = seed)
    } else {
      n_pers <- switch(entity,
        person    = ceiling(n_max * 1.05),
        household = ceiling(n_max * 2.4),
        object    = ceiling(n_max * 2.4),
        ceiling(n_max * 1.05))
      message(sprintf("Auto-initialising %s spine with %s persons. Call sim_init() explicitly for reproducible cross-file joins.",
                      dataset_id, format(n_pers, big.mark=",")))
      sim_init(dataset = dataset_id, year = year, n = n_pers, seed = seed)
    }
  }

  spine <- .sim_cache[[spine_key]]

  # Assemble the requested file via generic YAML-driven engine
  dt <- .assemble_generic(dataset_id, file_key, spine, col_q = col_q)

  # Apply skip and n_max
  if (skip > 0L) {
    dt <- dt[seq_len(nrow(dt)) > min(skip, nrow(dt))]
  }
  if (!is.infinite(n_max) && n_max < nrow(dt)) {
    dt <- dt[seq_len(as.integer(n_max))]
  }

  # Return as tibble (matches haven::read_sav output class)
  tibble::as_tibble(dt)
}
