# Apply a codelist mapping to a character vector -> haven::labelled integer
.lbl <- function(x, mapping, var_label = NULL) {
  iv <- unname(mapping$c2i[as.character(x)])
  haven::labelled(iv, labels = mapping$labels, label = var_label)
}

# Label column in-place only if it is still present in dt (no-op otherwise)
.lbl_if <- function(dt, col, mapping, var_label = NULL) {
  if (col %in% names(dt))
    data.table::set(dt, j = col, value = .lbl(dt[[col]], mapping, var_label))
  invisible(dt)
}
