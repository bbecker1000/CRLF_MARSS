# ==============================================================================
# 06_bootstrap_model.R
# CRLF MARSS PLUG-AND-PLAY PIPELINE
#
# PURPOSE:
#   Run parametric bootstrap confidence intervals for one successfully
#   converged MARSS model.
#
# RESPONSIBILITIES:
#   1. Refuse to bootstrap unconverged/failed models.
#   2. Determine bootstrap N from model registry.
#   3. Use a reproducible model-specific seed.
#   4. Run MARSSparamCIs().
#   5. Save the bootstrapped MARSS object.
#   6. Save standardized bootstrap status metadata.
#
# IMPORTANT:
#   This module DOES NOT extract the final long-format parameter table.
#   That happens in 07_extract_results.R.
#
#   This module DOES NOT calculate bootstrap AIC (AICbp).
# ==============================================================================

library(MARSS)
library(dplyr)
library(tibble)
library(readr)


# ==============================================================================
# 1. GET BOOTSTRAP N FOR ONE MODEL
# ==============================================================================

get_model_bootstrap_n <- function(
    fit_result,
    settings
) {
  
  registry_row <- fit_result$registered_spec$registry_row
  
  
  # ---------------------------------------------------------------------------
  # Prefer model-specific registry value
  # ---------------------------------------------------------------------------
  
  if (
    "Bootstrap_N" %in%
    names(registry_row)
  ) {
    
    registry_n <- suppressWarnings(
      as.integer(
        registry_row$Bootstrap_N[[1]]
      )
    )
    
    
    if (
      !is.na(registry_n) &&
      registry_n > 0
    ) {
      
      return(
        registry_n
      )
    }
  }
  
  
  # ---------------------------------------------------------------------------
  # Otherwise use pipeline default
  # ---------------------------------------------------------------------------
  
  get_setting(
    settings,
    "DEFAULT_BOOTSTRAPS",
    type = "integer"
  )
}


# ==============================================================================
# 2. MODEL-SPECIFIC REPRODUCIBLE SEED
#
# We want:
#
#   same master seed
#   +
#   deterministic model-specific offset
#
# So M0 and M1 do not start with identical bootstrap random streams.
# ==============================================================================

make_model_bootstrap_seed <- function(
    master_seed,
    model_id
) {
  
  model_offset <- sum(
    utf8ToInt(
      model_id
    )
  )
  
  
  seed <- as.integer(
    (
      as.numeric(master_seed) +
        as.numeric(model_offset)
    ) %%
      .Machine$integer.max
  )
  
  
  if (
    is.na(seed) ||
    seed <= 0
  ) {
    
    seed <- as.integer(
      master_seed
    )
  }
  
  
  seed
}


# ==============================================================================
# 3. WRITE SKIPPED BOOTSTRAP RECORD
# ==============================================================================

write_skipped_bootstrap <- function(
    fit_result,
    reason
) {
  
  model_id <- fit_result$model_id
  model_dir <- fit_result$model_dir
  
  
  bootstrap_summary <- tibble(
    
    Model_ID =
      model_id,
    
    Bootstrap_Status =
      "SKIPPED",
    
    Fit_Status =
      fit_result$fit_status,
    
    N_Boot_Requested =
      NA_integer_,
    
    Bootstrap_Seed =
      NA_integer_,
    
    Bootstrap_Method =
      "parametric",
    
    Error_Message =
      reason,
    
    Bootstrap_File =
      NA_character_,
    
    Run_ID =
      fit_result$run_id
  )
  
  
  write_csv(
    bootstrap_summary,
    file.path(
      model_dir,
      "bootstrap_summary.csv"
    )
  )
  
  
  cat("\n")
  cat("BOOTSTRAP SKIPPED:", model_id, "\n")
  cat("Reason:", reason, "\n")
  
  
  list(
    
    model_id =
      model_id,
    
    fit_result =
      fit_result,
    
    bootstrap_fit =
      NULL,
    
    bootstrap_status =
      "SKIPPED",
    
    bootstrap_summary =
      bootstrap_summary,
    
    bootstrap_path =
      NA_character_
  )
}


# ==============================================================================
# 4. RUN PARAMETRIC BOOTSTRAP
# ==============================================================================

bootstrap_registered_model <- function(
    fit_result,
    settings
) {
  
  model_id <- fit_result$model_id
  
  
  cat("\n")
  cat("============================================================\n")
  cat("BOOTSTRAPPING REGISTERED MARSS MODEL\n")
  cat("============================================================\n")
  
  cat(
    "Model:",
    model_id,
    "\n"
  )
  
  
  # ===========================================================================
  # CONVERGENCE GATE
  # ===========================================================================
  
  if (
    is.null(
      fit_result$fit
    )
  ) {
    
    return(
      write_skipped_bootstrap(
        fit_result,
        "No fitted MARSS object exists."
      )
    )
  }
  
  
  if (
    !identical(
      fit_result$fit_status,
      "CONVERGED"
    )
  ) {
    
    return(
      write_skipped_bootstrap(
        fit_result,
        paste0(
          "Model fit status is ",
          fit_result$fit_status,
          ", not CONVERGED."
        )
      )
    )
  }
  
  
  final_convergence <- suppressWarnings(
    as.integer(
      fit_result$fit$convergence
    )
  )
  
  
  if (
    length(final_convergence) != 1 ||
    is.na(final_convergence) ||
    final_convergence != 0
  ) {
    
    return(
      write_skipped_bootstrap(
        fit_result,
        paste0(
          "Final MARSS convergence code is ",
          final_convergence,
          ", not 0."
        )
      )
    )
  }
  
  
  # ===========================================================================
  # BOOTSTRAP SETTINGS
  # ===========================================================================
  
  n_boot <- get_model_bootstrap_n(
    fit_result = fit_result,
    settings = settings
  )
  
  
  master_seed <- get_setting(
    settings,
    "MASTER_SEED",
    type = "integer"
  )
  
  
  bootstrap_seed <- make_model_bootstrap_seed(
    master_seed = master_seed,
    model_id = model_id
  )
  
  
  set.seed(
    bootstrap_seed
  )
  
  
  cat(
    "Fit convergence: PASS\n"
  )
  
  cat(
    "Bootstrap method: parametric\n"
  )
  
  cat(
    "Bootstrap replicates:",
    n_boot,
    "\n"
  )
  
  cat(
    "Bootstrap seed:",
    bootstrap_seed,
    "\n"
  )
  
  
  # ===========================================================================
  # RUN PARAMETRIC BOOTSTRAP
  # ===========================================================================
  
  cat("\n")
  cat(
    "Starting MARSS parametric bootstrap CIs...\n"
  )
  
  
  bootstrap_start <- Sys.time()
  
  
  bootstrap_fit <- tryCatch(
    
    MARSSparamCIs(
      fit_result$fit,
      method = "parametric",
      nboot = n_boot,
      silent = TRUE
    ),
    
    error = function(e) {
      e
    }
  )
  
  
  bootstrap_end <- Sys.time()
  
  
  elapsed_minutes <- as.numeric(
    difftime(
      bootstrap_end,
      bootstrap_start,
      units = "mins"
    )
  )
  
  
  # ===========================================================================
  # BOOTSTRAP ERROR
  # ===========================================================================
  
  if (
    inherits(
      bootstrap_fit,
      "error"
    )
  ) {
    
    error_message <- conditionMessage(
      bootstrap_fit
    )
    
    
    bootstrap_summary <- tibble(
      
      Model_ID =
        model_id,
      
      Bootstrap_Status =
        "BOOTSTRAP_ERROR",
      
      Fit_Status =
        fit_result$fit_status,
      
      N_Boot_Requested =
        n_boot,
      
      Bootstrap_Seed =
        bootstrap_seed,
      
      Bootstrap_Method =
        "parametric",
      
      Elapsed_Minutes =
        elapsed_minutes,
      
      Error_Message =
        error_message,
      
      Bootstrap_File =
        NA_character_,
      
      Run_ID =
        fit_result$run_id
    )
    
    
    write_csv(
      bootstrap_summary,
      file.path(
        fit_result$model_dir,
        "bootstrap_summary.csv"
      )
    )
    
    
    writeLines(
      error_message,
      file.path(
        fit_result$model_dir,
        "bootstrap_error.txt"
      )
    )
    
    
    cat("\n")
    cat("BOOTSTRAP ERROR\n")
    cat(error_message, "\n")
    
    
    return(
      
      list(
        
        model_id =
          model_id,
        
        fit_result =
          fit_result,
        
        bootstrap_fit =
          NULL,
        
        bootstrap_status =
          "BOOTSTRAP_ERROR",
        
        bootstrap_summary =
          bootstrap_summary,
        
        bootstrap_path =
          NA_character_
      )
    )
  }
  
  
  # ===========================================================================
  # VERIFY CI COMPONENTS WERE ADDED
  # ===========================================================================
  
  required_components <- c(
    "par.lowCI",
    "par.upCI"
  )
  
  
  missing_components <- required_components[
    !vapply(
      required_components,
      function(x) {
        !is.null(
          bootstrap_fit[[x]]
        )
      },
      logical(1)
    )
  ]
  
  
  if (
    length(
      missing_components
    ) > 0
  ) {
    
    stop(
      paste(
        "Bootstrap finished but expected CI components are missing:",
        paste(
          missing_components,
          collapse = ", "
        )
      )
    )
  }
  
  
  # ===========================================================================
  # SAVE BOOTSTRAPPED FIT
  # ===========================================================================
  
  bootstrap_path <- file.path(
    fit_result$model_dir,
    "fit_bootstrap_CIs.rds"
  )
  
  
  saveRDS(
    bootstrap_fit,
    bootstrap_path
  )
  
  
  # ===========================================================================
  # BOOTSTRAP SUMMARY
  # ===========================================================================
  
  actual_n_boot <- if (
    !is.null(
      bootstrap_fit$par.CI.nboot
    )
  ) {
    
    suppressWarnings(
      as.integer(
        bootstrap_fit$par.CI.nboot
      )
    )
    
  } else {
    
    n_boot
  }
  
  
  ci_method <- if (
    !is.null(
      bootstrap_fit$par.CI.method
    )
  ) {
    
    as.character(
      bootstrap_fit$par.CI.method
    )
    
  } else {
    
    "parametric"
  }
  
  
  ci_alpha <- if (
    !is.null(
      bootstrap_fit$par.CI.alpha
    )
  ) {
    
    as.numeric(
      bootstrap_fit$par.CI.alpha
    )
    
  } else {
    
    0.05
  }
  
  
  bootstrap_summary <- tibble(
    
    Model_ID =
      model_id,
    
    Bootstrap_Status =
      "COMPLETE",
    
    Fit_Status =
      fit_result$fit_status,
    
    N_Boot_Requested =
      n_boot,
    
    N_Boot_Recorded =
      actual_n_boot,
    
    Bootstrap_Seed =
      bootstrap_seed,
    
    Bootstrap_Method =
      ci_method,
    
    CI_Alpha =
      ci_alpha,
    
    Elapsed_Minutes =
      elapsed_minutes,
    
    Error_Message =
      NA_character_,
    
    Bootstrap_File =
      bootstrap_path,
    
    Run_ID =
      fit_result$run_id
  )
  
  
  write_csv(
    bootstrap_summary,
    file.path(
      fit_result$model_dir,
      "bootstrap_summary.csv"
    )
  )
  
  
  # ===========================================================================
  # REPORT
  # ===========================================================================
  
  cat("\n")
  cat("------------------------------------------------------------\n")
  cat("BOOTSTRAP SUMMARY\n")
  cat("------------------------------------------------------------\n")
  
  cat(
    "Model:",
    model_id,
    "\n"
  )
  
  cat(
    "Status: COMPLETE\n"
  )
  
  cat(
    "Method:",
    ci_method,
    "\n"
  )
  
  cat(
    "Requested bootstrap replicates:",
    n_boot,
    "\n"
  )
  
  cat(
    "Recorded bootstrap replicates:",
    actual_n_boot,
    "\n"
  )
  
  cat(
    "CI alpha:",
    ci_alpha,
    "\n"
  )
  
  cat(
    "Elapsed minutes:",
    round(
      elapsed_minutes,
      2
    ),
    "\n"
  )
  
  cat(
    "Saved bootstrapped fit:",
    bootstrap_path,
    "\n"
  )
  
  cat(
    "------------------------------------------------------------\n"
  )
  
  
  # ===========================================================================
  # RETURN STANDARD BOOTSTRAP OBJECT
  # ===========================================================================
  
  list(
    
    model_id =
      model_id,
    
    fit_result =
      fit_result,
    
    bootstrap_fit =
      bootstrap_fit,
    
    bootstrap_status =
      "COMPLETE",
    
    bootstrap_summary =
      bootstrap_summary,
    
    bootstrap_path =
      bootstrap_path
  )
}


cat("\n============================================================\n")
cat("06_bootstrap_model.R LOADED SUCCESSFULLY\n")
cat("============================================================\n")