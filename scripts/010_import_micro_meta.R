# 010_import_micro_meta.R
# Downloads metadata for all Woonbase CBS microdata files from the ODISSEI portal.
# Source: https://portal.odissei.nl/dataverse/cbs?q=woonbase&fq2=keywordValue_ss%3A%22Woonbase%22
# Uses the Dataverse Search API and dataset export API.

library(httr2)
library(jsonlite)
library(data.table)
library(openxlsx)

base_url <- "https://portal.odissei.nl"
out_dir  <- "data/interim/woonbase_meta"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)


# Search all Woonbase datasets via Dataverse Search API ----

fetch_search_page <- function(start = 0, per_page = 20) {
  resp <- request(paste0(base_url, "/api/search")) |>
    req_url_query(
      q        = "Woonbase",
      type     = "dataset",
      subtree  = "cbs",
      fq       = 'keywordValue_ss:"Woonbase"',
      per_page = per_page,
      start    = start
    ) |>
    req_perform()
  resp_body_json(resp, simplifyVector = FALSE)
}

first_page <- fetch_search_page(start = 0, per_page = 20)
total      <- first_page$data$total_count
cat("Total Woonbase datasets found:", total, "\n")

all_items <- first_page$data$items
starts    <- seq(20, total - 1, by = 20)
for (s in starts) {
  page      <- fetch_search_page(start = s, per_page = 20)
  all_items <- c(all_items, page$data$items)
}
cat("Items retrieved:", length(all_items), "\n")


# Extract summary metadata from search results ----

null_to_na <- function(x) if (is.null(x)) NA_character_ else as.character(x[[1]])

dt_summary <- rbindlist(lapply(all_items, function(item) {
  data.table(
    name                    = null_to_na(item$name),
    global_id               = null_to_na(item$global_id),
    url                     = null_to_na(item$url),
    publisher               = null_to_na(item$publisher),
    published_at            = null_to_na(item$published_at),
    description             = null_to_na(item$description),
    identifier_of_dataverse = null_to_na(item$identifier_of_dataverse),
    file_count              = null_to_na(item$fileCount),
    major_version           = null_to_na(item$majorVersion),
    minor_version           = null_to_na(item$minorVersion),
    keywords = if (length(item$keywords) > 0)
      paste(unlist(item$keywords), collapse = "; ")
    else NA_character_
  )
}), fill = TRUE)

dt_summary[, selected := NA_character_]

xlsx_path <- file.path(out_dir, "woonbase_datasets_summary.xlsx")
write.xlsx(dt_summary, xlsx_path, overwrite = TRUE)
cat("Summary xlsx saved:", nrow(dt_summary), "datasets ->", xlsx_path, "\n")


# Download full metadata per dataset via export API ----

fetch_dataset_meta <- function(persistent_id) {
  resp <- request(paste0(base_url, "/api/datasets/export")) |>
    req_url_query(
      exporter     = "dataverse_json",
      persistentId = persistent_id
    ) |>
    req_error(is_error = \(resp) FALSE) |>
    req_perform()

  if (resp_status(resp) != 200L) {
    warning("Failed (", resp_status(resp), "): ", persistent_id)
    return(NULL)
  }
  resp_body_json(resp, simplifyVector = FALSE)
}

meta_list        <- vector("list", nrow(dt_summary))
names(meta_list) <- dt_summary$global_id

for (i in seq_len(nrow(dt_summary))) {
  pid <- dt_summary$global_id[i]
  cat(sprintf("[%d/%d] %s\n", i, nrow(dt_summary), pid))
  meta_list[[i]] <- fetch_dataset_meta(pid)
  Sys.sleep(0.3)
}

failed <- names(which(sapply(meta_list, is.null)))
if (length(failed) > 0)
  warning("Metadata not retrieved for ", length(failed), " dataset(s):\n",
          paste(failed, collapse = "\n"))


# Save full metadata ----

saveRDS(meta_list, file.path(out_dir, "woonbase_metadata_list.rds"))
write_json(
  meta_list,
  file.path(out_dir, "woonbase_metadata_list.json"),
  pretty     = TRUE,
  auto_unbox = TRUE
)

cat("Done. Metadata saved to:", out_dir, "\n")


# Import selection from reference xlsx ----
# After manually filling the `selected` column in Excel, re-import here.

ref_path <- xlsx_path
if (file.exists(ref_path)) {
  dt_selected <- as.data.table(readxl::read_xlsx(ref_path))
  dt_selected <- dt_selected[!is.na(selected) & selected != ""]
  cat("Datasets marked as selected:", nrow(dt_selected), "\n")
} else {
  message("Reference xlsx not found: ", ref_path)
}
