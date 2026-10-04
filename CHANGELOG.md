# Changelog

## 0.4.0-a.20261004.1 — working branch, 2026-10-04

- Consolidate the player-reported working installation into the qEagleStrikerp
  fork, including custom-action editing/quick creation, safe icon navigation,
  draggable UI, OnInput hiding and Quick Switch stale-return cancellation.
- Incorporate the later sparse-page/bar rendering fix in initial drawing and
  MP/TP updates, keeping default-layer fallback and Shared isolation.
- Add the later session-only `ui hide`, `ui show`, `ui auto` commands; event
  hiding still takes priority and unlocking restores automatic visibility.
- Preserve the captured settings, profiles, controller wrappers and assets in
  the complete package. Add A's explanatory comments and a distinct build ID.
- Move XIVCrossbar regressions to standalone paths and supply resource fixtures
  so a fresh checkout can run them without game-generated caches.
- Retain unaccepted DirectInput/travel prototypes as optional experiments.

Offline validation is recorded in `docs/VALIDATION-2026-10-04.md`. Live
acceptance of the remaining changes is pending; master is not updated.
