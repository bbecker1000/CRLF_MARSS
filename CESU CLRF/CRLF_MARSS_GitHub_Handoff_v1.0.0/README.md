# CRLF MARSS Population-Dynamics Pipeline

**Version:** 1.0.0 handoff baseline  
**Handoff date:** 2026-08-10  
**Primary entry point:** `00_run_full_pipeline.R`

This repository contains a registry-driven MARSS workflow for analyzing annual California Red-Legged Frog (CRLF) egg-mass dynamics across 14 monitoring ponds from 1997–2025. The pipeline was designed so that ecological hypotheses are defined in configuration tables rather than by copying and rewriting model-specific R scripts.

The main operating principle is simple:

```text
model_registry.csv
        ↓
scientific hypothesis
        ↓
build MARSS specification
        ↓
fit or resume saved fit
        ↓
diagnostics
        ↓
optional bootstrap inference
        ↓
parameter extraction / figures
        ↓
AIC / AICc comparison within candidate set
```

For an existing feature, adding a new ordinary model should normally mean adding a row to `config/model_registry.csv` and running the master script. A genuinely new predictor type may require extending feature construction first, but should still enter the MARSS workflow through the registry rather than through a separate one-off modeling script.

---

## 1. Scientific objective

The current analysis asks how hydroclimatic conditions represented by PDSI are associated with annual CRLF egg-mass dynamics at individual monitoring ponds. The candidate models examine contemporary early-season conditions, contemporary breeding-season conditions, recent multi-year climate memory, a separate three-year lag motivated by possible cohort/maturity timing, and seasonal interactions.

The biological response is annual egg-mass abundance transformed as:

```text
log(annual egg-mass abundance + 1)
```

Surveyed years with zero egg masses remain true zeros. Years without biological survey coverage remain `NA`; they are not converted to zero.

The current modeled biological matrix contains:

- 14 monitoring sites
- 29 biological years, 1997–2025
- 406 possible site-years
- 273 observed site-years
- 133 missing site-years

The 14 sites are:

- Laguna Salada: LS01, LS04, LS05, LS06, LS07, LS08, LS11
- Milagra Creek: MC01
- Redwood Creek: RC07, RC10, RC11
- Rodeo Lagoon: RL02
- Tennessee Valley: TV02
- Wilkins Gulch: WG01

See [`docs/DATA_DICTIONARY.md`](docs/DATA_DICTIONARY.md) for detailed field definitions.

---

## 2. Quick start

From a clean R session:

```r
setwd("F:/CRLF_MARSS")
source("00_run_full_pipeline.R")
```

The master script loads all modules, validates the inputs, reconstructs features, runs or resumes registered models, updates diagnostics and master tables, makes supported figures, and writes a reproducibility snapshot.

Existing compatible fits are reused by default. Existing completed bootstrap objects are also reused. Expensive models are not automatically refit merely because the master pipeline is rerun.

For the shortest handoff instructions, see [`QUICK_START.md`](QUICK_START.md).

---

## 3. Repository architecture

The active project should remain approximately:

```text
CRLF_MARSS/
│
├── README.md
├── QUICK_START.md
├── CHANGELOG.md
├── .gitignore
├── 00_run_full_pipeline.R
│
├── config/
│   ├── model_registry.csv
│   ├── site_registry.csv
│   ├── pipeline_settings.csv
│   └── archive/
│
├── R/
│   ├── 01_load_inputs.R
│   ├── 02_validate_inputs.R
│   ├── 03_build_features.R
│   ├── 04_build_model_spec.R
│   ├── 05_fit_model.R
│   ├── 06_bootstrap_model.R
│   ├── 07_extract_results.R
│   ├── 08_model_diagnostics.R
│   ├── 09_model_selection.R
│   ├── 10_make_figures.R
│   └── 11_run_registry.R
│
├── docs/
│   ├── METHODS_AND_JUSTIFICATIONS.md
│   ├── MODEL_REGISTRY_GUIDE.md
│   ├── DATA_DICTIONARY.md
│   ├── OUTPUT_GUIDE.md
│   ├── TROUBLESHOOTING.md
│   ├── HANDOFF_CHECKLIST.md
│   └── RELEASE_DECISIONS.md
│
├── tools/
│   └── 99_github_preflight.R
│
├── marss_results/
│   ├── biological/
│   ├── covariates/
│   ├── models/
│   ├── master_tables/
│   ├── plots/
│   ├── diagnostics/
│   ├── logs/
│   └── runs/
│
└── archive/
    └── baseline/
        ├── MARSS_BASELINE_CORRECT_LOCKED.R
        └── README_BASELINE.md
```

Do not reorganize live input/output paths casually. Several paths are deliberately stored in `config/pipeline_settings.csv`; changing the directory layout without updating configuration can break reproducibility.

---

## 4. Module-by-module workflow

### `01_load_inputs.R` — load configuration and data

Loads pipeline settings, site registry, model registry, biological response matrix, and climate master data. This module centralizes path handling so downstream code does not need hard-coded data-loading logic.

### `02_validate_inputs.R` — fail early on bad inputs

Validates site identities, biological dimensions and years, climate region/year coverage, duplicate region-years, missing base climate values, and registry structure. The purpose is to stop the analysis before model fitting if the underlying data structure is inconsistent.

### `03_build_features.R` — construct reusable climate features

Feature engineering is performed on the full historical climate record before filtering to the 1997–2025 biological window. This is essential because lagged and running-mean values for early biological years require pre-1997 climate history.

The current feature catalog includes:

- `PDSI_OctDec`
- `PDSI_JanMar`
- `PDSI_OctDec_RunMean1`
- `PDSI_OctDec_RunMean2`
- `PDSI_OctDec_RunMean3`
- `PDSI_OctDec_lag3`
- `PDSI_JanMar_RunMean1`
- `PDSI_JanMar_RunMean2`
- `PDSI_JanMar_RunMean3`
- `PDSI_JanMar_lag3`
- `PDSI_Interact`
- `PDSI_Interact_lag3`

### `04_build_model_spec.R` — translate registry rows into MARSS

Reads the requested covariates and model structure from a registry row, constructs the MARSS `c` matrix, builds the site-specific `C` matrix, and audits the number and uniqueness of free climate parameters.

For current site-specific climate models, each requested climate feature contributes 14 free `C` parameters: one response coefficient per biological site.

### `05_fit_model.R` — fit and convergence handling

Fits the registered MARSS model. The primary optimizer is KEM. Incomplete KEM convergence can trigger a BFGS fallback initialized from the KEM parameter estimates. Final fits, fit summaries, and model definitions are written into a model-specific output directory.

### `06_bootstrap_model.R` — optional parametric confidence intervals

Runs `MARSSparamCIs(..., method = "parametric")` only for models intentionally selected for uncertainty inference. Bootstrapping is expensive and is therefore separated from candidate screening.

The CI bootstrap is **not** bootstrap AIC and is **not** `AICbp`.

### `07_extract_results.R` — standardize parameters

Converts MARSS parameter output into readable tables with parameter type, site, watershed, covariate, estimate, lower CI, upper CI, and whether the CI excludes zero. Parameter-level CIs belong in the parameter table, not in a single model-level `CI` column.

### `08_model_diagnostics.R` — diagnostics and coverage

Saves MARSS residual objects, a residual inventory, fit diagnostics, and observation-coverage summaries.

### `09_model_selection.R` — candidate-set comparison

Combines the registry metadata with all available fit and bootstrap summaries. AIC, AICc, deltas, weights, and rankings are calculated **within `Candidate_Set` only**.

This prevents primary models, legacy sensitivity analyses, and future alternative parameterizations from being mixed into one meaningless weight calculation.

### `10_make_figures.R` — standardized figures

Produces site-level parameter figures after bootstrap CIs exist and candidate-set AICc comparison figures once at least two converged models are available in a candidate set.

### `11_run_registry.R` — workflow manager

Loops over requested registry rows and coordinates modules 04–10. Existing compatible fits are reused. Existing completed bootstraps are reused. The model-selection table is rebuilt at the end of a suite run.

### `00_run_full_pipeline.R` — master entry point

The intended user-facing entry point. It loads modules, inputs, validation, features, run snapshots, registered models, model selection, and reproducibility metadata.

---

## 5. MARSS architecture

The currently intended state-space structure is:

```r
list(
  Z = "identity",
  R = "zero",
  B = "identity",
  U = "unequal",
  Q = "diagonal and unequal",
  C = C_dynamic,
  c = covariate_matrix
)
```

The null model omits `C` and `c` entirely.

### Parameter interpretation

- `B = identity`: no estimated cross-site autoregressive coupling in the current baseline architecture.
- `U = unequal`: each site receives its own process drift/growth parameter.
- `Q = diagonal and unequal`: each site has its own process variance; contemporaneous process covariance among sites is not estimated in this structure.
- `R = zero`: observation error is fixed to zero in the current baseline, placing stochastic variation in the process component. This is a strong modeling assumption and should be documented and potentially sensitivity-tested in later work.
- `C`: climate-response coefficients.
- `c`: climate covariate time series supplied to the state process.

See [`docs/METHODS_AND_JUSTIFICATIONS.md`](docs/METHODS_AND_JUSTIFICATIONS.md) before modifying this structure.

---

## 6. Why climate exposure is watershed-level but `C` is site-specific

The climate series are associated with watersheds, but the biological populations are modeled at individual monitoring ponds. Ponds in the same watershed therefore share the relevant PDSI exposure time series while estimating independent response coefficients.

For example, LS01 and LS04 both use the Laguna Salada PDSI series, but their climate coefficients are distinct parameters such as:

```text
C_LS01_PDSI_JanMar
C_LS04_PDSI_JanMar
```

This design asks whether individual ponds respond differently to a shared watershed-scale climate history. Replacing these with one coefficient per watershed would answer a different scientific question and should not be treated as a harmless code simplification.

Parameter-count consequences under the current architecture are:

```text
Null model:                 42 total parameters
1 climate feature:         +14 C parameters → K = 56
2 climate features:        +28 C parameters → K = 70
3 climate features:        +42 C parameters → K = 84
```

These high-dimensional climate formulations are one reason AICc is especially important in this study.

---

## 7. Climate windows and temporal hypotheses

### Oct–Dec: early / antecedent conditions

Oct–Dec PDSI is used as an early-season or antecedent hydrologic window. It is intended to represent conditions associated with pond filling before the principal Jan–Mar breeding period.

### Jan–Mar: late / breeding-season conditions

Jan–Mar PDSI represents conditions during the principal breeding-season window used in the current analysis.

### Recent three-year mean

`RunMean3` is defined as:

```text
mean(t, t-1, t-2)
```

For biological year 2025, this corresponds to the mean of 2025, 2024, and 2023 values for the specified seasonal window.

### Separate `t-3`

The `lag3` feature is deliberately separate from the three-year running mean. For 2025, `t-3` corresponds to 2022. Models such as:

```text
RunMean3 + lag3
```

therefore represent:

```text
mean(2025, 2024, 2023) + 2022
```

The separate lag was motivated by the ecological hypothesis that conditions experienced by an earlier cohort may be relevant approximately three years later when individuals could contribute to the breeding population. This is a hypothesis to be tested, not an assumption that sexual maturity occurs at one exact age for every individual.

### Interaction models

When the early × late interaction is fitted, both seasonal main effects are retained with the interaction. The interaction is not interpreted in isolation.

---

## 8. Model registry: the scientific interface

`config/model_registry.csv` is the primary interface for defining candidate models. A model should not require a new copy-pasted fitting script merely because a different existing feature or feature combination is being tested.

Important registry columns include:

- `Model_Number`
- `Model_ID`
- `Model_Name`
- `Scientific_Question`
- `Hypothesis`
- `Biological_Interpretation`
- `Candidate_Set`
- `Comparison_Role`
- `Covariates`
- `Season_Focus`
- `Climate_Window`
- `Time_Structure`
- `Lag_Structure`
- `C_Structure`
- `Expected_C_Parameters`
- `Expected_Total_K`
- `Fit_Model`
- `Run_Bootstrap`
- `Primary_Analysis`

See [`docs/MODEL_REGISTRY_GUIDE.md`](docs/MODEL_REGISTRY_GUIDE.md) before adding or editing models.

A structural scientific change should generally receive a new `Model_ID`. Do not reuse an old identifier for a different mathematical model simply to keep numbering convenient.

---

## 9. Current candidate-set organization

The handoff version contains two conceptually separate groups.

### `PDSI_PRIMARY_HYPOTHESES_V1`

The primary candidate set contains the null plus contemporary, climate-memory, lagged, and interaction hypotheses. These models are intended to be compared against each other because they use the same response, biological time support, and baseline likelihood structure.

Current primary model numbers are P0–P9:

- P0 — Just Egg-Mass Abundance / null
- P1 — Early Oct–Dec Contemporary Year
- P2 — Late Jan–Mar Contemporary Year
- P3 — Early Oct–Dec Contemporary + t-3 Lag
- P4 — Late Jan–Mar Contemporary + t-3 Lag
- P5 — Early × Late Contemporary
- P6 — Early Running 3-Year Mean
- P7 — Late Running 3-Year Mean
- P8 — Early Recent 3-Year Mean + t-3 Lag
- P9 — Late Recent 3-Year Mean + t-3 Lag

### `PDSI_EXPLORATORY_LEGACY_V1`

Contains retained exploratory/legacy formulations, including the earlier two-year running-mean and fully lagged seasonal-interaction models. Their AIC/AICc weights are calculated within their own candidate set and should not be combined with the primary weights as though all rows belonged to one pre-specified model set.

---

## 10. Current analysis status at handoff

At the handoff baseline:

- 12 models are registered.
- 12 fit summaries exist.
- 12 models converged.
- No model was missing a fit.
- No model was recorded as a failed/error fit.
- M0/P0 has a completed 500-replicate parametric CI bootstrap.
- Other candidate models were initially screened without automatically launching expensive CI bootstraps.

Within `PDSI_PRIMARY_HYPOTHESES_V1`, the current AICc ranking begins:

1. P0 — null / Just Egg-Mass Abundance
2. P2 — Late Jan–Mar Contemporary Year
3. P6 — Early Running 3-Year Mean
4. P7 — Late Running 3-Year Mean
5. P1 — Early Oct–Dec Contemporary Year

The exact, authoritative model-selection values should always be read from:

```text
marss_results/master_tables/master_model_selection.csv
```

At the current snapshot, P0 receives most AICc weight, while P2 is the strongest climate formulation. Importantly, this does **not** mean that PDSI has been proven biologically irrelevant. Several climate models improve raw likelihood substantially, but site-specific climate responses introduce many additional parameters and therefore receive a strong small-sample complexity penalty under AICc.

Do not report “PDSI has no effect” solely from the null model receiving the best AICc. The supported statement is narrower: under the current candidate set and site-specific parameterization, the added climate formulations do not improve expected fit enough to overcome their added complexity according to AICc.

---

## 11. AIC, AICc, and inference

Model selection and parameter inference are deliberately separated.

### Model-level table

`master_model_selection.csv` contains model-level quantities such as:

- model identity and hypothesis
- parameter count `K`
- log likelihood
- AIC
- AICc
- ΔAIC / ΔAICc
- Akaike weights
- bootstrap status

### Parameter-level table

A fitted climate model can contain 14, 28, or 42 site-specific climate coefficients. Each coefficient has its own estimate and CI. It is therefore incorrect to store a model's uncertainty as one generic `CI` field.

Bootstrap-derived parameter uncertainty belongs in per-model `parameters.csv` files and, when compiled, a master parameter table containing fields such as:

```text
Model_ID
Model_Name
Site_ID
Watershed
Parameter_Type
Covariate
Estimate
Lower_95
Upper_95
CI_Excludes_Zero
N_Boot
```

---

## 12. Resume and reproducibility behavior

The registry runner was designed to be restartable.

For each model it checks whether a compatible saved fit exists. If so, that fit is reused rather than refit. It also checks for a completed bootstrap and reuses it when compatible.

This allows a clean-session master run to rebuild lightweight diagnostics, tables, and figures without repeating hours of completed fitting/bootstrap work.

The master pipeline writes run-level reproducibility information under:

```text
marss_results/runs/<RUN_ID>/
```

including configuration snapshots, QA tables, run logs, and `sessionInfo()`.

Before a formal release, perform the clean-session test described in [`docs/HANDOFF_CHECKLIST.md`](docs/HANDOFF_CHECKLIST.md).

---

## 13. Adding a new model using an existing feature

1. Open `config/model_registry.csv`.
2. Give the model a new permanent `Model_ID` and human-readable `Model_Number`/`Model_Name`.
3. State the scientific question and hypothesis in plain language.
4. Enter one or more existing feature names in `Covariates`, separated by `|`.
5. Set the appropriate `Candidate_Set`.
6. Set `C_Structure = site_specific` for the current site-specific hypothesis framework.
7. Set expected climate parameter count and total `K` for QA.
8. Leave `Run_Bootstrap = FALSE` during initial candidate screening unless there is a specific reason to run inference immediately.
9. Run:

```r
source("00_run_full_pipeline.R")
```

10. Inspect convergence and the updated master model-selection table.

Detailed examples are in [`docs/MODEL_REGISTRY_GUIDE.md`](docs/MODEL_REGISTRY_GUIDE.md).

---

## 14. Adding a genuinely new predictor type

Examples might include site hydrology or landscape connectivity.

Do **not** create an entirely separate MARSS pipeline. Instead:

1. Define the new predictor and its scientific scale.
2. Add reproducible feature construction and QA.
3. Ensure its year/site/watershed dimensions can be mapped into the generic MARSS `c`/`C` architecture.
4. Add registry metadata describing the feature.
5. Add model rows that request the new feature.
6. Extend `04_build_model_spec.R` only if the new predictor's spatial structure requires a new mapping strategy.

The current feature builder is watershed-climate oriented. A future site-year connectivity predictor may require explicit support for a `Spatial_Scale = site` feature class rather than being forced into a watershed matrix.

---

## 15. Files suitable for GitHub

Normally commit:

- all R source files
- `00_run_full_pipeline.R`
- configuration CSV files
- documentation
- `.gitignore`
- small master model-selection tables
- selected lightweight figures
- optional small run-summary files

Normally do **not** commit large regenerable objects such as:

- `fit.rds`
- `fit_KEM_initial.rds`
- `fit_BFGS_fallback.rds`
- `fit_bootstrap_CIs.rds`
- large residual RDS objects
- repeated run/log directories

Do not publish raw or restricted biological data until data-sharing permissions have been confirmed. See [`docs/RELEASE_DECISIONS.md`](docs/RELEASE_DECISIONS.md).

---

## 16. Important assumptions and limitations

1. **Observation error is fixed at zero (`R = zero`).** This is a strong assumption.
2. **Climate response is site-specific.** This creates high-dimensional models relative to 273 observed site-years.
3. **PDSI exposure is watershed-level.** Site-specific coefficients do not make the climate input itself pond-specific.
4. **AICc support is not causal proof.** These are observational models.
5. **A null-model win does not prove zero biological effect.** It indicates that added parameterized formulations are not supported enough to offset complexity under the selected criterion.
6. **Candidate-set design matters.** Akaike weights only have meaning relative to the models included in a coherent candidate set.
7. **Lag hypotheses are ecological hypotheses, not established life-history constants.**
8. **Historical feature construction must precede biological-year filtering.** Otherwise early lagged values can be fabricated or lost.
9. **Missing biological surveys are `NA`, not zero.**
10. **Parametric CI bootstrap and bootstrap AIC are different procedures.**

---

## 17. Documentation map

- [`QUICK_START.md`](QUICK_START.md) — shortest instructions for running the project
- [`docs/METHODS_AND_JUSTIFICATIONS.md`](docs/METHODS_AND_JUSTIFICATIONS.md) — scientific and modeling rationale
- [`docs/MODEL_REGISTRY_GUIDE.md`](docs/MODEL_REGISTRY_GUIDE.md) — how to define and add hypotheses
- [`docs/DATA_DICTIONARY.md`](docs/DATA_DICTIONARY.md) — inputs and feature definitions
- [`docs/OUTPUT_GUIDE.md`](docs/OUTPUT_GUIDE.md) — output files and directories
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) — common errors and recovery
- [`docs/HANDOFF_CHECKLIST.md`](docs/HANDOFF_CHECKLIST.md) — release/handoff verification
- [`docs/RELEASE_DECISIONS.md`](docs/RELEASE_DECISIONS.md) — items that require a human decision before public release
- [`docs/GITHUB_UPLOAD_STEPS.md`](docs/GITHUB_UPLOAD_STEPS.md) — safe staging, commit, push, and tagging workflow
- [`CHANGELOG.md`](CHANGELOG.md) — version history

---

## 18. Final handoff principle

The pipeline is intentionally structured so that scientific hypotheses are explicit, auditable, and reproducible. Future work should preserve that separation:

```text
DATA / FEATURE ENGINEERING
        ↓
MODEL REGISTRY = scientific hypotheses
        ↓
GENERIC MODEL BUILDER
        ↓
GENERIC FIT / DIAGNOSTIC / SELECTION PIPELINE
```

Avoid returning to one-off model scripts unless a genuinely different modeling framework is being developed. If a result cannot be reproduced from configuration plus the master pipeline, it should not be treated as part of the locked v1.0 workflow.
