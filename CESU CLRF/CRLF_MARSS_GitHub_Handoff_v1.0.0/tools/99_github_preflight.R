# ==============================================================================
# 99_github_preflight.R
# CRLF MARSS PIPELINE
#
# PURPOSE:
#   Non-destructive preflight checks before GitHub handoff/upload.
#
# USAGE:
#   setwd("F:/CRLF_MARSS")
#   source("tools/99_github_preflight.R")
#
# This script DOES NOT modify or delete project files.
# ==============================================================================

project_root <- normalizePath(
  getwd(),
  winslash = "/",
  mustWork = TRUE
)

cat("\n============================================================\n")
cat("CRLF MARSS GITHUB PREFLIGHT\n")
cat("============================================================\n")
cat("Project root:", project_root, "\n\n")

# ------------------------------------------------------------------------------
# Required project files
# ------------------------------------------------------------------------------

required_files <- c(
  "README.md",
  "QUICK_START.md",
  "CHANGELOG.md",
  ".gitignore",
  "00_run_full_pipeline.R",
  "config/model_registry.csv",
  "config/site_registry.csv",
  "config/pipeline_settings.csv",
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
  "R/11_run_registry.R",
  "docs/METHODS_AND_JUSTIFICATIONS.md",
  "docs/MODEL_REGISTRY_GUIDE.md",
  "docs/DATA_DICTIONARY.md",
  "docs/OUTPUT_GUIDE.md",
  "docs/TROUBLESHOOTING.md",
  "docs/HANDOFF_CHECKLIST.md",
  "docs/RELEASE_DECISIONS.md"
)

required_paths <- file.path(project_root, required_files)
required_exists <- file.exists(required_paths)

required_report <- data.frame(
  File = required_files,
  Exists = required_exists,
  stringsAsFactors = FALSE
)

cat("REQUIRED FILES\n")
cat("--------------\n")
print(required_report, row.names = FALSE)

if (any(!required_exists)) {
  cat("\nWARNING: Missing required handoff files:\n")
  cat(paste0("  - ", required_files[!required_exists], collapse = "\n"), "\n")
} else {
  cat("\nPASS: All required handoff files are present.\n")
}

# ------------------------------------------------------------------------------
# Scan files and sizes
# ------------------------------------------------------------------------------

all_files <- list.files(
  project_root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)

all_files <- all_files[file.info(all_files)$isdir %in% FALSE]
info <- file.info(all_files)

size_mb <- info$size / (1024^2)
rel_paths <- substring(
  normalizePath(all_files, winslash = "/", mustWork = FALSE),
  nchar(project_root) + 2
)

file_table <- data.frame(
  File = rel_paths,
  Size_MB = round(size_mb, 3),
  stringsAsFactors = FALSE
)

large25 <- file_table[file_table$Size_MB >= 25, , drop = FALSE]
large100 <- file_table[file_table$Size_MB >= 100, , drop = FALSE]

cat("\n\nFILES >= 25 MB\n")
cat("--------------\n")
if (nrow(large25) == 0) {
  cat("None.\n")
} else {
  print(large25[order(-large25$Size_MB), ], row.names = FALSE)
}

cat("\nFILES >= 100 MB\n")
cat("---------------\n")
if (nrow(large100) == 0) {
  cat("None.\n")
} else {
  print(large100[order(-large100$Size_MB), ], row.names = FALSE)
  cat("WARNING: Treat files >=100 MB as a conservative red flag and verify current host limits before push.\n")
}

# ------------------------------------------------------------------------------
# RDS inventory
# ------------------------------------------------------------------------------

rds_files <- file_table[grepl("\\.rds$", file_table$File, ignore.case = TRUE), , drop = FALSE]

cat("\n\nRDS FILE INVENTORY\n")
cat("------------------\n")
if (nrow(rds_files) == 0) {
  cat("None found.\n")
} else {
  print(rds_files[order(-rds_files$Size_MB), ], row.names = FALSE)
  cat("Review these against .gitignore before staging.\n")
}

# ------------------------------------------------------------------------------
# Obvious sensitive/local filenames
# ------------------------------------------------------------------------------

sensitive_patterns <- c(
  "\\.env$",
  "token",
  "credential",
  "secret",
  "password",
  "private",
  "restricted"
)

sensitive_hit <- rep(FALSE, nrow(file_table))
for (pat in sensitive_patterns) {
  sensitive_hit <- sensitive_hit | grepl(pat, file_table$File, ignore.case = TRUE)
}

sensitive_files <- file_table[sensitive_hit, , drop = FALSE]

cat("\n\nFILES REQUIRING PRIVACY/CREDENTIAL REVIEW\n")
cat("-----------------------------------------\n")
if (nrow(sensitive_files) == 0) {
  cat("No filenames matched the simple warning patterns.\n")
} else {
  print(sensitive_files, row.names = FALSE)
  cat("These matches are warnings only; inspect them manually.\n")
}

# ------------------------------------------------------------------------------
# Registry checks if readr is available
# ------------------------------------------------------------------------------

if (requireNamespace("readr", quietly = TRUE)) {
  registry_path <- file.path(project_root, "config/model_registry.csv")

  if (file.exists(registry_path)) {
    registry <- readr::read_csv(registry_path, show_col_types = FALSE)

    required_registry_fields <- c(
      "Model_ID",
      "Candidate_Set",
      "Covariates",
      "C_Structure",
      "Fit_Model",
      "Run_Bootstrap"
    )

    missing_registry_fields <- setdiff(required_registry_fields, names(registry))

    cat("\n\nMODEL REGISTRY\n")
    cat("--------------\n")
    cat("Rows:", nrow(registry), "\n")

    if (length(missing_registry_fields) > 0) {
      cat("WARNING: Missing expected registry fields:\n")
      cat(paste0("  - ", missing_registry_fields, collapse = "\n"), "\n")
    } else {
      cat("PASS: Core registry fields present.\n")
    }

    if ("Model_ID" %in% names(registry)) {
      dup_ids <- unique(registry$Model_ID[duplicated(registry$Model_ID)])
      if (length(dup_ids) > 0) {
        cat("WARNING: Duplicate Model_ID values:\n")
        cat(paste0("  - ", dup_ids, collapse = "\n"), "\n")
      } else {
        cat("PASS: Model_ID values are unique.\n")
      }
    }
  }
}

# ------------------------------------------------------------------------------
# Master selection snapshot
# ------------------------------------------------------------------------------

selection_path <- file.path(
  project_root,
  "marss_results",
  "master_tables",
  "master_model_selection.csv"
)

cat("\n\nMASTER MODEL-SELECTION TABLE\n")
cat("----------------------------\n")
if (file.exists(selection_path)) {
  cat("Found:", selection_path, "\n")
  if (requireNamespace("readr", quietly = TRUE)) {
    sel <- readr::read_csv(selection_path, show_col_types = FALSE)
    cat("Rows:", nrow(sel), "\n")
    if (all(c("Model_ID", "Pipeline_Model_Status") %in% names(sel))) {
      print(table(sel$Pipeline_Model_Status, useNA = "ifany"))
    }
  }
} else {
  cat("WARNING: master_model_selection.csv not found.\n")
}

# ------------------------------------------------------------------------------
# Git status if Git is available and repo initialized
# ------------------------------------------------------------------------------

cat("\n\nGIT STATUS\n")
cat("----------\n")

git_available <- nzchar(Sys.which("git"))
git_dir <- file.path(project_root, ".git")

if (!git_available) {
  cat("Git executable not found on PATH.\n")
} else if (!dir.exists(git_dir)) {
  cat("No .git directory found. Repository may not be initialized yet.\n")
} else {
  status <- tryCatch(
    system2("git", c("status", "--short"), stdout = TRUE, stderr = TRUE),
    error = function(e) paste("Unable to read git status:", conditionMessage(e))
  )
  if (length(status) == 0) {
    cat("Working tree clean.\n")
  } else {
    cat(paste(status, collapse = "\n"), "\n")
  }
}

cat("\n============================================================\n")
cat("PREFLIGHT COMPLETE\n")
cat("============================================================\n")
cat("This script is advisory and made no changes to project files.\n")
cat("Review docs/HANDOFF_CHECKLIST.md and docs/RELEASE_DECISIONS.md before upload.\n")
