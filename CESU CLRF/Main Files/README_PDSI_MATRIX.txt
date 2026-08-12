================================================================================
               CALIFORNIA RED-LEGGED FROG (CRLF) POPULATION DYNAMICS
                     MARSS STATE-SPACE MODELING COVARIATE PIPELINE
                               README DOCUMENTATION
================================================================================
Last Updated: 2026-07-16
Pipeline Purpose: Raw Climate Processing, Feature Engineering, and Standardization
Contact/PI: Anthony

--------------------------------------------------------------------------------
1. OVERVIEW & BIOLOGICAL OBJECTIVES
--------------------------------------------------------------------------------
This pipeline processes localized climate drivers to model the population dynamics
of the California Red-legged Frog (Rana draytonii) across 8 distinct coastal 
watersheds using Multivariate Auto-Regressive State-Space (MARSS) models.

The primary goal is to examine how seasonal drought sequences (represented by the
Palmer Drought Severity Index, PDSI) and delayed climate feedback (3-year lags,
corresponding to CRLF egg-to-breeding-adult maturity) govern annual egg-mass
recruitment rates.

--------------------------------------------------------------------------------
2. DATA SOURCE & SPATIAL COVERAGE
--------------------------------------------------------------------------------
Source: WestWide Drought Tracker (WWDT) monthly wide-format PDSI data.
Spatial Scale: 8 Individual, watershed-specific timeseries (no regional averaging):
  - KANOFF_CREEK
  - LAGUNA_SALADA
  - MILAGRA_CREEK
  - OAKWOOD_VALLEY
  - REDWOOD_CREEK
  - RODEO_LAGOON
  - TENNESSEE_VALLEY
  - WILKINS_GULCH

Temporal Range (Raw Climate Data): 1895 - 2026 (132 continuous years).
Biological Modeling Window: Water Years 1997 - 2025 (29 years of frog counts).

--------------------------------------------------------------------------------
3. FEATURE ENGINEERING & WATER YEAR LOGIC
--------------------------------------------------------------------------------
Because CRLF breeding and egg-laying are initiated by winter rainfall, we map all
climate metrics to 'Water Years' rather than calendar years.
For any target Water Year T, the biological year begins in October of calendar year T-1.

Four distinct seasonal windows were engineered to capture critical life-history stages:

A. Early Season Covariates (Autumn / Egg-Laying Prep):
   - 'OctDec' (T): Mean PDSI of Oct, Nov, Dec in calendar year T-1.
   - 'OctJan' (T): Mean PDSI of Oct, Nov, Dec (T-1) and Jan of calendar year T.
B. Late Season Covariates (Winter / Larval Development & Hydrologic Hydroperiod):
   - 'JanMar' (T): Mean PDSI of Jan, Feb, Mar in calendar year T.
   - 'FebMar' (T): Mean PDSI of Feb, Mar in calendar year T.

C. Delayed Feedback (3-Year Lags / t-3):
   - CRLF individuals typically take 3 years to reach breeding maturity.
   - All four seasonal windows are lagged by 3 years (e.g., OctDec_lag3, JanMar_lag3)
     to evaluate delayed environmental influences on adult breeding cohorts.
   - CRITICAL PIPELINE GUARD: To prevent losing modeling years at the start of our
     biological window, the 3-year lags were calculated on the raw 1895-2026 data
     *before* subsetting. Consequently, the first modeling year (1997) contains
     fully populated, real historical climate data from 1994 (no NA values).

D. Sequence Interactions (Winter Storm Sequencing):
   - Climate sequences (e.g., a dry autumn followed by a wet late-winter) are
     captured via multiplicative interaction terms between early and late seasons
     (e.g., OctDec * JanMar) for both current-year and 3-year lagged variables.

--------------------------------------------------------------------------------
4. SWAPPABLE MODEL COVARIATE PACKAGES (Z-SCORE STANDARDIZED)
--------------------------------------------------------------------------------
Due to extreme collinearity between overlapping months (e.g., Oct-Dec vs. Oct-Jan,
r = 0.98), these variables cannot be evaluated in the same model run without
destabilizing the state-space estimation. To resolve this, variables are partitioned
into 4 swappable, non-overlapping matrix configurations, scaled and ready for MARSS:

----------------------------------------------------------------------------------
 PACKAGE | EARLY SEASON | LATE SEASON | INTERACTION TERM | MODELING FOCUS
----------------------------------------------------------------------------------
 Package 1 | OctDec       | JanMar      | OctDec*JanMar    | Primary Winter Split
 Package 2 | OctDec       | FebMar      | OctDec*FebMar    | Trimmed Mid-Winter
 Package 3 | OctJan       | FebMar      | OctJan*FebMar    | Extended Fall Runoff
 Package 4 | OctJan       | JanMar      | OctJan*JanMar    | Symmetric Deep Winter
----------------------------------------------------------------------------------
 * Note: Each package includes: Current Seasonal, Current Interaction, Lagged (t-3) Seasonal, 
         and Lagged (t-3) Interaction (Total: 6 Covariate Tracks x 29 Years).
 * Scaling: To make effect size parameter estimates directly comparable in MARSS,
   all row vectors are individually Z-score standardized (Mean = 0, SD = 1).

--------------------------------------------------------------------------------
5. FILE DIRECTORY & INVENTORY
--------------------------------------------------------------------------------
Data is organized within the project repository as follows:

📁 raw_data (External/Drive):
   └─ F:/CRLF_MARSS/wwdt_data/          <- Contains the 8 raw wide WWDT CSVs

📁 marss_results/covariates/             <- Directory containing processed files:
   ├─ README.txt                        <- This file.
   ├─ pdsi_visual_check.png             <- Side-by-side timeseries plot (1997-2025).
   ├─ watershed_pdsi_master_long.csv    <- Raw, unscaled calculated metrics (1896-2026).
   │                                       Used for verification and custom plotting.
   └─ pdsi_matrix_[PKG]_[WATERSHED].rds <- Standardized matrices (6 rows x 29 columns).
                                           Loaded directly into MARSS 'c' input.

--------------------------------------------------------------------------------
6. R TEMPLATE: INGESTING COVARIATE MATRICES INTO MARSS
--------------------------------------------------------------------------------
Below is an example of how to dynamically load a specific covariate package
for a target watershed in your MARSS scripts:

  # A. Define selection parameter
  target_pkg       <- 'pkg1_oct_dec_jan_mar' # Options: pkg1, pkg2, pkg3, pkg4
  target_watershed <- 'KANOFF_CREEK'
  
  # B. Build path and read matrix
  covar_path <- file.path('marss_results/covariates', 
                          paste0('pdsi_matrix_', target_pkg, '_', target_watershed, '.rds'))
  
  covar_matrix <- readRDS(covar_path)
  
  # C. Verify dimensions (Must be exactly 6 rows by 29 columns)
  print(dim(covar_matrix)) # [1]  6 29
  print(colnames(covar_matrix)) # '1997' '1998' ... '2025'
  print(rownames(covar_matrix)) # 'OctDec' 'JanMar' 'Int_P1_Current' ...
================================================================================
