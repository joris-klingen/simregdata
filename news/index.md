# Changelog

## simregdata 0.4.0

- Documentation moved to a pkgdown site; README and getting-started
  vignette shortened.
- New quality articles comparing analyses on simulated data with
  StatLine: cars, household income and energy use.
- Dwelling characteristics (municipality, build year, floor area) are
  stable across years.
- Energy use depends on dwelling type, floor area, build year and
  household size, calibrated to StatLine 81528NED and 85140NED.
- Household income (INHATAB) is calibrated per household type to
  83932NED.
- `VEHTAB` household keys now match `INPATAB` and `INHATAB`.
- Cross-dataset join checks moved into the test suite.
