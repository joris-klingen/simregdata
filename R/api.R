#' Initialize a dataset spine and cache it for the session
#'
#' Builds the shared person/household/object spine (if not already cached) and
#' prepares dataset-specific state so that subsequent [read_sav()] calls can
#' assemble files without rebuilding.
#'
#' The spine is shared across all datasets.  Calling `sim_init()` for any
#' dataset auto-builds the spine from woonbase parameters when needed.
#'
#' @param dataset  Dataset identifier (default `"woonbase"`).
#' @param year  Simulation year (default 2023).
#' @param n     Number of persons to generate.
#'   `NULL` (the default) fetches the actual population count from bundled
#'   parameters for `year`.  Note that `n` and `seed` only take effect when the
#'   shared spine is (re)built; if a spine for `year` is already cached, the
#'   existing spine (with its original `n`/`seed`) is reused.  Call
#'   [sim_reset()] first to force a rebuild with a different `n` or `seed`.
#' @param seed  RNG seed for reproducibility (default 42).
#' @return Invisibly `NULL`.
#' @export
sim_init <- function(dataset = "woonbase", year = 2023L, n = NULL, seed = 42L) {
  .load_dataset_registry()
  ds <- .sim_cache$datasets[[dataset]]
  if (is.null(ds)) stop("Unknown dataset: ", dataset)

  year <- as.integer(year)

  # ---- Ensure shared spine exists ----
  # The spine is built from woonbase params and shared by all datasets.
  spine <- .sim_cache$spine
  spine_year <- if (!is.null(spine)) spine$year else NULL

  needs_spine <- is.null(spine) || (!is.null(spine_year) && spine_year != year)

  if (needs_spine) {
    params <- woonbase_cbs_params(year)
    n_pers <- if (is.null(n)) params$n_persons else as.integer(n)
    spine  <- .build_spine(n_pers, params, seed, year)
    .sim_cache$spine   <- spine
    .sim_cache$params  <- params
    .sim_cache$year    <- year
    .sim_cache$seed    <- seed
    # Keep .wb in sync for backward compat
    .wb$spine  <- spine
    .wb$params <- params
    .wb$year   <- year
    .wb$seed   <- seed
    # Legacy per-dataset keys (backward compat for woonbase)
    .sim_cache$spine_woonbase  <- spine
    .sim_cache$params_woonbase <- params
    .sim_cache$year_woonbase   <- year
    .sim_cache$seed_woonbase   <- seed
  }

  spine <- .sim_cache$spine

  # ---- Dataset-specific initialization ----
  builder <- ds$spine_builder

  if (identical(builder, "woonbase")) {
    # Woonbase reads directly from the shared spine; no extra work
    .sim_cache$spine_woonbase  <- spine
    .sim_cache$params_woonbase <- .sim_cache$params
    .sim_cache$year_woonbase   <- year
    .sim_cache$seed_woonbase   <- seed

  } else if (identical(builder, "generic")) {
    # Generic spine: sample from or link to the shared spine
    needed <- .scan_spine_columns(dataset)
    has_pers <- length(needed$pers) > 0L
    has_hh   <- length(needed$hh)   > 0L
    has_obj  <- length(needed$obj)  > 0L

    set.seed(seed)
    ds_spine <- list(
      year = year,
      jan1 = as.Date(paste0(year, "-01-01")),
      dec31 = as.Date(paste0(year, "-12-31"))
    )

    # Person-level spine: sample RINPERSOON from shared person spine
    if (has_pers) {
      if (is.null(n)) {
        n_national <- .load_dataset_n(dataset, year)
        if (!is.null(n_national)) {
          params <- .sim_cache$params
          if (!is.null(params) && !is.null(params$n_persons)) {
            ratio <- n_national / params$n_persons
            n_records <- as.integer(round(nrow(spine$pers) * ratio))
          } else {
            n_records <- n_national
          }
        } else {
          n_records <- nrow(spine$pers)
        }
      } else {
        n_records <- as.integer(n)
      }

      # SPOLIS: build job structure with monthly expansion
      if (identical(dataset, "spolis")) {
        # Sample persons first (these are the workers)
        idx <- sample.int(nrow(spine$pers), n_records,
          replace = n_records > nrow(spine$pers))
        pers_cols <- intersect(
          c("RINPERSOON", needed$pers), names(spine$pers))
        if (length(pers_cols) == 0L) pers_cols <- "RINPERSOON"
        sampled_pers <- spine$pers[idx, ..pers_cols]

        # Build job-month expanded spine
        ds_spine$pers <- .build_spolis_jobs(
          sampled_pers, n_jobs = n_records, year = year, seed = seed,
          params = NULL)

      } else if (identical(dataset, "secmbus")) {
        # SECMBUS: build person-period expansion
        idx <- sample.int(nrow(spine$pers), n_records,
          replace = n_records > nrow(spine$pers))
        pers_cols <- intersect(
          c("RINPERSOON", needed$pers), names(spine$pers))
        if (length(pers_cols) == 0L) pers_cols <- "RINPERSOON"
        sampled_pers <- spine$pers[idx, ..pers_cols]

        ds_params <- tryCatch({
          pp <- file.path(.dataset_dir(dataset), "params.yaml")
          if (file.exists(pp)) {
            ap <- yaml::read_yaml(pp)
            yk <- as.character(year)
            yd <- ap[[yk]]
            if (is.null(yd)) {
              av <- sort(as.integer(names(ap)))
              yd <- ap[[as.character(av[which.min(abs(av - year))])]]
            }
            lapply(yd, function(x) if (is.list(x)) unlist(x) else x)
          }
        }, error = function(e) NULL)

        ds_spine$pers <- .build_secm_periods(
          sampled_pers, year = year, seed = seed, params = ds_params)

      } else if (identical(dataset, "inhatab")) {
        # INHATAB: one row per household (key RINPERSOONHKW) with at least
        # one member present in the year, carrying the household income
        # drawn on the spine so it matches woonbase (R/params_inhatab.R)
        ds_spine$pers <- .build_inhatab_households(spine)

      } else if (identical(dataset, "betab")) {
        # BETAB: generate unique business IDs
        # Try to reuse BEIDs from SPOLIS if available
        spolis_spine <- .sim_cache$spine_spolis
        if (!is.null(spolis_spine) && "SBEID" %in% names(spolis_spine$pers)) {
          beids <- unique(spolis_spine$pers$SBEID)
          if (length(beids) > n_records) beids <- beids[seq_len(n_records)]
        } else {
          beids <- .rand_id(n_records, 8L)
        }
        ds_spine$pers <- data.table(
          BEID = beids,
          RINPERSOON = .rand_id(length(beids), 9L),
          RINPERSOONS = rep("R", length(beids))
        )

      } else if (dataset %in% .NETWERK_DATASETS) {
        # Network datasets: build dyadic person-pair relation table.
        # NOTE: buren relations are built from a year-invariant RINPERSOON
        # ordering so a non-mover keeps the same neighbours across years.
        # We deliberately do NOT cluster on GemeenteCodeJJJJ1Jan here: gemeente
        # is a Phase-2 (year-varying) attribute, so clustering on it would both
        # break cross-year stability and make the output depend on whether a
        # woonbase spatial file was read earlier in the session.
        pers_cols <- intersect(
          unique(c("RINPERSOON", needed$pers)),
          names(spine$pers))
        if (length(pers_cols) == 0L) pers_cols <- "RINPERSOON"

        idx <- sample.int(nrow(spine$pers), n_records,
          replace = n_records > nrow(spine$pers))
        sampled_pers <- spine$pers[idx, ..pers_cols]
        # Deduplicate: network relations are per unique person
        sampled_pers <- unique(sampled_pers, by = "RINPERSOON")

        # For collega: attach SBEID from SPOLIS spine if available
        spolis_spine <- .sim_cache$spine_spolis
        if (identical(dataset, "colleganetwerktab") &&
            !is.null(spolis_spine) &&
            "SBEID" %in% names(spolis_spine$pers)) {
          sbeid_map <- unique(spolis_spine$pers[, .(RINPERSOON, SBEID)])
          sampled_pers[sbeid_map, SBEID := i.SBEID, on = "RINPERSOON"]
        }

        ds_spine$pers <- .build_netwerk_relations(
          sampled_pers, dataset, year = year, seed = seed)

      } else if (identical(dataset, "zonnestroominstallaties")) {
        # Solar installations: sample from objects (not persons)
        obj_tbl <- spine$obj_raw %||% spine$obj
        n_obj <- nrow(obj_tbl)
        n_solar <- min(n_records, n_obj)
        idx <- sample.int(n_obj, n_solar,
          replace = n_solar > n_obj)
        ds_spine$pers <- data.table(
          RINOBJECTNUMMER = obj_tbl$RINOBJECTNUMMER[idx],
          SOORTOBJECTNUMMER = if ("SOORTOBJECTNUMMER" %in% names(obj_tbl))
            obj_tbl$SOORTOBJECTNUMMER[idx] else rep("B", n_solar)
        )

      } else {
        # Standard generic sampling.
        # Gemeente vehicle-ownership weights are RDW-specific (they model car
        # density) and must NOT leak into person/household datasets like
        # inpatab/inhatab/hoogsteopltab/vehtab, which are one-row-per-person and
        # would otherwise get duplicated, population-losing samples.
        gem_wt <- if (identical(dataset, "rdw")) {
          .load_gem_vehicle_weights(dataset, year)
        } else {
          NULL
        }
        gem_col <- if (!is.null(gem_wt)) {
          spine$pers$GemeenteCodeJJJJ1Jan %||% spine$pers_gemeente
        }
        # Only sample with replacement when we genuinely need more records than
        # there are persons; weighted-without-replacement still respects the
        # gemeente weights while keeping RINPERSOON/RINKENTEKEN unique.
        # RDW: draw owners, each with one or more vehicles (R/rdw_vehicles.R).
        # Dropped and business-stock cars come on top of the active fleet.
        n_draw <- n_records
        if (identical(dataset, "rdw")) {
          p_car <- .load_rdw_params(year)$vrtgsoort_p[["6"]] %||% 0.7
          n_records <- as.integer(round(n_records / (1 - p_car *
            (.RDW_CAR_UITVAL + .RDW_CAR_BEDRIJFSVOORRAAD))))
          n_draw <- as.integer(ceiling(n_records / .RDW_MEAN_VEHICLES * 1.05))
        }
        need_replace <- n_draw > nrow(spine$pers)
        if (!is.null(gem_col)) {
          pw <- gem_wt$veh_weight[match(gem_col, gem_wt$gem_code)]
          pw[is.na(pw)] <- 1.0
          idx <- sample.int(nrow(spine$pers), n_draw,
            replace = need_replace, prob = pw)
        } else {
          idx <- sample.int(nrow(spine$pers), n_draw,
            replace = need_replace)
        }

        pers_cols <- needed$pers
        if (length(pers_cols) == 0L) pers_cols <- "RINPERSOON"
        pers_cols <- intersect(pers_cols, names(spine$pers))
        if (length(pers_cols) == 0L) pers_cols <- "RINPERSOON"
        ds_spine$pers <- spine$pers[idx, ..pers_cols]
        if (identical(dataset, "rdw")) {
          ds_spine$pers <- .rdw_expand_owners(ds_spine$pers, n_records)
        }
      }

      # Generate deterministic RINKENTEKEN from RINPERSOON
      # ~12% annual car turnover: persons who "buy a new car" get a different
      # kenteken derived from RINPERSOON + year (deterministic per person-year)
      if ("RINKENTEKEN" %in% needed$pers && !("RINKENTEKEN" %in% names(ds_spine$pers))) {
        # one key per vehicle: owners can have several (R/rdw_vehicles.R)
        rp <- .rdw_vehicle_key(ds_spine$pers$RINPERSOON, ds_spine$pers$slot)
        base_kt <- .deterministic_kenteken(rp)
        # Deterministic turnover: hash RINPERSOON to a "car birth year"
        # that is stable per person. ~12% chance of new car each year.
        car_age_seed <- (as.double(rp) * 48271 + 99991) %% 2147483647
        car_birth_year <- 2010L + as.integer(car_age_seed %% 15L)
        # Person gets a new car if year > car_birth_year + ownership_duration
        # ownership_duration ~6 years (deterministic per person)
        own_dur <- 3L + as.integer((car_age_seed * 69069) %% 2147483647 %% 8L)
        # How many cars has this person had by this year?
        car_gen <- pmax(0L, as.integer((year - car_birth_year) %/% own_dur))
        # New kenteken for each generation (salt with generation number)
        needs_new <- car_gen > 0L
        if (any(needs_new)) {
          new_id <- paste0(rp[needs_new], "_", car_gen[needs_new])
          # Hash the composite ID to get a new kenteken
          new_kt <- .deterministic_kenteken(
            as.double(as.double(rp[needs_new]) * 48271 + car_gen[needs_new] * 69069) %%
              2147483647)
          base_kt[needs_new] <- new_kt
        }
        ds_spine$pers[, RINKENTEKEN := base_kt]
      }

      # Add HKW household key if needed (for INPATAB, INHATAB, VEHTAB_VERMOGEN)
      if ("RINPERSOONHKW" %in% needed$pers &&
          !("RINPERSOONHKW" %in% names(ds_spine$pers))) {
        if ("HUISHOUDNR" %in% names(ds_spine$pers)) {
          ds_spine$pers <- .add_hkw_to_spine(ds_spine$pers)
        } else if ("HUISHOUDNR" %in% names(spine$pers)) {
          # Build RINPERSOON -> RINPERSOONHKW map from shared spine
          hh_unique <- unique(spine$pers$HUISHOUDNR)
          hkw_lookup <- data.table(
            HUISHOUDNR = hh_unique,
            RINPERSOONHKW = .deterministic_hkw_id(hh_unique)
          )
          pers_hh <- data.table(
            RINPERSOON = spine$pers$RINPERSOON,
            HUISHOUDNR = spine$pers$HUISHOUDNR
          )
          pers_hh[hkw_lookup, RINPERSOONHKW := RINPERSOONHKW,
                  on = "HUISHOUDNR"]
          # Match sampled persons to their HKW
          ds_spine$pers[, RINPERSOONHKW := pers_hh$RINPERSOONHKW[
            match(ds_spine$pers$RINPERSOON, pers_hh$RINPERSOON)]]
        } else {
          # Fallback: generate random HKW IDs
          ds_spine$pers[, RINPERSOONHKW := .rand_id(nrow(ds_spine$pers), 9L)]
        }
      }

      # Yearly registers only hold persons who belong to this year's
      # population. The shared spine also carries persons who are born,
      # immigrate, die or emigrate in other years (R/demographics.R). Records
      # are drawn from the full spine, so draws stay stable across years, and
      # records of absent persons are dropped afterwards; this also scales the
      # record count to the population present. Network datasets keep their
      # year-invariant relations and BETAB has no person sample.
      if (!is.null(spine$pers_present) &&
          !(dataset %in% c(.NETWERK_DATASETS, "betab")) &&
          "RINPERSOON" %in% names(ds_spine$pers)) {
        present_ids <- spine$pers$RINPERSOON[spine$pers_present]
        ds_spine$pers <- ds_spine$pers[RINPERSOON %in% present_ids]
      }

      if (identical(dataset, "rdw")) {
        ds_spine$pers <- .rdw_vehicle_structure(ds_spine$pers, .load_rdw_params(year))
        ds_spine$vp <- .rdw_verkeersprestatie(ds_spine$pers)
      }
    }

    # Household-level spine: copy shared HH table directly
    if (has_hh) {
      .ensure_enriched("hh")
      spine <- .sim_cache$spine
      hh_cols <- intersect(needed$hh, names(spine$hh))
      if (length(hh_cols) == 0L) hh_cols <- "HUISHOUDNR"
      ds_spine$hh <- spine$hh[, ..hh_cols]
      # household key shared with INPATAB and INHATAB (R/household_key.R)
      if ("RINPERSOONHKW" %in% needed$hh) {
        ds_spine$hh[, RINPERSOONHKW := .deterministic_hkw_id(spine$hh$HUISHOUDNR)]
      }
    }

    # Object-level spine: copy shared object table directly
    if (has_obj) {
      obj_cols <- intersect(needed$obj, names(spine$obj_raw %||% spine$obj))
      if (length(obj_cols) == 0L) obj_cols <- "RINOBJECTNUMMER"
      obj_tbl <- spine$obj_raw %||% spine$obj
      ds_spine$obj <- obj_tbl[, ..obj_cols]
      if (!"RINOBJECTNUMMER" %in% obj_cols) {
        ds_spine$obj[, RINOBJECTNUMMER := obj_tbl$RINOBJECTNUMMER]
      }
      # Energy use per dwelling from its characteristics (R/energy.R)
      if (identical(dataset, "energieverbruik")) {
        ds_spine$obj <- .build_energy(ds_spine$obj, spine, year)
      }
    }

    .sim_cache[[paste0("spine_", dataset)]] <- ds_spine
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
      # Also clear the shared spine
      if (exists("spine", envir = .sim_cache)) rm(list = "spine", envir = .sim_cache)
      if (exists("params", envir = .sim_cache)) rm(list = "params", envir = .sim_cache)
      if (exists("year", envir = .sim_cache)) rm(list = "year", envir = .sim_cache)
      if (exists("seed", envir = .sim_cache)) rm(list = "seed", envir = .sim_cache)
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
  cat("  simregdata \u2014 synthetic file catalog\n")
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
      tab <- if (isTRUE(fi$tab_suffix)) "TAB" else ""
      filename <- sprintf("%s%d%sV1", fi$cbs_name, year, tab)
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

  # CBS VM layout: try CBSNAMETAB/ first (for TAB datasets), then CBSNAME/
  is_tab <- grepl("TABV\\d+$", base)
  if (is_tab) {
    pq_path <- file.path(data_root, paste0(toupper(cbs_name), "TAB"),
                          paste0(base, ".parquet"))
    if (file.exists(pq_path)) return(pq_path)
  }
  # Fallback: plain folder name (backward compat)
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
#' @param .name_repair  Column-name repair.  For non-simulated files this is
#'   passed to `haven::read_sav()`.  For simulated files (and parquet reads) it
#'   is applied only when it is a function (e.g. `~ make.unique(.x)`); string
#'   presets like `"unique"` are ignored because generated names are already
#'   unique.
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
      if (is.function(.name_repair)) {
        names(tbl) <- .name_repair(names(tbl))
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
  # For woonbase: check shared spine; for generic: check dataset-specific spine
  ds <- .sim_cache$datasets[[dataset_id]]
  builder <- ds$spine_builder

  if (identical(builder, "woonbase")) {
    cached_spine <- .sim_cache$spine
    cached_year  <- if (!is.null(cached_spine)) cached_spine$year else NULL
    needs_init <- is.null(cached_spine) || (!is.null(cached_year) && cached_year != year)
  } else {
    spine_key <- paste0("spine_", dataset_id)
    cached_spine <- .sim_cache[[spine_key]]
    cached_year  <- .sim_cache[[paste0("year_", dataset_id)]]
    needs_init <- is.null(cached_spine) || (!is.null(cached_year) && cached_year != year)
  }

  if (needs_init) {
    if (is.infinite(n_max)) {
      # Reuse existing spine size when only the year changed
      shared <- .sim_cache$spine
      prev_n <- if (!is.null(shared)) nrow(shared$pers) else NULL
      if (!is.null(prev_n)) {
        message(sprintf("Year changed to %d: rebuilding spine with %s persons.",
                        year, format(prev_n, big.mark = ",")))
      } else {
        message("n_max = Inf: fetching population count for ", year,
                " and generating full spine.")
      }
      sim_init(dataset = dataset_id, year = year, n = prev_n, seed = seed)
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

  # Get the right spine for assembly
  if (identical(builder, "woonbase")) {
    spine <- .sim_cache$spine
  } else {
    spine <- .sim_cache[[paste0("spine_", dataset_id)]]
  }

  # Deterministic per-file seed (same scheme as sim_export) so that reading the
  # same file twice in one session yields identical data, and on-the-fly reads
  # line up with exported parquet. stable_per columns are hash-based and
  # unaffected; this only pins the ordinary random columns.
  file_seed <- bitwXor(seed, sum(utf8ToInt(paste0(dataset_id, "/", file_key))))
  set.seed(file_seed)

  # Assemble the requested file via generic YAML-driven engine
  dt <- .assemble_generic(dataset_id, file_key, spine, col_q = col_q)

  # Post-processing: income-conditional EV share for RDW kentekens
  # EV-income adjustment disabled: fuel type is now deterministic per RINKENTEKEN
  # via stable_per in the column spec. Re-randomizing would break stability.
  if (FALSE && identical(dataset_id, "rdw") && "BRANDSTCODECORVRTG" %in% names(dt) &&
      "RINPERSOON" %in% names(dt)) {
    dt <- .adjust_ev_by_income(dt, .sim_cache$spine)
  }

  # Apply skip and n_max
  if (skip > 0L) {
    dt <- dt[seq_len(nrow(dt)) > min(skip, nrow(dt))]
  }
  if (!is.infinite(n_max) && n_max < nrow(dt)) {
    dt <- dt[seq_len(as.integer(n_max))]
  }

  # Apply .name_repair to column names (matches haven::read_sav behaviour)
  if (is.function(.name_repair)) {
    names(dt) <- .name_repair(names(dt))
  }

  # Return as tibble (matches haven::read_sav output class)
  tibble::as_tibble(dt)
}


# Income-conditional EV share ----
# Adjusts BRANDSTCODECORVRTG so EV adoption correlates with household income.
# Higher-income households are more likely to own electric vehicles.
.adjust_ev_by_income <- function(dt, shared_spine) {
  if (is.null(shared_spine) || is.null(shared_spine$hh)) return(dt)

  hh_tbl <- shared_spine$hh
  if (!("P100HBEST" %in% names(hh_tbl))) return(dt)

  # Build RINPERSOON -> income percentile map from shared spine
  pers_tbl <- shared_spine$pers
  if (is.null(pers_tbl)) return(dt)
  income_map <- hh_tbl$P100HBEST[match(pers_tbl$HUISHOUDNR,
                                        hh_tbl$HUISHOUDNR)]
  names(income_map) <- pers_tbl$RINPERSOON

  # Look up income for each vehicle row
  inc_pct <- income_map[dt$RINPERSOON]
  inc_pct[is.na(inc_pct)] <- 50L

  # Strip haven labels for clean comparison, then restore
  fuel_raw <- as.character(dt$BRANDSTCODECORVRTG)
  fuel_tab <- table(fuel_raw)
  n_total <- nrow(dt)
  ev_code <- "4"
  n_ev <- as.integer(fuel_tab[ev_code] %||% 0L)
  if (n_ev < 2L || n_ev >= n_total) return(dt)

  # Income-based EV probability: logistic tilt
  # Top decile ~3x more likely than bottom decile
  ev_score <- exp(0.025 * (inc_pct - 50))

  # Assign EV by weighted sampling without replacement
  ev_idx <- sample.int(n_total, n_ev, replace = FALSE, prob = ev_score)
  is_ev <- rep(FALSE, n_total)
  is_ev[ev_idx] <- TRUE

  # Non-EV fuel distribution (preserve relative shares)
  non_ev_fuels <- fuel_tab[names(fuel_tab) != ev_code]
  non_ev_p <- as.numeric(non_ev_fuels) / sum(non_ev_fuels)
  non_ev_names <- names(non_ev_fuels)

  # Reassign: overwrite the whole column to avoid type mismatch
  fuel_raw[is_ev] <- ev_code
  fuel_raw[!is_ev] <- .rcat(sum(!is_ev), non_ev_names, non_ev_p)
  data.table::set(dt, j = "BRANDSTCODECORVRTG", value = fuel_raw)
  dt
}


# Parquet export ----

# Resolve col_select keys to dataset IDs via the registry.
# Keys can be CBS names ("RDWNPACT"), their case variants, or file keys
# ("kentekens").  Returns a unique character vector of dataset IDs.
.datasets_from_col_select <- function(col_select) {
  .load_dataset_registry()
  registry <- .sim_cache$registry
  all_datasets <- .sim_cache$datasets

  ds_ids <- character()
  unmatched <- character()

  for (key in names(col_select)) {
    # Try registry lookup (cbs_name)
    info <- registry[[key]] %||% registry[[toupper(key)]] %||%
            registry[[tolower(key)]]
    if (!is.null(info)) {
      ds_ids <- c(ds_ids, info$dataset_id)
      next
    }
    # Try as file key across all datasets
    found <- FALSE
    for (ds_id in names(all_datasets)) {
      if (key %in% names(all_datasets[[ds_id]]$files)) {
        ds_ids <- c(ds_ids, ds_id)
        found <- TRUE
        break
      }
    }
    if (!found) unmatched <- c(unmatched, key)
  }

  if (length(unmatched) > 0L) {
    stop("col_select key(s) not found in any dataset: ",
         paste(unmatched, collapse = ", "))
  }
  unique(ds_ids)
}

# Simulation metadata helpers ----

.SIM_META_FILE <- ".sim_meta.yaml"

.read_sim_meta <- function(output_dir) {
  path <- file.path(output_dir, .SIM_META_FILE)
  if (!file.exists(path)) return(list())
  yaml::read_yaml(path)
}

.write_sim_meta <- function(output_dir, meta) {
  path <- file.path(output_dir, .SIM_META_FILE)
  yaml::write_yaml(meta, path)
}

# Build a meta key for a file+year combination (e.g. "RDWNPACT/2023")
.meta_key <- function(cbs_name, year) {
  paste0(cbs_name, "/", year)
}

# Check whether a file needs (re-)simulation.
# Returns TRUE if: no meta entry exists, columns changed, n changed, or seed changed.
# When columns is NULL (all columns requested), always re-simulate unless
# the meta entry was itself a full export (n and seed match and entry exists).
# Scalar equality that treats two NULLs as equal (n = NULL round-trips through
# .sim_meta.yaml as a missing/NULL field; `NULL != NULL` is logical(0) and would
# error inside `if`).
.eq_scalar <- function(a, b) {
  if (is.null(a) && is.null(b)) return(TRUE)
  if (is.null(a) || is.null(b)) return(FALSE)
  isTRUE(a == b)
}

.file_needs_sim <- function(meta, cbs_name, year, columns, n, seed) {
  key <- .meta_key(cbs_name, year)
  entry <- meta[[key]]
  if (is.null(entry)) return(TRUE)
  if (!.eq_scalar(entry$n, n) || !.eq_scalar(entry$seed, seed)) return(TRUE)
  # NULL columns = all columns requested; skip only if entry is a full export
  if (is.null(columns)) return(!isTRUE(entry$full))
  # Check if all requested columns are already present
  !all(columns %in% unlist(entry$columns))
}

# Record a file in the meta after successful export.
# full = TRUE when col_select was NULL for this file (all columns exported).
.meta_record <- function(meta, cbs_name, year, columns, n, seed, full = FALSE) {
  key <- .meta_key(cbs_name, year)
  meta[[key]] <- list(
    columns   = as.list(sort(columns)),
    n         = n,
    seed      = seed,
    full      = full,
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
  )
  meta
}

# Check whether a file (identified by CBS name or file key) is requested
# in a col_select list.  Returns TRUE when col_select is NULL (export all)
# or when any variant of the name appears as a key.
.file_requested <- function(cbs_name, fkey, col_select) {
  if (is.null(col_select)) return(TRUE)
  !is.null(col_select[[cbs_name]]          %||%
           col_select[[toupper(cbs_name)]]  %||%
           col_select[[tolower(cbs_name)]]  %||%
           col_select[[fkey]])
}

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
#' @param col_select  Optional named list of character vectors specifying
#'   which columns to include per CBS file.  Keys are CBS file names (e.g.
#'   `"SPOLISBUS"`) or file keys (e.g. `"spolisbus"`).  Identity/join key
#'   columns (defined in each manifest's `key_columns`) are always included.
#'   Files not listed are skipped entirely.  Default `NULL` exports all
#'   files with all columns.
#' @param force_resim  Logical; if `TRUE`, regenerate all files regardless
#'   of what was previously simulated.  Default `FALSE` skips files whose
#'   columns, `n`, and `seed` already match the `.sim_meta.yaml` in
#'   `output_dir`.
#' @return Invisibly, a list with elements `dir` (the output directory),
#'   `written` (number of parquet files written) and `skipped` (number of
#'   files skipped because they were already simulated).
#' @export
sim_export <- function(output_dir, dataset = NULL, year = 2023L,
                       n = NULL, seed = 42L, col_select = NULL,
                       force_resim = FALSE) {
  if (!requireNamespace("arrow", quietly = TRUE))
    stop("Package 'arrow' is required to write parquet files. ",
         "Install it with: install.packages('arrow')")

  .load_dataset_registry()
  ds_ids <- if (is.null(dataset)) names(.sim_cache$datasets) else dataset

  output_dir <- normalizePath(output_dir, mustWork = FALSE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  meta <- if (force_resim) list() else .read_sim_meta(output_dir)

  files_written <- character()
  files_skipped <- character()
  spine_built <- FALSE

  for (ds_id in ds_ids) {
    ds <- .sim_cache$datasets[[ds_id]]
    builder <- ds$spine_builder

    for (fkey in names(ds$files)) {
      fi <- ds$files[[fkey]]
      cbs_name <- fi$cbs_name

      # Skip files not requested by col_select
      if (!.file_requested(cbs_name, fkey, col_select)) next

      # Build filename: TAB suffix for tab_suffix files
      tab <- isTRUE(fi$tab_suffix)
      fname <- if (tab) {
        sprintf("%s%dTABV1.parquet", cbs_name, year)
      } else {
        sprintf("%s%dV1.parquet", cbs_name, year)
      }

      # Create subdirectory (include TAB suffix to match CBS VM layout)
      up_name <- toupper(cbs_name)
      folder_name <- if (tab && !grepl("TAB$", up_name)) {
        paste0(up_name, "TAB")
      } else {
        up_name
      }
      subdir <- file.path(output_dir, folder_name)
      dir.create(subdir, recursive = TRUE, showWarnings = FALSE)
      out_path <- file.path(subdir, fname)

      # Deterministic seed per file: base seed XOR hash of dataset+file key
      file_seed <- bitwXor(seed, sum(utf8ToInt(paste0(ds_id, "/", fkey))))
      set.seed(file_seed)

      # Resolve col_select for this file (match by CBS name or file key)
      file_col_q <- NULL
      file_cols <- NULL
      user_cols <- NULL
      if (!is.null(col_select)) {
        user_cols <- col_select[[cbs_name]] %||%
                     col_select[[toupper(cbs_name)]] %||%
                     col_select[[tolower(cbs_name)]] %||%
                     col_select[[fkey]]
        if (!is.null(user_cols)) {
          # Always include key columns from manifest
          key_cols <- fi$key_columns
          file_cols <- if (!is.null(key_cols)) {
            unique(c(unlist(key_cols), user_cols))
          } else {
            user_cols
          }
          file_col_q <- rlang::quo(tidyselect::all_of(file_cols))
        }
      }

      # Check meta against user-requested columns only (key_columns may have
      # suffixes in the actual output, so comparing them causes false mismatches)
      if (!.file_needs_sim(meta, cbs_name, year, user_cols, n, seed)) {
        files_skipped <- c(files_skipped, out_path)
        message(sprintf("  %s  (skipped, already simulated)", out_path))
        next
      }

      # Build spine lazily (only when at least one file needs generation)
      if (!spine_built) {
        if (is.null(.sim_cache$spine)) {
          sim_init("woonbase", year = year, n = n, seed = seed)
        }
        for (init_id in ds_ids) {
          sim_init(init_id, year = year, n = n, seed = seed)
        }
        spine_built <- TRUE
      }
      spine <- if (identical(builder, "woonbase")) {
        .sim_cache$spine
      } else {
        .sim_cache[[paste0("spine_", ds_id)]]
      }

      # Assemble the data.table (with optional column subset)
      dt <- .assemble_generic(ds_id, fkey, spine, col_q = file_col_q)
      tbl <- tibble::as_tibble(dt)

      # Write parquet
      arrow::write_parquet(tbl, out_path)
      files_written <- c(files_written, out_path)

      # Record in meta (use actual columns from assembled result)
      is_full <- is.null(file_cols)
      meta <- .meta_record(meta, cbs_name, year, names(tbl), n, seed,
                           full = is_full)

      message(sprintf("  %s  (%s rows x %s cols)",
                      out_path, format(nrow(tbl), big.mark = ","),
                      ncol(tbl)))
    }
  }

  # Persist meta to disk
  if (length(files_written) > 0L) {
    .write_sim_meta(output_dir, meta)
  }

  n_written <- length(files_written)
  n_skipped <- length(files_skipped)
  skip_msg <- if (n_skipped > 0L) sprintf(" (%d skipped)", n_skipped) else ""
  message(sprintf("\nExported %d parquet files to %s%s",
                  n_written, output_dir, skip_msg))
  invisible(list(dir = output_dir, written = n_written, skipped = n_skipped))
}


#' Generate a fractional sample of all datasets
#'
#' Convenience wrapper around [sim_export()] that generates a percentage of the
#' full CBS population for all datasets and writes parquet files in CBS VM-style
#' folder layout.  Supports multiple years in a single call.
#'
#' Network datasets (buren, collega, familie) are excluded by default because
#' they produce O(n * relations_per_person) rows and can be very large.
#'
#' @param output_dir  Directory to write parquet files into.
#' @param fraction    Fraction of the full population to simulate (default 0.01
#'   = 1%).  Must be between 0 (exclusive) and 1 (inclusive).
#' @param years       Integer vector of simulation years (default 2023).
#' @param seed        RNG seed for reproducibility (default 42).
#' @param include_network  Logical; include network datasets (buren, collega,
#'   familie)?  Default `FALSE`.
#' @param datasets   Optional character vector of dataset identifiers to
#'   include (e.g. `c("woonbase", "rdw")`).  Default `NULL` exports all
#'   registered datasets.  Takes precedence over `include_network`.
#' @param col_select  Optional named list passed to [sim_export()].  Keys are
#'   CBS file names (e.g. `"WoonbasePopulatiePersonen"`, `"RDWNPACT"`) and
#'   values are character vectors of column names.  Key columns (RINPERSOON
#'   etc.) are always included automatically.
#' @param force_resim  Logical; if `TRUE`, wipe the output directory and
#'   regenerate everything from scratch.  Default `FALSE` skips files that
#'   are already present in `.sim_meta.yaml` with matching columns, `n`,
#'   and `seed`.
#' @param verbose     Print progress summary (default `TRUE`).
#' @return Invisibly, `output_dir`.
#' @export
sim_population <- function(output_dir, fraction = 0.01, years = 2023L,
                       seed = 42L, include_network = FALSE,
                       datasets = NULL, col_select = NULL,
                       force_resim = FALSE, verbose = TRUE) {
  stopifnot(is.numeric(fraction), length(fraction) == 1L,
            fraction > 0, fraction <= 1)
  years <- as.integer(years)

  # Compute n from fraction using max population across years
  # Using a fixed n ensures longitudinal consistency (same persons across years)
  params_by_year <- lapply(stats::setNames(years, years), function(yr)
    suppressMessages(woonbase_cbs_params(yr)))
  max_pop <- max(vapply(params_by_year, function(p) p$n_persons, integer(1L)))
  n <- as.integer(round(fraction * max_pop))
  # Use first year for prompt display
  params <- params_by_year[[1L]]

  # Determine which datasets to export
  .load_dataset_registry()
  if (!is.null(datasets) && !is.null(col_select)) {
    stop("Specify either 'datasets' or 'col_select', not both. ",
         "When col_select is provided, datasets are inferred automatically.")
  }
  if (!is.null(col_select)) {
    # Infer datasets from col_select keys
    ds_ids <- .datasets_from_col_select(col_select)
  } else if (!is.null(datasets)) {
    unknown <- setdiff(datasets, names(.sim_cache$datasets))
    if (length(unknown) > 0L) {
      stop("Unknown dataset(s): ", paste(unknown, collapse = ", "),
           "\nAvailable: ", paste(names(.sim_cache$datasets), collapse = ", "))
    }
    ds_ids <- datasets
  } else {
    ds_ids <- names(.sim_cache$datasets)
    if (!include_network) {
      ds_ids <- setdiff(ds_ids, .NETWERK_DATASETS)
    }
  }

  n_years <- length(years)
  n_datasets <- length(ds_ids)

  # Estimate output size and time based on actual columns ----
  # Count columns per file, accounting for col_select
  total_cols <- 0L
  for (ds_id in ds_ids) {
    ds <- .sim_cache$datasets[[ds_id]]
    for (fkey in names(ds$files)) {
      fi <- ds$files[[fkey]]
      cbs_name <- fi$cbs_name
      # Skip files not requested by col_select
      if (!.file_requested(cbs_name, fkey, col_select)) next
      # Count columns from spec
      spec <- .load_column_spec(ds_id, fkey)
      n_file_cols <- 0L
      for (cs in spec$columns) {
        if (!is.null(cs[["suffixes"]])) {
          n_file_cols <- n_file_cols + length(cs[["suffixes"]])
        } else if (!is.null(cs[["suffixes_custom"]])) {
          n_file_cols <- n_file_cols + length(cs[["suffixes_custom"]])
        } else {
          n_file_cols <- n_file_cols + 1L
        }
      }
      # Apply col_select reduction if specified
      if (!is.null(col_select)) {
        file_cols <- col_select[[cbs_name]] %||%
                     col_select[[toupper(cbs_name)]] %||%
                     col_select[[tolower(cbs_name)]] %||%
                     col_select[[fkey]]
        if (!is.null(file_cols)) {
          n_file_cols <- length(file_cols)
        }
      }
      total_cols <- total_cols + n_file_cols
    }
  }
  # ~1.7 bytes per column per row in parquet; ~3s per 100k persons per dataset-year
  est_mb <- as.numeric(n) * total_cols * 1.7 * n_years / 1e6
  est_sec <- as.numeric(n) / 1e5 * 3 * n_datasets * n_years

  # Format size and time with appropriate units
  size_str <- if (est_mb >= 1000) {
    sprintf("%.1f GB", est_mb / 1000)
  } else {
    sprintf("%.0f MB", est_mb)
  }
  time_str <- if (est_sec >= 120) {
    sprintf("%.1f min", est_sec / 60)
  } else {
    sprintf("%.0f sec", est_sec)
  }

  # Check meta to count how many files need (re-)simulation ----
  output_dir <- normalizePath(output_dir, mustWork = FALSE)
  meta <- if (force_resim) list() else .read_sim_meta(output_dir)
  n_total_files <- 0L
  n_new_files   <- 0L
  new_file_names <- character()
  for (yr in years) {
    for (ds_id in ds_ids) {
      ds <- .sim_cache$datasets[[ds_id]]
      for (fkey in names(ds$files)) {
        fi <- ds$files[[fkey]]
        cbs_name <- fi$cbs_name
        if (!.file_requested(cbs_name, fkey, col_select)) next
        n_total_files <- n_total_files + 1L
        # Resolve user-requested columns (without key_columns, which may
        # have suffixes in the actual output)
        fc <- NULL
        if (!is.null(col_select)) {
          fc <- col_select[[cbs_name]] %||%
                col_select[[toupper(cbs_name)]] %||%
                col_select[[tolower(cbs_name)]] %||%
                col_select[[fkey]]
        }
        if (.file_needs_sim(meta, cbs_name, yr, fc, n, seed)) {
          n_new_files <- n_new_files + 1L
          new_file_names <- c(new_file_names, cbs_name)
        }
      }
    }
  }
  n_cached <- n_total_files - n_new_files

  # Check if any cached files have more columns than currently requested
  has_extra_cols <- FALSE
  if (!is.null(col_select) && length(meta) > 0L) {
    for (ds_id in ds_ids) {
      if (has_extra_cols) break
      ds <- .sim_cache$datasets[[ds_id]]
      for (fkey in names(ds$files)) {
        fi <- ds$files[[fkey]]
        cbs_name <- fi$cbs_name
        if (!.file_requested(cbs_name, fkey, col_select)) next
        fc <- col_select[[cbs_name]] %||%
              col_select[[toupper(cbs_name)]] %||%
              col_select[[tolower(cbs_name)]] %||%
              col_select[[fkey]]
        if (is.null(fc)) next
        entry <- meta[[.meta_key(cbs_name, years[1L])]]
        if (is.null(entry)) next
        meta_cols <- unlist(entry$columns)
        key_cols <- unlist(fi$key_columns)
        extra <- setdiff(setdiff(meta_cols, fc), key_cols)
        if (length(extra) > 0L) { has_extra_cols <- TRUE; break }
      }
    }
  }

  # Always prompt in interactive mode
  if (interactive()) {
    cat(sprintf(paste0(
      "\nCBS population %d: %s persons\n",
      "Simulating %.1f%% = %s persons, %d year%s, %d datasets\n",
      "  Estimated size: %s\n",
      "  Estimated time: %s\n"),
      years[1L], format(params$n_persons, big.mark = ","),
      fraction * 100, format(n, big.mark = ","),
      n_years, if (n_years > 1L) "s" else "",
      n_datasets, size_str, time_str))
    if (n_cached > 0L) {
      cat(sprintf("  Cached: %d/%d files (only %d to simulate)\n",
                  n_cached, n_total_files, n_new_files))
      if (n_new_files > 0L) {
        cat(sprintf("  New/changed: %s\n",
                    paste(unique(new_file_names), collapse = ", ")))
      }
    }
    if (has_extra_cols) {
      cat("  Note: some cached files have more columns than requested.\n")
    }
    if (n_new_files == 0L) {
      cat("  All files already simulated, nothing to do.\n")
      return(invisible(output_dir))
    }
    ans <- readline("Continue? (y/n) ")
    if (!tolower(trimws(ans)) %in% c("y", "yes")) {
      message("Aborted.")
      return(invisible(NULL))
    }
  }

  t0 <- proc.time()

  # Wipe output directory on force_resim
  if (force_resim && dir.exists(output_dir)) {
    unlink(output_dir, recursive = TRUE)
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    if (verbose) cat("Wiped output directory (force_resim)\n")
  }

  for (yr in years) {
    yr_idx <- which(years == yr)
    if (verbose) {
      cat(sprintf("\n[%d/%d] Year %d\n", yr_idx, n_years, yr))
      flush.console(); Sys.sleep(0)
    }

    suppressMessages(sim_reset())
    .load_dataset_registry()

    # Pre-init spolis so SBEID is available for collega (if included)
    if ("spolis" %in% ds_ids && "colleganetwerktab" %in% ds_ids) {
      suppressMessages(sim_init("spolis", year = yr, n = n, seed = seed))
    }

    # Export datasets for this year, showing per-file progress
    for (i in seq_along(ds_ids)) {
      ds_id <- ds_ids[i]
      # Print per-file lines with pre-computed skip/new status
      any_new <- FALSE
      if (verbose) {
        ds <- .sim_cache$datasets[[ds_id]]
        for (fkey in names(ds$files)) {
          fi <- ds$files[[fkey]]
          cbs_name <- fi$cbs_name
          if (!.file_requested(cbs_name, fkey, col_select)) next
          fc <- if (!is.null(col_select)) {
            col_select[[cbs_name]] %||%
              col_select[[toupper(cbs_name)]] %||%
              col_select[[tolower(cbs_name)]] %||%
              col_select[[fkey]]
          }
          will_skip <- !.file_needs_sim(meta, cbs_name, yr, fc, n, seed)
          up <- toupper(cbs_name)
          folder <- if (isTRUE(fi$tab_suffix) && !grepl("TAB$", up)) {
            paste0(up, "TAB")
          } else up
          preview <- if (!is.null(fc) && length(fc) > 0L) {
            if (length(fc) > 4L) {
              paste0(paste(fc[1:4], collapse = ", "), ", ...")
            } else {
              paste(fc, collapse = ", ")
            }
          } else {
            "all columns"
          }
          if (will_skip) {
            cat(sprintf("  %s [%s] skipped\n", folder, preview))
          } else {
            any_new <- TRUE
            cat(sprintf("  %s [%s] ...\n", folder, preview))
            flush.console(); Sys.sleep(0)
          }
        }
      }
      if (any_new || !verbose) {
        suppressMessages(
          sim_export(output_dir, dataset = ds_id, year = yr, n = n,
                     seed = seed, col_select = col_select,
                     force_resim = force_resim))
        # Re-read meta after export so subsequent checks see updates
        meta <- .read_sim_meta(output_dir)
        if (verbose) cat(sprintf("    %s done\n", ds_id))
      }
    }
  }

  elapsed <- (proc.time() - t0)[["elapsed"]]
  if (verbose) {
    # Count total files written
    all_files <- list.files(output_dir, pattern = "\\.parquet$",
                            recursive = TRUE)
    total_mb <- sum(file.size(
      file.path(output_dir, all_files)), na.rm = TRUE) / 1e6
    cat(sprintf("\nDone: %d files, %.0f MB, %.0f sec\n",
                length(all_files), total_mb, elapsed))
  }
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
    n <- yr_data$n_vehicles %||% yr_data$n_jobs %||% yr_data$n_households %||%
         yr_data$n_dwellings %||% yr_data$n_persons %||% yr_data$n_businesses %||%
         yr_data$n_installations
    if (!is.null(n)) as.integer(n) else NULL
  }, error = function(e) NULL)
}
