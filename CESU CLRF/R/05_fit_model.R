# ==============================================================================
# 05_fit_model.R
# CRLF MARSS PLUG-AND-PLAY PIPELINE
#
# PURPOSE:
#   Fit one validated MARSS model specification produced by
#   04_build_model_spec.R.
#
# OPTIMIZATION STRATEGY:
#
#   1. KEM provides a robust initial search / warm start.
#   2. If KEM convergence code == 0:
#          accept KEM.
#   3. If KEM returns a usable but incomplete convergence code:
#          pass KEM estimates to BFGS.
#   4. If BFGS convergence == 0:
#          accept BFGS as final fit.
#   5. Otherwise:
#          record FAILED_CONVERGENCE.
#
# IMPORTANT:
#   This module DOES NOT bootstrap.
# ==============================================================================

library(MARSS)
library(dplyr)
library(tibble)
library(readr)


# ==============================================================================
# 1. MODEL OUTPUT DIRECTORY
# ==============================================================================

get_model_output_directory <- function(
    project_root,
    model_id
) {
  
  model_dir <- file.path(
    project_root,
    "marss_results",
    "models",
    model_id
  )
  
  dir.create(
    model_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  dir.create(
    file.path(
      model_dir,
      "figures"
    ),
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  dir.create(
    file.path(
      model_dir,
      "diagnostics"
    ),
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  model_dir
}


# ==============================================================================
# 2. SAFE FIT VALUE
# ==============================================================================

safe_fit_value <- function(
    fit,
    field,
    default = NA
) {
  
  if (
    is.null(fit) ||
    is.null(fit[[field]])
  ) {
    
    return(default)
  }
  
  fit[[field]]
}


# ==============================================================================
# 3. MODEL DEFINITION TABLE
# ==============================================================================

build_model_definition_table <- function(
    registered_spec
) {
  
  registry_row <- registered_spec$registry_row
  
  tibble(
    
    Model_ID =
      registered_spec$model_id,
    
    Model_Family =
      registered_spec$model_family,
    
    Hypothesis =
      registered_spec$hypothesis,
    
    Biological_Interpretation =
      if (
        "Biological_Interpretation" %in%
        names(registry_row)
      ) {
        
        as.character(
          registry_row$Biological_Interpretation[[1]]
        )
        
      } else {
        
        NA_character_
      },
    
    Covariates =
      if (
        length(
          registered_spec$covariates
        ) == 0
      ) {
        
        ""
        
      } else {
        
        paste(
          registered_spec$covariates,
          collapse = "|"
        )
      },
    
    C_Structure =
      as.character(
        registry_row$C_Structure[[1]]
      ),
    
    B_Structure =
      as.character(
        registry_row$B_Structure[[1]]
      ),
    
    U_Structure =
      as.character(
        registry_row$U_Structure[[1]]
      ),
    
    Q_Structure =
      as.character(
        registry_row$Q_Structure[[1]]
      ),
    
    R_Structure =
      as.character(
        registry_row$R_Structure[[1]]
      ),
    
    Expected_Free_C =
      registered_spec$expected_free_C
  )
}


# ==============================================================================
# 4. RUN ID
# ==============================================================================

make_model_run_id <- function(
    model_id
) {
  
  timestamp <- format(
    Sys.time(),
    "%Y%m%d_%H%M%S"
  )
  
  paste0(
    timestamp,
    "_",
    model_id
  )
}


# ==============================================================================
# 5. CLASSIFY KEM CONVERGENCE
#
# MARSS KEM return codes relevant to us:
#
#   0  = full convergence
#
#   1  = maxit reached; neither abstol nor log-log passed
#   3  = abstol reached but no log-log information
#   10 = abstol passed but log-log not passed before maxit
#   11 = log-log passed but abstol did not
#   12 = abstol not reached and insufficient log-log information
#
# Codes >= 50 generally indicate algorithm/numerical errors rather than
# ordinary incomplete convergence.
# ==============================================================================

classify_kem_convergence <- function(
    convergence_code
) {
  
  if (
    is.na(
      convergence_code
    )
  ) {
    
    return(
      "UNKNOWN"
    )
  }
  
  
  if (
    convergence_code == 0
  ) {
    
    return(
      "CONVERGED"
    )
  }
  
  
  if (
    convergence_code %in%
    c(
      1,
      3,
      10,
      11,
      12
    )
  ) {
    
    return(
      "INCOMPLETE_CONVERGENCE"
    )
  }
  
  
  if (
    convergence_code >= 50
  ) {
    
    return(
      "NUMERICAL_ERROR"
    )
  }
  
  
  "OTHER_NONZERO"
}


# ==============================================================================
# 6. FIT REGISTERED MODEL
# ==============================================================================

fit_registered_model <- function(
    registered_spec,
    dat_matrix,
    settings,
    project_root
) {
  
  model_id <- registered_spec$model_id
  
  
  # ---------------------------------------------------------------------------
  # Output location
  # ---------------------------------------------------------------------------
  
  model_dir <- get_model_output_directory(
    project_root = project_root,
    model_id = model_id
  )
  
  
  run_id <- make_model_run_id(
    model_id
  )
  
  
  # ---------------------------------------------------------------------------
  # Settings
  # ---------------------------------------------------------------------------
  
  kem_maxit <- get_setting(
    settings,
    "MARSS_KEM_MAXIT",
    type = "integer"
  )
  
  
  bfgs_maxit <- get_setting(
    settings,
    "MARSS_BFGS_MAXIT",
    type = "integer"
  )
  
  
  master_seed <- get_setting(
    settings,
    "MASTER_SEED",
    type = "integer"
  )
  
  
  set.seed(
    master_seed
  )
  
  
  # ---------------------------------------------------------------------------
  # Header
  # ---------------------------------------------------------------------------
  
  cat("\n")
  cat("============================================================\n")
  cat("FITTING REGISTERED MARSS MODEL\n")
  cat("============================================================\n")
  
  cat(
    "Model:",
    model_id,
    "\n"
  )
  
  cat(
    "Family:",
    registered_spec$model_family,
    "\n"
  )
  
  cat(
    "Hypothesis:",
    registered_spec$hypothesis,
    "\n"
  )
  
  cat(
    "Expected free C parameters:",
    registered_spec$expected_free_C,
    "\n"
  )
  
  cat(
    "KEM maximum iterations:",
    kem_maxit,
    "\n"
  )
  
  cat(
    "BFGS maximum iterations:",
    bfgs_maxit,
    "\n"
  )
  
  
  # ===========================================================================
  # PRIMARY KEM FIT
  # ===========================================================================
  
  cat("\nStarting primary KEM fit...\n")
  
  
  kem_fit <- tryCatch(
    
    MARSS(
      y = dat_matrix,
      model = registered_spec$model_spec,
      method = "kem",
      control = list(
        maxit = kem_maxit
      ),
      silent = TRUE
    ),
    
    error = function(e) {
      e
    }
  )
  
  
  # ===========================================================================
  # KEM EXECUTION ERROR
  # ===========================================================================
  
  if (
    inherits(
      kem_fit,
      "error"
    )
  ) {
    
    error_message <- conditionMessage(
      kem_fit
    )
    
    
    fit_summary <- tibble(
      
      Model_ID =
        model_id,
      
      Model_Family =
        registered_spec$model_family,
      
      Hypothesis =
        registered_spec$hypothesis,
      
      Fit_Status =
        "FIT_ERROR",
      
      KEM_Convergence =
        NA_integer_,
      
      KEM_Iterations =
        NA_integer_,
      
      Final_Method =
        NA_character_,
      
      Final_Convergence =
        NA_integer_,
      
      Final_Iterations =
        NA_integer_,
      
      K =
        NA_integer_,
      
      N_Free_C =
        registered_spec$expected_free_C,
      
      LogLik =
        NA_real_,
      
      AIC =
        NA_real_,
      
      AICc =
        NA_real_,
      
      Error_Message =
        error_message,
      
      Run_ID =
        run_id
    )
    
    
    write_csv(
      fit_summary,
      file.path(
        model_dir,
        "fit_summary.csv"
      )
    )
    
    
    writeLines(
      error_message,
      file.path(
        model_dir,
        "fit_error.txt"
      )
    )
    
    
    return(
      list(
        
        model_id =
          model_id,
        
        registered_spec =
          registered_spec,
        
        fit =
          NULL,
        
        fit_status =
          "FIT_ERROR",
        
        final_method =
          NA_character_,
        
        fit_summary =
          fit_summary,
        
        model_dir =
          model_dir,
        
        run_id =
          run_id
      )
    )
  }
  
  
  # ===========================================================================
  # KEM RESULTS
  # ===========================================================================
  
  kem_convergence <- as.integer(
    safe_fit_value(
      kem_fit,
      "convergence",
      NA_integer_
    )
  )
  
  
  kem_iterations <- as.integer(
    safe_fit_value(
      kem_fit,
      "numIter",
      NA_integer_
    )
  )
  
  
  kem_class <- classify_kem_convergence(
    kem_convergence
  )
  
  
  cat(
    "KEM iterations:",
    kem_iterations,
    "\n"
  )
  
  cat(
    "KEM convergence code:",
    kem_convergence,
    "\n"
  )
  
  cat(
    "KEM convergence classification:",
    kem_class,
    "\n"
  )
  
  
  saveRDS(
    kem_fit,
    file.path(
      model_dir,
      "fit_KEM_initial.rds"
    )
  )
  
  
  # ===========================================================================
  # DEFAULT FINAL FIT = KEM
  # ===========================================================================
  
  final_fit <- kem_fit
  
  final_method <- "KEM"
  
  bfgs_attempted <- FALSE
  
  bfgs_convergence <- NA_integer_
  
  bfgs_iterations <- NA_integer_
  
  bfgs_error <- NA_character_
  
  
  # ===========================================================================
  # BFGS FALLBACK
  #
  # Run BFGS whenever KEM is not fully converged but still produced
  # a usable fit.
  # ===========================================================================
  
  if (
    kem_class %in%
    c(
      "INCOMPLETE_CONVERGENCE",
      "OTHER_NONZERO"
    )
  ) {
    
    bfgs_attempted <- TRUE
    
    
    cat("\n")
    cat("KEM did not achieve full convergence.\n")
    
    cat(
      "Passing KEM estimates to BFGS for final optimization...\n"
    )
    
    
    # -------------------------------------------------------------------------
    # Use KEM MLE estimates as BFGS starting values
    # -------------------------------------------------------------------------
    
    bfgs_inits <- tryCatch(
      
      coef(
        kem_fit,
        what = "par"
      ),
      
      error = function(e) {
        e
      }
    )
    
    
    if (
      inherits(
        bfgs_inits,
        "error"
      )
    ) {
      
      bfgs_error <- paste(
        "Could not extract KEM starting values:",
        conditionMessage(
          bfgs_inits
        )
      )
      
      
      cat(
        bfgs_error,
        "\n"
      )
      
    } else {
      
      
      # -----------------------------------------------------------------------
      # BFGS fit
      # -----------------------------------------------------------------------
      
      bfgs_fit <- tryCatch(
        
        MARSS(
          y = dat_matrix,
          model = registered_spec$model_spec,
          method = "BFGS",
          inits = bfgs_inits,
          control = list(
            maxit = bfgs_maxit
          ),
          silent = TRUE
        ),
        
        error = function(e) {
          e
        }
      )
      
      
      # -----------------------------------------------------------------------
      # BFGS execution error
      # -----------------------------------------------------------------------
      
      if (
        inherits(
          bfgs_fit,
          "error"
        )
      ) {
        
        bfgs_error <- conditionMessage(
          bfgs_fit
        )
        
        
        cat(
          "BFGS execution error:\n",
          bfgs_error,
          "\n"
        )
        
      } else {
        
        
        bfgs_convergence <- as.integer(
          safe_fit_value(
            bfgs_fit,
            "convergence",
            NA_integer_
          )
        )
        
        
        bfgs_iterations <- as.integer(
          safe_fit_value(
            bfgs_fit,
            "numIter",
            NA_integer_
          )
        )
        
        
        cat(
          "BFGS iterations:",
          bfgs_iterations,
          "\n"
        )
        
        
        cat(
          "BFGS convergence code:",
          bfgs_convergence,
          "\n"
        )
        
        
        saveRDS(
          bfgs_fit,
          file.path(
            model_dir,
            "fit_BFGS_fallback.rds"
          )
        )
        
        
        # ---------------------------------------------------------------------
        # Accept BFGS as the final optimizer result
        # ---------------------------------------------------------------------
        
        final_fit <- bfgs_fit
        
        final_method <- "BFGS"
      }
    }
  }
  
  
  # ===========================================================================
  # FINAL CONVERGENCE
  # ===========================================================================
  
  final_convergence <- as.integer(
    safe_fit_value(
      final_fit,
      "convergence",
      NA_integer_
    )
  )
  
  
  final_iterations <- as.integer(
    safe_fit_value(
      final_fit,
      "numIter",
      NA_integer_
    )
  )
  
  
  fit_status <- if (
    !is.na(
      final_convergence
    ) &&
    final_convergence == 0
  ) {
    
    "CONVERGED"
    
  } else {
    
    "FAILED_CONVERGENCE"
  }
  
  
  # ===========================================================================
  # SAVE FINAL FIT
  # ===========================================================================
  
  final_fit_path <- file.path(
    model_dir,
    "fit.rds"
  )
  
  
  saveRDS(
    final_fit,
    final_fit_path
  )
  
  
  # ===========================================================================
  # MODEL DEFINITION
  # ===========================================================================
  
  model_definition <- build_model_definition_table(
    registered_spec
  )
  
  
  write_csv(
    model_definition,
    file.path(
      model_dir,
      "model_definition.csv"
    )
  )
  
  
  # ===========================================================================
  # FIT SUMMARY
  # ===========================================================================
  
  fit_summary <- tibble(
    
    Model_ID =
      model_id,
    
    Model_Family =
      registered_spec$model_family,
    
    Hypothesis =
      registered_spec$hypothesis,
    
    Fit_Status =
      fit_status,
    
    KEM_Convergence =
      kem_convergence,
    
    KEM_Iterations =
      kem_iterations,
    
    BFGS_Attempted =
      bfgs_attempted,
    
    BFGS_Convergence =
      bfgs_convergence,
    
    BFGS_Iterations =
      bfgs_iterations,
    
    Final_Method =
      final_method,
    
    Final_Convergence =
      final_convergence,
    
    Final_Iterations =
      final_iterations,
    
    K =
      as.integer(
        safe_fit_value(
          final_fit,
          "num.params",
          NA_integer_
        )
      ),
    
    N_Free_C =
      as.integer(
        registered_spec$expected_free_C
      ),
    
    LogLik =
      as.numeric(
        safe_fit_value(
          final_fit,
          "logLik",
          NA_real_
        )
      ),
    
    AIC =
      as.numeric(
        safe_fit_value(
          final_fit,
          "AIC",
          NA_real_
        )
      ),
    
    AICc =
      as.numeric(
        safe_fit_value(
          final_fit,
          "AICc",
          NA_real_
        )
      ),
    
    Error_Message =
      bfgs_error,
    
    Run_ID =
      run_id
  )
  
  
  write_csv(
    fit_summary,
    file.path(
      model_dir,
      "fit_summary.csv"
    )
  )
  
  
  # ===========================================================================
  # SAVE MARSS WARNINGS / ERRORS
  # ===========================================================================
  
  fit_messages <- safe_fit_value(
    final_fit,
    "errors",
    NULL
  )
  
  
  if (
    !is.null(
      fit_messages
    )
  ) {
    
    writeLines(
      as.character(
        fit_messages
      ),
      file.path(
        model_dir,
        "diagnostics",
        "MARSS_messages.txt"
      )
    )
  }
  
  
  # ===========================================================================
  # CONSOLE REPORT
  # ===========================================================================
  
  cat("\n")
  cat("------------------------------------------------------------\n")
  cat("FINAL MODEL FIT SUMMARY\n")
  cat("------------------------------------------------------------\n")
  
  
  cat(
    "Model:",
    model_id,
    "\n"
  )
  
  
  cat(
    "Status:",
    fit_status,
    "\n"
  )
  
  
  cat(
    "KEM convergence:",
    kem_convergence,
    "\n"
  )
  
  
  cat(
    "BFGS attempted:",
    bfgs_attempted,
    "\n"
  )
  
  
  if (
    bfgs_attempted
  ) {
    
    cat(
      "BFGS convergence:",
      bfgs_convergence,
      "\n"
    )
  }
  
  
  cat(
    "Final method:",
    final_method,
    "\n"
  )
  
  
  cat(
    "Final convergence:",
    final_convergence,
    "\n"
  )
  
  
  cat(
    "K:",
    safe_fit_value(
      final_fit,
      "num.params",
      NA_integer_
    ),
    "\n"
  )
  
  
  cat(
    "LogLik:",
    safe_fit_value(
      final_fit,
      "logLik",
      NA_real_
    ),
    "\n"
  )
  
  
  cat(
    "AIC:",
    safe_fit_value(
      final_fit,
      "AIC",
      NA_real_
    ),
    "\n"
  )
  
  
  cat(
    "AICc:",
    safe_fit_value(
      final_fit,
      "AICc",
      NA_real_
    ),
    "\n"
  )
  
  
  cat(
    "Saved final fit:",
    final_fit_path,
    "\n"
  )
  
  
  cat(
    "------------------------------------------------------------\n"
  )
  
  
  # ===========================================================================
  # RETURN STANDARD FIT OBJECT
  # ===========================================================================
  
  list(
    
    model_id =
      model_id,
    
    registered_spec =
      registered_spec,
    
    fit =
      final_fit,
    
    fit_status =
      fit_status,
    
    final_method =
      final_method,
    
    fit_summary =
      fit_summary,
    
    model_definition =
      model_definition,
    
    model_dir =
      model_dir,
    
    fit_path =
      final_fit_path,
    
    run_id =
      run_id
  )
}


cat("\n============================================================\n")
cat("05_fit_model.R LOADED SUCCESSFULLY\n")
cat("============================================================\n")