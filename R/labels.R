# Apply a codelist mapping to a character vector -> haven::labelled integer
# Stores the reverse c2i mapping (integer -> CBS code) as the "cbs_codes" attribute
.lbl <- function(x, mapping, var_label = NULL) {
  iv <- unname(mapping$c2i[as.character(x)])
  out <- haven::labelled(iv, labels = mapping$labels, label = var_label)
  # Reverse c2i: integer -> CBS character code
  i2c <- stats::setNames(names(mapping$c2i), as.character(mapping$c2i))
  attr(out, "cbs_codes") <- i2c
  out
}

#' Extract CBS character codes from a haven-labelled column
#'
#' Converts a haven-labelled integer vector back to the original CBS character
#' codes (e.g. `"1"`, `"A"`, `"B"` for BRANDSTCODECORVRTG).  The reverse
#' mapping is stored as the `"cbs_codes"` attribute by [read_sav()] /
#' [sim_init()].
#'
#' @param x  A haven-labelled vector (as produced by `read_sav()`).
#' @return A character vector of CBS codes.
#' @export
cbs_code <- function(x) {
  i2c <- attr(x, "cbs_codes")
  if (is.null(i2c)) {
    warning("No cbs_codes attribute found; returning as.character()")
    return(as.character(x))
  }
  unname(i2c[as.character(as.integer(x))])
}

# Label column in-place only if it is still present in dt (no-op otherwise)
.lbl_if <- function(dt, col, mapping, var_label = NULL) {
  if (col %in% names(dt))
    data.table::set(dt, j = col, value = .lbl(dt[[col]], mapping, var_label))
  invisible(dt)
}
