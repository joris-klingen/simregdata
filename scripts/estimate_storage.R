library(yaml)
wb <- yaml::read_yaml("simcbsradata/inst/config/datasets/woonbase/params.yaml")
rdw <- yaml::read_yaml("simcbsradata/inst/config/datasets/rdw/params.yaml")
sp <- yaml::read_yaml("simcbsradata/inst/config/datasets/spolis/params.yaml")

# Per-row parquet byte rates from 1M benchmark (655.3 MB total)
# Woonbase: 9 files, mix of person/hh/obj entity
#   Person files (sleutel 16c, kenmerken_pers 32c, populatie_pers 50c): ~1.04M rows
#   HH files (kenmerken_hh 16c, populatie_hh 40c, ek_hh 60c): ~464K rows
#   Obj files (kenmerken_obj 22c, populatie_obj 45c, ek_obj 32c): ~464K rows
# From benchmark at 1M persons:
#   Total woonbase person-entity rows = 1,043,118 * 3 files
#   Total woonbase hh-entity rows = 464,326 * 3 files
#   Total woonbase obj-entity rows = 464,326 * 3 files
# Approximate bytes/row from benchmark (655.3 MB total, of which
#   RDW ~1M rows, SPOLIS ~1M rows, Woonbase ~1M pers / 464K hh / 464K obj)
# Let me compute per-dataset MB from typical parquet compression ratios:

# Measured from benchmark at n=1M:
# Per-person-row across all 9 woonbase files (accounting for hh/obj ratio):
#   woonbase total ≈ 443 MB (655.3 - ~100 RDW - ~112 SPOLIS)
#   persons ~1.04M, hh_ratio ~0.445, so hh~464K, obj~464K
wb_bytes_per_person <- 443 / 1.043  # MB per 1M persons

# RDW: 2 files, 1M rows each → ~100 MB
rdw_bytes_per_record <- 100 / 1.0  # MB per 1M records

# SPOLIS: 1 file, 1M rows, 133 cols → ~112 MB
sp_bytes_per_record <- 112 / 1.0   # MB per 1M records

cat("Per-row byte rates (MB per 1M rows):\n")
cat(sprintf("  Woonbase:  %.0f MB / 1M persons\n", wb_bytes_per_person))
cat(sprintf("  RDW:       %.0f MB / 1M records\n", rdw_bytes_per_record))
cat(sprintf("  SPOLIS:    %.0f MB / 1M records\n", sp_bytes_per_record))
cat("\n")

total_gb <- 0
cat(sprintf("%-4s  %10s  %10s  %10s  %8s\n",
            "Year", "Persons", "Vehicles", "Jobs", "Est. GB"))
cat(sprintf("%-4s  %10s  %10s  %10s  %8s\n",
            "----", "----------", "----------", "----------", "--------"))
for (y in 2016:2024) {
  ys <- as.character(y)
  np <- wb[[ys]][["n_persons"]]
  nv <- rdw[[ys]][["n_vehicles"]]
  nj <- sp[[ys]][["n_jobs"]]

  wb_mb <- (np / 1e6) * wb_bytes_per_person
  rdw_mb <- (nv / 1e6) * rdw_bytes_per_record
  sp_mb <- (nj / 1e6) * sp_bytes_per_record
  year_gb <- (wb_mb + rdw_mb + sp_mb) / 1000

  cat(sprintf("%d  %10s  %10s  %10s  %7.1f\n", y,
              format(np, big.mark = ","),
              format(nv, big.mark = ","),
              format(nj, big.mark = ","),
              year_gb))
  total_gb <- total_gb + year_gb
}
cat(sprintf("\nTotal estimated storage (2016-2024): %.0f GB\n", total_gb))
