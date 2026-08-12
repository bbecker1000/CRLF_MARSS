# GitHub Upload Steps

Use this only after the clean-session pipeline test and `tools/99_github_preflight.R` pass.

## 1. Copy the handoff documentation into the project

Follow `GITHUB_COPY_INSTRUCTIONS.txt` from the handoff bundle.

## 2. Review release decisions

Before a public push, resolve `docs/RELEASE_DECISIONS.md`, especially:

- repository visibility
- biological-data sharing permission
- sensitive site information
- license
- authorship/citation

## 3. Run the clean-session test

Restart R completely:

```r
setwd("F:/CRLF_MARSS")
source("00_run_full_pipeline.R")
```

Confirm zero pipeline errors and record the final run ID in `docs/HANDOFF_CHECKLIST.md`.

## 4. Run the preflight

```r
source("tools/99_github_preflight.R")
```

Review all large-file and privacy warnings.

## 5. Initialize Git if this directory is not already a repository

From Git Bash, PowerShell, or a terminal opened in `F:/CRLF_MARSS`:

```bash
git init
git branch -M main
```

If Git is already initialized, do not reinitialize merely for the handoff.

## 6. Inspect before staging

```bash
git status --short
```

Look specifically for:

- large `.rds` files
- raw/private data
- credentials/tokens
- temporary files
- repeated run/log directories

Do not proceed until the staged content is intentional.

## 7. Stage deliberately

A broad stage is acceptable only after `.gitignore` and preflight have been reviewed:

```bash
git add .
git status
```

Inspect the list again before committing.

## 8. First handoff commit

Example:

```bash
git commit -m "CRLF MARSS pipeline v1.0.0 handoff"
```

## 9. Connect the remote repository

After creating the repository under the appropriate personal, lab, or institutional GitHub account, add the remote using the repository URL supplied by GitHub:

```bash
git remote add origin <REPOSITORY_URL>
git remote -v
```

If `origin` already exists, inspect it before changing anything.

## 10. Push

```bash
git push -u origin main
```

If the remote contains an existing README/license/history, reconcile histories deliberately rather than force-pushing over them.

## 11. Create the release tag after verification

Once the pushed repository has been inspected and the release is considered locked:

```bash
git tag -a v1.0.0 -m "CRLF MARSS pipeline v1.0.0"
git push origin v1.0.0
```

Record the release commit hash in project records:

```bash
git rev-parse HEAD
```

## 12. What not to do

Do not:

- use `git add .` before reviewing `.gitignore`
- commit restricted biological/location data without permission
- commit API keys or credentials
- force-push over collaborators' history
- change the meaning of an existing `Model_ID` after release
- use Git history as the only archive for expensive binary model objects

## 13. Large fitted objects

If completed fits/bootstrap objects must be preserved, use the storage approach chosen in `docs/RELEASE_DECISIONS.md`. Keep ordinary Git history focused on source code, configuration, documentation, and lightweight reporting products.
