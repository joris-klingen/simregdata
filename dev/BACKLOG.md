# Backlog

Dev backlog for `simcbsradata`. Not part of the package (`dev/` is
`.Rbuildignore`d). Most items extend code that already exists.

<details>
<summary><b>1. Codebase scan -> auto sim selection + custom-sim suggestions</b></summary>

Extend the scanner so it doesn't just find `read_sav()` calls but matches the
exact columns requested against the registry, narrows simulation to only those,
and flags anything that isn't CBS data.

- **Builds on:** `sim_scan_columns()` in `../R/scan_columns.R` - already extracts
  `read_sav()` calls + CBS file names and string `col_select` by walking
  expressions. The extraction half exists; matching/reporting does not.
- **Add:** match requested columns exactly against the dataset registry; feed
  matches into a minimal sim / `col_select` so only used columns get generated.
- **Add:** report datasets/columns that are requested but have no exact match in
  any known dataset, and suggest scaffolding a custom simulation (point at
  `sim_create_custom()`).
- **Fix gap:** capture **unquoted** `col_select` (e.g. `col_select = c(RINPERSOON)`)
  by parsing the symbols instead of `eval()` - the current code only keeps a
  `col_select` that evaluates to a character vector, so unquoted tidyselect is
  silently dropped.
- **Fix gap:** record the dataset even when `read_sav()` is called **without**
  `col_select` (whole-file read) - currently those reads contribute nothing.
</details>

<details>
<summary><b>2. User-defined datasets via YAML (incl. non-RA data)</b></summary>

Make it easy to hand-author datasets that aren't CBS Remote-Access microdata
(e.g. external / own data) and have them simulated alongside the built-ins.

- **Builds on:** `sim_create_custom()` + `sim_register()` in `../R/custom.R`
  (custom-dataset registration already works).
- **Add:** a documented workflow + YAML template for non-RA datasets; validate
  the YAML; ensure they join on the shared spine like built-in datasets.
</details>

<details>
<summary><b>3. Convenience: 10% full population -> folder</b></summary>

One call to generate ~10% of the full population for every file and export.

- **Builds on:** `sim_population(output_dir, fraction = 0.01, ...)` in
  `../R/api.R` (fractional export already supported).
- **Add:** a thin convenience wrapper defaulting to `fraction = 0.10` across all
  datasets/years, with a sensible folder layout and an up-front size estimate.
</details>

<details>
<summary><b>4. Benchmark vs cbsodataR for calibrated variables</b></summary>

Validate that simulated aggregates match the real CBS StatLine figures for the
StatLine-calibrated variables (means, shares, distributions) - i.e. the vars
whose distributions come from real CBS data rather than being invented.

- **Builds on:** `cbsodataR` already used for calibration in
  `../R/params_vehtab.R` and `../R/params_energieverbruik.R`; the
  `statline-calibrated` level in `../R/column_overview.R`.
- **Add:** pull the source StatLine tables via `cbsodataR`, compute the same
  aggregates on a simulated sample, and report deltas so drift in calibrated
  vars is caught. Skip purely invented vars.
</details>
