================================================================================
CRLF MARSS PDSI MODEL RESULTS
INTERPRETATION, DIAGNOSTIC NEEDS, AND RECOMMENDED NEXT STEPS
Handoff Draft
================================================================================

PURPOSE
-------
This document summarizes what the current PDSI hypothesis table actually shows,
what can and cannot yet be concluded from the fitted MARSS models, how the
site-specific climate coefficients should be interpreted, what is currently
known about the residual diagnostics, and what analyses should be prioritized
next.

This is intended as collaborator-facing scientific interpretation rather than
a replacement for the exact model-selection table or raw diagnostic files.


================================================================================
1. CURRENT MODEL-SELECTION RESULT
================================================================================

Primary candidate set:
  PDSI_PRIMARY_HYPOTHESES_V1

The current AICc ranking is approximately:

Rank  Model   Description                          AICc    Delta AICc
----  ------  -----------------------------------  ------  ----------
1     P0      Null / no PDSI                      964       0.0
2     P2      Current Jan-Mar PDSI                972       8.35
3     P6      Oct-Dec 3-year running mean         984      20.1
4     P7      Jan-Mar 3-year running mean         994      30.2
5     P1      Current Oct-Dec PDSI                996      32.5
6     P4      Current Jan-Mar + t-3               997      33.3
7     P8      Oct-Dec RunMean3 + t-3             1016      52.1
8     P9      Jan-Mar RunMean3 + t-3             1022      58.6
9     P3      Current Oct-Dec + t-3               1029      65.0
10    P5      Current Oct-Dec x Jan-Mar           1034      70.8


AICc interpretation:
  P0 is clearly the best-supported model in the current primary candidate set.

  P2 is the strongest climate model, but its Delta AICc is approximately 8.35
  relative to the null.

  All other PDSI models are substantially farther from the null.

Therefore, under the CURRENT site-specific-C formulation, the PDSI covariates
do not improve expected predictive fit enough to offset their added parameter
cost according to AICc.


================================================================================
2. IMPORTANT AIC VS AICc RESULT
================================================================================

An important nuance is that P2 has a lower ordinary AIC than P0.

Approximate values:

  P0:
    AIC  ~ 948
    AICc ~ 964
    K    = 42

  P2:
    AIC  ~ 943
    AICc ~ 972
    K    = 56

Therefore:

  P2 improves the raw likelihood sufficiently to beat P0 under ordinary AIC,

BUT:

  P2 adds 14 site-specific climate coefficients, and the small-sample AICc
  correction reverses the ranking.

This distinction is scientifically important.

The result should NOT be summarized as:
  "PDSI has no effect."

A better interpretation is:

  "Contemporary Jan-Mar PDSI contains some explanatory signal, but the
   site-specific response formulation requires enough additional parameters
   that the climate model is not supported over the null once small-sample
   model complexity is accounted for."

This is currently the strongest climate-related conclusion in the model table.


================================================================================
3. WHAT THE CURRENT MODEL TABLE SUGGESTS ABOUT PDSI
================================================================================

A. CURRENT JAN-MAR IS THE STRONGEST PDSI FORMULATION
----------------------------------------------------
P2 is the strongest climate model.

This suggests that if PDSI contributes information, conditions during the
Jan-Mar breeding-season window are more promising than the current Oct-Dec
window under the tested formulations.


B. CURRENT OCT-DEC IS MUCH WEAKER
---------------------------------
P1 performs substantially worse than P2.

This suggests that contemporary antecedent Oct-Dec PDSI alone does not explain
the observed site-level egg-mass dynamics particularly well.


C. THREE-YEAR CLIMATE MEMORY DOES NOT RESCUE THE FIT
----------------------------------------------------
P6 is the second-best climate family after P2, but remains far behind the null.

P7 is weaker.

This indicates that smoothing PDSI across the recent three-year period does not
solve the main mismatch between the climate covariate and the biological data.


D. t-3 TERMS ADD LIKELIHOOD BUT ARE TOO EXPENSIVE
-------------------------------------------------
Models containing t-3 terms can improve raw likelihood, but they require 28
site-specific climate coefficients when combined with current or RunMean3
effects.

Their AICc values are poor.

Therefore the current evidence does not support adding a separate t-3 climate
effect under a fully site-specific coefficient structure.


E. THE INTERACTION MODEL FITS THE DATA BETTER IN RAW LIKELIHOOD, BUT IS TOO
   PARAMETER-RICH
---------------------------------------------------------------------------
P5 has the strongest raw likelihood among the primary climate models, but it
estimates 42 climate coefficients and has a very poor AICc.

This is a classic indication that model flexibility can improve in-sample fit
without providing enough information gain to justify the added complexity.


================================================================================
4. OUR CURRENT SCIENTIFIC INTERPRETATION
================================================================================

The current evidence points to a mismatch between the spatial/biological scale
of the PDSI covariates and the processes controlling egg-mass abundance.

The PDSI covariates may be too coarse, too indirect, or too weakly linked to
individual pond conditions to explain most of the site-level variability.

This is plausible because all ponds within a watershed share the same climate
history, while individual ponds can differ strongly in:

  hydroperiod
  actual water depth
  pond filling
  drying date
  local topography
  vegetation
  habitat condition
  restoration history
  landscape connectivity
  recolonization potential
  population size
  survey history

The current model allows each site to have a different PDSI coefficient, but
the underlying climate exposure is still watershed-level.

That means the model can estimate different responses to the same regional
climate history, but it cannot create the missing local hydrologic information
that PDSI does not directly measure.


================================================================================
5. WHY THE PDSI MODELS MAY BE STRUGGLING
================================================================================

Several non-exclusive explanations should be considered.

1. PDSI is a regional drought index, not pond hydroperiod.
   It may not represent whether a particular breeding pond filled, remained
   inundated, or dried before successful recruitment.

2. Individual site responses may be nonlinear.
   A pond may show little response across moderate PDSI but fail once a drought
   threshold is crossed.

3. The climate relationship may depend on hydroperiod.
   Seasonal and perennial ponds may respond differently.

4. The relationship may be conditional on connectivity.
   A site can experience breeding failure yet recover quickly if it is well
   connected, while an isolated site may remain depressed.

5. Site-specific C creates a very high-dimensional model.
   Fourteen slopes are added for each climate feature.

6. The 29-year time series is relatively short for estimating many independent
   climate slopes, particularly with missing biological observations.

7. Egg-mass abundance is influenced by processes not contained in PDSI:
   local pond hydrology, habitat change, density dependence, recruitment,
   movement, rescue, disease, and observation/process assumptions.

8. R is fixed at zero in v1.0.
   Therefore all unexplained stochastic variation is handled through the
   process component Q rather than a separately estimated observation-error
   component.


================================================================================
6. CLIMATE-COEFFICIENT PLOTS: WHAT THEY SHOULD TELL US
================================================================================

The site-specific C coefficients answer:

  "For this pond, what is the estimated direction and magnitude of association
   between the specified PDSI feature and the latent population process?"

For one-feature models such as P2:
  there are 14 separate climate coefficients.

For two-feature models:
  28 coefficients.

For three-feature models:
  42 coefficients.


WHAT TO LOOK FOR
----------------

A. CONSISTENT SIGN
  Are most site coefficients positive?
  Are most negative?
  Or are directions split across sites?

B. MAGNITUDE
  Are most coefficients close to zero?
  Are a few sites driving the apparent climate signal?

C. WITHIN-WATERSHED HETEROGENEITY
  Laguna Salada sites share the same PDSI time series.
  If their estimated slopes vary strongly in sign and magnitude, this supports
  the idea that local pond characteristics modify climate response.

D. HYDROPERIOD PATTERN
  Do seasonal ponds show different coefficient signs or magnitudes than
  perennial ponds?

E. UNCERTAINTY
  Which coefficients have bootstrap intervals clearly away from zero?
  Which are very uncertain?


================================================================================
7. IMPORTANT LIMITATION: CLIMATE EFFECT PLOTS ARE NOT YET COMPLETE
================================================================================

The current pipeline logs show that the PDSI candidate models were fit with:

  Run_Bootstrap = FALSE

and therefore reported:

  "Skipping bootstrap CI parameter extraction and parameter figure."

As a result, the files currently available for handoff do NOT support a final
site-by-site inference such as:

  "Site LS01 had a significant positive Jan-Mar PDSI effect."

Those statements require the actual coefficient table and uncertainty
intervals.

At the current handoff stage:

  model-level AIC/AICc interpretation is supported;

  final site-specific climate-effect inference is NOT yet complete.


================================================================================
8. WHICH COEFFICIENT MODEL SHOULD BE EXAMINED FIRST?
================================================================================

Priority 1:
  P2 -- current Jan-Mar PDSI

Why:
  It is the strongest PDSI candidate by AICc.
  It is also the only PDSI formulation that beats the null under ordinary AIC.

Recommended inference:
  run the parametric bootstrap for P2;
  extract all 14 site-specific C estimates and 95% CIs;
  produce a coefficient forest plot;
  group/annotate sites by watershed and hydroperiod.

This gives the cleanest answer to:

  "Where, if anywhere, is contemporary breeding-season PDSI associated with
   site-level egg-mass dynamics?"


Priority 2:
  P6 -- Oct-Dec 3-year running mean

Why:
  It is the next strongest climate formulation and the strongest early-season
  climate-memory model.

P6 can be useful as a contrasting biological hypothesis even though its AICc is
not competitive with P0.


LOWER PRIORITY:
  P3, P4, P8, P9, P5

These models are high-dimensional and have poor AICc support.
Bootstrapping all of them would require substantial computation with limited
expected inferential return.


================================================================================
9. RESIDUAL DIAGNOSTICS: WHAT IS CURRENTLY KNOWN
================================================================================

The pipeline successfully created MARSS tt1 residual objects for the fitted
models.

For the current 14-site model matrix:

  sites = 14
  years = 29
  observed site-years = 273
  missing site-years = 133

Residual calculation success means the diagnostic objects exist.

However:

  "Residual calculation PASS"

does NOT mean:

  "the model residuals are good."

The current file set available for this handoff does not contain enough
site-level residual summaries or residual plots to state which sites, years, or
models have problematic residual structure.

Therefore no residual-pattern result should be invented.


================================================================================
10. RESIDUAL PLOTS WE SHOULD PRODUCE / PRESERVE
================================================================================

For at minimum P0 and P2, produce:

1. Residuals through time by site
   Goal:
     identify years consistently over- or under-predicted.

2. Residual distribution by site
   Goal:
     identify sites with consistently poor fit or large unexplained variance.

3. Residual ACF by site
   Goal:
     identify remaining temporal autocorrelation.

4. Residual vs fitted-value plot
   Goal:
     identify heteroscedasticity or nonlinear structure.

5. Residual vs PDSI
   Goal:
     determine whether climate signal remains in residuals after fitting.

6. Residual heatmap: site x year
   Goal:
     identify years in which many sites move together in the same unexplained
     direction.

7. Annual mean residual across sites
   Goal:
     identify system-wide years that the model consistently misses.

8. Residuals stratified by hydroperiod
   Goal:
     assess whether seasonal versus perennial sites have different unexplained
     structure.


================================================================================
11. THE MOST IMPORTANT RESIDUAL COMPARISON: P0 VS P2
================================================================================

The next diagnostic question should not simply be:

  "Does P2 have residuals?"

Every model has residuals.

The useful comparison is:

  What residual structure disappears when Jan-Mar PDSI is added to P0,
  and what residual structure remains?

For each site, compare P0 and P2:

  residual variance
  residual mean
  absolute residual magnitude
  temporal autocorrelation
  years with extreme residuals

If P2 improves only a small subset of sites while doing little elsewhere, that
would explain why ordinary likelihood improves but AICc rejects 14 separate
climate slopes.

If P2 improves most sites slightly, that suggests a shared or partially pooled
climate-response formulation may be more efficient than 14 independent slopes.


================================================================================
12. COEFFICIENT HETEROGENEITY IS A KEY NEXT QUESTION
================================================================================

The current model estimates a separate PDSI response for every site.

That was biologically defensible, but it may be statistically expensive.

The next coefficient analysis should ask:

  Are the 14 site-specific P2 slopes genuinely different?

Possible patterns:

PATTERN A:
  Most slopes have similar sign and magnitude.

Interpretation:
  A common or partially pooled Jan-Mar climate effect may be more appropriate
  and much more parsimonious.

PATTERN B:
  Slopes separate by hydroperiod.

Interpretation:
  Consider two climate-response groups:
    seasonal
    perennial

PATTERN C:
  Slopes separate mainly by watershed.

Interpretation:
  A watershed-level or hierarchical slope structure may be adequate.

PATTERN D:
  A few sites have strong effects while most are near zero.

Interpretation:
  PDSI may be relevant locally but not as a universal predictor.

PATTERN E:
  Signs are highly inconsistent and CIs are broad.

Interpretation:
  PDSI is probably not capturing the dominant site-level process, and adding
  more PDSI temporal formulations is unlikely to solve the problem.


================================================================================
13. RECOMMENDED NEXT MODEL-STRUCTURE TESTS
================================================================================

Do NOT immediately add more PDSI lags.

The current table already tests:
  current
  running mean
  t-3
  interaction

and none outperform the null under AICc.

More temporal combinations risk becoming a search for a favorable model rather
than a biologically motivated test.


Higher-value next tests:

A. PARTIALLY POOLED / SHARED CLIMATE RESPONSE
---------------------------------------------
Test whether P2 can be represented more parsimoniously.

Examples:
  one global Jan-Mar slope;
  one slope per watershed;
  one slope per hydroperiod group;
  hierarchical/partial pooling if supported by the modeling framework.

Reason:
  P2 improves ordinary AIC but loses AICc because 14 extra slopes are expensive.

This is the single most obvious statistical next step.


B. LOCAL HYDROLOGY
------------------
Use staff-gauge variables where data coverage is adequate.

Potential predictors:
  staff_start_janmar
  staff_mean_janmar
  staff_mean_prev_oct_dec
  staff_max_oct_mar

Reason:
  These variables measure the actual pond-level hydrologic mechanism more
  directly than regional PDSI.


C. HYDROPERIOD INTERACTION / GROUPING
-------------------------------------
Test whether seasonal and perennial ponds respond differently.

Reason:
  The biological effect of drought should plausibly depend on whether a site
  normally dries or persists year-round.


D. CONNECTIVITY / RESCUE
------------------------
Complete static connectivity first, then dynamic connectivity.

Reason:
  climate may cause breeding failure, while connectivity may determine recovery
  and persistence.

The connectivity development workspace already identifies a pathway from
validated sites and resistance surfaces to site-level or site-year rescue
covariates.


E. NONLINEAR / THRESHOLD CLIMATE RESPONSE
-----------------------------------------
Consider a biologically defined drought threshold rather than assuming that
each one-unit change in PDSI has the same effect.

Examples:
  severe-drought indicator
  threshold below which breeding failure probability rises
  wet / normal / drought state

Any threshold should be defined biologically or a priori where possible.


================================================================================
14. R=0 SHOULD RECEIVE A SENSITIVITY TEST
================================================================================

The current v1.0 model fixes:

  R = zero

Therefore a separate observation-error variance is not estimated.

Before concluding that covariates are poor predictors of biological process,
a future sensitivity analysis should examine whether allowing some observation
error changes:

  Q estimates
  C estimates
  residual structure
  AIC/AICc ranking

This should be a new sensitivity-analysis candidate set, not a silent change to
the locked v1.0 results.


================================================================================
15. WHAT WE THINK THE CURRENT STORY IS
================================================================================

The current PDSI analysis has been useful even though the PDSI models do not win
AICc.

It tells us:

1. A simple climate-free site-level population model is difficult to improve
   upon using the current watershed-level PDSI formulations.

2. Jan-Mar PDSI is the most promising regional climate variable tested.

3. P2 contains enough information to improve ordinary AIC, so there is some
   climate signal worth investigating.

4. Fully site-specific climate responses are statistically expensive.

5. Adding more lag terms, running means, and interactions increases model
   complexity much faster than it increases supported fit.

6. The dominant missing predictors are likely to be more local or mechanistic:
   pond hydrology, hydroperiod differences, connectivity, or combinations of
   those processes.

7. The next phase should focus less on inventing additional PDSI formulations
   and more on understanding:
     coefficient heterogeneity,
     residual structure,
     local hydrology,
     and connectivity.


================================================================================
16. RECOMMENDED IMMEDIATE WORK PLAN
================================================================================

FIRST:
  Preserve v1.0 exactly as the completed PDSI candidate analysis.

SECOND:
  Bootstrap P2.
  Produce its 14 site-specific coefficient estimates and 95% CIs.

THIRD:
  Create a P0 vs P2 diagnostic package:
    residual-by-year plots
    site residual summaries
    residual ACF
    residual heatmap
    residual vs fitted
    residual improvement table

FOURTH:
  Examine whether P2 coefficients cluster by:
    hydroperiod
    watershed
    site

FIFTH:
  Test a more parsimonious Jan-Mar coefficient structure.

SIXTH:
  Evaluate local staff-gauge hydrology.

SEVENTH:
  Finish static landscape connectivity.

EIGHTH:
  Build a new, biologically motivated hydrology/connectivity candidate set.

NINTH:
  Evaluate R=0 as a sensitivity-analysis assumption.

TENTH:
  Only after those analyses should additional complex PDSI formulations be
  considered.


================================================================================
17. COLLABORATOR-FACING SUMMARY
================================================================================
   Across the primary PDSI candidate set, the climate free model received the
   strongest AICc support. Contemporary Jan-Mar PDSI was the strongest climate
   formulation and improved ordinary AIC relative to the null, indicating that
   breeding season climate contains some explanatory signal. However, the
   improvement was not sufficient to offset the 14 additional site-specific
   climate response parameters under AICc. More complex lagged, running-mean,
   and interaction formulations were progressively less supported. These
   results suggest that regional PDSI alone does not capture much of the
   site-level variability in egg-mass dynamics and motivate a shift toward
   coefficient diagnostics, local pond hydrology, hydroperiod structure, and
   landscape connectivity/rescue processes. Overall I would recommend talking more
   to biological experts on what they believe is the most important climate variable
   and time frame affecting these sites. Maybe look at Vapor pressue Deficit or Climate Water Deficit. 

