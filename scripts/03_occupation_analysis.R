# ============================================================
# Phase 5 - Occupational Group Selection
# ============================================================

library(tidyverse)
library(tidytext)
library(textstem)
library(here)

messi <- readRDS(
  here("data", "processed", "messi_clean.rds")
)

stopifnot(nrow(messi) == 337)

occupation_summary <- messi %>%
  count(occupation, name = "total_n", sort = TRUE)

eligible_occupations <- occupation_summary %>%
  filter(total_n >= 10) %>%
  pull(occupation)

excluded_occupations <- occupation_summary %>%
  filter(total_n < 10 | is.na(occupation))

print(occupation_summary)
print(excluded_occupations)

messi_occupation <- messi %>%
  filter(
    !is.na(occupation),
    occupation %in% eligible_occupations
  )

# ============================================================
# Analysis 6 - Themes by Occupation
# ============================================================

occupation_themes <- messi_occupation %>%
  mutate(
    is_coded = !is.na(main_theme) | !is.na(main_theme_2),
    
    money = coalesce(main_theme == "money", FALSE) |
      coalesce(main_theme_2 == "money", FALSE),
    
    recognition = coalesce(main_theme == "recognition", FALSE) |
      coalesce(main_theme_2 == "recognition", FALSE)
  ) %>%
  group_by(occupation) %>%
  summarise(
    total_n = n(),
    coded_n = sum(is_coded),
    money_n = sum(money),
    recognition_n = sum(recognition),
    both_n = sum(money & recognition),
    .groups = "drop"
  ) %>%
  mutate(
    coding_rate = round(100 * coded_n / total_n, 1),
    money_pct = if_else(
      coded_n > 0, round(100 * money_n / coded_n, 1), NA_real_
    ),
    recognition_pct = if_else(
      coded_n > 0, round(100 * recognition_n / coded_n, 1), NA_real_
    ),
    both_pct = if_else(
      coded_n > 0, round(100 * both_n / coded_n, 1), NA_real_
    )
  )

print(occupation_themes, n = Inf)

# ============================================================
# Figure 4 - Reward Themes by Occupation
# ============================================================

occupation_plot <- occupation_themes %>%
  select(
    occupation,
    money_pct,
    recognition_pct
  ) %>%
  pivot_longer(
    cols = c(money_pct, recognition_pct),
    names_to = "theme",
    values_to = "percentage"
  ) %>%
  mutate(
    theme = recode(
      theme,
      money_pct = "Money",
      recognition_pct = "Recognition"
    )
  )

fig4 <- occupation_plot %>%
  ggplot(
    aes(
      x = occupation,
      y = percentage,
      fill = theme
    )
  ) +
  geom_col(
    position = position_dodge(width = 0.8),
    width = 0.7
  ) +
  coord_flip() +
  scale_fill_manual(
    values = c(
      "Money" = "#527BA3",
      "Recognition" = "#B47862"
    )
  ) +
  labs(
    title = "Workplace Reward Themes by Occupation",
    subtitle = "Percentage of coded responses within each occupational group",
    x = NULL,
    y = "Percentage of coded responses",
    fill = "Theme",
    caption = "Groups with fewer than 10 responses excluded. Themes may overlap."
  ) +
  theme_minimal(base_size = 12)

fig4

ggsave(
  here("outputs", "figures", "04_occupation_themes.png"),
  plot = fig4,
  width = 10,
  height = 6,
  dpi = 300
)


# ============================================================
# Analysis 7.1 - Occupational Text Preprocessing
# ============================================================

preserve_words <- c(
  "appreciate", "thank", "work", "job", "feel",
  "more", "no", "not", "never", "without"
)

occupation_stopwords <- tidytext::stop_words %>%
  distinct(word) %>%
  filter(!word %in% preserve_words)

occupation_tokens <- messi_occupation %>%
  select(response_id, occupation, text_analysis) %>%
  filter(!is.na(text_analysis)) %>%
  tidytext::unnest_tokens(
    word,
    text_analysis,
    token = "words"
  ) %>%
  mutate(
    lemma = textstem::lemmatize_words(word),
    lemma = recode(
      lemma,
      "recognise" = "recognize",
      "recognised" = "recognize",
      "recognising" = "recognize"
    )
  ) %>%
  filter(
    !word %in% occupation_stopwords$word,
    !lemma %in% occupation_stopwords$word,
    str_detect(lemma, "[[:alpha:]]")
  )

# ============================================================
# Analysis 7.2 - Term Support
# ============================================================

term_support <- occupation_tokens %>%
  group_by(lemma) %>%
  summarise(
    respondents = n_distinct(response_id),
    total_occurrences = n(),
    occupations = n_distinct(occupation),
    .groups = "drop"
  )

support_summary <- term_support %>%
  summarise(
    total_terms = n(),
    one_respondent = sum(respondents == 1),
    two_respondents = sum(respondents == 2),
    three_or_more = sum(respondents >= 3)
  )

print(support_summary)

# ============================================================
# Analysis 7.3 - TF-IDF by Occupation
# ============================================================

occupation_tfidf <- occupation_tokens %>%
  count(
    occupation,
    lemma,
    name = "n"
  ) %>%
  tidytext::bind_tf_idf(
    term = lemma,
    document = occupation,
    n = n
  ) %>%
  left_join(
    term_support %>% select(lemma, respondents),
    by = "lemma"
  )

tfidf_top_all <- occupation_tfidf %>%
  group_by(occupation) %>%
  slice_max(
    tf_idf,
    n = 10,
    with_ties = FALSE
  ) %>%
  ungroup()

tfidf_top_supported <- occupation_tfidf %>%
  filter(respondents >= 3) %>%
  group_by(occupation) %>%
  slice_max(
    tf_idf,
    n = 10,
    with_ties = FALSE
  ) %>%
  ungroup()

print(tfidf_top_all, n = Inf)
print(tfidf_top_supported, n = Inf)
# ============================================================
# Analysis 7.4 - Within-Group Term Support
# ============================================================

within_group_support <- occupation_tokens %>%
  group_by(occupation, lemma) %>%
  summarise(
    group_respondents = n_distinct(response_id),
    .groups = "drop"
  )

tfidf_validated <- occupation_tfidf %>%
  left_join(
    within_group_support,
    by = c("occupation", "lemma")
  )

tfidf_top_validated <- tfidf_validated %>%
  filter(
    respondents >= 3,
    group_respondents >= 2
  ) %>%
  group_by(occupation) %>%
  slice_max(
    tf_idf,
    n = 10,
    with_ties = FALSE
  ) %>%
  ungroup()

print(tfidf_top_validated, n = Inf)

# ============================================================
# Figure 5 - Distinctive Occupational Vocabulary
# ============================================================

fig5 <- tfidf_top_validated %>%
  ggplot(
    aes(
      x = tidytext::reorder_within(
        lemma, tf_idf, occupation
      ),
      y = tf_idf
    )
  ) +
  geom_col(fill = "#527BA3") +
  coord_flip() +
  facet_wrap(
    ~ occupation,
    scales = "free",
    ncol = 2
  ) +
  tidytext::scale_x_reordered() +
  labs(
    title = "Distinctive Reward-Related Vocabulary by Occupation",
    subtitle = "TF-IDF with minimum respondent-support thresholds",
    x = NULL,
    y = "TF-IDF",
    caption = paste(
      "Terms used by at least 3 respondents overall",
      "and 2 within the occupation."
    )
  ) +
  theme_minimal(base_size = 11)

fig5

ggsave(
  here("outputs", "figures", "05_occupation_tfidf.png"),
  plot = fig5,
  width = 12,
  height = 9,
  dpi = 300
)

