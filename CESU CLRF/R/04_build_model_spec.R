# ==============================================================================
# 04_build_model_spec.R
# CRLF MARSS PLUG-AND-PLAY PIPELINE
#
# PURPOSE:
#   Convert one row of config/model_registry.csv into a validated
#   MARSS model specification.
#
# THIS MODULE DOES NOT FIT A MODEL.
# ==============================================================================

library(dplyr)
library(tidyr)
library(stringr)
library(tibble)


# ==============================================================================
# 1. PARSE MODEL COVARIATES
# ==============================================================================

parse_model_covariates <- function(x) {
  
  if (
    length(x) == 0 ||
    is.na(x) ||
    trimws(x) == ""
  ) {
    return(character(0))
  }
  
  covariates <- strsplit(
    as.character(x),
    "\\|"
  )[[1]]
  
  covariates <- trimws(covariates)
  covariates <- covariates[covariates != ""]
  
  unique(covariates)
}


# ==============================================================================
# 2. VALIDATE MODEL-REGISTRY ROW
# ==============================================================================

validate_model_row <- function(model_row) {
  
  if (nrow(model_row) != 1) {
    stop(
      "build_registered_model_spec() requires exactly one model-registry row."
    )
  }
  
  required_fields <- c(
    "Model_ID",
    "Model_Family",
    "Hypothesis",
    "Covariates",
    "C_Structure",
    "B_Structure",
    "U_Structure",
    "Q_Structure",
    "R_Structure"
  )
  
  missing_fields <- setdiff(
    required_fields,
    names(model_row)
  )
  
  if (length(missing_fields) > 0) {
    stop(
      paste(
        "Model registry row is missing required fields:",
        paste(missing_fields, collapse = ", ")
      )
    )
  }
  
  if (
    is.na(model_row$Model_ID[[1]]) ||
    trimws(model_row$Model_ID[[1]]) == ""
  ) {
    stop("Model_ID cannot be blank.")
  }
  
  invisible(TRUE)
}


# ==============================================================================
# 3. VALIDATE REQUESTED FEATURES
# ==============================================================================

validate_requested_features <- function(
    requested_covariates,
    feature_object,
    model_id
) {
  
  # Null model
  if (length(requested_covariates) == 0) {
    return(invisible(TRUE))
  }
  
  available_features <- feature_object$feature_catalog$Feature
  
  missing_features <- setdiff(
    requested_covariates,
    available_features
  )
  
  if (length(missing_features) > 0) {
    
    stop(
      paste0(
        "MODEL ",
        model_id,
        " REQUESTS UNKNOWN FEATURES: ",
        paste(missing_features, collapse = ", "),
        "\nAvailable features are: ",
        paste(available_features, collapse = ", ")
      )
    )
  }
  
  invisible(TRUE)
}


# ==============================================================================
# 4. BUILD MARSS COVARIATE MATRIX
#
# rows = watershed x requested feature
# cols = biological years
# ==============================================================================

build_marss_covariate_matrix <- function(
    feature_data,
    requested_covariates,
    biological_years
) {
  
  if (length(requested_covariates) == 0) {
    return(NULL)
  }
  
  
  # ---------------------------------------------------------------------------
  # Check biological years
  # ---------------------------------------------------------------------------
  
  missing_years <- setdiff(
    biological_years,
    unique(feature_data$Year)
  )
  
  if (length(missing_years) > 0) {
    stop(
      paste(
        "Feature table is missing biological years:",
        paste(missing_years, collapse = ", ")
      )
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Long form
  # ---------------------------------------------------------------------------
  
  cov_long <- feature_data %>%
    select(
      Year,
      Region,
      all_of(requested_covariates)
    ) %>%
    pivot_longer(
      cols = all_of(requested_covariates),
      names_to = "Feature",
      values_to = "Value"
    ) %>%
    mutate(
      Cov_Name = paste0(
        Region,
        "_",
        Feature
      )
    )
  
  
  # ---------------------------------------------------------------------------
  # One value per covariate-year
  # ---------------------------------------------------------------------------
  
  duplicates <- cov_long %>%
    count(
      Cov_Name,
      Year
    ) %>%
    filter(n != 1)
  
  if (nrow(duplicates) > 0) {
    
    print(
      duplicates,
      n = Inf
    )
    
    stop(
      "Covariate construction found duplicate covariate-year records."
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Wide form
  # ---------------------------------------------------------------------------
  
  cov_wide <- cov_long %>%
    select(
      Cov_Name,
      Year,
      Value
    ) %>%
    pivot_wider(
      names_from = Year,
      values_from = Value
    )
  
  
  cov_matrix <- as.matrix(
    cov_wide[, -1, drop = FALSE]
  )
  
  rownames(cov_matrix) <- cov_wide$Cov_Name
  
  mode(cov_matrix) <- "numeric"
  
  
  # ---------------------------------------------------------------------------
  # Exact biological year order
  # ---------------------------------------------------------------------------
  
  target_year_names <- as.character(
    biological_years
  )
  
  missing_matrix_years <- setdiff(
    target_year_names,
    colnames(cov_matrix)
  )
  
  if (length(missing_matrix_years) > 0) {
    stop(
      paste(
        "MARSS covariate matrix is missing years:",
        paste(missing_matrix_years, collapse = ", ")
      )
    )
  }
  
  cov_matrix <- cov_matrix[
    ,
    target_year_names,
    drop = FALSE
  ]
  
  
  # ---------------------------------------------------------------------------
  # NA gate
  # ---------------------------------------------------------------------------
  
  if (anyNA(cov_matrix)) {
    
    bad_locations <- which(
      is.na(cov_matrix),
      arr.ind = TRUE
    )
    
    print(bad_locations)
    
    stop(
      "MARSS covariate matrix contains NA values."
    )
  }
  
  
  cov_matrix
}


# ==============================================================================
# 5. BUILD SITE -> WATERSHED LOOKUP
# ==============================================================================

build_site_watershed_lookup <- function(site_registry) {
  
  lookup <- site_registry %>%
    filter(Active) %>%
    select(
      Site_ID,
      Watershed
    )
  
  if (anyDuplicated(lookup$Site_ID)) {
    stop(
      "Site registry produced duplicate Site_ID values."
    )
  }
  
  lookup
}


# ==============================================================================
# 6. BUILD SITE-SPECIFIC C MATRIX
#
# Climate input:
#   watershed-level
#
# Climate response:
#   independently estimated for every pond
#
# Example:
#
#   LS01 -> C_LS01_PDSI_JanMar
#   LS04 -> C_LS04_PDSI_JanMar
#
# Both ponds use Laguna Salada PDSI but receive separate C coefficients.
# ==============================================================================

build_site_specific_C_matrix <- function(
    site_names,
    covariate_names,
    site_registry
) {
  
  n_sites <- length(site_names)
  n_covariates <- length(covariate_names)
  
  
  # Numeric 0 = fixed zero
  # Character string = free MARSS parameter
  C_matrix <- matrix(
    list(0),
    nrow = n_sites,
    ncol = n_covariates,
    dimnames = list(
      site_names,
      covariate_names
    )
  )
  
  
  site_lookup <- build_site_watershed_lookup(
    site_registry
  )
  
  
  for (site_index in seq_along(site_names)) {
    
    site_id <- site_names[site_index]
    
    
    site_match <- site_lookup %>%
      filter(
        Site_ID == site_id
      )
    
    
    if (nrow(site_match) != 1) {
      stop(
        paste(
          "Could not resolve exactly one watershed for site:",
          site_id
        )
      )
    }
    
    
    # FIXED [[1]] SYNTAX
    watershed <- site_match$Watershed[[1]]
    
    
    matching_covariates <- grep(
      paste0(
        "^",
        watershed,
        "_"
      ),
      covariate_names
    )
    
    
    if (length(matching_covariates) == 0) {
      stop(
        paste(
          "No covariate rows found for site",
          site_id,
          "in watershed",
          watershed
        )
      )
    }
    
    
    for (cov_index in matching_covariates) {
      
      full_covariate_name <- covariate_names[cov_index]
      
      
      feature_name <- sub(
        paste0(
          "^",
          watershed,
          "_"
        ),
        "",
        full_covariate_name
      )
      
      
      # IMPORTANT:
      # Site ID makes each climate response unique.
      parameter_name <- paste0(
        "C_",
        site_id,
        "_",
        feature_name
      )
      
      
      C_matrix[
        site_index,
        cov_index
      ] <- parameter_name
    }
  }
  
  
  C_matrix
}


# ==============================================================================
# 7. AUDIT SITE-SPECIFIC C MATRIX
# ==============================================================================

audit_site_specific_C_matrix <- function(
    C_matrix,
    requested_covariates,
    site_names,
    model_id
) {
  
  # Preserve list element types
  cells <- as.vector(C_matrix)
  
  
  is_estimated <- vapply(
    cells,
    function(x) {
      is.character(x) &&
        length(x) == 1 &&
        !is.na(x)
    },
    logical(1)
  )
  
  
  estimated_names <- vapply(
    cells[is_estimated],
    as.character,
    character(1)
  )
  
  
  unique_parameters <- unique(
    estimated_names
  )
  
  
  n_active_cells <- length(
    estimated_names
  )
  
  n_free_C <- length(
    unique_parameters
  )
  
  
  expected_C <- length(site_names) *
    length(requested_covariates)
  
  
  cat("\n")
  cat("------------------------------------------------------------\n")
  cat(model_id, " C-MATRIX AUDIT\n")
  cat("------------------------------------------------------------\n")
  
  cat(
    "Sites:",
    length(site_names),
    "\n"
  )
  
  cat(
    "Requested covariates:",
    length(requested_covariates),
    "\n"
  )
  
  cat(
    "Expected site-specific C parameters:",
    expected_C,
    "\n"
  )
  
  cat(
    "Active site-climate cells:",
    n_active_cells,
    "\n"
  )
  
  cat(
    "Unique estimated C parameters:",
    n_free_C,
    "\n"
  )
  
  
  if (n_active_cells != expected_C) {
    stop(
      paste(
        "C-MATRIX ERROR:",
        model_id,
        "expected",
        expected_C,
        "active site-climate cells but found",
        n_active_cells
      )
    )
  }
  
  
  if (n_free_C != expected_C) {
    stop(
      paste(
        "C-MATRIX ERROR:",
        model_id,
        "expected",
        expected_C,
        "unique site-specific C parameters but found",
        n_free_C,
        ". Climate responses may have been unintentionally shared."
      )
    )
  }
  
  
  if (anyDuplicated(estimated_names)) {
    stop(
      paste(
        "C-MATRIX ERROR:",
        model_id,
        "contains duplicated climate-response parameter names."
      )
    )
  }
  
  
  cat(
    "C-matrix structure PASS.\n"
  )
  
  
  invisible(
    list(
      expected_C = expected_C,
      active_cells = n_active_cells,
      n_free_C = n_free_C,
      parameter_names = unique_parameters
    )
  )
}


# ==============================================================================
# 8. BUILD REGISTERED MARSS MODEL SPECIFICATION
# ==============================================================================

build_registered_model_spec <- function(
    model_row,
    dat_matrix,
    feature_object,
    site_registry,
    biological_years
) {
  
  validate_model_row(
    model_row
  )
  
  
  # ---------------------------------------------------------------------------
  # Pull registry values
  # ---------------------------------------------------------------------------
  
  model_id <- as.character(
    model_row$Model_ID[[1]]
  )
  
  model_family <- as.character(
    model_row$Model_Family[[1]]
  )
  
  hypothesis <- as.character(
    model_row$Hypothesis[[1]]
  )
  
  requested_covariates <- parse_model_covariates(
    model_row$Covariates[[1]]
  )
  
  c_structure <- tolower(
    trimws(
      as.character(
        model_row$C_Structure[[1]]
      )
    )
  )
  
  B_structure <- as.character(
    model_row$B_Structure[[1]]
  )
  
  U_structure <- as.character(
    model_row$U_Structure[[1]]
  )
  
  Q_structure <- as.character(
    model_row$Q_Structure[[1]]
  )
  
  R_structure <- as.character(
    model_row$R_Structure[[1]]
  )
  
  
  cat("\n")
  cat("============================================================\n")
  cat("BUILDING REGISTERED MODEL SPECIFICATION\n")
  cat("============================================================\n")
  
  cat(
    "Model:",
    model_id,
    "\n"
  )
  
  cat(
    "Family:",
    model_family,
    "\n"
  )
  
  cat(
    "Hypothesis:",
    hypothesis,
    "\n"
  )
  
  cat(
    "C structure:",
    c_structure,
    "\n"
  )
  
  
  # ---------------------------------------------------------------------------
  # Requested feature validation
  # ---------------------------------------------------------------------------
  
  validate_requested_features(
    requested_covariates = requested_covariates,
    feature_object = feature_object,
    model_id = model_id
  )
  
  
  # ===========================================================================
  # NULL MODEL
  # ===========================================================================
  
  if (length(requested_covariates) == 0) {
    
    if (!c_structure %in% c("none", "")) {
      warning(
        paste(
          model_id,
          "contains no covariates but C_Structure is",
          c_structure
        )
      )
    }
    
    
    model_spec <- list(
      Z = "identity",
      R = R_structure,
      B = B_structure,
      U = U_structure,
      Q = Q_structure
    )
    
    
    cat(
      "Covariates: NONE\n"
    )
    
    cat(
      "Expected climate parameters: 0\n"
    )
    
    cat(
      "NULL MODEL SPECIFICATION PASS.\n"
    )
    
    
    return(
      list(
        model_id = model_id,
        model_family = model_family,
        hypothesis = hypothesis,
        registry_row = model_row,
        covariates = character(0),
        cov_matrix = NULL,
        C_matrix = NULL,
        C_audit = list(
          expected_C = 0,
          active_cells = 0,
          n_free_C = 0,
          parameter_names = character(0)
        ),
        expected_free_C = 0,
        model_spec = model_spec
      )
    )
  }
  
  
  # ===========================================================================
  # COVARIATE MODEL
  # ===========================================================================
  
  supported_C_structures <- c(
    "site_specific"
  )
  
  
  if (!c_structure %in% supported_C_structures) {
    stop(
      paste(
        "Unsupported C_Structure:",
        c_structure,
        "for model",
        model_id,
        ". Currently supported:",
        paste(
          supported_C_structures,
          collapse = ", "
        )
      )
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Build MARSS c matrix
  # ---------------------------------------------------------------------------
  
  cov_matrix <- build_marss_covariate_matrix(
    feature_data = feature_object$model_window,
    requested_covariates = requested_covariates,
    biological_years = biological_years
  )
  
  
  # ---------------------------------------------------------------------------
  # Build pond-specific C matrix
  # ---------------------------------------------------------------------------
  
  C_matrix <- build_site_specific_C_matrix(
    site_names = rownames(dat_matrix),
    covariate_names = rownames(cov_matrix),
    site_registry = site_registry
  )
  
  
  # ---------------------------------------------------------------------------
  # Audit C matrix
  # ---------------------------------------------------------------------------
  
  C_audit <- audit_site_specific_C_matrix(
    C_matrix = C_matrix,
    requested_covariates = requested_covariates,
    site_names = rownames(dat_matrix),
    model_id = model_id
  )
  
  
  # ---------------------------------------------------------------------------
  # Construct MARSS specification
  # ---------------------------------------------------------------------------
  
  model_spec <- list(
    Z = "identity",
    R = R_structure,
    B = B_structure,
    U = U_structure,
    Q = Q_structure,
    C = C_matrix,
    c = cov_matrix
  )
  
  
  # ---------------------------------------------------------------------------
  # Report
  # ---------------------------------------------------------------------------
  
  cat("\nRequested covariates:\n")
  print(requested_covariates)
  
  
  cat(
    "\nMARSS c dimensions:",
    nrow(cov_matrix),
    "x",
    ncol(cov_matrix),
    "\n"
  )
  
  
  cat(
    "MARSS C dimensions:",
    nrow(C_matrix),
    "x",
    ncol(C_matrix),
    "\n"
  )
  
  
  cat(
    "Free site-specific C parameters:",
    C_audit$n_free_C,
    "\n"
  )
  
  
  cat(
    "REGISTERED MODEL SPECIFICATION PASS.\n"
  )
  
  
  # ---------------------------------------------------------------------------
  # Return complete pre-fit object
  # ---------------------------------------------------------------------------
  
  list(
    model_id = model_id,
    model_family = model_family,
    hypothesis = hypothesis,
    registry_row = model_row,
    covariates = requested_covariates,
    cov_matrix = cov_matrix,
    C_matrix = C_matrix,
    C_audit = C_audit,
    expected_free_C = C_audit$n_free_C,
    model_spec = model_spec
  )
}


cat("\n============================================================\n")
cat("04_build_model_spec.R LOADED SUCCESSFULLY\n")
cat("============================================================\n")