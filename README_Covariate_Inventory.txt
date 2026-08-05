================================================================================
               CALIFORNIA RED-LEGGED FROG (CRLF) MARSS MODELING
                   COVARIATE MATRIX INVENTORY (9 SCENARIOS)
================================================================================
Last Updated: 2026-08-04

--------------------------------------------------------------------------------
1. DIRECTORY OVERVIEW
--------------------------------------------------------------------------------
All files below are stored in: F:/CRLF_MARSS/marss_results/covariates/
These .rds files contain pre-scaled (Z-score: Mean=0, SD=1) numerical matrices
ready to be passed directly into the 'c' argument of the MARSS() function.

--------------------------------------------------------------------------------
2. MATRIX DIMENSIONS & STRUCTURE
--------------------------------------------------------------------------------
* Time Steps (Columns): All matrices contain exactly 29 columns representing
  the biological modeling window (Water Years 1997 - 2025).
* Single Covariate Models (1-6): 14 rows (one per localized monitoring site).
* Two-Covariate Models (7-9): 28 rows (stacked using rbind). The top 14 rows
  evaluate the cumulative drought debt (rolling mean), and the bottom 14 rows
  evaluate the delayed cohort effect (3-year lag).

--------------------------------------------------------------------------------
3. THE 9 MODEL SCENARIOS & FILE NAMES
--------------------------------------------------------------------------------

GROUP 1: CURRENT SEASON EFFECTS (Immediate Hydrology)
  Model 1: Early Season Only (Oct-Dec)
  File:    covar_matrix_model1_oct_dec_scaled.rds

  Model 2: Late Season Only (Jan-Mar)
  File:    covar_matrix_model2_jan_mar_scaled.rds

  Model 3: Early x Late Interaction (Compounding Winter Effect)
  File:    covar_matrix_model3_inter_cur.rds

GROUP 2: DELAYED COHORT EFFECTS (3-Year Lags / Adult Maturity)
  Model 4: Early Season Lag-3
  File:    covar_matrix_model1_5_oct_dec_lag3_scaled.rds

  Model 5: Late Season Lag-3
  File:    covar_matrix_model2_5_jan_mar_lag3_scaled.rds

  Model 6: Lag-3 Early x Late Interaction
  File:    covar_matrix_model6_inter_lag3.rds

GROUP 3: CUMULATIVE DROUGHT DEBT + LAG (Two-Covariate Models)
  Model 7: Water Year Mean (T=0) + Late Lag-3
  File:    covar_matrix_model7_mean0_lag3.rds

  Model 8: 2-Year Rolling Mean (T=0, T-1) + Late Lag-3
  File:    covar_matrix_model8_mean2yr_lag3.rds

  Model 9: 3-Year Rolling Mean (T=0, T-1, T-2) + Late Lag-3
  File:    covar_matrix_model9_mean3yr_lag3.rds

================================================================================
