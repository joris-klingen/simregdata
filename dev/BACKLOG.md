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

<details>
<summary><b>5. `conditional_on:` generator type (cross-column dependence)</b></summary>

Let a column's distribution depend on the value of an earlier column, so
correlations are modelled explicitly (e.g. fuel type conditional on build year,
income bracket conditional on education level) instead of every column being
drawn independently.

- **Builds on:** the `.resolve_column()` dispatcher in `../R/assemble.R` (a
  clean single seam for new generator types) and the progressive `base_tbl`
  building that already lets `stable_per` reference earlier columns.
- **Add:** a `conditional_on: <column>` spec with per-level `values`/`probs`
  (or per-level params), plus a matching classifier branch in
  `../R/column_overview.R`.
- **Why now:** this is also the principled fix for the `stable_per` hash
  correlation - real conditional structure replaces accidental rank
  correlation between columns sharing an identifier.
</details>

<details>
<summary><b>6. `sim_validate_config()` + config schema test</b></summary>

A single validator that checks every dataset config (built-in and user-defined)
for the classes of defect found in review.

- **Builds on:** `../R/registry.R` config loading; the ASCII guard in
  `../tests/testthat/test-config-ascii.R`.
- **Add:** verify each `random_categorical` `probs` sums to ~1; every `values`
  entry is covered by its `codelist` c2i (would have caught the SPOLIS `"-"`
  gap); every `from_params` / `mean_from_params` key exists in the dataset's
  `params.yaml` (would have caught `bouwjaar_p`); configs are ASCII-only; the
  manifest `entities` block is consistent with each file's `entity`.
- **Wire in:** run it in a testthat test over all datasets, and call it from
  `sim_register()` so custom YAML is validated on registration.
</details>

<details>
<summary><b>7. Demographic dynamics across years (births/deaths/migration)</b></summary>

Today the spine is a fixed max-N person set that is year-invariant (Phase 1),
so panels are perfectly balanced. Add genuine entry/exit so longitudinal
analyses (attrition, cohort entry, mortality) behave like real RA data.

- **Builds on:** the Phase 1 (identity) / Phase 2 (year-varying) split in
  `../R/spine.R`, and the existing person indicators
  (`Indicator_PersoonIsGeboren`, `...IsOverleden`, `...IsGeimmigreerd`).
- **Add:** let persons enter/leave the panel across years with valid GBA dates,
  driven deterministically per person so a given seed stays reproducible.
</details>

<details>
<summary><b>8. Native `.sav` export mode</b></summary>

Optionally write real SPSS `.sav` files (not just parquet) with full
haven-labelled metadata, mirroring CBS's actual RA file delivery.

- **Builds on:** `sim_export()` in `../R/api.R` and the haven-labelled columns
  already produced by `.lbl()` / `.apply_codelist()`.
- **Add:** a `format = c("parquet", "sav")` option that routes through
  `haven::write_sav()`, preserving value labels and variable labels, so scripts
  written against the simulator (real `haven::read_sav()` calls included) are
  drop-in for the RA environment.
</details>
