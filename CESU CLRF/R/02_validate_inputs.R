# ==============================================================================
# 02_validate_inputs.R
# CRLF MARSS PLUG-AND-PLAY PIPELINE
#
# PURPOSE:
#   Validate biological data, site registry, model registry,
#   and watershed climate records before feature engineering.
#
# FAILURE PHILOSOPHY:
#   Bad inputs stop the pipeline BEFORE MARSS is fitted.
# ==============================================================================

library(dplyr)
library(tidyr)
library(stringr)
library(tibble)


# ==============================================================================
# COLUMN DETECTOR
# ==============================================================================

find_input_column <- function(
    column_names,
    patterns
) {
  
  lower_names <- tolower(
    column_names
  )
  
  matches <- which(
    
    vapply(
      lower_names,
      
      function(x) {
        
        any(
          vapply(
            patterns,
            function(pattern) {
              grepl(
                pattern,
                x,
                ignore.case = TRUE
              )
            },
            logical(1)
          )
        )
      },
      
      logical(1)
    )
  )
  
  
  if (length(matches) == 0) {
    
    return(
      NA_character_
    )
  }
  
  
  column_names[
    matches[1]
  ]
}


# ==============================================================================
# VALIDATE SITE REGISTRY
# ==============================================================================

validate_site_registry <- function(
    site_registry
) {
  
  required_columns <- c(
    "Site_ID",
    "Prefix",
    "Watershed",
    "Active"
  )
  
  
  missing_columns <- setdiff(
    required_columns,
    names(site_registry)
  )
  
  
  if (length(missing_columns) > 0) {
    
    stop(
      paste(
        "Site registry missing columns:",
        paste(
          missing_columns,
          collapse = ", "
        )
      )
    )
  }
  
  
  duplicate_sites <- site_registry %>%
    count(
      Site_ID
    ) %>%
    filter(
      n != 1
    )
  
  
  if (nrow(duplicate_sites) > 0) {
    
    print(
      duplicate_sites,
      n = Inf
    )
    
    stop(
      "Site registry contains duplicate Site_ID records."
    )
  }
  
  
  active_sites <- site_registry %>%
    filter(
      Active
    )
  
  
  if (nrow(active_sites) == 0) {
    
    stop(
      "Site registry contains no active monitoring sites."
    )
  }
  
  
  cat(
    "Site registry PASS:",
    nrow(active_sites),
    "active sites.\n"
  )
  
  
  invisible(
    TRUE
  )
}


# ==============================================================================
# VALIDATE BIOLOGICAL MATRIX
# ==============================================================================

validate_biological_matrix <- function(
    dat_matrix,
    site_registry
) {
  
  if (is.null(
    rownames(
      dat_matrix
    )
  )) {
    
    stop(
      "Biological matrix has no site row names."
    )
  }
  
  
  if (is.null(
    colnames(
      dat_matrix
    )
  )) {
    
    stop(
      "Biological matrix has no year column names."
    )
  }
  
  
  if (anyDuplicated(
    rownames(
      dat_matrix
    )
  )) {
    
    stop(
      "Biological matrix contains duplicate site row names."
    )
  }
  
  
  if (anyDuplicated(
    colnames(
      dat_matrix
    )
  )) {
    
    stop(
      "Biological matrix contains duplicate year columns."
    )
  }
  
  
  years_vec <- suppressWarnings(
    as.numeric(
      colnames(
        dat_matrix
      )
    )
  )
  
  
  if (anyNA(
    years_vec
  )) {
    
    stop(
      "Biological matrix year names could not all be converted to numeric years."
    )
  }
  
  
  active_sites <- site_registry %>%
    filter(
      Active
    ) %>%
    pull(
      Site_ID
    )
  
  
  missing_from_matrix <- setdiff(
    active_sites,
    rownames(
      dat_matrix
    )
  )
  
  
  unexpected_in_matrix <- setdiff(
    rownames(
      dat_matrix
    ),
    active_sites
  )
  
  
  if (length(missing_from_matrix) > 0) {
    
    stop(
      paste(
        "Active sites missing from biological matrix:",
        paste(
          missing_from_matrix,
          collapse = ", "
        )
      )
    )
  }
  
  
  if (length(unexpected_in_matrix) > 0) {
    
    stop(
      paste(
        "Unexpected sites found in biological matrix:",
        paste(
          unexpected_in_matrix,
          collapse = ", "
        )
      )
    )
  }
  
  
  cat(
    "Biological matrix PASS:",
    nrow(dat_matrix),
    "sites;",
    ncol(dat_matrix),
    "years;",
    min(years_vec),
    "-",
    max(years_vec),
    "\n"
  )
  
  
  invisible(
    years_vec
  )
}


# ==============================================================================
# VALIDATE MODEL REGISTRY
# ==============================================================================

validate_model_registry <- function(
    model_registry
) {
  
  required_columns <- c(
    "Model_ID",
    "Enabled",
    "Model_Family",
    "Hypothesis",
    "Covariates",
    "C_Structure",
    "Bootstrap_N"
  )
  
  
  missing_columns <- setdiff(
    required_columns,
    names(model_registry)
  )
  
  
  if (length(missing_columns) > 0) {
    
    stop(
      paste(
        "Model registry missing columns:",
        paste(
          missing_columns,
          collapse = ", "
        )
      )
    )
  }
  
  
  duplicates <- model_registry %>%
    count(
      Model_ID
    ) %>%
    filter(
      n != 1
    )
  
  
  if (nrow(duplicates) > 0) {
    
    print(
      duplicates,
      n = Inf
    )
    
    stop(
      "Duplicate Model_ID values exist in model registry."
    )
  }
  
  
  enabled_models <- model_registry %>%
    filter(
      Enabled
    )
  
  
  cat(
    "Model registry PASS:",
    nrow(enabled_models),
    "enabled models.\n"
  )
  
  
  invisible(
    TRUE
  )
}


# ==============================================================================
# STANDARDIZE CLIMATE MASTER
# ==============================================================================

standardize_climate_master <- function(
    climate_raw,
    site_registry
) {
  
  # ---------------------------------------------------------------------------
  # Detect required fields
  # ---------------------------------------------------------------------------
  
  year_col <- find_input_column(
    names(climate_raw),
    c(
      "^year$",
      "water.?year",
      "^wy$"
    )
  )
  
  
  region_col <- find_input_column(
    names(climate_raw),
    c(
      "^region$",
      "watershed",
      "basin"
    )
  )
  
  
  octdec_col <- find_input_column(
    names(climate_raw),
    c(
      "pdsi.*oct.*dec",
      "oct.*dec.*pdsi",
      "^octdec$",
      "^pdsi_octdec$"
    )
  )
  
  
  janmar_col <- find_input_column(
    names(climate_raw),
    c(
      "pdsi.*jan.*mar",
      "jan.*mar.*pdsi",
      "^janmar$",
      "^pdsi_janmar$"
    )
  )
  
  
  detected <- c(
    year_col,
    region_col,
    octdec_col,
    janmar_col
  )
  
  
  if (anyNA(
    detected
  )) {
    
    cat(
      "\nClimate columns available:\n"
    )
    
    print(
      names(
        climate_raw
      )
    )
    
    stop(
      "Could not safely detect Year, Region, Oct-Dec PDSI, and Jan-Mar PDSI."
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Build prefix → canonical watershed map from site registry
  # ---------------------------------------------------------------------------
  
  region_lookup <- site_registry %>%
    distinct(
      Prefix,
      Watershed
    )
  
  
  # ---------------------------------------------------------------------------
  # Standardize raw climate table
  # ---------------------------------------------------------------------------
  
  climate_base <- climate_raw %>%
    transmute(
      
      Year = suppressWarnings(
        as.numeric(
          .data[[year_col]]
        )
      ),
      
      Region = str_to_upper(
        str_replace_all(
          str_squish(
            as.character(
              .data[[region_col]]
            )
          ),
          "[^A-Za-z0-9]+",
          "_"
        )
      ),
      
      PDSI_OctDec = suppressWarnings(
        as.numeric(
          .data[[octdec_col]]
        )
      ),
      
      PDSI_JanMar = suppressWarnings(
        as.numeric(
          .data[[janmar_col]]
        )
      )
    )
  
  
  # ---------------------------------------------------------------------------
  # Convert prefixes such as LS / RC to full canonical watershed names
  # ---------------------------------------------------------------------------
  
  for (
    i in seq_len(
      nrow(
        region_lookup
      )
    )
  ) {
    
    prefix <- region_lookup$Prefix[i]
    watershed <- region_lookup$Watershed[i]
    
    climate_base$Region[
      climate_base$Region == prefix
    ] <- watershed
  }
  
  
  # ---------------------------------------------------------------------------
  # Keep only modeled watersheds
  # ---------------------------------------------------------------------------
  
  required_watersheds <- unique(
    site_registry$Watershed[
      site_registry$Active
    ]
  )
  
  
  climate_base <- climate_base %>%
    filter(
      Region %in%
        required_watersheds
    )
  
  
  climate_base
}


# ==============================================================================
# VALIDATE CLIMATE MASTER
# ==============================================================================

validate_climate_master <- function(
    climate_base,
    site_registry
) {
  
  required_watersheds <- unique(
    site_registry$Watershed[
      site_registry$Active
    ]
  )
  
  
  missing_watersheds <- setdiff(
    required_watersheds,
    unique(
      climate_base$Region
    )
  )
  
  
  if (length(missing_watersheds) > 0) {
    
    stop(
      paste(
        "Climate master missing watersheds:",
        paste(
          missing_watersheds,
          collapse = ", "
        )
      )
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Duplicate watershed-year records
  # ---------------------------------------------------------------------------
  
  duplicate_years <- climate_base %>%
    count(
      Region,
      Year
    ) %>%
    filter(
      n != 1
    )
  
  
  if (nrow(duplicate_years) > 0) {
    
    print(
      duplicate_years,
      n = Inf
    )
    
    stop(
      "Climate master must contain exactly one row per watershed-year."
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Consecutive-year QA
  # ---------------------------------------------------------------------------
  
  year_gaps <- climate_base %>%
    arrange(
      Region,
      Year
    ) %>%
    group_by(
      Region
    ) %>%
    mutate(
      Year_Gap =
        Year -
        lag(
          Year
        )
    ) %>%
    filter(
      !is.na(
        Year_Gap
      ),
      Year_Gap != 1
    ) %>%
    ungroup()
  
  
  if (nrow(year_gaps) > 0) {
    
    print(
      year_gaps,
      n = Inf
    )
    
    stop(
      paste(
        "Climate histories contain non-consecutive years.",
        "Lagged features would be invalid."
      )
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Coverage table
  # ---------------------------------------------------------------------------
  
  climate_qa <- climate_base %>%
    group_by(
      Region
    ) %>%
    summarise(
      
      First_Year =
        min(
          Year,
          na.rm = TRUE
        ),
      
      Last_Year =
        max(
          Year,
          na.rm = TRUE
        ),
      
      N_Years =
        n_distinct(
          Year
        ),
      
      Missing_OctDec =
        sum(
          is.na(
            PDSI_OctDec
          )
        ),
      
      Missing_JanMar =
        sum(
          is.na(
            PDSI_JanMar
          )
        ),
      
      .groups = "drop"
    )
  
  
  cat("\n")
  cat("CLIMATE COVERAGE QA\n")
  cat("===================\n")
  
  print(
    climate_qa,
    n = Inf
  )
  
  
  if (
    any(
      climate_qa$Missing_OctDec > 0
    ) ||
    any(
      climate_qa$Missing_JanMar > 0
    )
  ) {
    
    stop(
      "Missing base PDSI values detected in climate history."
    )
  }
  
  
  cat(
    "Climate master PASS: complete consecutive watershed histories.\n"
  )
  
  
  invisible(
    climate_qa
  )
}


# ==============================================================================
# MASTER INPUT VALIDATOR
# ==============================================================================

validate_crlf_pipeline_inputs <- function(
    inputs
) {
  
  cat("\n")
  cat("============================================================\n")
  cat("VALIDATING CRLF MARSS PIPELINE INPUTS\n")
  cat("============================================================\n")
  
  
  validate_site_registry(
    inputs$site_registry
  )
  
  
  years_vec <- validate_biological_matrix(
    inputs$dat_matrix,
    inputs$site_registry
  )
  
  
  validate_model_registry(
    inputs$model_registry
  )
  
  
  climate_base <- standardize_climate_master(
    inputs$climate_raw,
    inputs$site_registry
  )
  
  
  climate_qa <- validate_climate_master(
    climate_base,
    inputs$site_registry
  )
  
  
  cat("\n")
  cat("ALL INPUT VALIDATION CHECKS PASSED.\n")
  
  
  list(
    
    inputs = inputs,
    
    years_vec = years_vec,
    
    climate_base = climate_base,
    
    climate_qa = climate_qa
  )
}