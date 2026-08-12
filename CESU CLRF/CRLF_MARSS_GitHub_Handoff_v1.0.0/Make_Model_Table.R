
# ==============================================================================
# make_collaborator_model_table.R
# CRLF MARSS v1.0
#
# PURPOSE:
#   Create clean collaborator-facing model-selection tables using the EXACT
#   values stored in master_model_selection.csv.
#
# OUTPUTS:
#   marss_results/master_tables/
#     COLLABORATOR_PRIMARY_MODEL_TABLE.csv
#     COLLABORATOR_EXPLORATORY_MODEL_TABLE.csv
#
# IMPORTANT:
#   AICc is treated as the primary model-selection metric.
#   Rankings and Akaike weights remain separated by Candidate_Set.
# ==============================================================================

library(readr)
library(dplyr)

project_root <- "F:/CRLF_MARSS"

input_file <- file.path(
  project_root,
  "marss_results",
  "master_tables",
  "master_model_selection.csv"
)

if (!file.exists(input_file)) {
  stop(
    "Could not find master model-selection table:\n",
    input_file
  )
}

models <- read_csv(
  input_file,
  show_col_types = FALSE
)

required <- c(
  "Candidate_Set",
  "Rank_AICc",
  "Model_Number",
  "Model_ID",
  "Model_Name",
  "Scientific_Question",
  "Hypothesis",
  "Covariates",
  "Season_Focus",
  "Climate_Window",
  "Time_Structure",
  "Lag_Structure",
  "K",
  "LogLik",
  "AIC",
  "AICc",
  "Delta_AICc",
  "Weight_AICc"
)

missing_fields <- setdiff(
  required,
  names(models)
)

if (length(missing_fields) > 0) {
  stop(
    "master_model_selection.csv is missing required columns:\n",
    paste(missing_fields, collapse = ", ")
  )
}

make_clean_table <- function(df) {

  df %>%
    transmute(

      AICc_Rank = Rank_AICc,

      Model = Model_Number,

      Model_ID = Model_ID,

      Model_Name = Model_Name,

      Covariates = case_when(
        is.na(Covariates) ~ "None",
        trimws(Covariates) == "" ~ "None",
        TRUE ~ Covariates
      ),

      Season = Season_Focus,

      Climate_Window = Climate_Window,

      Time_Structure = Time_Structure,

      Lag_Structure = Lag_Structure,

      Scientific_Question = Scientific_Question,

      Hypothesis = Hypothesis,

      K = K,

      LogLik = round(LogLik, 4),

      AIC = round(AIC, 4),

      AICc = round(AICc, 4),

      Delta_AICc = round(Delta_AICc, 4),

      AICc_Weight = signif(
        Weight_AICc,
        digits = 5
      )
    ) %>%

    arrange(
      AICc_Rank
    )
}


primary <- models %>%
  filter(
    Candidate_Set ==
      "PDSI_PRIMARY_HYPOTHESES_V1"
  ) %>%
  make_clean_table()


exploratory <- models %>%
  filter(
    Candidate_Set ==
      "PDSI_EXPLORATORY_LEGACY_V1"
  ) %>%
  make_clean_table()


primary_path <- file.path(
  project_root,
  "marss_results",
  "master_tables",
  "COLLABORATOR_PRIMARY_MODEL_TABLE.csv"
)


exploratory_path <- file.path(
  project_root,
  "marss_results",
  "master_tables",
  "COLLABORATOR_EXPLORATORY_MODEL_TABLE.csv"
)


write_csv(
  primary,
  primary_path
)


write_csv(
  exploratory,
  exploratory_path
)


cat("\n")
cat("============================================================\n")
cat("COLLABORATOR MODEL TABLES CREATED\n")
cat("============================================================\n")

cat("\nPRIMARY MODEL TABLE\n")
cat("-------------------\n")
print(
  primary,
  n = Inf,
  width = 200
)

cat("\nSaved:\n")
cat(primary_path, "\n")

cat("\nEXPLORATORY / LEGACY TABLE\n")
cat("--------------------------\n")
print(
  exploratory,
  n = Inf,
  width = 200
)

cat("\nSaved:\n")
cat(exploratory_path, "\n")

cat("\n")
cat("IMPORTANT:\n")
cat("AICc is the primary selection metric.\n")
cat("Do not combine Akaike weights across Candidate_Set values.\n")
