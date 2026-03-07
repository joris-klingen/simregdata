# SECMBUS period builder ----
#
# Generates a person-period table for socioeconomic categories.
# Each person has 1-3 contiguous periods covering the full year.
# Most people have 1 period (stable category); some have transitions.

# Build the expanded SECMBUS period spine ----
#
# Returns a data.table with one row per person-period, containing:
#   RINPERSOON, RINPERSOONS, period_start, period_end, SECM, period_group
#
# @param spine_pers  data.table with at least RINPERSOON column
# @param year        simulation year
# @param seed        RNG seed
# @param params      year-specific params list (with secm_dist)
.build_secm_periods <- function(spine_pers, year, seed, params = NULL) {

  set.seed(seed + 7L)  # offset from SPOLIS seed
  n_pers <- nrow(spine_pers)

  # Period count distribution: ~80% have 1 period, ~15% have 2, ~5% have 3
  n_periods <- sample(1:3, n_pers, replace = TRUE, prob = c(0.80, 0.15, 0.05))
  n_total <- sum(n_periods)

  # Expand person index

  person_idx <- rep(seq_len(n_pers), n_periods)
  period_within <- unlist(lapply(n_periods, seq_len))

  # SECM category distribution
  secm_vals <- NULL
  secm_probs <- NULL
  if (!is.null(params) && !is.null(params$secm_dist)) {
    secm_vals  <- as.character(names(params$secm_dist))
    secm_probs <- as.numeric(params$secm_dist)
  }
  if (is.null(secm_vals)) {
    secm_vals  <- c("1111", "1112", "1121", "1131", "1210", "1221",
                     "1311", "1321", "2111", "2121")
    secm_probs <- c(0.30, 0.15, 0.02, 0.06, 0.02, 0.03,
                     0.03, 0.18, 0.08, 0.06)
  }
  # Normalize
  secm_probs <- secm_probs / sum(secm_probs)

  # Assign SECM per period row (each period can have a different category)
  secm <- sample(secm_vals, n_total, replace = TRUE, prob = secm_probs)

  # Compute period dates ----
  # Periods are contiguous and cover Jan 1 - Dec 31
  month_days <- c(31L, 28L, 31L, 30L, 31L, 30L, 31L, 31L, 30L, 31L, 30L, 31L)
  is_leap <- (year %% 4L == 0L & year %% 100L != 0L) | (year %% 400L == 0L)
  if (is_leap) month_days[2L] <- 29L

  jan1_str <- sprintf("%d0101", year)
  dec31_str <- sprintf("%d1231", year)

  period_start <- character(n_total)
  period_end   <- character(n_total)

  # For each person, split the year into n_periods contiguous chunks
  idx <- 1L
  for (i in seq_len(n_pers)) {
    np <- n_periods[i]
    if (np == 1L) {
      period_start[idx] <- jan1_str
      period_end[idx]   <- dec31_str
      idx <- idx + 1L
    } else {
      # Split at random month boundaries
      boundaries <- sort(sample(2:12, np - 1L))
      starts <- c(1L, boundaries)
      ends   <- c(boundaries - 1L, 12L)
      for (j in seq_len(np)) {
        period_start[idx] <- sprintf("%d%02d01", year, starts[j])
        period_end[idx]   <- sprintf("%d%02d%02d", year, ends[j],
                                      month_days[ends[j]])
        idx <- idx + 1L
      }
    }
  }

  # Build result table
  rinpersoon <- spine_pers$RINPERSOON[person_idx]
  result <- data.table(
    RINPERSOON   = rinpersoon,
    period_start = period_start,
    period_end   = period_end,
    SECM         = secm,
    period_group = seq_len(n_total)
  )

  if ("RINPERSOONS" %in% names(spine_pers)) {
    result[, RINPERSOONS := spine_pers$RINPERSOONS[person_idx]]
  }

  result
}
