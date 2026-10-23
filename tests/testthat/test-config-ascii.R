# tests/testthat/test-config-ascii.R
# Guards against non-ASCII bytes in config YAML.
#
# Non-ASCII characters (em-dash, arrow, smart quotes, accents) - even in
# comments - break yaml::read_yaml() under non-UTF-8 R locales (e.g. radian
# launched from VSCode), which silently drops datasets from the registry and
# makes read_sav() fall through to haven with a misleading
# "does not exist in current working directory" error.

test_that("config YAML files contain only ASCII", {
  cfg_dir <- system.file("config", "datasets", package = "simregdata")
  skip_if(!nzchar(cfg_dir) || !dir.exists(cfg_dir), "config dir not available")

  yaml_files <- list.files(cfg_dir, pattern = "[.]ya?ml$",
                           recursive = TRUE, full.names = TRUE)
  expect_gt(length(yaml_files), 0L)

  has_non_ascii <- function(f) {
    bytes <- readBin(f, "raw", n = file.info(f)$size)
    any(as.integer(bytes) > 127L)
  }

  offenders <- Filter(has_non_ascii, yaml_files)
  offenders <- sub(".*/datasets/", "", offenders)

  expect_equal(
    offenders, character(0),
    info = paste(
      "Non-ASCII bytes break the dataset registry under non-UTF-8 locales.",
      "Replace with ASCII (use -- not an em-dash, -> not an arrow)."
    )
  )
})