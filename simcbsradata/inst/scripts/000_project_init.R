# scripts/000_project_init.R
# Shared setup sourced by scripts that need common packages and directories.

suppressPackageStartupMessages({
  library(simcbsradata)
  library(data.table)
  library(ggplot2)
  library(haven)
})

# Suppress Rplots.pdf when run non-interactively (e.g. via source())
if (!interactive()) pdf(NULL)

# Output directories
for (d in c("output/figures", "output/tables", "output/values",
            "data/interim", "data/processed")) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

# Shared colour palette (CBS house style)
CBS_KLEUREN <- c("#004699", "#009dec", "#6cbd74", "#bed200",
                 "#d48fb9", "#ff9100", "#ec0000")

options(
  ggplot2.discrete.fill   = list(CBS_KLEUREN),
  ggplot2.discrete.colour = list(CBS_KLEUREN)
)
