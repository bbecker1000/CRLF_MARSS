# Output Guide

The pipeline separates model-specific outputs from master comparison outputs.

## `marss_results/models/<Model_ID>/`

Each model receives its own directory.

### `fit.rds`
Final selected MARSS fit object. Large binary; normally exclude from Git and preserve in a separate analysis archive if needed.

### `fit_KEM_initial.rds`
Primary KEM fit object saved for reproducibility/debugging.

### `fit_BFGS_fallback.rds`
Saved only when BFGS fallback is attempted.

### `fit_summary.csv`
Small human-readable summary containing convergence, method, `K`, log likelihood, AIC/AICc, run ID, and related fields. Good candidate for Git if no sensitive information is embedded.

### `model_definition.csv`
Snapshot of the mathematical model definition used for compatibility/reuse checks.

### `fit_bootstrap_CIs.rds`
Completed MARSS parametric confidence-interval bootstrap object. Potentially large and expensive to reproduce; preserve outside ordinary Git history if necessary.

### `bootstrap_summary.csv`
Small summary of bootstrap status, requested/recorded replicates, seed, alpha, elapsed time, and run ID.

### `parameters.csv`
Standardized parameter estimates and bootstrap CIs after extraction.

### `parameters_C_climate.csv`
Climate-response coefficient subset. Empty for the null model by design.

### `parameter_QA.csv`
Count-based extraction QA versus expected `K` and expected climate parameter count.

### `diagnostics/`
Residual objects, residual inventory, fit diagnostics, and biological coverage summaries.

### `figures/`
Model-specific parameter plots and exact CSV data used to make them.

## `marss_results/master_tables/`

### `master_model_results.csv`
Broad combined registry + fit + selection dataset. Contains more technical columns than the presentation table.

### `master_model_selection.csv`
Primary model-level scientific reporting table. Contains model metadata, hypotheses, AIC/AICc, deltas, weights, convergence, and bootstrap status.

### `registered_models_not_yet_fit.csv`
Enabled/fittable registry rows that do not yet have a fit summary.

### `failed_models.csv`
Models with fit records that did not finish as `CONVERGED`.

A failed model should remain documented. Do not simply delete a failed model directory to make a candidate set look cleaner.

## `marss_results/plots/`

Contains candidate-set-level model-selection graphics such as ΔAICc plots and the exact data CSV used for each plot.

## `marss_results/logs/`

Registry-run logs containing model status and elapsed time. Usually transient; often excluded from Git.

## `marss_results/runs/<RUN_ID>/`

Full-pipeline reproducibility snapshots. Typical contents:

- `model_registry_used.csv`
- `site_registry_used.csv`
- `pipeline_settings_used.csv`
- `feature_catalog_used.csv`
- climate QA
- feature missingness QA
- biological QA
- `sessionInfo.txt`
- model run log
- model-selection snapshot
- pipeline run summary

These directories can accumulate quickly. Keep a locked release snapshot elsewhere if long-term preservation is required and avoid committing every routine rerun.

## Model-level versus parameter-level results

Do not put one generic “CI” column into the model-selection table. A site-specific climate model may have 14–42 separate climate coefficients, each with its own CI.

Use:

- model table for AIC/AICc and model metadata
- parameter table for coefficient estimates and CIs

## Suggested publication-facing outputs to retain in Git

If data permissions permit, lightweight outputs worth committing include:

- `master_model_selection.csv`
- selected summary tables
- model-selection PNG/PDF figures
- final parameter figures for inferential models
- small QA summaries

Do not commit large serialized fits merely for convenience.
