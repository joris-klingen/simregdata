# Dataset scaffolding from CBS PDF documentation ----

#' Scaffold a new dataset from CBS PDF documentation
#'
#' Generates skeleton YAML config files (manifest, codelists, column specs)
#' for a new CBS dataset. Column definitions are extracted from PDF text files
#' via [cbs_parse_pdf_columns()]. Character columns get `random_categorical`
#' stubs; numeric columns get `random_numeric` stubs. Users then edit the
#' generated YAML to refine distributions and codelists.
#'
#' @param dataset_id Short identifier for the dataset (e.g. `"voertuigen"`).
#' @param label Human-readable label (e.g. `"CBS Voertuigen"`).
#' @param files Named list of file definitions. Each element should be a list
#'   with:
#'   \describe{
#'     \item{cbs_name}{CBS CamelCase dataset name}
#'     \item{entity}{Entity type: `"person"`, `"household"`, or `"object"`}
#'     \item{txt_path}{Path to extracted PDF text file (optional)}
#'   }
#' @param spine_builder Spine builder type: `"woonbase"` (reads directly from
#'   the shared population spine) or `"generic"` (samples persons from the
#'   shared spine). Default `"generic"`.
#' @param output_dir Base output directory. Defaults to
#'   `inst/config/datasets/{dataset_id}` in the package source.
#' @return Invisibly, the output directory path.
#' @export
cbs_scaffold_dataset <- function(dataset_id,
                                 label = dataset_id,
                                 files = list(),
                                 spine_builder = "generic",
                                 output_dir = NULL) {

  if (is.null(output_dir)) {
    pkg_root <- system.file(package = "simcbsradata")
    if (nzchar(pkg_root)) {
      output_dir <- file.path(pkg_root, "config", "datasets", dataset_id)
    } else {
      output_dir <- file.path("inst", "config", "datasets", dataset_id)
    }
  }

  dir.create(file.path(output_dir, "columns"), recursive = TRUE, showWarnings = FALSE)

  # Build manifest
  manifest <- list(
    dataset_id = dataset_id,
    label = label,
    spine_builder = spine_builder,
    entities = list(
      person = list(id_col = "RINPERSOON", id_width = 9L, id_prefix_col = "RINPERSOONS")
    ),
    files = list()
  )

  for (fkey in names(files)) {
    fi <- files[[fkey]]
    col_file <- paste0(fkey, ".yaml")
    entity <- if (!is.null(fi$entity)) fi$entity else "person"

    manifest$files[[fkey]] <- list(
      cbs_name = fi$cbs_name,
      entity = entity,
      columns_file = col_file
    )

    # Generate column spec from PDF text
    columns <- list()
    if (!is.null(fi$txt_path) && file.exists(fi$txt_path)) {
      pdf_cols <- cbs_parse_pdf_columns(fi$txt_path)
      columns <- .scaffold_columns(pdf_cols, entity)
    } else {
      columns <- list(
        list(name = "RINPERSOON", source = "spine.pers.RINPERSOON"),
        list(name = "RINPERSOONS", source = "spine.pers.RINPERSOONS")
      )
    }

    spine_tbl <- switch(entity,
      person = "pers", household = "hh", object = "obj", "pers")

    col_spec <- list(entity = entity, spine_table = spine_tbl, columns = columns)
    yaml::write_yaml(col_spec, file.path(output_dir, "columns", col_file))
    cat(sprintf("  Written columns/%s (%d columns)\n", col_file, length(columns)))
  }

  yaml::write_yaml(manifest, file.path(output_dir, "manifest.yaml"))
  cat(sprintf("  Written manifest.yaml\n"))

  yaml::write_yaml(list(), file.path(output_dir, "codelists.yaml"))
  cat(sprintf("  Written codelists.yaml (empty -- add codelists manually)\n"))

  cat(sprintf("\nScaffolded dataset '%s' in:\n  %s\n", dataset_id, output_dir))
  cat("Next steps:\n")
  cat("  1. Edit columns/*.yaml -- set correct sources, distributions, codelists\n")
  cat("  2. Fill in codelists.yaml with value label mappings\n")
  cat("  3. Reload package or restart R to pick up the new dataset\n")

  invisible(output_dir)
}


# Generate smart column stubs from parsed PDF column definitions
.scaffold_columns <- function(pdf_cols, entity) {
  columns <- list()
  known_ids <- c("RINPERSOON", "RINPERSOONS", "HUISHOUDNR",
                 "RINOBJECTNUMMER", "SOORTOBJECTNUMMER", "RINKENTEKEN", "PandID")
  spine_tbl <- switch(entity,
    person = "pers", household = "hh", object = "obj", "pers")

  for (i in seq_len(nrow(pdf_cols))) {
    naam <- pdf_cols$naam[i]
    fmt  <- pdf_cols$formaat[i]
    col  <- list(name = naam)

    # Known ID columns -> source from spine
    if (naam %in% known_ids) {
      col$source <- paste0("spine.", spine_tbl, ".", naam)
    } else if (grepl("^A", fmt)) {
      # Character format -> random_categorical stub
      width <- as.integer(sub("^A", "", fmt))
      if (width == 1L) {
        col$random_categorical <- list(
          values = list("0", "1"),
          probs  = list(0.5, 0.5))
      } else {
        col$random_categorical <- list(
          values = list("TODO"),
          probs  = list(1.0))
      }
      col$`_comment` <- paste0("TODO: set values/probs (format ", fmt, ")")
    } else if (grepl("^F", fmt)) {
      # Numeric format -> random_numeric stub
      width <- as.integer(sub("^F", "", fmt))
      col$random_numeric <- list(
        distribution = "uniform",
        min = 0,
        max = 10^min(width, 6L),
        round = 0L)
      col$`_comment` <- paste0("TODO: set realistic range (format ", fmt, ")")
    } else {
      col$source <- "TODO"
    }

    columns[[length(columns) + 1L]] <- col
  }
  columns
}
