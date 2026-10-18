# ============================================================
# IDS 570 - MESSI Data Exploration
# Phase 3: Tokenization and Word Frequencies
# ============================================================
install.packages("textstem")
library(tidyverse)
library(tidytext)
library(textstem)
library(here)

messi <- readRDS(
  here("data", "processed", "messi_clean.rds")
)

stopifnot(nrow(messi) == 337)

glimpse(messi)

# ============================================================
# Analysis 3.1 - Word Tokenization
# ============================================================

tokens_raw <- messi %>%
  select(response_id, occupation, text_analysis) %>%
  filter(!is.na(text_analysis)) %>%
  unnest_tokens(
    output = word,
    input = text_analysis,
    token = "words",
    to_lower = TRUE
  )

token_summary <- tokens_raw %>%
  summarise(
    total_tokens = n(),
    unique_words = n_distinct(word),
    total_respondents = n_distinct(response_id)
  )

print(token_summary)

# ============================================================
# Analysis 3.2 - Raw Word Frequencies
# ============================================================

word_counts <- tokens_raw %>%
  group_by(word) %>%
  summarise(
    occurrences = n(),
    respondents = n_distinct(response_id),
    .groups = "drop"
  ) %>%
  mutate(
    respondent_pct = round(
      respondents / nrow(messi) * 100, 1
    )
  ) %>%
  arrange(desc(occurrences))

top_words_raw <- word_counts %>%
  slice_head(n = 30)

print(top_words_raw, n = 30)

# ============================================================
# Analysis 3.3 - Standard Stopword Filtering Preview
# ============================================================

top_words_filtered <- word_counts %>%
  anti_join(
    tidytext::stop_words %>% distinct(word),
    by = "word"
  ) %>%
  slice_head(n = 30)

print(top_words_filtered, n = 30)

# ============================================================
# Check Important Words Against Stopword Dictionary
# ============================================================

words_to_check <- c(
  "no", "not", "never", "more", "less",
  "without", "but", "work", "job",
  "money", "pay", "salary", "bonus",
  "recognition", "thank", "thanks",
  "appreciation", "manager"
)

stopword_check <- tibble(
  word = words_to_check
) %>%
  mutate(
    standard_stopword = word %in% tidytext::stop_words$word
  ) %>%
  left_join(
    word_counts,
    by = "word"
  ) %>%
  mutate(
    occurrences = replace_na(occurrences, 0L),
    respondents = replace_na(respondents, 0L)
  )

print(stopword_check, n = Inf)
# ============================================================
# Diagnostic Figure - Before and After Stopword Filtering
# ============================================================

comparison_words <- bind_rows(
  top_words_raw %>%
    slice_head(n = 15) %>%
    mutate(version = "Before stopword removal"),
  
  top_words_filtered %>%
    slice_head(n = 15) %>%
    mutate(version = "After standard stopword removal")
)

fig_stopword_comparison <- comparison_words %>%
  ggplot(
    aes(
      x = reorder_within(
        word, respondents, version
      ),
      y = respondents
    )
  ) +
  geom_col(fill = "#527BA3") +
  coord_flip() +
  facet_wrap(
    ~ version,
    scales = "free_y"
  ) +
  scale_x_reordered() +
  labs(
    title = "Most Common Words in MESSI Responses",
    subtitle = "Before and after standard stopword filtering",
    x = NULL,
    y = "Number of respondents mentioning word"
  ) +
  theme_minimal(base_size = 12)

fig_stopword_comparison

# ============================================================
# Analysis 3.4 - Word Lemmatization
# ============================================================

tokens_lemma <- tokens_raw %>%
  mutate(
    lemma = textstem::lemmatize_words(word),
    lemma = recode(
      lemma,
      "recognise" = "recognize",
      "recognised" = "recognize",
      "recognising" = "recognize"
    )
  )

lemma_check <- tokens_lemma %>%
  filter(word %in% c(
    "recognize", "recognized", "recognise",
    "recognised", "recognizing", "recognising",
    "bonus", "bonuses",
    "appreciate", "appreciated", "appreciating"
  )) %>%
  count(word, lemma, sort = TRUE)

print(lemma_check, n = Inf)
# ============================================================
# Analysis 3.5 - Customized Stopword List
# ============================================================

preserve_words <- c(
  "appreciate", "thank", "work", "job", "feel",
  "more", "no", "not", "never", "without"
)

unigram_stopwords <- tidytext::stop_words %>%
  distinct(word) %>%
  filter(!word %in% preserve_words)

# ============================================================
# Analysis 3.6 - Customized Unigram Tokens
# ============================================================

tokens_unigram <- tokens_lemma %>%
  filter(!word %in% unigram_stopwords$word) %>%
  filter(!lemma %in% unigram_stopwords$word) %>%
  filter(str_detect(lemma, "[[:alpha:]]"))

unigram_summary <- tokens_unigram %>%
  summarise(
    total_tokens = n(),
    unique_lemmas = n_distinct(lemma),
    respondents = n_distinct(response_id)
  )

print(unigram_summary)
# ============================================================
# Analysis 3.6A - Validate Domain-Specific Stopword Exceptions
# ============================================================

tokens_unigram %>%
  filter(response_id == 61) %>%
  count(lemma, sort = TRUE)

tokens_unigram %>%
  summarise(
    total_tokens = n(),
    unique_lemmas = n_distinct(lemma),
    respondents = n_distinct(response_id)
  )
# ============================================================
# Analysis 3.7 - Updated Lemmatized Word Frequencies
# ============================================================

lemma_counts <- tokens_unigram %>%
  group_by(lemma) %>%
  summarise(
    occurrences = n(),
    respondents = n_distinct(response_id),
    .groups = "drop"
  ) %>%
  mutate(
    respondent_pct = round(
      100 * respondents / nrow(messi), 1
    )
  ) %>%
  arrange(desc(respondents), desc(occurrences))

print(lemma_counts, n = 30)

# ============================================================
# Figure 2 - Most Frequent Lemmatized Content Words
# ============================================================

fig2 <- lemma_counts %>%
  slice_max(
    order_by = respondents,
    n = 20,
    with_ties = FALSE
  ) %>%
  ggplot(
    aes(
      x = reorder(lemma, respondents),
      y = respondents
    )
  ) +
  geom_col(fill = "#527BA3", width = 0.75) +
  coord_flip() +
  labs(
    title = "Most Frequently Mentioned Words in MESSI Responses",
    subtitle = "Lemmatized content words after standard stopword removal",
    x = NULL,
    y = "Number of respondents mentioning word",
    caption = paste0(
      "N = ", nrow(messi),
      " valid responses. Words are counted once per respondent."
    )
  ) +
  theme_minimal(base_size = 12)

fig2

ggsave(
  here("outputs", "figures", "02_lemma_word_frequency.png"),
  plot = fig2,
  width = 9,
  height = 6,
  dpi = 300
)


# ============================================================
# Quality Check - Responses Lost During Unigram Filtering
# ============================================================

missing_unigram_ids <- messi %>%
  distinct(response_id) %>%
  anti_join(
    tokens_unigram %>% distinct(response_id),
    by = "response_id"
  )

print(missing_unigram_ids)

# ============================================================
# Inspect Filtered Response Locally
# ============================================================

messi %>%
  semi_join(
    missing_unigram_ids,
    by = "response_id"
  ) %>%
  select(response_id, text_analysis) %>%
  View()


# ============================================================
# Analysis 4.1 - Bigram Tokenization
# ============================================================

bigrams_raw <- messi %>%
  select(response_id, occupation, text_analysis) %>%
  filter(!is.na(text_analysis)) %>%
  tidytext::unnest_tokens(
    bigram,
    text_analysis,
    token = "ngrams",
    n = 2
  ) %>%
  filter(!is.na(bigram), str_squish(bigram) != "")

# ============================================================
# Analysis 4.2 - Bigram Frequencies and Sparsity
# ============================================================

bigram_counts_raw <- bigrams_raw %>%
  group_by(bigram) %>%
  summarise(
    occurrences = n(),
    respondents = n_distinct(response_id),
    .groups = "drop"
  ) %>%
  arrange(desc(respondents), desc(occurrences))

bigram_sparsity <- bigram_counts_raw %>%
  summarise(
    unique_bigrams = n(),
    appearing_once = sum(occurrences == 1),
    appearing_in_one_response = sum(respondents == 1),
    appearing_in_3plus_responses = sum(respondents >= 3),
    pct_single_response = round(
      100 * mean(respondents == 1), 1
    )
  )

print(bigram_sparsity)
print(bigram_counts_raw, n = 30)

# ============================================================
# Analysis 4.3 - Bigram Filtering
# ============================================================

bigrams_split <- bigrams_raw %>%
  tidyr::separate(
    bigram,
    into = c("word1", "word2"),
    sep = " ",
    remove = FALSE
  )

bigrams_filtered <- bigrams_split %>%
  filter(
    !(word1 %in% unigram_stopwords$word &
        word2 %in% unigram_stopwords$word)
  )

bigram_counts <- bigrams_filtered %>%
  group_by(bigram) %>%
  summarise(
    occurrences = n(),
    respondents = n_distinct(response_id),
    .groups = "drop"
  ) %>%
  arrange(desc(respondents), desc(occurrences))

print(bigram_counts, n = 30)

# ============================================================
# Analysis 4.4 - Reward-Related Bigrams
# ============================================================

reward_terms <- c(
  "bonus", "bonuses",
  "money", "pay", "paid",
  "raise", "salary", "wage", "wages",
  "recognition", "recognize", "recognized",
  "recognise", "recognised",
  "appreciation", "appreciate", "appreciated",
  "thank", "thanks", "praise"
)

reward_bigrams <- bigrams_filtered %>%
  filter(
    word1 %in% reward_terms |
      word2 %in% reward_terms
  ) %>%
  group_by(bigram) %>%
  summarise(
    occurrences = n(),
    respondents = n_distinct(response_id),
    .groups = "drop"
  ) %>%
  arrange(desc(respondents), desc(occurrences))

print(reward_bigrams, n = 40)

# ============================================================
# Analysis 4.5 - Keyword-in-Context: Financial Rewards
# ============================================================

financial_context <- messi %>%
  filter(
    str_detect(
      text_analysis,
      regex(
        "\\b(bonus|bonuses|money|pay|paid|raise|salary|wages?)\\b",
        ignore_case = TRUE
      )
    )
  ) %>%
  select(
    response_id,
    occupation,
    text_analysis
  )

# ============================================================
# Analysis 4.6 - Keyword-in-Context: Recognition
# ============================================================

recognition_context <- messi %>%
  filter(
    str_detect(
      text_analysis,
      regex(
        "\\b(recognition|recogniz\\w*|recognis\\w*|appreciat\\w*|thank\\w*|praise)\\b",
        ignore_case = TRUE
      )
    )
  ) %>%
  select(
    response_id,
    occupation,
    text_analysis
  )

nrow(financial_context)
nrow(recognition_context)
# ============================================================
# Review Matched Contexts Locally
# ============================================================

View(financial_context)
View(recognition_context)

# ============================================================
# Analysis 4.7 - Meaningful Reward-Related Bigrams
# ============================================================

financial_terms <- c(
  "bonus", "bonuses", "money", "pay", "paid",
  "raise", "salary", "wage", "wages"
)

recognition_terms <- c(
  "recognition", "recognize", "recognized",
  "recognise", "recognised",
  "appreciation", "appreciate", "appreciated",
  "thank", "thanks", "praise"
)

reward_bigrams_grouped <- bigrams_filtered %>%
  mutate(
    reward_type = case_when(
      word1 %in% financial_terms |
        word2 %in% financial_terms ~ "Financial rewards",
      word1 %in% recognition_terms |
        word2 %in% recognition_terms ~ "Interpersonal recognition",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(reward_type)) %>%
  group_by(reward_type, bigram) %>%
  summarise(
    occurrences = n(),
    respondents = n_distinct(response_id),
    .groups = "drop"
  ) %>%
  filter(respondents >= 3) %>%
  arrange(reward_type, desc(respondents))

print(reward_bigrams_grouped, n = Inf)

# ============================================================
# Figure 3 - Reward-Related Bigram Frequencies
# ============================================================

fig3 <- reward_bigrams_grouped %>%
  group_by(reward_type) %>%
  slice_max(
    order_by = respondents,
    n = 12,
    with_ties = FALSE
  ) %>%
  ungroup() %>%
  ggplot(
    aes(
      x = tidytext::reorder_within(
        bigram, respondents, reward_type
      ),
      y = respondents,
      fill = reward_type
    )
  ) +
  geom_col(width = 0.75) +
  coord_flip() +
  facet_wrap(
    ~ reward_type,
    scales = "free_y"
  ) +
  tidytext::scale_x_reordered() +
  scale_fill_manual(
    values = c(
      "Financial rewards" = "#527BA3",
      "Interpersonal recognition" = "#B47862"
    )
  ) +
  labs(
    title = "Recurring Expressions of Workplace Rewards",
    subtitle = "Bigrams appearing in at least three distinct responses",
    x = NULL,
    y = "Number of respondents",
    caption = paste0(
      "N = ", nrow(messi),
      " valid responses. Exact adjacent word pairs."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none"
  )

fig3

# ============================================================
# Save Figure 3
# ============================================================

ggsave(
  here("outputs", "figures", "03_reward_bigrams.png"),
  plot = fig3,
  width = 11,
  height = 7,
  dpi = 300
)
