# ==============================================================================
# 03_build_features.R
# CRLF MARSS PLUG-AND-PLAY PIPELINE
#
# PURPOSE:
#   Generate the approved climate feature catalog from the validated,
#   continuous historical watershed PDSI series.
#
# IMPORTANT:
#   Lags and running means are constructed BEFORE restricting the data
#   to the biological modeling window.
# ==============================================================================

library(dplyr)
library(tidyr)
library(tibble)


# ==============================================================================
# BUILD CLIMATE FEATURES
# ==============================================================================

build_climate_features <- function(
    climate_base,
    biological_years
) {
  
  cat("\n")
  cat("============================================================\n")
  cat("BUILDING CLIMATE FEATURE CATALOG\n")
  cat("============================================================\n")
  
  
  # ---------------------------------------------------------------------------
  # Full historical feature construction
  # ---------------------------------------------------------------------------
  
  df_features_full <- climate_base %>%
    
    arrange(
      Region,
      Year
    ) %>%
    
    group_by(
      Region
    ) %>%
    
    mutate(
      
      # ========================================================================
      # OCT-DEC PDSI
      # ========================================================================
      
      PDSI_OctDec_RunMean1 =
        PDSI_OctDec,
      
      
      PDSI_OctDec_RunMean2 =
        (
          PDSI_OctDec +
            lag(
              PDSI_OctDec,
              1
            )
        ) / 2,
      
      
      PDSI_OctDec_RunMean3 =
        (
          PDSI_OctDec +
            lag(
              PDSI_OctDec,
              1
            ) +
            lag(
              PDSI_OctDec,
              2
            )
        ) / 3,
      
      
      PDSI_OctDec_lag3 =
        lag(
          PDSI_OctDec,
          3
        ),
      
      
      # ========================================================================
      # JAN-MAR PDSI
      # ========================================================================
      
      PDSI_JanMar_RunMean1 =
        PDSI_JanMar,
      
      
      PDSI_JanMar_RunMean2 =
        (
          PDSI_JanMar +
            lag(
              PDSI_JanMar,
              1
            )
        ) / 2,
      
      
      PDSI_JanMar_RunMean3 =
        (
          PDSI_JanMar +
            lag(
              PDSI_JanMar,
              1
            ) +
            lag(
              PDSI_JanMar,
              2
            )
        ) / 3,
      
      
      PDSI_JanMar_lag3 =
        lag(
          PDSI_JanMar,
          3
        ),
      
      
      # ========================================================================
      # OCT-DEC × JAN-MAR INTERACTION
      # ========================================================================
      
      PDSI_Interact =
        PDSI_OctDec *
        PDSI_JanMar,
      
      
      PDSI_Interact_lag3 =
        lag(
          PDSI_Interact,
          3
        )
    ) %>%
    
    ungroup()
  
  
  # ---------------------------------------------------------------------------
  # Restrict only AFTER historical features exist
  # ---------------------------------------------------------------------------
  
  df_features_model <- df_features_full %>%
    
    filter(
      Year %in%
        biological_years
    )
  
  
  # ---------------------------------------------------------------------------
  # Official feature catalog
  # ---------------------------------------------------------------------------
  
  feature_names <- c(
    
    "PDSI_OctDec",
    
    "PDSI_JanMar",
    
    "PDSI_OctDec_RunMean1",
    
    "PDSI_OctDec_RunMean2",
    
    "PDSI_OctDec_RunMean3",
    
    "PDSI_OctDec_lag3",
    
    "PDSI_JanMar_RunMean1",
    
    "PDSI_JanMar_RunMean2",
    
    "PDSI_JanMar_RunMean3",
    
    "PDSI_JanMar_lag3",
    
    "PDSI_Interact",
    
    "PDSI_Interact_lag3"
  )
  
  
  # ---------------------------------------------------------------------------
  # NA QA over biological model years
  # ---------------------------------------------------------------------------
  
  na_summary <- df_features_model %>%
    
    summarise(
      across(
        all_of(
          feature_names
        ),
        ~ sum(
          is.na(
            .x
          )
        )
      )
    ) %>%
    
    pivot_longer(
      everything(),
      names_to = "Feature",
      values_to = "N_Missing"
    )
  
  
  cat("\n")
  cat("MODEL-WINDOW FEATURE QA\n")
  cat("=======================\n")
  
  print(
    na_summary,
    n = Inf
  )
  
  
  if (
    any(
      na_summary$N_Missing > 0
    )
  ) {
    
    stop(
      paste(
        "At least one derived climate feature contains missing",
        "values during the biological model window."
      )
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Confirm every biological year exists for every watershed
  # ---------------------------------------------------------------------------
  
  coverage_check <- df_features_model %>%
    
    count(
      Region,
      name = "N_Years"
    )
  
  
  expected_n_years <- length(
    unique(
      biological_years
    )
  )
  
  
  bad_coverage <- coverage_check %>%
    
    filter(
      N_Years != expected_n_years
    )
  
  
  if (
    nrow(
      bad_coverage
    ) > 0
  ) {
    
    print(
      bad_coverage,
      n = Inf
    )
    
    stop(
      "Not every watershed has complete coverage for all biological years."
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Feature catalog metadata
  # ---------------------------------------------------------------------------
  
  feature_catalog <- tribble(
    
    ~Feature,
    ~Feature_Family,
    ~Spatial_Scale,
    ~Temporal_Structure,
    ~Description,
    
    "PDSI_OctDec",
    "Climate",
    "Watershed",
    "t",
    "Current Oct-Dec PDSI",
    
    "PDSI_JanMar",
    "Climate",
    "Watershed",
    "t",
    "Current Jan-Mar PDSI",
    
    "PDSI_OctDec_RunMean1",
    "Climate",
    "Watershed",
    "t",
    "Current Oct-Dec PDSI; explicit RunMean1 alias",
    
    "PDSI_OctDec_RunMean2",
    "Climate",
    "Watershed",
    "mean(t,t-1)",
    "Two-year Oct-Dec PDSI running mean",
    
    "PDSI_OctDec_RunMean3",
    "Climate",
    "Watershed",
    "mean(t,t-1,t-2)",
    "Three-year Oct-Dec PDSI running mean",
    
    "PDSI_OctDec_lag3",
    "Climate",
    "Watershed",
    "t-3",
    "Oct-Dec PDSI three years earlier",
    
    "PDSI_JanMar_RunMean1",
    "Climate",
    "Watershed",
    "t",
    "Current Jan-Mar PDSI; explicit RunMean1 alias",
    
    "PDSI_JanMar_RunMean2",
    "Climate",
    "Watershed",
    "mean(t,t-1)",
    "Two-year Jan-Mar PDSI running mean",
    
    "PDSI_JanMar_RunMean3",
    "Climate",
    "Watershed",
    "mean(t,t-1,t-2)",
    "Three-year Jan-Mar PDSI running mean",
    
    "PDSI_JanMar_lag3",
    "Climate",
    "Watershed",
    "t-3",
    "Jan-Mar PDSI three years earlier",
    
    "PDSI_Interact",
    "Climate interaction",
    "Watershed",
    "t",
    "Current Oct-Dec PDSI multiplied by current Jan-Mar PDSI",
    
    "PDSI_Interact_lag3",
    "Climate interaction",
    "Watershed",
    "t-3",
    "Oct-Dec × Jan-Mar interaction three years earlier"
  )
  
  
  cat("\n")
  cat(
    "Feature catalog built:",
    nrow(feature_catalog),
    "available features.\n"
  )
  
  cat(
    "Model window:",
    min(biological_years),
    "-",
    max(biological_years),
    "\n"
  )
  
  
  # ---------------------------------------------------------------------------
  # Return standardized feature object
  # ---------------------------------------------------------------------------
  
  list(
    
    full_history =
      df_features_full,
    
    model_window =
      df_features_model,
    
    feature_catalog =
      feature_catalog,
    
    na_summary =
      na_summary
  )
}