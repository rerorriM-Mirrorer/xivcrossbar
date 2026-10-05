# Changelog

## 0.4.0-a.20261005.3 — scale preview and menu essentials

- Preview a hidden crossbar for its grace period after scaling, then restore its visibility.
- Remove the persistent default-set explanation; inheritance remains unchanged.
- Handle action-type paging before choosing an action and show Save Changes first.
- Live acceptance remains pending.

## 0.4.0-a.20261005.2 — centered aliases and drag polish

- Center each alias by its rendered width, retaining dedicated X/Y offsets.
- Put Drag above the right edge, with the full lock hint below the outline.
- Keep outline edges at least one physical pixel at smaller scales.
- Offline regression checks pass; live acceptance remains pending.

## 0.4.0-a.20261005.1 — visibility and presentation

- Add saved autohide commands, session visibility toggle, manual Show during
  cutscenes, and finite nonnegative grace periods without the five-second cap.
- Default new configurations to OnInput with five seconds of release grace;
  preserve existing character overrides and profile loading behavior.
- Scale crossbar images, labels, indicators and drag regions together. Add
  dedicated alias offsets, bounded icon sizes, white unlocked outlines and
  pink Drag tile feedback. Keep saved movement offsets in screen pixels.
- Center binder contents/background together independently of crossbar offsets,
  with separate scaling and automatic screen fitting.
- Remove the unconditional self-target diagnostic. Reuse unchanged texture
  paths on reveal; a reduction in live reveal hitch is not yet established.
- Leave bindings, controller scripts and menu navigation for separate work.

Offline LuaJIT regression and Lua 5.1 syntax checks pass. Live testing is pending.

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
