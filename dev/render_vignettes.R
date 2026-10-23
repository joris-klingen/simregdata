# dev/render_vignettes.R
#
# Renders the vignettes to GitHub-flavoured markdown in docs/vignettes/, so
# the README can link to rendered pages (with figures) that display directly
# on GitHub. GitHub shows .Rmd and .html files as source, but renders .md.
# The quality vignettes fetch StatLine, so run this with internet access.
# The vignettes use the installed package (they attach it with library(),
# after haven), so install the current source first. Re-run after editing a
# vignette and commit the updated output:
#
#   R CMD INSTALL .
#   LC_ALL=C.UTF-8 Rscript dev/render_vignettes.R
#
# docs/ is .Rbuildignore'd, so the built package still ships only the
# html_vignette versions.

library(ggcpb)

# Dutch figure labels need a UTF-8 locale, otherwise accented characters
# are drawn as missing glyphs
if (!l10n_info()$`UTF-8`) Sys.setlocale("LC_CTYPE", "C.UTF-8")
if (!l10n_info()$`UTF-8`) stop("No UTF-8 locale; run with LC_ALL=C.UTF-8")


# Render ----

out_dir <- file.path("docs", "vignettes")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

for (rmd in list.files("vignettes", pattern = "\\.Rmd$", full.names = TRUE)) {
  tcat("rendering ", basename(rmd))
  # render from a copy inside out_dir so figure links in the .md are relative
  local_rmd <- file.path(out_dir, basename(rmd))
  # start from an empty figure folder so figures of removed or renamed
  # chunks do not linger
  unlink(sub("\\.Rmd$", "_files", local_rmd), recursive = TRUE)
  file.copy(rmd, local_rmd, overwrite = TRUE)
  rmarkdown::render(
    local_rmd,
    output_format = rmarkdown::github_document(html_preview = FALSE),
    quiet         = TRUE,
    envir         = new.env()
  )
  unlink(local_rmd)

  # links to sibling vignettes are written as .html for the built package;
  # on GitHub the siblings are .md
  md <- sub("\\.Rmd$", ".md", local_rmd)
  txt <- readLines(md, warn = FALSE)
  writeLines(gsub("(\\]\\([^):]*)\\.html\\)", "\\1.md)", txt), md)
}

tcat("rendered vignettes written to ", out_dir)
