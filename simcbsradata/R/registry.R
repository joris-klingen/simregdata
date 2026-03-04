# Dataset registry — generic config loader ----

# Scan inst/config/datasets/*/manifest.yaml, build lookup tables.
# Cached in .sim_cache on first use.

.load_dataset_registry <- function() {
  if (!is.null(.sim_cache$registry)) return(.sim_cache$registry)

  ds_dir <- .datasets_dir()
  if (!nzchar(ds_dir) || !dir.exists(ds_dir)) return(list())

  manifests <- list.files(ds_dir, pattern = "^manifest\\.yaml$",
                          recursive = TRUE, full.names = TRUE)

  registry <- list()  # cbs_name -> list(dataset_id, file_key, entity, ...)
  datasets <- list()  # dataset_id -> full manifest

  for (mf in manifests) {
    m <- yaml::read_yaml(mf)
    ds_id <- m$dataset_id
    datasets[[ds_id]] <- m
    datasets[[ds_id]]$config_dir <- dirname(mf)

    for (fkey in names(m$files)) {
      fi <- m$files[[fkey]]
      registry[[fi$cbs_name]] <- list(
        dataset_id   = ds_id,
        file_key     = fkey,
        entity       = fi$entity,
        columns_file = fi$columns_file,
        cbs_name     = fi$cbs_name
      )
    }
  }

  .sim_cache$registry <- registry
  .sim_cache$datasets <- datasets
  registry
}

# Load codelists for a dataset → same structure as old .M
.load_codelists <- function(dataset_id) {
  cache_key <- paste0("codelists_", dataset_id)
  if (!is.null(.sim_cache[[cache_key]])) return(.sim_cache[[cache_key]])

  ds <- .sim_cache$datasets[[dataset_id]]
  if (is.null(ds)) .load_dataset_registry()
  ds <- .sim_cache$datasets[[dataset_id]]
  if (is.null(ds)) stop("Unknown dataset: ", dataset_id)

  cl_path <- file.path(ds$config_dir, "codelists.yaml")
  if (!file.exists(cl_path)) stop("Codelists not found: ", cl_path)

  raw <- yaml::read_yaml(cl_path)

  # Convert to same format as old .M: list of list(c2i, labels)
  codelists <- lapply(raw, function(entry) {
    # c2i: named int vector; YAML nulls (~) → NA_integer_
    c2i_raw <- entry$c2i
    c2i_names <- names(c2i_raw)
    c2i_vals <- vapply(c2i_raw, function(v) {
      if (is.null(v)) NA_integer_ else as.integer(v)
    }, integer(1L))
    names(c2i_vals) <- c2i_names

    # labels: named int vector
    lab_raw <- entry$labels
    lab_names <- names(lab_raw)
    lab_vals <- vapply(lab_raw, as.integer, integer(1L))
    names(lab_vals) <- lab_names

    list(c2i = c2i_vals, labels = lab_vals)
  })

  .sim_cache[[cache_key]] <- codelists
  codelists
}

# Load column spec for a dataset + file type
.load_column_spec <- function(dataset_id, file_key) {
  cache_key <- paste0("colspec_", dataset_id, "_", file_key)
  if (!is.null(.sim_cache[[cache_key]])) return(.sim_cache[[cache_key]])

  ds <- .sim_cache$datasets[[dataset_id]]
  if (is.null(ds)) .load_dataset_registry()
  ds <- .sim_cache$datasets[[dataset_id]]

  fi <- ds$files[[file_key]]
  if (is.null(fi)) stop("Unknown file type '", file_key, "' in dataset '", dataset_id, "'")

  spec_path <- file.path(ds$config_dir, "columns", fi$columns_file)
  if (!file.exists(spec_path)) stop("Column spec not found: ", spec_path)

  spec <- yaml::read_yaml(spec_path)
  .sim_cache[[cache_key]] <- spec
  spec
}

# Parse a file name against the full registry (not just Woonbase)
.parse_file_registry <- function(file) {
  base <- tools::file_path_sans_ext(basename(file))

  # Try two CBS filename patterns:
  #   Standard:  {Name}{YYYY}V{N}     (e.g. WoonbaseSleutelbestand2023V1)
  #   TAB:       {Name}{YYYY}TABV{N}  (e.g. RDWNPACT2023TABV1)
  dataset_name <- NULL
  file_year    <- NULL

  m <- regmatches(base, regexec("^(.+?)(\\d{4})V\\d+$", base))[[1L]]
  if (length(m) == 3L) {
    dataset_name <- m[2L]
    file_year    <- as.integer(m[3L])
  } else {
    m2 <- regmatches(base, regexec("^(.+?)(\\d{4})TABV\\d+$", base))[[1L]]
    if (length(m2) == 3L) {
      dataset_name <- m2[2L]
      file_year    <- as.integer(m2[3L])
    }
  }

  if (is.null(dataset_name)) {
    dataset_name <- base
    file_year    <- NULL
  }

  registry <- .load_dataset_registry()
  info <- registry[[dataset_name]]
  if (!is.null(info)) {
    return(list(
      dataset_id = info$dataset_id,
      file_key   = info$file_key,
      entity     = info$entity,
      year       = file_year
    ))
  }
  NULL
}

# Get entity unit from registry
.registry_unit <- function(dataset_id, file_key) {
  ds <- .sim_cache$datasets[[dataset_id]]
  if (is.null(ds)) return("person")
  fi <- ds$files[[file_key]]
  if (is.null(fi)) return("person")
  fi$entity
}
