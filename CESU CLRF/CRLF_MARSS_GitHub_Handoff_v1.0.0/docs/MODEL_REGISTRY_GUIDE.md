# Model Registry Guide

`config/model_registry.csv` is the scientific control table for the CRLF MARSS pipeline.

The central rule is:

> If a model can be expressed as a new combination of already-supported features and structures, define it in the registry rather than creating a new model-specific R script.

## Registry columns

### `Sort_Order`
Display/execution ordering aid. It does not define scientific identity.

### `Model_Number`
Human-facing shorthand such as `P0`, `P1`, `P2`, `E1`. Useful in figures and manuscripts. It may be descriptive, but `Model_ID` is the permanent machine identifier.

### `Model_ID`
Permanent unique identifier and output-directory name. Examples: `M0_Null`, `P2_Late_Current`.

Do not reuse an existing `Model_ID` for a mathematically different model. Create a new ID.

### `Model_Name`
Human-readable model label.

### `Enabled`
Whether the registry row is active.

### `Fit_Model`
Whether the suite runner should fit/resume the model.

### `Run_Bootstrap`
Whether a new parametric CI bootstrap should be launched if a compatible completed bootstrap is not already present.

Use `FALSE` for initial candidate screening unless CI inference is required immediately.

### `Primary_Analysis`
Marks models belonging to the main analysis versus exploratory/sensitivity work.

### `Candidate_Set`
Defines the model-comparison universe for AIC/AICc deltas and weights. Only compare weights within a coherent candidate set.

Examples:

```text
PDSI_PRIMARY_HYPOTHESES_V1
PDSI_EXPLORATORY_LEGACY_V1
```

### `Comparison_Role`
Human-readable label such as `PRIMARY` or `EXPLORATORY`.

### `Model_Family`
Broad ecological/modeling category, for example:

```text
Null
Contemporary climate
Contemporary + cohort lag
Recent climate memory
Recent climate memory + cohort lag
Contemporary seasonal interaction
```

### `Scientific_Question`
Plain-language question the model is intended to answer.

### `Hypothesis`
Formal hypothesis statement.

### `Biological_Interpretation`
Explains the intended ecological meaning and guards against later misinterpretation.

### `Response`
Human-readable response definition. Current primary response is `log(annual egg-mass abundance + 1)`.

### `Covariates`
Pipe-separated feature names requested from the feature catalog.

Examples:

```text
PDSI_JanMar
PDSI_OctDec|PDSI_OctDec_lag3
PDSI_OctDec|PDSI_JanMar|PDSI_Interact
```

Null models use blank/NA covariates.

### `Season_Focus`
Descriptive category such as `Early`, `Late`, `Early + Late`, or `None`.

### `Climate_Window`
Descriptive seasonal window such as `Oct-Dec` or `Jan-Mar`.

### `Time_Structure`
Examples:

```text
t
mean(t,t-1,t-2)
t + t-3
mean(t,t-1,t-2) + t-3
```

### `Lag_Structure`
Human-readable temporal classification.

### `Interaction`
Whether the model contains an interaction term.

### `C_Structure`
Current primary climate models use `site_specific`; null uses `none`.

### `B_Structure`, `U_Structure`, `Q_Structure`, `R_Structure`
MARSS structural assumptions. Changes to these create a different model family/sensitivity analysis and should not be treated as mere registry formatting edits.

### `Expected_C_Parameters`
QA expectation for number of free climate coefficients.

For 14 sites under site-specific `C`:

```text
0 features → 0
1 feature  → 14
2 features → 28
3 features → 42
```

### `Expected_Total_K`
Expected total free parameter count. Under the current baseline:

```text
Null      → 42
1 feature → 56
2 feature → 70
3 feature → 84
```

### `Bootstrap_N`
Requested bootstrap replicate count for that model when bootstrap is enabled.

### `Status`
Administrative field such as `ACTIVE`.

### `Notes`
Free-text scientific/reproducibility notes.

## Adding a new model

Suppose the question is whether current Jan–Mar PDSI plus its `t-3` value affects individual sites.

A registry row should encode approximately:

```text
Model_Number: P_NEW
Model_ID: P_NEW_Late_Current_Lag3
Model_Name: Late Jan-Mar Contemporary + t-3 Lag
Candidate_Set: PDSI_PRIMARY_HYPOTHESES_V1
Covariates: PDSI_JanMar|PDSI_JanMar_lag3
C_Structure: site_specific
Expected_C_Parameters: 28
Expected_Total_K: 70
Fit_Model: TRUE
Run_Bootstrap: FALSE
```

Then run:

```r
source("00_run_full_pipeline.R")
```

The builder should report 28 active and 28 unique site-specific `C` parameters before fitting.

## When NOT to reuse a Model_ID

Create a new ID if any of the following scientific/mathematical components change:

- covariates
- lag definition
- running-mean definition
- `C` pooling structure
- `B`, `Q`, or `R` structure
- response transformation
- biological time support
- spatial representation of predictor exposure

Changing only explanatory wording in the registry can retain the same ID, but changing the actual model should not.

## Expected QA before accepting a new model

1. Requested features exist.
2. No MARSS `c` values are missing in the biological window.
3. `C` matrix has expected dimensions.
4. Active free `C` cells equal expectation.
5. Estimated parameter names are unique.
6. Final fit converges.
7. Actual `K` matches expected model complexity.
8. Model appears in the correct candidate set.
9. Model-selection table updates without mixing unrelated candidate sets.
