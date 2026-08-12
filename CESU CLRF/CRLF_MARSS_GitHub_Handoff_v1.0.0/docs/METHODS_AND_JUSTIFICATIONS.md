# Methods and Justifications

This document records the scientific and modeling decisions that should not be lost during code cleanup or project handoff.

## 1. Biological response

The MARSS response matrix represents annual CRLF egg-mass abundance by site and biological year. Counts are transformed as `log(count + 1)`.

### Why retain zeros?

A surveyed year in which no egg masses were observed is biological information and remains zero before transformation.

### Why retain `NA`?

An unsurveyed site-year does not establish biological absence. Missing biological coverage therefore remains `NA` and is handled as missing observation data by MARSS.

Converting unsurveyed years to zero would confound absence of survey effort with observed reproductive failure.

## 2. Biological time window

The modeled response spans 1997–2025. Climate features are not first truncated to those years. The longer historical climate record is used to construct lags and running means, then features are filtered to biological years. This prevents early model years from having artificially missing or zero-filled lagged values.

## 3. PDSI spatial scale

PDSI is represented by one climate series per modeled watershed. Sites within the same watershed share the same exposure time series.

This does not imply that all sites in a watershed have the same biological response. Under the active site-specific `C` structure, each site has its own climate-response coefficient.

## 4. Seasonal climate windows

### Oct–Dec

Represents antecedent/early hydrologic conditions leading into the principal breeding period. The biological hypothesis is that early winter moisture can influence pond filling and habitat availability.

### Jan–Mar

Represents the principal breeding-season climate window in the current analysis. The biological hypothesis is that contemporaneous breeding-season moisture conditions may influence egg-mass abundance and related population dynamics.

The labels “early” and “late” refer to these analysis windows, not universal CRLF seasonal definitions.

## 5. Running means

- `RunMean1 = t`
- `RunMean2 = mean(t, t-1)`
- `RunMean3 = mean(t, t-1, t-2)`

Running means test cumulative recent climate memory. They are not separate annual terms in the model; the average is one covariate.

Avoid including multiple heavily overlapping running means in the same model unless that exact collinear hypothesis is scientifically justified.

## 6. Three-year lag

`lag3` is the climate value at `t-3` and is intentionally distinct from `RunMean3`.

A model containing `RunMean3 + lag3` tests recent cumulative conditions across `t`, `t-1`, and `t-2` plus a separate `t-3` signal.

The lag was motivated by a possible cohort/maturity pathway: climate experienced by an earlier cohort could be associated with the breeding population several years later. The model tests this idea; it should not be described as proof that every CRLF reaches sexual maturity at exactly three years.

## 7. Seasonal interactions

`PDSI_Interact = PDSI_OctDec * PDSI_JanMar`.

Interaction models retain both main effects with the interaction. A main-effect-free interaction would make interpretation difficult and is not the current intended hypothesis.

## 8. Site-specific `C` coefficients

The current project intentionally estimates one climate response per site per requested climate feature.

For 14 sites:

- one feature → 14 `C` parameters
- two features → 28 `C` parameters
- three features → 42 `C` parameters

This architecture allows biological response heterogeneity among ponds exposed to the same watershed-scale climate history.

Changing to watershed-shared slopes is a different model family and should be stored in a different candidate set rather than silently substituted.

## 9. Baseline MARSS structure

Current baseline:

```r
Z = "identity"
B = "identity"
U = "unequal"
Q = "diagonal and unequal"
R = "zero"
```

For climate models, dynamic `C` and `c` components are added.

### `R = zero`

Observation error is fixed to zero. All stochastic variation represented in the current baseline enters through the process variance `Q`. This assumption is strong. It was retained to reproduce the established baseline architecture and should be treated as an explicit assumption, not an invisible default.

A future sensitivity analysis that changes `R` should receive its own model/candidate-set identity.

## 10. Fitting and convergence

KEM is the primary optimizer. Nonzero convergence conditions classified as incomplete can trigger BFGS fallback initialized from KEM estimates. A usable pipeline fit requires the final fit to be recorded as `CONVERGED` with final convergence code 0.

Intermediate KEM/BFGS objects are retained locally for diagnostics but need not be committed to GitHub.

## 11. Why AICc is emphasized

The biological dataset contains 273 observed site-years, while site-specific climate models can contain 56, 70, or 84 total free parameters. Because the ratio of information to estimated parameters is limited, the small-sample correction in AICc can be substantial.

This is scientifically informative: a climate model may improve raw likelihood but still be poorly supported once the cost of many site-specific coefficients is considered.

## 12. AIC versus biological effect

A null-model AICc win does not establish that climate has no biological effect. It establishes that, among the specified candidate formulations, the more complex climate models do not gain enough expected predictive fit to overcome their parameter cost under AICc.

Parameter estimates, uncertainty, alternative pooling structures, and additional biological covariates are distinct questions.

## 13. Candidate sets

Akaike weights are relative quantities. They should only be calculated among models that form a coherent comparison set using compatible response data, likelihood assumptions, and scientific purpose.

Primary hypotheses and exploratory/legacy formulations therefore remain separated by `Candidate_Set`.

## 14. Bootstrap inference

`MARSSparamCIs(..., method = "parametric")` is used for parameter confidence intervals. This is intentionally run only for selected models because it is computationally expensive.

The parameter CI bootstrap is not bootstrap AIC and should not be labeled `AICbp`.

## 15. Model selection before expensive inference

The intended workflow is:

```text
fit candidate set
    ↓
rank by AIC/AICc
    ↓
select scientifically important / competitive models
    ↓
run bootstrap CIs
```

This avoids spending hours bootstrapping models that have little model-selection support unless those models are retained for a separate scientific reason.

## 16. Future hydrology/connectivity extension

The architecture is intended to accommodate additional ecological drivers, but current climate feature construction is watershed-oriented. Site-year predictors such as connectivity should not be forced into a watershed feature representation. Extend the feature metadata/mapping layer so spatial scale is explicit, then route the feature through the same registry-driven MARSS builder.
