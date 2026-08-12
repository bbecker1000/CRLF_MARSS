# ==============================================================================
# 07_extract_results.R
# CRLF MARSS PLUG-AND-PLAY PIPELINE
#
# PURPOSE:
#   Convert a successfully bootstrapped MARSS model into standardized,
#   human-readable parameter tables.
#
# OUTPUT:
#   Each model receives:
#
#       parameters.csv
#       parameters_C_climate.csv
#       parameter_QA.csv
#
# STANDARDIZED PARAMETER TYPES:
#
#   U   = population growth / drift
#   Q   = process variance
#   x0  = initial latent state
#   C   = site-specific covariate response
#
# IMPORTANT:
#   This module DOES NOT refit or re-bootstrap anything.
# ==============================================================================

library(MARSS)
library(dplyr)
library(tibble)
library(readr)
library(stringr)


# ==============================================================================
# 1. SAFE COEFFICIENT EXTRACTION
# ==============================================================================

safe_coef_vector <- function(
    fit_object,
    what = NULL
) {
  
  result <- tryCatch(
    
    {
      if (is.null(what)) {
        
        coef(
          fit_object,
          type = "vector"
        )
        
      } else {
        
        coef(
          fit_object,
          type = "vector",
          what = what
        )
      }
    },
    
    error = function(e) {
      NULL
    }
  )
  
  result
}


# ==============================================================================
# 2. BUILD SITE REGEX
# ==============================================================================

build_site_regex <- function(
    site_registry
) {
  
  site_ids <- site_registry %>%
    filter(Active) %>%
    pull(Site_ID)
  
  # Longest first protects against future IDs where one is a substring
  # of another.
  site_ids <- site_ids[
    order(
      nchar(site_ids),
      decreasing = TRUE
    )
  ]
  
  paste0(
    "(",
    paste(
      site_ids,
      collapse = "|"
    ),
    ")"
  )
}


# ==============================================================================
# 3. IDENTIFY PARAMETER TYPE
# ==============================================================================

classify_marss_parameter <- function(
    parameter_name
) {
  
  if (
    grepl(
      "^C([._]|$)",
      parameter_name,
      ignore.case = FALSE
    )
  ) {
    
    return("C")
  }
  
  
  if (
    grepl(
      "^U([._]|$)",
      parameter_name,
      ignore.case = FALSE
    )
  ) {
    
    return("U")
  }
  
  
  if (
    grepl(
      "^Q([._]|$)",
      parameter_name,
      ignore.case = FALSE
    )
  ) {
    
    return("Q")
  }
  
  
  if (
    grepl(
      "^(x0|X0)([._]|$)",
      parameter_name
    )
  ) {
    
    return("x0")
  }
  
  
  "OTHER"
}


# ==============================================================================
# 4. EXTRACT SITE ID FROM PARAMETER NAME
# ==============================================================================

extract_parameter_site <- function(
    parameter_name,
    site_regex
) {
  
  site_hit <- str_extract(
    parameter_name,
    site_regex
  )
  
  if (
    length(site_hit) == 0 ||
    is.na(site_hit)
  ) {
    
    return(
      NA_character_
    )
  }
  
  site_hit
}


# ==============================================================================
# 5. EXTRACT COVARIATE FROM SITE-SPECIFIC C PARAMETER
#
# Examples potentially returned by MARSS:
#
#   C.C_LS01_PDSI_JanMar
#   C_LS01_PDSI_JanMar
#
# Both should become:
#
#   PDSI_JanMar
# ==============================================================================

extract_C_covariate <- function(
    parameter_name,
    site_id
) {
  
  if (
    is.na(site_id)
  ) {
    
    return(
      NA_character_
    )
  }
  
  
  cleaned <- parameter_name %>%
    
    str_replace(
      "^C\\.",
      ""
    ) %>%
    
    str_replace(
      "^C_",
      ""
    )
  
  
  covariate <- str_replace(
    cleaned,
    paste0(
      "^.*?",
      site_id,
      "_"
    ),
    ""
  )
  
  
  if (
    identical(
      covariate,
      cleaned
    )
  ) {
    
    return(
      NA_character_
    )
  }
  
  
  covariate
}


# ==============================================================================
# 6. SITE → WATERSHED LOOKUP
# ==============================================================================

get_parameter_watershed <- function(
    site_id,
    site_registry
) {
  
  if (
    is.na(site_id)
  ) {
    
    return(
      NA_character_
    )
  }
  
  
  hit <- site_registry %>%
    filter(
      Active,
      Site_ID == site_id
    )
  
  
  if (
    nrow(hit) != 1
  ) {
    
    return(
      NA_character_
    )
  }
  
  
  as.character(
    hit$Watershed[[1]]
  )
}


# ==============================================================================
# 7. EXTRACT STANDARDIZED PARAMETERS
# ==============================================================================

extract_registered_model_parameters <- function(
    bootstrap_result,
    site_registry
) {
  
  model_id <- bootstrap_result$model_id
  
  
  cat("\n")
  cat("============================================================\n")
  cat("EXTRACTING REGISTERED MODEL PARAMETERS\n")
  cat("============================================================\n")
  
  cat(
    "Model:",
    model_id,
    "\n"
  )
  
  
  # ===========================================================================
  # REQUIRE COMPLETED BOOTSTRAP
  # ===========================================================================
  
  if (
    !identical(
      bootstrap_result$bootstrap_status,
      "COMPLETE"
    )
  ) {
    
    stop(
      paste(
        "Cannot extract bootstrap parameter CIs for",
        model_id,
        "because bootstrap status is",
        bootstrap_result$bootstrap_status
      )
    )
  }
  
  
  fit_object <- bootstrap_result$bootstrap_fit
  
  
  if (
    is.null(
      fit_object
    )
  ) {
    
    stop(
      paste(
        "Bootstrap fit object is missing for model:",
        model_id
      )
    )
  }
  
  
  fit_result <- bootstrap_result$fit_result
  
  registered_spec <- fit_result$registered_spec
  
  
  # ===========================================================================
  # EXTRACT ESTIMATES AND CONFIDENCE INTERVALS
  # ===========================================================================
  
  estimates <- safe_coef_vector(
    fit_object
  )
  
  lower_ci <- safe_coef_vector(
    fit_object,
    what = "par.lowCI"
  )
  
  upper_ci <- safe_coef_vector(
    fit_object,
    what = "par.upCI"
  )
  
  
  if (
    is.null(estimates)
  ) {
    
    stop(
      paste(
        "Could not extract parameter estimates for:",
        model_id
      )
    )
  }
  
  
  if (
    is.null(lower_ci) ||
    is.null(upper_ci)
  ) {
    
    stop(
      paste(
        "Bootstrap CIs could not be extracted for:",
        model_id
      )
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Parameter names
  # ---------------------------------------------------------------------------
  
  parameter_names <- names(
    estimates
  )
  
  
  if (
    is.null(parameter_names)
  ) {
    
    stop(
      "Extracted MARSS coefficient vector has no parameter names."
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Match CIs by parameter name
  # ---------------------------------------------------------------------------
  
  lower_values <- lower_ci[
    match(
      parameter_names,
      names(lower_ci)
    )
  ]
  
  
  upper_values <- upper_ci[
    match(
      parameter_names,
      names(upper_ci)
    )
  ]
  
  
  # ===========================================================================
  # BUILD RAW PARAMETER TABLE
  # ===========================================================================
  
  parameter_table <- tibble(
    
    Model_ID =
      model_id,
    
    Model_Family =
      registered_spec$model_family,
    
    Hypothesis =
      registered_spec$hypothesis,
    
    Parameter =
      parameter_names,
    
    Estimate =
      as.numeric(
        estimates
      ),
    
    Lower_95 =
      as.numeric(
        lower_values
      ),
    
    Upper_95 =
      as.numeric(
        upper_values
      )
  )
  
  
  # ===========================================================================
  # PARSE PARAMETER MEANING
  # ===========================================================================
  
  site_regex <- build_site_regex(
    site_registry
  )
  
  
  parameter_table <- parameter_table %>%
    
    rowwise() %>%
    
    mutate(
      
      Parameter_Type =
        classify_marss_parameter(
          Parameter
        ),
      
      Site_ID =
        extract_parameter_site(
          Parameter,
          site_regex
        ),
      
      Watershed =
        get_parameter_watershed(
          Site_ID,
          site_registry
        ),
      
      Covariate =
        if (
          Parameter_Type == "C"
        ) {
          
          extract_C_covariate(
            Parameter,
            Site_ID
          )
          
        } else {
          
          NA_character_
        },
      
      CI_Excludes_Zero =
        if (
          !is.na(Lower_95) &&
          !is.na(Upper_95)
        ) {
          
          Lower_95 > 0 |
            Upper_95 < 0
          
        } else {
          
          NA
        }
    ) %>%
    
    ungroup()
  
  
  # ===========================================================================
  # ADD MODEL / BOOTSTRAP METADATA
  # ===========================================================================
  
  n_boot <- suppressWarnings(
    as.integer(
      bootstrap_result$bootstrap_summary$N_Boot_Recorded[[1]]
    )
  )
  
  
  parameter_table <- parameter_table %>%
    
    mutate(
      
      Bootstrap_Status =
        bootstrap_result$bootstrap_status,
      
      N_Boot =
        n_boot,
      
      Run_ID =
        fit_result$run_id
    ) %>%
    
    select(
      
      Model_ID,
      
      Model_Family,
      
      Hypothesis,
      
      Site_ID,
      
      Watershed,
      
      Parameter_Type,
      
      Covariate,
      
      Parameter,
      
      Estimate,
      
      Lower_95,
      
      Upper_95,
      
      CI_Excludes_Zero,
      
      Bootstrap_Status,
      
      N_Boot,
      
      Run_ID
    )
  
  
  # ===========================================================================
  # PARAMETER COUNT QA
  # ===========================================================================
  
  n_total <- nrow(
    parameter_table
  )
  
  
  n_U <- sum(
    parameter_table$Parameter_Type == "U"
  )
  
  
  n_Q <- sum(
    parameter_table$Parameter_Type == "Q"
  )
  
  
  n_x0 <- sum(
    parameter_table$Parameter_Type == "x0"
  )
  
  
  n_C <- sum(
    parameter_table$Parameter_Type == "C"
  )
  
  
  n_other <- sum(
    parameter_table$Parameter_Type == "OTHER"
  )
  
  
  expected_C <- registered_spec$expected_free_C
  
  
  fitted_K <- suppressWarnings(
    as.integer(
      fit_result$fit_summary$K[[1]]
    )
  )
  
  
  parameter_qa <- tibble(
    
    Model_ID =
      model_id,
    
    Total_Extracted =
      n_total,
    
    Expected_K =
      fitted_K,
    
    U_Parameters =
      n_U,
    
    Q_Parameters =
      n_Q,
    
    x0_Parameters =
      n_x0,
    
    C_Parameters =
      n_C,
    
    Expected_C =
      expected_C,
    
    Other_Parameters =
      n_other,
    
    Total_K_Match =
      n_total == fitted_K,
    
    C_Count_Match =
      n_C == expected_C
  )
  
  
  # ===========================================================================
  # REPORT
  # ===========================================================================
  
  cat("\n")
  cat("------------------------------------------------------------\n")
  cat("PARAMETER EXTRACTION QA\n")
  cat("------------------------------------------------------------\n")
  
  cat(
    "Total extracted:",
    n_total,
    "\n"
  )
  
  cat(
    "Expected K:",
    fitted_K,
    "\n"
  )
  
  cat(
    "U parameters:",
    n_U,
    "\n"
  )
  
  cat(
    "Q parameters:",
    n_Q,
    "\n"
  )
  
  cat(
    "x0 parameters:",
    n_x0,
    "\n"
  )
  
  cat(
    "C parameters:",
    n_C,
    "(expected",
    expected_C,
    ")\n"
  )
  
  cat(
    "Other parameters:",
    n_other,
    "\n"
  )
  
  
  # ===========================================================================
  # HARD QA
  # ===========================================================================
  
  if (
    n_total != fitted_K
  ) {
    
    stop(
      paste(
        "PARAMETER EXTRACTION ERROR:",
        model_id,
        "has K =",
        fitted_K,
        "but",
        n_total,
        "parameters were extracted."
      )
    )
  }
  
  
  if (
    n_C != expected_C
  ) {
    
    stop(
      paste(
        "SITE-SPECIFIC C EXTRACTION ERROR:",
        model_id,
        "expected",
        expected_C,
        "C parameters but extracted",
        n_C
      )
    )
  }
  
  
  if (
    n_U != nrow(
      fit_result$registered_spec$model_spec$Z
    ) &&
    !is.character(
      fit_result$registered_spec$model_spec$Z
    )
  ) {
    
    warning(
      "U parameter count should be inspected manually."
    )
  }
  
  
  cat(
    "Parameter extraction PASS.\n"
  )
  
  
  # ===========================================================================
  # CLIMATE C TABLE
  # ===========================================================================
  
  climate_table <- parameter_table %>%
    
    filter(
      Parameter_Type == "C"
    ) %>%
    
    arrange(
      Covariate,
      Site_ID
    )
  
  
  # ===========================================================================
  # SAVE MODEL-SPECIFIC OUTPUTS
  # ===========================================================================
  
  parameter_path <- file.path(
    fit_result$model_dir,
    "parameters.csv"
  )
  
  
  climate_path <- file.path(
    fit_result$model_dir,
    "parameters_C_climate.csv"
  )
  
  
  qa_path <- file.path(
    fit_result$model_dir,
    "parameter_QA.csv"
  )
  
  
  write_csv(
    parameter_table,
    parameter_path
  )
  
  
  write_csv(
    climate_table,
    climate_path
  )
  
  
  write_csv(
    parameter_qa,
    qa_path
  )
  
  
  cat("\n")
  cat(
    "Saved parameter table:",
    parameter_path,
    "\n"
  )
  
  cat(
    "Saved climate table:",
    climate_path,
    "\n"
  )
  
  cat(
    "Saved parameter QA:",
    qa_path,
    "\n"
  )
  
  
  # ===========================================================================
  # RETURN
  # ===========================================================================
  
  list(
    
    model_id =
      model_id,
    
    parameter_table =
      parameter_table,
    
    climate_table =
      climate_table,
    
    parameter_qa =
      parameter_qa,
    
    parameter_path =
      parameter_path,
    
    climate_path =
      climate_path,
    
    qa_path =
      qa_path
  )
}


cat("\n============================================================\n")
cat("07_extract_results.R LOADED SUCCESSFULLY\n")
cat("============================================================\n")