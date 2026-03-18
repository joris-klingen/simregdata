# Network dataset helpers ----
# Builds dyadic relation tables for burennetwerktab, colleganetwerktab,
# familienetwerktab.

.NETWERK_DATASETS <- c("burennetwerktab", "colleganetwerktab",
                        "familienetwerktab")

# Build an expanded person-pair relation table.
#
# Generates spatially/employer-clustered relations:
#   - burennetwerktab:  buren (101) from same RINOBJECTNUMMER or gemeente,
#                       buurtgenoten (102) from same gemeente
#   - colleganetwerktab: collega (201) from same SBEID, fallback to random
#   - familienetwerktab: random assignment (for now)
#
# @param sampled_pers data.table with RINPERSOON + optional GemeenteCodeJJJJ1Jan, SBEID.
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

  # Dispatch to dataset-specific builder
  if (identical(dataset_id, "burennetwerktab")) {
    .build_buren_relations(sampled_pers, n_rel_pp, rel_codes, rel_probs)
  } else if (identical(dataset_id, "colleganetwerktab")) {
    .build_collega_relations(sampled_pers, n_rel_pp)
  } else {
    .build_random_relations(sampled_pers, n_rel_pp, rel_codes, rel_probs)
  }
}


# Buren: spatially clustered neighbours ----
# Buren (101) sampled from same gemeente, buurtgenoten (102) also from same
# gemeente but a separate draw.  Falls back to random when gemeente is missing
# or too small.
.build_buren_relations <- function(sampled_pers, n_rel_pp, rel_codes, rel_probs) {
  persons <- sampled_pers$RINPERSOON
  n_pers  <- length(persons)
  gem_col <- sampled_pers[["GemeenteCodeJJJJ1Jan"]]

  # Partition: ~half buren (101), ~half buurtgenoten (102)
  n_buren <- as.integer(ceiling(n_rel_pp / 2))
  n_buurt <- n_rel_pp - n_buren

  # Pre-index persons by gemeente for fast within-group sampling
  has_gem <- !is.null(gem_col) && !all(is.na(gem_col))
  if (has_gem) {
    gem_idx <- split(seq_len(n_pers), gem_col)
    pers_gem <- as.character(gem_col)
  }

  # For each person, draw relations
  ego_list   <- vector("list", n_pers)
  alter_list <- vector("list", n_pers)
  rel_list   <- vector("list", n_pers)

  for (i in seq_len(n_pers)) {
    k_buren <- max(1L, rpois(1L, n_buren))
    k_buurt <- max(0L, rpois(1L, n_buurt))
    k_total <- k_buren + k_buurt

    if (has_gem) {
      pool <- gem_idx[[pers_gem[i]]]
      # Remove self from pool
      pool <- pool[pool != i]
    } else {
      pool <- integer(0L)
    }

    if (length(pool) >= 2L) {
      # Sample buren and buurtgenoten from same gemeente
      n_draw <- min(k_total, length(pool))
      drawn <- pool[sample.int(length(pool), n_draw, replace = n_draw > length(pool))]
      # Fill remainder from global pool if needed
      if (n_draw < k_total) {
        n_extra <- k_total - n_draw
        extra <- sample.int(n_pers, n_extra, replace = TRUE)
        extra[extra == i] <- ((i %% n_pers) + 1L)
        drawn <- c(drawn, extra)
      }
    } else {
      # Fallback: random from entire population
      drawn <- sample.int(n_pers, k_total, replace = TRUE)
      drawn[drawn == i] <- ((i %% n_pers) + 1L)
    }

    # Ensure no self-pairs
    drawn[drawn == i] <- ((i %% n_pers) + 1L)

    ego_list[[i]]   <- rep(persons[i], k_total)
    alter_list[[i]] <- persons[drawn]
    # First k_buren are buren (101), rest are buurtgenoten (102)
    rel_list[[i]]   <- c(rep("101", min(k_buren, k_total)),
                         rep("102", max(0L, k_total - k_buren)))
  }

  data.table(
    RINPERSOON        = unlist(ego_list, use.names = FALSE),
    RINPERSOONRELATIE = unlist(alter_list, use.names = FALSE),
    RELATIE           = unlist(rel_list, use.names = FALSE)
  )
}


# Collega: employer-based colleagues ----
# If SBEID is available, pairs persons who share the same employer.
# Persons without an employer get no colleague relations (matching CBS:
# only employed persons appear in COLLEGANETWERKTAB).
# Falls back to random pairing when SBEID is unavailable.
.build_collega_relations <- function(sampled_pers, n_rel_pp) {
  persons <- sampled_pers$RINPERSOON
  n_pers  <- length(persons)
  sbeid   <- sampled_pers[["SBEID"]]

  has_sbeid <- !is.null(sbeid) && !all(is.na(sbeid))

  if (!has_sbeid) {
    return(.build_random_relations(sampled_pers, n_rel_pp, "201", 1.0))
  }

  # Only employed persons (with SBEID) get colleague relations
  employed <- which(!is.na(sbeid))
  if (length(employed) < 2L) {
    return(data.table(
      RINPERSOON = character(0L),
      RINPERSOONRELATIE = character(0L),
      RELATIE = character(0L)
    ))
  }

  # Index employed persons by SBEID
  emp_sbeid <- as.character(sbeid[employed])
  sbeid_idx <- split(employed, emp_sbeid)

  ego_list   <- vector("list", length(employed))
  alter_list <- vector("list", length(employed))

  for (j in seq_along(employed)) {
    i <- employed[j]
    k <- max(1L, rpois(1L, n_rel_pp))

    # Pool: same-employer colleagues
    pool <- sbeid_idx[[emp_sbeid[j]]]
    pool <- pool[pool != i]

    if (length(pool) >= 1L) {
      # Sample from same employer, up to k
      n_same <- min(k, length(pool))
      drawn <- pool[sample.int(length(pool), n_same,
                               replace = n_same > length(pool))]
      # Fill remainder from other employed persons (different employer)
      if (n_same < k) {
        n_extra <- k - n_same
        extra <- employed[sample.int(length(employed), n_extra, replace = TRUE)]
        extra[extra == i] <- employed[((j %% length(employed)) + 1L)]
        drawn <- c(drawn, extra)
      }
    } else {
      # Solo employee: draw from all employed
      drawn <- employed[sample.int(length(employed), k, replace = TRUE)]
    }

    # Ensure no self-pairs
    drawn[drawn == i] <- employed[((j %% length(employed)) + 1L)]

    ego_list[[j]]   <- rep(persons[i], length(drawn))
    alter_list[[j]] <- persons[drawn]
  }

  data.table(
    RINPERSOON        = unlist(ego_list, use.names = FALSE),
    RINPERSOONRELATIE = unlist(alter_list, use.names = FALSE),
    RELATIE           = rep("201", sum(lengths(ego_list)))
  )
}


# Random (fallback): uniform partner sampling ----
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
