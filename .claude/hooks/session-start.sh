#!/bin/bash
# SessionStart hook for Claude Code cloud sessions.
# Installs the R package dependencies needed to run the test suite and the
# lintr linter, so `R CMD check`, testthat, and lintr work in a fresh container.
#
# Idempotent: already-installed packages are skipped. Uses the Posit Public
# Package Manager binary repo for Ubuntu (fast, no compilation).
set -euo pipefail

# Only run in the remote (cloud) environment. Locally, developers manage their
# own R library.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

if ! command -v Rscript >/dev/null 2>&1; then
  echo "session-start: Rscript not found on PATH; skipping R dependency install." >&2
  exit 0
fi

Rscript - <<'RSCRIPT'
# Posit Public Package Manager serves precompiled binaries for Ubuntu, so
# installs are fast and need no system toolchain. Pick the repo for the running
# distro codename, defaulting to the container's Ubuntu 24.04 (noble).
codename <- tryCatch(
  sub('^VERSION_CODENAME=', '',
      grep('^VERSION_CODENAME=', readLines('/etc/os-release'), value = TRUE)),
  error = function(e) character()
)
if (length(codename) != 1L || !nzchar(codename)) codename <- 'noble'
repo <- sprintf('https://packagemanager.posit.co/cran/__linux__/%s/latest', codename)
options(repos = c(CRAN = repo), Ncpus = max(1L, parallel::detectCores()))

# Imports needed at runtime + tools to test and lint. `arrow` powers the
# parquet-export tests (otherwise skipped). Base packages (stats/tools/utils)
# ship with R and are omitted.
needed <- c(
  'data.table', 'haven', 'rlang', 'tibble', 'tidyselect', 'yaml',
  'testthat', 'lintr', 'arrow'
)
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing)) {
  message('Installing R packages: ', paste(missing, collapse = ', '))
  try(install.packages(missing), silent = TRUE)
  still <- missing[!vapply(missing, requireNamespace, logical(1), quietly = TRUE)]
  if (length(still)) {
    # Don't fail the session: a blocked network just means tests/lint are
    # unavailable until the deps can be fetched. Make the reason obvious.
    message('')
    message('WARNING: could not install: ', paste(still, collapse = ', '))
    message('  The CRAN mirror (', repo, ') was unreachable.')
    message('  This usually means the environment network policy blocks R')
    message('  package repositories. Add packagemanager.posit.co under')
    message('  "Allowed domains" (Allow package managers left ticked), or')
    message('  widen the network access level.')
  }
} else {
  message('All required R packages already installed.')
}
RSCRIPT

echo "session-start: R dependency check complete." >&2
