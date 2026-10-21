# Reference household type distribution (average across 2016-2024 CBS data).
# Used in Phase 1 (identity) so that the same seed always produces the same
# household structure regardless of simulation year.
.REF_TYPHH_P <- c("1"=0.381, "2"=0.073, "3"=0.205, "4"=0.055,
                   "5"=0.194, "6"=0.072, "7"=0.005, "8"=0.014)

# Fixed average household size for identity-phase N_HH calculation.
# Same n + same seed → same N_HH → same persons across years.
.FIXED_AVG_HH_SIZE <- 2.15

# Reference year for absolute birth year generation.
# Person ages are computed as simulation_year - GBAGeboorteJaar.
.REF_YEAR <- 2020L


# Minimum observations per gemeente ----
.MIN_PER_GEM <- 10L

# Categorical by inverse CDF of per-object uniforms `u` (stable counterpart of
# .rcat)
.qcat <- function(u, cats, probs) {
  cum <- cumsum(probs / sum(probs))
  cats[pmin(findInterval(u, cum) + 1L, length(cats))]
}

# Construction-year classes (BOUWJAARKLASSE codes 1-15) and their year
# bounds; the open first and last classes are closed at 1850 and 2040
.BOUWJAAR_LOWER <- c(1850L, 1905L, 1925L, 1945L, 1955L, 1965L, 1975L, 1985L,
                     1995L, 2005L, 2015L, 2020L, 2025L, 2030L, 2035L)
.BOUWJAAR_UPPER <- c(.BOUWJAAR_LOWER[-1L], 2040L)

# Floor-area classes (OPPKLASSE codes 1-6) and their bounds in m2; the open
# classes are closed at 15 and 400 m2
.OPP_LOWER <- c(15L, 50L, 75L, 100L, 150L, 250L)
.OPP_UPPER <- c(.OPP_LOWER[-1L], 400L)

# Value by inverse CDF of a piecewise-uniform distribution over classes with
# shares `p` and bounds `lower`/`upper`
.qclass_value <- function(u, p, lower, upper) {
  p <- p / sum(p)
  cum <- c(0, cumsum(p))
  k <- pmin(findInterval(u, cum), length(p))
  frac <- (u - cum[k]) / p[k]
  as.integer(floor(lower[k] + frac * (upper[k] - lower[k])))
}

# Construction year per dwelling, stable across simulation years: drawn from
# the stock distribution over the construction-year classes (bouwjaar_p). The
# objects are the same in every simulation year, so a dwelling whose year lies
# after the simulation year stands in for an older one: it gets a year from
# the stock built up to .BOUWJAAR_REMAP_YEAR (same uniform, rescaled), which
# keeps its year identical in every simulation year from then on. For earlier
# simulation years the cut-off is the simulation year itself.
.BOUWJAAR_REMAP_YEAR <- 2010L

.stable_bouwjaar <- function(u, p, year) {
  p <- p / sum(p)
  b <- .qclass_value(u, p, .BOUWJAAR_LOWER, .BOUWJAAR_UPPER)
  late <- b > year
  if (any(late)) {
    # share of the stock built up to and including `cutoff`
    cutoff <- min(year, .BOUWJAAR_REMAP_YEAR)
    cum <- c(0, cumsum(p))
    k <- findInterval(cutoff + 1L, .BOUWJAAR_LOWER)
    f_cut <- cum[k] + p[k] * (cutoff + 1L - .BOUWJAAR_LOWER[k]) /
      (.BOUWJAAR_UPPER[k] - .BOUWJAAR_LOWER[k])
    b[late] <- pmin(.qclass_value(u[late] * f_cut, p, .BOUWJAAR_LOWER, .BOUWJAAR_UPPER),
                    cutoff)
  }
  b
}

# Gemeente per object, stable across simulation years: weighted rendezvous
# hashing. Each object takes the gemeente with the lowest -log(h) / p, where
# h hashes the (object, gemeente) pair, which draws gemeenten in proportion to
# p. A change in the shares or a gemeente merger only moves objects into or
# out of the gemeenten concerned; a cumulative (inverse-CDF) allocation would
# shift every gemeente after the change. To keep the cost at about
# N x (32 + G / 32) hashes, gemeenten are grouped into 32 fixed buckets by
# their code and the same rendezvous picks the bucket first. Shares are raised
# to at least min_n / N so small gemeenten keep about `min_n` objects in
# small samples.
.stable_gemeente <- function(obj_id, codes, probs, min_n = .MIN_PER_GEM,
                             n_buckets = 32L) {
  n <- length(obj_id)
  probs <- pmax(probs / sum(probs), min_n / n)
  probs <- probs / sum(probs)
  bucket <- 1L + as.integer(floor(.hash_to_uniform(codes, "gem_bucket") * n_buckets))
  w_bucket <- vapply(seq_len(n_buckets), function(b) sum(probs[bucket == b]), numeric(1L))
  obj_bucket <- .rendezvous(obj_id, seq_len(n_buckets), w_bucket, "obj_gem_bucket")

  code_num <- .hash_id_num(codes)
  out <- character(n)
  for (b in unique(obj_bucket)) {
    idx <- which(obj_bucket == b)
    g <- which(bucket == b)
    out[idx] <- codes[g][.rendezvous(obj_id[idx], code_num[g], probs[g], "obj_gem")]
  }
  out
}

# Weighted rendezvous: for each object the index of the candidate with the
# lowest -log(h) / weight, h hashing the (object, candidate key) pair
.rendezvous <- function(obj_id, keys, weights, salt) {
  mod <- 2147483647
  obj_h <- floor(.hash_mix(obj_id, salt) * mod)
  key_h <- floor(.hash_mix(as.double(keys), paste0(salt, "_key")) * mod)
  best <- rep(Inf, length(obj_id))
  pick <- integer(length(obj_id))
  for (j in seq_along(keys)) {
    if (weights[j] <= 0) next
    h <- .hash_pair(obj_h, key_h[j])
    score <- -log(h) / weights[j]
    better <- score < best
    best[better] <- score[better]
    pick[better] <- j
  }
  pick
}

# Gemeente-conditional categorical sampling ----
# Adjusts one target category's probability per gemeente while preserving
# the relative shares of all other categories.
# @param n Total number of draws.
# @param gem Character vector of gemeente codes (length n).
# @param base_p Named probability vector (national distribution).
# @param gem_target Named numeric vector: gem_code -> target category share
#   (e.g., apartment share per gemeente). NULL falls back to national i.i.d.
# @param target_cat Name of the category to adjust (e.g., "05" for apartments).
# @return Character vector of length n.
.rcat_gem_adjusted <- function(n, gem, base_p, gem_target, target_cat, u = NULL) {
  draw <- function(idx, p) {
    if (is.null(u)) .rcat(length(idx), names(p), p) else .qcat(u[idx], names(p), p)
  }
  if (is.null(gem_target)) {
    return(draw(seq_len(n), base_p))
  }

  cat_names <- names(base_p)
  nat_target <- base_p[[target_cat]]
  nat_other  <- base_p[cat_names != target_cat]
  other_sum  <- sum(nat_other)

  result <- character(n)
  for (g in unique(gem)) {
    mask <- which(gem == g)
    n_g <- length(mask)
    local_share <- gem_target[g]
    if (is.na(local_share)) local_share <- nat_target
    # Clamp to (0, 1) to avoid degenerate probabilities
    local_share <- max(0.001, min(0.999, local_share))
    local_p <- base_p
    local_p[[target_cat]] <- local_share
    local_p[cat_names != target_cat] <- nat_other * ((1 - local_share) / other_sum)
    result[mask] <- draw(mask, local_p)
  }
  result
}


.build_spine <- function(n_persons, params, seed, year) {
  year <- as.integer(year)
  t0 <- proc.time()[["elapsed"]]
  .stage <- function(i, n, label) {
    message(sprintf("  [%d/%d] %s ...", i, n, label))
  }

  jan1  <- as.Date(paste0(year, "-01-01"))
  dec31 <- as.Date(paste0(year, "-12-31"))

  N_HH <- round(n_persons / .FIXED_AVG_HH_SIZE)
  N_OBJ <- N_HH

  message(sprintf("  Building spine: %s persons / %s households / %s objects",
                  format(n_persons, big.mark=","),
                  format(N_HH, big.mark=","),
                  format(N_OBJ, big.mark=",")))

  # ==== PHASE 1: Year-invariant identity =====================================
  # Same seed always produces the same persons, IDs, birth years, sex,
  # household structure — regardless of simulation year.
  set.seed(seed)

  # ---- Objects (identity) ----
  .stage(1L, 3L, "Objects")

  dt_obj <- data.table::data.table(
    RINOBJECTNUMMER   = .rand_id(N_OBJ, 16L),
    SOORTOBJECTNUMMER = .rcat(N_OBJ, names(params$soortobj_p), params$soortobj_p)
  )

  # ---- Households (identity) ----
  .stage(2L, 3L, "Households")
  dt_hh <- data.table::data.table(
    HUISHOUDNR        = .seq_id(N_HH, 12L),
    TYPHH             = .rcat(N_HH, names(.REF_TYPHH_P), .REF_TYPHH_P),
    IMPUTATIECODEHH   = .rcat(N_HH, c("0","1"), c(0.95,0.05)),
    DATUMAANVANGHH    = .yyyymmdd(.rdate(N_HH, as.Date("2005-01-01"),
                                         as.Date("2020-01-01"))),
    RINOBJECTNUMMER   = dt_obj$RINOBJECTNUMMER,   # 1:1 mapping (simplified)
    SOORTOBJECTNUMMER = dt_obj$SOORTOBJECTNUMMER
  )

  dt_hh[TYPHH=="1",               HHSize := 1L]
  dt_hh[TYPHH %in% c("2","3"),    HHSize := 2L]
  dt_hh[TYPHH %in% c("4","5"),    HHSize := 2L + sample(1:3, .N, replace=TRUE, prob=c(0.50,0.35,0.15))]
  dt_hh[TYPHH=="6",               HHSize := 1L + sample(1:3, .N, replace=TRUE, prob=c(0.55,0.30,0.15))]
  dt_hh[TYPHH=="7",               HHSize := sample(2:5, .N, replace=TRUE)]
  dt_hh[TYPHH=="8",               HHSize := sample(5:25,.N, replace=TRUE)]
  dt_hh[, NKids := data.table::fcase(
    TYPHH %in% c("4","5"), pmax(0L, HHSize - 2L),
    TYPHH == "6",           pmax(0L, HHSize - 1L),
    default = 0L)]
  data.table::setkey(dt_hh, HUISHOUDNR)

  # ---- Persons (identity) ----
  .stage(3L, 3L, "Persons")
  # Expand: repeat each HH row once per person it contains
  dt_pers <- dt_hh[rep(seq_len(N_HH), times = dt_hh$HHSize)]
  dt_pers[, rank := data.table::rowid(HUISHOUDNR)]
  N_PERS_actual <- nrow(dt_pers)

  # PLHH (positie in huishouden) derived from TYPHH and rank within household
  dt_pers[, PLHH := data.table::fcase(
    TYPHH == "1",                       "2",   # alleenstaande
    TYPHH == "2",                       "3",   # niet-geh paar z.k.
    TYPHH == "3",                       "4",   # geh paar z.k.
    TYPHH == "4" & rank <= 2L,          "5",   # niet-geh paar m.k. -- partners
    TYPHH == "5" & rank <= 2L,          "6",   # geh paar m.k. -- partners
    TYPHH %in% c("4","5") & rank > 2L,  "1",   # kinderen
    TYPHH == "6" & rank == 1L,          "7",   # eenouder
    TYPHH == "6" & rank > 1L,           "1",   # kinderen
    TYPHH == "7" & rank == 1L,          "8",   # ref overig huishouden
    TYPHH == "7" & rank > 1L,           "9",   # overig lid
    TYPHH == "8",                       "10"   # institutioneel lid
  )]

  # Reference person: first in non-institutional HH; all institutional = "9"
  dt_pers[, REFPERSOONHH := data.table::fcase(
    TYPHH == "8",  "9",
    rank == 1L,    "1",
    default =      "0"
  )]

  # Birth year: absolute (year-invariant) using REF_YEAR as anchor.
  # Age in any simulation year = year - GBAGeboorteJaar.
  dt_pers[,            GBAGeboorteJaar := .REF_YEAR - sample(20L:75L, .N, replace = TRUE)]
  dt_pers[PLHH == "1", GBAGeboorteJaar := .REF_YEAR - sample(0L:17L,  .N, replace = TRUE)]
  dt_pers[TYPHH == "8", GBAGeboorteJaar := .REF_YEAR - sample(20L:85L, .N, replace = TRUE)]

  # Civil status by position in household
  dt_pers[,                          GBABurgerlijkeStaat := .rcat(.N, c("O","H","S","W"), c(0.55,0.30,0.08,0.07))]
  dt_pers[PLHH %in% c("4","6"),     GBABurgerlijkeStaat := .rcat(.N, c("H","P"), c(0.90,0.10))]
  dt_pers[PLHH == "1",              GBABurgerlijkeStaat := "O"]

  dt_pers[, GBAGeslachtsAanduiding := .rcat(N_PERS_actual, names(params$geslacht_p), params$geslacht_p)]
  dt_pers[, RINPERSOON  := .rand_id(N_PERS_actual, 9L)]
  dt_pers[, RINPERSOONS := "R"]
  dt_pers[, AanvangWoonduur := .yyyymmdd(.rdate(N_PERS_actual,
                                                 as.Date("2005-01-01"),
                                                 as.Date("2020-01-01")))]

  # Drop internal HH expansion columns not needed on persons
  dt_pers[, c("HHSize", "NKids", "rank") := NULL]

  # Lightweight aggregation (identity-phase: person counts are year-invariant)
  dt_pers[, AantalPersonenPerHuishouden := .N, by = HUISHOUDNR]
  dt_pers[, AantalKinderenPerHuishouden := sum(PLHH == "1"), by = HUISHOUDNR]
  hh_sz <- unique(dt_pers[, .(HUISHOUDNR, AantalPersonenPerHuishouden,
                               AantalKinderenPerHuishouden)])
  agg_cols <- c("AantalPersonenPerHuishouden", "AantalKinderenPerHuishouden")
  dt_hh[hh_sz, (agg_cols) := mget(agg_cols), on = "HUISHOUDNR"]

  # ---- Life course (identity-phase, year-invariant) ----
  # Assign each person a deterministic birth/death/migration profile from their
  # RINPERSOON so panels become unbalanced across years while staying
  # reproducible. Runs after all Phase 1 random draws so the RNG stream is
  # unchanged; see R/demographics.R.
  .assign_life_events(dt_pers, .REF_YEAR)


  # ==== PHASE 2: Year-specific attributes ====================================
  # Year-dependent seed: same person gets different gemeente, WOZ, indicators
  # each simulation year, but persons themselves are stable.
  set.seed(seed + year * 1000L)

  # ---- Object attributes (stable per dwelling) ----
  woz_sd <- 0.45

  # Dwelling attributes are drawn from per-dwelling uniforms (hashes of
  # RINOBJECTNUMMER) through this year's distributions, so a dwelling keeps its
  # attributes on 1 January and 31 December and, as far as the distributions
  # allow, across simulation years. Classes are derived from the values.
  obj_id <- .hash_id_num(dt_obj$RINOBJECTNUMMER)
  u_obj <- function(salt) .hash_mix(obj_id, paste0("obj_", salt))

  gem <- .stable_gemeente(obj_id, params$gem_codes, params$gem_probs)
  wijk <- paste0(gem, sprintf("%02d", 1L + floor(u_obj("wijk") * 20)))
  buurt <- paste0(gem, sprintf("%04d", 1L + floor(u_obj("buurt") * 200)))
  vslsoort <- .qcat(u_obj("vslsoort"), names(params$vslsoort_p), params$vslsoort_p)

  # VBOWoningType and TypeEigenaar: gemeente-conditional apartment and
  # owner-occupied shares
  woningtype <- .rcat_gem_adjusted(N_OBJ, gem, params$woningtype_p,
    params$gem_pct_apartment, "05", u = u_obj("woningtype"))
  eigenaar <- .rcat_gem_adjusted(N_OBJ, gem, params$eigenaar_p,
    params$gem_pct_owner, "E", u = u_obj("eigenaar"))

  bouwjaar <- .stable_bouwjaar(u_obj("bouwjaar"), params$bouwjaar_p, year)
  bouwjaar_klasse <- as.character(findInterval(bouwjaar, .BOUWJAAR_LOWER))
  opp_p <- params$opp_p[names(params$opp_p) != "9"]
  opp_vec <- .qclass_value(u_obj("oppervlakte"), opp_p, .OPP_LOWER, .OPP_UPPER)
  opp_klasse <- as.character(findInterval(opp_vec, .OPP_LOWER))

  # WOZ: per-municipality mean from StatLine, conditional on dwelling size
  if (!is.null(params$woz_gem_means)) {
    woz_mean <- params$woz_gem_means[gem]
    woz_mean[is.na(woz_mean)] <- params$woz_national_mean
    woz_mu <- log(woz_mean) - woz_sd^2 / 2
  } else {
    woz_mu <- rep(log(params$woz_national_mean) - woz_sd^2 / 2, N_OBJ)
  }
  woz_mu <- woz_mu + 0.8 * log(opp_vec / 85)
  woz_val <- round(stats::qlnorm(u_obj("woz"), woz_mu, woz_sd * 0.7), -3L)

  vbostatus <- .qcat(u_obj("vbostatus"), c("3", "4", "6"), c(0.10, 0.85, 0.05))
  aanwezig <- .qcat(u_obj("aanwezig"), c("0", "1"), c(0.02, 0.98))
  nieuwbouw <- data.table::fifelse(bouwjaar == year, "1", "0")

  for (sfx in c("1Jan", "31Dec")) {
    data.table::set(dt_obj, j = paste0("GemeenteCodeJJJJ",          sfx), value = gem)
    data.table::set(dt_obj, j = paste0("WijkCodeJJJJ",              sfx), value = wijk)
    data.table::set(dt_obj, j = paste0("BuurtCodeJJJJ",             sfx), value = buurt)
    data.table::set(dt_obj, j = paste0("VSLSoort",                  sfx), value = vslsoort)
    data.table::set(dt_obj, j = paste0("VBOBouwJaarKlasse",         sfx), value = bouwjaar_klasse)
    data.table::set(dt_obj, j = paste0("VBOOppervlakteKlasse",      sfx), value = opp_klasse)
    data.table::set(dt_obj, j = paste0("VBOWoningType",             sfx), value = woningtype)
    data.table::set(dt_obj, j = paste0("TypeEigenaar",              sfx), value = eigenaar)
    data.table::set(dt_obj, j = paste0("VBOBouwjaar",               sfx), value = bouwjaar)
    data.table::set(dt_obj, j = paste0("VBOOppervlakte",            sfx), value = opp_vec)
    data.table::set(dt_obj, j = paste0("WOZWaardeObjectBAG",        sfx), value = woz_val)
    data.table::set(dt_obj, j = paste0("WOZWaardeObjectBAGKlasse",  sfx), value = .woz_to_klasse(woz_val))
    data.table::set(dt_obj, j = paste0("VBOStatus",                 sfx), value = vbostatus)
    data.table::set(dt_obj, j = paste0("Indicator_VBOIsNieuwbouw",  sfx), value = nieuwbouw)
    data.table::set(dt_obj, j = paste0("Indicator_VBOIsAanwezig",   sfx), value = aanwezig)
    data.table::set(dt_obj, j = paste0("Indicator_VSLIsAanwezig",   sfx), value = "1")
  }
  dt_obj[, PandID1Jan := strrep("9", 16L)]
  dt_obj[VBOWoningType1Jan == "05", PandID1Jan := .rand_id(.N, 16L)]
  dt_obj[, PandID31Dec := PandID1Jan]
  dt_obj[, Indicator_VBOIsGesloopt      := .rcat(.N, c("-","0","1"), c(0.01,0.98,0.01))]
  dt_obj[, Indicator_VBOIsTransformatie := .rcat(.N, c("-","0","1"), c(0.01,0.985,0.005))]
  dt_obj[, Indicator_VBOIsNieuwbouw     := nieuwbouw]
  dt_obj[, Indicator_VSLIsOntrokken     := .rcat(.N, c("-","0","1"), c(0.01,0.985,0.005))]
  dt_obj[, Indicator_VSLIsNieuw         := .rcat(.N, c("-","0","1"), c(0.01,0.97,0.02))]
  data.table::setkey(dt_obj, RINOBJECTNUMMER)

  # ---- Housing mobility (year-varying) ----
  # ~6% of households move to a different object each year.
  # Movers swap RINOBJECTNUMMER among themselves so every object stays occupied.
  move_rate <- 0.06
  n_movers <- max(2L, round(N_HH * move_rate))
  mover_idx <- sample.int(N_HH, n_movers)

  # Shuffle objects among movers (circular permutation: no one stays in place)
  mover_obj <- dt_hh[["RINOBJECTNUMMER"]][mover_idx]
  shifted <- c(mover_obj[-1L], mover_obj[1L])
  data.table::set(dt_hh, i = mover_idx, j = "RINOBJECTNUMMER", value = shifted)
  data.table::set(dt_hh, i = mover_idx, j = "SOORTOBJECTNUMMER",
    value = dt_obj[["SOORTOBJECTNUMMER"]][match(shifted, dt_obj[["RINOBJECTNUMMER"]])])

  # Propagate new object to persons in moved households
  moved_hh <- dt_hh[["HUISHOUDNR"]][mover_idx]
  pers_in_moved <- dt_pers[["HUISHOUDNR"]] %in% moved_hh
  dt_pers[pers_in_moved, RINOBJECTNUMMER := dt_hh[["RINOBJECTNUMMER"]][
    match(dt_pers[["HUISHOUDNR"]][pers_in_moved], dt_hh[["HUISHOUDNR"]])]]
  dt_pers[pers_in_moved, SOORTOBJECTNUMMER := dt_hh[["SOORTOBJECTNUMMER"]][
    match(dt_pers[["HUISHOUDNR"]][pers_in_moved], dt_hh[["HUISHOUDNR"]])]]

  # ---- Person indicators (year-varying) ----
  # Set Indicator_PersoonIsVerhuisd based on actual movers
  dt_pers[, Indicator_PersoonIsVerhuisd := as.character(as.integer(pers_in_moved))]

  # Administrative indicators: small independent random flags, not tied to the
  # life course.
  admin_specs <- list(
    c("Indicator_PersoonIsAdministratiefAfgevoerd", 0.002),
    c("Indicator_PersoonIsAdministratiefOpgenomen", 0.002)
  )
  for (sp in admin_specs) {
    data.table::set(dt_pers, j = sp[[1L]],
      value = as.character(rbinom(N_PERS_actual, 1L, as.numeric(sp[[2L]]))))
  }

  # Life-event indicators: derived deterministically from each person's
  # entry/exit years (births, deaths, migration) rather than drawn
  # independently, so they stay consistent across years. `present` marks the
  # persons who belong to this year's population snapshot.
  demog <- .demographic_indicators(dt_pers, year)
  pers_present <- demog$present
  for (nm in setdiff(names(demog), "present")) {
    data.table::set(dt_pers, j = nm, value = demog[[nm]])
  }

  # AantalKeerVerhuisd: based on actual movers
  dt_pers[, AantalKeerVerhuisd := 0L]
  dt_pers[Indicator_PersoonIsVerhuisd == "1",
    AantalKeerVerhuisd := sample(1:3, .N, replace = TRUE, prob = c(0.80, 0.15, 0.05))]

  # ---- Income & wealth (year-varying, correlated with WOZ) ----
  woz <- dt_obj$WOZWaardeObjectBAG1Jan
  woz_rank <- data.table::frank(woz, ties.method = "random") / (N_HH + 1)

  # Disposable, gross, primary and standardised income: lognormal per
  # household type (and AOW age of the reference person), calibrated to
  # StatLine 83932NED and correlated with WOZ (R/params_inhatab.R)
  ref_age <- dt_pers[dt_pers[, .I[1L], by = HUISHOUDNR]$V1,
                     .(HUISHOUDNR, age = year - GBAGeboorteJaar)]
  hh_age <- ref_age$age[match(dt_hh$HUISHOUDNR, ref_age$HUISHOUDNR)]
  hh_age[is.na(hh_age)] <- 45L
  inc <- .simulate_hh_income(dt_hh$TYPHH, hh_age, woz_rank, year)
  for (nm in names(inc)) data.table::set(dt_hh, j = nm, value = inc[[nm]])

  # BELIH: taxable income (higher than disposable)
  dt_hh[, BELIH := as.integer(round(BESTINKH * stats::runif(.N, 1.1, 1.4), -2L))]

  # VERMHH: household wealth — correlated with WOZ rank, wider distribution
  verm_rank <- pmax(0.001, pmin(0.999, woz_rank + stats::rnorm(N_HH, 0, 0.15)))
  dt_hh[, VERMHH := as.integer(round(
    stats::qlnorm(verm_rank, meanlog = 11.0, sdlog = 0.8) - 50000, -2L))]

  # VROMHH: freely available wealth (fraction of total)
  dt_hh[, VROMHH := as.integer(round(VERMHH * stats::runif(.N, 0.3, 0.8), -2L))]

  # Percentile ranks (1-100)
  dt_hh[, P100HBEST := as.integer(ceiling(
    data.table::frank(BESTINKH, ties.method = "random") / .N * 100))]
  dt_hh[, P100HGEST := as.integer(ceiling(
    data.table::frank(GESTINKH, ties.method = "random") / .N * 100))]
  dt_hh[, P100HBRUT := as.integer(ceiling(
    data.table::frank(BRUTINKH, ties.method = "random") / .N * 100))]
  dt_hh[, P100HPRIM := as.integer(ceiling(
    data.table::frank(PRIMINKH, ties.method = "random") / .N * 100))]
  dt_hh[, P100HVERM := as.integer(ceiling(
    data.table::frank(VERMHH, ties.method = "random") / .N * 100))]
  dt_hh[, P100WELVAART := as.integer(ceiling(data.table::frank(
    data.table::frank(BESTINKH) + data.table::frank(VERMHH),
    ties.method = "random") / .N * 100))]

  # Reference persons (precomputed for lazy hh/obj enrichment)
  dt_ref <- dt_pers[dt_pers[, .I[1L], by = HUISHOUDNR]$V1]
  dt_ref[, LeeftijdRefPersoon := as.integer(year - GBAGeboorteJaar)]

  # Lightweight gemeente lookup for weighted sampling (avoids full obj->pers join)
  pers_gemeente <- dt_obj$GemeenteCodeJJJJ1Jan[
    match(dt_pers$RINOBJECTNUMMER, dt_obj$RINOBJECTNUMMER)]

  elapsed <- proc.time()[["elapsed"]] - t0
  message(sprintf("  Spine ready: %s persons, %s households, %s objects (%.1f s)",
                  format(N_PERS_actual, big.mark=","),
                  format(N_HH, big.mark=","),
                  format(N_OBJ, big.mark=","),
                  elapsed))

  list(pers = dt_pers, hh = dt_hh, obj = dt_obj,
       obj_raw = dt_obj, dt_ref = dt_ref,
       pers_gemeente = pers_gemeente,
       pers_present = pers_present,
       year = year, jan1 = jan1, dec31 = dec31,
       pers_spatial_enriched = FALSE,
       hh_enriched = FALSE,
       obj_enriched = FALSE)
}


# Columns added to dt_pers by the obj->pers spatial join
.PERS_SPATIAL_PREFIXES <- c(
  "GemeenteCodeJJJJ", "WijkCodeJJJJ", "BuurtCodeJJJJ",
  "VSLSoort", "TypeEigenaar", "VBOWoningType",
  "VBOBouwJaarKlasse", "VBOOppervlakteKlasse", "WOZWaardeObjectBAGKlasse")

# Check if a file spec needs pers_spatial enrichment
.spec_needs_pers_spatial <- function(spec) {
  if (spec$spine_table != "pers") return(FALSE)
  pats <- paste0("spine.pers.", .PERS_SPATIAL_PREFIXES)
  for (cs in c(spec$columns, spec$pre_compute)) {
    if (is.null(cs$source)) next
    for (p in pats) {
      if (startsWith(cs$source, p)) return(TRUE)
    }
  }
  FALSE
}

# Columns added to dt_hh by hh enrichment (ref-person + object merge)
.HH_ENRICHED_PREFIXES <- c(
  "RINPERSOON_Ref", "RINPERSOONS_Ref", "REFPERSOONHH_Ref",
  "PLHH_Ref", "GBAGeslachtsAanduiding_Ref", "LeeftijdRefPersoon",
  "VSLSoort", "WOZWaardeObjectBAGKlasse", "VBOBouwJaarKlasse",
  "VBOOppervlakteKlasse", "VBOWoningType", "TypeEigenaar", "GemeenteCodeJJJJ")

# Check if a file spec needs hh enrichment
.spec_needs_hh_enriched <- function(spec) {
  if (spec$spine_table != "hh") return(FALSE)
  pats <- paste0("spine.hh.", .HH_ENRICHED_PREFIXES)
  for (cs in c(spec$columns, spec$pre_compute)) {
    if (is.null(cs$source)) next
    for (p in pats) {
      if (startsWith(cs$source, p)) return(TRUE)
    }
  }
  FALSE
}

# Columns added to dt_obj by obj enrichment (kids + ref-person merge)
.OBJ_ENRICHED_COLS <- c(
  "AantalKinderenPerVSL", "LeeftijdJongsteKindPerVSL", "AantalPersonenPerVSL",
  "HUISHOUDNR", "DATUMAANVANGHH", "TYPHH", "AantalPersonenPerHuishouden",
  "RINPERSOON_Ref2", "RINPERSOONS_Ref2")

# Check if a file spec needs obj enrichment
.spec_needs_obj_enriched <- function(spec) {
  if (spec$spine_table != "obj") return(FALSE)
  pats <- paste0("spine.obj.", .OBJ_ENRICHED_COLS)
  for (cs in c(spec$columns, spec$pre_compute)) {
    if (is.null(cs$source)) next
    for (p in pats) {
      if (startsWith(cs$source, p)) return(TRUE)
    }
  }
  FALSE
}


# Lazy enrichment: build enriched spine tables on first access
.ensure_enriched <- function(which) {
  spine <- .sim_cache$spine
  if (is.null(spine)) stop("Spine not initialized")

  if (which == "pers_spatial" && !isTRUE(spine$pers_spatial_enriched)) {
    message("  [lazy] Object \u2192 person spatial join ...")
    dt_obj <- spine$obj_raw
    obj_value_cols <- c(
      paste0(c("GemeenteCodeJJJJ","WijkCodeJJJJ","BuurtCodeJJJJ","VSLSoort",
               "TypeEigenaar","VBOWoningType","VBOBouwJaarKlasse",
               "VBOOppervlakteKlasse","WOZWaardeObjectBAGKlasse"), "1Jan"),
      paste0(c("GemeenteCodeJJJJ","WijkCodeJJJJ","BuurtCodeJJJJ","VSLSoort",
               "TypeEigenaar","VBOWoningType","VBOBouwJaarKlasse",
               "VBOOppervlakteKlasse","WOZWaardeObjectBAGKlasse"), "31Dec"))
    spine$pers[dt_obj, (obj_value_cols) := mget(obj_value_cols),
               on = "RINOBJECTNUMMER"]
    spine$pers_spatial_enriched <- TRUE
  }

  if (which == "hh" && !isTRUE(spine$hh_enriched)) {
    message("  [lazy] Household enrichment (ref-person + object) ...")
    dt_ref <- spine$dt_ref
    dt_obj <- spine$obj_raw
    dt_hh  <- spine$hh

    # Join ref-person columns onto hh by reference
    ref_for_hh <- dt_ref[, .(HUISHOUDNR,
      RINPERSOON_Ref = RINPERSOON, RINPERSOONS_Ref = RINPERSOONS,
      REFPERSOONHH_Ref = REFPERSOONHH,
      PLHH_Ref = PLHH, GBAGeslachtsAanduiding_Ref = GBAGeslachtsAanduiding,
      LeeftijdRefPersoon)]
    ref_cols <- c("RINPERSOON_Ref", "RINPERSOONS_Ref", "REFPERSOONHH_Ref",
                  "PLHH_Ref", "GBAGeslachtsAanduiding_Ref", "LeeftijdRefPersoon")
    dt_hh[ref_for_hh, (ref_cols) := mget(ref_cols), on = "HUISHOUDNR"]

    # Join object columns onto hh by reference
    obj_value_cols <- c(
      paste0(c("VSLSoort","WOZWaardeObjectBAGKlasse","VBOBouwJaarKlasse",
               "VBOOppervlakteKlasse","VBOWoningType","TypeEigenaar",
               "GemeenteCodeJJJJ"), "1Jan"),
      paste0(c("VSLSoort","WOZWaardeObjectBAGKlasse","VBOBouwJaarKlasse",
               "VBOOppervlakteKlasse","VBOWoningType","TypeEigenaar",
               "GemeenteCodeJJJJ"), "31Dec"))
    dt_hh[dt_obj, (obj_value_cols) := mget(obj_value_cols),
           on = "RINOBJECTNUMMER"]

    spine$hh <- dt_hh
    spine$hh_enriched <- TRUE
  }

  if (which == "obj" && !isTRUE(spine$obj_enriched)) {
    message("  [lazy] Object enrichment (kids + ref-person) ...")
    dt_pers <- spine$pers
    dt_obj  <- data.table::copy(spine$obj_raw)
    dt_ref  <- spine$dt_ref
    year    <- spine$year

    # Count occupancy over the persons present in the simulation year so that
    # not-yet-born or departed persons do not inflate per-object counts (and so
    # youngest-child age stays non-negative). See R/demographics.R.
    occ_pers <- if (!is.null(spine$pers_present)) {
      dt_pers[spine$pers_present]
    } else {
      dt_pers
    }

    obj_kids <- occ_pers[, .(
      AantalKinderenPerVSL = sum(PLHH == "1"),
      LeeftijdJongsteKindPerVSL = if (any(PLHH == "1"))
        min(as.integer(year) - GBAGeboorteJaar[PLHH == "1"]) else 99L,
      AantalPersonenPerVSL = .N
    ), by = RINOBJECTNUMMER]

    # Join kids aggregation onto obj by reference
    kids_cols <- c("AantalKinderenPerVSL", "LeeftijdJongsteKindPerVSL",
                   "AantalPersonenPerVSL")
    dt_obj[obj_kids, (kids_cols) := mget(kids_cols), on = "RINOBJECTNUMMER"]
    dt_obj[is.na(AantalKinderenPerVSL), AantalKinderenPerVSL := 0L]
    dt_obj[is.na(LeeftijdJongsteKindPerVSL), LeeftijdJongsteKindPerVSL := 99L]
    dt_obj[is.na(AantalPersonenPerVSL), AantalPersonenPerVSL := 0L]

    # Join ref-person columns onto obj by reference
    ref_for_obj <- dt_ref[, .(RINOBJECTNUMMER,
      HUISHOUDNR, DATUMAANVANGHH, TYPHH, AantalPersonenPerHuishouden,
      RINPERSOON_Ref2 = RINPERSOON, RINPERSOONS_Ref2 = RINPERSOONS)]
    ref_cols <- c("HUISHOUDNR", "DATUMAANVANGHH", "TYPHH",
                  "AantalPersonenPerHuishouden",
                  "RINPERSOON_Ref2", "RINPERSOONS_Ref2")
    dt_obj[ref_for_obj, (ref_cols) := mget(ref_cols), on = "RINOBJECTNUMMER"]

    spine$obj <- dt_obj
    spine$obj_enriched <- TRUE
  }

  .sim_cache$spine <- spine
  .wb$spine <- spine
  spine
}
