# Release Decisions Requiring Human Confirmation

The computational pipeline can be prepared automatically, but these items require project-owner/PI/institutional decisions before a public GitHub release.

## 1. Repository visibility

Choose:

- public
- private
- institutional/internal

Do not assume public release is permitted merely because the code is ready.

## 2. Data-sharing permissions

Confirm whether the biological response data, site identifiers, climate extracts, and any location information can be redistributed.

Questions to resolve:

- Who owns/custodies the CRLF monitoring data?
- Are exact site locations sensitive?
- Can annual egg-mass data be posted publicly?
- Can the PDSI-derived watershed table be redistributed?
- Is attribution or a data-use agreement required?

Until resolved, source data should remain outside the public repository.

## 3. License

Choose a software/documentation license with the PI/institution as appropriate. Do not add a license by default without confirming desired reuse terms.

Common software choices include MIT, BSD-3-Clause, GPL-3.0, or an institutional alternative, but the project owner should decide.

## 4. Authors and contributors

Confirm the names and ordering to acknowledge in the repository and any `CITATION.cff` file.

Potential roles to document include:

- analysis/pipeline author
- PI/advisors
- monitoring-data contributors
- climate-data source
- collaborators who developed biological hypotheses

## 5. Citation

Decide whether the repository should cite:

- a thesis/capstone
- manuscript
- Zenodo DOI
- GitHub release
- institutional data product

A `CITATION.cff` file is best created after this is settled.

## 6. Large analysis objects

Decide where to preserve expensive binary products such as completed bootstrap objects:

- institutional storage
- Box/Drive
- OSF
- Zenodo release asset
- GitHub Release / Git LFS if appropriate

Normal Git history is not ideal for large regenerable `.rds` objects.

## 7. Final results status

The code repository can be released independently of a final biological manuscript. If model inference is still evolving, label current results as an analysis snapshot rather than a final ecological conclusion.
