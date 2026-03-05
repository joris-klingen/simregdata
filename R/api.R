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
    # Determine record count: scale n_vehicles to spine size
    if (is.null(n)) {
      n_national <- .load_dataset_n(dataset, year)
      if (!is.null(n_national)) {
        # Scale proportionally: n_vehicles / n_persons_national * spine_size
        wb_params <- .sim_cache$params_woonbase
        if (!is.null(wb_params) && !is.null(wb_params$n_persons)) {
          ratio <- n_national / wb_params$n_persons
          n_records <- as.integer(round(nrow(wb_spine$pers) * ratio))
        } else {
          n_records <- n_national
        }
      } else {
        n_records <- nrow(wb_spine$pers)
      }
    } else {
      n_records <- as.integer(n)
    }
    set.seed(seed)
    # Weighted sampling: use gemeente vehicle weights if available
    gem_wt <- .load_gem_vehicle_weights(dataset, year)
    gem_col <- if (!is.null(gem_wt)) {
      wb_spine$pers$GemeenteCodeJJJJ1Jan %||% wb_spine$pers_gemeente
    }
    if (!is.null(gem_col)) {
      pw <- gem_wt$veh_weight[match(gem_col, gem_wt$gem_code)]
      pw[is.na(pw)] <- 1.0
      # Always sample with replacement — synthetic data, and
      # sample.int(replace=FALSE, prob=) is O(n*k) in R
      idx <- sample.int(nrow(wb_spine$pers), n_records,
        replace = TRUE, prob = pw)
    } else {
      idx <- sample.int(nrow(wb_spine$pers), n_records,
        replace = n_records > nrow(wb_spine$pers))
    }
    # Column-pruned generic spine: only copy referenced spine columns
    needed <- .scan_spine_columns(dataset)
    pers_cols <- needed$pers
    if (length(pers_cols) == 0L) pers_cols <- "RINPERSOON"
    pers_cols <- intersect(pers_cols, names(wb_spine$pers))
    if (length(pers_cols) == 0L) pers_cols <- "RINPERSOON"
    spine <- list(
      pers = wb_spine$pers[idx, ..pers_cols],
      year = as.integer(year),
      jan1 = as.Date(paste0(year, "-01-01")),
      dec31 = as.Date(paste0(year, "-12-31"))
    )
    # Generate shared random IDs for cross-file joins (e.g. RINKENTEKEN)
    if ("RINKENTEKEN" %in% needed$pers && !("RINKENTEKEN" %in% names(spine$pers)))
      spine$pers[, RINKENTEKEN := .rand_id(nrow(spine$pers), 32L)]

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


# Parquet data root ----

#' Set or clear the parquet data root
#'
#' When a data root is set, [read_sav()] looks for pre-exported parquet files
#' before generating data on-the-fly.  Use [sim_export()] to create the
#' parquet files.
#'
#' @param path  Directory containing exported parquet files (CBS VM-style
#'   layout), or `NULL` to revert to on-the-fly generation.
#' @return Invisibly, the previous data root (or `NULL`).
#' @export
sim_set_data_root <- function(path) {
  prev <- .sim_cache$data_root
  if (!is.null(path)) {
    path <- normalizePath(path, mustWork = FALSE)
    if (!dir.exists(path)) warning("Data root does not exist yet: ", path)
  }
  .sim_cache$data_root <- path
  invisible(prev)
}

#' @rdname sim_set_data_root
#' @return The current data root path, or `NULL` if not set.
#' @export
sim_get_data_root <- function() {
  .sim_cache$data_root
}


# Parquet lookup helper ----

# Given a file argument (as passed to read_sav), try to find a matching
# parquet file under data_root.  Returns the full path or NULL.
.find_parquet <- function(file, data_root) {
  base <- tools::file_path_sans_ext(basename(file))
  # Strip .parquet too, in case user passed it
  base <- sub("\\.parquet$", "", base, ignore.case = TRUE)

  # Extract CBS name from standard or TAB pattern
  cbs_name <- NULL
  m <- regmatches(base, regexec("^(.+?)(\\d{4})V\\d+$", base))[[1L]]
  if (length(m) == 3L) {
    cbs_name <- m[2L]
  } else {
    m2 <- regmatches(base, regexec("^(.+?)(\\d{4})TABV\\d+$", base))[[1L]]
    if (length(m2) == 3L) cbs_name <- m2[2L]
  }
  if (is.null(cbs_name)) cbs_name <- base

  # CBS VM layout: UPPERCASENAME/basename.parquet
  pq_path <- file.path(data_root, toupper(cbs_name), paste0(base, ".parquet"))
  if (file.exists(pq_path)) return(pq_path)
  NULL
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

  # Parquet-first lookup: if data_root is set, try reading from disk

  data_root <- .sim_cache$data_root
  if (!is.null(data_root)) {
    pq_path <- .find_parquet(file, data_root)
    if (!is.null(pq_path)) {
      if (!requireNamespace("arrow", quietly = TRUE))
        stop("Package 'arrow' is required to read parquet files. ",
             "Install it with: install.packages('arrow')")
      # Evaluate col_select against parquet schema
      sel_cols <- NULL
      if (!rlang::quo_is_null(col_q)) {
        schema <- arrow::open_dataset(pq_path)$schema
        all_names <- schema$names
        names(all_names) <- all_names
        sel_idx <- tidyselect::eval_select(col_q, data = setNames(
          as.list(seq_along(all_names)), all_names))
        sel_cols <- names(sel_idx)
      }
      tbl <- if (is.null(sel_cols)) {
        arrow::read_parquet(pq_path)
      } else {
        arrow::read_parquet(pq_path, col_select = tidyselect::all_of(sel_cols))
      }
      # Apply skip and n_max
      if (skip > 0L) {
        tbl <- tbl[seq_len(nrow(tbl)) > min(skip, nrow(tbl)), , drop = FALSE]
      }
      if (!is.infinite(n_max) && n_max < nrow(tbl)) {
        tbl <- tbl[seq_len(as.integer(n_max)), , drop = FALSE]
      }
      return(tibble::as_tibble(tbl))
    }
  }

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


# Parquet export ----

#' Export simulated datasets to parquet files
#'
#' Generates synthetic data for one or all registered datasets and writes
#' each file as a parquet file in a CBS VM-style folder layout:
#' `output_dir/UPPERCASECBSNAME/CbsName{YYYY}V1.parquet`.
#'
#' @param output_dir  Directory to write parquet files into.
#' @param dataset  Dataset identifier, or `NULL` (default) to export all
#'   registered datasets.
#' @param year  Simulation year (default 2023).
#' @param n  Number of persons in the spine.  `NULL` (default) uses the
#'   population count from bundled parameters.
#' @param seed  RNG seed for reproducibility (default 42).
#' @return Invisibly, `output_dir`.
#' @export
sim_export <- function(output_dir, dataset = NULL, year = 2023L,
                       n = NULL, seed = 42L) {
  if (!requireNamespace("arrow", quietly = TRUE))
    stop("Package 'arrow' is required to write parquet files. ",
         "Install it with: install.packages('arrow')")

  .load_dataset_registry()
  ds_ids <- if (is.null(dataset)) names(.sim_cache$datasets) else dataset

  # Initialise woonbase first (generic datasets depend on it)
  if ("woonbase" %in% ds_ids) {
    sim_init("woonbase", year = year, n = n, seed = seed)
  } else if (any(vapply(ds_ids, function(id) {
    d <- .sim_cache$datasets[[id]]
    identical(d$spine_builder, "generic")
  }, logical(1L)))) {
    # Need woonbase spine for generic datasets
    if (is.null(.sim_cache$spine_woonbase))
      sim_init("woonbase", year = year, n = n, seed = seed)
  }

  # Initialise remaining datasets
  for (ds_id in ds_ids) {
    if (ds_id == "woonbase") next
    sim_init(ds_id, year = year, n = n, seed = seed)
  }

  output_dir <- normalizePath(output_dir, mustWork = FALSE)
  files_written <- character()

  for (ds_id in ds_ids) {
    ds <- .sim_cache$datasets[[ds_id]]
    spine <- .sim_cache[[paste0("spine_", ds_id)]]

    for (fkey in names(ds$files)) {
      fi <- ds$files[[fkey]]
      cbs_name <- fi$cbs_name

      # Build filename: TAB suffix for tab_suffix files
      tab <- isTRUE(fi$tab_suffix)
      fname <- if (tab) {
        sprintf("%s%dTABV1.parquet", cbs_name, year)
      } else {
        sprintf("%s%dV1.parquet", cbs_name, year)
      }

      # Create subdirectory
      subdir <- file.path(output_dir, toupper(cbs_name))
      dir.create(subdir, recursive = TRUE, showWarnings = FALSE)
      out_path <- file.path(subdir, fname)

      # Deterministic seed per file: base seed XOR hash of dataset+file key
      file_seed <- bitwXor(seed, sum(utf8ToInt(paste0(ds_id, "/", fkey))))
      set.seed(file_seed)

      # Assemble the full data.table
      dt <- .assemble_generic(ds_id, fkey, spine)
      tbl <- tibble::as_tibble(dt)

      # Write parquet
      arrow::write_parquet(tbl, out_path)
      files_written <- c(files_written, out_path)
      message(sprintf("  %s  (%s rows x %s cols)",
                      out_path, format(nrow(tbl), big.mark = ","),
                      ncol(tbl)))
    }
  }

  message(sprintf("\nExported %d parquet files to %s", length(files_written),
                  output_dir))
  invisible(output_dir)
}


# Try to load n_vehicles from a dataset's params.yaml
.load_dataset_n <- function(dataset_id, year) {
  params_path <- file.path(.dataset_dir(dataset_id), "params.yaml")
  if (!file.exists(params_path)) return(NULL)

  tryCatch({
    all_params <- yaml::read_yaml(params_path)
    yr_key <- as.character(year)
    yr_data <- all_params[[yr_key]]
    if (is.null(yr_data)) {
      avail <- sort(as.integer(names(all_params)))
      nearest <- avail[which.min(abs(avail - year))]
      yr_data <- all_params[[as.character(nearest)]]
    }
    n <- yr_data$n_vehicles %||% yr_data$n_jobs
    if (!is.null(n)) as.integer(n) else NULL
  }, error = function(e) NULL)
}
