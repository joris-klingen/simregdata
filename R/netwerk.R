# Network dataset helpers ----
# Builds dyadic relation tables for burennetwerktab, colleganetwerktab,
# familienetwerktab.

.NETWERK_DATASETS <- c("burennetwerktab", "colleganetwerktab",
                        "familienetwerktab")

# Build an expanded person-pair relation table.
#
# For each person in sampled_pers, generates K random relations with other
# persons from the same sample. Returns a data.table with one row per
# relation (RINPERSOON, RINPERSOONRELATIE, RELATIE).
#
# @param sampled_pers data.table with at least a RINPERSOON column.
# @param dataset_id   One of the .NETWERK_DATASETS.
# @param year         Simulation year (for params lookup).
# @param seed         RNG seed.
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

  persons <- sampled_pers$RINPERSOON
  n_pers  <- length(persons)

  # Draw number of relations per person (Poisson, clamped to >= 1)
  n_rels <- pmax(1L, rpois(n_pers, n_rel_pp))
  total_rows <- sum(n_rels)

  # Build expanded person column (repeat each person n_rels[i] times)
  ego <- rep(persons, n_rels)

  # For each relation row, sample a partner from the pool
  # (allow self-pairing to be filtered out, then replace)
  alter <- persons[sample.int(n_pers, total_rows, replace = TRUE)]

  # Remove self-relations: resample until no self-pairs remain
  self_mask <- (ego == alter)
  n_self <- sum(self_mask)
  attempts <- 0L
  while (n_self > 0L && attempts < 10L) {
    alter[self_mask] <- persons[sample.int(n_pers, n_self, replace = TRUE)]
    self_mask <- (ego == alter)
    n_self <- sum(self_mask)
    attempts <- attempts + 1L
  }

  # Assign RELATIE codes
  relatie <- .rcat(total_rows, rel_codes, rel_probs)

  data.table(
    RINPERSOON         = ego,
    RINPERSOONRELATIE  = alter,
    RELATIE            = relatie
  )
}
