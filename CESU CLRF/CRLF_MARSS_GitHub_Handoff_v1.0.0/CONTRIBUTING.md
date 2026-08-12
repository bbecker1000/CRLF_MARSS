# Contributing to the CRLF MARSS Pipeline

This repository is a scientific analysis pipeline. Code changes can change scientific meaning, so contributions should preserve a clear boundary between hypotheses, data processing, and generic model machinery.

## Preferred workflow

1. Create a branch for the change.
2. Explain the scientific/computational motivation.
3. Do not modify existing model meaning under an existing `Model_ID`.
4. Add new hypotheses through `config/model_registry.csv` when current feature/mapping logic already supports them.
5. Add new feature logic only when a genuinely new predictor is required.
6. Add/extend QA when changing dimensions, feature mapping, or parameter structures.
7. Run a clean-session master pipeline test.
8. Update `CHANGELOG.md` and relevant documentation.

## Changes requiring special review

Treat the following as scientific-model changes, not routine refactors:

- response transformation
- treatment of zeros/NA
- climate windows or lag definitions
- site/watershed mapping
- `B`, `Q`, `R`, `C`, or `c` structure
- pooling site-specific coefficients
- observation years/sites
- feature spatial scale
- candidate-set membership

## Outputs

Do not commit large `.rds` fit/bootstrap objects through normal Git history unless the repository policy explicitly changes.

## Reproducibility expectation

A pull request that changes active analysis should be reproducible from a fresh R session using:

```r
source("00_run_full_pipeline.R")
```
