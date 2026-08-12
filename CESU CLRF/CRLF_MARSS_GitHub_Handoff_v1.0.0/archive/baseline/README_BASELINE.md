# Archived Baseline MARSS Script

Place the previously validated monolithic MARSS analysis script here as:

```text
MARSS_BASELINE_CORRECT_LOCKED.R
```

## Purpose

The archived baseline is retained as a historical/reference implementation that helped validate the modular pipeline. It should not be the active entry point for new analyses.

## Rules

1. Do not edit the locked baseline in place.
2. Do not add new hypotheses by copying sections out of the baseline.
3. Use `00_run_full_pipeline.R` plus `config/model_registry.csv` for active analysis.
4. If a discrepancy appears between the modular pipeline and baseline, investigate and document the reason rather than silently changing either result.
5. If the baseline must be modified for an experiment, copy it to a new explicitly named file and leave the locked version unchanged.

## Why retain it?

It provides:

- an independent historical reference for model structure
- a way to confirm that refactoring did not silently alter core mathematics
- provenance for early figures/results

The modular pipeline is the maintained implementation because it separates data loading, QA, feature engineering, model construction, fitting, inference, diagnostics, selection, and reporting into auditable modules.
