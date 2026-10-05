# Changelog

## 0.4.0-a.20261005.7 — save and bind custom actions

- Quick custom-action review now offers Save & Bind first, taking the saved
  command, icon, alias, and linked action straight to button assignment.
- Save Only keeps catalog creation independent. Back after saving returns to
  the action menu without reopening the saved draft.
- Offline binder flow passes; live controller and screen checks remain pending.

## 0.4.0-a.20261005.6 — guarded server profile

- Wait for a stable, in-world player/server pair before loading or creating
  character hotbars. This targets Myrr's blank Asura folder on login.
- If the client later corrects the server, reload the addon against the
  corrected profile without copying bindings between server namespaces.
- The live login timing remains to be checked on Myrr and another character.

## 0.4.0-a.20261005.5 — consistent browsing triggers

- L2 pages backward and R2 forward on selector/review screens. Assignment
  retains trigger combinations for choosing the destination crossbar.
- Prevent automatic startup of both controller wrappers at once.
- Offline regressions pass; live navigation/controller checks remain pending.

## 0.4.0-a.20261005.4 — controller extras live test

- Integrate L3 release-to-switch into automatically launched DirectInput and XInput wrappers.
- Retry R1 Tab / L1 Shift+Tab with explicit SendEvent key-down/up and 40ms hold.
- Keep R3 unassigned; add controller-extras.ini switches for independent rollback.
- Shoulder targeting is experimental; Windows/FFXI acceptance is pending.

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
