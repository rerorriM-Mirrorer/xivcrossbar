# TESTING.md

## Package layout convention — 2026-10-16

- **Repository:** Keep `WORKFLOW.md` and `TESTING.md` at the repository root.
- **Testing ZIPs:** Include both inside the installable addon folder alongside the README and code. For patch/test-only bundles without an addon folder, place both next to the delivered files. No redundant outer ZIP-root copies.
- **Reference commit:** [`aa2eb8b`](https://github.com/rerorriM-Mirrorer/xivcrossbar/commit/aa2eb8b247118baf7d32f7994e3b54670f2a932a).
- **Verification:** Documentation only; no game code changed and no in-game tests performed for this instruction update.
- **History:** Previous ZIP-root conventions remain below as historical records, with dated corrections where they were stated as current instructions.

Read this first when preparing or evaluating a development/testing batch. This is a cumulative, project-specific development record kept at the repository ~~and testing-package~~ root alongside `WORKFLOW.md`. **Correction (2026-10-16):** In testing packages, put both guides alongside the addon or patch/test files, not at the outer ZIP root.

## Current testing batch — documentation adoption (2026-10-13)

- **Project:** XIVCrossbar (`rerorriM-Mirrorer/xivcrossbar`).
- **Batch:** Documentation-only adoption; no addon testing package or executable changes.
- **Starting default-branch commit:** `15d8381dfad0f9efdb84fe2d24655afc150faec4` (`master`).
- **Documents:** Added `WORKFLOW.md` and `TESTING.md`.
- **Reference:** [NPCMirror consolidated workflow](https://github.com/rerorriM-Mirrorer/ffxi-NPCmirror/blob/main/WORKFLOW.md).
- **Verification:** Inspect that the two files are at repository root, internal section links resolve, historical documents are preserved in Git, and only Markdown files change.
- **In-game testing:** Not performed for documentation-only adoption. Do not interpret this as validation of addon behavior.

- **Recorded migration commit:** [`9a6fc11`](https://github.com/rerorriM-Mirrorer/xivcrossbar/commit/9a6fc1186ff061232a18fbfc4ca9375c6a4c73e9).
- **Verified result:** Git comparison against the recorded starting commit lists Markdown changes only; `WORKFLOW.md` and `TESTING.md` exist at the repository root. No Lua source paths changed.

## Tests for the next functional batch

Document the requested change, step-by-step in-game checks with expected outcomes, regression checks, and observed results before delivering the next testing package. For UI or multibox behavior, identify character/client and screen resolution when relevant.

## Previous tests and checks

Existing historical tests have **not** been reconstructed or verified during this documentation migration. Preserve any existing tests, archives, and known-good reports; enter prior results only with traceable evidence.

## Cumulative changelog

- **2026-10-13 — Navigation refinement:** Corrected the heading levels for the Testing Packages and Shared Development Conventions sections in `WORKFLOW.md` ([`a22eb87`](https://github.com/rerorriM-Mirrorer/xivcrossbar/commit/a22eb87a768b9a6271b3658c1b123079026b5ba4)). Documentation only; no addon code changed.

- **2026-10-13:** Adopted the shared two-document development convention (`WORKFLOW.md` and `TESTING.md`), without changing executable addon behavior.

## Delivered packages and documents

| Date | Batch | Item | Type | Commit/reference | Notes |
| --- | --- | --- | --- | --- | --- |
| 2026-10-13 | Documentation adoption | WORKFLOW.md; TESTING.md | Repository documents | [`9a6fc11`](https://github.com/rerorriM-Mirrorer/xivcrossbar/commit/9a6fc1186ff061232a18fbfc4ca9375c6a4c73e9) | No test package; no Lua files changed |

## User-provided materials, observations, and requests

- **2026-10-13 — Shared conventions:** Combine Agathos, Design, and Workflow in that order in a single `WORKFLOW.md` with linked table of contents. Keep `WORKFLOW.md` and `TESTING.md` in every active repository and testing-package root; preserve project-specific instructions.
- Preserve prior reports, requests, observations, and source materials with their dates, associated batches, and references when verified. Do not reconstruct unknown history as fact.

## Corrections and retention

Correct inaccuracies with ~~strikethrough~~, a note explaining the correction, and the accurate replacement. Do not remove any historical testing information without mutual agreement.
