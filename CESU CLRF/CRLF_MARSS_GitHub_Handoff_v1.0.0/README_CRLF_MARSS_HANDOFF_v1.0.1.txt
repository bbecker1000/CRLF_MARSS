================================================================================
CALIFORNIA RED-LEGGED FROG (CRLF) MARSS POPULATION-DYNAMICS PIPELINE
MASTER HANDOFF README / USER MANUAL
Version 1.0.0
Validated clean-session baseline: 2026-08-10
================================================================================

PURPOSE
-------
This document is the primary handoff manual for the CRLF MARSS workflow. It
documents the data lineage, important variables, model architecture, climate
covariates, C-matrix logic, decisions made during data preparation, and the
steps required to reproduce or extend the analysis.

The CURRENT v1.0 analysis uses 14 sites across Water Years 1997-2025. Older
16-site files are retained as provenance but are not the authoritative final
model input.

================================================================================
1. QUICK START
================================================================================

Recommended final repository layout:

CRLF_MARSS/
|-- 00_run_full_pipeline.R
|-- config/
|   |-- model_registry.csv
|   |-- site_registry.csv
|   `-- pipeline_settings.csv
|-- R/
|   |-- 01_load_inputs.R
|   |-- 02_validate_inputs.R
|   |-- 03_build_features.R
|   |-- 04_build_model_spec.R
|   |-- 05_fit_model.R
|   |-- 06_bootstrap_model.R
|   |-- 07_extract_results.R
|   |-- 08_model_diagnostics.R
|   |-- 09_model_selection.R
|   |-- 10_make_figures.R
|   `-- 11_run_registry.R
|-- marss_results/
|-- docs/
`-- archive/

Run from a clean R session:

  setwd("F:/CRLF_MARSS")
  source("00_run_full_pipeline.R")

If the master script is still inside R/:

  source("R/00_run_full_pipeline.R")

Final clean-session validation:
  Registered models: 12
  Converged models:  12
  Pipeline errors:    0

================================================================================
2. BIOLOGICAL DATA REPOSITORY MAP
================================================================================

Master_AnnualEggs_StaffWindow_Cleaned_Hydroperiod_1997_2025.csv
  Type: CSV
  Shape: 2,117 rows x 14 columns
  Role: Primary ANNUAL SITE-YEAR biological/hydrology master table.

  Important clarification:
  73 sites x 29 years = 2,117 site-years. Because fields such as
  egg_masses_annual are already annualized, this file should not be described
  as a raw row-by-row survey log. It is the complete annual site-year master
  grid.

marss_y_raw_counts_wide.csv
  Type: CSV
  Historical shape: 16 rows x 30 columns
  Role: Intermediate wide raw-count matrix after the >=15-year monitoring
  filter but before the final two-site exclusion.
  Status: Preliminary / legacy relative to the final 14-site model.

marss_matrix_y_logTransformed.rds
  Type: R binary
  Historical shape: 16 sites x 29 years
  Role: Earlier 16-site log-transformed matrix.
  Status: Preliminary / legacy if it still contains 16 sites.

marss_results/biological/marss_matrix_y_14sites_logTransformed.rds
  Type: R binary
  Shape: 14 sites x 29 years
  Role: AUTHORITATIVE v1.0 MARSS biological response matrix.
  Transformation: y = log(egg_masses_annual + 1)
  Coverage: 273 observed site-years; 133 missing; 406 possible.

Core_Sites_LatLon.csv
  Type: CSV
  Shape: 58 rows x 4 columns
  Role: Broader spatial coordinate reference for core and peripheral sites.
  Current model membership is defined by config/site_registry.csv.

watershed_pdsi_master_long.csv
  Type: CSV
  Horizon: 1896-2026
  Role: Regional historical PDSI master used to build MARSS climate features.
  Source: WestWide Drought Tracker (WWDT), HUC-8 watershed-level PDSI.
  Project link: https://wrcc.dri.edu/wwdt/

README_PDSI_COVARIATE.R
  Type: R script
  Role: Historical helper for building MARSS c and C.
  Current replacement: R/03_build_features.R and R/04_build_model_spec.R.

README_Y_Matrix.txt
  Type: Text documentation
  Role: Historical documentation of biological-matrix construction, survey
  integrity rules, inclusion criteria, and QA graphics.

================================================================================
3. RAW BIOLOGICAL DATA -> FINAL MARSS MATRIX
================================================================================

Workflow:

  Raw field survey records
        |
        v
  Standardize site IDs, dates, water year, egg counts, staff gauge
        |
        v
  Audit annual survey status
        |
        |-- surveyed_nonzero
        |-- surveyed_zero
        `-- not_surveyed
        |
        v
  Aggregate egg masses to annual site counts
        |
        v
  Build complete 73-site x 29-year annual grid
        |
        v
  Retain sites with >=15 actively surveyed years
        |
        v
  16 sites pass the monitoring-history screen
        |
        v
  Remove TV03 and LS09 from the final population model
        |
        v
  FINAL 14 SITES
        |
        v
  Preserve surveyed zero = 0
  Preserve unsurveyed gap = NA
        |
        v
  Apply log(count + 1)
        |
        v
  marss_matrix_y_14sites_logTransformed.rds

================================================================================
4. ZERO VS NA: NON-NEGOTIABLE DATA-INTEGRITY RULE
================================================================================

Confirmed survey with no egg masses:
  raw count = 0
  transformed value = log(0 + 1) = 0

No adequate biological survey:
  value = NA

Never convert an unmonitored year to zero. A zero means a survey occurred and
no egg masses were detected. NA means the biological state was not observed.

Across the complete 73-site annual master:
  not_surveyed:      1,501 site-years (70.9%)
  surveyed_zero:       354 site-years (16.7%)
  surveyed_nonzero:    262 site-years (12.4%)
  observed surveys:    616 site-years

================================================================================
5. SITE-SELECTION DECISION: 73 -> 16 -> 14
================================================================================

First screen:
  Sites required >=15 active survey years during 1997-2025.
  16 sites passed.

Those 16 sites contained:
  8,071 of 9,838 recorded egg masses = 82.04% of project egg masses.

Final biological-information screen:
  Two sites passed the monitoring-history threshold but had essentially no
  positive breeding signal.

TV03
  Watershed: Tennessee Valley
  Active years: 16
  Zero years: 16
  Total egg masses: 0
  Final status: EXCLUDED FROM MARSS y MATRIX
  Reason: complete all-zero biological series.

LS09
  Watershed: Laguna Salada
  Active years: 17
  Zero years: 15
  Total egg masses: 2
  Final status: EXCLUDED FROM MARSS y MATRIX
  Reason: only two egg masses in the entire monitored series, providing
  extremely little positive abundance information for the final site-specific
  population-dynamics model.

These sites remain scientifically useful in project metadata as unoccupied or
near-nonbreeding reference sites. They are not deleted from the broader archive.

Final v1.0 modeled site count:
  16 - 2 = 14

================================================================================
6. FINAL 14 MODELED SITES
================================================================================

Laguna Salada:
  LS01  Perennial  37.621599  -122.494769
  LS04  Perennial  37.621660  -122.494248
  LS05  Perennial  37.621120  -122.492382
  LS06  Seasonal   37.620246  -122.492410
  LS07  Seasonal   37.619893  -122.492039
  LS08  Perennial  37.620674  -122.493078
  LS11  Perennial  ~37.621000 ~-122.491000

Milagra Creek:
  MC01  Seasonal   37.638958  -122.471994

Redwood Creek:
  RC07  Perennial  37.868232  -122.580885
  RC10  Seasonal   37.863221  -122.573444
  RC11  Seasonal   37.862058  -122.573280

Rodeo Lagoon:
  RL02  Perennial  37.832220  -122.525110

Tennessee Valley:
  TV02  Perennial  37.844403  -122.549628

Wilkins Gulch:
  WG01  Seasonal   37.934577  -122.695455

LS11 coordinate note:
  The current LS11 coordinates represent the Laguna Salada main-marsh /
  regional centroid and should be marked approximate unless an authoritative
  pond-level coordinate is located.

================================================================================
7. IMPORTANT BIOLOGICAL / HYDROLOGY VARIABLES
================================================================================

site_id
  Unique pond/site identifier.

watershed
  Watershed / regional grouping.

year
  Hydrologic Water Year. Model horizon = 1997-2025.

egg_masses_annual
  Annual total egg-mass abundance for a site-year.

egg_status_annual
  Annual survey audit category distinguishing positive, surveyed zero, and
  not surveyed.

hydroperiod
  Site-level classification: perennial or seasonal.

staff_max_oct_mar
  Maximum observed staff-gauge height during Oct-Mar.

staff_start_janmar
  First Jan-Mar staff-gauge value; start-of-breeding-season condition.

staff_mean_janmar
  Mean Jan-Mar staff-gauge height.

staff_mean_prev_oct_dec
  Mean Oct-Dec antecedent staff-gauge value.

n_staff_records_oct_mar
  Coverage / QA count of staff-gauge records.

Missing staff-gauge measurements are NA, not zero.

================================================================================
8. PDSI SOURCE AND CLIMATE COVARIATES
================================================================================

Source:
  WestWide Drought Tracker (WWDT)

Project URL:
  https://wrcc.dri.edu/wwdt/

Metric:
  Palmer Drought Severity Index (PDSI)

Spatial structure used by the project:
  HUC-8 watershed-level PDSI series.

Historical climate horizon:
  1896-2026.

Why the climate record begins long before the biological model:
  The MARSS biological model begins in 1997, but rolling means and t-3 lags
  require pre-1997 climate history. The historical record must therefore remain
  intact until AFTER climate features are constructed.

Climate-processing rule:

  full 1896-2026 regional series
          |
          v
  build current, rolling, lagged, and interaction features
          |
          v
  filter completed features to 1997-2025

Do NOT first truncate climate to 1997-2025 and then calculate lags.

================================================================================
9. WHY OCT-DEC AND JAN-MAR
================================================================================

PDSI_OctDec
------------
Definition:
  Mean October-November-December PDSI associated with the analysis / water-year
  record.

Interpretation:
  Early-season / antecedent hydroclimate.

Biological reasoning:
  These months represent early winter recharge and pond/pool filling conditions
  before the principal breeding period.

Primary question:
  Are early-season conditions important for annual site-level CRLF abundance?


PDSI_JanMar
------------
Definition:
  Mean January-February-March PDSI associated with the analysis / water-year
  record.

Interpretation:
  Late-season / principal breeding-period hydroclimate.

Biological reasoning:
  These months overlap the primary breeding / oviposition period and represent
  hydroclimatic conditions closer to observed egg-mass production.

Primary question:
  Are breeding-season conditions more informative than antecedent early-season
  conditions?


YEAR-LABEL RULE
---------------
The climate feature code operates on the Year labels present in the climate
master. Those labels must already be aligned consistently with the biological
Water Year convention.

For a row labeled 1997:
  t   = 1997
  t-1 = 1996
  t-2 = 1995
  t-3 = 1994

================================================================================
10. RUNNING-MEAN, LAG, AND INTERACTION VARIABLES
================================================================================

PDSI_OctDec_RunMean1
  Oct-Dec at t.

PDSI_OctDec_RunMean2
  mean of Oct-Dec at t and t-1.

PDSI_OctDec_RunMean3
  mean of Oct-Dec at t, t-1, and t-2.

PDSI_OctDec_lag3
  Oct-Dec value at t-3.

PDSI_JanMar_RunMean1
  Jan-Mar at t.

PDSI_JanMar_RunMean2
  mean of Jan-Mar at t and t-1.

PDSI_JanMar_RunMean3
  mean of Jan-Mar at t, t-1, and t-2.

PDSI_JanMar_lag3
  Jan-Mar value at t-3.

PDSI_Interact
  PDSI_OctDec * PDSI_JanMar for the contemporary year.

PDSI_Interact_lag3
  The interaction term lagged three years.


WHY t-3 WAS INCLUDED
--------------------
The t-3 variables test a biologically motivated cohort / maturity hypothesis:
conditions experienced three years before the current modeled year may affect
the abundance of individuals later contributing to the breeding population.

This should be described as a hypothesis, not as proof that every individual
has an exact three-year maturation schedule.


WHY RunMean3 DOES NOT INCLUDE t-3
---------------------------------
RunMean3 intentionally represents RECENT cumulative conditions:

  t, t-1, t-2

The separate lag3 variable represents:

  t-3

This allows the model to distinguish recent climate memory from the distinct
older cohort / maturity-year hypothesis.

================================================================================
11. EXPLICIT 1997 t-3 EXAMPLE
================================================================================

This example should remain in the handoff documentation because it prevents a
common lagging mistake.

For model year 1997:

  t   = 1997
  t-1 = 1996
  t-2 = 1995
  t-3 = 1994

Therefore:

PDSI_JanMar_RunMean3 for 1997 =
  mean(
    PDSI_JanMar[1997],
    PDSI_JanMar[1996],
    PDSI_JanMar[1995]
  )

PDSI_JanMar_lag3 for 1997 =
  PDSI_JanMar[1994]

PDSI_OctDec_RunMean3 for 1997 =
  mean(
    PDSI_OctDec[1997],
    PDSI_OctDec[1996],
    PDSI_OctDec[1995]
  )

PDSI_OctDec_lag3 for 1997 =
  PDSI_OctDec[1994]

A model defined as:

  RunMean3 + lag3

therefore uses:

  mean(1997, 1996, 1995) + 1994

It does NOT use:

  mean(1997, 1996, 1995, 1994)

This is why the climate source must include years before 1997.

================================================================================
12. FINAL BIOLOGICAL RESPONSE
================================================================================

Authoritative file:
  marss_results/biological/marss_matrix_y_14sites_logTransformed.rds

Dimensions:
  14 sites x 29 Water Years

Transformation:
  y(i,t) = log(egg_masses_annual(i,t) + 1)

Why +1:
  Keeps the transform defined for true biological zeros.

Why log-transform:
  Raw egg-mass counts are strongly right-skewed and range from zero to
  hundreds. The transformation compresses large differences and makes the
  response scale more compatible with the Gaussian state-space framework.

Important wording:
  The transformation improves compatibility with Gaussian assumptions. It
  does not prove that every model assumption is satisfied.

================================================================================
13. MARSS MODEL STRUCTURE
================================================================================

General state equation:

  x_t = B x_(t-1) + U + C c_t + w_t

General observation relationship:

  y_t = Z x_t + v_t

Current v1.0 structures:

  Z = "identity"
  B = "identity"
  U = "unequal"
  Q = "diagonal and unequal"
  R = "zero"

Climate models additionally contain:

  C = site-specific climate-response parameter matrix
  c = numeric climate covariate matrix

The null model omits C and c.


Z = identity
------------
Each observed biological series maps directly to the corresponding latent
site-level state.


B = identity
------------
Current state-transition structure used by the locked v1.0 pipeline.


U = unequal
-----------
Each of the 14 modeled sites estimates its own drift / growth parameter.


Q = diagonal and unequal
------------------------
Each site estimates its own process variance.

IMPORTANT:
Off-diagonal process covariances are not estimated. The current Q structure
therefore does NOT directly estimate cross-site process synchrony.


R = zero
--------
The current v1.0 model does not estimate a separate observation-error variance.

This is a strong assumption and must remain explicit in the documentation.

A future model with a different R structure should be treated as a new
sensitivity-analysis framework / Candidate_Set rather than silently replacing
v1.0.

================================================================================
14. c MATRIX VS C MATRIX
================================================================================

Lowercase c:
  Climate DATA.

Uppercase C:
  Climate-response PARAMETER / CONSTRAINT matrix.


CURRENT SPATIAL LOGIC
---------------------
Climate exposure is watershed-level.

Biological response is site/pond-level.

Sites within the same watershed share the same climate history but estimate
different response coefficients.


EXAMPLE: ONE JAN-MAR FEATURE
----------------------------
6 modeled watersheds
14 modeled sites
29 modeled years

c dimensions:
  6 x 29

C dimensions:
  14 x 6

For LS01:

  C[LS01, LAGUNA_SALADA_PDSI_JanMar]
      = "C_LS01_PDSI_JanMar"

All off-watershed entries in the LS01 row:
      = numeric 0

For LS04:

  C[LS04, LAGUNA_SALADA_PDSI_JanMar]
      = "C_LS04_PDSI_JanMar"

LS01 and LS04 use the same Laguna Salada Jan-Mar PDSI time series but their
response parameters are different.


WHY SITE-SPECIFIC C WAS CHOSEN
------------------------------
Ponds within the same watershed can share regional hydroclimate while differing
in local:

  hydroperiod
  morphology
  vegetation
  water retention
  habitat condition
  restoration history
  connectivity
  biological response

A watershed-shared slope would force all ponds in one watershed to respond
identically to climate.

The current model asks a different question:
  how does each pond respond to the climate history it experiences?


C-MATRIX CODING RULE
--------------------
Use:

  matrix(list(0), ...)

numeric 0:
  fixed zero / parameter not estimated

character parameter name:
  free parameter

Do not use character "0" or "zero" for fixed cells.

================================================================================
15. PARAMETER COUNTS AND C-MATRIX QA
================================================================================

Baseline model:
  14 U
  14 Q
  14 x0
  total K = 42

One climate feature:
  14 free C
  total K = 56

Two climate features:
  28 free C
  total K = 70

Three climate features:
  42 free C
  total K = 84


For F requested climate features:

  c dimensions = (6 * F) x 29
  C dimensions = 14 x (6 * F)
  expected free C = 14 * F

The builder must audit:

  number of sites
  number of requested features
  requested-feature existence
  model-year climate completeness
  c dimensions
  C dimensions
  active site-climate cells
  unique character parameter names
  expected free-C count

For 3 features:
  expected active cells = 42
  expected unique C names = 42

If a one-feature model contains only 6 unique climate slopes, that is a
watershed-shared model and is NOT the current site-specific architecture.

================================================================================
16. PIPELINE MODULES
================================================================================

R/01_load_inputs.R
  Loads settings, site registry, model registry, biological matrix, and climate
  master.

R/02_validate_inputs.R
  Validates sites, years, climate coverage, duplicate region-year rows, missing
  base PDSI, and registry structure.

R/03_build_features.R
  Builds the 12 PDSI features on the full historical climate series before
  filtering to the biological window.

R/04_build_model_spec.R
  Converts one registry row into a MARSS model definition; builds c and C and
  audits site-specific coefficients.

R/05_fit_model.R
  Fits KEM first; uses BFGS fallback for incomplete KEM convergence categories;
  saves final fit and fit summary.

R/06_bootstrap_model.R
  Runs selected parametric confidence-interval bootstraps.

R/07_extract_results.R
  Converts MARSS parameter output into readable site/watershed/covariate
  estimates and confidence intervals.

R/08_model_diagnostics.R
  Saves residuals, residual inventory, fit diagnostics, and observation
  coverage.

R/09_model_selection.R
  Joins registry metadata to model results and computes AIC/AICc ranking,
  deltas, and weights within Candidate_Set.

R/10_make_figures.R
  Creates standardized site-level parameter figures and candidate-set
  Delta-AICc figures.

R/11_run_registry.R
  Workflow manager. Loops through enabled model-registry rows and reuses
  compatible existing work.

00_run_full_pipeline.R
  User-facing master entry point.

================================================================================
17. MODEL REGISTRY
================================================================================

File:
  config/model_registry.csv

Core principle:
  A model is a scientific hypothesis defined in a registry row, not a separate
  copy-pasted R script.

Important fields:

  Model_Number
  Model_ID
  Model_Name
  Model_Family
  Scientific_Question
  Hypothesis
  Biological_Interpretation
  Candidate_Set
  Comparison_Role
  Covariates
  Season_Focus
  Climate_Window
  Time_Structure
  Lag_Structure
  Interaction
  C_Structure
  Expected_C_Parameters
  Expected_Total_K
  Fit_Model
  Run_Bootstrap
  Primary_Analysis

Do not reuse an old Model_ID for a mathematically different model.

================================================================================
18. FITTING, CONVERGENCE, AND RESUME LOGIC
================================================================================

Model fitting:
  KEM is attempted first.

If KEM fully converges:
  accept the KEM solution.

If KEM reaches an incomplete convergence category:
  warm-start BFGS from the KEM parameter estimates.

Saved files can include:
  fit_KEM_initial.rds
  fit_BFGS_fallback.rds
  fit.rds
  fit_summary.csv
  model_definition.csv

Resume logic:
  R/11_run_registry.R checks for a compatible model definition before reusing
  fit.rds.

If a saved fit matches:
  reuse it.

If the registered model definition changed:
  do not silently reuse it.

This protects the scientific meaning of model IDs and avoids rerunning expensive
models unnecessarily.

================================================================================
19. BOOTSTRAP CONFIDENCE INTERVALS
================================================================================

Current parameter-inference procedure:
  MARSSparamCIs(..., method = "parametric")

Purpose:
  estimate uncertainty for selected fitted parameters.

Recommended workflow:
  fit all candidate models
        |
        v
  compare AIC / AICc
        |
        v
  identify scientifically important / competitive models
        |
        v
  bootstrap selected models

This avoids spending hours bootstrapping clearly noncompetitive candidate
models.

Important:
  Parameter CI bootstrap is NOT AICbp.

Parameter-level fields:
  Estimate
  Lower_95
  Upper_95
  CI_Excludes_Zero

A one-feature site-specific model has 14 separate climate CIs.
A two-feature model has 28.
A three-feature model has 42.

Therefore confidence intervals belong in parameter-level tables, not in one
ambiguous model-level "CI" cell.

================================================================================
20. MODEL SELECTION
================================================================================

Model-level outputs:
  K
  LogLik
  AIC
  AICc
  Delta_AIC
  Delta_AICc
  Weight_AIC
  Weight_AICc

Why AICc matters:
  Site-specific climate responses add many parameters relative to the available
  biological observations. AICc adds a small-sample complexity penalty beyond
  ordinary AIC.

Candidate-set rule:
  Rankings, deltas, and weights are calculated WITHIN Candidate_Set only.

Current sets:
  PDSI_PRIMARY_HYPOTHESES_V1
  PDSI_EXPLORATORY_LEGACY_V1

Do not combine their weights.

Interpretation warning:
  A null-model AICc win does not mean "PDSI has no biological effect."

A climate model may improve LogLik substantially while losing AICc because the
site-specific C structure requires many additional coefficients.

Correct wording:
  "Within the specified candidate set and site-specific parameterization, the
  climate formulation did not improve expected fit enough to justify its added
  complexity according to AICc."

================================================================================
21. CURRENT v1.0 PRIMARY MODELS
================================================================================

P0 -- Just Egg-Mass Abundance
  Covariates: none
  Role: null/no-climate baseline
  K = 42

P1 -- Early Oct-Dec Contemporary Year
  Covariates:
    PDSI_OctDec
  Question:
    Is early-season PDSI important for population dynamics at individual sites?
  K = 56

P2 -- Late Jan-Mar Contemporary Year
  Covariates:
    PDSI_JanMar
  Question:
    Is breeding-season PDSI important for population dynamics at individual
    sites?
  K = 56

P3 -- Early Oct-Dec Contemporary + t-3
  Covariates:
    PDSI_OctDec
    PDSI_OctDec_lag3
  Question:
    Does early-season climate three years earlier add information after
    accounting for contemporary early-season conditions?
  K = 70

P4 -- Late Jan-Mar Contemporary + t-3
  Covariates:
    PDSI_JanMar
    PDSI_JanMar_lag3
  Question:
    Does breeding-season climate three years earlier add information after
    accounting for contemporary breeding-season conditions?
  K = 70

P5 -- Early x Late Contemporary
  Covariates:
    PDSI_OctDec
    PDSI_JanMar
    PDSI_Interact
  Question:
    Do contemporary early and late climate jointly influence population
    dynamics?
  Note:
    main effects are retained with the interaction.
  K = 84

P6 -- Early Running 3-Year Mean
  Covariates:
    PDSI_OctDec_RunMean3
  Question:
    Does mean early-season climate across t, t-1, and t-2 affect abundance?
  K = 56

P7 -- Late Running 3-Year Mean
  Covariates:
    PDSI_JanMar_RunMean3
  Question:
    Does mean breeding-season climate across t, t-1, and t-2 affect abundance?
  K = 56

P8 -- Early Recent 3-Year Mean + t-3
  Covariates:
    PDSI_OctDec_RunMean3
    PDSI_OctDec_lag3
  Question:
    Do recent early-season climate and the separate t-3 early-season climate
    jointly affect abundance?
  K = 70

P9 -- Late Recent 3-Year Mean + t-3
  Covariates:
    PDSI_JanMar_RunMean3
    PDSI_JanMar_lag3
  Question:
    Do recent breeding-season climate and the separate t-3 breeding-season
    climate jointly affect abundance?
  K = 70

Exploratory / legacy candidate set:
  E1 = Fully Lagged Early x Late Interaction
  E2 = Early Running 2-Year Mean

================================================================================
22. CURRENT v1.0 VALIDATION SNAPSHOT
================================================================================

At the final clean-session validation:

  Registered models: 12
  Fit summaries:     12
  Converged:         12
  Missing fits:       0
  Failed/error:       0
  Pipeline errors:    0

Primary AICc ranking at validation:

  1. P0  Null / Just Egg-Mass Abundance          AICc ~ 964   Delta = 0
  2. P2  Late Jan-Mar Contemporary               AICc ~ 972   Delta = 8.35
  3. P6  Early Running 3-Year Mean               AICc ~ 984   Delta = 20.1
  4. P7  Late Running 3-Year Mean                AICc ~ 994   Delta = 30.2
  5. P1  Early Oct-Dec Contemporary              AICc ~ 996   Delta = 32.5
  6. P4  Late Contemporary + t-3                 AICc ~ 997   Delta = 33.3
  7. P8  Early RunMean3 + t-3                    AICc ~1016   Delta = 52.1
  8. P9  Late RunMean3 + t-3                     AICc ~1022   Delta = 58.6
  9. P3  Early Contemporary + t-3                AICc ~1029   Delta = 65.0
 10. P5  Early x Late Contemporary               AICc ~1034   Delta = 70.8

This is a handoff snapshot.
The live source of truth is:

  marss_results/master_tables/master_model_selection.csv

================================================================================
23. OUTPUT FILES
================================================================================

Per-model directory:
  marss_results/models/<Model_ID>/

Important files:

fit.rds
  final accepted MARSS fit object

fit_summary.csv
  fit status, convergence, K, LogLik, AIC, AICc, Run_ID

model_definition.csv
  saved model definition used for compatibility checking

fit_KEM_initial.rds
  initial KEM fit

fit_BFGS_fallback.rds
  BFGS result when fallback was required

fit_bootstrap_CIs.rds
  parameter-bootstrap result when available

bootstrap_summary.csv
  bootstrap status, seed, nboot, method, runtime

parameters.csv
  parameter-level estimates and confidence intervals

parameters_C_climate.csv
  climate-response parameters only

parameter_QA.csv
  parameter-count audit

diagnostics/
  residual and observation-coverage outputs

figures/
  parameter plots


Master outputs:

marss_results/master_tables/master_model_results.csv
  rich registry + fit result table

marss_results/master_tables/master_model_selection.csv
  primary human-readable model/hypothesis comparison table

marss_results/master_tables/registered_models_not_yet_fit.csv
  registered requested models without a fit

marss_results/master_tables/failed_models.csv
  failed/error models

marss_results/plots/
  candidate-set model-selection figures

marss_results/logs/
  registry execution logs

marss_results/runs/
  reproducibility snapshots, settings, QA, sessionInfo

================================================================================
24. IMPORTANT ASSUMPTIONS / LIMITATIONS
================================================================================

1. The final response is annual egg-mass abundance, not a census of all life
   stages.

2. Surveyed zero and unsurveyed NA are fundamentally different.

3. The log transform improves scale behavior but does not guarantee all
   Gaussian assumptions.

4. R is fixed to zero, so v1.0 does not estimate separate observation error.

5. Q is diagonal and unequal, so current v1.0 does not estimate cross-site
   process covariance.

6. Climate exposure is watershed-level; climate response is site-specific.

7. Site-specific C is high-dimensional and can receive strong AICc penalties.

8. PDSI associations are observational. A coefficient is not automatic proof of
   causation.

9. t-3 is a cohort/maturity hypothesis, not an exact biological law.

10. Akaike weights depend on the models included in the candidate set.

================================================================================
25. LEGACY / CURRENT VERSION WARNINGS
================================================================================

16-site biological files:
  The >=15-year monitoring filter produced 16 sites.
  Final v1.0 removed TV03 and LS09.
  Any 16-site y matrix is therefore preliminary relative to v1.0.

Old watershed-shared C:
  Older architecture estimated one slope per watershed per feature.

  Approximate parameter totals:
    baseline = 42
    1 feature = 48
    2 features = 54
    3 features = 60

Current site-specific C:
    baseline = 42
    1 feature = 56
    2 features = 70
    3 features = 84

These are different scientific parameterizations.
Do not mix their AICc tables.

README_PDSI_COVARIATE.R:
  historical helper only.
  Active logic is in R/03 and R/04.

Model IDs:
  never change an existing Model_ID to mean a different mathematical model.

================================================================================
26. ADDING A NEW MODEL
================================================================================

If the feature already exists:

  1. Open config/model_registry.csv.
  2. Add a new row.
  3. Give it a NEW permanent Model_ID.
  4. Add Model_Number and Model_Name.
  5. Write Scientific_Question.
  6. Write Hypothesis.
  7. Write Biological_Interpretation.
  8. List Covariates separated by "|".
  9. Assign Candidate_Set.
 10. Set C_Structure.
 11. Record Expected_C_Parameters.
 12. Record Expected_Total_K.
 13. Usually leave Run_Bootstrap = FALSE during candidate screening.
 14. Run the full pipeline.
 15. Verify C-matrix QA.
 16. Verify convergence.
 17. Review AIC/AICc.
 18. Bootstrap only models selected for inference.

Do not create a new copy-pasted MARSS script for every hypothesis.

================================================================================
27. ADDING A NEW COVARIATE TYPE
================================================================================

Potential future predictors:
  staff-gauge hydrology
  hydroperiod
  static connectivity
  dynamic connectivity

Preferred architecture:

  new source data
       |
       v
  documented reproducible feature builder
       |
       v
  feature QA
       |
       v
  model_registry hypotheses
       |
       v
  same generic MARSS fit / diagnostic / selection pipeline

Current climate matrix logic is watershed-feature based.

A site-year variable such as dynamic connectivity may require an extension of
the model-spec builder so the predictor's spatial scale is represented
correctly. Do not force a site-level predictor into a watershed structure.

================================================================================
28. GITHUB / HANDOFF GUIDANCE
================================================================================

Recommended to commit:
  README documentation
  00_run_full_pipeline.R
  R/*.R
  config/model_registry.csv
  config/site_registry.csv
  config/pipeline_settings.csv
  lightweight master tables
  lightweight final figures
  CHANGELOG
  .gitignore

Usually do not commit to normal Git history:
  fit.rds
  fit_KEM_initial.rds
  fit_BFGS_fallback.rds
  fit_bootstrap_CIs.rds
  large residual RDS files
  repeated large run snapshots
  credentials
  restricted biological data

Before public release, confirm permission to release:
  raw CRLF monitoring data
  exact coordinates
  sensitive site notes
  staff-gauge records
  agency-owned source data

A public repository can still contain code, schemas, documentation, model
registry, and instructions even if sensitive data remain in controlled storage.

================================================================================
29. FINAL HANDOFF CHECKLIST
================================================================================

PIPELINE
[ ] 00_run_full_pipeline.R in intended final location
[ ] R/01 through R/11 present
[ ] model_registry.csv present
[ ] site_registry.csv present
[ ] pipeline_settings.csv present

BIOLOGICAL DATA
[ ] Final matrix identified as 14 x 29
[ ] TV03 exclusion documented: 16/16 zero years, 0 eggs
[ ] LS09 exclusion documented: 15/17 zero years, 2 eggs
[ ] surveyed zero vs NA documented
[ ] water-year convention documented

SPATIAL DATA
[ ] coordinate source documented
[ ] LS11 marked approximate / centroid
[ ] public coordinate permissions confirmed

PDSI
[ ] WWDT source documented
[ ] HUC-8 scale documented
[ ] 1896-2026 history documented
[ ] Oct-Dec rationale documented
[ ] Jan-Mar rationale documented
[ ] 1997 lag3 = 1994 documented
[ ] 1997 RunMean3 = mean(1997,1996,1995) documented
[ ] features built before filtering to 1997-2025 documented

MARSS
[ ] site-specific C documented
[ ] c vs C documented
[ ] K=42/56/70/84 documented
[ ] R=zero documented
[ ] Q diagonal-and-unequal limitation documented

MODEL SELECTION
[ ] primary vs exploratory Candidate_Set documented
[ ] AICc interpretation documented
[ ] CI bootstrap distinguished from AICbp
[ ] master_model_selection.csv retained

REPRODUCIBILITY
[ ] clean-session run completed
[ ] 12/12 models converged/reused
[ ] 0 pipeline errors
[ ] sessionInfo saved
[ ] validation run snapshot retained
[ ] locked-input hashes created if possible

GITHUB
[ ] .gitignore reviewed
[ ] no credentials staged
[ ] no restricted coordinates staged accidentally
[ ] no large binary fits staged accidentally
[ ] authorship/citation decided
[ ] license decided
[ ] repository visibility decided
[ ] v1.0.0 tagged after final review

================================================================================
30. FINAL HANDOFF PRINCIPLE
================================================================================

A future analyst should be able to answer all of these questions from this
README plus the config files:

  What is the biological response?
  Why are zeros different from NA?
  Why did 73 sites become 16 and then 14?
  Why were TV03 and LS09 removed?
  Where are site coordinates stored?
  Which coordinates are approximate?
  What does hydroperiod mean?
  Where does PDSI come from?
  Why Oct-Dec?
  Why Jan-Mar?
  What does t-3 mean?
  What does model year 1997 use for lag3? 1994.
  What does RunMean3 use for 1997? 1997, 1996, 1995.
  Why must climate history extend before 1997?
  What is c?
  What is C?
  Why are C coefficients site-specific?
  Why is R fixed at zero?
  What does Q estimate and not estimate?
  How are models added?
  How are models compared?
  Which files are current and which are legacy?
  How can the full analysis be rerun?

If those questions are answerable without reverse-engineering an old model
script, the handoff documentation is doing its job.

================================================================================
END OF MASTER HANDOFF README
================================================================================

================================================================================
31. DEEP-PARSE ADDENDUM: README_Y_MATRIX / README_PDSI_COVARIATE
================================================================================

This section incorporates additional provenance recovered from the historical
README_Y_Matrix.txt and README_PDSI_COVARIATE.R documentation.

31.1 HISTORICAL 16-SITE TARGET
------------------------------
The older README correctly described an intermediate 16 x 29 biological matrix
after applying the >=15 actively monitored-year criterion.

The final v1.0 workflow subsequently removed:
  TV03 -- 16 surveyed years, 16 zero years, 0 egg masses
  LS09 -- 17 surveyed years, 15 zero years, 2 total egg masses

Therefore:
  16-site matrices = monitoring-history-qualified intermediate products
  14-site matrix    = final v1.0 MARSS model input

31.2 IMPORTANT BIOLOGICAL OUTPUT FILES RECOVERED FROM THE OLD README
--------------------------------------------------------------------
marss_matrix_y_logTransformed.rds
  Historical 16 x 29 log(count + 1) matrix.
  Treat as legacy/intermediate if it still contains 16 sites.

marss_matrix_y_raw.rds
  Historical 16 x 29 raw numeric-count matrix.
  Important provenance/QA companion and worth retaining.

marss_y_raw_counts_wide.csv
  Historical human-readable wide matrix:
  16 site rows plus 29 Water-Year columns.
  Useful for manual auditing of positive counts, zeros, and NA gaps.

biological_site_metadata.csv
  Historical site metadata linkage:
  Site IDs, site names, watershed, hydroperiod, and related metadata.

Recommended final 14-site companions:
  marss_matrix_y_14sites_raw.rds
  marss_y_14sites_raw_counts_wide.csv
  marss_matrix_y_14sites_logTransformed.rds
  biological_site_metadata_14sites.csv

Do not delete the 16-site versions. Archive them as the pre-final screening
stage.

31.3 NUMERIC-INTEGRITY STANDARD
-------------------------------
The final y matrices should contain only:
  numeric positive counts
  numeric 0 for confirmed surveyed zeros
  true NA for unmonitored years

Do not allow text values such as:
  "0"
  "NA"
  "missing"
  "not_surveyed"

inside the numeric MARSS matrix.

Survey-status labels belong in the annual long-format audit table.

31.4 PRECISE NA / KALMAN-FILTER WORDING
---------------------------------------
Missing survey years remain NA.

MARSS accepts NA observations as missing. The state-space / Kalman-filter
machinery estimates latent states conditional on the fitted process model and
the available observations.

Do not describe a missing-year estimate as if it were an observed population
count or a known true value.

31.5 IMPORTANT Z-MATRIX LEGACY WARNING
--------------------------------------
The older README says biological_site_metadata.csv was used to construct
"structural grouping matrices (Z matrix) for watershed-level modeling."

That describes an earlier architecture.

CURRENT v1.0:
  Z = identity

Therefore current metadata/site-registry roles are:
  site identity
  site-to-watershed mapping
  hydroperiod
  coordinate linkage
  climate exposure mapping in c
  site-specific climate-response mapping/audit in C

Do NOT tell collaborators that the current Z matrix groups sites by watershed.

31.6 THREE-COLOR BIOLOGICAL QA HEATMAP
--------------------------------------
Historical QA figure:
  matrix_data_availability_heatmap_3color.png

Meaning:
  Gray   = unmonitored / NA
  Orange = surveyed zero
  Green  = positive egg-mass count

This is a high-value handoff diagnostic because it visually verifies the
zero-versus-missing rule.

Recommendation:
  retain it, or regenerate a final 14-site version named:
  matrix_data_availability_heatmap_3color_14sites.png

31.7 RAW-COUNT COMPANIONS SHOULD BE PRESERVED
---------------------------------------------
The transformed RDS is the model input, but the handoff should preserve a raw
matrix beside it.

Why:
  collaborators can audit the transformation;
  summary statistics can be reproduced directly;
  zeros and NA gaps are easy to inspect;
  the final model input can be independently checked.

Best final bundle:
  raw 14-site RDS
  wide 14-site raw CSV
  transformed 14-site RDS
  14-site metadata CSV
  14-site coverage heatmap

31.8 PATH CONSISTENCY
---------------------
Historical documentation references:
  outputs/Master_AnnualEggs_StaffWindow_Cleaned_Hydroperiod_1997_2025.csv

The final GitHub handoff should choose one canonical path and use the same path
in:
  README
  R/01_load_inputs.R
  data dictionary

If fallback paths are supported in code, label them as fallbacks.

31.9 CURRENT-vs-HISTORICAL SUMMARY
----------------------------------
Historical README material remains valuable for:
  >=15-year screening
  numeric-integrity rules
  zero-vs-NA handling
  raw/transformed matrix products
  site metadata linkage
  biological QA heatmap
  early automated C/c construction

Current v1.0 supersedes historical statements where architecture changed:
  16 sites -> 14 final modeled sites
  generic y filenames -> explicit 14-site authoritative filenames
  watershed-grouped Z language -> Z = identity
  README_PDSI_COVARIATE.R -> modular R/03 + R/04
  watershed-shared C variants -> site-specific C

================================================================================
32. RECOMMENDED FINAL BIOLOGICAL HANDOFF FILE SET
================================================================================

SOURCE / ANNUAL MASTER
  Master_AnnualEggs_StaffWindow_Cleaned_Hydroperiod_1997_2025.csv
  2,117 annual site-year rows = 73 sites x 29 years

FINAL SITE METADATA
  biological_site_metadata_14sites.csv

FINAL RAW MODEL-SUBSET MATRIX
  marss_matrix_y_14sites_raw.rds
  14 x 29

FINAL HUMAN-READABLE RAW MATRIX
  marss_y_14sites_raw_counts_wide.csv
  14 rows x 30 columns

FINAL MODEL MATRIX
  marss_matrix_y_14sites_logTransformed.rds
  14 x 29

FINAL COVERAGE QA
  matrix_data_availability_heatmap_3color_14sites.png

OPTIONAL TREND QA
  biological_honest_trends_14sites.png

This paired file set makes every step from annual biological counts to the
exact MARSS y matrix independently auditable.

================================================================================
END OF DEEP-PARSE ADDENDUM
================================================================================
