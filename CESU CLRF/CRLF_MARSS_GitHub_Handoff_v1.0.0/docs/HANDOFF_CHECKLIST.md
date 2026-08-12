# Handoff / GitHub Release Checklist

Use this checklist before calling a version of the CRLF MARSS repository handoff-ready.

## A. Freeze the science

- [ ] `config/model_registry.csv` contains the intended primary and exploratory models.
- [ ] Every primary model has a clear `Scientific_Question` and `Hypothesis`.
- [ ] Candidate sets are intentional and documented.
- [ ] Structural assumptions (`B`, `Q`, `R`, `C`) are documented.
- [ ] No model identifier has been silently reused for a different mathematical model.

## B. Input QA

- [ ] Site registry contains the intended 14 active sites.
- [ ] Biological matrix is 14 × 29 for 1997–2025.
- [ ] Surveyed zero versus unsurveyed `NA` convention is documented.
- [ ] Climate history is sufficient for lags/running means.
- [ ] Feature missingness QA passes for the modeled window.
- [ ] Source-data sharing permissions have been reviewed.

## C. Clean-session reproducibility test

Close R completely. Open a fresh session and run only:

```r
setwd("F:/CRLF_MARSS")
source("00_run_full_pipeline.R")
```

Confirm:

- [ ] all modules load
- [ ] input validation passes
- [ ] feature QA passes
- [ ] completed compatible fits are reused
- [ ] completed bootstrap objects are reused
- [ ] diagnostics run
- [ ] master tables rebuild
- [ ] candidate-set figures rebuild
- [ ] pipeline finishes with zero errors

Record the final run ID here:

```text
FINAL RELEASE RUN ID: ______________________________
```

## D. Model-output checks

- [ ] `master_model_selection.csv` exists.
- [ ] Expected number of registered models is present.
- [ ] All intended release models are `CONVERGED` or failures are explicitly documented.
- [ ] Expected `K` agrees with actual `K`.
- [ ] Null model contains zero `C` parameters.
- [ ] One-feature site-specific models contain 14 `C` parameters.
- [ ] Two-feature site-specific models contain 28 `C` parameters.
- [ ] Three-feature site-specific models contain 42 `C` parameters.
- [ ] Rankings/weights are within candidate set.

## E. Documentation

- [ ] `README.md` reviewed.
- [ ] `QUICK_START.md` reviewed.
- [ ] `METHODS_AND_JUSTIFICATIONS.md` reviewed.
- [ ] `MODEL_REGISTRY_GUIDE.md` reviewed.
- [ ] `DATA_DICTIONARY.md` reviewed.
- [ ] `OUTPUT_GUIDE.md` reviewed.
- [ ] `TROUBLESHOOTING.md` reviewed.
- [ ] `CHANGELOG.md` updated.
- [ ] archived baseline is labeled as historical/locked.

## F. GitHub preflight

Run:

```r
source("tools/99_github_preflight.R")
```

Then confirm:

- [ ] no unexpected files >25 MB are intended for Git.
- [ ] no fit/bootstrap RDS files are staged.
- [ ] no private/restricted raw data are staged.
- [ ] no credentials, tokens, or `.env` files are staged.
- [ ] `.gitignore` is present.
- [ ] `git status` contains only intended files.

## G. Public-release decisions

Resolve `RELEASE_DECISIONS.md`:

- [ ] repository name
- [ ] public/private visibility
- [ ] license
- [ ] authors/contributors
- [ ] citation format
- [ ] data availability statement
- [ ] whether selected outputs/figures can be public
- [ ] whether a large-object archive/release will be provided

## H. Version lock

- [ ] Set version to `1.0.0` in project documentation/settings if appropriate.
- [ ] Create a Git tag such as `v1.0.0` after final verification.
- [ ] Preserve the exact release commit hash in project records.
- [ ] Do not modify the archived release copy; future changes belong in a new version.
