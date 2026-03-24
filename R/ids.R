.seq_id  <- function(n, w)    sprintf(paste0("%0", w, "d"), seq_len(n))
.rand_id <- function(n, w) {
  if (w <= 9L) {
    pool <- 10^w - 1L
    unique <- n <= pool
    if (!unique)
      warning(sprintf(".rand_id: n=%d > pool=%d for width %d; IDs will not be unique", n, pool, w))
    sprintf(paste0("%0", w, "d"), sample.int(pool, n, replace = !unique))
  } else {
    # For wide IDs, concatenate random hex chunks — vectorized via do.call(paste0, ...)
    n_chunks <- ceiling(w / 8L)
    chunks <- lapply(seq_len(n_chunks), function(j)
      sprintf("%08x", sample.int(.Machine$integer.max, n, replace = TRUE)))
    substr(do.call(paste0, chunks), 1L, w)
  }
}
# Deterministic kenteken (license plate) from RINPERSOON ----
# Same RINPERSOON always produces the same RINKENTEKEN, regardless of year
# or RNG state.  Vectorized multiplicative hash producing 32-char hex IDs.
.deterministic_kenteken <- function(rinpersoon) {
  rp_num <- as.double(rinpersoon)
  mod <- 2147483647  # 2^31 - 1
  m1 <- (rp_num * 48271 + 12345) %% mod
  m2 <- (m1 * 69069 + 1) %% mod
  m3 <- (m2 * 48271 + 56789) %% mod
  m4 <- (m3 * 69069 + 98765) %% mod
  sprintf("%08x%08x%08x%08x",
          as.integer(m1 %% .Machine$integer.max),
          as.integer(m2 %% .Machine$integer.max),
          as.integer(m3 %% .Machine$integer.max),
          as.integer(m4 %% .Machine$integer.max))
}

.rcat    <- function(n, v, p = NULL) sample(v, n, replace = TRUE, prob = p)
.yyyymmdd <- function(d) {
  lt <- as.POSIXlt(d)
  sprintf("%04d%02d%02d", lt$year + 1900L, lt$mon + 1L, lt$mday)
}
.rdate   <- function(n, from, to)
  as.Date(sample(as.integer(from):as.integer(to), n, replace = TRUE), origin = "1970-01-01")

# Map numeric WOZ values (EUR) to WOZKLASSE codes (vectorized)
.woz_to_klasse <- function(woz) {
  breaks <- c(-Inf, 150000, 250000, 350000, 450000, 550000, 650000, Inf)
  codes  <- c("1", "2", "3", "4", "5", "6", "7")
  codes[findInterval(woz, breaks)]
}

# Deterministic hashing for stable-per-identifier columns ----

# Hash character ID vector to uniform (0,1) using multiplicative hashing.
# Salt differentiates columns so the same ID gets different values per column.
.hash_to_uniform <- function(id_vec, salt) {
  mod <- 2147483647  # 2^31 - 1
  # Convert salt to a numeric seed via byte sum
  salt_bytes <- as.integer(charToRaw(salt))
  salt_num <- sum(salt_bytes * seq_along(salt_bytes)) %% mod

  # Convert character IDs to numeric: sum UTF-8 byte values in 8-char chunks
  # to avoid overflow with long hex strings
  id_num <- vapply(id_vec, function(id) {
    raw_bytes <- as.integer(charToRaw(id))
    n_bytes <- length(raw_bytes)
    total <- 0
    chunk_size <- 8L
    multiplier <- 1
    for (i in seq(1L, n_bytes, by = chunk_size)) {
      end <- min(i + chunk_size - 1L, n_bytes)
      chunk <- raw_bytes[i:end]
      chunk_val <- sum(chunk * (256^(seq_along(chunk) - 1L)))
      total <- (total + chunk_val * multiplier) %% mod
      multiplier <- (multiplier * 259) %% mod
    }
    total
  }, double(1L), USE.NAMES = FALSE)

  # Multiplicative hash combining ID and salt
  h <- (id_num * 48271 + salt_num) %% mod
  h <- (h * 69069 + 1) %% mod
  h / mod
}

# Deterministic categorical: hash IDs to pick categories via cumulative probs.
.deterministic_categorical <- function(id_vec, values, probs, salt) {
  u <- .hash_to_uniform(id_vec, salt)
  cum_p <- cumsum(probs)
  # findInterval: values in (cum_p[i-1], cum_p[i]] map to bin i
  # Shift by adding 0 prefix so bin 1 = (0, cum_p[1]]
  bins <- findInterval(u, c(0, cum_p[-length(cum_p)]), left.open = TRUE) + 1L
  bins <- pmin(bins, length(values))
  values[bins]
}

# Deterministic numeric: hash IDs to numeric values via quantile function.
.deterministic_numeric <- function(id_vec, distribution, mean = 0, sd = 1,
                                   min = -Inf, max = Inf, round = NULL,
                                   salt = "") {
  u <- .hash_to_uniform(id_vec, salt)
  if (identical(distribution, "normal")) {
    # Clamp u away from 0/1 to avoid Inf from qnorm
    u <- pmin(pmax(u, 1e-10), 1 - 1e-10)
    vals <- stats::qnorm(u, mean = mean, sd = sd)
    if (is.finite(min)) vals <- pmax(vals, min)
    if (is.finite(max)) vals <- pmin(vals, max)
  } else if (identical(distribution, "uniform")) {
    vals <- min + u * (max - min)
  } else {
    stop("Unknown distribution: ", distribution)
  }
  if (!is.null(round)) vals <- round(vals, as.integer(round))
  vals
}
