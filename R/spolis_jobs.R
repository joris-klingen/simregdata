# SPOLIS job structure builder ----
#
# Generates a realistic job table with:
# - Multiple jobs per person (configurable distribution)
# - Persistent IKVIDs across months and years
# - Monthly row expansion (one row per job-month)
# - Job-level attributes that stay constant within a job

# Build the expanded SPOLIS job spine
#
# Returns a data.table with one row per job-month, containing:
#   RINPERSOON, RINPERSOONS, IKVID, job_group (integer 1..n_unique_jobs),
#   period_start, period_end (YYYYMMDD strings for the month boundaries),
#   plus columns for IKV start/end dates.
#
# @param spine_pers  data.table with at least RINPERSOON column
# @param n_jobs      target number of unique jobs
# @param params      year-specific params list
# @param year        simulation year
# @param seed        RNG seed
.build_spolis_jobs <- function(spine_pers, n_jobs, params, year, seed) {

  set.seed(seed)
  n_pers <- nrow(spine_pers)

  # Job-count distribution: how many jobs does each person have ----
  # ~70% have 1 job, ~20% have 2 jobs, ~7% have 3, ~3% have 4
  jobs_prob <- c(0.70, 0.20, 0.07, 0.03)
  jobs_per_person <- sample(1:4, n_pers, replace = TRUE, prob = jobs_prob)
  n_total_jobs <- sum(jobs_per_person)

  # Expand person index -> one row per job ----
  person_idx <- rep(seq_len(n_pers), jobs_per_person)
  job_within_person <- unlist(lapply(jobs_per_person, seq_len))

  rinpersoon <- spine_pers$RINPERSOON[person_idx]

  # Generate persistent IKVIDs (deterministic per person+job_index) ----
  ikvid <- .deterministic_job_id(rinpersoon, job_within_person, width = 32L)

  # Generate persistent employer IDs (SBEID) ----
  sbeid <- .deterministic_job_id(rinpersoon, job_within_person, width = 8L,
                                  salt = "beid")

  # Determine active months per job ----
  # Primary jobs (index 1) mostly run all 12 months
  # Secondary jobs have shorter durations
  start_month <- integer(n_total_jobs)
  end_month   <- integer(n_total_jobs)

  is_primary <- job_within_person == 1L

  # Primary jobs: ~85% full year, ~15% partial
  primary_full <- is_primary & (runif(n_total_jobs) < 0.85)
  start_month[primary_full] <- 1L
  end_month[primary_full]   <- 12L

  primary_partial <- is_primary & !primary_full
  n_pp <- sum(primary_partial)
  if (n_pp > 0L) {
    # Half start mid-year, half end mid-year
    pp_starts_late <- runif(n_pp) < 0.5
    start_month[primary_partial] <- ifelse(pp_starts_late,
      sample(2:6, n_pp, replace = TRUE), 1L)
    end_month[primary_partial] <- ifelse(pp_starts_late,
      12L, sample(6:11, n_pp, replace = TRUE))
  }

  # Secondary jobs: shorter, more variable duration
  secondary <- !is_primary
  n_sec <- sum(secondary)
  if (n_sec > 0L) {
    sec_start <- sample(1:12, n_sec, replace = TRUE,
                        prob = c(0.20, 0.10, 0.08, 0.08, 0.06, 0.06,
                                 0.06, 0.06, 0.10, 0.06, 0.06, 0.08))
    sec_duration <- pmin(
      sample(1:12, n_sec, replace = TRUE,
             prob = c(0.15, 0.12, 0.12, 0.10, 0.08, 0.08,
                      0.07, 0.06, 0.05, 0.05, 0.05, 0.07)),
      12L - sec_start + 1L
    )
    start_month[secondary] <- sec_start
    end_month[secondary]   <- sec_start + sec_duration - 1L
  }

  # Build job-level table (one row per unique job) ----
  job_tbl <- data.table(
    person_idx       = person_idx,
    job_within       = job_within_person,
    RINPERSOON       = rinpersoon,
    IKVID            = ikvid,
    SBEID            = sbeid,
    start_month      = start_month,
    end_month        = end_month,
    job_group        = seq_len(n_total_jobs)
  )

  # Copy RINPERSOONS from spine if available
  if ("RINPERSOONS" %in% names(spine_pers)) {
    job_tbl[, RINPERSOONS := spine_pers$RINPERSOONS[person_idx]]
  }

  # Expand to monthly rows ----
  months_list <- mapply(seq, start_month, end_month, SIMPLIFY = FALSE)
  n_months_each <- vapply(months_list, length, integer(1))
  month_vec <- unlist(months_list)

  expanded <- job_tbl[rep(seq_len(n_total_jobs), n_months_each)]
  expanded[, month := month_vec]

  # Compute period dates ----
  expanded[, period_start := sprintf("%d%02d01", year, month)]

  # Last day of each month
  month_days <- c(31L, 28L, 31L, 30L, 31L, 30L, 31L, 31L, 30L, 31L, 30L, 31L)
  # Leap year check
  is_leap <- (year %% 4L == 0L & year %% 100L != 0L) | (year %% 400L == 0L)
  if (is_leap) month_days[2L] <- 29L
  expanded[, period_end := sprintf("%d%02d%02d", year, month,
                                    month_days[month])]

  # IKV dates (job-level, not month-level)
  expanded[, ikv_start := sprintf("%d%02d01", year, start_month)]
  expanded[, ikv_end   := sprintf("%d%02d%02d", year, end_month,
                                   month_days[end_month])]

  # Jan 1 of the year (for SDATUMAANVANGIKVORG)
  jan1_str <- sprintf("%d0101", year)
  expanded[, ikv_start_prev := jan1_str]

  # Clean up helper columns
  expanded[, c("person_idx", "job_within", "start_month", "end_month",
               "month") := NULL]

  expanded
}


# Generate deterministic IDs from person+job index ----
# Same person+job always produces the same ID, regardless of year or seed.
# Fully vectorized: uses multiplicative hashing on numeric keys (no R-level
# per-element loop), ~100x faster than the previous vapply+rlang::hash approach.
.deterministic_job_id <- function(rinpersoon, job_index, width = 32L,
                                   salt = "") {
  salt_int <- if (nzchar(salt)) sum(utf8ToInt(salt)) else 0L
  rp_num <- as.double(rinpersoon)
  mod <- 2147483647  # 2^31 - 1
  mixed <- (rp_num * 31 + job_index * 7919 + salt_int) %% mod
  n_chunks <- ceiling(width / 8L)
  chunks <- vector("list", n_chunks)
  for (k in seq_len(n_chunks)) {
    mixed <- (mixed * 69069 + k) %% mod
    chunks[[k]] <- sprintf("%08x", as.integer(mixed))
  }
  substr(do.call(paste0, chunks), 1L, width)
}
