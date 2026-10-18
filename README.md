# Beyond Pay: Financial and Nonfinancial Recognition in Employee Narratives

**IDS 570 — Text as Data | Data Exploration (Freedom option)**

## Project overview

This project revisits open-ended survey responses from **Measuring Employment Sentiments and Social Inequality (MESSI)**, a research project led by Professor Scott Schieman. As an undergraduate research assistant, I previously read and manually coded MESSI responses to identify recurring themes. For this assignment, I explored how NLP can complement qualitative coding by efficiently summarizing vocabulary, examining the context of reward-related language, and comparing occupational groups.

The survey prompt was:

> Has there ever been a time in your working life when you got **a little more** of something and it made a difference for how you felt about yourself or your job?

**Research question:** What forms of workplace rewards emerge in employees' narratives, how are financial and nonfinancial recognition related, and do these patterns vary across occupations?

## Data and scope

- Canadian MESSI *A Little More* open-text subset: **340 original responses**, with **3 manually identified invalid responses excluded**, leaving **337 valid responses**.
- **323 responses** have at least one existing human-coded theme.
- The responses are brief, varied in wording, and accompanied by occupation and other employment-related variables.
- Available English translations were used where applicable, while original responses were retained for auditing.
- The analysis is **descriptive and exploratory**, not a representative estimate of all workers' preferences or a causal analysis.

**Data access:** The underlying respondent-level MESSI files are not included in this repository. Their use in the class project was approved, but permission to analyze data does not itself authorize public redistribution of individual responses or derivative outputs. To run the full analysis, an authorized user must supply the source workbook locally.

## Analysis workflow

| Stage | Approach | Analytical purpose |
|---|---|---|
| 1. Clean and harmonize | Review invalid responses, preserve human-coded themes, align selected labels | Establish a consistent corpus |
| 2. Theme prevalence | Summarize existing multi-label human codes | Identify dominant forms of workplace rewards |
| 3. Unigrams | Tokenization, lowercasing, lemmatization, customized stopwords, respondent-level frequencies | Identify common reward-related vocabulary efficiently |
| 4. Bigrams and context | Adjacent word pairs from unfiltered text, keyword-context review | Examine how financial and interpersonal rewards are expressed |
| 5. Occupation comparison | Within-occupation percentages for Money and Recognition | Explore variation across work contexts |
| 6. TF–IDF | Aggregate responses by occupation; require minimum respondent support | Identify relatively distinctive vocabulary, with careful contextual interpretation |

### Key methodological decisions

- Harmonized `acknowledgement` into `recognition` and assigned `flexibility/socialization?` to `flexibility`; original codes were retained separately.
- Preserved words such as `appreciate` and `thank`, which were unexpectedly excluded by a general-purpose stopword list.
- Built bigrams from **unfiltered responses** to preserve true word adjacency.
- Excluded occupations with **fewer than 10 respondents** from subgroup comparisons, but retained them in overall corpus analysis.
- Required a term to appear in at least **3 respondents overall and 2 within an occupation** for the main TF–IDF display.

## Main findings

- The two leading human-coded themes were **Recognition (173 of 323 coded responses; 53.6%)** and **Money (159; 49.2%)**. They were not mutually exclusive: **70 responses** received both codes.
- Lemmatized word frequencies identified frequent language such as `bonus`, `recognition`, `money`, `pay`, and `raise`; counting *distinct respondents* avoided treating repeated words from one respondent as broad prevalence.
- Bigrams mostly reinforced unigram patterns, but expressions such as *small bonus*, *Christmas bonus*, *thank you*, and *feel appreciated* added context. Most unique bigrams appeared in only one response, limiting generalization.
- Recognition appeared more frequently than Money in five of six occupational groups included in the comparison; **Sales** was the exception. Differences were descriptive and generally modest.
- TF–IDF was sensitive to individual wording and small subcorpora. One term worth revisiting was `society` in the Service group, where contextual reading suggested recognition linked to perceived social contribution.

**Takeaway:** NLP provided a fast overview of common language, while qualitative coding and contextual reading remained essential for interpreting short, heterogeneous responses. TF–IDF distinctiveness does not imply conceptual importance.

## Repository structure

```text
MESSI-NLP-Analysis/
├── README.md
├── .gitignore
├── MESSI-NLP-Analysis.Rproj
├── report.qmd
├── scripts/
│   ├── 01_import_clean.R
│   ├── 02_text_exploration.R
│   ├── 03_occupation_analysis.R
│   └── 04_export_results.R       # If created
├── data/
│   ├── raw/                      # Confidential; not committed
│   └── processed/                # Confidential; not committed
└── outputs/
    ├── figures/                  # Private unless sharing approved
    └── tables/                   # Private unless sharing approved
```

## Reproducing the analysis

1. Install **R** and open `MESSI-NLP-Analysis.Rproj` in RStudio.
2. Install the packages used by the scripts:

   ```r
   install.packages(c("tidyverse", "readxl", "here", "janitor", "tidytext", "textstem"))
   ```

3. **Authorized users only:** place the source Excel workbook at:

   ```text
   data/raw/(Original)A LITTLE MORE_MESSI_CAN_2024_MAY copy.xlsx
   ```

   If the local workbook has a different filename, update `excel_path` in `scripts/01_import_clean.R`.
4. Run the scripts in order:

   ```r
   source("scripts/01_import_clean.R")
   source("scripts/02_text_exploration.R")
   source("scripts/03_occupation_analysis.R")
   ```

   If `scripts/04_export_results.R` exists and uses objects from the earlier scripts, run it **in the same R session** afterward:

   ```r
   source("scripts/04_export_results.R")
   ```

5. Review the locally generated figures and summary tables under `outputs/`. Render `report.qmd` in RStudio if the report and its referenced outputs are present.

The scripts are intended to run from the project's root directory and use `here()` for local file paths. The full analysis cannot be reproduced from this public repository alone without access to the approved source data.

## Limitations and ethics

Survey responses are short, and occupational subgroup sizes vary. Theme prevalence relies on human coding and survey selection; word frequencies do not directly measure what employees value most. Bigrams are sparse, while TF–IDF can highlight rare or idiosyncratic language. Findings should be interpreted descriptively and checked against response context.

No raw respondent texts, identifiers, translated answers, respondent-level derivatives, or unapproved aggregate outputs should be committed to a public repository. Sharing any figures, tables, or excerpts requires authorization under the MESSI research project's data-sharing rules.

## Possible extension

A future project could use the original human-coded labels to develop and evaluate a thematic classification pipeline, comparing automated predictions against held-out human annotations. This classification extension **was not implemented** in the current data exploration.
