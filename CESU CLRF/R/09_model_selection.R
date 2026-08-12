# ==============================================================================
# 09_model_selection.R
# CRLF MARSS PLUG-AND-PLAY PIPELINE
#
# PURPOSE:
#   Build standardized master model-selection tables from all registered
#   models that have already been fitted.
#
# RESPONSIBILITIES:
#   1. Read existing model fit summaries.
#   2. Read bootstrap summaries when available.
#   3. Join scientific metadata from the model registry.
#   4. Preserve models that failed or have not yet been run.
#   5. Calculate AIC / AICc rankings WITHIN Candidate_Set only.
#   6. Preserve hypothesis descriptions alongside statistical results.
#   7. Save master comparison tables.
#
# IMPORTANT:
#   This module DOES NOT fit models.
#   This module DOES NOT bootstrap models.
#
#   AIC / AICc are MODEL-LEVEL statistics.
#
#   Bootstrap confidence intervals are PARAMETER-LEVEL results and are
#   produced by 06_bootstrap_model.R and 07_extract_results.R.
# ==============================================================================


library(dplyr)
library(readr)
library(tibble)


# ==============================================================================
# 1. LOGICAL FLAG HELPER
# ==============================================================================

coerce_registry_flag <- function(
    x,
    default = FALSE
) {
  
  if (is.logical(x)) {
    
    x[is.na(x)] <- default
    
    return(x)
  }
  
  
  x_chr <- toupper(
    trimws(
      as.character(x)
    )
  )
  
  
  result <- x_chr %in% c(
    "TRUE",
    "T",
    "1",
    "YES",
    "Y"
  )
  
  
  result[
    is.na(x_chr) |
      x_chr == ""
  ] <- default
  
  
  result
}


# ==============================================================================
# 2. NORMALIZE MODEL REGISTRY
# ==============================================================================

normalize_model_registry <- function(
    model_registry
) {
  
  out <- model_registry
  
  
  # ---------------------------------------------------------------------------
  # Candidate set
  # ---------------------------------------------------------------------------
  
  if (!"Candidate_Set" %in% names(out)) {
    
    out$Candidate_Set <-
      "PDSI_CORE_SITE_SPECIFIC"
  }
  
  
  out$Candidate_Set[
    is.na(out$Candidate_Set) |
      trimws(out$Candidate_Set) == ""
  ] <- "PDSI_CORE_SITE_SPECIFIC"
  
  
  # ---------------------------------------------------------------------------
  # Enabled
  # ---------------------------------------------------------------------------
  
  if (!"Enabled" %in% names(out)) {
    
    out$Enabled <- TRUE
    
  } else {
    
    out$Enabled <- coerce_registry_flag(
      out$Enabled,
      default = TRUE
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Fit model
  # ---------------------------------------------------------------------------
  
  if (!"Fit_Model" %in% names(out)) {
    
    out$Fit_Model <- out$Enabled
    
  } else {
    
    out$Fit_Model <- coerce_registry_flag(
      out$Fit_Model,
      default = TRUE
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Bootstrap
  # ---------------------------------------------------------------------------
  
  if (!"Run_Bootstrap" %in% names(out)) {
    
    out$Run_Bootstrap <- FALSE
    
  } else {
    
    out$Run_Bootstrap <- coerce_registry_flag(
      out$Run_Bootstrap,
      default = FALSE
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Primary analysis
  # ---------------------------------------------------------------------------
  
  if (!"Primary_Analysis" %in% names(out)) {
    
    out$Primary_Analysis <- TRUE
    
  } else {
    
    out$Primary_Analysis <- coerce_registry_flag(
      out$Primary_Analysis,
      default = TRUE
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Comparison role
  #
  # If not explicitly supplied:
  #   Primary_Analysis = TRUE  -> PRIMARY
  #   Primary_Analysis = FALSE -> EXPLORATORY
  # ---------------------------------------------------------------------------
  
  if (!"Comparison_Role" %in% names(out)) {
    
    out$Comparison_Role <- ifelse(
      out$Primary_Analysis,
      "PRIMARY",
      "EXPLORATORY"
    )
    
  } else {
    
    missing_role <-
      is.na(out$Comparison_Role) |
      trimws(out$Comparison_Role) == ""
    
    
    out$Comparison_Role[missing_role] <- ifelse(
      out$Primary_Analysis[missing_role],
      "PRIMARY",
      "EXPLORATORY"
    )
  }
  
  
  out
}


# ==============================================================================
# 3. READ ALL FIT SUMMARIES
# ==============================================================================

read_all_fit_summaries <- function(
    project_root
) {
  
  model_root <- file.path(
    project_root,
    "marss_results",
    "models"
  )
  
  
  if (!dir.exists(model_root)) {
    
    return(
      tibble(
        Model_ID = character()
      )
    )
  }
  
  
  fit_files <- list.files(
    model_root,
    pattern = "^fit_summary\\.csv$",
    recursive = TRUE,
    full.names = TRUE
  )
  
  
  if (length(fit_files) == 0) {
    
    return(
      tibble(
        Model_ID = character()
      )
    )
  }
  
  
  fit_tables <- lapply(
    
    fit_files,
    
    function(path) {
      
      x <- read_csv(
        path,
        show_col_types = FALSE
      )
      
      
      x$Fit_Summary_File <- normalizePath(
        path,
        winslash = "/",
        mustWork = TRUE
      )
      
      
      x
    }
  )
  
  
  bind_rows(
    fit_tables
  )
}


# ==============================================================================
# 4. READ ALL BOOTSTRAP SUMMARIES
# ==============================================================================

read_all_bootstrap_summaries <- function(
    project_root
) {
  
  model_root <- file.path(
    project_root,
    "marss_results",
    "models"
  )
  
  
  if (!dir.exists(model_root)) {
    
    return(
      tibble(
        Model_ID = character()
      )
    )
  }
  
  
  bootstrap_files <- list.files(
    model_root,
    pattern = "^bootstrap_summary\\.csv$",
    recursive = TRUE,
    full.names = TRUE
  )
  
  
  if (length(bootstrap_files) == 0) {
    
    return(
      tibble(
        Model_ID = character()
      )
    )
  }
  
  
  bootstrap_tables <- lapply(
    
    bootstrap_files,
    
    function(path) {
      
      x <- read_csv(
        path,
        show_col_types = FALSE
      )
      
      
      x$Bootstrap_Summary_File <- normalizePath(
        path,
        winslash = "/",
        mustWork = TRUE
      )
      
      
      x
    }
  )
  
  
  bind_rows(
    bootstrap_tables
  )
}


# ==============================================================================
# 5. STANDARDIZE FIT SUMMARY SCHEMA
# ==============================================================================

standardize_fit_summary_schema <- function(
    fit_table
) {
  
  if (!"Model_ID" %in% names(fit_table)) {
    
    fit_table$Model_ID <- character(
      nrow(fit_table)
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Compatibility with earlier pipeline versions
  # ---------------------------------------------------------------------------
  
  if (
    !"Final_Convergence" %in% names(fit_table) &&
    "Convergence_Code" %in% names(fit_table)
  ) {
    
    fit_table$Final_Convergence <-
      fit_table$Convergence_Code
  }
  
  
  if (
    !"Final_Iterations" %in% names(fit_table) &&
    "Num_Iterations" %in% names(fit_table)
  ) {
    
    fit_table$Final_Iterations <-
      fit_table$Num_Iterations
  }
  
  
  # ---------------------------------------------------------------------------
  # Required fields
  # ---------------------------------------------------------------------------
  
  required_defaults <- list(
    
    Fit_Status =
      NA_character_,
    
    Final_Method =
      NA_character_,
    
    Final_Convergence =
      NA_integer_,
    
    Final_Iterations =
      NA_integer_,
    
    K =
      NA_integer_,
    
    N_Free_C =
      NA_integer_,
    
    LogLik =
      NA_real_,
    
    AIC =
      NA_real_,
    
    AICc =
      NA_real_,
    
    Run_ID =
      NA_character_,
    
    Fit_Summary_File =
      NA_character_
  )
  
  
  for (field_name in names(required_defaults)) {
    
    if (!field_name %in% names(fit_table)) {
      
      fit_table[[field_name]] <- rep(
        required_defaults[[field_name]],
        nrow(fit_table)
      )
    }
  }
  
  
  # ---------------------------------------------------------------------------
  # One fit summary per Model_ID
  # ---------------------------------------------------------------------------
  
  if (nrow(fit_table) > 0) {
    
    fit_table <- fit_table %>%
      
      arrange(
        Model_ID,
        Run_ID
      ) %>%
      
      group_by(
        Model_ID
      ) %>%
      
      slice_tail(
        n = 1
      ) %>%
      
      ungroup()
  }
  
  
  fit_table
}


# ==============================================================================
# 6. STANDARDIZE BOOTSTRAP SUMMARY SCHEMA
# ==============================================================================

standardize_bootstrap_summary_schema <- function(
    bootstrap_table
) {
  
  if (!"Model_ID" %in% names(bootstrap_table)) {
    
    bootstrap_table$Model_ID <- character(
      nrow(bootstrap_table)
    )
  }
  
  
  required_defaults <- list(
    
    Bootstrap_Status =
      NA_character_,
    
    N_Boot_Requested =
      NA_integer_,
    
    N_Boot_Recorded =
      NA_integer_,
    
    Bootstrap_Seed =
      NA_integer_,
    
    Bootstrap_Method =
      NA_character_,
    
    CI_Alpha =
      NA_real_,
    
    Elapsed_Minutes =
      NA_real_,
    
    Bootstrap_File =
      NA_character_,
    
    Bootstrap_Summary_File =
      NA_character_,
    
    Run_ID =
      NA_character_
  )
  
  
  for (field_name in names(required_defaults)) {
    
    if (!field_name %in% names(bootstrap_table)) {
      
      bootstrap_table[[field_name]] <- rep(
        required_defaults[[field_name]],
        nrow(bootstrap_table)
      )
    }
  }
  
  
  # ---------------------------------------------------------------------------
  # One bootstrap summary per Model_ID
  # ---------------------------------------------------------------------------
  
  if (nrow(bootstrap_table) > 0) {
    
    bootstrap_table <- bootstrap_table %>%
      
      arrange(
        Model_ID,
        Run_ID
      ) %>%
      
      group_by(
        Model_ID
      ) %>%
      
      slice_tail(
        n = 1
      ) %>%
      
      ungroup()
  }
  
  
  bootstrap_table
}


# ==============================================================================
# 7. ENSURE COLUMNS EXIST
# ==============================================================================

ensure_columns_exist <- function(
    df,
    defaults
) {
  
  for (field_name in names(defaults)) {
    
    if (!field_name %in% names(df)) {
      
      df[[field_name]] <- rep(
        defaults[[field_name]],
        nrow(df)
      )
    }
  }
  
  
  df
}


# ==============================================================================
# 8. RANK ONE CANDIDATE SET
#
# IMPORTANT:
#   Only CONVERGED models with finite AIC and AICc values are eligible.
#
#   AIC weights and AICc weights are calculated separately WITHIN each
#   Candidate_Set.
# ==============================================================================

rank_candidate_set <- function(
    df
) {
  
  df$Selection_Eligible <-
    
    !is.na(df$Fit_Status) &
    
    df$Fit_Status ==
    "CONVERGED" &
    
    is.finite(
      df$AIC
    ) &
    
    is.finite(
      df$AICc
    )
  
  
  # ---------------------------------------------------------------------------
  # Initialize
  # ---------------------------------------------------------------------------
  
  df$Delta_AIC <-
    NA_real_
  
  df$AIC_Relative_Likelihood <-
    NA_real_
  
  df$Weight_AIC <-
    NA_real_
  
  df$Rank_AIC <-
    NA_integer_
  
  
  df$Delta_AICc <-
    NA_real_
  
  df$AICc_Relative_Likelihood <-
    NA_real_
  
  df$Weight_AICc <-
    NA_real_
  
  df$Rank_AICc <-
    NA_integer_
  
  
  eligible <- which(
    df$Selection_Eligible
  )
  
  
  if (length(eligible) == 0) {
    
    return(df)
  }
  
  
  # ===========================================================================
  # AIC
  # ===========================================================================
  
  min_aic <- min(
    df$AIC[eligible]
  )
  
  
  df$Delta_AIC[eligible] <-
    
    df$AIC[eligible] -
    min_aic
  
  
  df$AIC_Relative_Likelihood[eligible] <-
    
    exp(
      -0.5 *
        df$Delta_AIC[eligible]
    )
  
  
  aic_denominator <- sum(
    df$AIC_Relative_Likelihood[eligible]
  )
  
  
  if (
    is.finite(aic_denominator) &&
    aic_denominator > 0
  ) {
    
    df$Weight_AIC[eligible] <-
      
      df$AIC_Relative_Likelihood[eligible] /
      aic_denominator
  }
  
  
  df$Rank_AIC[eligible] <- as.integer(
    
    rank(
      df$AIC[eligible],
      ties.method = "min"
    )
  )
  
  
  # ===========================================================================
  # AICc
  # ===========================================================================
  
  min_aicc <- min(
    df$AICc[eligible]
  )
  
  
  df$Delta_AICc[eligible] <-
    
    df$AICc[eligible] -
    min_aicc
  
  
  df$AICc_Relative_Likelihood[eligible] <-
    
    exp(
      -0.5 *
        df$Delta_AICc[eligible]
    )
  
  
  aicc_denominator <- sum(
    df$AICc_Relative_Likelihood[eligible]
  )
  
  
  if (
    is.finite(aicc_denominator) &&
    aicc_denominator > 0
  ) {
    
    df$Weight_AICc[eligible] <-
      
      df$AICc_Relative_Likelihood[eligible] /
      aicc_denominator
  }
  
  
  df$Rank_AICc[eligible] <- as.integer(
    
    rank(
      df$AICc[eligible],
      ties.method = "min"
    )
  )
  
  
  df
}


# ==============================================================================
# 9. BUILD MASTER MODEL-SELECTION TABLE
# ==============================================================================

build_master_model_selection <- function(
    project_root,
    model_registry
) {
  
  cat("\n")
  cat("============================================================\n")
  cat("BUILDING MASTER MARSS MODEL-SELECTION TABLE\n")
  cat("============================================================\n")
  
  
  # ===========================================================================
  # NORMALIZE REGISTRY
  # ===========================================================================
  
  registry <- normalize_model_registry(
    model_registry
  )
  
  
  # ===========================================================================
  # READ CURRENT OUTPUTS
  # ===========================================================================
  
  fit_table <- read_all_fit_summaries(
    project_root
  )
  
  
  fit_table <- standardize_fit_summary_schema(
    fit_table
  )
  
  
  bootstrap_table <- read_all_bootstrap_summaries(
    project_root
  )
  
  
  bootstrap_table <- standardize_bootstrap_summary_schema(
    bootstrap_table
  )
  
  
  cat(
    "Registered models:",
    nrow(registry),
    "\n"
  )
  
  
  cat(
    "Fit summaries found:",
    nrow(fit_table),
    "\n"
  )
  
  
  cat(
    "Bootstrap summaries found:",
    nrow(bootstrap_table),
    "\n"
  )
  
  
  # ===========================================================================
  # REGISTRY FIELDS
  #
  # These are the scientific metadata we want attached to every result.
  # ===========================================================================
  
  registry_fields <- c(
    
    "Sort_Order",
    
    "Model_Number",
    
    "Model_ID",
    
    "Model_Name",
    
    "Enabled",
    
    "Fit_Model",
    
    "Run_Bootstrap",
    
    "Primary_Analysis",
    
    "Candidate_Set",
    
    "Comparison_Role",
    
    "Model_Family",
    
    "Scientific_Question",
    
    "Hypothesis",
    
    "Biological_Interpretation",
    
    "Response",
    
    "Covariates",
    
    "Season_Focus",
    
    "Climate_Window",
    
    "Time_Structure",
    
    "Lag_Structure",
    
    "Interaction",
    
    "C_Structure",
    
    "B_Structure",
    
    "U_Structure",
    
    "Q_Structure",
    
    "R_Structure",
    
    "Expected_C_Parameters",
    
    "Expected_Total_K",
    
    "Bootstrap_N",
    
    "Status",
    
    "Notes"
  )
  
  
  registry_fields <- intersect(
    registry_fields,
    names(registry)
  )
  
  
  registry_small <- registry %>%
    
    select(
      all_of(
        registry_fields
      )
    )
  
  
  # ===========================================================================
  # REGISTRY IS SCIENTIFIC SOURCE OF TRUTH
  #
  # Remove duplicated scientific fields that may have been saved in older
  # fit summaries.
  # ===========================================================================
  
  fit_table <- fit_table %>%
    
    select(
      -any_of(
        c(
          "Model_Family",
          "Hypothesis",
          "Biological_Interpretation",
          "Covariates"
        )
      )
    )
  
  
  # ===========================================================================
  # JOIN REGISTRY + FIT
  # ===========================================================================
  
  master <- registry_small %>%
    
    left_join(
      fit_table,
      by = "Model_ID"
    )
  
  
  # ===========================================================================
  # PREPARE BOOTSTRAP TABLE
  # ===========================================================================
  
  bootstrap_small <- bootstrap_table %>%
    
    select(
      any_of(
        c(
          "Model_ID",
          "Bootstrap_Status",
          "N_Boot_Requested",
          "N_Boot_Recorded",
          "Bootstrap_Seed",
          "Bootstrap_Method",
          "CI_Alpha",
          "Elapsed_Minutes",
          "Bootstrap_File",
          "Bootstrap_Summary_File"
        )
      )
    )
  
  
  # ---------------------------------------------------------------------------
  # Avoid ambiguous Elapsed_Minutes if fit summaries also contain one.
  # ---------------------------------------------------------------------------
  
  if ("Elapsed_Minutes" %in% names(bootstrap_small)) {
    
    bootstrap_small <- bootstrap_small %>%
      
      rename(
        Bootstrap_Elapsed_Minutes =
          Elapsed_Minutes
      )
  }
  
  
  # ===========================================================================
  # JOIN BOOTSTRAP
  # ===========================================================================
  
  master <- master %>%
    
    left_join(
      bootstrap_small,
      by = "Model_ID"
    )
  
  
  # ===========================================================================
  # ENSURE ALL REQUIRED COLUMNS EXIST
  # ===========================================================================
  
  master <- ensure_columns_exist(
    
    master,
    
    list(
      
      Sort_Order =
        NA_real_,
      
      Model_Number =
        NA_character_,
      
      Model_Name =
        NA_character_,
      
      Enabled =
        TRUE,
      
      Fit_Model =
        TRUE,
      
      Run_Bootstrap =
        FALSE,
      
      Primary_Analysis =
        TRUE,
      
      Candidate_Set =
        "PDSI_CORE_SITE_SPECIFIC",
      
      Comparison_Role =
        NA_character_,
      
      Model_Family =
        NA_character_,
      
      Scientific_Question =
        NA_character_,
      
      Hypothesis =
        NA_character_,
      
      Biological_Interpretation =
        NA_character_,
      
      Response =
        NA_character_,
      
      Covariates =
        NA_character_,
      
      Season_Focus =
        NA_character_,
      
      Climate_Window =
        NA_character_,
      
      Time_Structure =
        NA_character_,
      
      Lag_Structure =
        NA_character_,
      
      Interaction =
        NA,
      
      C_Structure =
        NA_character_,
      
      B_Structure =
        NA_character_,
      
      U_Structure =
        NA_character_,
      
      Q_Structure =
        NA_character_,
      
      R_Structure =
        NA_character_,
      
      Expected_C_Parameters =
        NA_integer_,
      
      Expected_Total_K =
        NA_integer_,
      
      Bootstrap_N =
        NA_integer_,
      
      Status =
        NA_character_,
      
      Notes =
        NA_character_,
      
      Fit_Status =
        NA_character_,
      
      Final_Method =
        NA_character_,
      
      Final_Convergence =
        NA_integer_,
      
      Final_Iterations =
        NA_integer_,
      
      K =
        NA_integer_,
      
      N_Free_C =
        NA_integer_,
      
      LogLik =
        NA_real_,
      
      AIC =
        NA_real_,
      
      AICc =
        NA_real_,
      
      Run_ID =
        NA_character_,
      
      Fit_Summary_File =
        NA_character_,
      
      Bootstrap_Status =
        NA_character_,
      
      N_Boot_Requested =
        NA_integer_,
      
      N_Boot_Recorded =
        NA_integer_,
      
      Bootstrap_Seed =
        NA_integer_,
      
      Bootstrap_Method =
        NA_character_,
      
      CI_Alpha =
        NA_real_,
      
      Bootstrap_Elapsed_Minutes =
        NA_real_,
      
      Bootstrap_File =
        NA_character_,
      
      Bootstrap_Summary_File =
        NA_character_
    )
  )
  
  
  # ===========================================================================
  # PIPELINE MODEL STATUS
  # ===========================================================================
  
  master <- master %>%
    
    mutate(
      
      Has_Fit =
        !is.na(
          Fit_Status
        ),
      
      
      Pipeline_Model_Status =
        case_when(
          
          !Enabled ~
            "DISABLED",
          
          !Fit_Model ~
            "NOT_REQUESTED",
          
          is.na(Fit_Status) ~
            "NOT_YET_FIT",
          
          Fit_Status == "CONVERGED" ~
            "CONVERGED",
          
          Fit_Status == "FAILED_CONVERGENCE" ~
            "FAILED_CONVERGENCE",
          
          Fit_Status == "FIT_ERROR" ~
            "FIT_ERROR",
          
          TRUE ~
            Fit_Status
        )
    )
  
  
  # ===========================================================================
  # RANK WITHIN EACH CANDIDATE SET
  # ===========================================================================
  
  candidate_sets <- unique(
    master$Candidate_Set
  )
  
  
  candidate_sets <- candidate_sets[
    !is.na(candidate_sets)
  ]
  
  
  ranked_sets <- lapply(
    
    candidate_sets,
    
    function(candidate_name) {
      
      candidate_df <- master %>%
        
        filter(
          Candidate_Set ==
            candidate_name
        )
      
      
      rank_candidate_set(
        candidate_df
      )
    }
  )
  
  
  if (length(ranked_sets) == 0) {
    
    master_ranked <- rank_candidate_set(
      master
    )
    
  } else {
    
    master_ranked <- bind_rows(
      ranked_sets
    )
  }
  
  
  # ===========================================================================
  # FUTURE BOOTSTRAP-AIC PLACEHOLDERS
  #
  # MARSS parameter CI bootstrap is NOT the same thing as AICbp.
  # ===========================================================================
  
  if (!"AICbp" %in% names(master_ranked)) {
    
    master_ranked$AICbp <-
      NA_real_
  }
  
  
  if (!"Delta_AICbp" %in% names(master_ranked)) {
    
    master_ranked$Delta_AICbp <-
      NA_real_
  }
  
  
  if (!"Weight_AICbp" %in% names(master_ranked)) {
    
    master_ranked$Weight_AICbp <-
      NA_real_
  }
  
  
  # ===========================================================================
  # MODELS NOT YET FIT
  # ===========================================================================
  
  missing_fits <- master_ranked %>%
    
    filter(
      Enabled,
      Fit_Model,
      !Has_Fit
    ) %>%
    
    arrange(
      Candidate_Set,
      Sort_Order
    ) %>%
    
    select(
      
      Candidate_Set,
      
      Comparison_Role,
      
      Model_Number,
      
      Model_ID,
      
      Model_Name,
      
      Model_Family,
      
      Scientific_Question,
      
      Hypothesis,
      
      Covariates,
      
      Season_Focus,
      
      Time_Structure
    )
  
  
  # ===========================================================================
  # FAILED MODELS
  # ===========================================================================
  
  failed_models <- master_ranked %>%
    
    filter(
      Has_Fit,
      Fit_Status != "CONVERGED"
    ) %>%
    
    arrange(
      Candidate_Set,
      Sort_Order
    )
  
  
  # ===========================================================================
  # CLEAN HUMAN-READABLE MODEL-SELECTION TABLE
  #
  # IMPORTANT FIX:
  #
  # Sort_Order is used HERE, before select() removes it from the final
  # publication-style table.
  # ===========================================================================
  
  model_selection <- master_ranked %>%
    
    arrange(
      
      Candidate_Set,
      
      is.na(
        Rank_AICc
      ),
      
      Rank_AICc,
      
      Sort_Order
    ) %>%
    
    select(
      
      # -----------------------------------------------------------------------
      # Candidate-set information
      # -----------------------------------------------------------------------
      
      Candidate_Set,
      
      Comparison_Role,
      
      Primary_Analysis,
      
      Rank_AICc,
      
      Rank_AIC,
      
      
      # -----------------------------------------------------------------------
      # Model identity
      # -----------------------------------------------------------------------
      
      Model_Number,
      
      Model_ID,
      
      Model_Name,
      
      Model_Family,
      
      
      # -----------------------------------------------------------------------
      # Scientific hypothesis
      # -----------------------------------------------------------------------
      
      Scientific_Question,
      
      Hypothesis,
      
      Biological_Interpretation,
      
      Response,
      
      Covariates,
      
      Season_Focus,
      
      Climate_Window,
      
      Time_Structure,
      
      Lag_Structure,
      
      Interaction,
      
      
      # -----------------------------------------------------------------------
      # MARSS structure
      # -----------------------------------------------------------------------
      
      C_Structure,
      
      B_Structure,
      
      U_Structure,
      
      Q_Structure,
      
      R_Structure,
      
      Expected_C_Parameters,
      
      Expected_Total_K,
      
      
      # -----------------------------------------------------------------------
      # Pipeline status
      # -----------------------------------------------------------------------
      
      Pipeline_Model_Status,
      
      Fit_Status,
      
      Final_Method,
      
      Final_Convergence,
      
      Final_Iterations,
      
      
      # -----------------------------------------------------------------------
      # Actual model complexity
      # -----------------------------------------------------------------------
      
      K,
      
      N_Free_C,
      
      
      # -----------------------------------------------------------------------
      # Likelihood and information criteria
      # -----------------------------------------------------------------------
      
      LogLik,
      
      AIC,
      
      Delta_AIC,
      
      Weight_AIC,
      
      AICc,
      
      Delta_AICc,
      
      Weight_AICc,
      
      
      # -----------------------------------------------------------------------
      # Future bootstrap-AIC fields
      # -----------------------------------------------------------------------
      
      AICbp,
      
      Delta_AICbp,
      
      Weight_AICbp,
      
      
      # -----------------------------------------------------------------------
      # Parameter bootstrap / CI status
      # -----------------------------------------------------------------------
      
      Run_Bootstrap,
      
      Bootstrap_N,
      
      Bootstrap_Status,
      
      N_Boot_Requested,
      
      N_Boot_Recorded,
      
      Bootstrap_Seed,
      
      Bootstrap_Method,
      
      CI_Alpha,
      
      Bootstrap_Elapsed_Minutes,
      
      
      # -----------------------------------------------------------------------
      # Documentation
      # -----------------------------------------------------------------------
      
      Status,
      
      Notes,
      
      
      # -----------------------------------------------------------------------
      # Reproducibility
      # -----------------------------------------------------------------------
      
      Run_ID
    )
  
  
  # ===========================================================================
  # SAVE MASTER TABLES
  # ===========================================================================
  
  output_dir <- file.path(
    project_root,
    "marss_results",
    "master_tables"
  )
  
  
  dir.create(
    output_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  
  master_path <- file.path(
    output_dir,
    "master_model_results.csv"
  )
  
  
  selection_path <- file.path(
    output_dir,
    "master_model_selection.csv"
  )
  
  
  missing_path <- file.path(
    output_dir,
    "registered_models_not_yet_fit.csv"
  )
  
  
  failed_path <- file.path(
    output_dir,
    "failed_models.csv"
  )
  
  
  write_csv(
    master_ranked,
    master_path
  )
  
  
  write_csv(
    model_selection,
    selection_path
  )
  
  
  write_csv(
    missing_fits,
    missing_path
  )
  
  
  write_csv(
    failed_models,
    failed_path
  )
  
  
  # ===========================================================================
  # REPORT
  # ===========================================================================
  
  cat("\n")
  cat("------------------------------------------------------------\n")
  cat("MASTER MODEL-SELECTION SUMMARY\n")
  cat("------------------------------------------------------------\n")
  
  
  cat(
    "Registered models:",
    nrow(registry),
    "\n"
  )
  
  
  cat(
    "Models with fit records:",
    sum(
      master_ranked$Has_Fit,
      na.rm = TRUE
    ),
    "\n"
  )
  
  
  cat(
    "Converged models:",
    sum(
      master_ranked$Fit_Status == "CONVERGED",
      na.rm = TRUE
    ),
    "\n"
  )
  
  
  cat(
    "Registered models not yet fit:",
    nrow(missing_fits),
    "\n"
  )
  
  
  cat(
    "Failed/error models:",
    nrow(failed_models),
    "\n"
  )
  
  
  cat(
    "Candidate sets:",
    paste(
      unique(
        master_ranked$Candidate_Set
      ),
      collapse = ", "
    ),
    "\n"
  )
  
  
  cat("\n")
  cat("Saved:\n")
  cat(master_path, "\n")
  cat(selection_path, "\n")
  cat(missing_path, "\n")
  cat(failed_path, "\n")
  
  
  # ===========================================================================
  # PRINT CURRENT AICc RANKING
  # ===========================================================================
  
  cat("\n")
  cat("CURRENT AICc RANKING\n")
  cat("====================\n")
  
  
  print(
    
    model_selection %>%
      
      select(
        
        Candidate_Set,
        
        Rank_AICc,
        
        Model_Number,
        
        Model_ID,
        
        Model_Name,
        
        Pipeline_Model_Status,
        
        K,
        
        LogLik,
        
        AIC,
        
        AICc,
        
        Delta_AICc,
        
        Weight_AICc,
        
        Bootstrap_Status
      ),
    
    n = Inf,
    
    width = 180
  )
  
  
  # ===========================================================================
  # RETURN
  # ===========================================================================
  
  list(
    
    master_results =
      master_ranked,
    
    model_selection =
      model_selection,
    
    missing_fits =
      missing_fits,
    
    failed_models =
      failed_models,
    
    master_path =
      master_path,
    
    selection_path =
      selection_path
  )
}


# ==============================================================================
# MODULE LOAD MESSAGE
# ==============================================================================

cat("\n============================================================\n")
cat("09_model_selection.R LOADED SUCCESSFULLY\n")
cat("============================================================\n")