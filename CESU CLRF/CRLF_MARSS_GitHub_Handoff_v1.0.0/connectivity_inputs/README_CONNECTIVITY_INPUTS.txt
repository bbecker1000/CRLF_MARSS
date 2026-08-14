================================================================================
CRLF CONNECTIVITY INPUTS
README / USER MANUAL / DEVELOPMENT GAMEPLAN
Project: F:/CRLF_MARSS
Folder:  F:/CRLF_MARSS/connectivity_inputs
================================================================================

PURPOSE
-------
The connectivity_inputs folder is the connectivity-development workspace for
the California Red-Legged Frog (CRLF) MARSS project.

It stores the quality-assurance tables, source registries, ecological
crosswalk-development files, site metadata joins, and other intermediate
products needed to build a reproducible landscape-connectivity covariate.

This folder should NOT yet be interpreted as a finished connectivity model.

The intended progression is:

  validated frog locations
          +
  original county vegetation / impervious sources
          |
          v
  source and coordinate QA
          |
          v
  ecological class crosswalk
          |
          v
  resistance surface
          |
          v
  least-cost distance
          |
          v
  site connectivity / rescue potential
          |
          v
  site-level or site-year MARSS covariate


================================================================================
1. CURRENT STATUS
================================================================================

COMPLETED / WELL DOCUMENTED
---------------------------
- Original Marin and San Mateo GIS source layers were identified.
- Old merged "ThreeCounty" layers were explicitly excluded from authoritative
  model construction.
- Source feature counts, geometry, CRS, and classification fields were audited.
- Raw vegetation and impervious classes were inventoried.
- The validated pond/site dataset was audited.
- 72 pond/site records and 27 attribute fields were exported for review.
- Coordinate completeness, geometry, habitat, watershed, and datum fields were
  checked.
- The final 14 model sites were joined to available habitat metadata.
- San Mateo wetland, aquatic, riparian, tidal, water, and borderline classes
  were reviewed.
- San Mateo impervious, road, building, and site-overlay QA was completed.
- Broad spatial-folder inventory files were created.

NOT YET LOCKED
--------------
- Final resistance-value crosswalk.
- Final common analysis CRS/grid.
- Final static resistance raster.
- Final site snapping/anchoring rules.
- Final 10 m -> 50 m aggregation method.
- Final dynamic PDSI resistance model.
- Final least-cost path matrix.
- Final connectivity-decay parameter alpha.
- Final site-year connectivity table.
- Final MARSS connectivity candidate set.

HANDOFF DESCRIPTION
-------------------
Treat connectivity_inputs as a:
  "validated spatial-input and methodology-development workspace."

Do not describe it as a completed connectivity analysis.


================================================================================
2. RELATIONSHIP TO data/spatial
================================================================================

Original/heavy GIS files are primarily stored under:

  F:/CRLF_MARSS/data/spatial/

Connectivity-specific review products are stored under:

  F:/CRLF_MARSS/connectivity_inputs/

Conceptually:

  data/spatial/
    = original downloads, geodatabases, rasters, and historical derived files

  connectivity_inputs/
    = QA, source provenance, ecological interpretation, site preparation, and
      future connectivity-specific outputs

The final connectivity model should always be traceable back to the original
county sources rather than to an undocumented merged product.


================================================================================
3. IMPORTANT CONFIRMED FOLDER CONTENTS
================================================================================

F:/CRLF_MARSS/connectivity_inputs/
|
|-- CRLF_14site_Locations_With_Habitat_Metadata.gpkg
|
|-- crosswalks/
|   |-- Marin_Raw_Class_Value_Counts.csv
|   |-- SanMateo_Raw_Class_Value_Counts.csv
|   |-- Marin_Impervious_Raw_Value_Counts.csv
|   |-- All_Original_Raw_Class_Value_Counts.csv
|   |-- SanMateo_Wetland_Aquatic_Water_Borderline_Candidates.csv
|   |-- SanMateo_Five_Borderline_Class_Audit.csv
|   `-- SanMateo_Ambiguous_Water_Related_Class_Audit.csv
|
`-- qa/
    |-- CRLF_Original_Source_Layer_Registry.csv
    |-- CRLF_Original_Source_Spatial_Summary.csv
    |-- CRLF_Excluded_Previous_Unified_Layers.csv
    |-- File_Geodatabase_Layer_Audit.csv
    |
    |-- SanMateo_Validated_Ponds_All_Attributes.csv
    |-- SanMateo_Validated_Ponds_First20.csv
    |-- SanMateo_Validated_Ponds_Value_Summary.csv
    |-- SanMateo_Validated_Ponds_Geometry_Summary.csv
    |-- SanMateo_Validated_Ponds_Component_Counts.csv
    |-- SanMateo_Validated_Ponds_Coordinate_Completeness.csv
    |
    |-- CRLF_14site_Habitat_Metadata_Join.csv
    |-- CRLF_14site_Unmatched_Metadata_Sites.csv
    |-- CRLF_14site_Metadata_Match_Summary.csv
    |
    |-- spatial_folder_audit/
    |   `-- broad spatial inventory / candidate-data tables
    |
    `-- san_mateo_vegetation_audit/
        |-- 05_SanMateo_Impervious_Field_Summary.csv
        |-- 06_SanMateo_Impervious_Consistency_Summary.csv
        |-- 07_SanMateo_Impervious_Threshold_Counts.csv
        |-- 08_SanMateo_Model_Site_Polygon_Overlay.csv
        |-- 09_SanMateo_Model_Site_Overlay_Issues.csv
        |-- 11_SanMateo_Candidate_Category_Summary.csv
        `-- SanMateo_Audit_Key_Results.txt


================================================================================
4. AUTHORITATIVE ORIGINAL SOURCES
================================================================================

A. MARIN LIFEFORM
-----------------
Geodatabase:
  F:/CRLF_MARSS/data/spatial/Lifeform.gdb/MARIN_LIFEFORM_9_30.gdb

Layer:
  MARIN_LIFEFORM_9_30

Features:
  28,629

Geometry:
  MULTIPOLYGON

CRS:
  EPSG:6420
  NAD83(2011) / California zone 3 (ftUS)

Primary classification field:
  LIFEFORM_18


B. SAN MATEO FINE-SCALE VEGETATION
----------------------------------
Geodatabase:
  F:/CRLF_MARSS/data/spatial/San_Mateo.gdb/San_Mateo.gdb

Layer:
  san_mateo_fine_scale_veg_6_14_22

Features:
  97,580

Geometry:
  MULTIPOLYGON

CRS:
  EPSG:6420
  NAD83(2011) / California zone 3 (ftUS)

Important fields:
  MAP_CLASS_18
  LIFEFORM_18
  FOREST_LIFEFORM_18
  PERVIOUS_18
  IMPERVIOUS_18
  PAVED_RD_18
  DIRT_RD_18
  OTHER_IMPERV_18
  BUILDING_18
  ACRES
  SOURCE
  URBAN_WINDOW


C. MARIN IMPERVIOUS
-------------------
Geodatabase:
  F:/CRLF_MARSS/data/spatial/
  Impervious_Delivery_8_20_Marin.gdb/
  Impervious_Delivery_8_20_Marin.gdb

Layer:
  Marin_Impervious_2018_8_20_v11f

Features:
  228,752

Geometry:
  MULTIPOLYGON / MULTISURFACE

CRS:
  EPSG:2227
  NAD83 / California zone 3 (ftUS)

Important raw classes:
  Other Paved Surface
  Building
  Other Dirt/Gravel Surface
  Paved Road
  Dirt/Gravel Road

IMPORTANT CRS NOTE:
The Marin impervious layer is EPSG:2227 while the Marin lifeform and San Mateo
vegetation layers are EPSG:6420. A final resistance workflow must explicitly
transform all layers to one common analysis CRS before overlay/rasterization.


================================================================================
5. WHY THE OLD UNIFIED LAYERS ARE NOT AUTHORITATIVE
================================================================================

Excluded/review-only layers:

  ThreeCountyUnified
  ThreeCountyLifeform_Merge

Location:
  F:/CRLF_MARSS/data/spatial/UNIFIED_VEG_MAP.gdb/UNIFIED_VEG_MAP.gdb

Reason:
  These were previously merged products whose provenance and reclassification
  decisions should not be assumed.

They may remain useful for:
  historical comparison
  sensitivity checks
  visual reference

They should NOT be used as the unquestioned source for the final resistance
model.

This decision is recorded in:

  qa/CRLF_Excluded_Previous_Unified_Layers.csv


================================================================================
6. SOURCE REGISTRY AND SPATIAL SUMMARY
================================================================================

qa/CRLF_Original_Source_Layer_Registry.csv
  Locks the authoritative source paths and exact internal layer names.

qa/CRLF_Original_Source_Spatial_Summary.csv
  Records:
    feature count
    geometry type
    EPSG
    CRS name

These are key handoff files because they answer:
  "Which exact GIS files and layers did the project intend to use?"


================================================================================
7. BROAD SPATIAL-FOLDER AUDIT
================================================================================

The broader spatial audit reported:

  239 regular files
  8 .gdb folders detected
  6 valid vector layers
  23 raster files successfully audited
  0 ZIP archives at the time of audit

Main connectivity-candidate table:

  qa/spatial_folder_audit/06_Potentially_Useful_Spatial_Data.csv

Candidate/historical products identified included:

  Marin_Dynamic_Cost_PDSI_3.tif
  Regional_D_dry_10m.tif
  Regional_D_wet_10m.tif
  San_Mateo_D_dry_10m.tif
  San_Mateo_D_wet_10m.tif
  San_Mateo_Dynamic_Cost_FinalState.tif
  Three_County_Master_Friction_10m.tif
  Macro_Habitat_Friction_10m.tif
  Marin_Macro_Habitat_Friction_10m.tif
  Marin_Macro_Habitat_Friction_GroundTruthed_10m.tif
  San_Mateo_Validated_Ponds.shp
  several San Mateo terrain / lidar-derived rasters

IMPORTANT:
These were flagged as potentially useful, not automatically approved as final
inputs. Derived friction/dynamic rasters require provenance review before reuse.

================================================================================
8. VALIDATED POND / SITE AUDIT
================================================================================

The validated pond dataset contains:

  72 records
  27 attribute fields

Main attribute export:

  qa/SanMateo_Validated_Ponds_All_Attributes.csv

Important fields recovered from the source include:

  LoctnID
    Site/location identifier.

  Dscrptn
    Site description.

  AcCRLFB
    CRLF-related attribute from the source dataset.

  Watrshd
    Watershed.

  WatrRgm
    Water regime.

  Hbtt_ty
    Habitat type.

  County
    County.

  Project
    Project identifier.

  Ltc_Lnt
    Lentic/lotic classification.

  StartLt, StartLn
  StopLat, StopLon
    Coordinate fields where populated.

  StpUTMX, StpUTMY
    UTM coordinate fields where populated.

  UtmZone
    UTM zone.

  Datum
    Coordinate datum.

  Elevatn
    Elevation.

  Slope
    Slope-related field.

  Commnts
    Site comments.


CONFIRMED ATTRIBUTE SUMMARY
---------------------------
County:
  Marin          53
  San Mateo      18
  San Francisco   1

Water regime:
  seasonal    41
  perennial   30
  missing      1

Habitat examples:
  pond
  marsh
  stream
  ditch
  meadow
  spring
  lagoon
  road
  slough

Datum:
  NAD83    63
  WGS84     4
  missing   5


WHY THIS MATTERS
----------------
Least-cost connectivity is sensitive to source/target node location.

A site placed:
  offshore
  on a road
  outside a valid raster
  on the wrong vegetation polygon
  or on a polygon sliver

can produce a badly distorted cost path.

Therefore pond/site QA is an essential modeling step, not clerical cleanup.


================================================================================
9. COORDINATE / GEOMETRY QA
================================================================================

Confirmed files:

  qa/SanMateo_Validated_Ponds_Coordinate_Completeness.csv
  qa/SanMateo_Validated_Ponds_Geometry_Summary.csv
  qa/SanMateo_Validated_Ponds_Component_Counts.csv

The coordinate-completeness audit found:

  StartLt: 0 present / 72 missing
  StartLn: 0 present / 72 missing
  StopLat: 0 present / 72 missing
  StopLon: 0 present / 72 missing
  StpUTMX: 17 present / 55 missing
  StpUTMY: 17 present / 55 missing
  UtmZone: 66 present / 6 missing
  Datum: 67 present / 5 missing

Interpretation:
  Do not assume visible coordinate attribute fields are the authoritative
  location source.

The spatial geometry itself and other validated location records may be more
important than the empty Start/Stop latitude-longitude attributes.


================================================================================
10. FINAL 14-SITE HABITAT METADATA JOIN
================================================================================

Confirmed files:

  qa/CRLF_14site_Habitat_Metadata_Join.csv
  qa/CRLF_14site_Unmatched_Metadata_Sites.csv
  qa/CRLF_14site_Metadata_Match_Summary.csv

Spatial output:

  CRLF_14site_Locations_With_Habitat_Metadata.gpkg

The metadata join reported:

  13 sites matched to metadata
   1 site unmatched

This means the final 14 MARSS sites were substantially linked to the validated
habitat/site inventory, but one mismatch remained at that stage.

Before final connectivity analysis:
  identify the unmatched site,
  document the resolution,
  validate the final 14 connectivity nodes,
  and preserve any approximate-coordinate warning such as LS11.


================================================================================
11. crosswalks/ DIRECTORY
================================================================================

The crosswalks directory is where raw GIS classification is translated into
biologically meaningful connectivity categories.

Intended logic:

  raw source class
       |
       v
  ecological interpretation
       |
       v
  candidate resistance category
       |
       v
  reviewed final resistance class
       |
       v
  numeric resistance

Separating class interpretation from resistance values is important.

It allows collaborators to review:
  "What habitat does this source class represent?"

separately from:
  "How costly should that habitat be for frog movement?"


================================================================================
12. MARIN RAW CLASS INVENTORY
================================================================================

File:
  crosswalks/Marin_Raw_Class_Value_Counts.csv

Purpose:
  Lists actual raw Marin LIFEFORM_18 values and counts.

Important classes found include:
  Developed
  Native Shrub
  Herbaceous
  Native Forest
  Freshwater Wetland
  Shrub Fragment
  Water
  Forest Fragment
  Tidal Wetland
  Non-native Forest
  Channel
  Mudflat

Why:
  The final resistance crosswalk should be built from actual observed class
  names rather than a remembered or simplified class list.


================================================================================
13. SAN MATEO RAW CLASS INVENTORY
================================================================================

File:
  crosswalks/SanMateo_Raw_Class_Value_Counts.csv

Broad LIFEFORM_18 categories include:
  Forest
  Shrub
  Developed
  Herbaceous
  Riparian Forest
  Tidal Wetland
  Mudflat
  Water
  Ag
  Freshwater Herbaceous Wetland
  Barren and Sparsely Vegetated
  Major Road
  Eel Grass

San Mateo also contains detailed MAP_CLASS_18 vegetation classes.

This detail is useful because:
  freshwater wetland
  riparian habitat
  tidal habitat
  marine vegetation
  developed land
  and uplands

should not automatically receive the same movement resistance.


================================================================================
14. MARIN IMPERVIOUS CLASS INVENTORY
================================================================================

File:
  crosswalks/Marin_Impervious_Raw_Value_Counts.csv

Confirmed raw classes:
  Other Paved Surface
  Building
  Other Dirt/Gravel Surface
  Paved Road
  Dirt/Gravel Road

These classes are particularly important for:
  barrier assignment
  developed-land overrides
  preserving narrow road features


================================================================================
15. COMBINED SOURCE-CLASS INVENTORY
================================================================================

File:
  crosswalks/All_Original_Raw_Class_Value_Counts.csv

Purpose:
  Combines raw class values from:
    Marin lifeform
    San Mateo vegetation
    Marin impervious

This is a useful master lookup when constructing the final resistance crosswalk.


================================================================================
16. SAN MATEO WETLAND / AQUATIC / BORDERLINE REVIEW
================================================================================

Confirmed files:

  crosswalks/SanMateo_Wetland_Aquatic_Water_Borderline_Candidates.csv

  crosswalks/SanMateo_Five_Borderline_Class_Audit.csv

  crosswalks/SanMateo_Ambiguous_Water_Related_Class_Audit.csv


The detailed audit identified 31 candidate classes spanning:
  freshwater aquatic vegetation
  freshwater marsh/wet meadow
  riparian forest
  mudflat/dry pond bottom
  tidal wetland
  eel grass
  water
  ambiguous shrub/herbaceous classes


Examples of freshwater/wetland classes:
  Arid West Freshwater Emergent Marsh Group
  Vancouverian Freshwater Wet Meadow & Marsh Group
  Western North American Freshwater Aquatic Vegetation Macrogroup

Examples of riparian classes:
  Salix lasiolepis Alliance
  Acer macrophyllum - Alnus rubra Alliance
  Cornus sericea - Salix association
  Populus trichocarpa Alliance
  several additional willow / alder / cottonwood classes

Other classes:
  Mudflat/Dry Pond Bottom Mapping Unit
  tidal wetland alliances
  Zostera eel grass
  Water


FIVE EXPLICIT BORDERLINE GROUPS
-------------------------------
The audit deliberately separated:

  Gaultheria shallon - Rubus (ursinus) Alliance
  Rubus spectabilis - Morella californica Alliance
  Conium maculatum - Foeniculum vulgare
  Rubus armeniacus
  Calamagrostis nutkaensis

Why:
  Their resistance classification should be an explicit ecological decision,
  not an automatic side effect of a broad vegetation label.


================================================================================
17. SAN MATEO IMPERVIOUS / SITE-OVERLAY QA
================================================================================

Folder:

  qa/san_mateo_vegetation_audit/

Important confirmed outputs:

05_SanMateo_Impervious_Field_Summary.csv
  Summarizes impervious-related fields.

06_SanMateo_Impervious_Consistency_Summary.csv
  Checks consistency among impervious fields.

07_SanMateo_Impervious_Threshold_Counts.csv
  Counts polygons meeting impervious/road/building thresholds.

08_SanMateo_Model_Site_Polygon_Overlay.csv
  Documents vegetation polygon(s) associated with model sites.

09_SanMateo_Model_Site_Overlay_Issues.csv
  Flags overlay issues.

11_SanMateo_Candidate_Category_Summary.csv
  Summarizes ecological candidate categories.

SanMateo_Audit_Key_Results.txt
  Combined review report.


CONFIRMED THRESHOLD COUNTS
--------------------------
Any impervious > 0:    35,925 polygons
Impervious >= 10%:     14,697
Impervious >= 25%:      6,592
Impervious >= 50%:      3,236
Paved road > 0:        12,752
Dirt road > 0:          9,697
Building > 0:           8,299
Other impervious > 0:  22,132

Why:
  Development is not represented by one simple polygon category.
  Impervious percentages, roads, and buildings may need to modify or override
  vegetation-based resistance.


================================================================================
18. RESISTANCE-SURFACE GAMEPLAN
================================================================================

Recommended sequence:

  authoritative source vectors
          |
          v
  standardize CRS / repair geometry
          |
          v
  apply ecological crosswalk
          |
          v
  assign base habitat resistance
          |
          v
  apply road / impervious / hard-barrier logic
          |
          v
  rasterize to one fine common grid
          |
          v
  validate site cells
          |
          v
  optionally aggregate for computation
          |
          v
  static resistance surface
          |
          v
  least-cost paths
          |
          v
  static connectivity
          |
          v
  dynamic climate modification
          |
          v
  annual connectivity
          |
          v
  MARSS connectivity covariate


================================================================================
19. WORKING ECOLOGICAL RESISTANCE CONCEPT
================================================================================

The working project concept has been approximately:

  freshwater / freshwater wetland / riparian
      very low resistance

  ordinary terrestrial upland
      moderate resistance

  developed
      high resistance

  major roads / strong hardscape
      very high resistance

  tidal wetland / mudflat
      special higher-cost class requiring explicit ecological review

  open marine
      hard barrier / unavailable

  eel grass / clearly marine habitat
      marine / unavailable for terrestrial frog movement


Provisional numeric values discussed during development were approximately:

  freshwater / wetland / riparian = 1
  terrestrial upland              = 5
  developed                       = 25
  major road                      = 100
  tidal wetland / mudflat         = special high-cost class
  open marine                     = NA / impassable

IMPORTANT:
These values are a WORKING MODEL ASSUMPTION.

They are not yet a locked empirical resistance scale.

The final values should be stored in a documented CSV/config file and
sensitivity tested.


================================================================================
20. ROAD / IMPERVIOUS OVERRIDE GAMEPLAN
================================================================================

A broad low-cost vegetation polygon may contain:
  pavement
  road
  building
  other hardscape

Therefore vegetation alone may be insufficient.

Conceptual priority could be:

  marine / true hard barrier
          >
  major road / major paved barrier
          >
  building / strong impervious
          >
  developed base class
          >
  vegetation base resistance

The exact hierarchy must be finalized and documented.

Reason:
  narrow high-cost barriers should not disappear simply because they occur
  inside a large low-cost vegetation polygon.


================================================================================
21. COMMON CRS / GRID GAMEPLAN
================================================================================

All source data must be brought to one explicit projected analysis CRS.

The final raster specification should document:

  CRS / EPSG
  extent
  resolution
  origin
  cell alignment
  NoData definition
  marine-mask logic

The raster template is part of the scientific model and should be reproducible.


================================================================================
22. 10 m -> 50 m COMPUTATIONAL STRATEGY
================================================================================

A working plan was:

  fine resistance surface ~10 m
          |
          v
  aggregate 5 x 5 cells
          |
          v
  ~50 m least-cost analysis surface

One proposed aggregation rule:
  maximum resistance within each 5 x 5 block

Why maximum:
  averaging could dilute a narrow road or strong barrier.

Example:
  one high-cost road cell surrounded by low-cost upland could become a
  moderate-cost cell under mean aggregation.

Maximum aggregation preserves the barrier.

IMPORTANT:
This remains a working methodological decision.

Before locking it:
  compare alternatives,
  inspect representative roads,
  inspect narrow aquatic corridors,
  verify that preserving barriers does not destroy biologically important
  low-cost movement corridors.


================================================================================
23. SITE NODE / SNAPPING GAMEPLAN
================================================================================

Every final model site must be placed on a valid movement cell.

Potential problems:
  site falls on NoData
  site falls in marine water
  site falls on a road cell
  coordinate is approximate
  rasterization shifts habitat
  point is just outside the correct polygon

Recommended approach:

  retain original coordinate
        |
        v
  inspect underlying resistance
        |
        v
  if invalid, snap to nearest defensible valid cell
        |
        v
  save original + snapped locations + distance + reason

Never silently move a biological site.

Recommended future QA table:

  CRLF_14site_Connectivity_Node_QA.csv

Suggested fields:
  site_id
  original_x
  original_y
  snapped_x
  snapped_y
  snap_distance_m
  original_resistance
  snapped_resistance
  snap_reason
  qa_status


================================================================================
24. HARD-BARRIER GAMEPLAN
================================================================================

Open marine water should generally be treated differently from ordinary
high-cost terrestrial habitat.

Why:
  a least-cost algorithm can otherwise create a mathematically cheap but
  biologically implausible ocean crossing.

Working rule:
  true hard barrier -> NoData / infinite cost -> no connection

The Golden Gate/open marine setting is an example where this matters.

Tidal wetland should NOT automatically be equated with open marine.
It requires separate ecological treatment.


================================================================================
25. DYNAMIC PDSI-DEPENDENT RESISTANCE
================================================================================

A future extension was designed to allow terrestrial movement resistance to
vary among years.

Biological idea:
  wet years may increase terrestrial movement opportunity;
  dry years may reduce it.

A provisional bounded multiplier discussed during development was:

  multiplier =
    min(
      2,
      max(
        0.5,
        exp(-0.35 * z_PDSI)
      )
    )

Interpretation:
  wetter-than-normal climate -> lower terrestrial resistance
  drier-than-normal climate  -> higher terrestrial resistance

Bounds:
  0.5 to 2

IMPORTANT:
This modifier should apply only to ecologically appropriate classes.

Wet PDSI should NOT make:
  roads
  buildings
  open ocean

become easy movement habitat.

The formula remains a working assumption until formally locked and sensitivity
tested.

================================================================================
26. EXISTING DERIVED RASTERS: REVIEW BEFORE REUSE
================================================================================

The spatial audit found several derived cost/friction/dynamic rasters in
data/spatial, including:

  Marin_Dynamic_Cost_PDSI_3.tif
  Regional_D_dry_10m.tif
  Regional_D_wet_10m.tif
  San_Mateo_D_dry_10m.tif
  San_Mateo_D_wet_10m.tif
  San_Mateo_Dynamic_Cost_FinalState.tif
  Three_County_Master_Friction_10m.tif
  Macro_Habitat_Friction_10m.tif
  Marin_Macro_Habitat_Friction_10m.tif
  Marin_Macro_Habitat_Friction_GroundTruthed_10m.tif

These may preserve useful prior work.

However:

  FILE EXISTS
      does NOT mean
  FILE IS THE FINAL AUTHORITATIVE INPUT

Before reusing one, recover:

  source-layer provenance
  creating script
  crosswalk used
  resistance values
  CRS
  resolution
  extent
  NoData rules
  road treatment
  marine treatment
  dynamic-climate formula

Until verified, label these:
  REVIEW / LEGACY / SENSITIVITY PRODUCTS.


================================================================================
27. LEAST-COST PATH GAMEPLAN
================================================================================

After the static resistance surface is locked:

For each modeled-site pair i,j:

  resistance raster
       |
       v
  accumulated least-cost distance
       |
       v
  d_ij

The result should be a pairwise 14-site cost-distance matrix.

Required QA:

  diagonal distances = 0
  symmetry checked if resistance is symmetric
  disconnected pairs explicitly identified
  unexpected NA / infinite paths investigated
  representative paths mapped
  paths visually checked around:
    roads
    development
    wetlands
    riparian corridors
    coastlines
    marine barriers

Recommended outputs:

  CRLF_14site_LCP_CostDistance_Static.csv
  CRLF_14site_LCP_Path_QA.gpkg
  CRLF_14site_LCP_Disconnected_Pairs.csv


================================================================================
28. COST DISTANCE -> CONNECTIVITY
================================================================================

A working transformation is:

  connectivity_ij = exp(-alpha * d_ij)

where:

  d_ij
    least-cost distance between sites i and j

  alpha
    dispersal-decay parameter

Set:

  connectivity_ii = 0

A site-level connectivity index can then be:

  S_i = sum_j connectivity_ij

Interpretation:

  high S_i
    stronger potential landscape connection / rescue opportunity

  low S_i
    stronger isolation


ALPHA IS IMPORTANT
------------------
Alpha determines how quickly connectivity declines with cost distance.

It should be:
  based on movement/dispersal literature,
  calibrated,
  or sensitivity tested.

Do not choose alpha simply because one map looks visually appealing.


================================================================================
29. STATIC VS DYNAMIC CONNECTIVITY
================================================================================

STATIC CONNECTIVITY
-------------------
One fixed landscape resistance surface.

Question:
  Which ponds are structurally isolated or well connected under the mapped
  landscape?

Advantages:
  simpler
  easier to validate
  useful baseline
  less computationally expensive

Recommended:
  finish this FIRST.


DYNAMIC CONNECTIVITY
--------------------
Annual PDSI modifies selected terrestrial resistance classes.

Question:
  Does potential rescue/recolonization vary between wet and dry years?

Output would be:
  site x year connectivity
  1997-2025

This is the more direct version of the climate-dependent rescue hypothesis,
but it should be built only after static connectivity is trusted.


================================================================================
30. CONNECTION TO THE MARSS PROJECT
================================================================================

Current PDSI models ask:

  Does hydroclimate affect annual site-level egg-mass dynamics?

Connectivity models would ask:

  Does landscape isolation / movement opportunity affect persistence or
  recovery?

A future combined question is:

  Are climate-driven breeding failures more persistent at isolated sites,
  while better-connected sites show greater rescue or recolonization potential?

This fits the broader biological framework:

  persistence
      =
  breeding/hydroclimatic conditions
      x
  landscape connectivity / rescue potential


IMPORTANT PIPELINE ARCHITECTURE NOTE
------------------------------------
The current MARSS climate builder is watershed-oriented.

Connectivity will probably be:
  site-level
or
  site-year-level.

Do not force connectivity into the existing watershed c/C layout only because
that code already exists.

Correct future approach:
  extend the feature/model-spec layer to support site-scale predictors,
  while retaining the same registry-driven fit, diagnostic, bootstrap, and
  model-selection framework.


================================================================================
31. POSSIBLE FUTURE CONNECTIVITY HYPOTHESES
================================================================================

These are suggested future model families, not current fitted models.

C0 -- No Connectivity
  Baseline without connectivity.

C1 -- Static Connectivity
  Does structural landscape connectivity affect egg-mass abundance?

C2 -- Dynamic Connectivity
  Does annual climate-dependent connectivity affect egg-mass abundance?

C3 -- PDSI + Static Connectivity
  Do hydroclimate and long-term isolation independently affect abundance?

C4 -- PDSI + Dynamic Connectivity
  Do climate conditions and annual movement opportunity jointly affect
  abundance?

C5 -- Climate x Connectivity
  Are climate effects stronger or more persistent at isolated sites?

These should be defined as a new coherent Candidate_Set.

Do not automatically mix their Akaike weights with the existing PDSI-only
candidate set.


================================================================================
32. RECOMMENDED NEXT STEPS
================================================================================

STEP 1
  Inventory the CURRENT contents of:
    F:/CRLF_MARSS/connectivity_inputs/
    F:/CRLF_MARSS/data/spatial/

STEP 2
  Find the creating scripts for existing friction/dynamic rasters.

STEP 3
  Resolve the 14-site metadata mismatch and lock the connectivity nodes.

STEP 4
  Select one common analysis CRS and raster template.

STEP 5
  Finish a documented ecological resistance crosswalk.

STEP 6
  Determine how San Francisco / any remaining geographic gaps are handled.

STEP 7
  Lock road / impervious override logic.

STEP 8
  Create the static fine-resolution resistance raster.

STEP 9
  QA:
    class coverage
    NoData
    site cells
    roads
    coastlines
    wetlands
    marine barriers

STEP 10
  Evaluate 10 m -> 50 m aggregation.

STEP 11
  Compute static pairwise least-cost distances.

STEP 12
  Select/sensitivity-test alpha.

STEP 13
  Create static site connectivity.

STEP 14
  Validate static connectivity biologically and spatially.

STEP 15
  Implement annual PDSI-dependent resistance.

STEP 16
  Compute annual connectivity for 1997-2025.

STEP 17
  Create a clean site-year connectivity feature table.

STEP 18
  Extend the modular MARSS feature builder for site/site-year predictors.

STEP 19
  Add connectivity hypotheses to model_registry.csv.

STEP 20
  Use the existing generic MARSS fit / diagnostics / selection pipeline.


================================================================================
33. RECOMMENDED FUTURE CONNECTIVITY FOLDERS
================================================================================

As the analysis matures, expand connectivity_inputs to:

connectivity_inputs/
|
|-- README_CONNECTIVITY_INPUTS.txt
|
|-- config/
|   |-- resistance_crosswalk_v1.csv
|   `-- connectivity_settings.csv
|
|-- nodes/
|   |-- CRLF_14site_Connectivity_Nodes.gpkg
|   `-- CRLF_14site_Connectivity_Node_QA.csv
|
|-- crosswalks/
|   `-- [current audit/crosswalk files]
|
|-- resistance/
|   |-- CRLF_Static_Resistance_10m.tif
|   |-- CRLF_Static_Resistance_50m.tif
|   `-- resistance_raster_QA.csv
|
|-- lcp/
|   |-- CRLF_14site_LCP_CostDistance_Static.csv
|   |-- CRLF_14site_LCP_Path_QA.gpkg
|   `-- CRLF_14site_LCP_Disconnected_Pairs.csv
|
|-- connectivity/
|   |-- CRLF_14site_Static_Connectivity.csv
|   `-- CRLF_14site_Annual_Dynamic_Connectivity_1997_2025.csv
|
`-- qa/
    `-- [current and future QA outputs]


================================================================================
34. HANDOFF RULES
================================================================================

DO NOT:
  use ThreeCountyUnified as an unquestioned source;
  use ThreeCountyLifeform_Merge as an unquestioned source;
  assume every raster in data/spatial is final;
  silently change CRS;
  silently move/snap model sites;
  average away road barriers without checking;
  treat tidal wetland as identical to freshwater wetland;
  treat marine water as ordinary high-cost terrestrial habitat;
  let wet-year PDSI make roads/ocean low cost;
  choose alpha without documenting the rationale;
  insert site-level connectivity into a watershed-scale predictor structure
  without updating the architecture properly.

DO:
  preserve authoritative source paths;
  keep source registries;
  document every crosswalk decision;
  retain QA outputs;
  keep original and snapped node coordinates;
  finish and validate static connectivity before dynamic connectivity;
  sensitivity-test resistance values and alpha;
  treat future connectivity models as a documented new model family.


================================================================================
35. CURRENT BOTTOM LINE
================================================================================

The connectivity_inputs folder contains a substantial, useful foundation for a
future CRLF landscape-connectivity / rescue-effect analysis.

The strongest completed pieces are:

  authoritative county-source identification
  source CRS/geometry QA
  raw class inventories
  validated pond/site attribute audit
  final-14-site habitat metadata join
  San Mateo wetland/aquatic/riparian class review
  impervious/road QA
  model-site polygon overlay QA
  broad spatial-data inventory
  explicit exclusion of poorly documented old merged layers

The remaining scientific/computational task is to convert those audited inputs
into one reproducible resistance model, then derive static and potentially
dynamic site connectivity for use in MARSS.

Recommended handoff wording:

  "Spatial-source auditing and resistance-model development are well advanced.
   The final resistance surface, least-cost connectivity matrix, and MARSS
   connectivity covariate remain to be finalized and sensitivity tested."

================================================================================
END OF README_CONNECTIVITY_INPUTS.txt
================================================================================
