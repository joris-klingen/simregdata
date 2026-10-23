# simregdata

Synthetic CBS microdata generator for R. Mimics the exact file structure, column names, value labels, and cross-file join keys of CBS registers — so analysis code written against this simulator runs unchanged on the real remote-access data. Key variables are calibrated to publicly available CBS StatLine statistics for realistic marginal distributions across demographics, housing, vehicles, employment, wealth, and energy.

> **Disclaimer.** simregdata is an independent project. It is not affiliated
> with, endorsed by, or supported by CBS (Statistics Netherlands). All data it
> produces is synthetic: it contains no CBS microdata, and nothing it produces
> describes real persons, households, dwellings or businesses. Results computed
> on simulated data are not statistics about the Netherlands; publish only
> results computed on the real data in CBS Remote Access, under CBS's output
> rules. See [docs/provenance.md](docs/provenance.md) for where every
> parameter comes from.

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

See the **[Getting started guide](docs/vignettes/simregdata.md)** for the full workflow: labelled columns, cross-file joins, bulk parquet export, custom datasets, and the complete function reference.

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

Rendered versions of the vignettes (with output and figures) are in
[docs/vignettes/](docs/vignettes/), regenerated with `Rscript dev/render_vignettes.R`.

- **[Getting started](docs/vignettes/simregdata.md)** — workflow, joins, bulk export, custom datasets, function reference, performance, demographic dynamics
- **[Calibration overview](docs/vignettes/calibration-overview.md)** — how variables are calibrated to CBS StatLine
- **[Column overview](docs/column-overview.md)** — all 648 simulated columns
- **[Provenance](docs/provenance.md)** — the source of every simulation parameter
- **[CBS variable reference](docs/cbs-variable-reference.md)** — source variable documentation notes

### Simulation quality

How close is an analysis on simulated data to the same analysis on the real
microdata? A series of vignettes answers that per research question, comparing
simulated outcomes with CBS StatLine (via `cbsodataR`, plots via
[ggcpb](https://github.com/joris-klingen/ggcpb)):

| Vignette | Research question | Datasets |
|----------|-------------------|----------|
| [Cars](docs/vignettes/quality-cars.md) | How fast is the car fleet electrifying, by vehicle age, mileage and region? | RDW, Woonbase |
| [Household income](docs/vignettes/quality-income.md) | How unequal is household disposable income, and how does it differ by household type? | INHATAB, INPATAB, Woonbase |
| [Energy use](docs/vignettes/quality-energy.md) | Which dwellings use the most gas and electricity, and how much do solar panels reduce net demand? | Energieverbruik, Woonbase |

## How it works

The simulator is driven by per-dataset YAML config under `inst/config/datasets/`. Year-specific parameters are calibrated to CBS StatLine, checked into git, and applied at generation time — **no API calls are made when data is generated**. Persons carry a deterministic, year-invariant life course (birth, death, migration), so the population is genuinely unbalanced across years while cross-year joins stay reproducible. Details are in the [Getting started guide](docs/vignettes/simregdata.md).

## Background

[CBS microdata](https://www.cbs.nl/nl-nl/onze-diensten/maatwerk-en-microdata/microdata-zelf-onderzoek-doen "CBS microdata catalog") are linked administrative registers available to researchers via the CBS Remote Access environment. Because the real files are restricted, this project simulates them from the PDF variable documentation so that analysis scripts can be developed and tested locally, workflows can be benchmarked, and colleagues without CBS access can reproduce results.

## Sources

- **Calibration parameters**: CBS StatLine open data, © CBS, reused under
  [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/)
  (see the [CBS copyright statement](https://www.cbs.nl/nl-nl/over-ons/website/copyright)).
  Tables used: 37230ned, 70072ned, 71486ned (population, households, WOZ);
  81431NED (jobs and wages); 83834NED (household wealth); 83932NED
  (household income); 85236NED, 85237NED, 85404NED (vehicles); 81528NED,
  85140NED and the Kerncijfers wijken en buurten tables (energy use). The
  `*_update_params()` functions fetch them; [docs/provenance.md](docs/provenance.md)
  lists which parameters come from which table and which do not come from
  StatLine.
- **File structure and variable definitions**: transcribed from the public
  variable documentation in the
  [CBS microdata catalogue](https://www.cbs.nl/nl-nl/onze-diensten/maatwerk-en-microdata/microdata-zelf-onderzoek-doen/catalogus-microdata).
  The documents themselves are not part of this repository;
  [docs/cbs-catalogs.yaml](docs/cbs-catalogs.yaml) lists their URLs.
