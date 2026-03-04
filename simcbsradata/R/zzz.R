# Config path helpers ----

# Base path for all dataset configs
.datasets_dir <- function() {
  system.file("config", "datasets", package = "simcbsradata")
}

# Dataset-specific config directory
.dataset_dir <- function(dataset_id) {
  file.path(.datasets_dir(), dataset_id)
}

# Woonbase-specific helpers (backward compat + used by params.R)
.wb_annual_yaml <- function() {
  file.path(.dataset_dir("woonbase"), "params.yaml")
}

.wb_gem_weights_csv <- function() {
  file.path(.dataset_dir("woonbase"), "gem_weights.csv")
}
