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
