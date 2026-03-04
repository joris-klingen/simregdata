.seq_id  <- function(n, w)    sprintf(paste0("%0", w, "d"), seq_len(n))
.rand_id <- function(n, w) {
  if (w <= 9L) {
    pool <- 10^w - 1L
    unique <- n <= pool
    if (!unique)
      warning(sprintf(".rand_id: n=%d > pool=%d for width %d; IDs will not be unique", n, pool, w))
    sprintf(paste0("%0", w, "d"), sample.int(pool, n, replace = !unique))
  } else {
    # For wide IDs, concatenate random hex chunks of 8 chars (safe for sample.int)
    n_chunks <- ceiling(w / 8L)
    parts <- replicate(n_chunks, sprintf("%08x", sample.int(.Machine$integer.max, n, replace = TRUE)))
    if (is.null(dim(parts))) parts <- matrix(parts, nrow = n)
    vapply(seq_len(n), function(i) substr(paste0(parts[i, ], collapse = ""), 1L, w), character(1L))
  }
}
.rcat    <- function(n, v, p = NULL) sample(v, n, replace = TRUE, prob = p)
.yyyymmdd <- function(d) {
  lt <- as.POSIXlt(d)
  sprintf("%04d%02d%02d", lt$year + 1900L, lt$mon + 1L, lt$mday)
}
.rdate   <- function(n, from, to)
  as.Date(sample(as.integer(from):as.integer(to), n, replace = TRUE), origin = "1970-01-01")
