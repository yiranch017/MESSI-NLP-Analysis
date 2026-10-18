

# IDS 570 - Data Exploration
# Project: Beyond Pay
# Step 1: Data ingestion and initial cleaning

library(tidyverse)
library(readxl)
library(here)
library(janitor)

getwd()
here()

excel_path <- here(
  "data",
  "raw",
  "(Original)A LITTLE MORE_MESSI_CAN_2024_MAY copy.xlsx"
)

file.exists(excel_path)

messi_raw <- read_excel(
  path = excel_path,
  sheet = "LITTLEMORE",
  range = cell_cols("A:T")
)

dim(messi_raw)

# ============================================================
# Phase 2: Data Cleaning
# ============================================================

messi <- messi_raw %>%
  janitor::clean_names() %>%
  transmute(
    response_id = row_number(),
    occupation = str_squish(as.character(occupation)),
    emplength = as.character(emplength),
    waypaid = as.character(waypaid),
    littlemore = str_squish(as.character(littlemore)),
    text_original = as.character(littlemore_open),
    text_translation = na_if(
      str_squish(as.character(french_translation)), ""
    ),
    main_theme = na_if(
      str_to_lower(str_squish(as.character(main_theme))), ""
    ),
    main_theme_2 = na_if(
      str_to_lower(str_squish(as.character(main_theme_2))), ""
    )
  ) %>%
  mutate(
    text_analysis = coalesce(
      text_translation,
      na_if(str_squish(text_original), "")
    ),
    text_source = if_else(
      !is.na(text_translation),
      "translated",
      "original"
    ),
    word_count = str_count(text_analysis, "\\S+")
  )

glimpse(messi)

# ============================================================
# Phase 2 - Theme Harmonization and Invalid Response Removal
# ============================================================

invalid_excel_rows <- c(182L, 229L, 330L)

rows_to_exclude <- messi %>%
  mutate(excel_row = response_id + 1L) %>%
  filter(excel_row %in% invalid_excel_rows)

stopifnot(
  nrow(rows_to_exclude) == 3,
  all(is.na(rows_to_exclude$main_theme)),
  all(is.na(rows_to_exclude$main_theme_2))
)

messi <- messi %>%
  mutate(
    excel_row = response_id + 1L,
    
    main_theme_original = main_theme,
    main_theme_2_original = main_theme_2,
    
    main_theme = case_when(
      main_theme == "acknowledgement" ~ "recognition",
      main_theme == "flexibility/socialization?" ~ "flexibility",
      TRUE ~ main_theme
    ),
    
    main_theme_2 = case_when(
      main_theme_2 == "acknowledgement" ~ "recognition",
      main_theme_2 == "flexibility/socialization?" ~ "flexibility",
      TRUE ~ main_theme_2
    )
  ) %>%
  filter(!excel_row %in% invalid_excel_rows)

dim(messi)

# ============================================================
# Phase 2 - Cleaning Validation
# ============================================================

cleaning_summary <- messi %>%
  summarise(
    total_responses = n(),
    primary_coded = sum(!is.na(main_theme)),
    any_theme_coded = sum(
      !is.na(main_theme) | !is.na(main_theme_2)
    ),
    uncoded_responses = sum(
      is.na(main_theme) & is.na(main_theme_2)
    ),
    acknowledgement_remaining = sum(
      main_theme == "acknowledgement" |
        main_theme_2 == "acknowledgement",
      na.rm = TRUE
    ),
    ambiguous_flexibility_remaining = sum(
      main_theme == "flexibility/socialization?" |
        main_theme_2 == "flexibility/socialization?",
      na.rm = TRUE
    )
  )

print(cleaning_summary)

# ============================================================
# Phase 2.1 - Corpus Overview
# ============================================================

data_summary <- messi %>%
  summarise(
    total_responses = n(),
    valid_text = sum(!is.na(text_analysis)),
    translated = sum(text_source == "translated"),
    primary_coded = sum(!is.na(main_theme)),
    secondary_coded = sum(!is.na(main_theme_2)),
    any_theme_coded = sum(
      !is.na(main_theme) | !is.na(main_theme_2)
    ),
    mean_words = round(mean(word_count, na.rm = TRUE), 2),
    median_words = median(word_count, na.rm = TRUE),
    min_words = min(word_count, na.rm = TRUE),
    max_words = max(word_count, na.rm = TRUE)
  )

print(data_summary)

occupation_counts <- messi %>%
  count(occupation, sort = TRUE)

print(occupation_counts)

# ============================================================
# Phase 2.2 - Inspect Human-Coded Theme Labels
# ============================================================

primary_themes <- messi %>%
  count(main_theme, sort = TRUE)

secondary_themes <- messi %>%
  count(main_theme_2, sort = TRUE)

print(primary_themes, n = Inf)
print(secondary_themes, n = Inf)

# ============================================================
# Analysis 1 - Human-Coded Theme Prevalence
# ============================================================

theme_long <- messi %>%
  select(response_id, main_theme, main_theme_2) %>%
  pivot_longer(
    cols = c(main_theme, main_theme_2),
    names_to = "theme_source",
    values_to = "theme"
  ) %>%
  filter(!is.na(theme)) %>%
  distinct(response_id, theme, .keep_all = TRUE)

n_coded <- n_distinct(theme_long$response_id)

theme_counts <- theme_long %>%
  count(theme, sort = TRUE) %>%
  mutate(
    pct_coded = round(100 * n / n_coded, 1),
    pct_all = round(100 * n / nrow(messi), 1)
  )

print(theme_counts, n = Inf)

# ============================================================
# Save Updated Cleaned Dataset
# ============================================================

saveRDS(
  messi,
  here("data", "processed", "messi_clean.rds")
)

saveRDS(
  theme_long,
  here("data", "processed", "messi_themes_long.rds")
)
