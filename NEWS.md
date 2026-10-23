# simregdata 0.4.0

* Simulated files now have the structure of the real ones where it breaks
  code: owners with several vehicles, dropped and business-stock cars, company
  owners outside the population, `VERKEERSPRESTATIE` limited to active cars of
  natural persons, numeric RDW columns; INHATAB codes for unknown income and
  institutional households and negative incomes; empty `GAS`/`ELEK`, capped
  `ELEKNETTO`, consistent heating and determination codes; vacant dwellings
  and unknown floor area and WOZ classes.
* New column rules in the YAML specs: `only_for`, `not_for`, `codes_for` and
  `numeric: true`.
* Documentation moved to a pkgdown site; README and getting-started vignette
  shortened.
* Worked examples (cars, household income, energy use) that develop analysis
  code on simulated data, compare it with StatLine and list what differs in
  Remote Access.
* Dwelling characteristics (municipality, build year, floor area) are stable
  across years.
* Energy use depends on dwelling type, floor area, build year and household
  size, calibrated to StatLine 81528NED and 85140NED.
* Household income (INHATAB) is calibrated per household type to 83932NED.
* `VEHTAB` household keys now match `INPATAB` and `INHATAB`.
* Cross-dataset join checks moved into the test suite.
