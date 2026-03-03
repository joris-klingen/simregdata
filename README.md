# sim_mdata

Synthetic CBS Woonbase microdata generator for R. Mimics the exact file structure, column names, value labels, and cross-file join keys of the seven CBS Woonbase registers — so analysis code written against this simulator runs unchanged on the real restricted-access data.

## Background

[CBS Woonbase](https://www.cbs.nl/nl-nl/onze-diensten/maatwerk-en-microdata/microdata-zelf-onderzoek-doen/microdatabestanden/woonbase-kenmerken-woonruimten) is a set of linked housing and population microdata files available to researchers via the CBS Remote Access environment. Because the real files are restricted, this project simulates them from the PDF variable documentation so that:

- Analysis scripts can be developed and tested locally
- Workflows can be benchmarked and profiled
- Colleagues without CBS access can reproduce results

## Directory layout

```
sim_mdata/
├── data/
│   ├── raw/mdata_pdfs_woonbase/      # 7 CBS variable documentation PDFs
│   │   └── extracted/                # Plain-text extraction from each PDF
│   └── interim/woonbase_meta/        # Parsed metadata (RDS + CSV)
├── output/figures/                   # Generated plots (gitignored)
├── scripts/
│   ├── 000_project_init.R            # Shared package loads + directory setup
│   ├── 010_import_micro_meta.R       # ODISSEI Dataverse metadata download
│   ├── 030_analyse_woonbase.R        # 6 plots + 2 maps from joined Woonbase files
│   ├── 031_housing_type_timeseries.R # Housing stock composition 2016–2024
│   ├── 090_test_woonbase_import.R    # Phase timing + profvis flame graph
│   ├── test_read_sav_woonbase.R      # Correctness test suite (PASS/FAIL)
│   └── functions/
│       └── read_sav_woonbase.R       # Core simulator (~880 lines)
└── references/                       # Variable selection notes
```

## The seven Woonbase files

| Short name | CBS file name prefix |
|------------|----------------------|
| `sleutel` | `woonbasesleutel` |
| `kenmerken_pers` | `woonbasekenmerkenpers` |
| `kenmerken_hh` | `woonbasekenmerkenhuis` |
| `kenmerken_obj` | `woonbasekenmerkenwoon` |
| `populatie_pers` | `woonbasepopulatieperso` |
| `populatie_hh` | `woonbasepopulatiehuis` |
| `populatie_obj` | `woonbasepopulatiewoon` |

`read_sav()` recognises any realistic CBS file name (with or without year and version suffix, any case).

## Quick start

```r
source("scripts/functions/read_sav_woonbase.R")

# Build a spine for 2023 (100 000 persons takes ~ 2 s)
woonbase_init(year = 2023L, n = 100000L, seed = 42L)

# Read columns — works exactly like haven::read_sav() on the real CBS file,
# including haven::labelled columns that convert with as_factor()
dt <- read_sav(
  "woonbasepopulatieperso",
  col_select = c(RINPERSOON, VBOWoningType1Jan, GBAGeboorteJaar1Jan)
)

# Cross-file joins work because all files share the same spine IDs
dt_pers <- as.data.table(read_sav("woonbasepopulatieperso",
                                   col_select = c(RINPERSOON, HUISHOUDNR1Jan,
                                                  VBOWoningType1Jan)))
dt_hh   <- as.data.table(read_sav("woonbasepopulatiehuis",
                                   col_select = c(HUISHOUDNR1Jan, TYPHH1Jan)))

dt_pers[dt_hh, on = "HUISHOUDNR1Jan", TYPHH1Jan := i.TYPHH1Jan]
```

## How the simulator works

`read_sav_woonbase.R` exports three public functions:

| Function | Description |
|----------|-------------|
| `woonbase_init(year, n, seed)` | Builds and caches the shared spine (persons × households × objects). Call once before reading multiple files to guarantee consistent join keys. |
| `read_sav(file, col_select, n_max, skip, ...)` | Drop-in replacement for `haven::read_sav()`. Recognises Woonbase file names and returns synthetic data; falls through to `haven::read_sav()` for any other path. |
| `woonbase_reset()` | Clears the cached spine (forces a rebuild on the next call). |

### Spine generation

A single shared spine is built in three stages:

1. **Objects** — N_HH dwelling records with spatial attributes (gemeente, wijk, buurt), WOZ value, floor area, build year, owner type, housing type.
2. **Households** — N_HH household records linked to objects; TYPHH proportions optionally drawn from CBS table 71486ned via `cbsodataR`.
3. **Persons** — expanded from households using vectorised `rep()` + `rowid()`; person roles (PLHH), birth year, civil status, and movement indicators assigned by subsetting rather than eager `fcase()` to avoid generating wasted random draws.

Population and household counts for the requested year are fetched from CBS StatLine (tables `37230ned` and `71486ned`) when `cbsodataR` is available; otherwise hardcoded 2023 fallback values are used.

### File assembly and lazy labelling

Each call to `read_sav()` passes the tidyselect `col_select` quosure directly into `.wb_assemble()`. The assembler:

1. Selects the full wide column set from the spine
2. Immediately trims to the requested columns (`.subset_cols()`)
3. Applies `haven::labelled()` only to columns that survived the trim (`.lbl_if()`)

Requesting 2 columns from `populatie_pers` skips ~28 of the 30 labelling calls, which dominates wall time at scale.

## Performance

At 1 M persons on a modern laptop:

| Stage | Approximate time |
|-------|-----------------|
| Spine build (`woonbase_init`) | 8–15 s |
| Assemble 2 columns (`read_sav` with `col_select`) | < 0.5 s |
| Assemble all columns (no `col_select`) | 3–5 s |

Run `scripts/090_test_woonbase_import.R` in RStudio for a labelled timing breakdown and a `profvis` flame graph.

## CBS API (cbsodataR)

`woonbase_cbs_params()` fetches live population and household counts from CBS StatLine. If the package is not installed or the API is unreachable the function silently falls back to hardcoded 2023 values. The relevant tables are:

- `37230ned` — *Bevolking aan het begin van de periode* (population on 1 January)
- `71486ned` — *Particuliere huishoudens; samenstelling en grootte* (household type distribution)

## Dependencies

```r
install.packages(c("data.table", "haven", "rlang", "tidyselect",
                   "ggplot2", "sf",        # for 030 / 031
                   "cbsodataR",            # optional: live CBS counts
                   "profvis"))             # optional: flame graph in 090
```
