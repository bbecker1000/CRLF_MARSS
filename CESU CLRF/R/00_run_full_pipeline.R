# ==============================================================================
# 00_run_full_pipeline.R
# CRLF MARSS PLUG-AND-PLAY PIPELINE
#
# PURPOSE:
#   Master entry point for the entire CRLF MARSS analysis.
#
# NORMAL USE:
#
#   setwd("F:/CRLF_MARSS")
#   source("00_run_full_pipeline.R")
#
# THE PIPELINE WILL:
#
#   1. Load all modules.
#   2. Load inputs and configuration.
#   3. Validate biological / climate / registry data.
#   4. Build the approved feature catalog.
#   5. Execute enabled registered models.
#   6. Reuse compatible completed fits.
#   7. Reuse completed bootstraps.
#   8. Run new bootstraps only when requested by registry.
#   9. Produce diagnostics.
#  10. Extract parameters when bootstrap CIs are available.
#  11. Produce figures.
#  12. Rebuild master model-selection tables.
#  13. Save a reproducibility snapshot of the run.
#
# IMPORTANT:
#   Scientific hypotheses belong in:
#
#       config/model_registry.csv
#
#   New ordinary models should NOT require editing this master script.
# ==============================================================================


# ==============================================================================
# 0. USER EXECUTION SETTINGS
#
# These control HOW the pipeline runs, not WHAT the scientific models mean.
# ==============================================================================

PROJECT_ROOT <- normalizePath(
  getwd(),
  winslash = "/",
  mustWork = TRUE
)


# NULL = run all enabled models with Fit_Model = TRUE
#
# Example subset:
#
# MODELS_TO_RUN <- c(
#   "M0_Null",
#   "M4_OctDec_RunMean3"
# )

MODELS_TO_RUN <- NULL


# ------------------------------------------------------------------------------

FORCE_REFIT <- FALSE

# TRUE means:
#   ignore compatible saved fit.rds files and refit.
#
# Normally leave FALSE.


# ------------------------------------------------------------------------------

FORCE_BOOTSTRAP <- FALSE

# TRUE means:
#   request bootstrap for models being run.
#
# Normally leave FALSE.
# Prefer controlling bootstrap using Run_Bootstrap in model_registry.csv.


# ------------------------------------------------------------------------------

RUN_DIAGNOSTICS <- TRUE

MAKE_FIGURES <- TRUE


# ==============================================================================
# 1. LOAD REQUIRED PACKAGES
# ==============================================================================

required_packages <- c(
  "MARSS",
  "ggplot2",
  "dplyr",
  "tidyr",
  "stringr",
  "tibble",
  "readr"
)


missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]


if (length(missing_packages) > 0) {
  
  stop(
    paste(
      "Required R packages are missing:",
      paste(
        missing_packages,
        collapse = ", "
      )
    )
  )
}


suppressPackageStartupMessages({
  
  library(MARSS)
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(tibble)
  library(readr)
  
})


# ==============================================================================
# 2. PIPELINE HEADER
# ==============================================================================

pipeline_start_time <- Sys.time()


cat("\n")
cat("================================================================\n")
cat("CRLF MARSS PLUG-AND-PLAY PIPELINE\n")
cat("================================================================\n")

cat(
  "Project root:",
  PROJECT_ROOT,
  "\n"
)

cat(
  "Start time:",
  as.character(
    pipeline_start_time
  ),
  "\n"
)


# ==============================================================================
# 3. LOAD PIPELINE MODULES
# ==============================================================================

module_files <- c(
  
  "R/01_load_inputs.R",
  
  "R/02_validate_inputs.R",
  
  "R/03_build_features.R",
  
  "R/04_build_model_spec.R",
  
  "R/05_fit_model.R",
  
  "R/06_bootstrap_model.R",
  
  "R/07_extract_results.R",
  
  "R/08_model_diagnostics.R",
  
  "R/09_model_selection.R",
  
  "R/10_make_figures.R",
  
  "R/11_run_registry.R"
)


missing_modules <- module_files[
  !file.exists(
    file.path(
      PROJECT_ROOT,
      module_files
    )
  )
]


if (length(missing_modules) > 0) {
  
  stop(
    paste(
      "Pipeline modules are missing:",
      paste(
        missing_modules,
        collapse = ", "
      )
    )
  )
}


cat("\n")
cat("Loading pipeline modules...\n")


for (module_file in module_files) {
  
  source(
    file.path(
      PROJECT_ROOT,
      module_file
    ),
    local = FALSE
  )
}


cat(
  "All pipeline modules loaded.\n"
)


# ==============================================================================
# 4. LOAD INPUTS
# ==============================================================================

inputs <- load_crlf_pipeline_inputs(
  project_root = PROJECT_ROOT
)


# ==============================================================================
# 5. VALIDATE INPUTS
# ==============================================================================

validated <- validate_crlf_pipeline_inputs(
  inputs
)


# ==============================================================================
# 6. BUILD FEATURE CATALOG
# ==============================================================================

features <- build_climate_features(
  
  climate_base =
    validated$climate_base,
  
  biological_years =
    validated$years_vec
)


# ==============================================================================
# 7. CREATE RUN DIRECTORY
#
# Every full pipeline execution gets a reproducibility snapshot.
# ==============================================================================

RUN_ID <- paste0(
  format(
    pipeline_start_time,
    "%Y%m%d_%H%M%S"
  ),
  "_FULL_PIPELINE"
)


run_directory <- file.path(
  PROJECT_ROOT,
  "marss_results",
  "runs",
  RUN_ID
)


dir.create(
  run_directory,
  recursive = TRUE,
  showWarnings = FALSE
)


cat("\n")
cat("Run directory:\n")
cat(run_directory, "\n")


# ==============================================================================
# 8. SNAPSHOT CONFIGURATION USED FOR THIS RUN
# ==============================================================================

write_csv(
  inputs$model_registry,
  file.path(
    run_directory,
    "model_registry_used.csv"
  )
)


write_csv(
  inputs$site_registry,
  file.path(
    run_directory,
    "site_registry_used.csv"
  )
)


write_csv(
  inputs$settings,
  file.path(
    run_directory,
    "pipeline_settings_used.csv"
  )
)


write_csv(
  features$feature_catalog,
  file.path(
    run_directory,
    "feature_catalog_used.csv"
  )
)


write_csv(
  validated$climate_qa,
  file.path(
    run_directory,
    "climate_input_QA.csv"
  )
)


write_csv(
  features$na_summary,
  file.path(
    run_directory,
    "feature_missingness_QA.csv"
  )
)


# ==============================================================================
# 9. BIOLOGICAL INPUT QA SNAPSHOT
# ==============================================================================

biological_QA <- tibble(
  
  N_Sites =
    nrow(
      inputs$dat_matrix
    ),
  
  N_Years =
    ncol(
      inputs$dat_matrix
    ),
  
  First_Year =
    min(
      validated$years_vec
    ),
  
  Last_Year =
    max(
      validated$years_vec
    ),
  
  Total_Site_Years =
    length(
      inputs$dat_matrix
    ),
  
  Observed_Site_Years =
    sum(
      !is.na(
        inputs$dat_matrix
      )
    ),
  
  Missing_Site_Years =
    sum(
      is.na(
        inputs$dat_matrix
      )
    )
)


write_csv(
  biological_QA,
  file.path(
    run_directory,
    "biological_input_QA.csv"
  )
)


# ==============================================================================
# 10. SAVE R SESSION INFORMATION
# ==============================================================================

session_info_path <- file.path(
  run_directory,
  "sessionInfo.txt"
)


capture.output(
  sessionInfo(),
  file = session_info_path
)


# ==============================================================================
# 11. RUN REGISTERED MODEL SUITE
# ==============================================================================

pipeline_result <- run_registered_model_suite(
  
  inputs =
    inputs,
  
  validated =
    validated,
  
  features =
    features,
  
  model_ids =
    MODELS_TO_RUN,
  
  force_refit =
    FORCE_REFIT,
  
  force_bootstrap =
    FORCE_BOOTSTRAP,
  
  run_diagnostics =
    RUN_DIAGNOSTICS,
  
  make_figures =
    MAKE_FIGURES
)


# ==============================================================================
# 12. SAVE THIS RUN'S MODEL LOG
# ==============================================================================

write_csv(
  pipeline_result$run_log,
  file.path(
    run_directory,
    "model_run_log.csv"
  )
)


# ==============================================================================
# 13. SNAPSHOT FINAL MODEL-SELECTION TABLE
# ==============================================================================

write_csv(
  pipeline_result$selection$model_selection,
  file.path(
    run_directory,
    "model_selection_snapshot.csv"
  )
)


write_csv(
  pipeline_result$selection$master_results,
  file.path(
    run_directory,
    "master_model_results_snapshot.csv"
  )
)


# ==============================================================================
# 14. PIPELINE COMPLETION SUMMARY
# ==============================================================================

pipeline_end_time <- Sys.time()


elapsed_minutes <- as.numeric(
  difftime(
    pipeline_end_time,
    pipeline_start_time,
    units = "mins"
  )
)


n_models_requested <- nrow(
  pipeline_result$run_log
)


n_converged <- sum(
  pipeline_result$run_log$Pipeline_Status ==
    "CONVERGED",
  na.rm = TRUE
)


n_errors <- sum(
  pipeline_result$run_log$Pipeline_Status ==
    "PIPELINE_ERROR",
  na.rm = TRUE
)


pipeline_summary <- tibble(
  
  Run_ID =
    RUN_ID,
  
  Pipeline_Start =
    as.character(
      pipeline_start_time
    ),
  
  Pipeline_End =
    as.character(
      pipeline_end_time
    ),
  
  Elapsed_Minutes =
    elapsed_minutes,
  
  Project_Root =
    PROJECT_ROOT,
  
  N_Sites =
    nrow(
      inputs$dat_matrix
    ),
  
  N_Biological_Years =
    ncol(
      inputs$dat_matrix
    ),
  
  First_Biological_Year =
    min(
      validated$years_vec
    ),
  
  Last_Biological_Year =
    max(
      validated$years_vec
    ),
  
  N_Registered_Models =
    nrow(
      inputs$model_registry
    ),
  
  N_Models_Run =
    n_models_requested,
  
  N_Converged =
    n_converged,
  
  N_Pipeline_Errors =
    n_errors,
  
  Force_Refit =
    FORCE_REFIT,
  
  Force_Bootstrap =
    FORCE_BOOTSTRAP,
  
  Diagnostics =
    RUN_DIAGNOSTICS,
  
  Figures =
    MAKE_FIGURES
)


write_csv(
  pipeline_summary,
  file.path(
    run_directory,
    "pipeline_run_summary.csv"
  )
)


# ==============================================================================
# 15. HUMAN-READABLE RUN SUMMARY
# ==============================================================================

summary_lines <- c(
  
  "CRLF MARSS PLUG-AND-PLAY PIPELINE",
  
  "================================",
  
  "",
  
  paste(
    "Run ID:",
    RUN_ID
  ),
  
  paste(
    "Start:",
    pipeline_start_time
  ),
  
  paste(
    "End:",
    pipeline_end_time
  ),
  
  paste(
    "Elapsed minutes:",
    round(
      elapsed_minutes,
      3
    )
  ),
  
  "",
  
  paste(
    "Biological sites:",
    nrow(
      inputs$dat_matrix
    )
  ),
  
  paste(
    "Biological years:",
    min(
      validated$years_vec
    ),
    "-",
    max(
      validated$years_vec
    )
  ),
  
  paste(
    "Registered models:",
    nrow(
      inputs$model_registry
    )
  ),
  
  paste(
    "Models executed:",
    n_models_requested
  ),
  
  paste(
    "Converged:",
    n_converged
  ),
  
  paste(
    "Pipeline errors:",
    n_errors
  ),
  
  "",
  
  paste(
    "Force refit:",
    FORCE_REFIT
  ),
  
  paste(
    "Force bootstrap:",
    FORCE_BOOTSTRAP
  ),
  
  "",
  
  paste(
    "Run directory:",
    run_directory
  )
)


writeLines(
  summary_lines,
  file.path(
    run_directory,
    "pipeline_run_summary.txt"
  )
)


# ==============================================================================
# 16. FINAL CONSOLE REPORT
# ==============================================================================

cat("\n")
cat("================================================================\n")
cat("CRLF MARSS FULL PIPELINE COMPLETE\n")
cat("================================================================\n")


cat(
  "Run ID:",
  RUN_ID,
  "\n"
)


cat(
  "Elapsed minutes:",
  round(
    elapsed_minutes,
    3
  ),
  "\n"
)


cat(
  "Models executed:",
  n_models_requested,
  "\n"
)


cat(
  "Converged:",
  n_converged,
  "\n"
)


cat(
  "Pipeline errors:",
  n_errors,
  "\n"
)


cat("\n")
cat("Run snapshot saved to:\n")
cat(run_directory, "\n")


cat("\n")
cat("Current model-selection table:\n")


print(
  
  pipeline_result$selection$model_selection %>%
    
    select(
      Candidate_Set,
      Rank_AICc,
      Model_ID,
      Pipeline_Model_Status,
      K,
      LogLik,
      AICc,
      Delta_AICc,
      Weight_AICc
    ),
  
  n = Inf,
  width = 160
)


cat("\n")
cat("================================================================\n")
cat("PIPELINE FINISHED SUCCESSFULLY\n")
cat("================================================================\n")