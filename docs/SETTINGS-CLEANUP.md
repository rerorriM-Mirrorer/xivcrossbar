# Settings cleanup review and implementation

November 12, 2026. Working branch: feat/settings-cleanup-20261112.

## Findings and scope

The supplied visibility overlay was on fix/eventbars-chat-death-20261112
(e0ef2ae); the latest credit centering was on feat/contributor-credits-20261112
(03f0142). This branch combines both. Their TESTING histories are retained.
Current GitHub AGENTS/WORKFLOW/TESTING were read before changes.

Five consumers independently load the addon settings XML. Renaming every
runtime property would increase regression risk without improving the user's
configuration. The new libs/settings_schema.lua translates XML at load/save;
existing runtime property names and command paths remain in place. Translation
happens on each raw global/character section before inheritance. New spelling
wins over old spelling within a section; character overrides still beat globals.
Defaults are not reapplied to existing characters during migration.

## Implemented public names

| XML name | Values / behavior |
| --- | --- |
| Controller | PS, Xbox, XboxRB, F710, FightPad |
| Device | Existing backend device number |
| Preset | Default, Legacy, private Me |
| Layout | Full, Compact; Tight remains deferred |
| Scale | Existing independent HUD scale |
| Visibility | Show, Hide, Auto |
| Fading | HUD fading; independent of opacity controls |
| StartupSet / SharedSet | Existing startup/shared behavior |
| Crossbar.Number | Existing supported counts 3, 4, 5, 6 |
| Crossbar.Labels / Costs / RecastText / RecastAnimation / Elements | Positive booleans |
| Crossbar.HideEmptySlots | Keeps its existing inverted meaning |
| Texts.CrossbarLabels / CrossbarLabelOffsetX / CrossbarLabelOffsetY | Existing label appearance and placement |
| Texts.LabelOpacity | Shared by Crossbar Labels and Set Name |
| Texts.SetName / SetNameOffsetX / SetNameOffsetY | Unchanged |
| SlotGlow / RecastFlash / TriggerScale | Independent feedback switches |
| Cutscene | Show-only restriction; Auto ignores it |

The familiar preset/layout/controller/crossbar/visibility/fading commands and
old aliases use the existing execution paths. Singular `crossbar` keeps its
set-selection meaning; plural `crossbars` controls the number of 8-slot groups.
`eventbars on` remains the inverse alias of `cutscene off`. Existing field names
are accepted on import; saves use friendly names. Presentation normally derives from Preset and DisplayPreset is omitted. An
existing conflicting appearance-only override is retained as a compatibility
exception until a full preset is explicitly applied; it must not change Me
identity or personal-control permissions. Migration does not apply a full preset
or reset any other saved appearance/control fields.

Trigger-field alpha is fixed at 210, including the binder's amber field. The
binder's amber color is retained. Texts.LabelOpacity remains 60 for Default/Me;
Style.SlotAlpha remains 100. Whole-HUD fading still multiplies the field alpha.
Text fading/settling and tested fade timings are internal. STPC is always true;
HideBattleNotice is internal false. Stock Color/Theme/native guard/diagnostic
implementation values are omitted from global XML. Customized advanced values
and character overrides remain recoverable in XML instead of being discarded.

Legacy defaults now disable Crossbar Labels, Set Name, SlotGlow, RecastFlash,
TriggerScale and Fading; retain Show, persistent extras and Cutscene ON.
Default keeps modern XI behavior. Me retains its personal options, including
working camera zoom/map routing. Controller selection does not apply a preset.

## Deliberately unfinished before public release

- Shared multi-client XML writes are still not transactional. This cleanup is
  not a save-race fix. Do not broadcast preset changes yet. A separate storage
  change should lock/re-read/merge/atomically replace, with process-level tests.
- Removing ALL advanced Color/Theme/native/bridge properties requires a
  migration home for non-default personal values. ControllerBridge is still
  retained; dropping it would reset existing Trust/PS integrations. Stock theme
  values are hidden now; customized values are preserved. Propose a separate
  advanced/private store only after its ownership/saving is designed and tested.
- on_logout_unload_addon still has a real logout caller and is preserved.
  on_unload_killahk is obsolete and no longer exported. StopWrapperAfterLastClient
  and NativeDetachOnUnload have active lifecycle roles and are not deleted.
- BattleNotice still has renderer consumers. Its setting is forced false and
  omitted; deleting the artwork/code is a separate, traceable removal.
- Diagnostic commands remain available as advanced tools. Old textfade/textsettle
  commands retain their live session effect, but fixed internals are restored on
  reload and are no longer ordinary XML preferences.
- Cutscene detection is still a status/HP/chat/menu approximation, not a proven
  authoritative cutscene flag. Auto routing is unrestricted in-world; the game
  itself can still reject an action (for example while dead).
- Tight, smaller elemental markers and optional dark trigger fields are deferred.

## Installation and live acceptance

Apply the Lua overlay to the existing developed installation. Keep settings and
hotbars. Reload one client at a time. No AHK/DLL changes or controller reset.
The optional settings-me.global-example.xml is a separate reference, NOT an
installation replacement for existing data/settings.xml or character sections.

Try an existing old XML with character overrides, then inspect one save/reload.
Check Full/Compact, Default/Legacy/Me, all old/new command pairs, Show/Cutscene,
Auto through chat/native menus/status4/death, shoulders, held-client switching,
zoom and map. Confirm fields at 210 and labels/slots independent through fades.
Automated checks are mock/static/CI; no assistant in-game FFXI test is claimed.


Verification: final code 8524858d17059d89d02009db392136042dc844d1 passed
GitHub run 43268730614 (all 58 Lua suites plus Windows native/AHK checks).
143 Lua sources parsed after temporary Windower syntax normalization. Local
regressions and XML example parsing passed. These do not replace live FFXI tests.
