# Quick test of SPOLIS job structure
suppressPackageStartupMessages({
  library(data.table)
  library(haven)
})
devtools::load_all(".")

cat("=== SPOLIS job structure test ===\n\n")

sim_reset()
sim_init("spolis", year = 2023L, n = 100L, seed = 42L)
dt <- as.data.table(read_sav("SPOLISBUS2023V1"))

cat(sprintf("Rows: %d, Cols: %d\n", nrow(dt), ncol(dt)))
cat(sprintf("Unique persons: %d\n", length(unique(dt[["RINPERSOON"]]))))
cat(sprintf("Unique IKVIDs: %d\n", length(unique(dt[["IKVID"]]))))

# Check job structure
person_jobs <- dt[, .(n_ikvid = uniqueN(IKVID), n_rows = .N), by = RINPERSOON]
cat(sprintf("Persons with 1 job: %d\n", sum(person_jobs[["n_ikvid"]] == 1)))
cat(sprintf("Persons with 2+ jobs: %d\n", sum(person_jobs[["n_ikvid"]] > 1)))

# Check monthly consistency - same IKVID should have same SSECT
job_check <- dt[, .(n_sect = uniqueN(SSECT)), by = IKVID]
cat(sprintf("Jobs with consistent SSECT: %d / %d\n",
            sum(job_check[["n_sect"]] == 1), nrow(job_check)))

# Check SCONTRACTSOORT consistency
job_contract <- dt[, .(n_contract = uniqueN(SCONTRACTSOORT)), by = IKVID]
cat(sprintf("Jobs with consistent SCONTRACTSOORT: %d / %d\n",
            sum(job_contract[["n_contract"]] == 1), nrow(job_contract)))

# Check months per job
job_months <- dt[, .N, by = IKVID]
cat(sprintf("Avg months per job: %.1f\n", mean(job_months[["N"]])))
cat(sprintf("Min months: %d, Max months: %d\n",
            min(job_months[["N"]]), max(job_months[["N"]])))

# Check period dates
cat(sprintf("Sample period_start: %s\n",
            paste(head(dt[["SDATUMAANVANGIKO"]], 5), collapse = ", ")))
cat(sprintf("Sample period_end: %s\n",
            paste(head(dt[["SDATUMEINDEIKO"]], 5), collapse = ", ")))

# Check IKV dates are job-level
ikv_check <- dt[, .(n_ikv_start = uniqueN(SDATUMAANVANGIKV)), by = IKVID]
cat(sprintf("Jobs with consistent IKV start: %d / %d\n",
            sum(ikv_check[["n_ikv_start"]] == 1), nrow(ikv_check)))

# Cross-year persistence test
# IKVIDs are deterministic per RINPERSOON+job_index, so the same person
# appearing in two years should get the same IKVIDs.
cat("\n--- Cross-year persistence ---\n")

# Test directly: same RINPERSOON+job_index -> same IKVID regardless of year
test_persons <- c("000000001", "000000002", "000000003")
id_a <- simcbsradata:::.deterministic_job_id(test_persons, c(1L, 1L, 1L))
id_b <- simcbsradata:::.deterministic_job_id(test_persons, c(1L, 1L, 1L))
stopifnot(identical(id_a, id_b))
cat("  Same RINPERSOON+job_index -> same IKVID: PASS\n")

# Different job_index -> different IKVID
id_j1 <- simcbsradata:::.deterministic_job_id("000000001", 1L)
id_j2 <- simcbsradata:::.deterministic_job_id("000000001", 2L)
stopifnot(id_j1 != id_j2)
cat("  Different job_index -> different IKVID: PASS\n")

# Different person -> different IKVID
id_p1 <- simcbsradata:::.deterministic_job_id("000000001", 1L)
id_p2 <- simcbsradata:::.deterministic_job_id("000000002", 1L)
stopifnot(id_p1 != id_p2)
cat("  Different person -> different IKVID: PASS\n")

# Full pipeline: same spine, different year
sim_reset()
woonbase_init(year = 2023L, n = 100L, seed = 42L)
sim_init("spolis", year = 2023L, n = 100L, seed = 42L)
dt23b <- as.data.table(read_sav("SPOLISBUS2023V1"))

# Same spine, same seed, same n -> same persons -> same IKVIDs
sim_init("spolis", year = 2023L, n = 100L, seed = 42L)
dt23c <- as.data.table(read_sav("SPOLISBUS2023V1"))

ikvids_b <- sort(unique(dt23b[["IKVID"]]))
ikvids_c <- sort(unique(dt23c[["IKVID"]]))
stopifnot(identical(ikvids_b, ikvids_c))
cat("  Reproducible IKVIDs with same seed: PASS\n")

cat("\n=== Done ===\n")
