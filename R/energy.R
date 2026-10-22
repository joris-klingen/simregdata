# Dwelling-level energy use (ENERGIEVERBRUIK, ENERGIEVERBRUIKMAAND) ----
#
# Gas and electricity per dwelling follow the dwelling's characteristics as
# published in StatLine 85140NED (one-way means by dwelling type,
# construction year, floor area and number of occupants, percentiles, solar
# panels), with the national level per year from 81528NED. Parameters are
# written by energieverbruik_update_structure().
#
# The one-way means are joint targets: a multiplicative model (one factor per
# category of each characteristic) is raked on the simulated stock until every
# one-way mean matches, so the result reflects the simulated joint
# distribution of the characteristics rather than double counting their
# overlap. Lognormal noise with mean 1 adds the spread, its sd chosen to match
# the published percentiles.

# Monthly profiles (shares of the annual total, January to December)
.GAS_MONTH_P  <- c(0.170, 0.150, 0.130, 0.080, 0.050, 0.030,
                   0.025, 0.025, 0.035, 0.070, 0.110, 0.160)
.ELEK_MONTH_P <- c(0.100, 0.090, 0.090, 0.080, 0.075, 0.070,
                   0.070, 0.070, 0.075, 0.085, 0.095, 0.100)
.ZON_MONTH_P  <- c(0.020, 0.040, 0.080, 0.110, 0.130, 0.130,
                   0.130, 0.120, 0.090, 0.070, 0.030, 0.020)
# Share of delivery and feed-in in the high (daytime) tariff
.ELEK_HOOG_SHARE <- 0.55
.TERUG_HOOG_SHARE <- 0.85
# Dwellings built from this year on are mostly connected without gas
.GASLOOS_VANAF <- 2018L

# Structure for a year: the year's own 85140NED block, or the nearest one
# with its levels scaled to the year's national means (81528NED)
.energy_structure <- function(year) {
  all_params <- yaml::read_yaml(.energieverbruik_params_yaml())
  yrs <- as.integer(names(all_params))
  with_s <- yrs[vapply(all_params, function(x) !is.null(x$structuur), logical(1L))]
  if (length(with_s) == 0L)
    stop("No dwelling-level energy structure; run energieverbruik_update_structure().")
  ref <- with_s[which.min(abs(with_s - year))]
  s <- all_params[[as.character(ref)]]$structuur
  yr_p <- all_params[[as.character(yrs[which.min(abs(yrs - year))])]]
  ref_p <- all_params[[as.character(ref)]]

  # actual (not temperature-corrected) national gas use relative to the
  # corrected mean of the structure
  s$gas_actual_ratio <- as.numeric(ref_p$gas_mean) / s$totaal$gas
  if (ref != year) {
    gas_scale  <- as.numeric(yr_p$gas_mean) / as.numeric(ref_p$gas_mean)
    elek_scale <- as.numeric(yr_p$elek_mean) / as.numeric(ref_p$elek_mean)
    zon_share  <- as.numeric(yr_p$solar_pv_share %||% s$totaal$zon)
    sw_share   <- as.numeric(yr_p$stadsverwarming_pct %||% (s$totaal$stadsw * 100)) / 100
    scale_dim <- function(x, measure, f) {
      for (k in c("woningtype", "bouwjaar", "oppervlakte", "bewoners")) {
        x[[k]][[measure]] <- lapply(x[[k]][[measure]], function(v) v * f)
      }
      x$totaal[[measure]] <- x$totaal[[measure]] * f
      x
    }
    s <- scale_dim(s, "gas", gas_scale)
    s <- scale_dim(s, "elek", elek_scale)
    s <- scale_dim(s, "zon", zon_share / s$totaal$zon)
    s <- scale_dim(s, "stadsw", sw_share / s$totaal$stadsw)
    s$gas_pct  <- s$gas_pct * gas_scale
    s$elek_pct <- s$elek_pct * elek_scale
    s$zonnestroom <- lapply(s$zonnestroom, function(z) lapply(z, function(v) v * elek_scale))
  }
  s
}

# Raking of a multiplicative (or additive) model to one-way means: factors f
# such that the mean of w * f within every category comes as close as
# possible to its target. `groups` is a named list of category vectors (NA =
# no target), `targets` a named list of named target vectors, `start` the
# national mean, which is also kept as a target. The one-way targets come from
# the real stock; on a simulated stock with a different joint distribution of
# the characteristics they cannot all be met, so instead of classic raking
# (which matches the last margin exactly and cycles) every iteration applies
# the average adjustment over all margins, which converges to a compromise
# with small errors on every margin. With `additive = TRUE` the categories
# shift f by a constant instead of scaling it, which gives a less skewed
# distribution.
.rake_means <- function(w, groups, targets, start, additive = FALSE,
                        iter = 300L) {
  n <- length(w)
  groups <- c(groups, list(.totaal = rep("totaal", n)))
  targets <- c(targets, list(.totaal = c(totaal = start)))
  f <- rep(start / max(mean(w), 1e-9), n)
  for (it in seq_len(iter)) {
    step <- numeric(n)
    for (k in names(groups)) {
      g <- groups[[k]]
      m <- tapply(w * f, g, mean)
      tg <- targets[[k]][names(m)]
      adj <- if (additive) (tg - m) / tapply(w, g, mean) else log(tg / m)
      adj[!is.finite(adj)] <- 0
      hit <- !is.na(g) & g %in% names(adj)
      step[hit] <- step[hit] + adj[g[hit]]
    }
    step <- step / length(groups)
    f <- if (additive) f + step else f * exp(step)
  }
  f
}

# Raking of probabilities on the logit scale: one additive effect per category
# of each grouping, adjusted towards the target share of every category and
# the national share `start`, with the same averaged (compromise) steps as
# .rake_means(). Unlike multiplicative raking the probabilities stay within
# (0, 1).
.rake_logit <- function(groups, targets, start, iter = 300L) {
  n <- length(groups[[1L]])
  groups <- c(groups, list(.totaal = rep("totaal", n)))
  targets <- c(targets, list(.totaal = c(totaal = start)))
  eta <- rep(stats::qlogis(start), n)
  for (it in seq_len(iter)) {
    step <- numeric(n)
    for (k in names(groups)) {
      g <- groups[[k]]
      m <- tapply(stats::plogis(eta), g, mean)
      tg <- targets[[k]][names(m)]
      adj <- stats::qlogis(pmin(pmax(tg, 1e-4), 1 - 1e-4)) - stats::qlogis(m)
      adj[!is.finite(adj)] <- 0
      hit <- !is.na(g) & g %in% names(adj)
      step[hit] <- step[hit] + adj[g[hit]]
    }
    eta <- eta + step / length(groups)
  }
  stats::plogis(eta)
}

# Normal noise (truncated at zero) whose sd best matches the published
# positive percentiles
.fit_noise_additive <- function(base, pct, z, zero_share, probs = seq(0.1, 0.9, 0.1)) {
  keep <- pct > 0
  # percentiles of the positive part: shift the probabilities past the zeros
  p_pos <- (probs[keep] - zero_share) / (1 - zero_share)
  ok <- p_pos > 0
  sds <- seq(10, 1500, by = 10)
  err <- vapply(sds, function(sdv) {
    q <- stats::quantile(pmax(base + sdv * z, 0), p_pos[ok], names = FALSE)
    sum((q - pct[keep][ok])^2)
  }, numeric(1L))
  sds[which.min(err)]
}

# Lognormal noise with mean 1 whose sd best matches the ratios of the
# published percentiles (among positive values) to their median
.fit_noise <- function(base, pct, z, probs = seq(0.1, 0.9, 0.1)) {
  keep <- pct > 0
  target <- pct[keep] / stats::median(pct[keep])
  sds <- seq(0.05, 1.2, by = 0.025)
  err <- vapply(sds, function(sdv) {
    x <- base * exp(sdv * z - sdv^2 / 2)
    q <- stats::quantile(x, probs[keep], names = FALSE)
    sum((log(q / stats::median(q)) - log(target))^2)
  }, numeric(1L))
  sds[which.min(err)]
}

# Add the energy columns to an object table. `obj` holds the dwellings of the
# dataset (RINOBJECTNUMMER), `spine` the shared spine for their
# characteristics and occupants.
.build_energy <- function(obj, spine, year) {
  s <- .energy_structure(year)
  all_obj <- spine$obj_raw %||% spine$obj
  i <- match(obj$RINOBJECTNUMMER, all_obj$RINOBJECTNUMMER)
  n <- length(i)
  obj_num <- .hash_id_num(obj$RINOBJECTNUMMER)

  # characteristics in the 85140NED categories
  pers <- spine$pers
  if (!is.null(spine$pers_present)) pers <- pers[spine$pers_present]
  occ <- tabulate(match(pers$RINOBJECTNUMMER, obj$RINOBJECTNUMMER), nbins = n)
  cls <- function(x, lower) names(lower)[findInterval(x, lower)]
  bj_lower  <- stats::setNames(as.integer(names(.ENERGY_DIMS$bouwjaar)), names(.ENERGY_DIMS$bouwjaar))
  opp_lower <- stats::setNames(as.integer(names(.ENERGY_DIMS$oppervlakte)), names(.ENERGY_DIMS$oppervlakte))
  bouwjaar <- all_obj$VBOBouwjaar1Jan[i]
  # dwellings of unknown type (00, 99) are treated as terraced houses, the
  # most common type, rather than left without a dwelling-type effect
  woningtype <- all_obj$VBOWoningType1Jan[i]
  woningtype[!woningtype %in% names(.ENERGY_DIMS$woningtype)] <- "04"
  groups <- list(
    woningtype  = woningtype,
    bouwjaar    = cls(bouwjaar, bj_lower),
    oppervlakte = cls(all_obj$VBOOppervlakte1Jan[i], opp_lower),
    bewoners    = as.character(pmin(pmax(occ, 1L), 5L))
  )
  target <- function(measure, dims) {
    stats::setNames(lapply(dims, function(k) unlist(s[[k]][[measure]])), dims)
  }

  # district heating and solar panels: probabilities raked to the shares per
  # category, assigned with per-dwelling uniforms so a dwelling keeps them as
  # long as its probability does not fall
  sw_dims <- c("woningtype", "bouwjaar")
  p_sw <- .rake_logit(groups[sw_dims], target("stadsw", sw_dims), s$totaal$stadsw)
  stadsw <- .hash_mix(obj_num, "energy_stadsw") < p_sw
  zon_dims <- c("woningtype", "oppervlakte", "bewoners")
  p_zon <- .rake_logit(groups[zon_dims], target("zon", zon_dims), s$totaal$zon)
  zon <- .hash_mix(obj_num, "energy_zonpv") < p_zon

  # gas: none with district heating, mostly none in new dwellings, and as
  # many other all-electric dwellings as the published zero percentiles imply
  zero_share <- if (s$gas_pct[1L] <= 0) {
    p20 <- s$gas_pct[2L]; p30 <- s$gas_pct[3L]
    max(0.10, min(0.19, (20 - 10 * p20 / max(p30 - p20, 1)) / 100))
  } else 0
  u_gas <- .hash_mix(obj_num, "energy_gasloos")
  gasloos <- stadsw | (!is.na(bouwjaar) & bouwjaar >= .GASLOOS_VANAF & u_gas < 0.8)
  extra <- max(0, zero_share * n - sum(gasloos)) / max(1, sum(!gasloos))
  gasloos <- gasloos | (!gasloos & u_gas < extra)

  gas_dims <- c("woningtype", "bouwjaar", "oppervlakte", "bewoners")
  w_gas <- as.numeric(!gasloos)
  f_gas <- .rake_means(w_gas, groups[gas_dims], target("gas", gas_dims), s$totaal$gas,
                       additive = TRUE)
  f_gas <- pmax(f_gas, 50)
  z_gas <- stats::rnorm(n)
  sd_gas <- .fit_noise_additive(f_gas[!gasloos], s$gas_pct, z_gas[!gasloos],
                                mean(gasloos))
  gassjv <- w_gas * pmax(f_gas + sd_gas * z_gas, 0)
  gas <- gassjv * s$gas_actual_ratio

  # electricity delivery: raked on the characteristics and on solar panels
  elek_dims <- c("woningtype", "oppervlakte", "bouwjaar", "bewoners")
  el_groups <- c(list(zon = ifelse(zon, "met", "zonder")), groups[elek_dims])
  el_targets <- c(list(zon = c(met = s$zonnestroom$met$elek, zonder = s$zonnestroom$zonder$elek)),
                  target("elek", elek_dims))
  f_elek <- .rake_means(rep(1, n), el_groups, el_targets, s$totaal$elek)
  z_elek <- stats::rnorm(n)
  sd_elek <- .fit_noise(f_elek, s$elek_pct, z_elek)
  elek <- f_elek * exp(sd_elek * z_elek - sd_elek^2 / 2)

  # solar capacity (kWp, lognormal around 4 kWp, larger on larger dwellings)
  # and feed-in proportional to it, scaled so that net delivery is the
  # published share of delivery for dwellings with panels
  opp <- all_obj$VBOOppervlakte1Jan[i]
  kwp <- ifelse(zon, round(exp(log(4) + 0.3 * log(opp / 100) +
    0.35 * stats::qnorm(.hash_mix(obj_num, "energy_kwp"))), 3), 0)
  netto_share <- s$zonnestroom$met$netto / s$zonnestroom$met$elek
  terug_target <- if (any(zon)) (1 - netto_share) * mean(elek[zon]) else 0
  terug <- if (any(zon)) kwp * terug_target / mean(kwp[zon]) else rep(0, n)
  netto <- elek - terug

  # main heating: district heating without gas, all-electric, or individual
  # central heating (block heating for a share of apartments)
  blok <- groups$woningtype %in% "05" & .hash_mix(obj_num, "energy_blok") < 0.15
  hoofdverw <- data.table::fifelse(stadsw, "5",
               data.table::fifelse(gasloos, "8", data.table::fifelse(blok, "2", "1")))

  out <- data.table::copy(obj)
  cols <- list(
    STADSW           = as.character(as.integer(stadsw)),
    GAS              = round(gas),
    GASSJV           = round(gassjv),
    ELEK             = round(elek),
    ELEKTERUG        = round(terug),
    ELEKNETTO        = round(elek) - round(terug),
    ZONPV            = as.character(as.integer(zon)),
    ZONVERMOGEN1JAN  = kwp,
    ZONVERMOGEN31DEC = kwp,
    WARMTESCHATTING  = round(ifelse(stadsw, f_gas * 0.0317, 0), 1),
    HOOFDVERWARMING31DEC   = hoofdverw,
    KBHOOFDVERWARMING31DEC = sprintf("%02d", as.integer(hoofdverw))
  )
  for (m in 1:12) {
    mm <- sprintf("%02d", m)
    cols[[paste0("GASLEV", mm)]]     <- round(gas * .GAS_MONTH_P[m] / sum(.GAS_MONTH_P), 1)
    e_m <- elek * .ELEK_MONTH_P[m] / sum(.ELEK_MONTH_P)
    t_m <- terug * .ZON_MONTH_P[m] / sum(.ZON_MONTH_P)
    cols[[paste0("ELKLEV", mm)]]     <- round(e_m * .ELEK_HOOG_SHARE, 1)
    cols[[paste0("ELKLEVLAAG", mm)]] <- round(e_m * (1 - .ELEK_HOOG_SHARE), 1)
    cols[[paste0("ELKTLV", mm)]]     <- round(t_m * .TERUG_HOOG_SHARE, 1)
    cols[[paste0("ELKTLVLAAG", mm)]] <- round(t_m * (1 - .TERUG_HOOG_SHARE), 1)
  }
  for (nm in names(cols)) data.table::set(out, j = nm, value = cols[[nm]])
  out
}
