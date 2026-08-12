# Data Dictionary

This document describes the active data objects and engineered climate features used by the CRLF MARSS pipeline. Exact source-data distribution permissions must be confirmed before public release.

## 1. Biological response matrix

Configured path at handoff:

```text
marss_results/biological/marss_matrix_y_14sites_logTransformed.rds
```

### Structure

- rows: monitoring sites
- columns: biological years
- sites: 14
- years: 1997–2025
- dimensions: 14 × 29

### Values

Annual egg-mass abundance transformed as:

```text
log(count + 1)
```

Interpretation:

- observed zero: surveyed with zero annual egg masses
- positive value: transformed observed annual abundance
- `NA`: no biological survey observation for that site-year

At handoff:

- 406 possible site-years
- 273 observed site-years
- 133 missing site-years

## 2. Site registry

```text
config/site_registry.csv
```

Expected core fields:

- `Site_ID`
- `Prefix`
- `Watershed`
- `Active`

### Active sites and watersheds

| Watershed | Sites |
|---|---|
| Laguna Salada | LS01, LS04, LS05, LS06, LS07, LS08, LS11 |
| Milagra Creek | MC01 |
| Redwood Creek | RC07, RC10, RC11 |
| Rodeo Lagoon | RL02 |
| Tennessee Valley | TV02 |
| Wilkins Gulch | WG01 |

## 3. PDSI master

Configured primary path at handoff:

```text
marss_results/covariates/watershed_pdsi_master_long.csv
```

A root-level fallback may also be supported by the loader depending on configuration.

At the validated handoff snapshot:

- six modeled watersheds
- historical coverage 1896–2026
- 131 annual rows per watershed
- no missing base Oct–Dec or Jan–Mar PDSI values in the validated historical series
- one row per watershed-year
- consecutive annual coverage

The long historical record is required because lagged/running features must be generated before filtering to 1997–2025.

## 4. Engineered climate features

### `PDSI_OctDec`
Contemporary Oct–Dec PDSI for the biological year.

### `PDSI_JanMar`
Contemporary Jan–Mar PDSI for the biological year.

### `PDSI_OctDec_RunMean1`
Equivalent to contemporary Oct–Dec value `t`.

### `PDSI_OctDec_RunMean2`
Mean Oct–Dec PDSI across `t` and `t-1`.

### `PDSI_OctDec_RunMean3`
Mean Oct–Dec PDSI across `t`, `t-1`, and `t-2`.

### `PDSI_OctDec_lag3`
Oct–Dec PDSI at `t-3`.

### `PDSI_JanMar_RunMean1`
Equivalent to contemporary Jan–Mar value `t`.

### `PDSI_JanMar_RunMean2`
Mean Jan–Mar PDSI across `t` and `t-1`.

### `PDSI_JanMar_RunMean3`
Mean Jan–Mar PDSI across `t`, `t-1`, and `t-2`.

### `PDSI_JanMar_lag3`
Jan–Mar PDSI at `t-3`.

### `PDSI_Interact`
Product of contemporary early and late seasonal PDSI:

```text
PDSI_OctDec * PDSI_JanMar
```

### `PDSI_Interact_lag3`
`t-3` value of the interaction feature as implemented by the feature builder.

## 5. Feature coverage requirement

MARSS covariate matrix `c` cannot contain missing values in the modeled biological window. The feature builder therefore performs missingness QA. At the locked development snapshot, all 12 PDSI features had zero missing values for 1997–2025.

Do not replace missing lagged climate values with zero. If a future feature cannot be constructed for the full biological window, resolve the scientific/data-support issue explicitly.

## 6. Model registry

```text
config/model_registry.csv
```

This is a scientific configuration table, not raw data. See `MODEL_REGISTRY_GUIDE.md`.

## 7. Pipeline settings

```text
config/pipeline_settings.csv
```

Important handoff values include:

- `PIPELINE_VERSION = 1.0.0`
- `MASTER_SEED = 20260810`
- `DEFAULT_BOOTSTRAPS = 500`
- `MARSS_KEM_MAXIT = 2000`
- `MARSS_BFGS_MAXIT = 1000`
- `STUDY_START_YEAR = 1997`
- `STUDY_END_YEAR = 2025`
- `RESPONSE_TRANSFORMATION = log(count + 1)`
- default `C` structure: site-specific
- default `Z`: identity
- default `B`: identity
- default `U`: unequal
- default `Q`: diagonal and unequal
- default `R`: zero

If the live CSV differs, the live CSV is authoritative and the difference should be documented in `CHANGELOG.md`.

## 8. Data distribution warning

Before uploading a public repository, confirm whether the biological and climate input files can be redistributed. If permissions are uncertain, keep source data out of Git and document:

- data owner/custodian
- source
- version/date
- expected local path
- required columns
- how an authorized collaborator obtains the file

Never publish sensitive site-location information simply because the analysis code references site IDs.
