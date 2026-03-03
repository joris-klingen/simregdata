.seq_id  <- function(n, w)    sprintf(paste0("%0", w, "d"), seq_len(n))
.rand_id <- function(n, w) {
  # For widths <= 9 use sample.int; wider: combine two ranges
  if (w <= 9L) {
    pool <- 10^w - 1L
    unique <- n <= pool
    if (!unique)
      warning(sprintf(".rand_id: n=%d > pool=%d for width %d; IDs will not be unique", n, pool, w))
    sprintf(paste0("%0", w, "d"), sample.int(pool, n, replace = !unique))
  } else {
    h <- ceiling(w / 2L)
    paste0(sprintf(paste0("%0", h,   "d"), sample.int(10^h       - 1L, n, replace = TRUE)),
           sprintf(paste0("%0", w-h, "d"), sample.int(10^(w - h) - 1L, n, replace = TRUE)))
  }
}
.rcat    <- function(n, v, p = NULL) sample(v, n, replace = TRUE, prob = p)
.yyyymmdd <- function(d) {
  lt <- as.POSIXlt(d)
  sprintf("%04d%02d%02d", lt$year + 1900L, lt$mon + 1L, lt$mday)
}
.rdate   <- function(n, from, to)
  as.Date(sample(as.integer(from):as.integer(to), n, replace = TRUE), origin = "1970-01-01")
