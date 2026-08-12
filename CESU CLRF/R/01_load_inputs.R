# ==============================================================================
# 01_load_inputs.R
# CRLF MARSS PLUG-AND-PLAY PIPELINE
#
# PURPOSE:
#   Read pipeline configuration, site registry, model registry,
#   biological MARSS matrix, and raw climate data.
#
# IMPORTANT:
#   This module does NOT modify data.
#   This module does NOT fit MARSS models.
# ==============================================================================

library(readr)
library(dplyr)
library(tibble)


# ==============================================================================
# GET PROJECT ROOT
# ==============================================================================

get_project_root <- function(project_root = getwd()) {
  
  normalizePath(
    project_root,
    winslash = "/",
    mustWork = TRUE
  )
}


# ==============================================================================
# READ PIPELINE SETTINGS
# ==============================================================================

load_pipeline_settings <- function(project_root) {
  
  settings_path <- file.path(
    project_root,
    "config",
    "pipeline_settings.csv"
  )
  
  if (!file.exists(settings_path)) {
    
    stop(
      paste(
        "Pipeline settings file not found:",
        settings_path
      )
    )
  }
  
  settings <- read_csv(
    settings_path,
    show_col_types = FALSE
  )
  
  required_columns <- c(
    "Setting",
    "Value",
    "Description"
  )
  
  missing_columns <- setdiff(
    required_columns,
    names(settings)
  )
  
  if (length(missing_columns) > 0) {
    
    stop(
      paste(
        "pipeline_settings.csv is missing columns:",
        paste(
          missing_columns,
          collapse = ", "
        )
      )
    )
  }
  
  settings
}


# ==============================================================================
# GET ONE SETTING
# ==============================================================================

get_setting <- function(
    settings,
    setting_name,
    type = c(
      "character",
      "numeric",
      "integer",
      "logical"
    )
) {
  
  type <- match.arg(type)
  
  hit <- settings %>%
    filter(
      Setting == setting_name
    )
  
  if (nrow(hit) != 1) {
    
    stop(
      paste(
        "Expected exactly one pipeline setting named:",
        setting_name
      )
    )
  }
  
  value <- hit$Value[[1]]
  
  if (type == "numeric") {
    
    value <- as.numeric(value)
    
  } else if (type == "integer") {
    
    value <- as.integer(value)
    
  } else if (type == "logical") {
    
    value <- toupper(value) %in% c(
      "TRUE",
      "T",
      "1",
      "YES"
    )
  }
  
  value
}


# ==============================================================================
# LOAD SITE REGISTRY
# ==============================================================================

load_site_registry <- function(project_root) {
  
  site_path <- file.path(
    project_root,
    "config",
    "site_registry.csv"
  )
  
  if (!file.exists(site_path)) {
    
    stop(
      paste(
        "Site registry not found:",
        site_path
      )
    )
  }
  
  read_csv(
    site_path,
    show_col_types = FALSE
  )
}


# ==============================================================================
# LOAD MODEL REGISTRY
# ==============================================================================

load_model_registry <- function(project_root) {
  
  registry_path <- file.path(
    project_root,
    "config",
    "model_registry.csv"
  )
  
  if (!file.exists(registry_path)) {
    
    stop(
      paste(
        "Model registry not found:",
        registry_path
      )
    )
  }
  
  read_csv(
    registry_path,
    show_col_types = FALSE
  )
}


# ==============================================================================
# LOAD BIOLOGICAL MATRIX
# ==============================================================================

load_biological_matrix <- function(
    project_root,
    settings
) {
  
  relative_path <- get_setting(
    settings,
    "BIOLOGICAL_MATRIX"
  )
  
  bio_path <- file.path(
    project_root,
    relative_path
  )
  
  if (!file.exists(bio_path)) {
    
    stop(
      paste(
        "Biological matrix not found:",
        bio_path
      )
    )
  }
  
  dat_matrix <- readRDS(
    bio_path
  )
  
  dat_matrix <- as.matrix(
    dat_matrix
  )
  
  mode(dat_matrix) <- "numeric"
  
  dat_matrix
}


# ==============================================================================
# LOAD RAW CLIMATE MASTER
# ==============================================================================

load_climate_master <- function(
    project_root,
    settings
) {
  
  relative_path <- get_setting(
    settings,
    "CLIMATE_MASTER"
  )
  
  climate_path <- file.path(
    project_root,
    relative_path
  )
  
  
  # ---------------------------------------------------------------------------
  # Historical fallback retained from locked baseline
  # ---------------------------------------------------------------------------
  
  if (!file.exists(climate_path)) {
    
    fallback <- file.path(
      project_root,
      "watershed_pdsi_master_long.csv"
    )
    
    if (file.exists(fallback)) {
      
      climate_path <- fallback
    }
  }
  
  
  if (!file.exists(climate_path)) {
    
    stop(
      paste(
        "Climate master not found:",
        climate_path
      )
    )
  }
  
  
  read_csv(
    climate_path,
    show_col_types = FALSE
  )
}


# ==============================================================================
# MASTER INPUT LOADER
# ==============================================================================

load_crlf_pipeline_inputs <- function(
    project_root = getwd()
) {
  
  project_root <- get_project_root(
    project_root
  )
  
  
  cat("\n")
  cat("============================================================\n")
  cat("LOADING CRLF MARSS PIPELINE INPUTS\n")
  cat("============================================================\n")
  
  
  # ---------------------------------------------------------------------------
  # Configuration
  # ---------------------------------------------------------------------------
  
  settings <- load_pipeline_settings(
    project_root
  )
  
  site_registry <- load_site_registry(
    project_root
  )
  
  model_registry <- load_model_registry(
    project_root
  )
  
  
  # ---------------------------------------------------------------------------
  # Data
  # ---------------------------------------------------------------------------
  
  dat_matrix <- load_biological_matrix(
    project_root,
    settings
  )
  
  climate_raw <- load_climate_master(
    project_root,
    settings
  )
  
  
  # ---------------------------------------------------------------------------
  # Biological years
  # ---------------------------------------------------------------------------
  
  years_vec <- suppressWarnings(
    as.numeric(
      colnames(
        dat_matrix
      )
    )
  )
  
  
  # ---------------------------------------------------------------------------
  # Report
  # ---------------------------------------------------------------------------
  
  cat(
    "Project root:",
    project_root,
    "\n"
  )
  
  cat(
    "Biological matrix:",
    nrow(dat_matrix),
    "sites x",
    ncol(dat_matrix),
    "years\n"
  )
  
  cat(
    "Climate master:",
    nrow(climate_raw),
    "rows\n"
  )
  
  cat(
    "Site registry:",
    nrow(site_registry),
    "sites\n"
  )
  
  cat(
    "Model registry:",
    nrow(model_registry),
    "registered models\n"
  )
  
  
  # ---------------------------------------------------------------------------
  # Return everything as one pipeline object
  # ---------------------------------------------------------------------------
  
  list(
    
    project_root = project_root,
    
    settings = settings,
    
    site_registry = site_registry,
    
    model_registry = model_registry,
    
    dat_matrix = dat_matrix,
    
    years_vec = years_vec,
    
    climate_raw = climate_raw
  )
}