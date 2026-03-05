# Column validation against CBS PDF documentation ----

#' Parse column definitions from extracted CBS PDF text
#'
#' Reads the "Bestandsopbouw" variable table from an extracted CBS PDF text
#' file and returns a data.frame of variable definitions.
#'
#' @param txt_path Path to an extracted PDF text file.
#' @return A data.frame with columns \code{volgnr} (integer), \code{naam}
#'   (character), and \code{formaat} (character).
#' @export
cbs_parse_pdf_columns <- function(txt_path) {
  lines <- readLines(txt_path, warn = FALSE)

  # Find all header lines and the first "Toelichting" end marker
  # Supports two CBS formats: "VolgNr Naam Formaat" and "Nr Variabele Form."
  hdr_idx <- grep("^\\s*(VolgNr\\s+Naam\\s+Formaat|Nr\\s+Variabele\\s+Form)", lines)
  end_idx <- grep("^\\s*Toelichting op de variabelen", lines)
  if (length(hdr_idx) == 0L || length(end_idx) == 0L)
    stop("Could not find Bestandsopbouw table in ", txt_path)

  # Table runs from first header to last line before first "Toelichting"
  start <- hdr_idx[1L]
  end   <- end_idx[end_idx > start][1L]

  block <- lines[(start + 1L):(end - 1L)]

  # Drop page-break noise
  noise <- grepl("^\\s*$", block) |
    grepl("^\\s*Microdata Services", block) |
    grepl("^\\s*documentatie\\s", block) |
    grepl("^\\s*(VolgNr\\s+Naam\\s+Formaat|Nr\\s+Variabele\\s+Form)", block)
  block <- block[!noise]

  # Parse: number  name-tokens  format (e.g. "15 Indicator PersoonIsGeboren A1")
  # Format code is the last whitespace-separated token matching [AF]\d+
  out <- vector("list", length(block))
  k <- 0L
  for (ln in block) {
    m <- regmatches(ln, regexec("^\\s*(\\d+)\\s+(.+)\\s+([AF]\\d+\\S*)\\s*$", ln))[[1L]]
    if (length(m) == 4L) {
      k <- k + 1L
      naam <- trimws(m[3L])
      # Fix PDF extraction artifact: spaces within variable names → underscores
      naam <- gsub(" ", "_", naam)
      out[[k]] <- data.frame(
        volgnr  = as.integer(m[2L]),
        naam    = naam,
        formaat = m[4L],
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, out[seq_len(k)])
}


#' Compare simulated columns against CBS PDF documentation
#'
#' Generates a small synthetic dataset for a Woonbase file type, parses the
#' corresponding CBS PDF documentation, and reports matches, missing columns,
#' extra columns, and case mismatches.
#'
#' @param file CBS file name (e.g. \code{"WoonbaseSleutelbestand2023V1"}).
#' @param txt_path Path to the extracted PDF text file for this file type.
#' @param year Simulation year (default 2023).
#' @param n Number of rows to simulate (default 1000).
#' @return A list with elements \code{match}, \code{missing}, \code{extra},
#'   and \code{case_mismatch}.
#' @export
cbs_check_columns <- function(file, txt_path, year = 2023L, n = 1000L) {
  woonbase_init(year = year, n = n, seed = 1L)
  dt <- read_sav(file)

  pdf_cols <- cbs_parse_pdf_columns(txt_path)

  sim_names <- names(dt)
  pdf_names <- pdf_cols$naam

  # Exact matches
  matched <- intersect(sim_names, pdf_names)

  # Remaining after exact match
  sim_rest <- setdiff(sim_names, matched)
  pdf_rest <- setdiff(pdf_names, matched)

  # Case-insensitive matches among leftovers
  sim_lower <- tolower(sim_rest)
  pdf_lower <- tolower(pdf_rest)
  case_overlap <- intersect(sim_lower, pdf_lower)

  case_mismatch <- data.frame(
    simulated = sim_rest[match(case_overlap, sim_lower)],
    pdf       = pdf_rest[match(case_overlap, pdf_lower)],
    stringsAsFactors = FALSE
  )

  # Truly missing / extra (exclude case mismatches)
  missing <- setdiff(pdf_rest, case_mismatch$pdf)
  extra   <- setdiff(sim_rest, case_mismatch$simulated)

  list(
    match         = matched,
    missing       = missing,
    extra         = extra,
    case_mismatch = case_mismatch
  )
}
