==============================================================================
MARSS BIOLOGICAL INPUT DATA PIPELINE & ARCHIVE DIRECTORY
==============================================================================
Generated on : 2026-07-17
Project Scope: California Red-legged Frog (CRLF) Population Modeling
Study Window : Water Years 1997 - 2025 (Temporal Horizon = 29 continuous years)
Target Shape : Wide Matrix (16 Rows x 29 Columns)

------------------------------------------------------------------------------
1. DATA SOURCE & FILTERING CRITERIA
------------------------------------------------------------------------------
Primary Source File: 
  -> outputs/Master_AnnualEggs_StaffWindow_Cleaned_Hydroperiod_1997_2025.csv

Inclusion Protocol:
  * Long-format count data was audited for data integrity.
  * Sites were filtered to retain ONLY sub-populations with >= 15 years of
    active monitoring history across the 29-year horizon.
  * Outcome: 16 core biological sites passed this threshold.

Data Integrity Standards:
  * Numbers are verified pure numeric values.
  * Confirmed Zero Counts (surveyed, no eggs found) are explicitly kept as 0.0.
  * Unmonitored Years are kept as explicit NA gaps. MARSS requires these true
    NA placeholders to trigger its Kalman filter state estimation loops rather
    than treating missing data as local extinctions.

------------------------------------------------------------------------------
2. FILE REPOSITORY DIRECTORY MAP (WHICH FILE TO USE WHEN)
------------------------------------------------------------------------------
Look in this folder ('marss_results/biological/') for the following outputs:

[★] GO-TO MODELING FILE [★]
--> marss_matrix_y_logTransformed.rds
    What: A pure R matrix of log-transformed annual counts: log(Count + 1).
    Dimensions: 16 rows (Sites) by 29 columns (Years 1997-2025).
    R Use Case: Load with `readRDS()`. Pass directly to the MARSS model as 'y'.
    Why: Standardizes population variance and handles exponential scaling.

[ ] AUXILIARY FILE
--> marss_matrix_y_raw.rds
    What: Pure R numeric matrix of raw, untransformed egg mass counts.
    Dimensions: 16 rows x 29 columns.
    R Use Case: Load with `readRDS()`. Best for raw summary calculations.

[ ] SPREADSHEET BACKUP
--> marss_y_raw_counts_wide.csv
    What: Standard wide CSV version of the raw counts (Sites as rows, Years as headers).
    Use Case: Open in Excel to manually review data lines, zeros, or NAs.

[ ] SITE REFERENCE MAP
--> biological_site_metadata.csv
    What: Clean linkage map identifying the 16 passing Site IDs, their full names,
          their corresponding Watersheds, and Hydroperiod classifications.
    Use Case: Use this to construct your structural allocation matrix (Z matrix)
              when grouping sites by common watershed or breeding dynamics.

------------------------------------------------------------------------------
3. PIPELINE GRAPHICS & VISUALIZATIONS
------------------------------------------------------------------------------
--> matrix_data_availability_heatmap_3color.png
    A 3-color diagnostic tile sweep showing Missing Gaps (Gray), True Zeros (Orange),
    and Positive Counts (Green). Verifies that the model treats structural gaps
    correctly vs. active zero surveys.

--> biological_honest_trends.png
    A multi-panel faceted time-series line graph tracking population trajectories.
    Lines explicitly BREAK when hitting unmonitored years to maintain perfect
    scientific honesty regarding data blackouts.

==============================================================================
NEXT ARCHITECTURAL STEP: BUILDING THE MARSS DESIGN MATRICES (Z, R, Q, c)
==============================================================================
