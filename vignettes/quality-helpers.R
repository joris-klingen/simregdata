# Shared helpers for the quality-* vignettes: StatLine access and figures.
# Sourced from each vignette's hidden setup chunk.

library(data.table)
library(haven)
library(ggplot2)
library(ggcpb)
library(simregdata)  # after haven, so read_sav() is the simulator's

# ggcpb's open fallback font (Source Sans 3) instead of the Rijksoverheid font
options(cbsodataR.base_url = "https://opendata.cbs.nl",
        ggcpb.font_path = character(0), ggcpb.font_warning = FALSE)
cpb_register_fonts(enable_showtext = FALSE)

# A StatLine table with dimension labels added and codes trimmed, or NULL
# when StatLine cannot be reached (after a few tries)
statline <- function(id, ..., tries = 3L) {
  for (i in seq_len(tries)) {
    dt <- tryCatch(
      suppressWarnings(as.data.table(cbsodataR::cbs_add_label_columns(
        cbsodataR::cbs_get_data(id, ...)))),
      error = function(e) NULL)
    if (!is.null(dt)) break
  }
  if (is.null(dt)) return(NULL)
  for (j in names(dt)) {
    if (is.factor(dt[[j]]) || is.character(dt[[j]])) {
      set(dt, j = j, value = trimws(as.character(dt[[j]])))
    }
  }
  dt
}

# first measure column whose name matches `pattern`
measure <- function(dt, pattern) {
  col <- grep(pattern, names(dt), value = TRUE)[1]
  if (is.na(col)) stop("no column matching ", pattern)
  as.numeric(dt[[col]])
}

period <- function(year) paste0(year, "JJ00")

# Write `p` with save_cpb() at a CPB page width next to knitr's figures and
# include it; shown at half size via the chunk's out.width
show_cpb <- function(p, name, page = "half", height = NULL) {
  file <- file.path(dirname(knitr::fig_path()), paste0(name, ".png"))
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  invisible(utils::capture.output(suppressMessages(
    save_cpb(file, p, page = page, height = height))))
  # link relative to the HTML, which pkgdown writes outside vignettes/
  knitr::include_graphics(sub("^.*/(?=[^/]+_files/)", "", file, perl = TRUE),
                          error = FALSE)
}

# Horizontal bars: first category at the top, simulatie above StatLine; pass
# colour_index = c(2, 6) to keep simulatie blue and StatLine magenta
flip <- function(d, x) {
  d <- copy(d)
  d[, (x) := factor(get(x), levels = rev(levels(factor(get(x)))))]
  d[, bron := factor(bron, levels = c("StatLine", "simulatie"))]
  d
}

# Lines: simulatie blue, StatLine magenta, as in the bar charts; pass
# colour_index = c(6, 2)
lines_bron <- function(d) {
  d <- copy(d)
  d[, bron := factor(bron, levels = c("simulatie", "StatLine"))]
  d
}
