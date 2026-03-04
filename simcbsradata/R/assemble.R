# Generic data-driven assembly engine ----

# Resolve a single column value from spec + spine
.resolve_column <- function(col_spec, spine, n_rows, codelists, jan1, dec31, computed) {

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

  # Random categorical
  if (!is.null(col_spec$random_categorical)) {
    rc <- col_spec$random_categorical
    vals <- as.character(rc$values)
    probs <- if (!is.null(rc$probs)) as.numeric(rc$probs) else NULL
    return(.rcat(n_rows, vals, probs))
  }

  # Random ID (fixed-width random identifier string)
  if (!is.null(col_spec$random_id)) {
    w <- as.integer(col_spec$random_id$width)
    return(.rand_id(n_rows, w))
  }

  # Random numeric
  if (!is.null(col_spec$random_numeric)) {
    rn <- col_spec$random_numeric
    if (identical(rn$distribution, "uniform")) {
      vals <- runif(n_rows, rn$min, rn$max)
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


# Main generic assembly: builds a data.table from YAML column spec
.assemble_generic <- function(dataset_id, file_key, spine, col_q = NULL) {

  spec <- .load_column_spec(dataset_id, file_key)
  codelists <- .load_codelists(dataset_id)

  # Determine which spine table to use + row count
  tbl_name <- spec$spine_table
  base_tbl <- spine[[tbl_name]]
  if (is.null(base_tbl)) stop("Spine table '", tbl_name, "' not found")
  n_rows <- nrow(base_tbl)

  jan1  <- .yyyymmdd(spine$jan1)
  dec31 <- .yyyymmdd(spine$dec31)

  # Pre-compute derived columns if specified
  computed <- list()
  if (!is.null(spec$pre_compute)) {
    for (pc in spec$pre_compute) {
      src_val <- .resolve_column(pc, spine, n_rows, codelists, jan1, dec31, computed)
      if (identical(pc$transform, "persklasse")) {
        computed[[pc$name]] <- .compute_persklasse(as.integer(src_val))
      } else {
        computed[[pc$name]] <- src_val
      }
    }
  }

  # Build result data.table column by column
  result_cols <- list()
  result_names <- character()

  for (cs in spec$columns) {
    # Expand suffixes
    if (!is.null(cs$suffixes)) {
      for (sfx in cs$suffixes) {
        # Create a copy of the spec with suffix applied
        cs2 <- cs
        cs2$name <- gsub("\\{sfx\\}", sfx, cs$name)
        if (!is.null(cs2$source)) {
          cs2$source <- gsub("\\{sfx\\}", sfx, cs2$source)
        }
        if (isTRUE(cs2$indicator_label) && !is.null(cs2$label)) {
          cs2$label <- gsub("\\{sfx\\}", sfx, cs2$label)
        }
        cs2$suffixes <- NULL

        val <- .resolve_column(cs2, spine, n_rows, codelists, jan1, dec31, computed)
        val <- .apply_codelist(val, cs2, codelists)
        result_cols[[length(result_cols) + 1L]] <- val
        result_names <- c(result_names, cs2$name)
      }
    } else if (!is.null(cs$suffixes_custom)) {
      # Custom suffix list with explicit output_suffix values
      for (sc in cs$suffixes_custom) {
        cs2 <- cs
        cs2$name <- gsub("\\{sfx_lower\\}", sc$output_suffix, cs$name)
        if (!is.null(cs2$source)) {
          cs2$source <- gsub("\\{sfx\\}", sc$output_suffix, cs2$source)
          cs2$source <- gsub("\\{sfx_lower\\}", sc$output_suffix, cs2$source)
        }
        cs2$suffixes_custom <- NULL

        val <- .resolve_column(cs2, spine, n_rows, codelists, jan1, dec31, computed)
        val <- .apply_codelist(val, cs2, codelists)
        result_cols[[length(result_cols) + 1L]] <- val
        result_names <- c(result_names, cs2$name)
      }
    } else {
      val <- .resolve_column(cs, spine, n_rows, codelists, jan1, dec31, computed)
      val <- .apply_codelist(val, cs, codelists)
      result_cols[[length(result_cols) + 1L]] <- val
      result_names <- c(result_names, cs$name)
    }
  }

  names(result_cols) <- result_names
  dt <- data.table::as.data.table(result_cols)

  # Apply col_select
  if (!is.null(col_q) && !rlang::quo_is_null(col_q)) {
    sel <- tryCatch(
      names(tidyselect::eval_select(col_q, dt)),
      error = function(e) {
        cs <- eval(rlang::quo_get_expr(col_q))
        intersect(as.character(cs), names(dt))
      })
    dt <- dt[, sel, with = FALSE]
  }

  dt
}
