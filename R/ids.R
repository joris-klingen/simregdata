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
  .hash_mix(.hash_id_num(id_vec), salt)
}

# Numeric form of character IDs for .hash_mix(). Split out so callers that
# need several salts for the same IDs convert them only once.
.hash_id_num <- function(id_vec) {
  mod <- 2147483647  # 2^31 - 1
  # Convert character IDs to numeric: sum UTF-8 byte values in 8-char chunks
  # to avoid overflow with long hex strings. Vectorised per ID length: the
  # bytes of all IDs of one length form a matrix with one column per ID.
  id_vec <- as.character(id_vec)
  out <- numeric(length(id_vec))
  len <- nchar(id_vec, type = "bytes")
  for (n_bytes in unique(len)) {
    idx <- which(len == n_bytes)
    if (n_bytes == 0L) next
    bytes <- matrix(as.integer(charToRaw(paste(id_vec[idx], collapse = ""))),
                    nrow = n_bytes)
    total <- numeric(length(idx))
    multiplier <- 1
    for (i in seq(1L, n_bytes, by = 8L)) {
      rows <- i:min(i + 7L, n_bytes)
      chunk_val <- colSums(bytes[rows, , drop = FALSE] * (256^(seq_along(rows) - 1L)))
      total <- (total + chunk_val * multiplier) %% mod
      multiplier <- (multiplier * 259) %% mod
    }
    out[idx] <- total
  }
  out
}

# Uniform (0,1) from numeric IDs (see .hash_id_num()) and a salt
.hash_mix <- function(id_num, salt) {
  mod <- 2147483647  # 2^31 - 1
  # Convert salt to a numeric seed via byte sum
  salt_bytes <- as.integer(charToRaw(salt))
  salt_num <- sum(salt_bytes * seq_along(salt_bytes)) %% mod

  # Multiplicative hash combining ID and salt.
  # The salt must enter *multiplicatively*, not just additively: an additive
  # salt (h = id*a + salt) makes every column's uniform an affine shift of the
  # same draw, so all stable_per columns of one identifier become perfectly
  # rank-correlated. Deriving a salt-specific odd multiplier decorrelates them.
  # Operands stay < 2^53 so double arithmetic remains exact:
  #   id_num < mod (~2.1e9), salt_mult < 2^21 (~2.1e6) -> product < 4.6e15.
  salt_mult <- (salt_num %% 1048573) * 2 + 1  # odd multiplier in [1, ~2.1e6]
  h <- (id_num * salt_mult) %% mod
  h <- (h * 48271 + salt_num) %% mod
  h <- (h * 69069 + 1) %% mod
  h / mod
}

# Uniform (0,1) for (a, b) pairs of numeric hashes in [0, 2^31 - 1), mixed
# with xor-shifts so that, unlike .hash_mix(), the result is not affine in the
# inputs: pairs that share one element give unrelated values. Multipliers stay
# below 2^22 so the products are exact in double arithmetic.
.hash_pair <- function(a, b) {
  mod <- 2147483647
  x <- bitwXor(as.integer(a), as.integer(b))
  x <- bitwXor(x, bitwShiftR(x, 16L))
  x <- as.integer((as.double(x) * 2654435) %% mod)
  x <- bitwXor(x, bitwShiftR(x, 13L))
  x <- as.integer((as.double(x) * 1500007) %% mod)
  x <- bitwXor(x, bitwShiftR(x, 16L))
  (as.double(x) + 0.5) / (mod + 1)
}

# Deterministic categorical: hash IDs to pick categories via cumulative probs.
.deterministic_categorical <- function(id_vec, values, probs, salt) {
  u <- .hash_to_uniform(id_vec, salt)
  # Normalize so probs that don't sum to 1 behave like the random sample()
  # path (which renormalizes) instead of dumping the residual on the last bin.
  probs <- probs / sum(probs)
  cum_p <- cumsum(probs)
  # findInterval with breakpoints [0, cum_p[1], ..., cum_p[n-1]]
  # returns bin index 1..n matching values[1..n]
  bins <- findInterval(u, c(0, cum_p[-length(cum_p)]), left.open = TRUE)
  bins <- pmax(1L, pmin(bins, length(values)))
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
