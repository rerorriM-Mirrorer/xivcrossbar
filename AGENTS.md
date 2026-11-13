# Agent entry point

## Before work

At the start of every session involving this repository, and whenever resuming work:

1. Identify the repository, current branch, and intended working branch.
2. Read the current root-level `AGENTS.md` and `WORKFLOW.md` directly from this repository. Read `WORKFLOW.md` in full; do not rely on remembered or previously copied versions.
3. Read `TESTING.md` from the beginning through the current development status and the heading `## Previous cumulative history (retained)`. Search older history by keyword when relevant. If that heading has not yet been added, read through the current status section and search older history as needed.
4. If a required shared document is missing, consult the canonical version in `rerorriM-Mirrorer/ffxi-NPCmirror`. Preserve and reconcile project-specific guidance and history rather than overwriting them.

## Repository safeguards

- Work on a dedicated development branch, not directly on `main` or `master`.
- Treat `main`/`master` as the last version trusted after live FFXI testing. Do not merge or promote a development branch into it without the owner's explicit approval.
- Follow `WORKFLOW.md` for development, verification, documentation, and testing-package practices.
- Do not use `[skip ci]` on commits that change Lua.

## TESTING.md history

Keep one concise current development status at the top of `TESTING.md`, followed by `## Previous cumulative history (retained)`.

When updating the status:
- Copy the previous status block unchanged into the retained history section.
- Write the new status above it.
- Insert content at the appropriate heading; do not rewrite or silently discard historical records.
- An open item may leave the current status only when a dated history entry records its disposition, such as resolved, superseded, or deferred.

If the history heading does not yet exist, introduce it carefully at the boundary between the current status and older records, preserving those records.

## XIVCrossbar branch boundaries

- Before work on a branch or release candidate, read `docs/BRANCH-MAP.md` and the relevant handoff or scope document identified by the current `TESTING.md` status.
- This repository contains separate public, personal, experimental, and release-snapshot lines. Verify the intended branch and source checkpoint from current GitHub state; do not infer that a branch is public or released from its name.
- Keep personal-only features, native-controller experiments, and binder-preview work out of the public beta unless the owner explicitly approves them.
- Shared UI and controller files overlap heavily across branches. Never overlay an entire file or branch wholesale; port the smallest coherent behavior, adapt its dependencies and tests, and preserve the target branch's defaults and known-good behavior.
- Do not promote a release snapshot or development branch to `main`/`master` without explicit approval and the required live acceptance.
