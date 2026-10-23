# simregdata 0.4.0

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
