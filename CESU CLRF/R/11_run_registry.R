# ==============================================================================
# 11_run_registry.R
# CRLF MARSS PLUG-AND-PLAY PIPELINE
#
# PURPOSE:
#   Automatically execute models defined in config/model_registry.csv.
#
# WORKFLOW:
#
#   Registry row
#       ↓
#   Build MARSS specification
#       ↓
#   Reuse existing compatible fit OR fit model
#       ↓
#   Diagnostics
#       ↓
#   Reuse existing bootstrap OR bootstrap when requested
#       ↓
#   Extract parameters when bootstrap CIs exist
#       ↓
#   Make parameter figure
#       ↓
#   Continue to next registered model
#       ↓
#   Rebuild master model-selection table
#
# IMPORTANT:
#   Existing expensive results are reused by default.
# ==============================================================================

library(dplyr)
library(readr)
library(tibble)


# ==============================================================================
# 1. READ LOGICAL FLAG FROM REGISTRY ROW
# ==============================================================================

get_registry_flag <- function(
    model_row,
    field,
    default = FALSE
) {
  
  if (!field %in% names(model_row)) {
    return(default)
  }
  
  
  value <- model_row[[field]][[1]]
  
  
  if (is.logical(value)) {
    
    if (is.na(value)) {
      return(default)
    }
    
    return(value)
  }
  
  
  value_chr <- toupper(
    trimws(
      as.character(value)
    )
  )
  
  
  if (
    is.na(value_chr) ||
    value_chr == ""
  ) {
    return(default)
  }
  
  
  value_chr %in% c(
    "TRUE",
    "T",
    "1",
    "YES",
    "Y"
  )
}


# ==============================================================================
# 2. MODEL OUTPUT PATHS
# ==============================================================================

get_registered_model_paths <- function(
    project_root,
    model_id
) {
  
  model_dir <- file.path(
    project_root,
    "marss_results",
    "models",
    model_id
  )
  
  
  list(
    
    model_dir =
      model_dir,
    
    fit =
      file.path(
        model_dir,
        "fit.rds"
      ),
    
    fit_summary =
      file.path(
        model_dir,
        "fit_summary.csv"
      ),
    
    model_definition =
      file.path(
        model_dir,
        "model_definition.csv"
      ),
    
    bootstrap =
      file.path(
        model_dir,
        "fit_bootstrap_CIs.rds"
      ),
    
    bootstrap_summary =
      file.path(
        model_dir,
        "bootstrap_summary.csv"
      ),
    
    parameters =
      file.path(
        model_dir,
        "parameters.csv"
      )
  )
}


# ==============================================================================
# 3. NORMALIZE DEFINITION VALUES
# ==============================================================================

normalize_definition_value <- function(x) {
  
  x <- as.character(x)
  
  x[is.na(x)] <- ""
  
  trimws(x)
}


# ==============================================================================
# 4. CHECK WHETHER OLD FIT MATCHES CURRENT MODEL DEFINITION
#
# This prevents an old M4 fit from being reused if somebody later changes
# what M4 means inside model_registry.csv.
# ==============================================================================

existing_definition_matches <- function(
    registered_spec,
    definition_path
) {
  
  if (!file.exists(definition_path)) {
    return(FALSE)
  }
  
  
  existing <- read_csv(
    definition_path,
    show_col_types = FALSE
  )
  
  
  if (nrow(existing) != 1) {
    return(FALSE)
  }
  
  
  current <- build_model_definition_table(
    registered_spec
  )
  
  
  fields_to_compare <- c(
    
    "Model_ID",
    
    "Covariates",
    
    "C_Structure",
    
    "B_Structure",
    
    "U_Structure",
    
    "Q_Structure",
    
    "R_Structure",
    
    "Expected_Free_C"
  )
  
  
  fields_to_compare <- intersect(
    fields_to_compare,
    intersect(
      names(existing),
      names(current)
    )
  )
  
  
  if (length(fields_to_compare) == 0) {
    return(FALSE)
  }
  
  
  for (field in fields_to_compare) {
    
    old_value <- normalize_definition_value(
      existing[[field]][[1]]
    )
    
    
    new_value <- normalize_definition_value(
      current[[field]][[1]]
    )
    
    
    if (!identical(old_value, new_value)) {
      
      cat(
        "\nExisting model definition differs for:",
        field,
        "\n"
      )
      
      cat(
        "Existing:",
        old_value,
        "\n"
      )
      
      cat(
        "Current :",
        new_value,
        "\n"
      )
      
      
      return(FALSE)
    }
  }
  
  
  TRUE
}


# ==============================================================================
# 5. LOAD EXISTING COMPATIBLE FIT
# ==============================================================================

load_existing_registered_fit <- function(
    registered_spec,
    project_root
) {
  
  model_id <- registered_spec$model_id
  
  
  paths <- get_registered_model_paths(
    project_root = project_root,
    model_id = model_id
  )
  
  
  required_files <- c(
    
    paths$fit,
    
    paths$fit_summary,
    
    paths$model_definition
  )
  
  
  if (!all(file.exists(required_files))) {
    
    return(NULL)
  }
  
  
  compatible <- existing_definition_matches(
    
    registered_spec =
      registered_spec,
    
    definition_path =
      paths$model_definition
  )
  
  
  if (!compatible) {
    
    stop(
      paste0(
        "Existing fit for ",
        model_id,
        " does not match the current registered model definition. ",
        "The old fit will NOT be reused. ",
        "Use force_refit = TRUE only after confirming that a new fit is intended."
      )
    )
  }
  
  
  fit_object <- readRDS(
    paths$fit
  )
  
  
  fit_summary <- read_csv(
    paths$fit_summary,
    show_col_types = FALSE
  )
  
  
  model_definition <- read_csv(
    paths$model_definition,
    show_col_types = FALSE
  )
  
  
  if (nrow(fit_summary) != 1) {
    
    stop(
      paste(
        "Existing fit summary is invalid for:",
        model_id
      )
    )
  }
  
  
  cat("\n")
  cat("Existing compatible fit found.\n")
  cat("Reusing:\n")
  cat(paths$fit, "\n")
  
  
  list(
    
    model_id =
      model_id,
    
    registered_spec =
      registered_spec,
    
    fit =
      fit_object,
    
    fit_status =
      as.character(
        fit_summary$Fit_Status[[1]]
      ),
    
    final_method =
      as.character(
        fit_summary$Final_Method[[1]]
      ),
    
    fit_summary =
      fit_summary,
    
    model_definition =
      model_definition,
    
    model_dir =
      paths$model_dir,
    
    fit_path =
      paths$fit,
    
    run_id =
      as.character(
        fit_summary$Run_ID[[1]]
      ),
    
    resumed =
      TRUE
  )
}


# ==============================================================================
# 6. LOAD EXISTING COMPLETED BOOTSTRAP
# ==============================================================================

load_existing_registered_bootstrap <- function(
    fit_result
) {
  
  bootstrap_path <- file.path(
    fit_result$model_dir,
    "fit_bootstrap_CIs.rds"
  )
  
  
  summary_path <- file.path(
    fit_result$model_dir,
    "bootstrap_summary.csv"
  )
  
  
  if (
    !file.exists(bootstrap_path) ||
    !file.exists(summary_path)
  ) {
    
    return(NULL)
  }
  
  
  bootstrap_summary <- read_csv(
    summary_path,
    show_col_types = FALSE
  )
  
  
  if (nrow(bootstrap_summary) != 1) {
    return(NULL)
  }
  
  
  bootstrap_status <- as.character(
    bootstrap_summary$Bootstrap_Status[[1]]
  )
  
  
  if (!identical(
    bootstrap_status,
    "COMPLETE"
  )) {
    
    return(NULL)
  }
  
  
  # ---------------------------------------------------------------------------
  # Check that bootstrap belongs to the same fit run
  # ---------------------------------------------------------------------------
  
  if ("Run_ID" %in% names(bootstrap_summary)) {
    
    bootstrap_run_id <- as.character(
      bootstrap_summary$Run_ID[[1]]
    )
    
    
    fit_run_id <- as.character(
      fit_result$run_id
    )
    
    
    if (
      !is.na(bootstrap_run_id) &&
      !is.na(fit_run_id) &&
      bootstrap_run_id != fit_run_id
    ) {
      
      cat(
        "Existing bootstrap belongs to a different fit Run_ID.\n"
      )
      
      return(NULL)
    }
  }
  
  
  bootstrap_fit <- readRDS(
    bootstrap_path
  )
  
  
  cat("\n")
  cat("Existing completed bootstrap found.\n")
  cat("Reusing:\n")
  cat(bootstrap_path, "\n")
  
  
  list(
    
    model_id =
      fit_result$model_id,
    
    fit_result =
      fit_result,
    
    bootstrap_fit =
      bootstrap_fit,
    
    bootstrap_status =
      "COMPLETE",
    
    bootstrap_summary =
      bootstrap_summary,
    
    bootstrap_path =
      bootstrap_path,
    
    resumed =
      TRUE
  )
}


# ==============================================================================
# 7. RUN ONE REGISTERED MODEL
# ==============================================================================

run_one_registered_model <- function(
    model_row,
    inputs,
    validated,
    features,
    force_refit = FALSE,
    force_bootstrap = FALSE,
    run_diagnostics = TRUE,
    make_figures = TRUE
) {
  
  model_id <- as.character(
    model_row$Model_ID[[1]]
  )
  
  
  cat("\n")
  cat("################################################################\n")
  cat("REGISTERED MODEL EXECUTION\n")
  cat("################################################################\n")
  
  cat(
    "Model:",
    model_id,
    "\n"
  )
  
  
  # ===========================================================================
  # REGISTRY FLAGS
  # ===========================================================================
  
  enabled <- get_registry_flag(
    model_row,
    "Enabled",
    TRUE
  )
  
  
  fit_requested <- get_registry_flag(
    model_row,
    "Fit_Model",
    TRUE
  )
  
  
  bootstrap_requested <- get_registry_flag(
    model_row,
    "Run_Bootstrap",
    FALSE
  )
  
  
  if (force_bootstrap) {
    
    bootstrap_requested <- TRUE
  }
  
  
  cat(
    "Enabled:",
    enabled,
    "\n"
  )
  
  
  cat(
    "Fit requested:",
    fit_requested,
    "\n"
  )
  
  
  cat(
    "Bootstrap requested:",
    bootstrap_requested,
    "\n"
  )
  
  
  # ===========================================================================
  # SKIP MODEL
  # ===========================================================================
  
  if (
    !enabled ||
    !fit_requested
  ) {
    
    cat(
      "Model skipped by registry settings.\n"
    )
    
    
    return(
      
      list(
        
        model_id =
          model_id,
        
        status =
          "SKIPPED"
      )
    )
  }
  
  
  # ===========================================================================
  # BUILD MODEL SPECIFICATION
  # ===========================================================================
  
  registered_spec <- build_registered_model_spec(
    
    model_row =
      model_row,
    
    dat_matrix =
      inputs$dat_matrix,
    
    feature_object =
      features,
    
    site_registry =
      inputs$site_registry,
    
    biological_years =
      validated$years_vec
  )
  
  
  # ===========================================================================
  # FIT OR RESUME
  # ===========================================================================
  
  fit_result <- NULL
  
  
  if (!force_refit) {
    
    fit_result <- load_existing_registered_fit(
      
      registered_spec =
        registered_spec,
      
      project_root =
        inputs$project_root
    )
  }
  
  
  if (is.null(fit_result)) {
    
    cat("\n")
    cat("No reusable fit found.\n")
    cat("Fitting model now...\n")
    
    
    fit_result <- fit_registered_model(
      
      registered_spec =
        registered_spec,
      
      dat_matrix =
        inputs$dat_matrix,
      
      settings =
        inputs$settings,
      
      project_root =
        inputs$project_root
    )
  }
  
  
  # ===========================================================================
  # DIAGNOSTICS
  # ===========================================================================
  
  diagnostic_result <- NULL
  
  
  if (
    run_diagnostics &&
    !is.null(
      fit_result$fit
    )
  ) {
    
    diagnostic_result <- diagnose_registered_model(
      
      fit_result =
        fit_result,
      
      dat_matrix =
        inputs$dat_matrix
    )
  }
  
  
  # ===========================================================================
  # BOOTSTRAP
  #
  # First check whether one already exists.
  #
  # A completed bootstrap can be reused even when Run_Bootstrap = FALSE.
  # A NEW bootstrap is launched only when requested.
  # ===========================================================================
  
  bootstrap_result <- load_existing_registered_bootstrap(
    fit_result
  )
  
  
  if (
    is.null(bootstrap_result) &&
    bootstrap_requested
  ) {
    
    bootstrap_result <- bootstrap_registered_model(
      
      fit_result =
        fit_result,
      
      settings =
        inputs$settings
    )
  }
  
  
  if (
    is.null(bootstrap_result) &&
    !bootstrap_requested
  ) {
    
    cat("\n")
    cat(
      "No completed bootstrap exists and Run_Bootstrap = FALSE.\n"
    )
    
    cat(
      "Skipping bootstrap CI parameter extraction and parameter figure.\n"
    )
  }
  
  
  # ===========================================================================
  # PARAMETER EXTRACTION
  # ===========================================================================
  
  parameter_result <- NULL
  
  
  if (
    !is.null(bootstrap_result) &&
    identical(
      bootstrap_result$bootstrap_status,
      "COMPLETE"
    )
  ) {
    
    parameter_result <- extract_registered_model_parameters(
      
      bootstrap_result =
        bootstrap_result,
      
      site_registry =
        inputs$site_registry
    )
  }
  
  
  # ===========================================================================
  # PARAMETER FIGURE
  # ===========================================================================
  
  figure_result <- NULL
  
  
  if (
    make_figures &&
    !is.null(parameter_result)
  ) {
    
    figure_result <- plot_registered_model_parameters(
      
      parameter_result =
        parameter_result,
      
      fit_result =
        fit_result,
      
      site_registry =
        inputs$site_registry
    )
  }
  
  
  # ===========================================================================
  # RETURN
  # ===========================================================================
  
  list(
    
    model_id =
      model_id,
    
    status =
      fit_result$fit_status,
    
    registered_spec =
      registered_spec,
    
    fit_result =
      fit_result,
    
    diagnostic_result =
      diagnostic_result,
    
    bootstrap_result =
      bootstrap_result,
    
    parameter_result =
      parameter_result,
    
    figure_result =
      figure_result
  )
}


# ==============================================================================
# 8. RUN REGISTERED MODEL SUITE
# ==============================================================================

run_registered_model_suite <- function(
    inputs,
    validated,
    features,
    model_ids = NULL,
    force_refit = FALSE,
    force_bootstrap = FALSE,
    run_diagnostics = TRUE,
    make_figures = TRUE
) {
  
  cat("\n")
  cat("================================================================\n")
  cat("CRLF MARSS REGISTERED MODEL SUITE\n")
  cat("================================================================\n")
  
  
  registry <- normalize_model_registry(
    inputs$model_registry
  )
  
  
  # ===========================================================================
  # ENABLED MODELS
  # ===========================================================================
  
  registry_run <- registry %>%
    
    filter(
      Enabled,
      Fit_Model
    )
  
  
  # ===========================================================================
  # OPTIONAL MODEL SUBSET
  # ===========================================================================
  
  if (!is.null(model_ids)) {
    
    missing_requested <- setdiff(
      model_ids,
      registry_run$Model_ID
    )
    
    
    if (length(missing_requested) > 0) {
      
      stop(
        paste(
          "Requested Model_ID values are not currently enabled/fittable:",
          paste(
            missing_requested,
            collapse = ", "
          )
        )
      )
    }
    
    
    registry_run <- registry_run %>%
      
      filter(
        Model_ID %in%
          model_ids
      )
  }
  
  
  # ===========================================================================
  # RUN ORDER
  # ===========================================================================
  
  if (
    "Sort_Order" %in%
    names(registry_run)
  ) {
    
    registry_run <- registry_run %>%
      
      arrange(
        Sort_Order
      )
  }
  
  
  cat(
    "Models scheduled:",
    nrow(registry_run),
    "\n"
  )
  
  
  cat("\n")
  
  print(
    registry_run %>%
      select(
        Model_ID,
        Model_Family,
        Covariates
      ),
    n = Inf,
    width = 140
  )
  
  
  # ===========================================================================
  # EXECUTION LOOP
  # ===========================================================================
  
  results <- list()
  
  run_log <- list()
  
  
  for (
    i in seq_len(
      nrow(
        registry_run
      )
    )
  ) {
    
    model_row <- registry_run[
      i,
      ,
      drop = FALSE
    ]
    
    
    model_id <- as.character(
      model_row$Model_ID[[1]]
    )
    
    
    start_time <- Sys.time()
    
    
    result <- tryCatch(
      
      run_one_registered_model(
        
        model_row =
          model_row,
        
        inputs =
          inputs,
        
        validated =
          validated,
        
        features =
          features,
        
        force_refit =
          force_refit,
        
        force_bootstrap =
          force_bootstrap,
        
        run_diagnostics =
          run_diagnostics,
        
        make_figures =
          make_figures
      ),
      
      error = function(e) {
        
        list(
          
          model_id =
            model_id,
          
          status =
            "PIPELINE_ERROR",
          
          error =
            conditionMessage(
              e
            )
        )
      }
    )
    
    
    end_time <- Sys.time()
    
    
    results[[model_id]] <- result
    
    
    error_message <- NA_character_
    
    
    if (
      !is.null(
        result$error
      )
    ) {
      
      error_message <- as.character(
        result$error
      )
    }
    
    
    run_log[[length(run_log) + 1]] <- tibble(
      
      Model_ID =
        model_id,
      
      Pipeline_Status =
        result$status,
      
      Error_Message =
        error_message,
      
      Start_Time =
        as.character(
          start_time
        ),
      
      End_Time =
        as.character(
          end_time
        ),
      
      Elapsed_Minutes =
        as.numeric(
          difftime(
            end_time,
            start_time,
            units = "mins"
          )
        )
    )
    
    
    cat("\n")
    cat(
      "Completed registry step:",
      model_id,
      "| Status:",
      result$status,
      "\n"
    )
  }
  
  
  # ===========================================================================
  # COMBINE RUN LOG
  # ===========================================================================
  
  run_log <- bind_rows(
    run_log
  )
  
  
  # ===========================================================================
  # SAVE RUN LOG
  # ===========================================================================
  
  log_dir <- file.path(
    inputs$project_root,
    "marss_results",
    "logs"
  )
  
  
  dir.create(
    log_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  
  log_path <- file.path(
    
    log_dir,
    
    paste0(
      "registry_run_",
      format(
        Sys.time(),
        "%Y%m%d_%H%M%S"
      ),
      ".csv"
    )
  )
  
  
  write_csv(
    run_log,
    log_path
  )
  
  
  # ===========================================================================
  # UPDATE MASTER MODEL SELECTION
  # ===========================================================================
  
  selection_result <- build_master_model_selection(
    
    project_root =
      inputs$project_root,
    
    model_registry =
      inputs$model_registry
  )
  
  
  # ===========================================================================
  # MODEL-SELECTION FIGURES
  # ===========================================================================
  
  selection_figures <- NULL
  
  
  if (make_figures) {
    
    selection_figures <- plot_candidate_set_aicc(
      
      selection_result =
        selection_result,
      
      project_root =
        inputs$project_root
    )
  }
  
  
  # ===========================================================================
  # FINAL REPORT
  # ===========================================================================
  
  cat("\n")
  cat("================================================================\n")
  cat("REGISTERED MODEL SUITE COMPLETE\n")
  cat("================================================================\n")
  
  
  print(
    run_log,
    n = Inf,
    width = 140
  )
  
  
  cat("\nRun log:\n")
  
  cat(
    log_path,
    "\n"
  )
  
  
  # ===========================================================================
  # RETURN
  # ===========================================================================
  
  list(
    
    model_results =
      results,
    
    run_log =
      run_log,
    
    selection =
      selection_result,
    
    selection_figures =
      selection_figures,
    
    log_path =
      log_path
  )
}


# ==============================================================================
# MODULE LOAD MESSAGE
# ==============================================================================

cat("\n============================================================\n")
cat("11_run_registry.R LOADED SUCCESSFULLY\n")
cat("============================================================\n")