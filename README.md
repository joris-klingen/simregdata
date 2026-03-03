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
├── config/
│   ├── cbs_annual.yaml               # CBS population counts + TYPHH per year
│   └── gem_weights.csv               # Municipality population weights per year
├── data/
│   ├── raw/mdata_pdfs_woonbase/      # 7 CBS variable documentation PDFs
│   │   └── extracted/                # Plain-text extraction from each PDF
│   └── interim/woonbase_meta/        # Parsed metadata (RDS + CSV)
├── output/figures/                   # Generated plots (gitignored)
├── scripts/
│   ├── 000_project_init.R            # Shared package loads + directory setup
│   ├── 030_analyse_woonbase.R        # 6 plots + 2 maps from joined Woonbase files
│   ├── 031_housing_type_timeseries.R # Housing stock composition 2016–2024
│   ├── 101_maps_woonbase.R           # Municipality choropleths
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

`read_sav()` matches exact CBS dataset names (CamelCase, as used on the secure VM). The year and version suffix (`2023V1`) are parsed to auto-set the simulation year. Full VM paths, bare dataset names, and `.sav` extensions are all accepted.

## Quick start

```r
source("scripts/functions/read_sav_woonbase.R")

# Build a spine for 2023 (100 000 persons takes ~ 2 s)
woonbase_init(year = 2023L, n = 100000L, seed = 42L)

# Read columns — works exactly like haven::read_sav() on the real CBS file,
# including haven::labelled columns that convert with as_factor()
dt <- read_sav(
  "WoonbasePopulatiePersonen2023V1",
  col_select = c(RINPERSOON, VBOWoningType1Jan, GBAGeboorteJaar1Jan)
)

# Full CBS VM path works too — year is inferred from the filename
dt <- read_sav(
  "G:/BOUWENENWONEN/WOONBASEPOPULATIEPERSONEN/WoonbasePopulatiePersonen2023V1.sav",
  col_select = c(RINPERSOON, VBOWoningType1Jan)
)

# Cross-file joins work because all files share the same spine IDs
dt_pers <- as.data.table(read_sav("WoonbasePopulatiePersonen2023V1",
                                   col_select = c(RINPERSOON, HUISHOUDNR1Jan,
                                                  VBOWoningType1Jan)))
dt_hh   <- as.data.table(read_sav("WoonbasePopulatieHuishoudens2023V1",
                                   col_select = c(HUISHOUDNR1Jan, TYPHH1Jan)))

dt_pers[dt_hh, on = "HUISHOUDNR1Jan", TYPHH1Jan := i.TYPHH1Jan]
```

## How the simulator works

`read_sav_woonbase.R` exports three public functions:

| Function | Description |
|----------|-------------|
| `woonbase_init(year, n, seed)` | Builds and caches the shared spine (persons × households × objects). Call once before reading multiple files to guarantee consistent join keys. |
| `read_sav(file, col_select, n_max, skip, ...)` | Drop-in replacement for `haven::read_sav()`. Matches exact CBS Woonbase dataset names (e.g. `WoonbasePopulatiePersonen2023V1`) and returns synthetic data; infers the simulation year from the filename. Falls through to `haven::read_sav()` for any other path. |
| `woonbase_catalog(year)` | Prints all 7 available synthetic file names with column counts and observation units. |
| `woonbase_reset()` | Clears the cached spine (forces a rebuild on the next call). |
| `woonbase_update_params(years)` | Fetches CBS StatLine data via `cbsodataR` and writes to `config/cbs_annual.yaml` + `config/gem_weights.csv`. Run once to refresh. |

### Spine generation

A single shared spine is built in three stages:

1. **Objects** — N_HH dwelling records with spatial attributes (gemeente, wijk, buurt), WOZ value, floor area, build year, owner type, housing type.
2. **Households** — N_HH household records linked to objects; TYPHH proportions from `config/cbs_annual.yaml`.
3. **Persons** — expanded from households using vectorised `rep()` + `rowid()`; person roles (PLHH), birth year, civil status, and movement indicators assigned by subsetting rather than eager `fcase()` to avoid generating wasted random draws.

Population counts and household type proportions for each year (2016–2024) are read from `config/cbs_annual.yaml`; municipality weights from `config/gem_weights.csv`. Both files are pre-populated and checked into git, so **no API calls are made during data generation**. To refresh with the latest CBS data, run `woonbase_update_params()` once.

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

## CBS parameters

Year-specific population counts and household type distributions are stored in `config/cbs_annual.yaml`; municipality population weights in `config/gem_weights.csv` (both checked into git). This means `read_sav()` never calls the CBS API during normal use.

To refresh (e.g. when CBS publishes a new year):

```r
source("scripts/functions/read_sav_woonbase.R")
woonbase_update_params()               # refreshes 2016-2024
woonbase_update_params(years = 2025)   # add a single new year
```

The update function fetches from CBS StatLine tables:

- `37230ned` — *Bevolking aan het begin van de periode* (population on 1 January)
- `71486ned` — *Particuliere huishoudens; samenstelling en grootte* (household type distribution)

## Dependencies

```r
install.packages(c("data.table", "haven", "rlang", "tidyselect", "yaml",
                   "ggplot2", "sf", "glue",  # for 030 / 031 / 101
                   "cbsodataR",              # optional: refresh YAML params
                   "profvis"))               # optional: flame graph in 090
```
