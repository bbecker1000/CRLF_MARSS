================================================================================
CRLF MARSS POPULATION-DYNAMICS PIPELINE
USER MANUAL / HANDOFF GUIDE
Version 1.0.0
Handoff baseline: 2026-08-10
================================================================================

PURPOSE
-------
This document is the plain-text user manual for the California Red-Legged Frog
(CRLF) MARSS population-dynamics workflow. It is intended for a future student,
analyst, collaborator, or PI who needs to understand:

  1. what the important files contain;
  2. what the important variables mean;
  3. how raw monitoring data became the MARSS response matrix;
  4. how PDSI was converted into climate covariates;
  5. why the C-matrix is constructed the way it is;
  6. how the model registry controls hypotheses;
  7. how model fitting, diagnostics, bootstrapping, and model selection work;
  8. which scientific choices must NOT be changed casually.

This manual treats the CURRENT v1.0 pipeline as authoritative. Older scripts and
tables are retained as provenance, but they should not override the current
registry-driven, 14-site, site-specific-C workflow.


================================================================================
1. CURRENT AUTHORITATIVE ANALYSIS STATE
================================================================================

Biological response:
  Annual CRLF egg-mass abundance transformed as log(count + 1).

Biological horizon:
  1997-2025 inclusive = 29 biological years.

Current modeled sites:
  14 monitoring ponds.

Current response matrix:
  14 sites x 29 years = 406 possible site-years.

Observed / missing coverage in the locked v1.0 model matrix:
  Observed site-years = 273
  Missing site-years  = 133

Current modeled watersheds:
  LAGUNA_SALADA
  MILAGRA_CREEK
  REDWOOD_CREEK
  RODEO_LAGOON
  TENNESSEE_VALLEY
  WILKINS_GULCH

Current modeled sites:
  Laguna Salada:
    LS01, LS04, LS05, LS06, LS07, LS08, LS11

  Milagra Creek:
    MC01

  Redwood Creek:
    RC07, RC10, RC11

  Rodeo Lagoon:
    RL02

  Tennessee Valley:
    TV02

  Wilkins Gulch:
    WG01

Current model registry:
  12 registered models total:
    - 10 primary PDSI hypotheses
    - 2 exploratory / legacy hypotheses

Clean-session validation:
  12/12 registered models recognized as converged.
  0 pipeline errors.
  Model selection and figures rebuild from saved fits.
  Existing compatible fits are reused automatically.
  Existing completed bootstraps are reused automatically.


================================================================================
2. ONE-COMMAND WORKFLOW
================================================================================

From the project root:

  setwd("F:/CRLF_MARSS")
  source("00_run_full_pipeline.R")

The master script performs the following:

  LOAD
    |
    v
  VALIDATE INPUTS
    |
    v
  BUILD FEATURES
    |
    v
  READ MODEL REGISTRY
    |
    v
  BUILD MARSS SPECIFICATION
    |
    v
  REUSE COMPATIBLE FIT OR FIT MODEL
    |
    v
  DIAGNOSTICS
    |
    v
  OPTIONAL BOOTSTRAP
    |
    v
  PARAMETER EXTRACTION
    |
    v
  FIGURES
    |
    v
  AIC / AICc MODEL SELECTION
    |
    v
  REPRODUCIBILITY SNAPSHOT


================================================================================
3. ACTIVE R MODULES
================================================================================

00_run_full_pipeline.R
  User-facing master entry point. Loads all modules, inputs, validation,
  features, model registry, model suite, selection tables, figures, and
  reproducibility metadata.

R/01_load_inputs.R
  Loads settings, site registry, model registry, biological matrix, and
  climate master data.

R/02_validate_inputs.R
  Checks site identities, year structure, climate coverage, duplicates,
  missing values, registry consistency, and input dimensions.

R/03_build_features.R
  Constructs PDSI features on the FULL historical climate series before
  filtering to 1997-2025.

R/04_build_model_spec.R
  Converts a registry row into MARSS model matrices. Builds c and site-specific
  C and performs hard audits of free climate parameters.

R/05_fit_model.R
  Fits registered models. Uses KEM first and BFGS fallback for incomplete KEM
  convergence categories. Saves fit objects and summaries.

R/06_bootstrap_model.R
  Runs parametric confidence-interval bootstraps only for models explicitly
  selected for bootstrap inference.

R/07_extract_results.R
  Converts MARSS parameter output into readable parameter tables with site,
  watershed, covariate, estimate, confidence interval, and CI-zero status.

R/08_model_diagnostics.R
  Saves MARSS residuals, residual inventory, fit diagnostics, and observation
  coverage.

R/09_model_selection.R
  Joins scientific metadata to fit summaries and computes AIC/AICc rankings,
  deltas, and weights WITHIN Candidate_Set only.

R/10_make_figures.R
  Creates site-level parameter figures when bootstrap CIs exist and
  candidate-set Delta-AICc figures.

R/11_run_registry.R
  Workflow manager. Loops across enabled registry rows, reuses completed
  compatible work, and coordinates modules 04-10.


================================================================================
4. CORE SCIENTIFIC DECISIONS
================================================================================

4.1 TRUE ZERO VS MISSING SURVEY
-------------------------------
A confirmed survey in which zero egg masses were detected is a biological zero.

  surveyed + no egg masses -> 0

A year with no adequate biological survey is missing information.

  not surveyed -> NA

These two states must NEVER be merged.

Why:
  Converting an unsurveyed year to zero falsely creates a local biological
  failure. MARSS can retain NA observations and estimate latent state through
  the state-space framework without pretending an observation occurred.


4.2 LOG TRANSFORMATION
----------------------
The response supplied to MARSS is:

  y(i,t) = log(egg_mass_count(i,t) + 1)

Why +1:
  Allows true zeros to remain defined.

Why log:
  Compresses extreme count differences and makes the response more compatible
  with a Gaussian state-space representation. It does not make every modeling
  assumption automatically true; diagnostics and sensitivity analyses remain
  important.


4.3 EARLY CLIMATE WINDOW: OCT-DEC
---------------------------------
PDSI_OctDec represents antecedent / early-season climate.

Ecological intent:
  Conditions in October-December can represent moisture conditions associated
  with pond filling and hydrologic setup before the principal breeding period.


4.4 LATE CLIMATE WINDOW: JAN-MAR
--------------------------------
PDSI_JanMar represents the principal breeding-season climate window used in the
current analysis.

Ecological intent:
  Test whether moisture conditions closer to egg laying / breeding are more
  informative than antecedent early-season conditions.


4.5 THREE-YEAR RUNNING MEAN
---------------------------
RunMean3 is:

  mean(t, t-1, t-2)

Example for biological year 2025:

  mean(2025, 2024, 2023)

It does NOT include t-3.


4.6 SEPARATE t-3 FEATURE
------------------------
lag3 is the climate value at:

  t-3

For 2025:

  t-3 = 2022

A model containing:

  RunMean3 + lag3

therefore means:

  mean(2025, 2024, 2023) + 2022

Why:
  This separates recent cumulative climate from a distinct earlier cohort /
  maturity hypothesis. The lag is a testable ecological hypothesis, not a
  declaration that all frogs mature at one exact age.


4.7 INTERACTION MODELS
----------------------
When the Early x Late interaction is fitted, the two main effects remain in
the model:

  Early + Late + Early*Late

Do not fit or interpret the interaction in isolation under the current
hierarchical model definition.


================================================================================
5. MARSS MODEL ARCHITECTURE
================================================================================

Current state model:

  Z = "identity"
  B = "identity"
  U = "unequal"
  Q = "diagonal and unequal"
  R = "zero"

Climate models additionally include:

  C = site-specific response matrix
  c = watershed climate covariate matrix

Null model:
  C and c are omitted entirely.


PARAMETER MEANINGS
------------------
Z
  Observation mapping. Identity means each observed biological series maps
  directly to its corresponding latent state.

B
  State-transition structure. Identity in the current architecture.

U
  Site-specific state drift / population growth term.
  "unequal" means each modeled pond receives its own U parameter.

Q
  Process variance.
  "diagonal and unequal" means each pond has its own process variance while
  contemporaneous off-diagonal process covariances are not estimated.

R
  Observation-error variance.
  Fixed to zero in v1.0.

IMPORTANT:
  R = zero is a strong modeling assumption. It is part of the locked baseline
  and should be documented and sensitivity-tested before being changed.

x0
  Site-specific initial latent state estimates.

C
  Climate-response coefficients.

c
  Climate covariate time series supplied to the state process.


================================================================================
6. SITE-SPECIFIC C-MATRIX: WHAT IT DOES AND WHY
================================================================================

Climate exposure is represented at watershed scale, but biological populations
are modeled at individual ponds.

Therefore:

  Ponds in the same watershed share the same climate time series,

BUT:

  each pond estimates a different climate-response coefficient.

Example:

  LS01 and LS04 both use the Laguna Salada Jan-Mar PDSI series.

Their response coefficients are distinct:

  C_LS01_PDSI_JanMar
  C_LS04_PDSI_JanMar

This is deliberate.

A single coefficient shared by all Laguna Salada ponds would answer a DIFFERENT
scientific question.


C AND c DIMENSIONS
------------------

Let F = number of requested climate features.
Let W = 6 active modeled watersheds.
Let S = 14 active modeled sites.
Let T = 29 biological years.

Then:

  c dimensions = (W * F) x T
  C dimensions = S x (W * F)

Only the cells connecting a site to its own watershed are estimated.
Off-watershed cells are fixed numeric zero.

Free site-specific C parameters:

  F = 0 ->  0 free C -> total K = 42
  F = 1 -> 14 free C -> total K = 56
  F = 2 -> 28 free C -> total K = 70
  F = 3 -> 42 free C -> total K = 84

This parameter count is a major reason AICc is emphasized: site-specific climate
models can improve likelihood while still being penalized strongly for added
complexity.


================================================================================
7. MODEL SELECTION
================================================================================

Model-level quantities:
  LogLik
  K
  AIC
  AICc
  Delta_AIC
  Delta_AICc
  Weight_AIC
  Weight_AICc

AIC/AICc values are model-level quantities.

Confidence intervals are parameter-level quantities.

Do NOT place one ambiguous "CI" value in a model-level table for a model with
14, 28, or 42 climate coefficients. Store individual CIs in the parameter table.

Akaike weights are meaningful only WITHIN a coherent Candidate_Set.

Current candidate sets:

  PDSI_PRIMARY_HYPOTHESES_V1
  PDSI_EXPLORATORY_LEGACY_V1

Do not combine their weights into one global interpretation.


================================================================================
8. BOOTSTRAP INFERENCE
================================================================================

Current CI procedure:
  MARSSparamCIs(..., method = "parametric")

Purpose:
  Generate parameter uncertainty intervals for selected models.

Important:
  Parameter CI bootstrap is NOT the same as bootstrap AIC / AICbp.

The pipeline intentionally separates:
  candidate screening -> AIC/AICc

from:
  expensive parameter inference -> bootstrap CI

This prevents spending hours bootstrapping clearly noncompetitive candidate
models.


================================================================================
9. HOW TO ADD A NEW MODEL
================================================================================

If the requested feature already exists:

  1. Open config/model_registry.csv.
  2. Assign a NEW permanent Model_ID.
  3. Add a human-readable Model_Number and Model_Name.
  4. Write the scientific question.
  5. Write the hypothesis.
  6. Record the biological interpretation.
  7. Add feature names in Covariates separated by "|".
  8. Assign the correct Candidate_Set.
  9. Use C_Structure = site_specific under the current hypothesis framework.
 10. Record Expected_C_Parameters and Expected_Total_K.
 11. Leave Run_Bootstrap = FALSE during initial screening unless intentional.
 12. Run source("00_run_full_pipeline.R").
 13. Inspect convergence, QA, AICc, and master tables.

Never reuse an old Model_ID for a mathematically different model.


================================================================================
10. HOW TO ADD A NEW TYPE OF PREDICTOR
================================================================================

Examples:
  staff-plate hydrology
  landscape connectivity

Do not build a separate MARSS pipeline.

Instead:

  1. define the variable;
  2. document its units and spatial scale;
  3. construct the feature reproducibly;
  4. QA its site/year coverage;
  5. register the feature;
  6. extend model-spec mapping only if its spatial structure requires it;
  7. define hypotheses in model_registry.csv;
  8. use the same generic fit/diagnostic/selection machinery.

The current feature builder is watershed-climate oriented. Site-year
connectivity will likely need an explicit site-scale feature mapping rather
than being forced into a watershed representation.


================================================================================
11. PRIMARY HANDOFF RULE
================================================================================

Scientific hypotheses belong in configuration and documented feature logic.

Avoid returning to:
  M17_script.R
  M18_script.R
  M19_script.R

The intended pattern is:

  DATA / FEATURE ENGINEERING
          |
          v
  MODEL REGISTRY = SCIENTIFIC HYPOTHESES
          |
          v
  GENERIC MODEL BUILDER
          |
          v
  GENERIC FIT / DIAGNOSTIC / MODEL-SELECTION PIPELINE

If a result cannot be reproduced from the documented inputs + configuration +
master pipeline, it should not be considered part of the locked v1.0 workflow.
