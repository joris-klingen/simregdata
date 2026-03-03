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
  params <- woonbase_cbs_params(year)
  n_pers <- if (is.null(n)) params$n_persons else as.integer(n)
  .wb$spine  <- .wb_build_spine(n_pers, params, seed, year)
  .wb$params <- params
  .wb$year   <- year
  .wb$seed   <- seed
  invisible(NULL)
}

#' Clear the cached spine
#'
#' Forces a rebuild on the next [read_sav()] call.
#'
#' @return Invisibly `NULL`.
#' @export
woonbase_reset <- function() { .wb$spine <- NULL; invisible(NULL) }

#' Print a catalog of available synthetic Woonbase files
#'
#' Shows the 7 CBS dataset names, their observation unit, column count, and
#' the exact file name to pass to [read_sav()].
#'
#' @param year  Year to display in example file names (default 2023).
#' @return Invisibly `NULL`.
#' @export
woonbase_catalog <- function(year = 2023L) {

  units <- c(sleutel = "person", kenmerken_pers = "person",
             kenmerken_hh = "household", kenmerken_obj = "object",
             populatie_pers = "person", populatie_hh = "household",
             populatie_obj = "object")

  ncols <- c(sleutel = 16L, kenmerken_pers = 20L, kenmerken_hh = 14L,
             kenmerken_obj = 22L, populatie_pers = 40L, populatie_hh = 34L,
             populatie_obj = 35L)

  cat("\n")
  cat("  CBS Woonbase \u2014 synthetic file catalog\n")
  cat("  ======================================\n\n")
  cat(sprintf("  %-30s  %-10s  %s  %s\n",
              "Dataset name", "Unit", "Cols", "read_sav() file argument"))
  cat(sprintf("  %-30s  %-10s  %s  %s\n",
              "------------------------------", "----------", "----",
              "----------------------------------------"))

  for (key in names(.WB_FILES)) {
    dsname   <- .WB_FILES[[key]]
    filename <- sprintf("%s%dV1", dsname, year)
    cat(sprintf("  %-30s  %-10s  %3d   %s\n",
                dsname, units[[key]], ncols[[key]], filename))
  }

  cat(sprintf("\n  Full VM path example:\n"))
  cat(sprintf("    G:/BOUWENENWONEN/%s/%s%dV1.sav\n",
              toupper(.WB_FILES[["populatie_pers"]]),
              .WB_FILES[["populatie_pers"]], year))
  cat("\n")
  invisible(NULL)
}


#' Read a CBS Woonbase file (synthetic) or any other .sav file (via haven)
#'
#' Drop-in replacement for [haven::read_sav()] that intercepts CBS Woonbase
#' file names and returns synthetic microdata.  For all other file paths,
#' falls through to `haven::read_sav()`.
#'
#' Supports the same arguments as `haven::read_sav()`: `n_max`, `skip`,
#' `col_select` (tidyselect or character vector).  Extra arguments (`year`,
#' `seed`) control the simulation when no spine has been pre-built with
#' [woonbase_init()].
#'
#' @param file  File name or path.  For Woonbase files, use the exact CBS
#'   CamelCase name (e.g. `"WoonbasePopulatiePersonen2023V1"`).
#' @param encoding  Passed to `haven::read_sav()` (non-Woonbase files only).
#' @param user_na   Passed to `haven::read_sav()` (non-Woonbase files only).
#' @param col_select  Column selection (tidyselect expressions or character
#'   vector).
#' @param skip  Number of rows to skip (default 0).
#' @param n_max  Maximum number of rows to return (default `Inf`).
#' @param .name_repair  Passed to `haven::read_sav()` (non-Woonbase files
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
  parsed <- .wb_parse_file(file)

  # Fall through to haven for non-Woonbase files
  if (is.null(parsed)) {
    return(haven::read_sav(file, encoding=encoding, user_na=user_na,
                           col_select=!!col_q, skip=skip, n_max=n_max,
                           .name_repair=.name_repair, ...))
  }

  file_type <- parsed$type
  # Year inferred from filename (e.g. 2023 from "...2023V1") takes precedence
  if (!is.null(parsed$year)) year <- parsed$year

  # Auto-initialise spine if needed
  if (is.null(.wb$spine) || (!is.null(.wb$year) && .wb$year != year)) {
    if (is.infinite(n_max)) {
      message("n_max = Inf: fetching CBS population count for ", year, " and generating full spine.")
      woonbase_init(year=year, n=NULL, seed=seed)
    } else {
      unit   <- .wb_unit(file_type)
      n_pers <- switch(unit,
        person    = ceiling(n_max * 1.05),
        household = ceiling(n_max * 2.4),
        object    = ceiling(n_max * 2.4))
      message(sprintf("Auto-initialising spine with %s persons for '%s'. Call woonbase_init() explicitly for reproducible cross-file joins.",
                      format(n_pers, big.mark=","), file_type))
      woonbase_init(year=year, n=n_pers, seed=seed)
    }
  }

  # Assemble the requested file (col_select applied inside)
  dt <- .wb_assemble(file_type, .wb$spine, col_q = col_q)

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
