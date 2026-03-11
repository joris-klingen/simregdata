# Scan R scripts to detect which CBS columns are used ----

#' Scan R scripts for CBS column usage
#'
#' Parses R scripts and extracts column names from `read_sav()` calls that
#' use `col_select`.  Returns a named list suitable for passing to
#' [sim_export()]'s `col_select` parameter.
#'
#' @param paths  Character vector of file or directory paths.  Directories
#'   are searched recursively for `.R` files.
#' @return A named list of character vectors, keyed by uppercase CBS file
#'   name (e.g. `list(SPOLISBUS = c("RINPERSOON", "IKVID", ...))`.
#' @export
#' @examples
#' \dontrun{
#' cols <- sim_scan_columns("my_project/scripts/")
#' sim_export("output", dataset = "spolis", col_select = cols)
#' }
sim_scan_columns <- function(paths) {
  # Collect .R files
  r_files <- character()
  for (p in paths) {
    if (dir.exists(p)) {
      r_files <- c(r_files,
        list.files(p, pattern = "\\.[Rr]$", recursive = TRUE, full.names = TRUE))
    } else if (file.exists(p)) {
      r_files <- c(r_files, p)
    }
  }
  if (length(r_files) == 0L) {
    message("No R files found in: ", paste(paths, collapse = ", "))
    return(list())
  }

  result <- list()

  for (rf in r_files) {
    exprs <- tryCatch(parse(rf), error = function(e) NULL)
    if (is.null(exprs)) next
    .walk_exprs(exprs, result_env = environment())
  }

  # Deduplicate
  lapply(result, unique)
}


# Recursively walk parsed expressions looking for read_sav() calls
.walk_exprs <- function(expr, result_env) {
  if (is.call(expr)) {
    fn_name <- as.character(expr[[1L]])
    # Match read_sav() or simcbsradata::read_sav()
    is_read_sav <- identical(fn_name, "read_sav") ||
      (length(fn_name) == 3L && fn_name[3L] == "read_sav")

    if (is_read_sav) {
      .extract_read_sav(expr, result_env)
    }

    # Recurse into all sub-expressions
    for (i in seq_along(expr)) {
      .walk_exprs(expr[[i]], result_env)
    }
  } else if (is.recursive(expr)) {
    for (i in seq_along(expr)) {
      .walk_exprs(expr[[i]], result_env)
    }
  }
}


# Extract file name and col_select from a read_sav() call
.extract_read_sav <- function(call_expr, result_env) {
  # Get the file argument (first positional or named 'file')
  file_arg <- NULL
  if (length(call_expr) >= 2L) {
    arg1 <- call_expr[[2L]]
    if (is.null(names(call_expr)) || names(call_expr)[2L] == "" ||
        identical(names(call_expr)[2L], "file")) {
      # Try direct eval first (works for string literals)
      file_arg <- tryCatch(eval(arg1), error = function(e) NULL)
      # If that fails, try extracting from sprintf/paste0 template
      if (is.null(file_arg) || !is.character(file_arg)) {
        file_arg <- .extract_template_string(arg1)
      }
    }
  }

  if (is.null(file_arg) || !is.character(file_arg)) return(NULL)

  # Extract CBS name from the file string
  cbs_name <- .extract_cbs_name(file_arg)
  if (is.null(cbs_name)) return(NULL)

  # Get col_select argument
  col_sel <- NULL
  arg_names <- names(call_expr)
  if (!is.null(arg_names)) {
    cs_idx <- match("col_select", arg_names)
    if (!is.na(cs_idx)) {
      cs_expr <- call_expr[[cs_idx]]
      col_sel <- tryCatch(eval(cs_expr), error = function(e) NULL)
    }
  }

  if (!is.null(col_sel) && is.character(col_sel)) {
    result <- get("result", envir = result_env)
    result[[cbs_name]] <- unique(c(result[[cbs_name]], col_sel))
    assign("result", result, envir = result_env)
  }
}


# Extract the format string from sprintf() or paste0() calls
# e.g. sprintf("RDWNPACT%dTABV1", yr) -> "RDWNPACT%dTABV1"
.extract_template_string <- function(expr) {
  if (!is.call(expr)) return(NULL)
  fn <- as.character(expr[[1L]])
  if (identical(fn, "sprintf") && length(expr) >= 2L) {
    # First arg to sprintf is the format string
    fmt <- tryCatch(eval(expr[[2L]]), error = function(e) NULL)
    if (is.character(fmt)) return(fmt)
  }
  if (identical(fn, "paste0") && length(expr) >= 2L) {
    # Try to eval — often fails, but try
    tryCatch(eval(expr), error = function(e) NULL)
  } else {
    NULL
  }
}


# Extract CBS name from a file string like "SPOLISBUS2023V1" or
# "RDWNPACT%dTABV1" (sprintf template)
.extract_cbs_name <- function(file_str) {
  # Standard pattern: Name{YYYY}V{N}
  m <- regmatches(file_str, regexec("^(.+?)(\\d{4})V\\d+$", file_str))[[1L]]
  if (length(m) == 3L) return(toupper(m[2L]))

  # TAB pattern: Name{YYYY}TABV{N}
  m2 <- regmatches(file_str, regexec("^(.+?)(\\d{4})TABV\\d+$", file_str))[[1L]]
  if (length(m2) == 3L) return(toupper(m2[2L]))

  # sprintf template: Name%dV1 or Name%dTABV1
  m3 <- regmatches(file_str, regexec("^(.+?)%d(TAB)?V\\d+$", file_str))[[1L]]
  if (length(m3) >= 2L) return(toupper(m3[2L]))

  # sprintf template without TAB: Name%dV1
  m4 <- regmatches(file_str, regexec("^(.+?)%dV\\d+$", file_str))[[1L]]
  if (length(m4) >= 2L) return(toupper(m4[2L]))

  NULL
}
