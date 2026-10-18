# ============================================================
# IDS 570 - Export Analysis Tables
# ============================================================

library(tidyverse)
library(here)

dir.create(
  here("outputs", "tables"),
  recursive = TRUE,
  showWarnings = FALSE
)

table_names <- c(
  "data_summary",
  "theme_counts",
  "token_summary",
  "unigram_summary",
  "lemma_counts",
  "bigram_sparsity",
  "bigram_counts",
  "reward_bigrams",
  "reward_bigrams_grouped",
  "occupation_summary",
  "occupation_themes",
  "support_summary",
  "tfidf_top_all",
  "tfidf_top_validated"
)

available_tables <- table_names[
  vapply(
    table_names,
    exists,
    logical(1),
    envir = .GlobalEnv
  )
]

missing_tables <- setdiff(
  table_names,
  available_tables
)

purrr::walk(
  available_tables,
  function(name) {
    readr::write_csv(
      get(name, envir = .GlobalEnv),
      here("outputs", "tables", paste0(name, ".csv"))
    )
  }
)


cat("Exported tables:\n")
print(available_tables)

cat("\nTables not currently in memory:\n")
print(missing_tables)

cat("\nFiles in outputs/tables:\n")
print(list.files(here("outputs", "tables")))