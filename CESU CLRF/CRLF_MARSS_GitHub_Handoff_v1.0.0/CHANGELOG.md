# Changelog

All notable changes to the CRLF MARSS pipeline should be documented here.

## [1.0.0] — 2026-08-10

### Added

- Registry-driven model execution through `config/model_registry.csv`.
- Centralized site and pipeline configuration.
- Full input validation and climate-feature QA.
- Historical PDSI feature construction before biological-year filtering.
- Site-specific MARSS climate-response matrix construction and parameter-count auditing.
- KEM fitting with convergence classification and BFGS fallback for incomplete convergence.
- Resume/reuse behavior for compatible saved model fits.
- Optional parametric bootstrap confidence intervals with reproducible model-specific seeds.
- Standardized parameter extraction and site/watershed mapping.
- Residual diagnostics and biological observation-coverage summaries.
- Candidate-set-specific AIC/AICc ranking and Akaike weights.
- Site-level parameter figures and candidate-set ΔAICc plots.
- Master `00_run_full_pipeline.R` entry point and run snapshots.
- Primary PDSI hypothesis registry (P0–P9) plus retained exploratory/legacy models.
- GitHub handoff documentation set and preflight script.

### Verified at handoff

- 14 biological sites and 29 biological years (1997–2025).
- 12 registered model fits found.
- 12 models converged.
- 0 models not yet fit.
- 0 failed/error models in the handoff snapshot.
- M0/P0 500-replicate parametric CI bootstrap successfully completed and reusable.

### Important compatibility note

The archived monolithic baseline is retained for historical validation only. New analyses should use the modular registry-driven pipeline.
