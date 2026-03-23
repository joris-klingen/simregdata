# Generic data-driven assembly engine ----

# Resolve a single column value from spec + spine
.resolve_column <- function(col_spec, spine, n_rows, codelists, jan1, dec31,
                            computed, params = NULL) {

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
  if (is.null(col_spec$codelist)) return(val)
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
      # Case-insensitive fallback: extract the character vector from the quo
      # environment (handles all_of(file_cols) where file_cols has wrong case)
      requested <- tryCatch({
        env <- rlang::quo_get_env(col_q)
        if (exists("file_cols", envir = env, inherits = TRUE)) {
          get("file_cols", envir = env, inherits = TRUE)
        } else {
          as.character(eval(rlang::quo_get_expr(col_q), env))
        }
      }, error = function(e2) NULL)
      if (!is.null(requested)) {
        all_lower <- tolower(all_names)
        matched <- all_names[all_lower %in% tolower(requested)]
        if (length(matched) > 0L) return(matched)
      }
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

  base_tbl <- spine[[tbl_name]]
  if (is.null(base_tbl)) stop("Spine table '", tbl_name, "' not found")
  n_rows <- nrow(base_tbl)

  jan1  <- .yyyymmdd(spine$jan1)
  dec31 <- .yyyymmdd(spine$dec31)

  # Load dataset params (year-specific calibrated distributions)
  params_key <- paste0("params_", dataset_id)
  params_yr_key <- paste0("params_year_", dataset_id)
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
        if (isTRUE(cs2$indicator_label) && !is.null(cs2$label))
          cs2$label <- gsub("\\{sfx\\}", sfx, cs2$label)
        cs2$suffixes <- NULL

        val <- .resolve_column(cs2, spine, n_rows, codelists, jan1, dec31,
                               computed, params)
        val <- .apply_codelist(val, cs2, codelists)
        idx <- idx + 1L
        result_cols[[idx]] <- val
        result_names[[idx]] <- cs2$name
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
                               computed, params)
        val <- .apply_codelist(val, cs2, codelists)
        idx <- idx + 1L
        result_cols[[idx]] <- val
        result_names[[idx]] <- cs2$name
      }
    } else {
      # Skip if not selected
      if (!is.null(selected_set) && !(cs$name %in% selected_set)) next

      # Job-level columns: generate once per unique job, then expand to rows
      if (has_job_groups && identical(cs$level, "job")) {
        val <- .resolve_column(cs, spine, n_unique_jobs, codelists, jan1,
                               dec31, computed, params)
        val <- .apply_codelist(val, cs, codelists)
        val <- val[job_groups]
      } else {
        val <- .resolve_column(cs, spine, n_rows, codelists, jan1, dec31,
                               computed, params)
        val <- .apply_codelist(val, cs, codelists)
      }
      idx <- idx + 1L
      result_cols[[idx]] <- val
      result_names[[idx]] <- cs$name
    }
  }

  # Trim pre-allocated vectors to actual size
  result_cols <- result_cols[seq_len(idx)]
  result_names <- result_names[seq_len(idx)]

  names(result_cols) <- result_names
  dt <- data.table::as.data.table(result_cols)

  # Apply col_select (still needed for tidyselect patterns like starts_with)
  if (!is.null(col_q) && !rlang::quo_is_null(col_q)) {
    sel <- tryCatch(
      names(tidyselect::eval_select(col_q, dt)),
      error = function(e) {
        requested <- tryCatch({
          env <- rlang::quo_get_env(col_q)
          if (exists("file_cols", envir = env, inherits = FALSE)) {
            get("file_cols", envir = env, inherits = FALSE)
          } else {
            as.character(eval(rlang::quo_get_expr(col_q), env))
          }
        }, error = function(e2) character(0L))
        # Case-insensitive match against assembled columns
        dt_lower <- tolower(names(dt))
        names(dt)[dt_lower %in% tolower(requested)]
      })
    if (length(sel) > 0L) dt <- dt[, sel, with = FALSE]
  }

  dt
}
