# Generic data-driven assembly engine ----

# Resolve a single column value from spec + spine
.resolve_column <- function(col_spec, spine, n_rows, codelists, jan1, dec31,
                            computed, params = NULL, base_tbl = NULL) {

  # Constant value
  if (!is.null(col_spec$value)) {
    return(rep(as.character(col_spec$value), n_rows))
  }

  # Template (date placeholders)
  if (!is.null(col_spec$template)) {
    tpl <- col_spec$template
    tpl <- gsub("\\{jan1\\}", jan1, tpl, fixed = FALSE)
    tpl <- gsub("\\{dec31\\}", dec31, tpl, fixed = FALSE)
    return(rep(tpl, n_rows))
  }

  # Random categorical (optionally from params)
  if (!is.null(col_spec$random_categorical)) {
    rc <- col_spec$random_categorical
    stable_id <- col_spec$stable_per
    # stable_per: deterministic assignment by identifier. Still honor a
    # from_params year-calibrated distribution when one is available; only fall
    # back to the hardcoded values/probs when the params key is missing.
    if (!is.null(stable_id) && !is.null(base_tbl) &&
        stable_id %in% names(base_tbl)) {
      vals <- as.character(rc$values)
      probs <- if (!is.null(rc$probs)) as.numeric(rc$probs) else
        rep(1 / length(vals), length(vals))
      if (!is.null(rc$from_params) && !is.null(params)) {
        pv <- params[[rc$from_params]]
        if (!is.null(pv)) {
          vals  <- as.character(names(pv))
          probs <- as.numeric(pv)
        }
      }
      return(.deterministic_categorical(
        as.character(base_tbl[[stable_id]]), vals, probs,
        salt = col_spec$name))
    }
    # from_params: look up named probability vector from cached dataset params
    if (!is.null(rc$from_params) && !is.null(params)) {
      pv <- params[[rc$from_params]]
      if (!is.null(pv)) {
        vals  <- as.character(names(pv))
        probs <- as.numeric(pv)
        return(.rcat(n_rows, vals, probs))
      }
    }
    vals <- as.character(rc$values)
    probs <- if (!is.null(rc$probs)) as.numeric(rc$probs) else NULL
    return(.rcat(n_rows, vals, probs))
  }

  # Random ID (fixed-width random identifier string)
  if (!is.null(col_spec$random_id)) {
    w <- as.integer(col_spec$random_id$width)
    return(.rand_id(n_rows, w))
  }

  # Random numeric (optionally from params)
  if (!is.null(col_spec$random_numeric)) {
    rn <- col_spec$random_numeric
    stable_id <- col_spec$stable_per
    # stable_per: deterministic numeric by identifier. Apply mean/sd overrides
    # from year-calibrated params first, then hash deterministically so the
    # value stays constant per identifier across years.
    if (!is.null(stable_id) && !is.null(base_tbl) &&
        stable_id %in% names(base_tbl)) {
      if (!is.null(params)) {
        if (!is.null(rn$mean_from_params))
          rn$mean <- as.numeric(params[[rn$mean_from_params]] %||% rn$mean)
        if (!is.null(rn$sd_from_params))
          rn$sd <- as.numeric(params[[rn$sd_from_params]] %||% rn$sd)
      }
      return(.deterministic_numeric(
        as.character(base_tbl[[stable_id]]),
        distribution = rn$distribution,
        mean = as.numeric(rn$mean %||% 0),
        sd = as.numeric(rn$sd %||% 1),
        min = as.numeric(rn$min %||% -Inf),
        max = as.numeric(rn$max %||% Inf),
        round = rn$round,
        salt = col_spec$name))
    }
    # Override mean/sd from params if specified
    if (!is.null(params)) {
      if (!is.null(rn$mean_from_params))
        rn$mean <- as.numeric(params[[rn$mean_from_params]] %||% rn$mean)
      if (!is.null(rn$sd_from_params))
        rn$sd <- as.numeric(params[[rn$sd_from_params]] %||% rn$sd)
    }
    if (identical(rn$distribution, "uniform")) {
      vals <- runif(n_rows, rn$min, rn$max)
      if (!is.null(rn$round)) vals <- round(vals, as.integer(rn$round))
      return(vals)
    }
    if (identical(rn$distribution, "normal")) {
      vals <- rnorm(n_rows, rn$mean, rn$sd)
      if (!is.null(rn$min)) vals <- pmax(vals, rn$min)
      if (!is.null(rn$max)) vals <- pmin(vals, rn$max)
      if (!is.null(rn$round)) vals <- round(vals, as.integer(rn$round))
      return(vals)
    }
    stop("Unknown random_numeric distribution: ", rn$distribution)
  }

  # Source from spine or computed
  if (!is.null(col_spec$source)) {
    src <- col_spec$source
    # computed.XXX sources
    if (grepl("^computed\\.", src)) {
      col_name <- sub("^computed\\.", "", src)
      val <- computed[[col_name]]
      if (is.null(val)) stop("Computed column not found: ", col_name)
      return(val)
    }
    # spine.{table}.{col} sources
    parts <- strsplit(src, ".", fixed = TRUE)[[1L]]
    if (length(parts) >= 3L && parts[1L] == "spine") {
      tbl_name <- parts[2L]
      col_name <- paste(parts[3L:length(parts)], collapse = ".")
      tbl <- spine[[tbl_name]]
      if (is.null(tbl)) stop("Spine table not found: ", tbl_name)
      if (!(col_name %in% names(tbl)))
        stop("Column '", col_name, "' not found in spine$", tbl_name)
      return(tbl[[col_name]])
    }
  }

  stop("Cannot resolve column spec: ", paste(names(col_spec), collapse = ", "))
}

# Apply codelist labelling to a column value
.apply_codelist <- function(val, col_spec, codelists) {
  if (is.null(col_spec$codelist)) {
    # No codelist: still attach the variable label (haven's "label" attribute)
    # so documented labels on non-coded columns reach the output.
    if (!is.null(col_spec$label)) attr(val, "label") <- col_spec$label
    return(val)
  }
  cl_name <- col_spec$codelist
  cl <- codelists[[cl_name]]
  if (is.null(cl)) stop("Codelist not found: ", cl_name)

  # Determine label text
  lbl_text <- col_spec$label
  if (isTRUE(col_spec$indicator_label)) {
    # Use gsub("_"," ", col_name) pattern like old code
    lbl_text <- gsub("_", " ", col_spec$name)
  }

  .lbl(val, cl, lbl_text)
}

# Compute persklasse transform (AantalPersonenPerVSL → klasse)
.compute_persklasse <- function(n_vec) {
  data.table::fcase(
    n_vec == 0L, "----", n_vec == 1L, "1", n_vec == 2L, "2",
    n_vec == 3L, "3", n_vec == 4L, "4", n_vec == 5L, "5",
    n_vec %between% c(6L, 9L), "6", n_vec >= 10L, "7",
    default = "----"
  )
}


# Filter spec to only columns in selected_set (for enrichment checks)
.filter_spec_to_selected <- function(spec, selected_set) {
  filtered <- spec
  filtered$columns <- Filter(function(cs) {
    if (!is.null(cs[["suffixes"]])) {
      expanded <- vapply(cs[["suffixes"]], function(sfx)
        gsub("\\{sfx\\}", sfx, cs$name), character(1L))
      any(expanded %in% selected_set)
    } else if (!is.null(cs[["suffixes_custom"]])) {
      expanded <- vapply(cs[["suffixes_custom"]], function(sc)
        gsub("\\{sfx_lower\\}", sc$output_suffix, cs$name), character(1L))
      any(expanded %in% selected_set)
    } else {
      cs$name %in% selected_set
    }
  }, spec$columns)
  # Also filter pre_compute to only those referenced by remaining columns
  if (!is.null(filtered$pre_compute)) {
    needed_computed <- character()
    for (cs in filtered$columns) {
      if (!is.null(cs$source) && grepl("^computed\\.", cs$source))
        needed_computed <- c(needed_computed, sub("^computed\\.", "", cs$source))
    }
    if (length(needed_computed) > 0L) {
      filtered$pre_compute <- Filter(function(pc) pc$name %in% needed_computed,
                                     filtered$pre_compute)
    } else {
      filtered$pre_compute <- list()
    }
  }
  filtered
}

# Main generic assembly: builds a data.table from YAML column spec
.assemble_generic <- function(dataset_id, file_key, spine, col_q = NULL) {

  spec <- .load_column_spec(dataset_id, file_key)
  codelists <- .load_codelists(dataset_id)

  # Determine which spine table to use + row count
  tbl_name <- spec$spine_table

  # Pre-filter columns via col_select (compute early so enrichment can use it)
  selected_set <- NULL
  has_col_select <- !is.null(col_q) && !rlang::quo_is_null(col_q)
  if (has_col_select) {
    # Expand all column names to know the full set
    all_names <- character(length(spec$columns) * 2L)
    idx_n <- 0L
    for (cs in spec$columns) {
      if (!is.null(cs[["suffixes"]])) {
        for (sfx in cs[["suffixes"]]) {
          idx_n <- idx_n + 1L
          all_names[[idx_n]] <- gsub("\\{sfx\\}", sfx, cs$name)
        }
      } else if (!is.null(cs[["suffixes_custom"]])) {
        for (sc in cs[["suffixes_custom"]]) {
          idx_n <- idx_n + 1L
          all_names[[idx_n]] <- gsub("\\{sfx_lower\\}", sc$output_suffix, cs$name)
        }
      } else {
        idx_n <- idx_n + 1L
        all_names[[idx_n]] <- cs$name
      }
    }
    all_names <- all_names[seq_len(idx_n)]
    # Evaluate col_select against a dummy with all names
    selected_set <- tryCatch({
      dummy <- stats::setNames(as.list(seq_along(all_names)), all_names)
      dummy <- as.data.frame(dummy, check.names = FALSE)
      names(tidyselect::eval_select(col_q, dummy))
    }, error = function(e) {
      NULL
    })
  }

  # Trigger lazy enrichment if needed (shared spine has enrichment flags)
  # When col_select is active, only enrich if selected columns need it
  if (!is.null(spine$hh_enriched)) {
    check_spec <- if (!is.null(selected_set)) {
      .filter_spec_to_selected(spec, selected_set)
    } else {
      spec
    }
    if (tbl_name == "hh" && !isTRUE(spine$hh_enriched)) {
      if (.spec_needs_hh_enriched(check_spec)) {
        spine <- .ensure_enriched("hh")
      }
    } else if (tbl_name == "obj" && !isTRUE(spine$obj_enriched)) {
      if (.spec_needs_obj_enriched(check_spec)) {
        spine <- .ensure_enriched("obj")
      }
    } else if (tbl_name == "pers" && !isTRUE(spine$pers_spatial_enriched)) {
      if (.spec_needs_pers_spatial(check_spec)) {
        spine <- .ensure_enriched("pers_spatial")
      }
    }
  }

  # Population snapshot: restrict a person-level file to the persons present in
  # the simulation year (demographic entry/exit) and repair household
  # bookkeeping for the survivors. Enrichment above has already run against the
  # full person spine, so the presence mask still aligns row-for-row and the
  # subset carries any enriched columns. The filtered table is substituted into
  # the local `spine` (copy-on-modify, so the session cache is untouched) so
  # that both the base table and every `spine.pers.*` source read use the same
  # population. See R/demographics.R.
  if (isTRUE(spec$population_snapshot) && identical(tbl_name, "pers") &&
      !is.null(spine$pers_present)) {
    spine$pers <- .repair_active_households(spine$pers[spine$pers_present])
  }

  base_tbl <- spine[[tbl_name]]
  if (is.null(base_tbl)) stop("Spine table '", tbl_name, "' not found")
  n_rows <- nrow(base_tbl)

  jan1  <- .yyyymmdd(spine$jan1)
  dec31 <- .yyyymmdd(spine$dec31)

  # Load dataset params (year-specific calibrated distributions).
  # Use a "dsparams_" prefix so the woonbase key does not collide with the
  # legacy full spine-params list cached under "params_woonbase" by sim_init().
  params_key <- paste0("dsparams_", dataset_id)
  params_yr_key <- paste0("dsparams_year_", dataset_id)
  params <- .sim_cache[[params_key]]
  cached_yr <- .sim_cache[[params_yr_key]]
  if (is.null(params) || !identical(cached_yr, spine$year)) {
    params <- tryCatch({
      params_path <- file.path(.dataset_dir(dataset_id), "params.yaml")
      if (file.exists(params_path)) {
        all_p <- yaml::read_yaml(params_path)
        yr_key <- as.character(spine$year)
        yr_data <- all_p[[yr_key]]
        if (is.null(yr_data)) {
          avail <- sort(as.integer(names(all_p)))
          nearest <- avail[which.min(abs(avail - spine$year))]
          yr_data <- all_p[[as.character(nearest)]]
        }
        lapply(yr_data, function(x) {
          if (is.list(x)) unlist(x) else x
        })
      }
    }, error = function(e) NULL)
    if (!is.null(params)) {
      .sim_cache[[params_key]] <- params
      .sim_cache[[params_yr_key]] <- spine$year
    }
  }

  # Pre-compute derived columns if specified (skip unneeded when col_select active)
  computed <- list()
  if (!is.null(spec$pre_compute)) {
    # Find which computed columns are actually referenced by selected columns
    needed_computed <- NULL
    if (!is.null(selected_set)) {
      needed_computed <- character()
      for (cs in spec$columns) {
        # Only check columns that will be generated
        col_names <- if (!is.null(cs[["suffixes"]])) {
          vapply(cs[["suffixes"]], function(sfx)
            gsub("\\{sfx\\}", sfx, cs$name), character(1L))
        } else if (!is.null(cs[["suffixes_custom"]])) {
          vapply(cs[["suffixes_custom"]], function(sc)
            gsub("\\{sfx_lower\\}", sc$output_suffix, cs$name), character(1L))
        } else {
          cs$name
        }
        if (any(col_names %in% selected_set) && !is.null(cs$source) &&
            grepl("^computed\\.", cs$source)) {
          needed_computed <- c(needed_computed, sub("^computed\\.", "", cs$source))
        }
      }
    }
    for (pc in spec$pre_compute) {
      if (!is.null(needed_computed) && !(pc$name %in% needed_computed)) next
      src_val <- .resolve_column(pc, spine, n_rows, codelists, jan1, dec31,
                                 computed, params)
      if (identical(pc$transform, "persklasse")) {
        computed[[pc$name]] <- .compute_persklasse(as.integer(src_val))
      } else {
        computed[[pc$name]] <- src_val
      }
    }
  }

  # Detect job-group structure (for SPOLIS monthly data)
  has_job_groups <- "job_group" %in% names(base_tbl)
  if (has_job_groups) {
    job_groups   <- base_tbl$job_group
    n_unique_jobs <- max(job_groups)
  }

  # Build result data.table column by column
  # Copy base_tbl so we can progressively add resolved columns (for stable_per)
  base_tbl <- data.table::copy(base_tbl)
  n_cols <- length(spec$columns) * 2L  # upper bound (suffixes expand)
  result_cols <- vector("list", n_cols)
  result_names <- character(n_cols)
  idx <- 0L

  for (cs in spec$columns) {
    # Expand suffixes
    if (!is.null(cs[["suffixes"]])) {
      for (sfx in cs[["suffixes"]]) {
        cs2 <- cs
        cs2$name <- gsub("\\{sfx\\}", sfx, cs$name)
        # Skip if not selected
        if (!is.null(selected_set) && !(cs2$name %in% selected_set)) next
        if (!is.null(cs2$source))
          cs2$source <- gsub("\\{sfx\\}", sfx, cs2$source)
        if (!is.null(cs2$label))
          cs2$label <- gsub("\\{sfx\\}", sfx, cs2$label)
        cs2$suffixes <- NULL

        val <- .resolve_column(cs2, spine, n_rows, codelists, jan1, dec31,
                               computed, params, base_tbl = base_tbl)
        val <- .apply_codelist(val, cs2, codelists)
        idx <- idx + 1L
        result_cols[[idx]] <- val
        result_names[[idx]] <- cs2$name
        data.table::set(base_tbl, j = cs2$name, value = val)
      }
    } else if (!is.null(cs[["suffixes_custom"]])) {
      for (sc in cs[["suffixes_custom"]]) {
        cs2 <- cs
        cs2$name <- gsub("\\{sfx_lower\\}", sc$output_suffix, cs$name)
        # Skip if not selected
        if (!is.null(selected_set) && !(cs2$name %in% selected_set)) next
        if (!is.null(cs2$source)) {
          cs2$source <- gsub("\\{sfx\\}", sc$output_suffix, cs2$source)
          cs2$source <- gsub("\\{sfx_lower\\}", sc$output_suffix, cs2$source)
        }
        cs2$suffixes_custom <- NULL

        val <- .resolve_column(cs2, spine, n_rows, codelists, jan1, dec31,
                               computed, params, base_tbl = base_tbl)
        val <- .apply_codelist(val, cs2, codelists)
        idx <- idx + 1L
        result_cols[[idx]] <- val
        result_names[[idx]] <- cs2$name
        data.table::set(base_tbl, j = cs2$name, value = val)
      }
    } else {
      # Skip if not selected
      if (!is.null(selected_set) && !(cs$name %in% selected_set)) next

      # Job-level columns: generate once per unique job, then expand to rows
      if (has_job_groups && identical(cs$level, "job")) {
        val <- .resolve_column(cs, spine, n_unique_jobs, codelists, jan1,
                               dec31, computed, params, base_tbl = base_tbl)
        val <- .apply_codelist(val, cs, codelists)
        val <- val[job_groups]
      } else {
        val <- .resolve_column(cs, spine, n_rows, codelists, jan1, dec31,
                               computed, params, base_tbl = base_tbl)
        val <- .apply_codelist(val, cs, codelists)
      }
      idx <- idx + 1L
      result_cols[[idx]] <- val
      result_names[[idx]] <- cs$name
      if (length(val) == nrow(base_tbl))
        data.table::set(base_tbl, j = cs$name, value = val)
    }
  }

  # Trim pre-allocated vectors to actual size
  result_cols <- result_cols[seq_len(idx)]
  result_names <- result_names[seq_len(idx)]

  names(result_cols) <- result_names
  dt <- data.table::as.data.table(result_cols)

  # Apply col_select (still needed for tidyselect patterns like starts_with).
  # Let eval_select errors propagate so an invalid selection (e.g. a mistyped
  # column) fails loudly like haven, instead of silently returning all columns.
  if (!is.null(col_q) && !rlang::quo_is_null(col_q)) {
    sel <- names(tidyselect::eval_select(col_q, dt))
    dt <- dt[, sel, with = FALSE]
  }

  dt
}
