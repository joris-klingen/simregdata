# Network dataset helpers ----
# Builds dyadic relation tables for burennetwerktab, colleganetwerktab,
# familienetwerktab.
#
# Longitudinal consistency:
#   - Partner assignment is deterministic from sorted position within
#     gemeente (buren) or SBEID (collega) groups.
#   - Same person + same gemeente = same buren across years.
#   - When someone moves (spine Phase 2 housing mobility), their buren
#     change naturally because they enter a different gemeente group.
#   - Collega changes track SPOLIS job turnover (same SBEID = same colleagues).
#   - Familie uses year-invariant seed only — fully stable across years.

.NETWERK_DATASETS <- c("burennetwerktab", "colleganetwerktab",
                        "familienetwerktab")

# Build an expanded person-pair relation table.
#
# @param sampled_pers data.table with RINPERSOON + optional
#   GemeenteCodeJJJJ1Jan, SBEID.
# @param dataset_id   One of the .NETWERK_DATASETS.
# @param year         Simulation year (for params lookup).
# @param seed         RNG seed (year-invariant from sim_init Phase 1).
# @return data.table with columns: RINPERSOON, RINPERSOONRELATIE, RELATIE.
.build_netwerk_relations <- function(sampled_pers, dataset_id, year, seed) {
  set.seed(seed)

  # Load dataset params for relation counts and distribution
  ds_params <- tryCatch({
    pp <- file.path(.dataset_dir(dataset_id), "params.yaml")
    if (file.exists(pp)) {
      ap <- yaml::read_yaml(pp)
      yk <- as.character(year)
      yd <- ap[[yk]]
      if (is.null(yd)) {
        av <- sort(as.integer(names(ap)))
        yd <- ap[[as.character(av[which.min(abs(av - year))])]]
      }
      lapply(yd, function(x) if (is.list(x)) unlist(x) else x)
    }
  }, error = function(e) NULL)

  n_rel_pp <- if (!is.null(ds_params$n_relations_per_person)) {
    as.integer(ds_params$n_relations_per_person)
  } else {
    20L
  }

  rel_dist <- ds_params$relatie_dist
  rel_codes <- as.character(names(rel_dist))
  rel_probs <- as.numeric(rel_dist)

  # Dispatch to dataset-specific builder
  if (identical(dataset_id, "burennetwerktab")) {
    .build_buren_relations(sampled_pers, n_rel_pp, seed)
  } else if (identical(dataset_id, "colleganetwerktab")) {
    .build_collega_relations(sampled_pers, n_rel_pp, seed)
  } else {
    .build_random_relations(sampled_pers, n_rel_pp, rel_codes, rel_probs)
  }
}


# Buren: deterministic circular assignment within gemeente ----
# Persons are sorted by gemeente + RINPERSOON.  Each person is paired with
# the next K persons in circular order within their gemeente group.
# Offsets 1..n_buren → code 101 (Buur), rest → code 102 (Buurtgenoot).
# Deterministic: same person in same gemeente = same neighbors across years.
.build_buren_relations <- function(sampled_pers, n_rel_pp, seed) {
  set.seed(seed)

  gem_col <- sampled_pers[["GemeenteCodeJJJJ1Jan"]]
  has_gem <- !is.null(gem_col) && !all(is.na(gem_col))

  # Build work table sorted deterministically
  dt <- data.table(
    RINPERSOON = sampled_pers$RINPERSOON,
    gem = if (has_gem) as.character(gem_col) else rep("ALL", nrow(sampled_pers))
  )
  setorder(dt, gem, RINPERSOON)
  n <- nrow(dt)

  # Group metadata (vectorized)
  dt[, `:=`(gpos = seq_len(.N), gsize = .N, gstart = .I[1L]),
     by = gem]

  # Relation counts: Poisson, deterministic from seed
  n_buren <- as.integer(ceiling(n_rel_pp / 2))
  k <- pmax(1L, rpois(n, n_rel_pp))
  total <- sum(k)

  # Expand: one row per relation
  ego_row <- rep.int(seq_len(n), k)
  offs <- sequence(k)   # offset 1,2,...,k[1], 1,2,...,k[2], ...

  # Circular alter assignment within gemeente group
  gpos   <- dt$gpos[ego_row]
  gsize  <- dt$gsize[ego_row]
  gstart <- dt$gstart[ego_row]

  alter_gpos <- ((gpos - 1L + offs) %% gsize) + 1L
  alter_row  <- gstart + alter_gpos - 1L

  # Handle self-pairs (gem_size == 1: circular wraps to self)
  is_self <- (alter_row == ego_row)
  if (any(is_self)) {
    # Replace with random from global pool
    alt <- sample.int(n, sum(is_self), replace = TRUE)
    # Ensure no self
    still <- (alt == ego_row[is_self])
    if (any(still)) alt[still] <- ((ego_row[is_self][still] %% n) + 1L)
    alter_row[is_self] <- alt
  }

  # Relation codes: first n_buren offsets = 101 (Buur), rest = 102 (Buurtgenoot)
  rel <- ifelse(offs <= n_buren, "101", "102")

  data.table(
    RINPERSOON        = dt$RINPERSOON[ego_row],
    RINPERSOONRELATIE = dt$RINPERSOON[alter_row],
    RELATIE           = rel
  )
}


# Collega: deterministic circular assignment within SBEID ----
# Only employed persons (with SBEID) get colleague relations.
# Sorted by SBEID + RINPERSOON, circular assignment within employer group.
# Deterministic: same person at same employer = same colleagues across years.
.build_collega_relations <- function(sampled_pers, n_rel_pp, seed) {
  set.seed(seed)

  sbeid <- sampled_pers[["SBEID"]]
  has_sbeid <- !is.null(sbeid) && !all(is.na(sbeid))

  if (!has_sbeid) {
    # Fallback: random pairing among all persons
    return(.build_random_relations(sampled_pers, n_rel_pp, "201", 1.0))
  }

  # Only employed persons
  employed_mask <- !is.na(sbeid)
  if (sum(employed_mask) < 2L) {
    return(data.table(
      RINPERSOON = character(0L),
      RINPERSOONRELATIE = character(0L),
      RELATIE = character(0L)
    ))
  }

  dt <- data.table(
    RINPERSOON = sampled_pers$RINPERSOON[employed_mask],
    sbeid = as.character(sbeid[employed_mask])
  )
  setorder(dt, sbeid, RINPERSOON)
  n <- nrow(dt)

  # Group metadata
  dt[, `:=`(gpos = seq_len(.N), gsize = .N, gstart = .I[1L]),
     by = sbeid]

  # Relation counts
  k <- pmax(1L, rpois(n, n_rel_pp))
  total <- sum(k)

  # Expand
  ego_row <- rep.int(seq_len(n), k)
  offs <- sequence(k)

  # Circular alter within employer group
  gpos   <- dt$gpos[ego_row]
  gsize  <- dt$gsize[ego_row]
  gstart <- dt$gstart[ego_row]

  alter_gpos <- ((gpos - 1L + offs) %% gsize) + 1L
  alter_row  <- gstart + alter_gpos - 1L

  # Handle self-pairs (solo employees)
  is_self <- (alter_row == ego_row)
  if (any(is_self)) {
    alt <- sample.int(n, sum(is_self), replace = TRUE)
    still <- (alt == ego_row[is_self])
    if (any(still)) alt[still] <- ((ego_row[is_self][still] %% n) + 1L)
    alter_row[is_self] <- alt
  }

  data.table(
    RINPERSOON        = dt$RINPERSOON[ego_row],
    RINPERSOONRELATIE = dt$RINPERSOON[alter_row],
    RELATIE           = rep("201", total)
  )
}


# Random (fallback): uniform partner sampling ----
# Used for familienetwerktab and as fallback.  Year-invariant seed
# gives fully stable relations across years.
.build_random_relations <- function(sampled_pers, n_rel_pp, rel_codes,
                                    rel_probs) {
  persons <- sampled_pers$RINPERSOON
  n_pers  <- length(persons)

  n_rels <- pmax(1L, rpois(n_pers, n_rel_pp))
  total_rows <- sum(n_rels)

  ego   <- rep(persons, n_rels)
  alter <- persons[sample.int(n_pers, total_rows, replace = TRUE)]

  # Remove self-relations
  self_mask <- (ego == alter)
  n_self <- sum(self_mask)
  attempts <- 0L
  while (n_self > 0L && attempts < 10L) {
    alter[self_mask] <- persons[sample.int(n_pers, n_self, replace = TRUE)]
    self_mask <- (ego == alter)
    n_self <- sum(self_mask)
    attempts <- attempts + 1L
  }

  relatie <- .rcat(total_rows, rel_codes, rel_probs)

  data.table(
    RINPERSOON        = ego,
    RINPERSOONRELATIE = alter,
    RELATIE           = relatie
  )
}
