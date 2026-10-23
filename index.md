# simregdata

[![R-CMD-check](https://github.com/joris-klingen/simregdata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/joris-klingen/simregdata/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/joris-klingen/simregdata/actions/workflows/pkgdown.yaml/badge.svg)](https://joris-klingen.github.io/simregdata/)
[![License: GPL (\>=
2)](https://img.shields.io/badge/license-GPL%20(%3E%3D%202)-blue.svg)](https://joris-klingen.github.io/simregdata/LICENSE.md)

Simulated CBS microdata for R. `simregdata` reproduces the file names,
columns, value labels and join keys of 15 CBS registers, so analysis
code written against it runs unchanged on the real data in CBS Remote
Access. Distributions are calibrated to CBS StatLine.

> **Disclaimer.** simregdata is independent of CBS (Statistics
> Netherlands). All data it produces is synthetic and describes no real
> persons, households, dwellings or businesses. Publish only results
> computed on the real data, under CBS’s output rules.

## Installation

``` r

remotes::install_github("joris-klingen/simregdata")
```

## Example

``` r

library(haven)
library(simregdata)  # after haven, so read_sav() is the simulator's

sim_init("woonbase", year = 2023, n = 100000, seed = 42)
pers <- read_sav("WoonbasePopulatiePersonen2023V1",
                 col_select = c(RINPERSOON, HUISHOUDNR1Jan, VBOWoningType1Jan))

# all datasets share one population, so joins match
sim_init("rdw", year = 2023)
rdw <- read_sav("RDWNPACT2023TABV1")
```

## How good is it?

Quality articles run a research question on simulated data and compare
the answer with StatLine:
[cars](https://joris-klingen.github.io/simregdata/articles/quality-cars.html),
[household
income](https://joris-klingen.github.io/simregdata/articles/quality-income.html)
and [energy
use](https://joris-klingen.github.io/simregdata/articles/quality-energy.html).

![Mean household income by household type, simulated and
StatLine](reference/figures/README-income.png)

## Datasets

| Topic                  | Datasets                                     |
|------------------------|----------------------------------------------|
| Housing and population | Woonbase (13 files), GBA (3)                 |
| Vehicles               | RDW (2)                                      |
| Work and income        | SPOLIS, INPATAB, INHATAB, SECMBUS            |
| Wealth and education   | VEHTAB, HOOGSTEOPLTAB                        |
| Businesses             | BETAB                                        |
| Energy                 | Energieverbruik (2), Zonnestroominstallaties |
| Networks               | Buren-, Collega- and Familienetwerktab       |

The [column
overview](https://joris-klingen.github.io/simregdata/articles/column-overview.html)
lists every simulated column, and the [provenance
article](https://joris-klingen.github.io/simregdata/articles/provenance.html)
where each parameter comes from.

## Sources

Calibration parameters come from CBS StatLine open data, © CBS, reused
under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). File
structures follow the public variable documentation in the [CBS
microdata
catalogue](https://www.cbs.nl/nl-nl/onze-diensten/maatwerk-en-microdata/microdata-zelf-onderzoek-doen/catalogus-microdata).
