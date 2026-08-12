# CRLF MARSS Pipeline — Quick Start

This file is intentionally short. Read `README.md` and `docs/METHODS_AND_JUSTIFICATIONS.md` before modifying the science or model structure.

## Run the complete pipeline

Start a clean R session and run:

```r
setwd("F:/CRLF_MARSS")
source("00_run_full_pipeline.R")
```

A normal rerun should reuse compatible saved fits and completed bootstrap objects rather than recomputing them.

## The main files a user should edit

### `config/model_registry.csv`
Defines scientific hypotheses and controls which models are fit or bootstrapped.

### `config/site_registry.csv`
Defines the active sites and watershed mapping.

### `config/pipeline_settings.csv`
Defines global paths, years, optimizer limits, bootstrap defaults, seed, and baseline MARSS structures.

Do not edit numbered R modules simply to test a new combination of features that already exists in the feature catalog.

## Add a model

1. Add one row to `config/model_registry.csv`.
2. Use a new permanent `Model_ID`.
3. List requested covariates separated by `|`.
4. Put the model in the correct `Candidate_Set`.
5. Use `Run_Bootstrap = FALSE` for initial screening unless parameter CIs are immediately required.
6. Run the master pipeline.
7. Check `marss_results/master_tables/master_model_selection.csv`.

## Key outputs

```text
marss_results/master_tables/master_model_selection.csv
marss_results/master_tables/master_model_results.csv
marss_results/plots/
marss_results/models/<Model_ID>/fit_summary.csv
marss_results/models/<Model_ID>/diagnostics/
```

After a bootstrap:

```text
marss_results/models/<Model_ID>/bootstrap_summary.csv
marss_results/models/<Model_ID>/parameters.csv
marss_results/models/<Model_ID>/figures/
```

## Before GitHub/public release

Run:

```r
source("tools/99_github_preflight.R")
```

Then follow `docs/HANDOFF_CHECKLIST.md` and resolve all items in `docs/RELEASE_DECISIONS.md`.
