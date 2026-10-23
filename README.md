# simregdata

Synthetic CBS microdata generator for R. Mimics the exact file structure, column names, value labels, and cross-file join keys of CBS registers — so analysis code written against this simulator runs unchanged on the real remote-access data. Key variables are calibrated to publicly available CBS StatLine statistics for realistic marginal distributions across demographics, housing, vehicles, employment, wealth, and energy.

## Installation

```r
remotes::install_github("joris-klingen/simregdata")
```

Requires `data.table`, `haven`, `rlang`, `tidyselect`, `yaml`, `tibble`; `arrow` and `cbsodataR` are optional (parquet I/O and StatLine refresh). Licensed under GPL (≥ 2).

## Quick start

```r
library(simregdata)

# Build a shared population spine, then read a file exactly as you would
# with haven::read_sav() on the real CBS remote-access environment
sim_init("woonbase", year = 2023, n = 100000, seed = 42)

dt <- read_sav(
  "WoonbasePopulatiePersonen2023V1",
  col_select = c(RINPERSOON, HUISHOUDNR1Jan, VBOWoningType1Jan)
)

# Cross-file joins work because every dataset shares the same spine IDs
sim_init("rdw", year = 2023)
rdw <- read_sav("RDWNPACT2023TABV1")
```

See the **[Getting started guide](vignettes/simregdata.Rmd)** for the full workflow: labelled columns, cross-file joins, bulk parquet export, custom datasets, and the complete function reference.

## Datasets

**15 datasets, 31 file types, 648 columns**, all sharing a common population spine with consistent join keys (RINPERSOON, HUISHOUDNR, RINOBJECTNUMMER, RINPERSOONHKW) so cross-file joins work exactly as on the real CBS Remote Access. See the full **[column overview](docs/column-overview.md)** for every simulated column with its source, spatial level, calibration link, and codelist.

<details>
<summary>Supported datasets</summary>

| Dataset | Description | Key |
|---------|-------------|-----|
| **Woonbase** | Housing + population (13 files) | RINPERSOON, HUISHOUDNR, RINOBJECTNUMMER |
| **GBA** | Population register (3 files) | RINPERSOON |
| **RDW** | Vehicle registrations (2 files) | RINPERSOON, RINKENTEKEN |
| **SPOLIS** | Employment records with monthly job structure | RINPERSOON, SBEID |
| **VEHTAB** | Household wealth | RINPERSOONHKW |
| **Income** (INPATAB, INHATAB) | Personal + household income | RINPERSOON, RINPERSOONHKW |
| **HOOGSTEOPLTAB** | Highest attained education level | RINPERSOON |
| **SECMBUS** | Socioeconomic category (monthly periods) | RINPERSOON |
| **BETAB** | Business register | BEID |
| **Energieverbruik** | Dwelling energy consumption (annual + monthly smart meter) | RINOBJECTNUMMER |
| **Zonnestroominstallaties** | Solar PV installations + monthly production | RINOBJECTNUMMER |
| **Networks** (Buren, Collega, Familie) | Neighbour, colleague, and family networks | RINPERSOON |

</details>

## Documentation

- **[Getting started](vignettes/simregdata.Rmd)** — workflow, joins, bulk export, custom datasets, function reference, performance, demographic dynamics
- **[Calibration overview](vignettes/calibration-overview.Rmd)** — how variables are calibrated to CBS StatLine
- **[Column overview](docs/column-overview.md)** — all 648 simulated columns
- **[CBS variable reference](docs/cbs-variable-reference.md)** — source variable documentation notes

## How it works

The simulator is driven by per-dataset YAML config under `inst/config/datasets/`. Year-specific parameters are calibrated to CBS StatLine, checked into git, and applied at generation time — **no API calls are made when data is generated**. Persons carry a deterministic, year-invariant life course (birth, death, migration), so the population is genuinely unbalanced across years while cross-year joins stay reproducible. Details are in the [Getting started guide](vignettes/simregdata.Rmd).

## Background

[CBS microdata](https://www.cbs.nl/nl-nl/onze-diensten/maatwerk-en-microdata/microdata-zelf-onderzoek-doen "CBS microdata catalog") are linked administrative registers available to researchers via the CBS Remote Access environment. Because the real files are restricted, this project simulates them from the PDF variable documentation so that analysis scripts can be developed and tested locally, workflows can be benchmarked, and colleagues without CBS access can reproduce results.
