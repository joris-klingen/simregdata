#!/usr/bin/env bash
# Startup script for a Claude cloud environment working on the simregdata R package.
# Target: Ubuntu (Claude cloud images). Run once at environment setup.
# Installs R, system libraries for sf/arrow/ggplot2, and all package dependencies.

set -euo pipefail

echo "==> simregdata cloud setup starting"

export DEBIAN_FRONTEND=noninteractive

# --- System packages ---------------------------------------------------------
# R base + build toolchain, plus headers that sf (gdal/geos/proj/udunits),
# ggplot2/systemfonts (fontconfig/freetype/harfbuzz/fribidi) and the usual
# curl/ssl/xml2 R packages compile against.
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  r-base r-base-dev \
  build-essential gfortran \
  pandoc \
  libcurl4-openssl-dev libssl-dev libxml2-dev \
  libgdal-dev libgeos-dev libproj-dev libudunits2-dev \
  libfontconfig1-dev libfreetype6-dev libharfbuzz-dev libfribidi-dev \
  libpng-dev libtiff5-dev libjpeg-dev

echo "==> R version: $(R --version | head -n1)"

# --- R package installation --------------------------------------------------
# Use Posit Public Package Manager so CRAN packages install as precompiled
# Linux binaries (minutes instead of compiling everything from source).
UBUNTU_CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-jammy}")"

Rscript - "$UBUNTU_CODENAME" <<'EOF'
codename <- commandArgs(trailingOnly = TRUE)[1]
repo <- sprintf(
  "https://packagemanager.posit.co/cran/__linux__/%s/latest",
  codename
)
options(
  repos = c(P3M = repo, CRAN = "https://cloud.r-project.org"),
  Ncpus = max(1L, parallel::detectCores())
)
options(HTTPUserAgent = sprintf(
  "R/%s R (%s)",
  getRversion(),
  paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])
))

# pak resolves and installs Imports + Suggests from the DESCRIPTION, plus the
# dev tooling, pulling binaries where available.
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak")
}

pak::pak(c(
  "local::.",        # simregdata itself (deps = Imports + Suggests)
  "devtools",
  "roxygen2",
  "testthat",
  "lintr"
), dependencies = TRUE)

cat("\n==> Installed package check:\n")
needed <- c("data.table", "haven", "rlang", "tibble", "tidyselect", "yaml",
            "arrow", "sf", "ggplot2", "testthat", "devtools")
for (p in needed) {
  cat(sprintf("  %-12s %s\n", p,
      if (requireNamespace(p, quietly = TRUE)) "ok" else "MISSING"))
}
EOF

# --- Smoke test --------------------------------------------------------------
# Load the package to confirm the toolchain is wired up end to end.
Rscript -e 'devtools::load_all("."); cat("\n==> simregdata loaded OK\n")'

echo "==> simregdata cloud setup complete"
echo "    Run tests with: Rscript -e 'devtools::test()'"
