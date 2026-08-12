# ==============================================================================
# 08_model_diagnostics.R
# CRLF MARSS PLUG-AND-PLAY PIPELINE
#
# PURPOSE:
#   Create standardized diagnostics for a fitted registered MARSS model.
#
# RESPONSIBILITIES:
#   1. Record biological observation coverage.
#   2. Record optimization / likelihood diagnostics.
#   3. Calculate MARSS residuals safely.
#   4. Save the complete residual object.
#   5. Save an inventory of the residual object's structure.
#
# IMPORTANT:
#   This module does NOT refit.
#   This module does NOT bootstrap.
# ==============================================================================

library(MARSS)
library(dplyr)
library(tibble)
library(readr)


# ==============================================================================
# 1. OBJECT DIMENSION HELPER
# ==============================================================================

describe_object_dimensions <- function(x) {
  
  d <- dim(x)
  
  if (is.null(d)) {
    
    return(
      as.character(
        length(x)
      )
    )
  }
  
  paste(
    d,
    collapse = " x "
  )
}


# ==============================================================================
# 2. RESIDUAL OBJECT INVENTORY
# ==============================================================================

inventory_residual_object <- function(
    residual_object,
    model_id
) {
  
  if (is.null(residual_object)) {
    
    return(
      tibble(
        Model_ID = model_id,
        Component = NA_character_,
        Class = NA_character_,
        Dimensions = NA_character_
      )
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # If returned object has named components
  # ---------------------------------------------------------------------------
  
  if (
    is.list(residual_object) &&
    !is.null(names(residual_object))
  ) {
    
    component_names <- names(
      residual_object
    )
    
    
    return(
      tibble(
        
        Model_ID =
          model_id,
        
        Component =
          component_names,
        
        Class =
          vapply(
            residual_object,
            function(x) {
              paste(
                class(x),
                collapse = "|"
              )
            },
            character(1)
          ),
        
        Dimensions =
          vapply(
            residual_object,
            describe_object_dimensions,
            character(1)
          )
      )
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Non-list object
  # ---------------------------------------------------------------------------
  
  tibble(
    
    Model_ID =
      model_id,
    
    Component =
      "Residual_Object",
    
    Class =
      paste(
        class(residual_object),
        collapse = "|"
      ),
    
    Dimensions =
      describe_object_dimensions(
        residual_object
      )
  )
}


# ==============================================================================
# 3. MODEL / DATA DIAGNOSTICS
# ==============================================================================

build_fit_diagnostics_table <- function(
    fit_result,
    dat_matrix,
    residual_success
) {
  
  model_id <- fit_result$model_id
  
  fit_summary <- fit_result$fit_summary
  
  
  n_total_cells <- length(
    dat_matrix
  )
  
  
  n_observed <- sum(
    !is.na(
      dat_matrix
    )
  )
  
  
  n_missing <- sum(
    is.na(
      dat_matrix
    )
  )
  
  
  observation_fraction <- n_observed /
    n_total_cells
  
  
  tibble(
    
    Model_ID =
      model_id,
    
    Model_Family =
      fit_result$registered_spec$model_family,
    
    Fit_Status =
      fit_result$fit_status,
    
    Final_Method =
      fit_result$final_method,
    
    Final_Convergence =
      fit_summary$Final_Convergence[[1]],
    
    Final_Iterations =
      fit_summary$Final_Iterations[[1]],
    
    N_Sites =
      nrow(
        dat_matrix
      ),
    
    N_Years =
      ncol(
        dat_matrix
      ),
    
    Total_Site_Years =
      n_total_cells,
    
    Observed_Site_Years =
      n_observed,
    
    Missing_Site_Years =
      n_missing,
    
    Observation_Fraction =
      observation_fraction,
    
    K =
      fit_summary$K[[1]],
    
    N_Free_C =
      fit_summary$N_Free_C[[1]],
    
    LogLik =
      fit_summary$LogLik[[1]],
    
    AIC =
      fit_summary$AIC[[1]],
    
    AICc =
      fit_summary$AICc[[1]],
    
    Residuals_Available =
      residual_success,
    
    Run_ID =
      fit_result$run_id
  )
}


# ==============================================================================
# 4. RUN MODEL DIAGNOSTICS
# ==============================================================================

diagnose_registered_model <- function(
    fit_result,
    dat_matrix
) {
  
  model_id <- fit_result$model_id
  
  
  cat("\n")
  cat("============================================================\n")
  cat("RUNNING REGISTERED MODEL DIAGNOSTICS\n")
  cat("============================================================\n")
  
  cat(
    "Model:",
    model_id,
    "\n"
  )
  
  
  # ===========================================================================
  # FIT GATE
  # ===========================================================================
  
  if (
    is.null(
      fit_result$fit
    )
  ) {
    
    stop(
      paste(
        "Cannot diagnose",
        model_id,
        "because no fitted MARSS object exists."
      )
    )
  }
  
  
  if (
    !identical(
      fit_result$fit_status,
      "CONVERGED"
    )
  ) {
    
    warning(
      paste(
        model_id,
        "did not have CONVERGED status.",
        "Diagnostics will still be saved for documentation."
      )
    )
  }
  
  
  model_dir <- fit_result$model_dir
  
  
  diagnostics_dir <- file.path(
    model_dir,
    "diagnostics"
  )
  
  
  dir.create(
    diagnostics_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  
  # ===========================================================================
  # MARSS RESIDUALS
  # ===========================================================================
  
  cat(
    "Calculating MARSS tt1 residuals...\n"
  )
  
  
  residual_attempt <- tryCatch(
    
    MARSSresiduals(
      fit_result$fit,
      type = "tt1"
    ),
    
    error = function(e) {
      e
    }
  )
  
  
  # ---------------------------------------------------------------------------
  # Residual failure
  # ---------------------------------------------------------------------------
  
  if (
    inherits(
      residual_attempt,
      "error"
    )
  ) {
    
    residual_success <- FALSE
    
    residual_object <- NULL
    
    residual_error <- conditionMessage(
      residual_attempt
    )
    
    
    writeLines(
      residual_error,
      file.path(
        diagnostics_dir,
        "residual_error.txt"
      )
    )
    
    
    cat(
      "Residual calculation failed:\n",
      residual_error,
      "\n"
    )
    
  } else {
    
    residual_success <- TRUE
    
    residual_object <- residual_attempt
    
    residual_error <- NA_character_
    
    
    saveRDS(
      residual_object,
      file.path(
        diagnostics_dir,
        "MARSS_residuals_tt1.rds"
      )
    )
    
    
    cat(
      "Residual calculation PASS.\n"
    )
  }
  
  
  # ===========================================================================
  # RESIDUAL STRUCTURE INVENTORY
  # ===========================================================================
  
  residual_inventory <- inventory_residual_object(
    residual_object = residual_object,
    model_id = model_id
  )
  
  
  write_csv(
    residual_inventory,
    file.path(
      diagnostics_dir,
      "residual_object_inventory.csv"
    )
  )
  
  
  # ===========================================================================
  # CORE FIT / DATA DIAGNOSTICS
  # ===========================================================================
  
  fit_diagnostics <- build_fit_diagnostics_table(
    fit_result = fit_result,
    dat_matrix = dat_matrix,
    residual_success = residual_success
  )
  
  
  fit_diagnostics <- fit_diagnostics %>%
    mutate(
      Residual_Error =
        residual_error
    )
  
  
  write_csv(
    fit_diagnostics,
    file.path(
      diagnostics_dir,
      "fit_diagnostics.csv"
    )
  )
  
  
  # ===========================================================================
  # OBSERVATION COVERAGE BY SITE
  # ===========================================================================
  
  site_coverage <- tibble(
    
    Site_ID =
      rownames(
        dat_matrix
      ),
    
    N_Years =
      ncol(
        dat_matrix
      ),
    
    N_Observed =
      rowSums(
        !is.na(
          dat_matrix
        )
      ),
    
    N_Missing =
      rowSums(
        is.na(
          dat_matrix
        )
      )
  ) %>%
    
    mutate(
      
      Fraction_Observed =
        N_Observed /
        N_Years,
      
      Model_ID =
        model_id
    ) %>%
    
    relocate(
      Model_ID
    )
  
  
  write_csv(
    site_coverage,
    file.path(
      diagnostics_dir,
      "observation_coverage_by_site.csv"
    )
  )
  
  
  # ===========================================================================
  # REPORT
  # ===========================================================================
  
  cat("\n")
  cat("------------------------------------------------------------\n")
  cat("MODEL DIAGNOSTICS SUMMARY\n")
  cat("------------------------------------------------------------\n")
  
  
  cat(
    "Sites:",
    nrow(
      dat_matrix
    ),
    "\n"
  )
  
  
  cat(
    "Years:",
    ncol(
      dat_matrix
    ),
    "\n"
  )
  
  
  cat(
    "Observed site-years:",
    sum(
      !is.na(
        dat_matrix
      )
    ),
    "\n"
  )
  
  
  cat(
    "Missing site-years:",
    sum(
      is.na(
        dat_matrix
      )
    ),
    "\n"
  )
  
  
  cat(
    "Residual object created:",
    residual_success,
    "\n"
  )
  
  
  cat(
    "Diagnostics directory:",
    diagnostics_dir,
    "\n"
  )
  
  
  cat(
    "------------------------------------------------------------\n"
  )
  
  
  # ===========================================================================
  # RETURN
  # ===========================================================================
  
  list(
    
    model_id =
      model_id,
    
    fit_diagnostics =
      fit_diagnostics,
    
    site_coverage =
      site_coverage,
    
    residual_object =
      residual_object,
    
    residual_inventory =
      residual_inventory,
    
    residual_success =
      residual_success,
    
    diagnostics_dir =
      diagnostics_dir
  )
}


cat("\n============================================================\n")
cat("08_model_diagnostics.R LOADED SUCCESSFULLY\n")
cat("============================================================\n")