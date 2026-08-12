================================================================================
31. DEEP-PARSE ADDENDUM: README_Y_MATRIX / README_PDSI_COVARIATE
================================================================================

This section incorporates additional provenance recovered from the historical
README_Y_Matrix.txt and README_PDSI_COVARIATE.R documentation.

31.1 HISTORICAL 16-SITE TARGET
------------------------------
The older README correctly described an intermediate 16 x 29 biological matrix
after applying the >=15 actively monitored-year criterion.

The final v1.0 workflow subsequently removed:
  TV03 -- 16 surveyed years, 16 zero years, 0 egg masses
  LS09 -- 17 surveyed years, 15 zero years, 2 total egg masses

Therefore:
  16-site matrices = monitoring-history-qualified intermediate products
  14-site matrix    = final v1.0 MARSS model input

31.2 IMPORTANT BIOLOGICAL OUTPUT FILES RECOVERED FROM THE OLD README
--------------------------------------------------------------------
marss_matrix_y_logTransformed.rds
  Historical 16 x 29 log(count + 1) matrix.
  Treat as legacy/intermediate if it still contains 16 sites.

marss_matrix_y_raw.rds
  Historical 16 x 29 raw numeric-count matrix.
  Important provenance/QA companion and worth retaining.

marss_y_raw_counts_wide.csv
  Historical human-readable wide matrix:
  16 site rows plus 29 Water-Year columns.
  Useful for manual auditing of positive counts, zeros, and NA gaps.

biological_site_metadata.csv
  Historical site metadata linkage:
  Site IDs, site names, watershed, hydroperiod, and related metadata.

Recommended final 14-site companions:
  marss_matrix_y_14sites_raw.rds
  marss_y_14sites_raw_counts_wide.csv
  marss_matrix_y_14sites_logTransformed.rds
  biological_site_metadata_14sites.csv

Do not delete the 16-site versions. Archive them as the pre-final screening
stage.

31.3 NUMERIC-INTEGRITY STANDARD
-------------------------------
The final y matrices should contain only:
  numeric positive counts
  numeric 0 for confirmed surveyed zeros
  true NA for unmonitored years

Do not allow text values such as:
  "0"
  "NA"
  "missing"
  "not_surveyed"

inside the numeric MARSS matrix.

Survey-status labels belong in the annual long-format audit table.

31.4 PRECISE NA / KALMAN-FILTER WORDING
---------------------------------------
Missing survey years remain NA.

MARSS accepts NA observations as missing. The state-space / Kalman-filter
machinery estimates latent states conditional on the fitted process model and
the available observations.

Do not describe a missing-year estimate as if it were an observed population
count or a known true value.

31.5 IMPORTANT Z-MATRIX LEGACY WARNING
--------------------------------------
The older README says biological_site_metadata.csv was used to construct
"structural grouping matrices (Z matrix) for watershed-level modeling."

That describes an earlier architecture.

CURRENT v1.0:
  Z = identity

Therefore current metadata/site-registry roles are:
  site identity
  site-to-watershed mapping
  hydroperiod
  coordinate linkage
  climate exposure mapping in c
  site-specific climate-response mapping/audit in C

Do NOT tell collaborators that the current Z matrix groups sites by watershed.

31.6 THREE-COLOR BIOLOGICAL QA HEATMAP
--------------------------------------
Historical QA figure:
  matrix_data_availability_heatmap_3color.png

Meaning:
  Gray   = unmonitored / NA
  Orange = surveyed zero
  Green  = positive egg-mass count

This is a high-value handoff diagnostic because it visually verifies the
zero-versus-missing rule.

Recommendation:
  retain it, or regenerate a final 14-site version named:
  matrix_data_availability_heatmap_3color_14sites.png

31.7 RAW-COUNT COMPANIONS SHOULD BE PRESERVED
---------------------------------------------
The transformed RDS is the model input, but the handoff should preserve a raw
matrix beside it.

Why:
  collaborators can audit the transformation;
  summary statistics can be reproduced directly;
  zeros and NA gaps are easy to inspect;
  the final model input can be independently checked.

Best final bundle:
  raw 14-site RDS
  wide 14-site raw CSV
  transformed 14-site RDS
  14-site metadata CSV
  14-site coverage heatmap

31.8 PATH CONSISTENCY
---------------------
Historical documentation references:
  outputs/Master_AnnualEggs_StaffWindow_Cleaned_Hydroperiod_1997_2025.csv

The final GitHub handoff should choose one canonical path and use the same path
in:
  README
  R/01_load_inputs.R
  data dictionary

If fallback paths are supported in code, label them as fallbacks.

31.9 CURRENT-vs-HISTORICAL SUMMARY
----------------------------------
Historical README material remains valuable for:
  >=15-year screening
  numeric-integrity rules
  zero-vs-NA handling
  raw/transformed matrix products
  site metadata linkage
  biological QA heatmap
  early automated C/c construction

Current v1.0 supersedes historical statements where architecture changed:
  16 sites -> 14 final modeled sites
  generic y filenames -> explicit 14-site authoritative filenames
  watershed-grouped Z language -> Z = identity
  README_PDSI_COVARIATE.R -> modular R/03 + R/04
  watershed-shared C variants -> site-specific C

================================================================================
32. RECOMMENDED FINAL BIOLOGICAL HANDOFF FILE SET
================================================================================

SOURCE / ANNUAL MASTER
  Master_AnnualEggs_StaffWindow_Cleaned_Hydroperiod_1997_2025.csv
  2,117 annual site-year rows = 73 sites x 29 years

FINAL SITE METADATA
  biological_site_metadata_14sites.csv

FINAL RAW MODEL-SUBSET MATRIX
  marss_matrix_y_14sites_raw.rds
  14 x 29

FINAL HUMAN-READABLE RAW MATRIX
  marss_y_14sites_raw_counts_wide.csv
  14 rows x 30 columns

FINAL MODEL MATRIX
  marss_matrix_y_14sites_logTransformed.rds
  14 x 29

FINAL COVERAGE QA
  matrix_data_availability_heatmap_3color_14sites.png

OPTIONAL TREND QA
  biological_honest_trends_14sites.png

This paired file set makes every step from annual biological counts to the
exact MARSS y matrix independently auditable.

================================================================================
END OF DEEP-PARSE ADDENDUM
================================================================================
