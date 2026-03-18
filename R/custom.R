# User-defined custom datasets ----

# Key mapping: user-friendly key name → internal spec
.CUSTOM_KEYS <- list(
  rinpersoon = list(
    entity = "person", spine_table = "pers",
    key_columns = c("RINPERSOONS", "RINPERSOON"),
    columns = list(
      list(name = "RINPERSOONS", source = "spine.pers.RINPERSOONS"),
      list(name = "RINPERSOON",  source = "spine.pers.RINPERSOON")
    )
  ),
  huishoudnr = list(
    entity = "household", spine_table = "hh",
    key_columns = c("HUISHOUDNR"),
    columns = list(
      list(name = "HUISHOUDNR", source = "spine.hh.HUISHOUDNR")
    )
  ),
  rinobjectnummer = list(
    entity = "object", spine_table = "obj",
    key_columns = c("SOORTOBJECTNUMMER", "RINOBJECTNUMMER"),
    columns = list(
      list(name = "SOORTOBJECTNUMMER", source = "spine.obj.SOORTOBJECTNUMMER"),
      list(name = "RINOBJECTNUMMER",   source = "spine.obj.RINOBJECTNUMMER")
    )
  ),
  rinkenteken = list(
    entity = "person", spine_table = "pers",
    key_columns = c("RINPERSOONS", "RINPERSOON", "RINKENTEKEN"),
    columns = list(
      list(name = "RINPERSOONS", source = "spine.pers.RINPERSOONS"),
      list(name = "RINPERSOON",  source = "spine.pers.RINPERSOON"),
      list(name = "RINKENTEKEN", source = "spine.pers.RINKENTEKEN")
    )
  )
)


#' Create a custom dataset template YAML
#'
#' Writes a commented template file that you can edit to define a custom
#' dataset.  After editing, register it with [sim_register()].
#'
#' @param path  File path for the template (e.g. `"my_survey.yaml"`).
#' @return Invisibly, `path`.
#' @export
sim_create_custom <- function(path) {
  template <- paste0(
    "# Custom dataset definition for simcbsradata\n",
    "# Edit this file, then register with: sim_register(\"", path, "\")\n",
    "#\n",
    "# After registering:\n",
    "#   sim_init(\"my_dataset\", year = 2023, n = 1000)\n",
    "#   dt <- read_sav(\"my_dataset2023V1\")\n",
    "\n",
    "name: my_dataset\n",
    "label: My Custom Dataset\n",
    "\n",
    "# Key that links to the shared spine.\n",
    "# Options: rinpersoon, huishoudnr, rinobjectnummer, rinkenteken\n",
    "key: rinpersoon\n",
    "\n",
    "columns:\n",
    "  # Categorical column with labels\n",
    "  - name: category\n",
    "    type: categorical\n",
    "    values: [1, 2, 3]\n",
    "    labels: [Low, Medium, High]\n",
    "    probs:  [0.30, 0.45, 0.25]\n",
    "\n",
    "  # Numeric column (normal distribution)\n",
    "  - name: score\n",
    "    type: numeric\n",
    "    mean: 50\n",
    "    sd: 15\n",
    "    min: 0\n",
    "    max: 100\n",
    "\n",
    "  # Random identifier\n",
    "  - name: record_id\n",
    "    type: id\n",
    "    width: 8\n",
    "\n",
    "  # Constant value\n",
    "  - name: version\n",
    "    type: constant\n",
    "    value: \"1.0\"\n"
  )
  writeLines(template, path)
  message("Template written to: ", path)
  invisible(path)
}


#' Register a custom dataset from a simple YAML file
#'
#' Reads a single YAML file defining a custom dataset and registers it so
#' that [sim_init()], [read_sav()], [sim_catalog()], and [sim_population()]
#' can use it.  The dataset links to the shared population spine via a key
#' column (RINPERSOON, HUISHOUDNR, RINOBJECTNUMMER, or RINKENTEKEN).
#'
#' Calling `sim_register()` again with the same name silently overwrites
#' the previous registration.  Note that [sim_reset()] clears all custom
#' registrations.
#'
#' @param path  Path to the custom dataset YAML file.
#' @return Invisibly, the dataset name.
#' @export
sim_register <- function(path) {
  if (!file.exists(path)) stop("File not found: ", path)

  raw <- yaml::read_yaml(path)

  # Validate required fields
  name <- raw$name
  if (is.null(name) || !nzchar(name))
    stop("Custom YAML must have a 'name' field")
  key <- tolower(raw$key %||% "rinpersoon")
  if (!key %in% names(.CUSTOM_KEYS))
    stop("Unknown key: '", key, "'. Must be one of: ",
         paste(names(.CUSTOM_KEYS), collapse = ", "))

  label <- raw$label %||% name
  user_cols <- raw$columns
  if (is.null(user_cols) || length(user_cols) == 0L)
    stop("Custom YAML must have at least one column in 'columns'")

  key_spec <- .CUSTOM_KEYS[[key]]

  # Ensure the dataset registry is loaded (so we don't overwrite it later)
  .load_dataset_registry()

  # Build internal column spec
  col_specs <- key_spec$columns  # start with key columns
  codelists <- list()

  for (uc in user_cols) {
    uc_name <- uc$name
    if (is.null(uc_name)) stop("Each column must have a 'name' field")
    uc_type <- uc$type %||% "categorical"

    cs <- list(name = uc_name)

    if (identical(uc_type, "categorical")) {
      vals <- as.character(uc$values)
      probs <- if (!is.null(uc$probs)) as.numeric(uc$probs) else NULL
      cs$random_categorical <- list(values = vals, probs = probs)

      # Build codelist if labels are provided
      if (!is.null(uc$labels)) {
        labs <- as.character(uc$labels)
        int_codes <- seq_along(vals)
        c2i <- stats::setNames(int_codes, vals)
        lab_map <- stats::setNames(int_codes, labs)
        codelists[[uc_name]] <- list(c2i = c2i, labels = lab_map)
        cs$codelist <- uc_name
      }

    } else if (identical(uc_type, "numeric")) {
      cs$random_numeric <- list(
        distribution = "normal",
        mean = as.numeric(uc$mean %||% 0),
        sd   = as.numeric(uc$sd %||% 1)
      )
      if (!is.null(uc$min)) cs$random_numeric$min <- as.numeric(uc$min)
      if (!is.null(uc$max)) cs$random_numeric$max <- as.numeric(uc$max)
      if (!is.null(uc$round)) {
        cs$random_numeric$round <- as.integer(uc$round)
      } else {
        cs$random_numeric$round <- 0L
      }

    } else if (identical(uc_type, "id")) {
      cs$random_id <- list(width = as.integer(uc$width %||% 8L))

    } else if (identical(uc_type, "constant")) {
      cs$value <- as.character(uc$value %||% "")

    } else {
      stop("Unknown column type: '", uc_type, "' for column '", uc_name, "'")
    }

    col_specs <- c(col_specs, list(cs))
  }

  # Build internal manifest
  file_key <- name
  cbs_name <- name

  manifest <- list(
    dataset_id = name,
    label = label,
    spine_builder = "generic",
    entities = list(
      person = list(id_col = "RINPERSOON", id_width = 9L,
                    id_prefix_col = "RINPERSOONS")
    ),
    files = stats::setNames(list(list(
      cbs_name = cbs_name,
      entity = key_spec$entity,
      columns_file = paste0(file_key, ".yaml"),
      key_columns = key_spec$key_columns
    )), file_key),
    custom = TRUE
  )

  # Build internal column spec structure
  col_spec_internal <- list(
    entity = key_spec$entity,
    spine_table = key_spec$spine_table,
    columns = col_specs
  )

  # Inject into cache
  .sim_cache$datasets[[name]] <- manifest
  .sim_cache$registry[[cbs_name]] <- list(
    dataset_id = name,
    file_key = file_key,
    entity = key_spec$entity,
    columns_file = paste0(file_key, ".yaml"),
    cbs_name = cbs_name
  )
  .sim_cache[[paste0("colspec_", name, "_", file_key)]] <- col_spec_internal
  .sim_cache[[paste0("codelists_", name)]] <- codelists

  message(sprintf("Registered custom dataset: %s (%d columns, key: %s)",
                  name, length(user_cols), key))
  invisible(name)
}
