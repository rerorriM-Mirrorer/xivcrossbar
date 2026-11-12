# Current Development Status - Settings cleanup test

2026-11-12 (America/Chicago), rerorriM-Mirrorer/xivcrossbar,
feat/settings-cleanup-20261112. Integrated source baselines: credits
03f0142faf7d428385fc1437a7acbb8301a4521f and visibility
e0ef2aeefe13b3bbc4b9b504ef1f3babc0171926. Latest user-confirmed live
behavior: personal camera zoom and map work well; bound credit icons work.
Menu centering and the supplied Cutscene/Auto patch still need live acceptance.

Implemented: public XML schema translation at scope boundaries, friendly command
aliases, 210 trigger-field alpha including binder, updated Legacy defaults,
positive Crossbar booleans, fixed text-fade/STPC internals, stock internal/theme
value pruning with non-default override preservation. See docs/SETTINGS-CLEANUP.md
for the complete findings, migration policy and explicitly unfinished scope;
docs/COMMAND-AUDIT.md inventories callback commands and exposure classification.
Controller/zoom/map transport is retained. A false actor/targeting result in the
visibility branch was corrected so disabled shoulder targeting stays disabled.

Local validation: 58 Lua suites pass using Lua 5.4 with temporary Windower syntax
normalization; 143 Lua sources parse. Targeted additions exercise schema old/new
scope inheritance and false values, actual friendly command callback, unchanged
Me zoom/map options, field alpha independence and whole-HUD fades. Old tests
which asserted chat/Event capture suppression were updated to the approved Auto
contract; current no-focus/reader/ownership guards remain tested. XML examples
were generated from the actual presets/schema and parsed with Python ElementTree.
GitHub run 43268730614 at source 8524858d17059d89d02009db392136042dc844d1
passed all 58 Lua suites and Windows x86 native/AHK checks. No assistant live FFXI test.

INSTALL: overlay only the matching addon files; keep data/settings.xml and all
hotbars. Reload one client at a time, no controller/DLL restart. Migration is
automatic on loading/saving; no full preset is applied implicitly. Optional
Default/Me global XML files under docs are references, not installed replacements.
Do not broadcast preset changes: the simultaneous-client shared XML save race
is still unresolved. Preserve character overrides. Advanced non-default colors,
native lifecycle preferences and bridge integrations are retained rather than
silently dropped; a private/advanced persistence design remains follow-up work.
Show-only cutscene detection remains approximate. Tight/element icons/dark fields
are deferred. Next: live old-XML migration, all old/new commands, presets, fields,
Show/Cutscene and Auto across chat/menu/Event/death/shoulders/focus switching.

## Previous cumulative history (retained)

# Current Development Status - Cutscene Show-only and Auto crossbar availability (TEST PENDING)

2026-11-12 (America/Chicago). Repository rerorriM-Mirrorer/xivcrossbar,
working branch fix/eventbars-chat-death-20261112, based on published
test/set-name-hud-20261112 commit 8152dec36bd85617a42f500bbc7b26044ccb011f.
Current work supersedes the old EventBars behavior but does not merge to master.
Read the current GitHub AGENTS.md, WORKFLOW.md and TESTING.md. Compared with
qEagleStrikerp/xivcrossbar master: upstream explicitly hid bars when player
status became 4; the newer chat/native-menu controller restrictions belong
to this fork's DirectLink architecture.

REQUEST: Auto must expose and route ALL L2/R2 and enabled shoulder crossbars
and their commands while chat is open, any regular FFXI menu is open, death/
Raise is displayed, and status is Event (4), without special EventBars
permission. Default/Me enable this. Cutscene is an independent ON/OFF
preference for Show-only HUD hiding. Legacy enables Cutscene; Default/Me
disable it. Do not block PS switching during login, zoning or other status.

CHANGES (Lua only; no AHK/native DLL changes):
- visibility.lua: remove event-induced Show-to-Auto remapping; implement
  Cutscene Show-only hiding. Windower has no authoritative cutscene flag;
  conservative approximation is status 4, positive HP, chat/menu closed.
  Auto always ignores the Cutscene setting. Death/raise and FFXI menus are
  explicitly exempt from Show cutscene hiding.
- xivcrossbar.lua: native hook uses ordinary addon input context even when
  FFXI chat is open; DirectLink no longer changes to native-chat or drops
  held crossbar presses; remove shoulder targeting, display and modifier
  handoff chat/event/menu restrictions; maintain normal addon menu ownership.
  Preserve foreground/reader/heartbeat and character-loaded prerequisites.
  AutoHold now continues through chat/event/death.
- shoulder_banks.lua: in-world shoulders work with FFXI menus/chat/Event 4
  and death/Raise, limited only by presence of FFXI character/info and
  normal modifier/binding priority.
- libs/preset_base.lua, libs/settings_presets.lua: new Cutscene preference,
  Legacy ON, Default/Me OFF. Old EventBars XML remains tolerated but is no
  longer a separate input gate.
- //xb cutscene on/off/status; //xb eventbars compatibility is INVERSE:
  eventbars on = cutscene off, eventbars off = cutscene on.
- tests/cutscene_context.lua: regression cases for Show/Auto/Hide, HP 0,
  chat/menu exceptions, AutoHold and shoulder availability.
- README.md, libs/command_help.lua updated. Previous test/source history
  below is deliberately preserved.

INSTALL/TEST: Preserve all existing user data and character files. Overlay
xivcrossbar.lua, visibility.lua, shoulder_banks.lua, libs/preset_base.lua,
libs/settings_presets.lua and libs/command_help.lua at matching paths, then
//lua r xivcrossbar on each client. Do NOT replace saved settings.xml and do
NOT replace or restart AHK/native DLLs for this Lua-only patch. Do not send
broadcast preset-change commands while shared settings XML write races remain
unfixed (separate outstanding work).

LIVE ACCEPTANCE STILL REQUIRED: Verify Default/Me Auto:
(1) idle then L2/R2 + face/D-pad in chat input and expanded chat log;
(2) L1/R1/L1+R1 shoulder display + face/D-pad in chat, event, native menu;
(3) death/Raise prompt with visible Auto held banks and command execution
attempt; game may legitimately refuse combat abilities while dead;
(4) status 4 warp/cutscene and regular NPC dialogue/menu, including
//xb auto and //xb show with Cutscene ON and OFF; keep Raise visible;
(5) AutoHold across chat/death; bare native navigation unchanged;
(6) PS away/return during zoning, loading, death and login;
(7) multibox focus handoff and held-button quarantine still prevent leaks;
(8) Default, Me, Legacy preset reload, saved XML and //xb eventbars alias.
If Show/Auto behavior differs in-game, attach one //xb diagnose start full
capture and identify the status/chat/menu/HP sequence. The Show cutscene
proxy needs live classification before declaring cutscene-only accuracy.

VERIFICATION: source review of the actual on-branch Lua files;
local texlua/Lua 5.3 mock policy test PASSED for the verbatim visibility.lua
and shoulder_banks.lua snapshot with 26 assertions covering Show/Auto/Hide,
Event 4, Raise HP 0, chat/menu, AutoHold and shoulder eligibility.
The subsequently added preset-value assertions in tests/cutscene_context.lua
have been source-reviewed, but not executed locally; they await full CI.
Neither that mock check nor source review is a Windower/FFXI live test.
Full Lua suite/Windows CI and actual game acceptance remain UNVERIFIED.
No installed FFXI client, AHK reader or controller hardware was exercised
by the assistant.

---

# Current Development Status - Menu-visible set name and persistent extra captions VERIFIED

2026-11-12 (America/Chicago). Repository rerorriM-Mirrorer/xivcrossbar,
branch test/set-name-hud-20261112. Tested source checkpoint
caf89a791a18204ebd55d3cad07e2501a2053358, based on
79f832454bedc3cbc7279aba9d6bcf2f87c69843. GitHub Actions
run 43241843720 PASSED both Lua and Windows jobs. 136 Lua sources parsed
under temporary Windower syntax normalization; the full Lua regression
suite passed, including tests/set_name_label.lua for persistent versus
autohidden double-tap captions, full-mode hint icons/text, combined/shoulder
suppression, binder/chooser menu-visible set name and live title update.
Windows 2022 x86 native fixtures, module loading, PS5 AHK discovery/reader
fixtures and package assembly passed. Artifact ID 13956275380 uploaded.
These are mock/static/CI passes, NOT live FFXI testing. Live acceptance
of the new visibility rules remains pending user testing.

The first CI check on commit 8ea6edc, run 43241645917, failed a
mock-only chooser_text assertion because tests/compact.lua left the reused
singleton chooser_open=true. The fixture now explicitly resets that flag to
match the closed-chooser state seen in the game's render pass. Runtime UI
logic was unchanged by this correction. Follow-up run 43241843720 passed.

Runtime change from the preceding set-name overlay is ONLY ui.lua.
A delta overlay may therefore include just ui.lua, with WORKFLOW.md and
TESTING.md beside it inside the xivcrossbar folder. Keep existing saved
settings, prior patch files, AHK and DLLs; overlay ui.lua and run
//lua r xivcrossbar. No full game, controller-reader or DLL restart.
User confirmed //xb banklabeloffset 0 3 looks excellent for Default
Compact and Full; 0 9 is the provisional Legacy Compact reference.
These are observations, not new hardcoded offsets. Potential future layout
names: Full, Compact, Tight. Actual in-game checks requested: legacy
persistent double-taps 5/6 retain set name and full hints; Default/Me
nonpersistent double-taps hide them; combined 3/4 hide; shoulder 7/8/9
hide; binder and Options chooser keep set name, including on live set
switch, while full hints remain hidden in menus. Check autohide/hold,
fade, long names, compact and full.

---

# Current Development Status - Persistent double-tap captions and menu-visible set name

2026-11-12 (America/Chicago), rerorriM-Mirrorer/xivcrossbar,
branch test/set-name-hud-20261112. Starting published source:
79f832454bedc3cbc7279aba9d6bcf2f87c69843.
Read current GitHub AGENTS.md, WORKFLOW.md, TESTING.md.
User confirmed Default Compact and Full trigger captions and set name
look excellent with //xb banklabeloffset 0 3. Legacy Compact appearance
may prefer 0 9. Future layout naming proposal: Full, Compact, Tight.
These are observed tuning references, not new automatic mode-specific
offset settings; the existing position controls and settings are unchanged.

AutoHideExtraBars=false is the Legacy preset setting that keeps double-
tap banks visible. The set-name caption and, in full mode, Share/Options
hints now remain shown while selecting double-tap banks 5/6 only if
AutoHideExtraBars=false. Combined banks 3/4 and shoulders 7/8/9
still hide them immediately. When AutoHideExtraBars=true, double-tap
banks still hide them. The set-name caption remains visible whenever
the binder or set chooser is open, regardless of the preview bank,
and retains live set name updates; full-layout hints stay hidden in
menus. Normal whole-HUD autohide/fade remains owned by geometry.

Changed runtime: ui.lua only. Changed mocked regression:
tests/set_name_label.lua. README and cumulative TESTING.md are updated.
Existing saved offsets, controller bridge, AHK, DLL, other presets,
and binding XML remain untouched. Testing: please exercise persistent
and autohidden extra bank options, combo/shoulder precedence, binder
and Options chooser open/close, immediate title change, both compact/
full, fade/autohold. CI/static status to follow; no live FFXI execution
has been carried out by the assistant.

---

# Current Development Status - Set-name HUD offset command verification

2026-11-12 (America/Chicago), repository rerorriM-Mirrorer/xivcrossbar,
test/set-name-hud-20261112. Successfully verified published code checkpoint
bae90c1845d575c7f134126b24ce0e01b6f183a0 on GitHub Actions run
43237098828. This documentation update does not modify that tested runtime.
Ubuntu Lua regression suite PASSED, including real command-path tests for
//xb setnameoffset: numeric validity, saved offsets, bare status,
reset to 0,0, and isolation of the trigger-label positions; the HUD
mock also passed shared compact/full caption anchors and contextual hiding.
136 Lua files parsed using temporary Windower Lua 5.4 normalization.
Windows 2022 x86 native fixtures and module loading both PASSED (2/2),
AutoHotkey v2 discovery/reader fixtures PASSED, and matched installable
artifact 13953950452 was uploaded successfully. All CI jobs PASSED.
These are static/mock/CI checks, not a Windower/FFXI visual test.

Test/install: GitHub Actions run 43237098828 contains the full-folder
installable artifact. For a minimal UI-only overlay, copy ui.lua,
xivcrossbar.lua, theme.lua, libs/preset_base.lua,
libs/personal_preset.lua, libs/settings_presets.lua and
libs/command_help.lua from the artifact onto matching relative
addon paths, retaining existing data/character settings, and
//lua r xivcrossbar. Do not replace the controller AHK or native DLLs
for this change. Existing saved BankLabelOffsetY=-63 remains until
//xb banklabeloffset 0 0 or a full preset reapplication. Set-name
offset begins at 0,0; //xb setnameoffset <x> <y> changes only
that label. Verify in-game on both Compact and Full, all presets,
with single, combined, double-tap and shoulder banks; check
autohide/hold/fades, job changes, long titles, 4K/laptop clients.
The visual test is pending user confirmation.

---

# Set-name HUD test refinement - independent set-name offsets

2026-11-12. Branch test/set-name-hud-20261112. User requested an
independent position command for the set-name label. Added
//xb setnameoffset <x> <y>, with bare status, numeric validation,
immediate live relayout and character-setting persistence. Default 0,0.
The preset values retain zero offsets and do not alter bank label positions.
Regression coverage checks independent position and reset; the real display
preset test fixture now provides the new UI method. First CI attempt
43236384558 failed in a display-only fixture (nil set_set_name) after
136 Lua sources parsed; this fixture correction is included. Recheck full
CI before claiming automated pass; actual FFXI appearance remains untested.

---

# Current Development Status - Set-name caption and shared label anchors

2026-11-12 (America/Chicago), rerorriM-Mirrorer/xivcrossbar,
branch test/set-name-hud-20261112. Starting published source:
0a5540bcdfc829b533393fd3d314180bfdde4d4f (fix/settings-inheritance).
Read current AGENTS.md, WORKFLOW.md and TESTING.md from GitHub before editing.
Isolated UI test only; existing personal controller baseline is untouched.

Requested: Full Legacy/Default/Me labels share the old Legacy (0,0) baseline;
compact labels align six pixels above the actual bank top regardless of preset.
Current set caption: all uppercase, one font-size smaller than trigger captions,
matching amber stroke and alpha, centered between L2 and R2 on caption rail.
It follows UI scale, fade and set/job changes. It and full-mode Share/Options
hints are visible only when no bank or single L2/R2 is selected; immediately
hidden on combined/double/shoulder banks or addon menus. //xb setname toggles
bare/on/off/status. No clickable chooser entry point is added in this test.

Runtime overlay files: ui.lua, xivcrossbar.lua, theme.lua,
libs/preset_base.lua, libs/personal_preset.lua, libs/settings_presets.lua,
libs/command_help.lua. Back up existing files; keep directory paths, overlay
only the seven Lua files, then //lua r xivcrossbar. No controller-reader restart,
AHK replacement, DLL change, data XML replacement or full client restart.
Preset definitions now use zero offset. Existing saved character settings may
still carry -63; //xb banklabeloffset 0 0 normalizes the position without
resetting other Me settings or bindings. Reapplying Default/Me also resets it,
but may reset other preset preferences.

Mock checks: tests/set_name_label.lua, tests/legacy_extra_bars.lua and
modified tests/xi_layout.lua cover centered caption geometry, visibility and
compact/full switches. Run all Lua suites, parse Lua 5.1 syntax, and inspect
CI before accepting. Live FFXI remains UNTESTED: inspect Full and Compact,
Legacy/Default/Me, 3-6 trigger banks, idle/L2/R2/combined/double/shoulder,
menu open/close, no-trigger AutoHold, autohide and fade transitions; compare
4K and laptop widths and very long set names. Switch/rename sets and jobs;
verify matching alpha/stroke and //xb setname bare/on/off/status, including
opacity 0. Do not claim tests are in-game until user confirms.

---

# Current Development Status - Permissive PS and fresh modifier arrival

2026-11-12 (America/Chicago), rerorriM-Mirrorer/xivcrossbar, branch
fix/settings-inheritance. Starting published source 462002c. Read current
GitHub AGENTS.md, WORKFLOW.md and TESTING.md before editing. Compared old
personal AHK v1 source 52bfa1d directly. User reports restrictive PS behavior
and requests held triggers read as new presses on the destination.

PS: last non-FFXI application with suitable window fallback; last FFXI client
with existing-client fallback on return. No 30-second timer, gameplay/chat/
menu/event gate, recent-PS-departure requirement, or live message-ready gate.
Retains Me PS setting, on/test/off, valid HWND/PID checks, fresh-edge latch,
and old shoulder/trigger chord exclusion. Face buttons and stick motion no
longer block PS. Minimized targets are restored. Hardware must still expose
PS and the selected profile must be PS5 DirectInput.

Held-modifier handoff now routes fresh trigger downs on the destination instead
of directly seeding state flags. Existing combined trigger order is retained.
An imported held double-tap bank starts with a fresh single trigger press;
no double tap is synthesized. Shoulders enter transport as fresh held presses
without firing targeting/set-cycle shortcuts. Already-held switching slot
buttons remain consumed until release; handoff packet sequence dedup remains.
Internal handoff presses may initialize during receiver join before ordinary
message filtering is ready. Focus/readiness/chat/menu guards still apply.

This change does NOT claim to fix the independently reported intermittent
native-targeting leak. Native hook/foreground-quarantine changes are deferred;
no DLL or timeout values change. Test fresh modifier arrival and native blocking
as separate observations. Verification: five focused local Lua suites passed and 135 sources parsed
under Lua 5.4 with temporary Windower syntax normalization. Windows CI run
43215915365 at 192675b8dffd4c83fdd5676de0323a15e3648fdc passed all 52 Lua
suites, x86 native fixtures/module loading, AHK v2.0.19 discovery and actual
reader/profile/lifecycle fixtures including permissive PS decisions. Live
FFXI/window-switch acceptance remains; CI does not exercise your desktop.
This verification entry is documentation-only. Next: PS and handoff acceptance, then native leak capture.

INSTALL: //xb controller stop, overlay Lua/AHK files, //lua r xivcrossbar on
each client, then //xb controller start. No full client restart; keep existing
matching extra-controls DLLs. Existing //xb me settings apply, with //xb me ps
on to enable if needed. No personal data/settings shipped.

---

# Current Development Status - Extra controls routing and Me shortcut tests

2026-11-12 (America/Chicago), rerorriM-Mirrorer/xivcrossbar, branch
fix/settings-inheritance. Starting published source cbd8a21. Read current
GitHub AGENTS.md, WORKFLOW.md and TESTING.md before editing. User reports
previous personal controls feel good; no live acceptance of this batch yet.

Adds negotiated 23-control reader messages and native extra-capture capability.
New logical controls: L3/R3, PS, touchpad click, mute, right-stick Up/Right/Down/Left.
Unassigned inputs remain native. PS keeps its existing private AHK window toggle.
PS5 DirectInput candidates use buttons 11/12/13/14/15 and axes Z/Rz; mute is
driver-dependent and may not be exposed. F710 exposes L3/R3 where available;
no invented fightpad extras. Standard XInput supports L3/R3 and right stick,
not PS/Guide/touchpad/mute. Touch surface gestures and independent paddles
are not available from these joystick APIs. Record InputTrace/diagnostics to
verify actual device outputs; these mappings are not claimed hardware-tested.

Under //xb me: CameraZoom and TouchpadMap default on. Private controls
//xb me zoom on|off and //xb me map on|off save live without addon reload.
L1 first, centered right stick then Up holds period (zoom in), Down holds comma
(zoom out). Native vertical camera movement is suppressed while this shortcut
owns the axis. Release, focus loss, stale lease, disable/menu/test or reader
shutdown releases generated keys. A held stick is not adopted across clients.
L1 + fresh touchpad sends toggle ffxidb once; bare touchpad is unchanged.
Other modifiers, held slot buttons, menus and chat suppress these shortcuts.
Default/Legacy leave both shortcuts off. Existing shoulder correction, PS,
set cycling, neutral/client movement modes and held-modifier handoff remain.
The camera keys assume the user's period/comma bindings, not auto-detection.

All 52 Lua suites passed; 135 sources parsed under Lua 5.4 with temporary
Windower syntax normalization. Host g++ C++17 native fixture and generated
mapping consistency passed. Windows CI run 43209235016 at published
7b29831b09f61b83e241d5e65e905cf2ec5dc952 passed Lua, x86 MSVC native
fixtures, module loading, AHK v2.0.19 discovery and actual reader/profile/
lifecycle fixtures including new zoom decisions and 23-control messages.
Artifact 13939982729 downloaded and its GitHub SHA256 verified. Initial
Windows run found an outdated Lua registration fixture callback count; the
fixture now verifies the extra capability/export and passes. Cleanup was also
reviewed to reset zoom arming on client/reader changes. This verification
update is documentation-only; delivered runtime equals the successful build. Live PS5 input identity, camera
zoom/axis blocking, touchpad toggle, L3 native TargetNPC, client switches,
release cleanup and Default/Legacy native behavior remain to test.

INSTALL: stop reader, close ALL FFXI clients, overlay matched Lua/AHK/native
files, restart clients and use //xb me. This one expanded hook install needs
a client restart. Future Lua/reader changes within these routes can use addon
reload/reader restart without closing FFXI. No data/settings files overwritten.
Rollback: close clients and restore the previous matched runtime/DLLs.
Next: user live acceptance; no configurable action-map UI introduced.

---

# Current Development Status - Shoulder correction

2026-11-12. Repository rerorriM-Mirrorer/xivcrossbar, branch
fix/settings-inheritance. Starting published source 0f46235.
User reports the other personal controls feel good. Restored revision 3
shoulder tabbing only with an existing target; removed R2 TargetNPC dispatch
and command. Old saved R2TargetNPC=true is harmless. Legacy fallback R1
behavior is preserved from before the personal-controls patch. L1+R1 NPC
shortcut remains removed. No native DLL changes: addon reload is sufficient.

Verification: all 51 Lua suites passed and 134 sources parsed under Lua 5.4
with temporary Windower syntax normalization; no live FFXI test performed here. Test untargeted shoulders,
targeted reverse/forward cycling, both shoulder chord orders, R2 with an old
saved flag, and existing PS/set/movement controls. Next: live acceptance and
a separately scoped configurable personal-action map.

Correction to the historical batch below: targetless shoulder cycling and R2
TargetNPC were unintended and are superseded by this entry. Earlier results
are preserved as the record of that delivered build.

---

# Current Development Status - Optional personal controls and combined handoff test

2026-11-12 (America/Chicago). rerorriM-Mirrorer/xivcrossbar,
fix/settings-inheritance. Starting local cbf0827 matches published fc10a3d.
Read current GitHub AGENTS.md, WORKFLOW.md and TESTING.md before edits. The
held-modifier package is still untested in FFXI by the user; this delivery
combines its runtime files and matching newly built native DLLs with this batch.
Trust interpretation is explicitly deferred to the separate Trust conversation.
No Trust files, settings or bindings are changed here.

Me now owns ShoulderBanks.PersonalControls: Enabled, R2TargetNPC, PSButton,
SetCycling and MovementArm. Legacy/Default initialize these disabled with client
movement arming. Me enables them and selects neutral arming; //xb me applies
and reloads as before. Nested test controls do not reload:
//xb me status; //xb me controls on|off; //xb me r2target on|off;
//xb me ps on|off; //xb me sets on|off; //xb me movement client|neutral.
Nested changes require the Me preset; its master OFF disables new shortcuts
and returns movement arming to the original client-focus rule. Existing bridge
movement off/test/on remains available. No public top-level command is added.
Controller profile/device and saved bindings remain preserved.

Removed TargetNPC from both shoulder-target paths. With shoulder targeting on,
L1 sends Shift-Tab and R1 Tab even without a target; simultaneous shoulders do
not acquire an NPC. The combined shoulder bank remains usable. R2 TargetNPC is
optional: a fresh bare R2 press in gameplay with no native menu, other modifiers
or held action targets an NPC, then retains ordinary R2-bank behavior. Adopted
R2 holds across focus do not synthesize this action. InputTest suppresses the
real TargetNPC command. No R2 release or repeat action is added.

Set controls (user selected cycle, not chooser): hold L2 then freshly press L1
for previous; hold R2 then freshly press R1 for next. Uses existing chooser order
and wraps, filters the Add New sentinel and respects Shared visibility. Trigger
first is required; both triggers, held action buttons, setup/text/Trust menus
and repeat downs cannot cycle. A new native capability gates the chord so the
shoulder does not leak into native navigation. Native v1 ABI memory sizes stay
unchanged; hook/policy files must match this build.

PS was rebuilt as controller_ps.ahk. User selected bare PS only, no shoulder-PS
combos. One global physical edge latch spans focus changes. A valid foreground
non-FFXI window is remembered; bare PS from eligible gameplay selects it and
arms a 30 s return to the originating FFXI HWND/PID. Release and press PS again
outside to return. Invalid/reused handles, desktop/taskbar, expired returns,
held PS, chords, inactive/test/off modes and non-PS5 profiles cannot activate
unintended windows. Test mode only reports the decision. Outside polling uses
the existing profile-slot reader, not a hardcoded device-number PS read. Visit
the preferred non-FFXI window with Alt-Tab once so the reader can remember it.

Movement: client preserves one signal per client-focus session after stable
center. Neutral emits at most one signal per centered-to-movement gesture.
Center threshold <12%, movement threshold >=24%, stable-center interval 100 ms.
A held/uncentered stick cannot repeatedly signal. Neutral consumes an attempt
even when Trust/eligibility is unavailable; no delayed replay after readiness
changes. Client mode retains its prior readiness retry semantics. The exact
30 ms vk1D/sc07B pulse and matching Trust receiver lease remain unchanged.
See docs/TRUST-STICK-HANDOFF.md: park/stop semantics, idempotent receipts and
movement-owned cleanup belong to Trust and are not implemented by this patch.

All 51 local Lua suites passed (134 sources parsed with temporary Windower
syntax normalization under Lua 5.4); final targeted routing/preset/bridge reruns
and host g++ C++17 native fixtures passed. Windows 2022 CI run 43193701625 at bca4f2778b7e6cc30dca21400925c7d83f39fe03
passed both jobs: complete Lua regression, x86 MSVC build/native fixtures,
pinned AutoHotkey v2.0.19 discovery and real reader/profile/lifecycle fixtures,
including new PS and stick-arming decisions and the inherited focus handoff.
Artifact 13932391017 downloaded with its GitHub SHA256 verified. The original
windows-latest run remained queued, so the native workflow is now pinned to
Windows 2022 for reproducible builds. This verification update is docs-only. New AHK fixtures test
client/neutral arming, PS latch/return/chord/expiry/off decisions and existing
held-modifier focus transfer. No live FFXI or real desktop PS switching pass
is claimed. Existing timer text-settling flicker remains a separate pending fix.

INSTALL: combined incremental package over the preset/layout build; installing
fc10a3d separately is NOT required. Stop shared reader with //xb controller stop,
unload XIVCrossbar and CLOSE ALL FFXI processes before replacing native DLLs.
Back up addon files; overlay the matching xivcrossbar folder; restart FFXI,
load XB per client, start the reader if needed, then //xb me to activate this
test group. Begin with all buttons released. No settings/hotbars are overwritten.
Rollback requires closing FFXI and restoring matching Lua/AHK/native files.
The optional global Me XML is separately supplied, never auto-installed.
WORKFLOW.md and cumulative TESTING.md remain inside the addon payload.

Live: first test held L1/R1/L2/R2 transfer, including combined/double banks and
consume-until-release switching buttons. Then test individual Me switches,
R2 TargetNPC, targetless Tab/Shift-Tab and no combined-chord NPC acquisition.
Test set cycling order/wrap and unchanged bindings. Test PS outside/back with
release, chords and stale windows. Use bridge movement test mode to compare
client and neutral cadence before enabling real Trust messages. Verify Default
and Legacy disable personal controls, bare gameplay remains native, and old
partial installs do not advertise the new set-chord capability.

---

# Current Development Status - Held-modifier handoff between FFXI clients

2026-11-11 (America/Chicago). rerorriM-Mirrorer/xivcrossbar,
fix/settings-inheritance. Starting local source 63d6169 matches published
37ce5f1. Current GitHub AGENTS.md, WORKFLOW.md and TESTING.md read before edits.
User reported L1 held across a window switch was lost while native D-pad input
reached the destination. Requested all four logical modifiers to carry, while
already-held action buttons remain consumed until release. The prior Legacy
layout/preset fix is included in the source baseline; this is a controller batch.

Reader: a direct FFXI-to-FFXI switch snapshots held logical L2/R2/L1/R1 and the
last published active trigger bank. On a matching capable destination lease,
only modifiers still physically held are adopted. All other currently-held
buttons are seeded without down edges, so they must be released and pressed
again. Ordinary startup, reconnect and non-FFXI transitions retain neutral
rearming. Existing mappings, controller profile selection and slot scanning
are unchanged. Alternate R1-as-chooser mappings retain their existing semantics.

Lua: token-checked resume records restore modifier/bank state directly, without
routing synthetic presses, opening double-tap windows or shoulder targeting.
Double-tap and ordered combined banks are retained where the destination's
trigger layout supports them; otherwise its normal compatible bank is used.
Receiver validates mask/range/sequence/token, and ignores duplicate records.
Source lease cleanup releases old ownership. Old DLLs do not advertise the
handoff capability, so readers retain neutral gating rather than half-enabling.

Native: the matching hook and policy adopt preheld modifiers without action
edges, quarantine already-held action buttons through release, and cover the
foreground-to-Lua heartbeat gap. DirectInput state/buffered and XInput paths
share suppression policy. The v1 policy ABI memory layout is unchanged. A new
module capability field gates Lua/reader handoff. Native build workflow now runs
for this development branch to build x86 DLLs and execute Windows/AHK fixtures.

Local verification: all 50 Lua regression suites passed and 132 sources parsed
with temporary Windower syntax normalization under Lua 5.4. New tests exercise
all modifier masks, bank preservation, fresh input, invalid/duplicate records
and the real adoption callback. Host g++ C++17 native fixture passed, including
focus-gap quarantine, modifier combinations and consume-until-release after
modifier release. Windows CI run 43139719439 at published source d5d4ea42f7bbe32f5fee77b87cdeed14cf49eee9
passed both jobs: all Lua suites, x86 MSVC build/native fixtures, pinned official
AutoHotkey v2.0.19 discovery smoke, and real AHK reader/profile/lifecycle plus
handoff fixtures. Downloaded artifact 13909251690 matched its GitHub SHA256
and passed ZIP integrity checks. Packaged DLLs are x86 and taken directly from
that build. No live FFXI handoff success is claimed. This verification update
changes documentation only; runtime source is identical to that CI checkpoint. Canonical ASCII chat-output convention is adopted here.

INSTALL: This batch changes the loaded native bridge DLL. Stop the shared
reader, unload XIVCrossbar on every client, and CLOSE ALL FFXI processes before
replacing native DLLs; Lua reload alone cannot replace the loaded hook. Back up
the current addon/native/reader files. Overlay the matching controller patch,
restart FFXI, load XIVCrossbar on each client and run //xb controller start once.
Start with all buttons released. Keep profile/device consistent across clients.
No settings/hotbars are replaced. Roll back by closing FFXI and restoring the
backed-up Lua, AHK and DLL files together. Do not mix hook/policy versions.

Live acceptance: on two clients, hold each of L1, R1, L2 and R2, use a bound
window-switch action, and keep the modifier held. Destination should display
the matching bank, with no native D-pad/face leak or repeated switch. Release
only the action and press a fresh action without releasing the modifier. Repeat
both triggers, both shoulders, double-tap trigger banks and 4/6-bank trigger
order. Release modifier before the switching direction and verify that direction
stays blocked until released. Check rapid round trips, chat/addon menus, leaving
FFXI for another app, disconnect/reconnect, reader stop/restart and foreground
changes with no modifier. Native bare gameplay should remain normal.

Pending separate issue: the timer text-settling blink from the provided render
capture is not part of this controller change.

---

# Current Development Status — ASCII reload feedback and Legacy bank spacing

2026-11-11. Repository rerorriM-Mirrorer/xivcrossbar, branch
fix/settings-inheritance. Starting local checkpoint cb77d9d is source-identical
to published 89bec17. Current GitHub AGENTS.md, WORKFLOW.md and TESTING.md read
before editing. User live report: preset reload feedback rendered the UTF-8
em dash as an unwanted Japanese character. Requested capitalized plain messages,
Legacy compact bank labels matching Default/Me placement, extra bars farther
outward, and smaller vertical separation in compact only. Full Legacy labels
were reported good and their relative placement is retained.

Feedback is now exactly [XIVCrossbar] Default reloading, Legacy reloading,
or Me reloading. No dash or other non-ASCII character is emitted by these
three preset confirmations. Other existing messages are outside this change.

Legacy's extra banks retain regular cross geometry and move 90 logical pixels
outward on each side. Full layout retains the configured -180 vertical offset;
compact uses 60% of that offset (-108 with current Legacy settings), reducing
the gap while keeping the pair above and outside the regular bars. Switching
compact/full recalculates all slot surfaces and labels through existing layout
machinery. No extra offset accumulation or new saved-setting fields are added.
Legacy compact headers anchor six pixels above the actual top of each bank,
matching Default/Me's compact gap despite Legacy's different slot row order.
Full Legacy header placement and regular bar positions remain unchanged.

Targeted checks pass: actual command branch emits exact ASCII captions and
saves/reloads once; invalid arguments cannot reload. Legacy geometry checks
cover both extra banks/all slots, three full/compact round trips, preserved
full labels/artwork and matching Default/Me header gaps. All 49 regression
suites passed in one complete run; all 131 Lua sources parsed with temporary
Windower syntax normalization under Lua 5.4. Git diff whitespace checks pass.
No Windows, Lua 5.1 or live FFXI fix confirmation
is claimed. The prior diagnostic also identified timer text-settling blinks;
that is a separate pending repair and is not changed in this batch.

Install: incremental patch over the Settings Presets build. Unload XIVCrossbar
on each client, back up replaced code, overlay the xivcrossbar folder, and load.
No settings/hotbar data or AHK/native files are supplied; no controller or FFXI
restart is needed. Existing Legacy settings are adapted at render time, so
there is no need to replace settings.xml or reapply the preset to get spacing.
Rollback by unloading and restoring the backed-up code. WORKFLOW.md, TESTING.md
and README.md accompany the payload inside the addon folder.

Live acceptance: invoke //xb default, //xb legacy and //xb me and check the
capitalized readable messages. In Legacy compare full and compact, including
several toggles: unchanged full labels, compact labels above their bars, extra
pair wider than the main pair and closer vertically when compact. Check normal
HUD scale and small windows, captions/recasts remaining attached to their slots,
and no drift after repeated toggles. Verify Default/Me appearance is unchanged.

---

# Current Development Status — Legacy / Default / Me settings presets

2026-11-11. Repository rerorriM-Mirrorer/xivcrossbar, branch
fix/settings-inheritance. Starting local checkpoint cda8a49 is source-identical
to published 2d78c17. Current GitHub AGENTS.md, WORKFLOW.md and TESTING.md read
before edits. User confirmed the gold success flash looks great. Publication
permission was explicitly granted; the earlier push block is superseded.

Commands: //xb legacy, //xb default, //xb me. Each applies a complete owned
settings snapshot, saves for the current character and gracefully reloads Lua.
Controller profile/device and input-test/trace selections are preserved. Saved
hotbar bindings, custom actions and XML set names are never rewritten. Existing
//xb new <name> still creates a named set. //xb display retains its existing display/visibility behavior.
Fresh-install defaults now come from the Default preset; existing saved settings
continue to override missing-value defaults normally. Presets explicitly reset
the fields they own, so personal values cannot leak into another preset.

Legacy: original full layout and original trigger artwork; Show visibility;
extra double-tap pair aligned above regular bars, 180 logical pixels higher;
Shared on; shoulders/targeting off; event bars off; original set names. Upstream
master xivcrossbar.lua explicitly hides at status 4. Upstream chooser selects
the alphabetically first non-fallback set (usually Basic), not a hardcoded Main.
That startup rule is retained, with our existing safe fallback for sparse files.
Five trigger banks are used so the requested always-visible extra pair exists.
This is an intentional presentation exception to upstream's three-bank default.

Default: XI compact, On Input, Auto hold 0, Shared on; same legacy startup rule;
shoulders and shoulder targeting off; held bars available during events; extra
bars hidden until used; trigger scaling and slot glow on. Me: uploaded global
snapshot plus Cioara overrides, XI compact/Always, Auto hold 3, Shared off,
job/subjob fallback set (internal default) selected on reload, shoulders and
targeting enabled, event bars available, skillchain/lockout indicators hidden.
If the job/subjob fallback is absent, safe legacy selection is used.
Default/Me use newer display labels; named-set XML content is preserved.
All three keep subdued bank labels, recast-ready flash and gold success flash.
Slot rumble and L2/R2-to-L1/R1 navigation changes remain deferred.

The separately supplied optional-settings/settings-me-global.xml is NOT an
automatic install payload. It contains one global section with Cioara overrides
folded in, Shared off and job/subjob startup; no character sections. It retains
the uploaded PlayStation 5 DirectInput / Device 2 selection. To use it, unload
XIVCrossbar on every client sharing this folder, back up data/settings.xml, copy
this file there as settings.xml, then load. This deliberately replaces existing
character overrides. The normal //xb me command preserves hardware selection.

Source for personal values: settings(20261111-220202).xml (uploaded this chat).
No hotbar/custom-action user data are included. Testing package: incremental
code patch over current development build; WORKFLOW.md, TESTING.md and README.md
inside xivcrossbar; optional settings kept outside the installable addon folder.
Back up replaced code before overlay. Preset commands reload the addon; no FFXI
or AHK restart is needed. Rollback: unload and restore code/settings backups.

Verification: across the full-suite run and targeted reruns, all 48 regression
suites passed; all 130 Lua sources parsed through temporary Windower syntax
normalization under Lua 5.4. Checks include all nine preset transitions,
controlled resets, hardware preservation, actual chooser startup selection,
legacy extra-bank coordinates/artwork and updated fresh defaults. Five existing
fixtures now explicitly specify old starting layouts, disabled glow, event-bar
expectations or configured label opacity instead of assuming old defaults.
Standalone XML parsed and checked for global-only scope, folded overrides and
requested Me values. Git diff whitespace checks pass. No Windows, AHK, Lua 5.1
or live FFXI preset test is claimed.

Live acceptance: switch legacy -> default -> me -> legacy; verify labels,
startup set after reload, Shared chooser visibility, shoulders,
event behavior, extra-bank separation, both flashes, animations and indicators.
Verify existing bindings are intact, controller selection unchanged, and test
small windows/HUD scale. Independently try the optional global settings copy
with backups and confirm no previous character overrides remain active.

---

# Current Development Status — Gold-white confirmed-action flash

2026-11-11. Repository rerorriM-Mirrorer/xivcrossbar, branch
fix/settings-inheritance, starting source checkpoint 729bb68. Lua-only visual
batch; existing AHK/native companion versions are unchanged. Current GitHub
AGENTS.md, WORKFLOW.md and TESTING.md were read before this work. The final
local commit is identified in the delivery; it is not a published remote head.

Requested: a white outer glow with a slightly more opaque golden-white center,
about 2–3 times slower than recast-ready feedback, on confirmed Attack/Disengage,
Summon/Release, Assault/Retreat, Trust/Return, weaponskill execution and completed
uninterrupted spells. Implemented 0.4 s fade (ready flash remains 0.15 s), white
border alpha 156, center RGB 255/235/174 alpha 184. Existing textures are reused;
success and ready animations have independent lifetimes. New cooldowns cannot
cancel the success fade. The overlay follows bank scale, position and opacity.

One pending request is armed from the actual accepted typed slot action,
resolved against the pre-press pet/trust state. Another press replaces it.
Own spell/WS/JA completion packets are matched by category and resource ID;
WS misses and spell resists still count as execution. Cast interruption cancels.
Requests expire after 3 s unless a matching spell-start packet extends the cast
window to 30 s. Other actors, custom macros, items and unrequested actions do
not independently start this feedback. Attack, Assault/Retreat and Return use
observed player/pet/party transitions; Release also accepts its own action packet.
Confirmation is queued through the next render tick so an automatic summon or
Release environment reload does not erase it before it can be drawn. Hidden
banks, menus, slot reloads, zones, jobs, logout and unload clear stale feedback.

Packet/state correlation is bounded and intentionally conservative, not a new
action scheduler: changing sets or pressing another action can discard an older
pending result. A delayed avatar-swap sequence can outlive its initial request
window; do not infer a failed summon merely from absence of this visual.
Arbitrary macros and other pet abilities are outside this first success batch.

Verification: all 46 regression suites passed in the temporary Windower-syntax-
normalized Lua 5.4 harness; all 125 Lua sources parsed. The new tracker/UI tests
cover actor/ID matching, interruption, expiry, duplicates, state transitions,
independent cooldown timing and hidden/rebound cleanup. After inspecting the
existing textures, the success border uses the original recast-glow asset; the
tracker, success UI and recast suites were rerun after that final texture choice.
Two existing event-extraction fixtures gained mocks for the new tracker.
Git diff whitespace checks pass.
No live FFXI, Windows renderer or Lua 5.1 pass is claimed. Last user-confirmed
behavior remains stable current play and the earlier grey availability feedback.

Install this incremental patch over the current public development installation
(including the previous Blood Pact MP patch). Unload XIVCrossbar, back up the
replaced files, overlay the xivcrossbar folder, then load it on each client.
Do not replace data/hotbar/settings folders. No FFXI or AHK restart is required.
Rollback: unload, restore those files, remove libs/action_success.lua if newly
added, then load again. WORKFLOW.md and this cumulative record accompany the
payload inside the addon folder. Public directory restructuring remains deferred.

Live acceptance: try Attack then Disengage; summon then Release (including an
automatic pet-set switch); Assault then Retreat; summon/return a Trust; a WS
that hits and one that misses; a normal completed spell, a resist and an
interrupted cast. Verify the gold center fading over the start of recast,
white border, hidden-bank/menu behavior, compact/full layout, HUD scale/fades,
and no flash from party actions or a rejected command. Check a long cast and
fast consecutive presses. Report timing, opacity and whether the border reads
clearly at normal playing scale before extending to other pet actions/items.

Publication remains local: an earlier automatic approval review rejected the
GitHub push because the destination/private-source publication was unverified.
No push is retried in this batch.

---

# Current Development Status — Personal three-character hotbar data overlay

2026-11-11. Code baseline fe2a2b9 on fix/settings-inheritance; no runtime code change.
User-provided hotbar(1).zip SHA256 736e71c87d33246561c4ee7a74bc0422463af61d9b13643259bde34e7a1acefd.
Data-only payload: Shared.xml, CustomActions.xml and WHM-DEFAULT.xml for Cioara,
Myrr and Clairvaux. L1 Down stop-follow; Circle trust pauseall; Triangle explicit
stopall/echo/follow-me sequence. Both banks based on Cioara, R1 Up mount-all.
Remove only the three WHM L2-double-press NPC overrides. Preserve Ready, All Jobs
Default and unrelated job bindings/catalog entries. Corresponding catalog records
updated alongside inline commands. No mount/follow coupling in this batch.

Nine XML parse/roundtrip and structural checks passed; shoulder banks identical;
non-targeted Shared/catalog content unchanged; WHM changes exactly the requested
removals. Trust command source on test/party-stealth checked for native pauseall
IPC; follow stopall/mount-all source inspected. No FFXI live pass is claimed.
Install precautions and rollback are in INSTALL-HOTBAR.md inside the payload.
Unload XIVCrossbar on all three clients before overlay, preserve current folders
as backup, then load again. No FFXI/reader restart. Personal data is delivered
as a separate artifact, not added to repository defaults or public runtime.
This documentation commit remains local pending earlier publication approval.

---

# Current Development Status — Blood Pact MP display

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Starting checkpoint `53074ee`. User reports missing MP costs on Blood Pacts.

2026-11-11 delivery: `XIVCrossbar-Blood-Pact-MP-Patch.zip`.
The resource generator hardcoded every job ability's MP cost to zero. Generate
Windower MP values for BloodPactRage/BloodPactWard only; preserve zero for Monster
entries whose mp_cost represents Ready charges. The crossbar's initial cost
label and ongoing affordability checks now resolve pact MP directly from installed
Windower job_abilities, so old generated caches work immediately without deletion
or a forced regeneration. Existing MP colours, hide-cost settings and insufficient
MP treatment are retained. Spell/WS and arbitrary macro behavior stay unchanged.
These are resource/base MP costs; dynamic/gear-adjusted costs are not calculated.

Validation: 44 mocked Lua suites passed; 122 Lua sources parsed under Lua 5.4
with temporary Windower syntax normalization. New tests cover Rage and Ward,
legacy cached zero values, zero-base-cost entries, Ready-charge exclusion and
spell/ability ID collisions. Existing UI/layout/cost regression suites pass.
No in-game FFXI confirmation or Windows/Lua 5.1 execution is claimed.

Overlay on current build, reload XIVCrossbar on every client. No FFXI or reader
restart, and no user-data files are supplied. Live: check one Rage and one Ward
with a positive base MP cost; verify normal MP colour and insufficient-MP state,
Hide Action Cost, and existing recast behavior. Zero-base/dynamic pacts should
not receive an invented cost. Source checked: Windower/Resources job_abilities;
restore code/layout and controller behavior otherwise unchanged. Local publication
only pending the earlier GitHub push approval. Directory restructure remains deferred.

---

# Current Development Status — All-profile-slot reading survives normal commands

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Starting checkpoint `77bcfcc`. User observed normal input with the opt-in reader
but no scan row; uploaded controller-all-slots.log proves slot-2 scans between
10:55:28 and 10:59:36 UTC. Uploaded controller-status(1).ini has no scan markers,
so it cannot establish the same writer. User then changed PS5 device to 1, which
could restart the old single-device reader. User now authorizes all backend slots
regardless of selected device number, including normal startup/profile commands.

2026-11-11 delivery: `XIVCrossbar-All-Slots-Integrated-Patch.zip`.
Normal ffxi_directinput.ahk always scans the selected profile's backend. The
controller-all-slots.ahk entry remains a compatible alias, no longer required.
Status always publishes scan_mode and reader_build=profile-slots2, reader script
and connected/active slots. The source log includes PID/script to correlate
writers. All-slot Lua status matching ignores device-number differences, while
profile/protocol/liveness remain mandatory. Reader leases also retain profile
validation but no longer reject a client because its saved device differs.
Device-only selection therefore preserves a matching all-slot reader. Profile
changes may restart it but always return to full backend scanning. Legacy readers
without scan_mode retain strict number matching and must be stopped for upgrade.

IMPORTANT: this removes reader/lease number gating, not native guard attachment
selection. Status labels the saved number Guard Device, with Running / All Slots
and Reader Slots showing the sampling scope. Device 1 can still affect the native
hook's attachment even while the reader gets input from physical slot 2. Automatic
native matching/multi-device filtering is NOT implemented. Check native leakage
when testing additional pads; do not interpret reader acceptance as proof that
all game-side devices are intercepted. Each profile still uses one mapping and
one backend. Same-profile multi-source held states retain any-down/all-up logic.

Install: `//xb controller stop`, wait for exit, overlay ZIP, then reload
XIVCrossbar on clients and run `//xb controller start` if needed. Normal startup
now starts the scanning reader. No manual AHK test launch or FFXI restart.
Check `//xb controller status` for Reader Slots / All profile slots. Try selecting
PS5 device 1 while the pad remains in slot 2: input sampling should continue,
with connected slot 2 reported. Check other clients with differing saved numbers,
reconnect, duplicate presses, holds and native leakage. If status is odd, send the
new controller-status.ini and controller-all-slots.log; marker/PID/script fields
now permit correlation. Rollback requires restoring prior reader and messages
files plus controller_profiles.lua/xivcrossbar.lua from the preceding test ZIP,
stopping and restarting the reader. That restores opt-in behavior.

Verification: 43 mocked Lua suites and 120 normalized Lua 5.4 parse checks. New
runtime profile-matching test proves an all-slot reader accepts numbers 1/16 when
status says 2, rejects a different profile/protocol, preserves the running process
for a device-only request, and retains legacy/stopped-reader rules. Existing
DirectLink source expectations updated to require profile ownership without
number gating. Windows harness now requires all-slot/build markers for ordinary
launches and profile restarts; single-slot decode fixtures call the single-slot
reader directly. Windows/AHK tests remain unexecuted (no interpreter available).
No new live/hardware pass is claimed. Mapping generation check passed.
Publication remains local pending earlier GitHub push approval.

---

# Current Development Status — Selected-profile all-slot reader experiment

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Starting checkpoint `149b10e`. User authorizes scanning all addresses for the
selected profile/backend, without cross-profile mapping detection or mixing.

2026-11-11 delivery: `XIVCrossbar-All-Profile-Slots-Test.zip`.
Normal launcher remains single-device. Optional `controller-all-slots.ahk`
starts the same shared reader with all-slot mode enabled. It retains the saved
profile, reads only that backend (WinMM/DirectInput addresses 1–16 or XInput 1–4),
and applies the unchanged profile mapping to every address. Raw per-source input
is combined into one logical stream after mapping: any-source down, all-sources
up. There is no per-source profile inference or PS/Xbox mapping combination.
Newly connected sources must release all mapped buttons and PS before acceptance.
Disconnected sources drop their held state. Movement uses the strongest single
source vector rather than adding axes; PS retains correct pressed/released edges.

The same existing mutex prevents competing readers. Existing focus, DirectLink,
menu/Trust and last-client lifecycle paths remain. Test startup clears a stale
stop marker only after acquiring the mutex. Status and unified diagnostics add
scan mode/connected/active slot fields. Source changes go to
`data/controller-all-slots.log` (bounded at 2 MiB). Entries contain profile,
connected/active slots and per-slot 14-button bitmasks/PS state; they do not prove
physical identity or distinguish virtual duplicates automatically.

IMPORTANT: saved device number/status matching and the native guard attachment
remain unchanged for compatibility. Reader sampling ignores that number in test
mode. Another pad may still leak native input because the game/guard attachment
has not been redesigned. This experiment measures overlap and input acceptance;
it does not establish automatic native matching. Near-simultaneous duplicate
sources may still produce extra edges if their reported holds do not overlap.

## Install and try (FFXI may remain open)
1. Run `//xb controller stop`, wait for the current reader to exit (about 2s).
2. Overlay this ZIP's xivcrossbar folder on the current installation. Keep data.
3. Run `controller-all-slots.ahk` from inside the xivcrossbar folder with AHK v2.
   It reads the saved profile from data/controller-launch.ini. Do not change
   profiles during this run: the addon's profile switch starts the normal reader.
4. Reload XIVCrossbar on clients for the added status/diagnostic fields. A running
   test reader already matches the saved profile and is retained by startup.
5. Release controls, focus FFXI, run `//xb controller status`; Reader Slots should
   say All profile slots (test). Device number still describes the saved/native
   selection; it is not the test reader's input gate.
6. Try one controller, reconnect it, then additional compatible controllers over
   USB/Bluetooth. Check buttons, trigger banks, menus, holds, client switching,
   duplicate actions and native leakage. All addresses use the selected profile:
   a different-model pad is not automatically assigned a different mapping.
7. Send data/controller-all-slots.log plus a unified diagnostic if anything is odd.
Rollback: `//xb controller stop`, wait for exit, then `//xb controller start`.
That starts the regular single-device reader again. No FFXI restart is required.
To restore original files entirely, restore ffxi_directinput.ahk from the previous
build; the optional extra scripts can remain unused.

## Verification and limits
Five mocked Lua suites passed (diagnostics, runtime launch planning, startup
notices, client registry and profile lifecycle); all 119 Lua files parsed after
temporary Windower normalization. Mapping generation check and include closure
checks passed. Normal and test entry points resolve their seven/eight script
include closures respectively. Python packager compiles. Windows AHK regression
fixture extended for overlap, final-source release/disconnect, neutral arming,
slot 16, XInput range restriction and no-device behavior. Its staging harness now
copies controller_slots.ahk. THESE AHK TESTS WERE NOT EXECUTED: no Windows/AHK
runtime is available here. No controller or live FFXI acceptance is claimed.
Run tests/public_ahk_v2.ps1 with an AHK v2 interpreter on Windows for those checks.
This is an opt-in experiment, not the public beta release default. Earlier
settings write-path/release packaging work remains pending. Commits remain local
pending the earlier GitHub publication approval.

---

# Current Development Status — Black Magic and Summoner binder restoration

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Starting checkpoint `3cfe04b`; GitHub head remains the older published baseline
pending the previous push approval. User reports Black Magic alphabetic ordering,
unorganized/unfiltered Blood Pacts, and spirits mixed into the summon list.

2026-11-11 delivery: `XIVCrossbar-Binder-Magic-Pacts-Patch.zip`.
Black Magic joins White Magic/Bard songs in ascending resource-ID order.
SummonerPact entries put all regular summons before spirits, with ascending ID
inside each group. Blood Pact Rage/Ward now use the prior Pact Binding 1 helper
and level catalog from published source `9f6eac6`: current main/sub SMN level
plus learned, level-eligible summon spells determine binding eligibility.
No pet or active Astral Flow is required to list/bind those pacts. Sort eligible
pacts by required level, then avatar name, then ID. Preserve entry IDs/targets,
custom artwork and generic/shipped Rage/Ward fallback icons. Missing JP data in
the shared spell chooser now defaults to zero. Existing binding assignments and
execution requirements are unchanged.

Catalog provenance: `libs/blood_pact_levels.lua` restored verbatim from
`9f6eac6` (GitHub blob `21160111d73b499b0b0b4278aebfbf2b095c8ddb`). Original
level data derives from LandSandBoat abilities.sql plus official Siren Ward
levels, as documented in the prior personal Pact Binding 1 delivery. This batch
restores that catalog rather than claiming a new current-data audit. Unmapped
pacts remain omitted; merits/JP/Astral Flow remain game-use restrictions, not
additional binding filters. Wyvern/other pet actions do not enter SMN lists.

Validation: 42 mocked Lua suites passed; 119 sources parsed under Lua 5.4 after
temporary Windower syntax normalization. New test executes the actual Rage/Ward,
Black Magic and summoning chooser functions with mocked UI/game data; exercises
main/sub SMN levels, learned/unlearned avatars, above-level exclusion, no native
pet-availability dependency, summon group order, missing JP data, targets and
icon fallback. Existing Trust/White Magic/Song sorts and UI regressions pass.
No live FFXI, Windows or Lua 5.1 execution is claimed.

Install as an overlay on the current build, then reload XIVCrossbar on every
client. No FFXI restart or reader change. Cumulative payload includes preceding
config/availability/flicker changes plus two Rage/Ward fallback icons. User data
is not supplied. Live: check Black Magic order, both pact lists without a pet,
with/without Astral Flow, and the summons/spirit boundary. Verify learned avatars
and level-eligible pacts, then bind one entry and check its target/label/icon.
Flicker-fix live confirmation and all-address reader experiment remain pending.

---

# Current Development Status — Availability colour flicker repair

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Starting checkpoint `3b4d954`. User reports flickering on Cioara and supplied
`client-20261111-090448-656456-2-client.log` (Library source
`libfile_8eb5eb0983548191b76aaead5e2f284a`). Read the attached copy directly.

2026-11-11 evidence: 30-second diagnostic, 1715 frames, full render ring had
51108 overwritten records. Retained drawing entries span the tail of the capture
and contain 5999 native.color calls, with 2999 object/frame pairs containing
both 255/255/255 and 130/130/130. Visibility is Always at both endpoints.
This proves repeated opposing drawing calls, not which pixels Windows displayed;
it does not establish the absence of earlier visibility transitions.

The preceding availability change reset icon/label colours before applying grey
on each frame. Windower may draw between setters. Remove the early icon reset
and choose the final icon/label colours once at the end of each slot update.
Keep normal/menu shades, grey availability, original label colours on recovery,
existing pet/trust cues and geometry/fades unchanged.

Validation: 41 mocked Lua suites and 115 Lua source parse checks under Lua 5.4
with temporary Windower syntax normalization. The availability test executes
the actual final-colour block, requires one write per icon/label, checks recovery
and menu shading, and rejects the original early reset. UI regression suites
cover existing layouts and fades. No live FFXI confirmation or GPU capture.

Delivery: `XIVCrossbar-Availability-Flicker-Patch.zip`; overlay current build and
reload XIVCrossbar on every client. No FFXI restart or native/reader update.
Includes current companion/config files for consistency. Live: leave the same
unavailable slots visible on Cioara; confirm stable grey, then change availability
and open/close the binder to check normal/menu colours. If flicker persists,
repeat the diagnostic while it occurs. All-address AHK experiment remains deferred.
Local commit only: GitHub publication remains pending earlier push approval.

---

# Current Development Status — Grey availability and controller wording

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Starting checkpoint `e47d8e0`. User confirmed synced red tint worked, then chose
the original grey for all availability causes; pink is deferred.

2026-11-11 delivery: `XIVCrossbar-Grey-Controller-Messages-Patch.zip`.
Known JA/WS availability now uses the game's lists regardless of Level Sync;
missing known actions use grey (130/130/130) instead of red. Ordinary pet-command
and existing pet/trust availability rules remain. No bindings are rewritten.
Spell eligibility and arbitrary macro interpretation are not expanded here.

Visibility feedback and status display `On Input`, `Always`, or `Hidden` while
saved values remain unchanged. Normal startup feedback is `Starting controller...`,
`Controller ready.` (green after a matching connected ready heartbeat), and
`Controller already running.` A cancelled launch cannot announce ready. A bounded
10-second readiness check reports a missing controller or incomplete readiness
with `//xb controller status` as the next step. Normal startup no longer includes
the device/modifier string; detailed status retains profile and device selection.

Checks: 41 mocked Lua suites and 115 temporarily normalized Lua 5.4 source parse
checks. New tests exercise actual startup code with observed heartbeat, duplicate
start, selection mismatch, cancellation, missing device and absent heartbeat;
formatting checks verify green survives chat formatting and visibility captions.
Availability tests cover both synced and unrestricted characters. No Windows,
Lua 5.1 or live FFXI validation is claimed for this batch.

Install over the current working build; reload XIVCrossbar on every client.
No FFXI restart. Prior config ownership changes are included for a coherent overlay.
Live checks: show/auto/hide feedback, startup with pad connected/disconnected,
and JA/WS grey/restoration inside and outside sync. Last user-confirmed visual
checkpoint is the preceding red availability build; grey revision is pending.
GitHub publication remains blocked pending the earlier explicit push approval.

Message audit proposals (not changed in this batch): replace shared-wrapper stop
request with `Stopping controller for all clients...`; make selection mismatch
feedback name a corrective command; reduce repeated selected/running fields in
normal status while retaining diagnostics; make native-hook failures state the
specific recovery action. Preserve diagnostic detail rather than hiding faults.
Next separate experiment: all-address input aggregation in the AHK reader.
That experiment is not included in this payload.

---

# Current Development Status — Synced action availability tint

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Starting checkpoint `6960169` includes the prior config ownership repair; that
commit remains local because automatic approval review rejected its GitHub push.
User approved dimming/red treatment for abilities and WS unavailable under sync.

2026-11-11 delivery: `XIVCrossbar-Synced-Actions-Patch.zip`.
While buff 269 (Level Sync) or 143 (Level Restriction) is active, sample
`windower.ffxi.get_abilities()` every 250 ms. Known job abilities (including
job-ability-backed pet actions) and weaponskills absent from their respective
lists receive a dim red icon tint and muted red label. Linked custom actions
use their linked metadata; arbitrary macros, spells, unknown actions and ordinary
pet commands are unchanged. No bindings or action dispatch are altered.
Availability restoration resets the tint; unavailable slots do not advertise
skillchain opportunities or recast-ready flashes. Missing API/list data leaves
the availability cue inactive rather than guessing. The game's lists can reflect
weapon/unlock restrictions as well as levels; red means unavailable under the
current restriction, not proof of a specific level requirement.

Validation: 40 mocked Lua suites passed. 114 Lua sources parsed under Lua 5.4
with temporary Windower syntax normalization. New tests cover list membership,
JA/WS ID separation, learned pet actions versus pet commands, linked actions,
unknown metadata, empty/missing lists, sync/restriction removal, tint restoration
and the actual UI sampling block. Full existing UI, Auto hold and config registry
regressions passed. No live FFXI or Lua 5.1 execution was available for this batch.

Install over the current working build and reload XIVCrossbar on every client;
no client restart or native/reader update. Package includes the earlier config
ownership files to keep this overlay coherent. No data/settings are supplied.
Live check: bind one low-level and one higher-level JA/WS, enter sync, verify
only unavailable actions tint, change synced level, then remove sync and verify
normal colors return. Check a bound WS after a weapon change while synced and
confirm recast dimming, compact/full layouts and fades remain readable.

References checked: Windower/Lua wiki FFXI-Functions (`get_abilities`) and
Windower/Resources `resources_data/buffs.lua`; existing GearSwap consumers use
these numeric ID lists. Current installed game-list refresh timing needs live
confirmation. Prior malformed XML/concurrent saves investigation remains open.

---

# Current Development Status — Config registry ownership repair

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Source checkpoint: `c01ba0db0d71c3ee38dcff0c24f095e2998bda71` (same tree as local
Auto hold checkpoint `7bbf996`). User reports Auto hold now behaves as intended,
but shared `libs/config.lua:339` raises `meta` nil.

The private config copy advertised itself as `_libs.config`, while addon modules
also used a mutable global `config` reference. Private and shared config copies
have separate settings registries; a shared save cannot own a private table.
The private module now leaves the shared singleton intact and explicitly loads
it for companion libraries. All five addon config consumers keep a local import
of the private module. Global inheritance and Auto hold behavior remain intact.

Validation: 39 mocked Lua suites passed and 112 Lua sources parsed under Lua 5.4
with temporary Windower syntax normalization. New ownership test executes private
load/save with stubbed parsing, serialization, collections and I/O, verifies both
registries save independently after global replacement, and checks all consumers
import explicitly. UI fixtures now mock that explicit import. This is not live
Windower/FFXI verification, nor a reproduction using the user's installed library.

Install `XIVCrossbar-Config-Ownership-Patch.zip` over the current patched build;
reload XIVCrossbar on every client. No native DLL/reader change or FFXI restart.
Change Auto hold, reload, and check it persists without the config error. Then
continue normal multibox play. Malformed XML/concurrent writes remain unresolved.

---

# Current Development Status — Auto hold keeps the idle layout visible

Baseline `5fb06921a0a9a8f86c26320da9f6f16ec7881671`.
Auto hold now extends visibility after release while the displayed bank follows
the current input. Releasing the last trigger or shoulder restores the normal
Show-mode idle layout during the hold. The 75 ms two-trigger handoff is unchanged.

Run `//xb auto` and `//xb autohold 1.5`. Release each regular trigger,
combined trigger, double-tap and shoulder bank. The ordinary layout should remain
visible briefly, then fade. Press another trigger during the hold and verify it
takes priority immediately. Check scaling and fades both on and off.
Live visual confirmation is pending.

---

# Current Development Status — Settings inheritance

The uploaded working build remains the runtime baseline, with revision 3 default.
The user confirmed recurring Cioara overrides resembling addon defaults.

A reproduction executed the Windower config.lua source and supporting libraries
through Lua 5.4 with syntax-only compatibility normalization. Myrr saving a file
with global compact=true, five bars, and only a Cioara opacity override produced
Cioara compact=false and three bars. The addon-local library copy instead
preserved only Cioara's explicit opacity override. The shared Windower library
is not modified. Original library license is retained in the local copy.

Install this patch and reload XIVCrossbar on all clients using this addon.
Test one client saving a preference, then reload another and check its global
inheritance and explicit character preferences. Existing explicit overrides,
including previously manufactured overrides, are preserved.

This fixes the reproduced inheritance defect. Concurrent saves and malformed
XML remain under investigation. This simulated result does not establish which
Windower library version is installed on the user's PC.

---

# Current Development Status — November 10, 2026 — Reloadable actions and armed PS probe

Branch `feat/reloadable-controller-logic`. Starting checkpoint
`ceeb3a599123fddb2ab7b1b6ab490a684b2b9adf`.

Close FFXI before installing this matching hook and policies. The hook dispatches
numbered actions to the loaded policy under its callback mutex. Tab/Shift+Tab
implementation is now inside each policy DLL. Future compatible action changes
can be installed using a new numbered policy and Lua update.

1. Load logic 3 and enable bank targeting. Check targetless L1+R1 acquisition
   and selected-target L1/R1 cycling on press. Switch policies live.
2. Run `controller-discovery.ahk`, release controls, and press PS. Select
   its responding row, then choose Arm selected PS input and confirm the
   API, slot and button. Set the addon's PS bridge off during the probe.
3. Focus a non-FFXI application, return to FFXI, then press PS. Press PS
   again to return to that same client. Disarm PS ends
   the probe. A device-list change disarms it automatically.
4. Identify a pad with a face-button press, select the desired row/profile,
   and confirm to copy its selection command. Paste in FFXI and check live
   polls with `//xb nativepad status`.

The scanner retains duplicate entries and logs the visible inventory.
Automatic persistent reconnect identity and matching against FFXI's polled
device remain future work. PS requires an exposed button event in this probe.
Physical acceptance is pending.

---

# Current Development Status — November 10, 2026 — Controller discovery diagnostic

Branch `feat/reloadable-controller-logic`. Starting checkpoint
`1b83d8312d7f13a0fc51794246ba34ea497f99c2`.

Run `controller-discovery.ahk` with AutoHotkey v2. Release all buttons,
press a face button, then PS separately. The utility enumerates all 16 WinMM
slots used by the current DirectInput reader and all four XInput slots.
It shows every responding entry. Select a row and profile, then confirm to
copy the existing profile-selection command. Paste it into FFXI and inspect
`//xb nativepad status` for game polls. Save the report after testing PS.

Controller type detection uses the reported name and requires confirmation.
This diagnostic cannot prove two API entries represent the same physical pad,
or establish persistent identity across a reconnect. Device list changes
reset its button baseline. Guard matching and reconnect identity work remain
pending the physical-device report.

The Windows workflow parses the script and exercises enumeration without
controllers. Hardware selection and PS detection require live testing.

---

# Current Development Status — November 10, 2026 — Targeting on press

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `feat/reloadable-controller-logic`.
Starting checkpoint `7cc8e4ebf9628a4bded5f5d33c95ae8ed9d06224`.
This overlay uses the matching Windows x86 hook and policy binaries from that
checkpoint. Close FFXI before replacing the hook. Keep the existing addon data.

1. Wait for the guard, then run `//xb nativepad logic 3` and
   `//xb bank targeting on`.
2. With no target, hold one shoulder and press the other. Confirm that
   `/targetnpc` runs immediately on the second press, in either order.
   Single presses should leave the target empty.
3. With a target selected, press L1 and R1 separately. Confirm Shift+Tab and
   Tab happen on press. A simultaneous chord and all releases send no
   targeting action. With staggered presses, the first shoulder can cycle
   immediately and the second does not acquire an NPC.
4. Check the combined bank, native menus and chat, and switch to revision 1
   to confirm the previous behavior remains available.

Mocked Lua routing covers these press edges. Live FFXI acceptance is pending.

---

# Current Development Status — November 10, 2026 — Shoulder targeting revision 3

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `feat/reloadable-controller-logic`.
Starting checkpoint `c5fc9eb4169c0320fd96b9e34adb993a37541e65`.
Install the matching resident DLL with FFXI closed. Keep the addon data.
The resident hook adds guarded Shift+Tab. The ownership ABI is unchanged.

1. Wait for the native guard, then run `//xb nativepad logic 3` and
   `//xb bank targeting on`. Tap both shoulders, in both orders. The last
   release should send `/targetnpc` once.
2. With no target, each shoulder tap alone should leave the target empty.
   With a target selected, R1 should send Tab and L1 should send Shift+Tab.
3. Hold a shoulder longer than 350 ms, use a bank slot, press a trigger, or
   open a menu while held. Confirm the release does not send a shortcut.
   Verify a bound combined-bank slot still fires once. Try a native menu,
   chat, and a client switch.
4. Switch to logic 1 or 2 and confirm the previous R1 behavior returns.
   The Xbox RB chooser profile retains its chooser assignment.

The routing fixture checks the real Lua callback for both shoulder orders,
target eligibility, and cancellation. The Windows fixture compares native
ownership across all three revisions. Live FFXI acceptance is pending.

---

# Current Development Status — November 10, 2026 — Reloadable controller logic

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `feat/reloadable-controller-logic`.
Starting checkpoint `162efaeab0931d928236c6f11721c5b803962cd5`.
The x86 hook remains resident and loads its ownership policy from a numbered
DLL. Both trial revisions implement the current shoulder and trigger rules.

1. Back up the installed addon and data, close all FFXI clients, and overlay
   the matching test build. Keep the existing data. Start FFXI, wait for the
   guard, and confirm that `//xb nativepad status` shows revision 1.
2. Release the pad and run `//xb nativepad logic 2`. Confirm the status shows
   revision 2 and that trigger banks, shoulder banks, and native menu input
   behave as before. Repeat with revision 1, without closing FFXI.
3. Try `//xb nativepad logic 999999`. The current revision should remain active.
   On a second client, verify the first client's swap did not change its revision.
4. Hold a shoulder or trigger across a swap. A fresh press after releasing the
   pad should work. Check both XInput and DirectInput, including a native menu.

The Windows fixture checks the ABI, rejection of missing and incompatible
modules, revision swaps while polling, and cleanup of the previous module.
The actual controller and FFXI checks above require a live session.

---

# Current Development Status — November 10, 2026 — Keyboard ownership and HUD controls

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `83af1ec65ff72eab5d5e601965a61b51839ebb09`.
Windower 4 public beta, using the matching Event banks build as the overlay base.
The user reported keyboard navigation reaching FFXI beneath remap and custom-action screens.

1. With a native menu underneath, open `//xb remap` and try the arrows, Enter,
   keypad Enter, and Escape. Hold Enter from profile selection into the next
   page. Hold Escape as the addon screen closes. Release each before trying
   a fresh key. The native menu should only receive the fresh press after
   the addon gives up keyboard ownership.
2. Repeat through Create Custom Action, its text fields, icon picker, and
   review. A physical arrow press should move one step. Enter should commit
   or advance once. Back out with Escape and check the native menu and camera.
3. Check setup and `//xb controller status`, `//xb nativepad status`,
   `//xb diagnose status`, and `//xb help`. Check the PlayStation 5 label,
   waiting for client focus or game polls, and an actual hook failure.
4. Run `//xb auto` and `//xb autohold 1.5`. Release a single trigger,
   a centered bank, or a visible shoulder bank. The last displayed bank
   should stay briefly before fading. Native controls should resume on
   release according to the existing controller rules. The 75 ms center
   handoff still applies while a trigger stays held. Repeat with fades off,
   and check `//xb show`, `//xb hide`, focus loss, and Event bars.
5. With trigger scaling on, try both slot name alignments. Text should
   retain its size while following the bank. Try `//xb costalign left`,
   `center`, and `right` with changing MP, TP, and quantities, then add a
   `//xb costoffset <x> <y>` and restart to confirm persistence.

All 37 mocked Lua suites passed and 109 sources parsed under the test runner's
Lua 5.4 syntax normalization. The starting branch had a stale lockout visibility
test fixture. Its input now supplies the effective visibility mode. Live
keyboard propagation, controller status, and visual checks remain pending.

---

# Current Development Status — November 10, 2026 — Event banks

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `41dd0e319a91cc1da9f8d404b9a0f7d15ee6535b`.
The user reported losing access to crossbar commands during a warp event.

1. Overlay the patch and run `//xb restart`, then `//xb eventbars on`.
   In Show, start a dialogue choice or warp event. The bars should tuck
   away while idle and appear when a trigger or visible shoulder bank
   is held. Release it, then finish the event and check Show returns.
2. Repeat in Auto. Try L2/R2, both trigger orders where configured,
   double taps, and enabled L1/R1/L1+R1 banks. Try a bound NPCMirror
   command or window-switch action while the choice is open.
3. Check that chat and addon menus retain input ownership. `//xb hide`
   keeps gameplay bars hidden. `//xb eventbars off` restores the prior
   Event behavior. The preference is independent of the display preset.

Six mocked Lua suites passed. They cover Event visibility in both
modes, restoring Show after Event, native shoulder capture masks, and
Lua slot dispatch during Event. Live choice and warp checks are pending.

---

# Current Development Status — November 10, 2026 — Shoulder banks in battle

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `f792bcd385da400b780f83782eed2b1c87eaeb83`.
The user confirmed the bank labels now center correctly. They reported
shoulder-bank slots and drawing being suppressed in battle and requested
a silent automatic DirectInput match.

1. Overlay the patch and run `//xb restart`. Automatic success is quiet.
   `//xb nativepad status` still includes the match when the single-device
   fallback was used. An attachment failure still reports itself.
2. With shoulder banks enabled and visible, engage and hold L1, R1, and
   L1+R1. Confirm each bank appears and a bound slot dispatches once with
   the battle palette open. Check normal trigger priority.
3. Outside combat, confirm a native menu retains shoulder-slot ownership.
   Check chat, cutscenes and addon menus. R1 targeting still respects the
   native menu flag.

Six mocked Lua suites passed, including capture masks, actual Lua
dispatch under the native battle menu flag, and quiet automatic matching.
Live combat and DirectInput startup confirmation are pending.

---

# Current Development Status — November 10, 2026 — Trust Return and recast glow

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `cefdd12ca00c655cc6947529979e88fa2e109511`.
The user confirmed cost offsets felt good and reported Moogle's portrait
turning into a white square on Return. They also saw a bright white square
on the first recast-ready flash.

1. Apply the patch and run `//xb restart`. Summon Moogle from a typed Trust
   slot. It should keep its summon portrait, change its name to Return,
   and show a pink X at the recast timer position.
2. Press the Return slot and watch the party list. Once Moogle is gone,
   the X should clear and the summon label should return. Repeat with
   a Trust whose slot has a custom portrait.
3. With Recast Flash on, check the first recast-ready flash after restart
   and compare it to later flashes. The texture is now configured at
   zero opacity during the cooldown. Native image settings are isolated
   per surface. The first visible FFXI frame still needs confirmation.

Six mocked Lua suites passed, including native and custom portrait
preservation, the Return-to-summon transition, and early glow setup.

---

# Current Development Status — November 10, 2026 — Bank caption centering

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `56d752211935051ebdf38653e3d5ecea8c324e7d`.
The user confirmed independent outline colors and liked the recast timers.
Several rarely shown banks still appeared right of center. A hidden
caption could spend the full width-settling window without drawing,
and a zero-width fallback could persist after native extents recovered.

1. Apply the patch and run `//xb restart`. Wait before first showing
   `R2x2`, `L2x2`, the combined bank, and `L1+R1`. Compare each label
   with its own bank at a horizontal bank label offset of zero.
2. Check a recast timer. It is nudged 2 layout pixels right, with
   its vertical anchor still 13 pixels below the top of the 40-pixel slot.

Five mocked Lua suites passed, including hidden captions and recovery
after a zero-width fallback. Live centering is pending.

---

# Current Development Status — November 10, 2026 — HUD text rendering

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `e55e9a7018652d8adc7e9a8b36417a891b433b54`.

The user reported outline color changes after bank opacity updates and
restart, blinking centered slot names during TriggerScale, and uneven
bank-label placement. The saved XML has black slot outlines and centered
slot names. The supplied diagnostic is input-only and predates the report.
Windower retains the supplied text options table, so HUD text objects now
receive independent native settings. Centered text keeps stable font metrics
during bank scaling. Bank labels anchor to the full width of their own bank.

1. Apply the patch and run `//xb restart`. Set `//xb slotlabelstroke black`
   and `//xb banklabelopacity 60`. The bank outline should stay gold.
   Restart and check both again.
2. With `//xb slotlabelalign center`, rapidly switch trigger banks and look
   for caption blinking. With horizontal bank offset zero, compare the
   `R2x2` and `L1+R1` labels with the actual widths of their own banks.
3. Use an action with a recast. Check the centered white size-10 timer
   with a black outline. Try `//xb costoffset -8 -24` to move costs and
   item counts toward the top-right. `0 0` restores the old anchor.

Seven mocked Lua suites passed, including a Windower-style shared-settings
regression, stationary font metrics during trigger scaling, timer placement,
and cost offset application. In-game alignment and readability are pending.

---

# Current Development Status — November 9, 2026 — Label layout controls

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `f4b4c0c862d38b5ba8955f7cf9a299903ab77d65`.
In the live build the user saw some bank labels overlap slot action names
and reported that their outlines appeared to change together. The two
label types have independent outline colors. Slot amber uses the original
darker amber. The bank outline uses the brighter binding-highlight gold.

1. Overlay the Lua patch and run `//xb restart`.
2. Try `//xb banklabeloffset 0 -8` and `//xb slotlabeloffset 0 4`.
   Positive offsets move right and down. `0 0` resets each anchor.
3. Use `//xb slotlabelalign center`, then `left`. Check captions while
   switching sets, layouts and banks.
4. Try `//xb banklabelopacity 160`, `0`, then `255`. The setting affects
   the bank label's fill and outline. Check it during a fade.
5. Try `//xb slotlabelstroke amber`, then `black`. Watch that only
   slot action names change outline color. Restart and check persistence.

Seven Lua suites passed with mocked Windower surfaces, including separate
outline colors, offset geometry, centered-to-left text settling, and
bank opacity composed with fades. Live spacing is pending.

---

# Current Development Status — November 9, 2026 — Bank label styling

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `bcf081d82fa6cadaf7267a170fe4fc38212a4412`.
The first label pass was larger and darker than desired in FFXI. Slot
captions continued to inherit the saved theme stroke. The revised bank
font is 6% smaller before Windower rounds the rendered size to an integer.
It uses the brighter binding-field gold and stays fixed through bank
scale and slide while still following bank and HUD fades. Moving or
scaling the whole HUD still moves or scales the labels.

1. Overlay the patch and run `//xb restart`. Compare labels with
   TriggerScale on. Check size, contrast and position as banks switch.
2. Use `//xb banklabels off` during a fade, then `//xb banklabels on`.
   Check that bank labels alone are hidden and restored.
3. Try `//xb slotlabelstroke amber` and `//xb slotlabelstroke black`.
   Check that only slot action names change outline color. Restart to
   verify both settings persist.

Seven Lua suites with mocked Windower surfaces passed. Live contrast
and perceived size are pending.

---

# Current Development Status — November 9, 2026 — Crossbar labels

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `c88ac80d4d27491635942ed4a4b7eea2fe32e098`.
The user reported the combined-bank release patch did the trick in FFXI.

Each visible bank now has a white label with a dark amber outline between its
two upper slots. The labels follow the bank position, scale, slide, and
existing text fade policy.

1. Overlay the Lua patch and run `//xb restart`. With both side banks shown,
   check `L2` and `R2` placement in compact and full layout.
2. In five-bank mode, hold both triggers to check `R2+L2`, and double-tap
   each trigger for `L2x2` and `R2x2`. In six-bank mode check both trigger
   orders, `R2>L2` and `L2>R2`.
3. Check the shoulder labels `L1`, `R1`, and `L1+R1` when their banks are
   visible. Move or scale the HUD and verify the labels stay centered.
4. In Auto, repeat quick paired releases with Fade On and Off and check
   that the center label disappears with its bank.

Six Lua suites with mocked Windower surfaces cover label text, layout
anchors, bank ownership, visibility and release/fade behavior. Font
placement and amber contrast still need a live FFXI check.

---

# Current Development Status — November 9, 2026 — Combined-bank release

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `92065c119a532fe5aa03bfa0496670f15bd48eae`.

In Auto, the combined L2/R2 bank keeps its visual selection for 75 ms after
the first release. A second release within the window fades or hides the
center by itself. If one trigger stays down, the side pair replaces the
center in the next draw after the window. Gameplay continues to route using
the physical triggers.

1. Overlay the Lua patch and run `//xb restart`. Use Auto with TriggerScale.
2. With Fade On, hold both triggers and release them in quick succession.
   Check that only the center fades. Repeat while still moving into center.
3. Hold both, release one and keep the other held. Check that the side pair
   takes over without the center fading on top. Press a slot immediately
   after the first release to verify that the remaining trigger owns input.
4. Repeat with Fade Off. A quick paired release should hide the center
   directly. A sustained single trigger should reveal the side pair.
5. Repeat both trigger orders in six-bank mode. Confirm a trigger repress
   or opening the addon menu clears a pending handoff.

The capture ending in `215759-744394-1-client.log` contains 44 paired
releases from center. Twelve were routed together, and 31 more arrived
within 75 ms. Six Lua test suites passed with mocked Windower surfaces,
including both fade settings, both TriggerScale settings, same-frame
releases, re-press, menu cancellation, and the preserved travel into center.
Live FFXI verification is pending.

---

# Current Development Status — November 9, 2026 — Compact HUD hints

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `fd6c68a06ffc9fa2dd6981828ee74ea79b978f32`.
Compact mode skips creation of the Options/Share HUD hints. Switching from
full to compact disposes the hint images and captions immediately, including
during a fade. The set chooser computes its anchor from the layout.

1. Overlay the Lua patch and run `//xb restart`.
2. In XI compact and Auto, tap L2/R2 rapidly with Fade On, then Off, then
   On again. Options and Share hints should stay absent.
3. Hold Options in compact and check that the chooser opens at its normal
   anchor. Switch to full and verify both hints return, then back to compact.
4. If a hint still flashes, capture one occurrence and stop immediately.
   Capture state includes the actual layout, fade option and hint allocation.
   Fade commands are recorded separately from high-volume draw calls.

### November 9 — Options hint follow-up

The full capture ending in `215434-528375-7-client.log` recorded 137 routed
L2/R2 edges. The render ring overwrote 222,563 entries and retained roughly
the last half-second, without enough data to identify the flashing object.
Mocked layout and lifecycle tests check compact startup, removal of full
hints during interrupted fades, and restoration without growing the live
resource count. Live FFXI verification remains pending.

---

# Current Development Status — November 9, 2026 — Set chooser rendering

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `29730f1347238a6d8835df72fd7098e554e74e01`.
The Lua overlay keeps bank visibility in the render pass and writes each
slot's resolved icon directly when a set changes. In the binder, an inherited
source badge replaces the cost and recast overlay for its slot.

1. Overlay the Lua patch and run `//xb restart`.
2. With XI, Auto and Fade On, hold Options, highlight Add New Set, then
   release Options. Watch that only the side bars fade. Repeat after entering
   and backing out of name entry, in compact and full layouts.
3. Scroll quickly through sets with different bindings and shared inherited
   icons. Check that the selected set's art stays steady between changes.
4. With the binder open, hold Options and scroll sets. Inherited ALL/JOB
   badges should stay steady, with no MP/TP cost flashing underneath. Close
   the binder and check that regular costs and recast overlays return.
5. In XI compact, tap L2 and R2 quickly with Fade On and again with Fade Off.
   If the Options hint still flashes, start `//xb diagnose start render`,
   reproduce once and run `//xb diagnose stop` immediately.

### November 9 — Set chooser and hint diagnostic evidence

The compact full capture ending in `214606-288162-1-client.log` retained the
late set-scroll rendering and overwrote 98,982 render records. The supplied
full-size set, Options hint, and inherited-badge captures recorded input only.
The later full capture ending in `215242-454624-6-client.log` retained 522
same-frame repeated image path writes and 95 same-frame show/hide pairs for
text surfaces. The render trace redacts art paths and caption contents. The
set-refresh fixture asserts that inherited badges and costs no longer issue
competing visibility calls, and that refreshing a set preserves the current
reveal in compact and full layouts. The Options flash still needs an isolated
render capture if it persists. Live visual verification is pending.

---

# Current Development Status — November 9, 2026 — Superwarp city folders

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `0c8a53f89557214f8644477be88ea8bede5eea9e`.
This ports the November 7 Public Beta Superwarp city-folder overlay from
its `206bbde` base into the current binder.

Apply the combined Lua patch and run `//xb restart`. Open Action Binder,
choose Superwarp, and check that Bastok, San d'Oria, and Windurst appear
before the remaining alphabetical destinations. Choose a numbered Home
Point or Survival Guide and verify the stored command. Back from binding
should restore the city page. Back again should restore the root city row.

The Lua fixture covers the three folders, 38 numbered Home Points,
3 Survival Guides, scope preservation, and both Back transitions. Warp
landing landmarks still need in-game confirmation.

---

# Current Development Status — November 9, 2026 — Custom-action icon picker

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `2e459a0015ef57f883a5ced63300cb86aea9e21b`.

Overlay the Lua patch and run `//xb restart`. Edit the Quests custom
action, select Choose Icon, and confirm the title identifies Quests.
Open a folder and check its breadcrumb. Without switching focus, tap
R2 then L2 and repeat after Back and re-entry. A trigger already held
on entry must be released before it can page on the next press.

The user reported that paging resumed after focus changed. The fixture
covers stale binder trigger flags and successful paging in both
directions. If it still stalls in Windower, collect a full diagnostic
through the failing taps and focus change so the input and render paths
can be compared.

---

# Current Development Status — November 9, 2026 — Delete from custom-action review

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `45f9fdb`, with the XI preset and keyboard changes in
this batch. Apply the combined Lua overlay and run `//xb restart`.

Edit an existing custom action and check that Delete Custom Action is
last, after Link Action. Enter confirmation, then press Escape or Back.
The draft should return intact. If you changed the name without saving,
confirmation should still identify the original catalog entry. Confirm
on a disposable entry and check the catalog. An unsaved new action
should have no Delete option.

The Lua fixture exercises the real review and catalog callbacks for
cancel, unsaved rename, failed write, and successful deletion. Live
keyboard capture and menu rendering remain to verify.

---

# Current Development Status — November 9, 2026 — Modal keyboard ownership

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `45f9fdb`, with the XI preset changes in this batch.

Apply the Lua patch and run `//xb restart`. Open remap or a custom-action
review over a native menu. Try each arrow, Enter, and Escape. The native
keyboard should be blocked while the addon screen owns it. Tap an arrow
and wait a second. The cursor should only move once. Controller D-pad
holds should still repeat. Try typing a name, going Back, changing focus
between clients, and closing the addon while holding a navigation key.
Verify normal native keyboard input returns on leaving the addon menu.

Lua checks cover one-step dispatch, release after changing screens, and
guard transitions. Verify the Windower input block in a live client.

---

# Current Development Status — November 9, 2026 — XI preset and set labels

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `45f9fdbd4bf20872c248548c36866ec8f1e8d552`.

Apply the Lua patch and run `//xb restart`. Reapply `//xb display xi` to
activate Slot Glow, Recast Flash, and TriggerScale in an existing XI setup.
Check the toggles with their individual status commands. Override them
individually to compare effects.

Open the set chooser and both set-switch pickers. Verify ALL, the main-job
abbreviation, the job/subjob pair, and Main. With no subjob, the job-pair
label uses the main job alone. Try switching with existing bindings and
by saved key. Switch to Legacy and verify the previous labels return.

Local Lua checks exercise the preset and destination keys. Live drawing
and keyboard ownership are separate acceptance checks.

---

# Current Development Status — November 9, 2026 — Setup selection controls

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Starting checkpoint `d5a3793018f73b1691808ea3d20683b9044f1d20`.
Windower 4 x86 and the existing AutoHotkey v2 reader.

Cioara completed setup on the attachment-recovery build after manually
selecting PlayStation 5, Device 2 and then clicking the profile tile.
The initial click alone did not proceed. The exact cause of that
initial failure remains open. Device discovery is a separate pass.

Overlay this Lua patch on the attachment-recovery build and run
`//xb restart`. Then use `//xb remap` on a client you are comfortable
remapping. A first-time installation can also test the Welcome page.
Use the same device slot that already worked on Cioara.

1. On Welcome, check the Enter-or-click prompt and tap Enter. Hold it
   long enough to repeat and verify that it advances only one page.
2. On Input Profile and Button Artwork, use the arrow keys, hover a
   different tile, then resume with the keyboard. The animated gold
   cursor and amber highlight should follow one shared selection.
   Confirm once by keyboard and once by mouse on separate passes.
3. Open setup over an FFXI menu. Click blank panel space, right-click,
   and scroll inside and outside the panel. FFXI should receive only
   outside input. Drag from inside to outside and outside to inside.
   Each release belongs to the side that received the press.
4. Confirm artwork and verify the cursor disappears. Map buttons with
   the existing controller prompts. Cancel and reopen setup to check
   that the previous click cannot activate a new page.

The Lua fixture exercises the real wizard handlers with a simulated
Windower host. Physical input capture, visuals, and panel layering
remain live acceptance checks.

---

# Current Development Status — November 9, 2026 — Native attachment recovery

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Starting checkpoint `03aa76ad921dd41b46ff966ba43dc6fc7b931664`.
Build `0.4.0-beta1.20261109.hook1`, Windower 4 x86 and AutoHotkey v2.

Cioara reported that FFXI read the DualSense over USB and the reader showed
PlayStation 5, Device 2, Connected and Ready. Profile selection succeeded,
then the native hook was unavailable and face-button mapping stalled.
A similar hook failure was reported over Bluetooth. The exact failed
operation was unavailable in that build.

Install the complete matching x86 build with all FFXI clients and the
shared reader closed. Keep the existing bindings and controller settings.

1. Connect the DualSense by USB and start Cioara. Leave the reader on Device 2.
   Check `//xb controller status` and `//xb nativepad status`. If the fallback
   is used, chat reports the sole-controller match for Device 2. The guard
   still needs FFXI to poll the selected device and DirectLink to join.
2. With filtering active, select the layout and map R2 plus a face button.
   The setup prompt should advance once and FFXI should receive no
   underlying face-button action. Verify bare native input after setup.
3. If attachment still fails, copy the full Hook Unavailable line with its
   operation and hex code. `//xb nativepad status` repeats it. With the
   intended device connected, `//xb nativepad auto` retries once.
4. Repeat after a clean Bluetooth launch with its detected reader slot.
   With two controllers connected, confirm the fallback does not select an
   arbitrary device. A valid Windows joystick-ID mapping still takes priority.

Local Lua fixtures cover failed status persistence, retry reset and detail
propagation. The portable C++ input fixture passes. The Windows host fixture
now checks the DLL's Lua attachment error return. Actual USB and Bluetooth
attachment in FFXI remains the acceptance check.

---

# November 8, 2026 — Getting started and command help

Branch `integration/shoulder-banks`. Overlay this Lua patch on the
input diagnostics build at `2c7e8a2` and run `//xb restart`.

- Run bare `//xb`, `//xb help`, and `//xb ?`. Each should print the same
  six-line guide. Check Share and Options on PlayStation, View and Menu
  on standard Xbox, and RB on the Xbox R1-chooser profile.
- Run `//xb typo` and `//xb help typo`. Each should name the invalid
  command or topic and print the same short guide.
- Try `//xb help sets`, `//xb help bindings`, `//xb help display`,
  `//xb help controller`, `//xb help diagnostics`, and `//xb help all`.
  Each topic should open on its own and `all` should print all five.
- Check `//xb inputtest status` and `//xb inputtrace status`. Try each
  with a misspelled option and confirm status stays the same. Test the
  explicit on and off options, then restore the original settings.

Lua fixture checks cover the command dispatch and chat output. Windower
chat wrapping and physical controller labels await in-game confirmation.

# Current Development Status — November 8, 2026 — Input-first diagnostics

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint: `4ef0784f8a583d60eb1c66699e06deb4842ecd51`.
Build: `0.4.0-beta1.20261107.diagnostics2`.

Install the matching x86 artifact with FFXI and its shared reader stopped.
Preserve `data/`. Restore the previous program files with both stopped
to roll back.

- Run bare `//xb diagnose`. Press a native D-pad direction, then test a
  held direction followed by L1, an L1 slot, and R2 takeover. Add a
  multiword mark and stop. The single log should link reader sequence,
  Lua receipt, route and slot outcome. It should include native masks
  where available and contain no render events.
- Repeat over Trust with `bridge menu test`, then live. Check the
  difference between dry-run status and a claimed navigation edge.
  Move focus to another client during the capture. Its AHK input
  should not appear in the original client's reader feed.
- Start a `render` capture and check that extents and positions remain
  while captions and paths are omitted. `full` includes both streams.
  `snapshot` saves state only. Test a pre-login capture without a
  known PID and confirm the wrapper feed is explicitly omitted.
- Test two clients requesting the one shared reader and verify the
  existing reader capture continues. Wait for the save message before
  sharing files. Explicit user marks are included.
- Reader stages use QPC wall-time deltas and record stages at or above
  8 ms during a capture. Native masks are observed samples. Neither
  source establishes what the FFXI UI actually did.

Local fixtures cover capture profiles, stream merging, PID request
shape, redaction, snapshot isolation and message sequence propagation.
Live FFXI and two-client diagnostics remain pending.

---

# Current Development Status — November 8, 2026 — Optional controller bridges

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint: `514e03240b5b5bdbd07aeae00da33c8a86bbbf43`.
Build: `0.4.0-beta1.20261107.bridge-test1`.

Install the complete matching x86 artifact with FFXI closed and the
shared AutoHotkey reader stopped. Keep `data/`. Restore the previous
program files with the clients and reader stopped to roll back.

All features default off. Run `//xb bridge all test`, then
`//xb bridge status`. Test mode reports decisions and adds no native
suppression, Trust output, or focus switch. `//xb inputtest on` also
forces any saved live bridge into test mode.

1. Use the matching Trust build that publishes controller-menu leases
   and integrated movement leases. Open Trust over a native menu. In
   test mode check the “Would route” line. In live mode run
   `//xb bridge menu on` and test a single press, direction repeat,
   Confirm, Back, and a text field. Hold a direction when closing the
   Trust lease and verify native input resumes only after release.
2. With `//xb bridge movement test`, focus an FFXI client with the stick
   centered and move it. Check the reader decision in status. Switch
   clients and check Send and Ready separately. With `on`, verify Trust
   receives its dedicated signal once and native analog movement stays
   intact. Ready waits for a ready receiver and gameplay. The current
   Trust receiver identifies movement leases by character window title,
   as on the personal build.
3. On PS5 DirectInput, focus a named non-FFXI window, return manually to
   FFXI, then tap PS. Test mode reports the remembered destination.
   Live mode switches once. Release and press again within 30 seconds
   to return to the originating FFXI client. A hold, another pressed
   controller button, or a menu blocks a fresh switch. Verify both
   clients and make sure an expired return does not steal focus.
4. With `//xb bridge all off`, check the ordinary beta controls and
   verify the reader reports no new bridge actions.

Portable Lua/native fixtures cover mode and ownership boundaries.
The first Windows run built and passed both native fixtures, then stopped
because the reader test staging list omitted the new AHK include.
Windows x86/AHK CI and actual FFXI/Trust observations are separate
checks. Live input and focus-switch acceptance remain pending.

---

# Current Development Status — November 8, 2026 — Trigger and job parity

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint: `adba856143afdbe4247afae4cdfcb22eda7e1edc`.
Test build: `0.4.0-beta1.20261107.personal-parity1`.

Install the matching x86 artifact with FFXI closed and the reader
stopped. Keep your data folder. Roll back by restoring the preceding
program files with FFXI closed and the reader stopped.

- Use `//xb triggerbanks 5` to reload in five-bank mode. Test both trigger
  orders, then double-tap L2 and R2 separately. Both orders use saved
  bar 3, double taps keep bars 5 and 6, and saved bar 4 returns when
  switching back to six. Check the binding preview and confirmation too.
- With `//xb triggerscale on`, swap from the side pair to the combined
  or shoulder bank and back. Check fast reversals, menus, Always and
  Autohide. The two sides move inward or outward and crossfade with the
  center over 90 ms. Existing scale easing is still 60 ms.
- Bind a learned Trust as a typed spell. Expect the summoned Trust to
  show Return on its own slot and dismiss by name. Check unlearned spells,
  pet-only actions with no pet, and command bindings with linked metadata.
- On SMN, check Assault/Retreat with the pet idle and engaged, and
  paired Attack/Disengage against a concrete target. A matching avatar
  or spirit slot shows Release. A different summon releases, waits for
  the pet to disappear, and casts once. Try zoning and another action
  during the wait. Selector-style attacks remain ordinary attacks.
- Run `//xb jobsets` on a job with eligible magic or pet commands. It
  explicitly creates missing editable category sets for the current
  job/subjob. It preserves existing sets and slots. Run it twice to
  confirm the second invocation adds zero.

Local fixtures cover the five-bank surfaces and interrupted animation,
real dispatch for Trust/pet actions and summon replacement, and additive
job sets. Gamepad visuals and action acceptance remain pending in FFXI.

---

# Current Development Status — November 7, 2026 — Playable shoulder banks

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint: `eb63165f56a34a256216547f3c699124c4a7a5f2`.
Test build: `0.4.0-beta1.20261107.shoulder-slots1`.

L1, R1 and L1+R1 now have eight playable slots each. The normal binder
previews and edits them, even while disabled. Named bank records in
the character's Shared.xml keep bindings separate from job/subjob files
and numbered crossbars. The slot executor and centered combined-trigger
layout are shared with existing bars. Targeting keeps its separate toggle.

Install the full matching Windows x86 artifact with FFXI closed and the
shared reader stopped. Keep the existing data directory. Roll back by
closing FFXI, stopping the reader, and restoring the prior program files.

1. In the ordinary binder choose a Console Command, e.g. `input /echo L1 slot`.
   On Enter Button Combo hold L1 and press a direction or face button.
   Release it, then confirm the tentative binding.
2. Run `//xb bank l1 on`. Hold L1 and press that same slot. Expect the
   centered bank, one command and no native slot action. Release L1 first
   with a direction still held. The direction must stay owned until release.
3. Hold L1, hold L2 or R2, and confirm the trigger bar wins. Release the
   trigger with L1 still held. The L1 bank returns. A slot held across
   either change must not fire twice. Test both shoulder chord orders.
4. Use `//xb bank l1 hide` to test dispatch without drawing and
   `//xb bank l1 off` to restore native input. Re-enable, switch jobs,
   and reload to verify the same slot remains bound. Check binder delete
   and icon changes. On the RB chooser profile, test L1 only.
5. Check menus, focus, chat and older installations with all banks off.
   The earlier R1 targeting live checks still apply.

Simulated coverage includes the real binder confirmation path, shared
storage routing, action execution across sets, centered layout and
trigger priority, and native ownership through release. Physical
controller and in-game behavior remain to be checked.

---

# Current Development Status — November 7, 2026 — R1 targeting and bank selection

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint: `9450d8c71806f44100d542d9e0e6f6f5beefa76d`.
Test build: `0.4.0-beta1.20261107.shoulder-targeting1`.

R1 targeting is opt-in and uses the acknowledged controller stream.
It takes ownership of fresh, unmodified R1 only in gameplay. The Lua
router chooses `/targetnpc` or a Tab tap on the press edge. The receiver
waits for a matching extended reader and native bridge before enabling
targeting. The alternate RB chooser profile keeps its existing role.
The first transport checkpoint passed Windows x86 and Lua CI. Local
checks for this batch cover real routing with simulated inputs, parsed
shoulder chords, portable native ownership, and source packaging.
Actual FFXI targeting and Tab delivery remain to be checked.

## Live test

Install the x86 CI artifact with the matching DLL, Lua and AHK files.
Stop the shared reader before swapping files and preserve the existing
`data/` directory. Restart the FFXI client if it still has the previous
DLL loaded, then start the updated reader. To roll back, disable
targeting with `//xb bank targeting off`, stop the reader, and restore
the prior addon folder and DLL with the clients closed.

1. With targeting off, confirm native R1 behaves as before.
2. Run `//xb bank targeting on`. Clear your target and tap R1 near an NPC.
   Expect the same selection as `/targetnpc`. Tap R1 with a target and
   compare with physical Tab. Hold R1 for a moment and release it.
   Expect one action per press.
3. Try L1 then R1, both shoulders in the same sample, and R1 then L1.
   The first two send no shortcut. R1 first can send once before the
   later L1 edge. R1 while L2/R2 is down should pass through normally.
4. Repeat during a native menu, addon menu, dialogue, or chat entry, and
   switch focused clients while holding R1. No targeting shortcut should
   fire there or replay on focus return.
5. The alternate Xbox chooser must still open on RB. On standard
   XInput and DualSense, compare native passthrough when disabled.

## Bank scaffold

`//xb bank <l1|r1|both> <on|off|show|hide>` saves separate enabled and
visible preferences. All three banks start disabled. Selection is traced
under BANK when diagnostics are active. Check that L2/R2 preempt the
selected shoulder bank, and releasing the trigger restores the selection
if the shoulder remains held. Action storage, binder destinations, slot
dispatch, and centered rendering are the next milestones.

---

# Current Development Status — November 7, 2026 — Shoulder input transport

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint: `d7c6b6b98b79a0e5fac06633a8ba56ac65e96e1c`.
Personal behavior reference: `72e7b6dfb9df0d5832d143af37081a6d489691fe`.

The first milestone adds L1 and R1 observation to the generated hardware
maps and the existing acknowledged stream. Extended clients can lease
14 inputs. The current router still leases 12 and native shoulder
ownership is unchanged. The alternate XInput profile continues to use
RB only for its chooser. The additional DirectInput mappings use Joy5
and Joy6, as on the personal DualSense. Physical FightPad and F710
mapping confirmation remains pending.

Local generated-mapping and portable C++ fixture checks pass. The Lua
fixture covers rejection on ordinary leases and ordered shoulder edges
on an extended lease. The Windows workflow builds the actual x86 DLL
and runs the AutoHotkey fixture. Hardware tests remain pending.

Next milestones are ownership, dispatch and the binder, persistent shared
bindings, and centered rendering. The agreed optional command is
`//xb bank targeting on|off`, off by default. On eligible R1 down,
run `/targetnpc` with no selected target or send Tab with one selected.
Holding and releasing send nothing further. If both shoulders are down
in the same input sample, send neither shortcut. If the other shoulder
arrives later, entering the chord sends no additional shortcut. Verify
menus, trigger priority, each chord order and focus rearming before a
live testing package.

---

# Current Development Status — November 7, 2026 — Compact Options hint

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `616293cca78745eb01cd622127956a40281e0798`.

Myrr reported an Options icon flash while rapidly tapping R2.
`Myrr-20261107-185138-475080-1-Myrr.log` shows repeated idle/trigger
transitions with the addon menu closed. The render buffer overwrote older
events and retained 2,065 alpha, 1,415 position, and 1,289 size calls.
These are Lua drawing calls. The capture does not identify the flashed
icon or measure GPU cost.

Ported the compact visibility policy from personal commit `a572fca`.
Compact hints start hidden and leave the draw list immediately, even
during a fade. Full-layout hints still follow the normal crossbar fade.
The chooser hides its overlapping caption directly. The opacity pass
skips fully hidden surfaces and applies the current opacity on reveal.

Overlay this Lua patch on the special-bank TriggerScale build. Reload
XIVCrossbar. In XI compact with fades and TriggerScale on, rapidly tap R2
with Autohide and then Always visibility. Repeat after closing the binder
and chooser. Options and Share hints should stay hidden in compact.
Check that switching to full layout restores the hints and Options still
opens the chooser. The compact fixture covers 108 layouts and interrupted
fades. The text-fade fixture checks zero fade alpha writes for a hidden
image and correct opacity on reveal. In-game confirmation is pending.

---

# Current Development Status — November 7, 2026 — Special-bank TriggerScale

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `0071f3078b1f120b664ae94a674627da2463a32c`.

With TriggerScale enabled, combined and double-tap banks grow by the saved
shift. When a special bank closes and the regular pair is visible, both
return from the smaller scale. With no trigger held they settle at 100%;
a remaining single trigger uses its regular scale targets. The bounce uses
the 60 ms easing. Autohide still decides when banks are visible.

Check with `//xb show`, both combined orders, both double taps, and rapid
release/repress. Repeat with fades and Autohide. The Lua fixture covers
special-bank scaling, field alignment, the return midpoint, and the
hidden case. Live feel is pending. Overlay the 60 ms TriggerScale build.

---

# Current Development Status — November 7, 2026 — 60 ms TriggerScale

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `67060a6a3c846f095e391cd682ab8ab25c90258a`.

The user requested a faster TriggerScale. The bank animation keeps the
same easing curve and now takes 60 ms. The opacity fade still follows its
own settings. The Lua fixture checks the midpoint at 30 ms and completion
while a longer opacity fade is still in progress. Live feel is pending.
This patch overlays the symmetric TriggerScale build.

---

# Current Development Status — November 7, 2026 — Symmetric trigger scale

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `206bbde2a35c6342a8f3eceb3ebc1b435d96a8d3`.
The user liked Myrr's XI layout and requested symmetric scale with fades.

- With `//xb triggerscale on` and `//xb triggerscale 1`, both banks rest at
  100% of HUD scale. Hold R2 for 101% right and 99% left. Hold L2 for the
  reverse. A saved 99% small scale becomes a 1% shift without editing XML.
  The number in the command now denotes a percent shift.
- Check `//xb fade on` with XI, then repeat with fade off. Check Always and
  Autohide, rapid trigger reversals, combined and double-tap banks, and the
  addon menu. The animation stays centered and uses the existing 120 ms
  easing. Menus and special banks use normal scale.
- Automated Lua tests check centered scale above/below 100%, saved 99%,
  opacity running alongside scaling, and fade-off immediate hide. Live
  feel remains to be checked. This Lua patch overlays the XI layout build.

---

# Current Development Status — November 7, 2026 — XI compact spacing and artwork

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `8c6767c199cbe1bf891f303633274d17772763fb`.
The user approved the softer recast flash and requested tighter XI spacing.

- Select `//xb display xi`, turn `//xb triggerscale off`, and use
  `//xb show` to compare both banks. At 1×, standard compact XI uses
  touching side tiles, a 4 px gap between vertically stacked tiles, and a
  16 px gap between the L2 and R2 banks. The alternate layout preserves its
  split grouping. Saved HUD scale and offsets apply to the entire layout.
- Compare occupied and empty slots. Empty XI frames have a shaded top
  and brighter lower lip. Four new warm-white field textures are fitted
  around the active bank or its two clusters. Check single, combined,
  double-tap and binding-preview states.
- Switch to `//xb display legacy` while compact. Original spacing,
  empty-slot artwork, dark fields and thicker square-ended combat strips
  should return. Legacy leaves compact enabled so spacing is easy to compare.
- Lua fixtures cover live layout changes, empty visibility, field fitting,
  and the Legacy skillchain ribbon shape. In-game density, label readability
  and asset appearance are pending. This patch overlays the soft recast build.

---

# Current Development Status — November 7, 2026 — Softer recast-ready flash

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `a759b530f21e162a9e7a74ccd496af95a521501c`.

The user found the nearly opaque white square looked like a graphical glitch.
The new texture combines a translucent warm-white fill and a brighter
feathered edge. Both fade together over 150 ms. The center peaks around
34% opacity and the edge around 56% before any bar fade.
The gold confirmed-action animation is deferred.

Keep `//xb recastflash on` and compare the softer effect at the end of a
visible cooldown. Check it in compact mode, during trigger scaling, and
alongside the held gold border. Automated tests cover the view size,
placement, initial opacity, decay, and existing trigger rules. Live
appearance is pending. This patch overlays the recast-flash build.

---

# Current Development Status — November 7, 2026 — Recast-ready flash and glow release fix

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `353d2776358a0bb12088b7b6dcde7fe0619d4bf7`.
The user reported the rounded ribbons looked better and is continuing live checks.

Myrr's 30-second capture showed accepted up edges for the affected inputs.
For example, DirectLink sequence 17 lit glow object 274, while sequence 18,
its matching release, hid 276. Both logs show button-up activity during
song casts and refusals. The glow release lookup swapped Circle and Square
relative to the action path. Press and release now use the same slot map.
This fix concerns visual ownership and preserves action selection.

Enable `//xb recastflash on` and keep the bank visible through a cooldown.
At observed positive-to-zero recast, the slot flashes white at alpha 250
and falls to zero over 100 ms. It works independently of slotglow. Initially
ready, rebound, hidden and menu-covered slots do not replay a ready flash.
Repeat Myrr's Circle and Square song holds, releasing one at a time, and
check that only the released border clears.

Lua tests cover mapped release, simultaneous recasts, decay, nil samples,
rebind, hidden banks, menu and hide cleanup. Live visual testing is pending.
The patch changes Lua only and can overlay the combat strips build.

---

# Current Development Status — November 7, 2026 — Combat ribbons and brighter slot glow

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `bd18fb813165fe9bfbaefdcd886245d3b084bf58`.
The user reported the feathered frame was too dim at all three levels.

- In XI, check the translucent white pre-skillchain ribbon and black edge,
  then the more opaque TP-blue/white flash during the open window. In Legacy,
  check the configured waiting/open colors. Switch presets during a window
  and verify the color changes without waiting for the next chain.
- Spell, weaponskill, and job ability lockouts retain their XI tint ramps
  and Legacy colors. XI autoattack uses pale pink before the estimate and
  pale green past it, while Legacy keeps its configured red/green colors.
  All three strips use thinner rounded fills and backings.
- Test `//xb skillchain 255`, `//xb lockout 255`, and `//xb autoattack 255`
  independently. Check off, on, and status. Lockout on restores the saved
  per-action values. Autoattack off or zero hides it and stops swing tracking.
- Gold frame alphas are now 250 ready, 190 unavailable, and 145 empty.
  The core of the stroke is white, its feather is gold, and the tile
  center is transparent. Check the held border alongside the XI pulse.
- Automated Lua checks cover ribbon phase colors, commands, and held glow.
  In-game colors, brightness and strip positioning are pending. This
  delivery changes Lua and artwork, with no native DLL source changes.

---

# Current Development Status — November 7, 2026 — Feathered slot glow

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `ce809fd18f9d178517e3ca029fb5e5ce9c79f730`.

The user reported the held XI slot pulse was faint and the gold border
was hard to see. The settled pulse now uses alpha 96 instead of 72, with
the initial flash and timing retained. `//xb slotglow on` uses a dedicated
feathered gold outline around the tile. The outline remains dimmer on
unavailable actions and faintest on empty slots.

Hold a slot with XI selected to compare the settled pulse. Enable slotglow
and compare ready, unavailable and empty slots. Repeat with Legacy to see
the gold frame without the XI pulse, then test compact layout and trigger
scaling. Check both the feather and brightness at the normal play resolution.
The texture and Lua fixture cover a transparent center, alpha falloff,
brightness ordering, held opacity and alignment. Live appearance is pending.
The native DLL is the same source baseline as the preceding package.

---

# Current Development Status — November 7, 2026 — Gold slot hold border

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `d4ec6145d6d90c103d1b98647e8a1123fbca7eeb`.

- `//xb slotglow on` enables the saved opt-in. Hold a slot button with a
  trigger and check that a soft gold border brightens on press, settles
  while held, and clears on release. Quick taps have a 60 ms minimum.
- Compare a ready action, an action on cooldown or without MP/TP, and an
  empty slot. The border should be progressively fainter. Try two buttons
  at once, bank switches, menu opening, focus loss, and Autohide.
- Test with Legacy and XI, including fade-off trigger scaling. The gold
  border can run with the existing white flash and XI pulse. It indicates
  input receipt, and does not predict server acceptance.
- Lua regression fixtures cover brightness ordering, simultaneous holds,
  layer compatibility, bank geometry, release, and cleanup. In-game
  brightness and timing are pending.

---

# Current Development Status — November 7, 2026 — Trigger scale animation

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `2850a526ad3d378d6225a837792f6648bc7c33b4`.
The two-client native handoff and physical F710/FightPadPro checks remain open.

- `//xb fade off` then `//xb triggerscale on` opts in. The shared idle
  size defaults to 95% of HUD scale. `//xb triggerscale 0.90` sets it to
  90%, with 75–100% accepted. `//xb triggerscale status` reports the option.
- With Always visibility, hold L2 or R2 and check the selected side reaches
  normal size while the other stays small. On release both settle at the
  saved small size. Each bank keeps its center through the 120 ms transition.
- With Autohide, the selected single bank opens small and pops to full size.
  Releasing the last trigger hides immediately. Combined and double-tap banks
  draw at full size. Fade-on mode and menus use normal scale.
- The Lua fixtures exercise positions, scale endpoints, fields, special
  banks, menu behavior and immediate hiding with mocked Windower drawings.
  In-game timing, readability and alignment still need live review.
- Deferred design notes: larger centered italic white timers, possible
  upper-right MP/TP costs, and centered action labels.

---

# Current Development Status — November 7, 2026 — Shared physical controller mappings

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint for this two-commit batch: `bccffc33e80a4248cdbf8cf9b06745a8b8deb003`.
The most recent user-confirmed Xbox result was the earlier isolation run.

The reader and DLL now consume generated physical tables from
`packaging/controller_mappings.json`. PS5 and F710 share a layout,
FightPadPro keeps its face-button order, and both XInput profiles use
physical LT/RT. The alternate still uses RB for the chooser.
Logical DirectLink codes and saved bindings stay compatible.

Generation consistency, the portable C++ mapping fixture, the Lua suite
and exact-source staging were checked locally. Windows CI verifies the
generated files and runs the real x86 and AHK fixtures before packaging.
Use the complete artifact, including `controller_mappings.ahk` and the
matching DLL. Close all FFXI clients and stop the shared reader before
installing. See the next section for the live two-client lifecycle check.
Physical F710 and FightPadPro checks remain open. Animations are the next batch.

---

# Current Development Status — November 7, 2026 — Addon-owned native hooks

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `bccffc33e80a4248cdbf8cf9b06745a8b8deb003`.

The user accepted the Xbox isolation result for community experimentation.
Physical LT/RT are restored. No additional local Xbox hardware round is planned.

The addon now suspends the native guard and releases controller ownership on
wrapper stop, logout, or graceful restart. Unload also detaches this client's
hooks by default. The shared wrapper follows the last-client policy. The
native bridge starts in pass-through until it receives a Lua context and
rearms from neutral after a lost message lease. Native pad status separates
filtering from pass-through and reports the hook state. The DLL stays pinned
because detachment does not establish that every callback has returned.

The local Lua suite passed, including independent mocked clients, wrapper
stop/restart, same-reader login recovery, reload, and detach reporting. The
portable C++ fixture passed. Windows CI builds the DLL and exercises concurrent
XInput polling across detach/reattach. This is a hook test, not DLL unloading.

Live Windower check with two clients on the same profile: unload one addon
with its trigger held and confirm native controls return immediately. Switch
to the second client and confirm the wrapper is still running and its guard
works. Reload the first addon, release to neutral, and verify a fresh chord.
On wrapper stop/start, inspect `//xb nativepad status` and repeat the handoff.
Close all clients before installing or replacing the matching x86 package.

---

# Current Development Status — November 7, 2026 — Standard XInput triggers

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `959414d8432ee4c22e03429a754212d4ab1095d8`.

- The user reported the Xbox isolation run worked well enough to leave further
  physical XInput experimentation to the community. The earlier wired Xbox
  360 LT spikes remain recorded below. There is no additional local Xbox
  hardware run planned.
- Standard XInput uses physical LT and RT again. The temporary LB substitution
  and unconditional LT masking were removed from the reader and native
  bridge. Both XInput profiles use the original trigger threshold, and the
  alternate profile still uses RB for the chooser.
- A nonnumeric DirectInput POV sample now follows the existing disconnect
  path, releasing held input and waiting for neutral before rearming. The
  AHK regression covers unavailable POV, a centered hat, and a diagonal.
- The portable C++ ownership and mapping fixture and local Lua suite passed.
  Windows x86 CI runs the native and AHK fixtures and packages the complete
  addon on the published commit. These checks do not exercise live FFXI.
- Close all FFXI clients and stop the shared reader before installing the
  complete matching x86 artifact. Preserve existing settings and bindings.
  The next controller milestone is addon-owned hook lifecycle and shared
  Windows mapping definitions.

---

# Current Development Status — November 7, 2026 — Friendly icon-picker folder labels

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`, starting
source checkpoint `7cad8004dc6b98a830a9663d39d9340d700c7a58`. Most recent user live feedback: White Magic
ascending ID and weaponskills descending ID preferred. Job Ability, Song and
Trust role/portrait sorting remain awaiting live acceptance.

## Icon-picker labels only

The navigable icon picker presents folder names in friendly title case,
including Blue Magic, Rune Enchantments, Phantom Rolls, Weapon Skills,
Pet Commands and the acronym UI. Breadcrumbs use the same visual labels.
The underlying folder names, selection IDs, relative icon paths, casing,
stored icon fields, artwork fallback and icon pack contents are unchanged.
The separate legacy flat picker is not changed because it has no folder rows.

The user-provided `test.zip` contains a curated default icon pack:
553 PNG icons versus 900 PNG icons in the original repository default
iconpack; 41 Trust portraits, all 91 UI assets, 24 Job-folder files and
selected other categories remain. Its `icon_list.txt` listed 464 entries,
all present, with no unlisted non-UI PNGs. The user's archive remains a
personal test asset and was not uploaded to the public GitHub repository.

Verification: `tests/icon_picker_folder_labels.lua` asserts visual
labels and breadcrumbs while checking that navigation and saved paths
continue using actual names. The existing Lua tests and Windows CI
are run on the published commit. No Windower/FFXI in-game test of the
new labels has been performed yet.

Installation: replace only `addons/xivcrossbar/action_binder.lua` on
the current Public Beta branch, run `//xb restart`, and open the
Change Slot Icon / Change Action Icon folder picker. Inspect folder rows
and nested folder title, select an existing icon, and verify it saves
and displays after reload. No icon files are included or changed.

---

# Current Development Status — November 7, 2026 — Job Abilities, Songs, Trust portrait/role sort experiment

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`, starting source checkpoint
`9d070b9353ffc2af96263f7d55c48a108db4af12`. Last user-observed FFXI behavior: White Magic ascending IDs and
weaponskills descending IDs both preferred over the former alphabetical lists.

## Action binder order (test batch)

- Job Abilities: ascending resource ID; available/eligible abilities and excluded
  submenus remain unchanged.
- Bard Songs: ascending spell ID; White Magic remains ascending ID; Weaponskills
  remain descending ID. Other magic and ability categories retain prior ordering.
- Trusts: custom name-specific portrait found in the ACTIVE icon pack first,
  unportrayed Trusts second. Within both sections, role precedence is:
  passive/non-interactive special, healer, tank, support, offensive caster,
  physical ranged, then melee/unclassified, with ascending spell ID ties.
  Roles are a curated and incomplete presentation taxonomy; unidentified Trusts
  fall to the final bucket. 'Special' means untargetable passive aura, not every
  alter ego whose wiki job is called Special. Portrait availability is checked
  in the user's selected icon pack, with unchanged fallback to game spell icons.
- No changes to custom icon files, icon_list.txt, generators, known spells,
  action targets, bindings, saved settings, AHK, native blocker, or controller.
- The existing `images/icons/iconpacks/default/GENERATE_ICON_LIST.bat`
  refreshes `icon_list.txt` after manual PNG deletions. The batch script calls
  `BatchSubstitute.bat` to strip the current absolute path; this test does
  not run or alter either script.
- Verified before publishing: Lua 5.4 syntax parse after source-preserving
  Windower string normalization; comparator fixture on 11 sample Trusts
  and prior JA/Songs/White/WS sort markers. In-game Trust and JA/Song
  selection results still need live verification. Automated CI runs after push.
- Install only `addons/xivcrossbar/action_binder.lua` from this commit and
  `//xb restart`. Return to the selector and inspect order/icons.
  Restore prior `action_binder.lua` to reverse.

References for curated roles (not normative): FFXI official Trust role
description and community Trust spell-icon role families. Curation is
experimental, with no claim of an exhaustive live roster mapping.

---

# Current Development Status — November 7, 2026 — White Magic and weaponskill ordering experiment

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `7bec8ad2db74662feb42bc8d7425c62f5f4f8cb1`. User confirmed in FFXI that the standalone White Magic
ascending-ID patch was substantially more natural to browse than alphabetical.
This commit preserves that tested White Magic behavior and tries **descending
resource ID** for the weaponskill selection list only.

## Selection ordering test

- `action_binder.lua`: White Magic `a.id < b.id` (prior standalone live
  experiment), weaponskills `a.id > b.id` (new, awaiting in-game feedback).
  All other magic and ability menus retain their existing alphabetical sort.
- No changes to spell/WS eligibility, known actions, targets, icons, gamepad,
  AHK, native DLL, saved data, action execution, or bindings.
- User is independently curating the default icon pack; icon files were not changed.
- Static verification: targeted source diff and comparator/order assertions.
  No FFXI live test of descending WS order yet. Ascending IDs are not the same
  as required combat skill or learned level; this is an exploratory sort.
- Install: replace only `addons/xivcrossbar/action_binder.lua` while unloaded
  or outside the binder, then `//xb restart`. Check White Magic retains ascending
  IDs, weaponskills appear descending, and other lists remain alphabetical.
- Reversal: restore the prior `action_binder.lua` from backup.

Delivery: single-file standalone patch built from the user's previously tested
White Magic patch, with one additional weaponskill comparator change.

---

# Current Development Status — November 7, 2026 — Xbox 360 LB/L2 isolation test

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch
`experiment/messages-native-all-profiles`. Source checkpoint:
`75becceaa35599f942bc4bb5c7931e08e149b332`. Temporary input-only experiment; NOT live verified.

## Wired Xbox 360 input substitution

**Superseded November 7:** The branch restored standard LT/RT. This section
records the isolation build and is retained as test history.

The standalone XInput probe observed unintended LT peaks of 80–146/255 when
moving the analog sticks. Previous native/message diagnostics independently
showed phantom logical button 11 edges under both sticks and no dropped
messages. This build isolates the noisy sensor without changing Lua bindings:

- Standard `xinput`: LB -> logical button 11 (L2), including double taps and
  LB+RT chords. The AHK reader ignores analog LT even above its former 4/255
  threshold. RT and other logical controls remain unchanged.
- The native XInput guard captures LB according to logical L2 ownership and
  sets physical LT to zero while its focused, live guard is active. If the
  guard is unavailable/stopped, native behavior still fails open.
- `xinput-r1-chooser` (`xinputalt`) and PS5/F710/FightPadPro remain unchanged.
  No existing character bindings, display logic, DirectLink transport, or
  timing machinery was modified.

**Installation/test:** Stop the shared wrapper, close every FFXI process,
back up the addon, and install the complete matching Windows x86 artifact,
including its newly built `native/xb_gamepad_messages.dll`. Select
`//xb controller profile xinput`, use `//xb controller status` and
`//xb nativepad status`, and test LB hold/release, LB double tap, LB+RT,
ordinary RT, analog-stick movement with no phantom L2, bare navigation,
chat, native menu, and rearming after focus switch or addon stop. Run
`//xb diagnose` on the analog-stick test and compare button-11 edges.

**Verification:** Initial Windows CI run 42356792441 compiled the x86 DLL,
passed both C++ native fixtures and the Lua suite, but stopped before packaging
because the AHK fixture still expected LT >4 to activate standard XInput.
The fixture was updated to exercise standard LB, ignore even LT=255, and
preserve the alternate physical-LT behavior. The replacement CI result and
live Windower/FFXI verification remain pending. This batch does not implement automatic unloading
of the native DLL. The bridge currently pins its module; the agreed request
to load/unload it with addon or wrapper lifecycle remains outstanding and
must be addressed separately, after this test.

---

# Current Development Status — November 7, 2026

Lockout visibility fix for `experiment/messages-native-all-profiles` in
`rerorriM-Mirrorer/xivcrossbar`, based on `9f5b3ef`.

## Lockout strip with Auto

Lionstag reported the lockout bars were hard to see. Previously the strip
only updated while the crossbar was visible and inherited its opacity.
The strip can now show at its configured opacity after the slots fade out
in Auto. It still respects explicit Hide, per-action opacity, and Event
visibility. The skillchain indicator remains independently configurable.

Unload XIVCrossbar and overlay this cumulative Lua patch on the `cbbad60`
native test install or its first display-preset patch. Load the addon and
select `//xb display xi`. Cast a short spell, release the trigger before
completion, and check that only the lockout strip appears afterward.
Repeat with a weaponskill and a job ability. Keep `//xb skillchain off`
during the check to verify the controls are independent.

The local Lua suite passed, including triggerless Auto visibility,
independent opacity, expiry, explicit Hide and status-4 cases. Live
FFXI visibility is pending.

---

# Current Development Status — November 7, 2026

Display preset patch for `experiment/messages-native-all-profiles` in
`rerorriM-Mirrorer/xivcrossbar`, based on `cbbad60`. Lionstag confirmed
PS5 startup, binding icon cleanup, and Up/Down blocking with both triggers
at a Survival Guide. A bound echo still needs a live check.

## Display presets and Event visibility

`//xb display` toggles presets, with XI selected on first use. Use
`//xb display legacy`, `//xb display xi`, or `//xb display status` explicitly.
The preset saves immediately. Existing installs use their current appearance
until a preset is selected.

- Legacy uses always-visible bars, configured MP/TP and lockout colors,
  no crossbar fades, and the original shared flash. It keeps the current layout.
- XI selects compact, trigger-driven visibility, crossbar and text fades,
  pale green affordable MP, blue affordable TP, and pink insufficient costs.
  The lockout bars transition from gray-blue to green for spells, pink for
  weaponskills, or blue for job abilities. The independent slot pulses sit
  above the normal flash.
- Auto can show the main bars when a trigger is held during status 4.
  Always-visible mode hides the main bars during status 4.

Overlay this Lua patch onto the complete `cbbad60` native test install with
the addon unloaded. Load it again and switch presets while in game. Test
an affordable and unaffordable spell, TP crossing 1,000, one of each lockout
type, then reload and check the saved preset. At a Survival Guide compare
Auto with a held trigger and Legacy. Check simultaneous slot pulses and
focus or trigger release while a slot is held.

The full Lua suite passed, including preset save/apply, cost threshold,
lockout endpoints, status 4 and DirectLink release. Live visuals are pending.

---

# Current Development Status — November 7, 2026

Hotfix for `experiment/messages-native-all-profiles` in `rerorriM-Mirrorer/xivcrossbar`,
based on `7f8fd18`.

## Binding preview cleanup

Lionstag's diagnostic showed the Attack preview stayed visible when Back
returned from Enter Button Combo to the target picker. The binder now
clears the combo panel, glyphs, action icon and captions when leaving that
page. Back from confirmation to the combo page still shows the preview.
The menu-resource fixture verifies image disposal and panel visibility on Back.

## Native module startup

The user reported the generic DLL compatibility warning on the previous
messages build. The archived DLL was PE32 and contained the PID callback.
The exact reason the live process rejected it was not captured. This build
uses a distinct DLL and entry point, separates file-load, Lua API and
process-ID diagnostics, and tests the module's registration with a Windows
Lua 5.1 API fixture. Close every FFXI process before installing the complete
build. Check `//xb nativepad status` and keep any new error verbatim.

---

# Current Development Status — November 7, 2026

Messages-only native guard test branch `experiment/messages-native-all-profiles`
in `rerorriM-Mirrorer/xivcrossbar`, starting from native experiment
`6c77a2602963be82fb5a8c0e67355adec350cd1a`. The prior public beta and
controller fallback remain available as separate builds.

## All-profile native blocking and DirectLink

The Windows reader sends twelve ordered DirectLink edges for every profile.
Each focused FFXI process publishes its own PID, profile, device, and token.
The guard waits for native game polls, neutral, and a reader heartbeat.
Without a compatible live hook or reader, FFXI keeps normal native controls.
No Apps/Ctrl or F-key capture, synthetic gameplay arrows, or IJKL routing
remains in this Windows path. Login, dialogue, and bare gameplay use the
existing FFXI Gamepad Config. Keep those assignments enabled.

Install the complete Windows x86 artifact in a backed-up test install. Stop
the old shared reader and close every FFXI process before replacing the DLL.
See BETA-QUICKSTART.md and native/README.md. Roll back by restoring the backed-up
addon with every process closed. No character settings or bindings ship.

| Profile | Physical check | Result |
| --- | --- | --- |
| xinput | Xbox A/B/X/Y, LT/RT, D-pad, View/Menu | Pending |
| xinputalt | Xbox RB opens chooser, Menu stays native | Pending |
| ps5 | DualSense DirectInput, Create/Options, both trigger orders | Pending |
| f710 | DirectInput mode, face labels and hat including diagonals | Pending |
| fightpadpro | DirectInput face ordering, Start/Select, D-pad and triggers | Pending |

For each profile, verify controller and native status, login, dialogue, bare
native controls, single/combined/double-tap chords, binder, chooser, chat,
and release ordering. Verify a held native direction stays native when a
trigger is pressed and a captured direction returns to FFXI after trigger
release. Check focus handoff between two clients, reader stop/start,
disconnect/reconnect and unload. XInput DLL variants and multiple attached
DirectInput devices need separate physical results.

All 22 local Lua fixtures passed, with 85 parsed sources. The portable C++
ownership and mapping fixture also passed. Windows CI and live FFXI are
separate checks. CI builds the x86 DLL and runs the Windows loader and AHK fixtures.
The first Windows run (42347180849) compiled and passed the x86 native tests.
The AHK fixture exposed that the detached lease still reported one neutral
transition as consumed. The reader now reports inactivity immediately. The
old review-key fixture was also updated for the separated callbacks. Use the
GitHub workflow result for the published head to verify Windows status.

---

# Current Development Status

Binding-screen polish on `experiment/native-gamepad-bridge`, based on
GitHub checkpoint `83d0fba` in `rerorriM-Mirrorer/xivcrossbar`. The user
preferred the original cursor height with the restored bounce. GripRumble
remains a separate optional test companion.

## 2026-11-06 — Binding preview and menu title backing

The binding screen shows a centered action icon and label above its prompt.
A translucent green tint marks the chosen slot only during binding
confirmation. The existing amber field marks the preview bank. Binder and
controller setup titles use a padded, semi-opaque text background. The
cursor stays at its normal height and long non-final-column captions are
fitted to leave a gap for it. Windower text still draws above image
primitives. The title backing can reduce overlap around the heading, but
other addons retain control of their own visibility.

Overlay the patch into Windower's addons folder and run `//xb restart`.
Try a spell, a custom action with a distinct alias and icon, and an existing
binding. Check that the preview stays visible while trying triggers. Choose a
slot on a single, combined, or double-tap bank, and verify the green tint on
that slot. Back out and confirm separately. Check compact and standard
layouts, a long neighboring label, and the title with EnemyBar2 open.

Local Lua regressions passed for preview redraw, Back, resource cleanup,
custom Save & Bind, crossbar destinations, compact geometry, text settling,
and combat overlay. Color, placement, and third-party layering still need
a live client check.

---

## 2026-11-07 — Slot acceptance tap and cursor alignment

Overlay the XIVCrossbar patch and run `//xb restart`. The cursor keeps the
bounce and returns to its original height except where a left-hand label
extends into its space. Check Select Action Type and a neighboring long label.

To try rumble, install GripRumble 0.1.17 separately and restart its Windows
helper. Load GripRumble and use `//grip slotpress` to feel the reference tap.
Enable the cue for the current XIVCrossbar load with `//xb slotrumble on`.
Run the following checks with the existing flash behavior.

- Valid bound action, regular switch, and quick switch: one tap per press.
- Empty slot, missing destination, and pet command without a pet: no tap.
- `//xb inputtest on`: dummy press still flashes and sends no tap. Turn
  Input Test off afterward.
- `//xb slotrumble off`: disable the tap. Reloading also turns it off.
  With GripRumble absent, action dispatch and flash still work.

The tap reports local acceptance. Combat cues still report the game result.
Lua simulation passed accepted and rejected actions, both switch types,
Input Test, cue opt-in and absence, and cursor positioning. Existing
crossbar-destination and menu resource regressions passed. The companion's
cue table and Lua command passed static checks. Live controller testing is
pending. The release build can remove the single emit call and test command.

---

## 2026-11-07 — Golden cursor bounce and caption clearance

The complete cursor sprites now step down one pixel every two frames and
reset at the end of the loop. The selectable-list cursor sits above the
caption line because Windower text renders above image primitives.

A local Lua fixture passed the six-frame sequence and reset, alignment of
the four image layers, sizing, hide, and cleanup checks. The live check is
to overlay the patch, run `//xb restart`, and watch the cursor loop in
`//xb menu`, including in a column beside a long label and on page controls.

---

## 2026-11-07 — Golden cursor crop correction

The transparent divider rows are at atlas y=0, 21, 42, and 63. The six
32×20 crops now start at y=1, 22, and 43. Local checks verified that each
crop covers exactly one complete sprite and that all six saved PNGs match
their atlas crops pixel for pixel. The renderer and animation are unchanged.

Back up the existing cursor folder, overlay the patch in Windower's
`addons` folder, run `//xb restart`, and open `//xb menu`. Check both
arrow edges through a full loop. Live verification of the new crops is pending.

---

## 2026-11-07 — Golden cursor atlas extraction

The six cursor frames now use the DXT3 alpha indicated by the original
`51.DAT` atlas. Decoding the same payload as DXT5 reproduced the previous
PNGs exactly. Crop bounds, frame order, and playback timing are preserved.

Local checks passed for the source hash, all 3,840 alpha samples against
the raw DXT3 nibbles, and all six PNG round trips. In-game appearance is pending.

Back up `images/assets/menu/cursor`, overlay the patch into Windower's
`addons` folder, and run `//xb restart`. Open `//xb menu` and watch the
cursor on one option and while moving between options. Check for dark lines
and legibility. To roll back, restore the cursor folder and restart the addon.

---

# Menu browsing and compact startup

- User reported repeated successful Trust paging. Cold startup could render Full while saved Compact was true. UI setup now reads the current setting after character initialization.
- Icon browsing and recursive icon selection use Windower directory APIs. Picker directions repeat after 350 ms and wrap along the current row or column, skipping unavailable cells. Release, page changes, focus loss, and closing the picker cancel repeat.
- Live: cold-start Compact, enter nested icon folders without a console flash, and hold all four directions in a sparse picker. Cursor texture cleanup and inherited icon flicker remain open.

---

# Graceful XIVCrossbar unload command

- User confirmed the shared AHK wrapper exited on unload and returned smoothly on load. Added `//xb unload` using the existing fade and cleanup path, followed by Windower unload.
- Live: verify the alias follows the same shutdown path, then repeat with a second loaded client to confirm the shared reader stays alive until the last unload.

---

# Shared AHK last-client shutdown

- Ported the personal branch owner-file registry. AHK keeps running while any registered client is loaded, including minimized clients. After the final unload it waits two seconds before exiting. StopWrapperAfterLastClient defaults on and can be set false in settings. The old forced-off field does not override this setting.
- Live: update the Lua and AHK files as a set, restart the old wrapper, test one client and then two clients. Unload one client first, then the last. Confirm a quick reload within the grace period keeps the wrapper running.

---

# Held-trigger handoff

- Closing the XIVCrossbar menu keeps the held trigger bank available immediately. In automatic guard mode, releasing the final owned trigger returns held D-pad directions to FFXI after 120 ms. Face-button ownership remains through release. Buffered DirectInput replays a held POV value when space is available.
- Live: close the addon menu while holding each trigger, use a fresh face press, then hold a direction and release the trigger first. Check release before the delay and menu Cancel separately. DLL update requires a full client restart.

---

# Skillchain indicator opacity command

- `//xb skillchain off` sets opacity to zero; `on` restores the built-in default (220). The bare command toggles, and `status` reports the current opacity. Changes save and apply without a reload.
- Live check: toggle off and on during a skillchain window and confirm the indicator and saved value follow the setting.

---

# Native FFXI menus and crossbar chords

- Native FFXI menu_open no longer gates the guard or Lua controller router. Bare controls retain native passthrough; L2/R2 chords work over ordinary and battle menus. Chat still yields to native input, and XIVCrossbar menus still own their inputs. Automatic guard startup no longer prints the poll reminder.
- Live: test L2 and R2 with AutoHide over native main and battle menus, plus bare Up/Circle and addon-menu Cancel. Lua-only change; reload XIVCrossbar.

---

# Native hook detachment on addon unload

- Enabled by default. `//xb diagnose native detach off|on` changes the persisted option. Wrapper stop still disables filtering without detaching. Addon unload restores native entry points while retaining the pinned DLL and trampolines for in-flight callbacks. Reload with a ready wrapper re-enables the hooks.
- Live retest: load the guard, unload XIVCrossbar while AHK stays running, verify native controls, reload, and verify the guard and filtering return. Replacing the DLL still requires restarting FFXI.

---

# Automatic native guard alongside AHK

- Experimental default: start the guard once a matching AHK reader reports ready. AHK remains the sole addon action source. Missing/stale readers disable the guard; native poll activity is required before skipping bare keyboard equivalents.
- The guard filters polled and buffered trigger chords and addon-menu presses. Buffered ownership advances in event order and peek reads do not commit it. Native menus/chat use Windower context flags; validate the native battle palette separately.
- `//xb diagnose native pass` saves the opt-out, `//xb diagnose native auto` restores the default, and `//xb diagnose native status` reports the active guard.
- Live: leave FFXI bindings assigned, verify bare inputs, menu Cancel ownership, R2+Up release ordering, AHK stop/restart, client focus handoff, and Xbox parity. Trust and other addons are not yet live-verified against this guard.

---

# Live Up/Circle probe with AHK

- Lionstag confirmed native suppression with AHK stopped and raw/masked values 0x001, 0x040, and 0x041. With AHK running the native menu still reacted, consistent with the Lua gameplay fallback synthesizing keyboard equivalents.
- During the probe, bare Up and Circle no longer synthesize gameplay keys. Existing injected holds are released on activation. XIVCrossbar menu and trigger-chord actions retain their normal routing.
- Retest in a native main menu with AHK running, then try R2+Circle and restore passthrough.

---

# Buffered takeover ownership scaffold

- Portable fixture covers the proposed default Up/Circle passthrough, explicit capture override, and a captured Up surviving trigger release and a menu or policy change. Buffered consumers can distinguish captured release edges from fresh native presses. The live diagnostic hook retains its existing behavior.

---

# Buffered DirectInput diagnostic with AHK running

- Lionstag confirmed the LuaCore loader and raw Up/Circle masks, with buffered DirectInput reads preventing suppression in the prior build.
- Native input passes through by default. Use `//xb diagnose native block` with AHK running, `//xb diagnose native status` for counters, and `//xb diagnose native pass` to restore passthrough. This probe does not inject Lua actions. It filters both polled and buffered Up/Circle for the selected device, waiting for neutral before arming.
- Live check: keep AHK running and verify native Up/Circle only are suppressed, diagonals retain the other direction, other native binds and AHK crossbars continue to work, and passthrough restores fresh Up/Circle presses. Buffered full takeover remains out of scope for this diagnostic.

---

# Native probe — Windower C module and Circle\n\n- Lionstag reached addon setup but Windower had no ffi module. The bridge now uses package.loadlib and resolves the already-loaded LuaCore.dll exports. Missing exports return a loader error without installing hooks.\n- Probe mode captures D-pad Up and Circle/B together, including separate release ownership. The other controls remain native. Live acceptance remains pending.\n\n---\n
# AHK v2 shortcut startup

- The bootstrap creates a validated interpreter shortcut. Subsequent starts use the shortcut and the current profile handoff, with one bootstrap retry if the reader does not start. Stop or unload cancels the pending retry.
- Live check: first bootstrap may show a console. Stop and restart after discovery and confirm that the cached launch starts without it.

---

# Native gamepad bridge experiment — public AHK v2 baseline

- Experimental branch starts at public v2 checkpoint 9b718705f1276a940a2c672eb17ae6dd220c04ae. Session-only opt-in adds a per-process XInput and polled DirectInput hook, isolated Up probe, and Lua takeover route. See native/README.md for setup and rollback.
- Portable C++ fixture passed for Up-only filtering, unrelated inputs, release ownership, neutral rearm and both layouts. Simulated public Lua regression suite passed. Windows x86 build and DLL-load fixture run in the experimental workflow.
- Live FFXI verification pending for both APIs, especially the DirectInput polling implementation and format, LuaJIT DLL loading, context transitions and multiclient handoff. Buffered DirectInput is detected and left in pass-through.

---

# November 6, 2026 — Public v2 menu preview

- XIVCrossbar menus keep the HUD visible with dimmer icons and hide gameplay trigger fields. The binder exposes its selected bank for an amber field during binding selection and confirmation. Native FFXI menu routing is outside this change.
- A trigger held while the addon menu owns input must return to neutral before it can activate a gameplay slot.
- Simulated Lua regression suite passed. Live: check Select Trust paging, single/combined/double-tap bank previews in compact and standard layouts, and closing the menu while holding R2.

---

# November 6, 2026 — Public AHK v2 conversion audit

- Keep diagnostic request cleanup failures local to the diagnostic poll.
- Native fixture now forces a failed snapshot flush and checks that pending events survive and publish on retry. Physical DirectInput and XInput testing remains open.

---

# November 6, 2026 — Public AHK v2 snapshot write recovery

- Lionstag live report: DirectLink FileMove failed with a count of one and escaped the OSError handler. The snapshot writer now catches generic file-operation errors and lets the existing flush cadence retry unacknowledged events. The cause of the failed replacement is unconfirmed.
- Live retest: repeat controller use after setup on Lionstag. Confirm a failed replacement does not interrupt polling and that subsequent input recovers.

---

# November 6, 2026 — Public AHK v2 DirectInput hotfix

- Live report: selecting a DirectInput profile crashed on the first connected poll with invalid array index 5. The reader now appends eight buttons after the four POV entries.
- The Windows fixture calls the production reader with a simulated connected joystick. Recheck profile selection and controller input on physical hardware.

---

# Current Development Status — November 6, 2026 — Public Beta AHK v2 Test 1

- Branch `development/public-ahk-v2` starts at public Beta 1 commit `1f928a80e6187a772615c16b99d957625dff7ff1`. Personal v2 reference `ad368145a2790a5d947bb132f75c17732545ac66`. Read the current development guidance and testing history from both branches.
- Converted the public reader and its two supporting modules in place. Adapted interpreter discovery, the per-installation mutex, explicit shutdown and reader identity diagnostics. Kept the public profiles, Lua receiver, public defaults, routing and on-disk protocol. The public explicit stop and restart model remains in use.
- Native Windows CI covers both interpreter bitnesses, startup through CMD and launch INI, direct argument selection for all five profiles, duplicate-reader rejection, stop/restart and refusal of a non-AHK executable. The package job requires both native jobs and reruns the existing simulated Lua suite. This does not measure physical input.
- First live pass: one DualSense and one client. Confirm startup and the configured profile, IJKL and face bindings, L2/R2 and simultaneous/double trigger order, native menus, custom-action menus, diagnostic save and stop/restart. Compare against public v1 with equivalent settings.
- Then exercise two to four clients, rapid trigger input, held keys through focus changes, neutral rearm, reload/unload and disconnect/reconnect. Check for stale events, stuck keys, and duplicate or wrong-transport input. Test F710, FightPadPro and both XInput routes with actual hardware before accepting them.
- Recheck historical compact Options-hint flicker and diagnostic-save memory failure in game. Follow README for a whole-folder install and rollback. This testing branch is for live acceptance before any community release decision.

---

# Current Development Status — October 29, 2026 — Public Beta 1 Fresh-Install Defaults

- **Working repository/branch:** `rerorriM-Mirrorer/xivcrossbar`, `release/beta1-ps5-directlink`, following known-good automated `combatui1` checkpoint `50a67ee5f76f210c3c49f678dfac8f7ec4dfbbf4`; runtime `0.4.0-beta1.20261029.ps5-directlink-freshdefaults1`. Personal `development/directlink`, last-known-good stable/master and RC3 are untouched.
- **Requested new defaults (only):** `GameplayDPad='ijkl'` (bare gameplay D-pad arrows route via I/J/K/L), `Animation.TextFade=true` (text follows animated slots), `AutoAttackIndicator.Enabled=false` (do not estimate swings, default bar opacity remains zero), `VisibilityMode='oninput'` (trigger-based AutoHide). Existing fade times `0.1s` in, `0.5s` out, `2s` startup, and `TextSettling=true` remain unchanged. No new timer or command was introduced.
- **Important AutoHide finding:** `visibility.should_show('oninput', trigger_held, cutscene, startup_reveal)` has no elapsed-time post-trigger retention: it becomes false immediately after release, then the existing `FadeOut=0.5` completes. User is choosing whether a possible future 3/9/15/30-second hold duration belongs in beta, particularly considering longtime users. No such hold duration exists in this checkpoint; the decision is deferred.
- **Upgrade behavior:** Saved `data/settings.xml` values take precedence if already present. An installation upgraded from a base version which never serialized these new fields will receive the updated defaults for missing fields, which may surprise people accustomed to always-visible bars or bare arrow targeting. The short setup now specifically requires I/J/K/L assigned to FFXI **Menu/Target Cursor**, or `//xb dpad arrows`; the old always-visible mode remains available through `//xb show`/`//xb autohide off`, endpoint text via `//xb textfade off`, and swing tracking via `//xb autoattack on`. Treat these as fresh/missing-field defaults, not forced per-character overrides.
- **Regression coverage:** Updated `tests/textfade.lua` and `tests/combat_ui_beta1.lua` for the requested default changes while retaining explicit opt-outs. Added `tests/new_defaults_beta1.lua` for IJKL transport mappings, startup reveal/cutscene/trigger visibility, unchanged fade times, default tracking and text fade and compatibility of saved alternatives. These are simulated Lua tests, not a live Windower/FFXI validation; latest docs-head GitHub CI is to be confirmed.
- **Delivery:** Focused defaults-only change; continue preserving cumulative TESTING entries below, no direct modifications to saved character data, no new GitHub prerelease or stable promotion. `BETA-QUICKSTART.md` and README were updated with the requirements, settings and no-delay caveat. Any test installation ZIP must include README, WORKFLOW and cumulative TESTING inside the `xivcrossbar` folder.

---
# Current Development Status — October 29, 2026 — Public Beta 1 Combat Overlays and Options Cancel Parity

- **Repository and source baseline:** `rerorriM-Mirrorer/xivcrossbar`, `release/beta1-ps5-directlink`. Starting known CI-pass remote head `5def65d9ba3d194510c8a8feeeeebf8684b3d1c5`, runtime now `0.4.0-beta1.20261029.ps5-directlink-combatui1`. Personal `development/directlink`, public RC3 and master were not changed.
- **User request:** Include three known personal fixes before the public beta release: hide both skillchain indicator primitives at skillchain opacity zero, independently disable all autoattack swing estimation with `//xb autoattack off` (without conflating that with hiding the bar), and restore ordinary slot-frame art when a skillchain helper animation no longer applies. Audit other menu changes not yet brought from personal. No speculative feature work.
- **Skillchain bars:** `ui.lua:display_skillchain_indicator` now first checks `self.theme.skillchain_window_opacity == 0`, hides BOTH progress/background prims, then returns; the previous active-timer drawing path is unchanged at nonzero opacity. Setting remains XML `SkillchainIndicator.Opacity=0`, not a new CLI.
- **Autoattack estimate:** Added `AutoAttackIndicator.Enabled=true` to defaults; carried via `theme.lua` as `aa_enabled`; `ui:set_autoattack_enabled` gates recording/engagement/pause tracking and redraws, resets historic interval/estimate/engagement on changes, and invalidates older scheduled pause callbacks by generation. `xivcrossbar.lua` gates melee, WS, JA and gain/lose buff processing when disabled. `//xb autoattack [on|off|status]` saves and reports this independently of opacity; when switching ON during battle it resumes from fresh engagement state. Existing bar hide at `AutoAttackIndicator.Opacity=0` is preserved, but this does not stop estimation unless Enabled=false. `status` and `help` now list the toggle. Real game attacks are unaffected.
- **Contextual frame:** When a rendered action lacks a valid skillchain property, `ui:check_recasts` restores base `slot_frame` artwork and full alpha even if it is warming up, eliminating the prior sticky animated helper frame; a valid skillchain property continues its existing animated-frame presentation. No icon assets or frame sequences changed.
- **Additional menu regression discovered and fixed:** Beta's root Options/set chooser calls `action_binder:is_cancel_button(button)` for face-button cancel, but the beta binder lacked that function. Ported only the personal layout-aware mapping (PS/Xbox/GameCube/Nintendo) to prevent a nil-method error and honor saved cancel mappings. Existing root chooser logic is unchanged.
- **Other menu parity findings (audit only, not automatically imported):** Most underlying custom-action Review/Save & Bind, physical Review arrows/Enter/Escape, page navigation/back state, compact-specific hints, list drawing and menu layout are already in beta. Personal SMN Blood Pact picker uses `libs/blood_pacts` and filters native currently available pacts, whereas public binder still populates Rage/Ward by scanning broad resource entries. Personal chooser displays the old Basic set as `Main` and has personal catalog bank names; this is deliberately private rather than a public release requirement. Personal first-install profile selector offers extended reader profiles, which are explicitly unavailable in public and not to be ported. The proposed setup R2 live-highlight was discussion only and has not been implemented as a shared base change. No wholesale binder diff was imported.
- **Verification:** Added `tests/combat_ui_beta1.lua`, dynamically executing extracted public `ui.lua` skillchain primitive visibility and autoattack estimate state/toggle functions under mocked Windower; tests both opacity zero/positive, record/stop/reset behavior, pending callback isolation, saved default/theme propagation, and real slot-frame reset snippet. Added four-layout Options cancel regression against actual `action_binder.lua` helper. Existing suites include DirectLink edge/login, custom-action editor return, review keyboard, simulated text settling, text fading, compact grids, status/help formatting, diagnostics and package integrity. Automated results are Linux Lua 5.4 with temporary Windower source normalization; do not describe as native FFXI.
- **Live acceptance pending:** On an isolated beta installation, set `SkillchainIndicator.Opacity=0` in XML and confirm neither bar nor background remains visible while an SC timer is running; then test a nonzero opacity. Set `//xb autoattack off` and confirm no estimator runs or renders, re-enable and confirm fresh learning without stale results; retain existing zero-opacity bar visibility mode. Switch into/out of an eligible WS/SC hint during recast warmup and verify the normal slot frame returns. Open Options chooser and press the configured controller Cancel face button; confirm no Lua error. Previous compact Options flicker and diagnostic save memory regression still await direct in-game verification.
- **Release boundary:** Automated regression and packaging completion on the documentation-head commit must still be checked before distributing. No GitHub tag/release or native hardware acceptance is claimed. Keep full history below and include `WORKFLOW.md` / `TESTING.md` inside the installable addon ZIP.

---
# Current Development Status — October 29, 2026 — Public Beta 1 Review Keyboard and Color-Coded Messages

- **Repo/branch and source checkpoint:** \`rerorriM-Mirrorer/xivcrossbar\` on \`release/beta1-ps5-directlink\`; starting published head \`444ca7c2b989c5817b8ee6ec0316e34369cdcb98\`, runtime target \`0.4.0-beta1.20261029.ps5-directlink-releaseui1\`. This patch alters only Beta 1. Personal \`development/directlink\`, RC3 and stable/master are unchanged.
- **User request:** Port the already-developed physical keyboard navigation in custom-action Save/Review (arrows for navigation, Enter to choose, Escape to back out), and migrate remaining public user-facing chat messages to the agreed BattleStations-inspired style, **no feature creep**. Remind the user after delivery to ask about polishing remaining messages in the *personal* DirectLink branch.
- **Review keyboard:** Ported \`libs/controller/review_keyboard.lua\` from personal. A new \`action_binder:is_keyboard_review()\` predicate limits handling to visible \`EDIT_CUSTOM_ACTION_REVIEW\` and \`CONFIRM_CUSTOM_ACTION\` screens, not inline text fields or set chooser. Root physical \`controller_keyboard\` invokes review handler **before** generic Escape and text confirmation; gated by game focus, no prior block, not restarting, no chooser, no field-owned Enter. Edge ownership through key-up prevents typematic repeat, pre-held key activation and Enter/Escape release leaking into FFXI. The DirectLink message path is intentionally excluded. Old input text entry, controller face/menu binds and gameplay routing remain intact.
- **Chat presentation:** Added \`libs/chat_status.lua\` and \`libs/chat_help.lua\` adapted from the personal formatters, with the project's additional palette: [XIVcrossbar] purple 200, headings purple and separators 140, syntax/labels blue 207, descriptions/values white 0, ready/ON green 158, pending 140, errors 167. The original root single-color help is replaced with grouped full \`//xb\` syntax + explanatory arrow on chat channel 0. Root \`//xb status\` and \`//xb controller status\` now have readable headings/field rows, state and relevant input mode (rather than dense raw counters). Root command responses, argument errors formerly printed exclusively to the console, binding and set feedback, \`action_binder.lua\`, \`player.lua\`, \`ui/icon_extractor.lua\`, \`gamepad_converter.lua\`, diagnostic callbacks, controller responses and display toggles now use the common formatting emitter. Existing input diagnostics \`[XIVCrossbar test]\` remain explicitly diagnostic chatter; log file content and user-authored commands are not recolored or rewritten.
- **Regressions and tests:** \`tests/review_keyboard.lua\` ports the six-key fixture and exercises the *actual public root keyboard prefix* with mocked Windower keyboard handling, including field-owned Enter and DirectLink isolation. \`tests/chat_formatting.lua\` asserts the help/status palette, binding values, errors, green ON, chat-only standard output and absence of console-only argument errors. Existing isolated testing fixtures (\`compact_command\`, \`crossbar_destinations\`, \`custom_action_save_return\`, \`login_input\`, \`profile_gate\`, \`profile_lifecycle\`, \`shared_command_regressions\`) supply a chat emitter where extracted handlers previously expected direct console output. Automated CI passed for the runtime checkpoint including simulated Lua 5.4 Windower syntax-normalized source/regressions, Python syntax and full install packaging; latest documentation-head CI still to be verified.
- **Scope limitation:** No native Windows/AHK/FFXI live run. Color rendering with Windower's actual \`chat\` library and physical keyboard focus/blocked behavior are inferred from the existing personal implementation and simulated checks. The previously observed compact hint flicker and diagnostic memory failure still await user testing on the recent beta.
- **Minimal live acceptance:** Open a saved custom-action Review screen: arrow keys move the highlighted choice, Enter selects it, Escape goes back, and typing into Name/Alias/Command still works. Verify \`//xb help\`, \`//xb status\`, and \`//xb controller status\` for purple headings/identity, blue commands/labels, white values, green readiness and red errors. Check no physical key escapes to FFXI during Review, and native arrow/Enter keys remain unchanged outside the addon. \`BETA-QUICKSTART.md\` documents only the short setup/new command list.
- **Release boundary:** This remains a public *beta* candidate, not stable; GitHub packaging alone is not a tagged prerelease or live acceptance. Continue to keep distinct whole-folder backups and never merge with personal \`data/\` or source.

---

# Current Development Status — October 29, 2026 — Beta 1 Caption Settling and Terse User Guide

- **Working repository/branch:** `rerorriM-Mirrorer/xivcrossbar`, `release/beta1-ps5-directlink`, following verified previous beta source head `0a3c74205b1be8a78c7340b4896368889fdd447f` and existing runtime `0.4.0-beta1.20261029.ps5-directlink-textfade1`. The existing personal build is the narrowly inspected source of the previously user-tested text-measurement technique; **personal `development/directlink`, RC3 and `master` were not changed**.
- **User request:** Fix the text/caption flicker with the established settling approach, confirm inline keyboard editing on the custom-action Save/Review screen, and provide a terse new-user README with only additional setup and public commands. Do not introduce personal companion banks, layout changes or new input routes.
- **Keyboard editing already present, no code change:** `action_binder.lua` supports `EDIT_CUSTOM_ACTION_REVIEW`, `display_inline_custom_action_entry` and `custom_action_review_field` for Name, Alias, Command; Save Only returns to catalog, Save & Bind continues to button assignment. Prior `tests/custom_action_save_return.lua` and menu resource regressions already covered this behavior; not ported or rewritten.
- **Caption flicker repair:** Added the personal-derived bounded frame-based `ui/text_measure.lua` (two matching valid widths on distinct prerender frames, 512-entry bounded key cache, eight-frame fallback), wrapped *only text* object measurement and three native alpha channels in public `ui/resources.lua`, switched centered-label paths in `ui_geometry.lua` and `ui/text_layout.lua` to `measure_width`/commit only after correct positioning, and begin the measurement frame at the start of public prerender. Newly changed captions are transparent while a native extent from the preceding caption might be returned. This preserves UI ownership and public resource API, avoids importing personal image assets/renderer/shortcuts, and does not modify menu or controller routing.
- **Text fade compatibility:** The previous `//xb textfade [on|off|status]` remains independently configurable and defaults OFF. During measurement suppression, requested text, stroke and backdrop opacities are remembered; after committing a stable center, the native alpha is restored to the current fade value. No new fade timings or startup behavior.
- **Setting and command:** `TextSettling=true` by default, saved in settings, with `//xb textsettle [on|off|status]` as the optional comparison/diagnostic switch. Version `0.4.0-beta1.20261029.ps5-directlink-settling1`.
- **Terse newcomer guide:** `BETA-QUICKSTART.md` included alongside `README.md` in the installable addon folder. It limits guidance to the extra AHK v1 single-reader/setup constraints, PS5 DirectLink profile and FFXI gamepad duplicate-key avoidance, optional IJKL mapping, new toggle/status commands, and a short note about the already working inline custom-action editor. Full README and historic TESTING are preserved.
- **Regression plan and limitations:** Existing 71-source Lua parse and regression suites, compact grid, menu lifecycle, diagnostics, local libs and text fading run in Linux Lua 5.4 with temporary Windower syntax normalization. New `tests/textsettle.lua` reproduces stale width / two consecutive stable frame samples, cache reuse, bounded fallback, real proxy/native alpha suppression, fade restoration, and object cleanup. The behavior was previously user-confirmed in the personal build; **this new public port has NOT been live-tested in Windower 4 or FFXI**. Windower's proprietary native measurement timing and appearance still need real-world verification. Previous compact hint flicker and diagnostic save memory failures were observed on older builds and remain unconfirmed after their targeted simulated fixes.
- **Focused live acceptance when convenient:** Keep the beta installed separately from the personal build; in game use `//xb textsettle status` (ON), `//xb fade on`, `//xb textfade on` and change a bound alias/repeatedly open and close binder menus while switching bars. Watch for delayed labels vs wrong-position flashes, and check that editing Save/Review retains inline keyboard input. Restore `//xb textfade off` for original endpoint opacity; no exhaustive feature audit is needed.
- **Publishing boundary:** New GitHub test ZIP and remote-head SHA must match the final documentation commit. CI/static or simulated success is not a native Windows/Windower/FFXI acceptance and does not create a GitHub prerelease.

---

# Current Development Status — October 29, 2026 — Beta 1 Optional Text Fading (No Other Feature Port)

- **Repository/branch:** `rerorriM-Mirrorer/xivcrossbar` / `release/beta1-ps5-directlink`; base was upstream qEagleStrikerp source `15d8381dfad0f9efdb84fe2d24655afc150faec4`. Prior beta runtime/source head `47ef6cf5fe8088871986cb0a88d6b363abcf8fab`. Personal `development/directlink`, public RC3 and `master` remain untouched.
- **User request:** Add only the existing personal feature to make crossbar text fade with artwork, then enumerate user-visible improvements over the upstream base. User previously said **NO FEATURE CREEP**; this is a single requested opt-in appearance feature, not the personal renderer or a command/help redesign.
- **Implementation:** `//xb textfade [on|off|status]` and `//xb ui textfade` control a saved `Animation.TextFade` boolean; bare command toggles. Defaults **OFF** to preserve the previous endpoint-visible caption behavior. `theme.apply` carries the preference to `ui:setup`, and `ui_geometry.lua` changes only alpha/visibility for native text surfaces. With option ON, text glyph, backdrop and stroke opacity follow crossbar fades, including through a deferred fade-out; `set_text_fade` can apply immediately mid-fade without recreating surfaces, modifying input or recentering labels. Regular `//xb fade` behavior and durations are independent and unchanged. The personal text measurement, settling algorithm, and banks are NOT ported.
- **Implementation source commits:** `5d84c0f` defaults; `9e4996e` theme; `d636aca` geometry; `eb0fbd3` UI initialization; `344f5ae` root command/help/version; `673a326` and later fixture corrections for `tests/textfade.lua`. Cumulative history below is preserved.
- **Verification:** The dedicated Lua 5.4 simulated `tests/textfade.lua` checks old default, persisted saved preference wiring, intermediate glyph/backdrop/stroke alpha, retained text through fade-out, live off/on change, unaffected image fade, and command source wiring. Existing controller, menu, resources and diagnostics suites run in CI with temporary syntax normalization. **No native Windower 4/FFXI visual acceptance has been performed**; text fading's appearance and potential flicker remain in-game checks.
- **Beta's previously observed live issues remain historically recorded below:** Old public controller/help message formatting, compact Options-hint flicker and `Diagnostic save failed: not enough memory` were observed on an earlier beta. Targeted compact-hint and streaming-save fixes passed CI but have not been re-tested in FFXI; do not call them confirmed resolved.
- **Focused next check:** On the isolated beta installation, run `//xb status`, `//xb fade on`, `//xb textfade status`, `//xb textfade on`, then reveal/hide the crossbar with `//xb auto` and L2/R2. Confirm text and strokes fade in/out with images, text remains centered, and `//xb textfade off` restores endpoint-only labels. Verify preference after `//lua r xivcrossbar`. No other feature acceptance is required for this change.
- **Release state:** Source-only/simulated candidate pending final documentation-head CI packaging and optional public beta prerelease. Do not claim tag, GitHub Release, native AHK acceptance, or stable promotion based on the CI results.

---

# Current Development Status — October 29, 2026 — Beta 1 Stabilization: Diagnostic Memory and Compact Hint

- **User-observed live blockers:** On the freshly loaded Beta 1 after the xml2 module fix, the old public formatting remained in `//xb controller status` and help output; the Options/Share UI hint flashed into view in compact mode; `//xb diagnose` eventually printed **"Diagnostic save failed: not enough memory"**. User explicitly requested **NO FEATURE CREEP**, a working/releasable beta, and asked for the text-with-bars fade command and why InputTest was recommended.
- **Scope correction:** `//xb inputtest on` was an inappropriate recommendation for unified diagnostic acceptance: it changes actual slot actions to dummy messages, and the 30-second diagnosis should observe real input. The next test must start with `//xb inputtest off`. Extra set-management tests were inherited functionality, not new Beta 1 requirements, and are outside the focused acceptance pass. Public RC3 messaging/help formatting was intentionally not ported from personal in this patch; personal `//xb textfade on|off|status` is **absent** from Beta 1, whose renderer retains endpoint text visibility.
- **Confirmed compact-state exposure:** `ui.lua:show_button_hints()` previously unconditionally showed four controller hint objects. Calling it from any menu/fade pathway could momentarily revive Options/Share while compact even though other callers try to suppress them. The show function now hard-blocks this if `self.is_compact`, using existing `hide_button_hints()`. No additional rendering engine or UI feature is imported.
- **Diagnostic memory-pressure remediation:** `diagnostic_session.lua` previously cloned up to 12,000 Lua events plus up to 6,000 render trace events and the AHK feed into a sorted array and built a large `table.concat` body before the single file write. `diagnostic_bridge.lua` now provides `write_stream` to write each merged chronological line to an adjacent temporary file, close it, and atomically rename it into the final result. `diagnostic_session.lua` uses a three-way chronological merge over existing Lua, render and lazily parsed AHK streams. It does not build a full extra result table/string in production; buffer caps, all event sources and AHK cleanup behavior remain unchanged. The old in-memory writer is retained solely as a compatibility path for isolated fake-filesystem tests.
- **Confidence and uncertainty:** The final-allocation spike is an identified design problem compatible with the user's **"not enough memory"** report, but the exact native allocation failure has not been independently reproduced. The new code substantially reduces save-time allocations; Windows/Windower in-game testing is still required. A process already severely memory-constrained could still fail.
- **Regression coverage:** Updated `tests/diagnostic_beta1.lua` to require streaming (the legacy writer raises an error in the stress fixture), merge >3,000 observations, check chronological output, confirm LUA/RENDER/AHK presence and capped-event drop reporting, and check the compact hint guard. Prior diagnostics, module-loader, controller and UI source suites are retained. Source tests use Linux Lua 5.4 temporary syntax normalization, not native Windower 4 Lua 5.1.
- **Runtime:** `0.4.0-beta1.20261029.ps5-directlink-diagstream1`. Includes previous `libs/xml2` loader hotfix; no changes to profile input mappings, custom action catalogs, text settling, message formatting, or personal banks. Personal `development/directlink`, RC and master remain unchanged.
- **Exact in-game next pass:** (1) Confirm version with `//xb status`; (2) `//xb inputtest off`; (3) `//xb compact on` and open/close crossbars and Options menu during fades; no compact hint should flash; (4) run **one** `//xb diagnose`, perform real L2/R2/bare-button inputs for 30 seconds, and confirm `Diagnostic saved` plus one log under `data/diagnostics/`. If save still fails, preserve console output and `data/diagnostics/` temporary result, without trying another simultaneous diagnostic client. Keep separate entire-folder backup of the personal installation.
- **Release gate:** Linux CI and packaging need to succeed at the latest documentation-complete head before distribution. In-game native acceptance is **pending**. The previously documented other diagnostic limitations (overlapping AHK client capture, incomplete native gameplay key-down logging, no Lua crash-time checkpoints, forced unload race) remain open; do not treat them as resolved. No stable/master promotion or public release claim.

---

# Current Development Status — October 29, 2026 — Beta 1 Diagnostic Test 1 Library-Loader Hotfix

- **Repository / branch:** `rerorriM-Mirrorer/xivcrossbar` / `release/beta1-ps5-directlink`. The previously published complete diagnostic bundle was built from source `1bf559fab4e9771b992b2095439ea58b45e511e0` (the preceding runtime source was `2e4a95af9cd3385d9c9bde30808a4c5c1cdc7502`). Personal development branch, stable/master and other public release branches remain untouched.
- **User-provided live startup failure (October 29):** Attempted loading the complete Beta 1 diagnostic ZIP produced a Windower Lua module-not-found search listing `libs/xml2.lua`, `libs/xml2.dll`, `plugins/libs/libs` and `addons/libs/libs` locations. The ZIP **does include** `xivcrossbar/libs/xml2.lua`; it was a **search-path issue**, not evidence that an XML DLL needs installing. Full exact console trace was not supplied, so this root-cause conclusion is strongly indicated by module search locations rather than independently reproduced in native Windower.
- **Code change:** Added a small initialization block in `xivcrossbar.lua` that normalizes `windower.addon_path` separators, appends `<addon folder>/?.lua` to the Lua `package.path` if absent, and leaves the existing shared Windower module paths first. This makes the existing `require('libs/xml2')` and other `require('libs/...')` calls resolve bundled addon-local modules without requiring copies in the shared `addons/libs/` directory. The addon content, controller transport, diagnostics, render tracing and saved settings are otherwise unchanged. The resulting runtime identifies as `0.4.0-beta1.20261029.ps5-directlink-diag1-libfix1`.
- **Regression addition:** New `tests/local_library_loader.lua` simulates Windower's shared library search without an addon-local search path, confirms that a bundled module cannot initially load, executes the actual startup bootstrap with Windows-style backslashes, then confirms it resolves the addon-local `libs/kebab_casify` and checks referenced `libs/*` files are present. The Linux regression runner performs temporary Windower-literal normalization and uses Lua 5.4; **this does not constitute native Windower 4/Lua 5.1 or FFXI acceptance**.
- **Previous diagnostic limitations unchanged:** One shared AHK capture can be replaced by an overlapping client, normal gameplay native key-down is underreported in the trace, Lua data is not crash-checkpointed, and forced unload may merge a stale AHK checkpoint. These remain explicitly documented in the October 25 preflight audit below; do not treat them as fixed.
- **Full install / rollback:** Stop the shared controller wrapper, unload XIVCrossbar on every client, move the current `addons/xivcrossbar/` folder out of the addons directory to preserve settings and personal art, and extract the **complete replacement ZIP** so `addons/xivcrossbar/xivcrossbar.lua` and `addons/xivcrossbar/libs/xml2.lua` both exist. Never copy beta-local `libs/` files into Windower's shared `addons/libs/`, overlay this version on the personal addon, or look for a standalone XML DLL. On failure, preserve the console trace; restore the entire backup folder to roll back.
- **Next validation:** Confirm `//lua l xivcrossbar` loads, `//xb status` reports `...-libfix1`, PS5 profile initialization works, and `//xb diagnose snapshot` can save its own per-character log. Native Windower/AutoHotkey and FFXI controller testing remains pending.

---

# Current Development Status — October 25, 2026 — Beta 1 Diagnostic Test 1 Preflight Code Audit (No Runtime Patch)

- **Repository/branch/source audited:** `rerorriM-Mirrorer/xivcrossbar`, `release/beta1-ps5-directlink`, `2e4a95af9cd3385d9c9bde30808a4c5c1cdc7502`. Audit of the complete packaged beta, not the personal development renderer. **No runtime changes in this audit**; do not describe the build as in-game tested or new ZIP as delivered.
- **Method:** Manual pre-release static code review of AHK physical poll and shared diagnostic request, DirectLink event/ack stream and Lua lease, input routing, unified-session lifecycle, public resource/geometry observation, and test assertions. Prior CI for source checkpoint: GitHub Actions run `40188209234`, all Linux Lua/static/package steps passed. **Native AHK/Windows/Windower and live FFXI acceptance remain pending**.
- **Confirmed diagnostic coverage gap (medium):** `xivcrossbar.lua` logs native key-down in login context, but not the normal gameplay `transport:gameplay_key` / `setkey ... down` path (approx. lines 1932–1939). A missed action in-game may therefore show a Lua receiver event but lack the expected native-request trace. Remedy: trace immediately before all native key send sites, checking for parity without injecting extra keys.
- **Confirmed shared-reader conflict (medium/high for multibox diagnosis):** `controller_diagnostics.ahk:DiagTick` accepts any new `on <id> <character>` request and closes/replaces an ongoing AHK capture. No ownership/active-session gate or per-client response exists; overlapping `//xb diagnose` commands on separate clients leave a partial AHK section in one log. Remedy: reject the second request with explicit busy status, or later design a multi-subscriber observation feed.
- **Confirmed capture-durability limitation (medium):** `diagnostic_session.lua` buffers Lua observations until stop/deadline. Only AHK stages periodic files. A process crash or freeze before stop can lose the Lua/render portion entirely; "partial on unload" only applies to graceful Lua unload. Remedy: checkpoint a bounded partial Lua capture periodically outside high-frequency input handlers, with careful timing and error reporting.
- **Confirmed stop/unload race (medium):** Normal `stop` provides 0.75s for AHK to process its off request; `force` on unload immediately merges and can read a previous periodic AHK checkpoint before off/final write, silently omitting the last events. Remedy: carry a completion/closed marker and report incomplete merge; avoid claiming full AHK capture without proof.
- **Minor normal-path observation overhead:** `DiagTick` checks for a request roughly every 100 ms even when disabled; `ui/resources.lua` allocates weak render-trace metadata on UI object creation with tracing disabled. Not proven harmful; can optimize if profiling establishes impact.
- **Live-only/open risks:** AHK v1 native parsing and FILETIME/encoding, FFXI window title matching a character lease, rapid input overlap, true frame timing and old caption/fade flickers cannot be accepted by the Linux simulated suites. The beta intentionally did not import personal text settling.
- **Recommendation:** A focused diagnostic correctness patch before relying on the single-file capture for difficult controller bugs; then CI, native Windows syntax check if available, and controlled game acceptance. Keep existing diagnostic ZIP as unverified test candidate until patched or independently observed.

---

# Current Development Status — October 25, 2026 — Beta 1 Diagnostic Test 1

- **Repository/branch:** `rerorriM-Mirrorer/xivcrossbar` / `release/beta1-ps5-directlink`. Original public base `a73a6c6754a1edccd6515a7b641733e044a1f7f9`. Personal `development/directlink` and stable/master branches remain unchanged.
- **Runtime:** `0.4.0-beta1.20261025.ps5-directlink-diag1`; retains all Beta 1 PS5-only DirectLink/other-profile Apps behavior. No companion banks or personal shortcut controls added.
- **Requested behavior:** On-demand `//xb diagnose` creates a fresh, unique per-character 30-second diagnostic file under `xivcrossbar/data/diagnostics/`. Single file merges AHK physical/poll/Apps/DirectLink snapshots, Lua message sequences/acceptance, native key requests, snapshots, routed input contexts, and opt-in public render observation. `mark`, `stop`, `status` and `snapshot` commands supported. No append to earlier captures. AHK writes a bounded **temporary** `data/diagnostics-staging/<session>.ahk`, overwritten periodically (about once/second); Lua merges the last snapshot and removes it upon successful save. The single shared AHK reader supports one AHK diagnostic session at a time.
- **Rendering port:** Copied personal `ui/render_trace.lua` observation engine with a read-only event list API; instrumented public `ui/resources.lua` and `ui_geometry.lua` to observe their existing native calls, text extents, centering, object creation/disposal and contextual frame gaps. Did **not** port personal `ui/geometry.lua`, text settling, replacement UI algorithms or banks. Trace does not observe GPU pixels. Suppressed extra native getter calls: no rendering methods or layout decisions changed on purpose.
- **Performance/safety:** Trace is disabled until requested. Lua writes the final capture once after 30 seconds (or a stop), with a 0.75-second grace for the AHK feed. AHK checkpoints bounded in-memory events and uses a maximum ~512 KiB feed; Lua and render buffers are bounded; overflow counts are reported. Full state is sampled at start/end, not every frame. Logging can itself affect timing, especially during rich UI changes. On unload, partial capture is attempted. Keyboard text/chat contents are not recorded by this controller route; logical controller events and filenames include character identity.
- **Available verification:** Source/regression CI on the working branch executes `python3 tests/run_lua.py tests/*.lua` on Lua 5.4 with documented temporary Windower syntax normalization, parses every Lua source, checks the upstream Python launcher, and builds an exact-source complete installation. New `tests/diagnostic_beta1.lua` covers unique files per request, AHK feed merge, Lua/render ordering, manual marks, stop handoff, unload, caps, render proxy call parity and existing extent result. First CI run after adding the test failed because the isolated fixture omitted LuaSocket; the fixture was corrected to use a deterministic test clock. **Native Windows AutoHotkey, Windower, FFXI, and controller hardware remain untested**; no timing-speed or visual correction is claimed.
- **Previous user-confirmed behavior:** Public RC3 original Apps input and setup worked; personal Survival Guide controller route was successful in a separate development branch. Neither verifies this beta.
- **Release state:** Diagnostic test candidate only. No tagged community release/PR or promotion to master. Next action is one controlled in-game PS5 acceptance recording, then review any trace anomalies.

## Single-file Beta 1 diagnostic acceptance checklist

1. **Back up the installed variant's complete folder**, including configuration/data. Stop the shared reader with `//xb controller stop`, unload XIVCrossbar on all clients, and install this ZIP as a complete `Windower/addons/xivcrossbar/` folder. Do not overlay private/personal settings, do not nest folders, and do not run an old controller AHK in parallel. To roll back, stop/unload and restore that complete backup.
2. Load `//lua l xivcrossbar`; select `//xb controller profile ps5`. Confirm `//xb status` version ends in `ps5-directlink-diag1` and `//xb controller status` reports the selected profile and running AHK route.
3. On **Franklet** (1280×720), run `//xb diagnose`. Use L2/R2 crossbars, bare face/D-pad, Options/Share, in-world and native menus, and an NPC dialogue. Mark any odd behavior with `//xb diagnose mark`. Stop early with `//xb diagnose stop` or let it finish automatically.
4. **Wait until chat says "Diagnostic saved"**, then send the **single newly created** file from `addons/xivcrossbar/data/diagnostics/`. If it instead reports failure, preserve both the error and `data/diagnostics-staging/` temporary AHK feed. AHK events may be absent if the controller wrapper was stopped, focus changed before request, or the temporary file could not be read; the report should identify that rather than silently imply completeness.
5. Repeat on **Killala or Lionstag** (960×540). Test rapid taps, trigger overlaps, a change of FFXI window focus and one menu transition. Verify a second capture gets a different filename and does not append to or overwrite the first.
6. Compare FPS responsiveness and UI visuals with tracing **off** and **on**. Inspect render 'native.text', 'extents', 'center-*', 'surface-retire' and frame-gap lines. If text suddenly appears misaligned or the log reports overwritten events, record it. No extra render instrumentation should be imported from personal until such regressions are understood.
7. Other F710/XInput/FightPadPro input profiles preserve their Apps route but are not necessarily hardware-verified. Continue previous Beta 1 and Maintenance 2 acceptance requirements below.

## Development notes

The Beta 1 trace merges events by Unix-epoch observation timestamps. AHK uses Windows system FILETIME, and Lua uses LuaSocket wall time; this can correlate broad timing but cannot prove the moment FFXI visibly acted. AHK logs *sampled* 10ms controller state, so a tap entirely between polls cannot be reconstructed. Low-volume preview is intentionally used to avoid perturbing the very scheduler being investigated. The capture records only the addon-controlled drawing calls and does not show GPU pixels or other addons' rendering.

---

# Current Development Status — October 25, 2026 (America/Chicago) — Beta 1 PS5 DirectLink Test 1

- **Repository / branch:** `rerorriM-Mirrorer/xivcrossbar` / `release/beta1-ps5-directlink`; founded from the published public RC3 source `a73a6c6754a1edccd6515a7b641733e044a1f7f9`. Upstream reference: qEagleStrikerp/xivcrossbar `15d8381dfad0f9efdb84fe2d24655afc150faec4`.
- **Runtime:** `0.4.0-beta1.20261025.ps5-directlink-test1`; AutoHotkey v1 shared reader with ordinary PS5-only acknowledged button stream. Other PS5 setup/login and F710/FightPadPro/XInput/XInput-alt inputs retain Apps+F1-F12; no companion banks or personal shortcuts.
- **Implementation:** Lua message receiver `controller_messages.lua`, per-character focused lease `controller_lease.lua`, AHK publisher `controller_messages.ahk`, PS5 route in `ffxi_directinput.ahk`, and source-preserving integration into the existing public `xivcrossbar.lua` keyboard router. Message-token/sequence/ack snapshots, stale heartbeat recovery, cancellation, immediate neutral rearm, no queued action replay after cancel. AHK polling uses `SetBatchLines,-1`; PS5 diagonal POV continuity; physical keyboard F-key ownership is kept separate from message holds. Non-PS5 profiles use the old input path.
- **Compatibility:** Original upstream `FFXI_Input.py` and `FFXI_Input.sh` copied into root, unmodified. Historical controller AHK variants and diagnostic files copied under `compat/upstream/` unchanged, for reference only; *not* additional launched profiles. Linux scripts and optional historic AHK utilities are **not** live-tested.
- **Source baseline for acceptance:** Code checkpoint `de106a12264c80ccb061bee2ba5df99114e689ad` (message-input handling and tests). Subsequent status/documentation-only changes do not modify runtime unless explicitly noted. The final published head is in the handoff and GitHub history.
- **Available verification:** GitHub Actions on the Beta 1 branch executes `python3 tests/run_lua.py tests/*.lua` on Lua 5.4 shared library with temporary Windower-literal normalization, 12 top-level suites including the new acknowledged DirectLink/keyboard-owner suite, 64 Lua source parses, upstream Steam Deck Python syntax, and exact-source complete-folder packaging. At least the preceding runtime checkpoint `bcece71b8e16bdb9ad2553c2563cc373665713bd` passed CI; the final acceptance artifact must come from a **successful run at the latest head**. This is **static/simulated** verification only, NOT native AutoHotkey, Windower, FFXI, or controller hardware testing.
- **Last user-confirmed live behavior:** Original public RC3 controller setup, basic Apps routing, startup fade, restart and Icons1 succeeded. Personal development branch confirmed Survival Guide controller operation separately. Neither proves Beta 1 DirectLink in this public branch.
- **Current release gate:** Unreleased test candidate; no community release, upstream PR, stable promotion or in-game acceptance. Personal development and public/master branches unchanged. The user's **one focused live acceptance pass** is next.

## Beta 1 complete installation and rollback

1. Download the artifact from the latest successful GitHub Actions **Beta 1 verification and installable ZIP** workflow run at the published release branch. Its ZIP must contain **one `xivcrossbar/` addon folder** with `README.md`, `WORKFLOW.md`, `TESTING.md`, code, compatible auxiliary references, images and themes; it is NOT an incremental patch.
2. **Before installing:** stop the existing shared wrapper with `//xb controller stop` and unload XIVCrossbar on **every client**. Back up/move the entire existing addon folder (including `data/`, `config.ini`, custom icons/artwork) somewhere outside Windower/addons. Do not overlay Beta 1 atop the personal version or merge their catalogs/data. Only one variant can run from that addon path at a time.
3. Extract the artifact's `xivcrossbar/` directly into Windower/addons; it must NOT become `xivcrossbar/xivcrossbar/`. For an isolated first pass use a fresh Beta 1 setup. Never copy personal settings into the public fork. Load `//lua l xivcrossbar` on each participating client and choose `//xb controller profile ps5` (device 1 unless intentionally changed).
4. Confirm `//xb status` says `beta1.20261025.ps5-directlink-test1`. Open `//xb controller status` after login: PS5 route should report DirectLink messages; before login/setup it may show Apps. Ensure another controller script is not running.
5. **Single live pass:** Cross/Square/Circle/Triangle and D-pad in bare gameplay and native menus; L2, R2, L2→R2, R2→L2 and optional doubletap bars; fast trigger+slot combinations, roll over a diagonal; Options chooser and Share, custom-action editor and Back/Escape; in-world NPC dialogue/status 4; normal physical F-keys and Ctrl+F-keys; two game clients switching focus/one-client reload/unload; save/reload/scale/compact at 1280×720 and 960×540. Record missing/doubled input, menu leakage, stuck keys, and character or screen-resolution effects. Validate fresh login wizard if possible; no-subjob storage/missions remain part of public Maintenance 2 acceptance.
6. If anything fails, note the exact sequence and capture `//xb controller status`, wrapper `data/controller-status.ini`, and the relevant Windower console/chat output. No need to collect logs for each success. Some non-PS5 profiles require unavailable physical hardware and must remain clearly marked **untested**.
7. **Rollback:** Stop Beta 1 reader, unload every client, remove Beta 1 folder, restore the original complete addon folder and its own state, reload. Never mix the public and personal `data` stores.

## Source regression and acceptance rationale

- New `tests/directlink_beta1.lua` exercises actual Lua message parser: ordered trigger-before-face, up events, seq/ack dedupe, stale snapshots, invalid sequence gap, same-snapshot cancellation, heartbeat watchdog and new token, plus source guards for PS5-only messages, absent personal banks, preserved other profiles and Apps key transport.
- Updated existing `tests/login_input.lua` exercises the named real root keyboard handler, pre-login keys and physical F-key passthrough even when a matching DirectLink logical button is held.
- Updated mock `tests/profile_lifecycle.lua` includes the new lease close lifecycle. Existing regression histories below remain applicable but **are not additional in-game testing for this build**.
- Native Windows AutoHotkey v1 syntax/joystick polling, transient title-matched leases, FFXI dialogue inputs, rapid taps and actual multi-client control are still pending. Static tests alone cannot establish latency improvements or reliability under Windower/FFXI.

---

# Current Development Status — October 18, 2026 (America/Chicago)

- **Repository / branch:** `rerorriM-Mirrorer/xivcrossbar` / `public/rc3-maintenance`; working source began at published `dc5e02efa05fdbb3ac75a66887744fc24fb61535`.
- **Runtime:** `0.4.0-a.20261016.public-rc3-maintenance2`; public Apps-key AHK remains unchanged. No DirectLink transport or personal bindings are added in this pass.
- **Current change:** Repaired legacy `sw`/`switch` handling and multiword set keys; made `copy`/`move`, `alias` and `icon` respect `Hotbar.Number`; removed unreachable `set` code; consolidated the mis-signed action callback so own job abilities refresh spell availability. Added regression coverage, the final-status workflow rule and the missing `AGENTS.md` entry point. Aligned package-document placement with the canonical shared convention (inside the installable addon folder).
- **Last user-confirmed live behavior:** Original RC3 setup and controller routing, startup fade, restart and Icons1 were reported working. Maintenance 1 public ports and Maintenance 2 remain pending dedicated live regression.
- **Verification:** All 11 top-level Lua regression files passed with `python3 tests/run_lua.py tests/*.lua`. All 61 Lua sources parsed with the documented Lua 5.4 normalization fallback. This is source/simulated verification, not native Lua 5.1/Windower/FFXI acceptance.
- **Still to test in FFXI:** `sw`/`switch` with empty/multiword names; CLI edits with three and six bars; job-ability spell refresh; all public Maintenance 2 pagination, identity, destinations and save-return cases; multi-client wrapper, menu and resolution regressions.
- **Next development:** Live-test the complete public Maintenance 2 candidate, then consider selective generic DirectLink architecture ports before promotion to `master` or a public tagged release.
- **Publication correction:** The October 16 initial push was blocked, but a later authorized push succeeded. The public branch had reached `dc5e02e` before this task. Earlier dated notes below preserve the original failed-attempt history; they are not the current remote state.
- **Delivery:** Source-and-test checkpoint only; no new ZIP, upstream pull request, community announcement or live FFXI run. Final pushed commit is reported in the GitHub handoff.

---

# Public RC3 Maintenance 2 — complete testing installation — October 16, 2026

Runtime: `0.4.0-a.20261016.public-rc3-maintenance2`.
Branch: `public/rc3-maintenance`. Package header records the final local commit.
GitHub source baseline: `2c41936a5b095b73f3615b3ba241e413ae846126`.
~~**NOT PUBLISHED:** the environment approval check denied the first push. No
alternative push mechanism was attempted. Ask Max to confirm publishing these
commits to the existing public branch. Do not describe this delivery as pushed.~~
**October 18 correction:** This was true for the initial October 16 attempt;
the branch was subsequently published through the authorized GitHub workflow,
with `dc5e02e` as its verified pre-maintenance source head.

## Request, workflow and source baseline

Max requested review of NPCmirror's current WORKFLOW.md first, then all four
previously identified public candidates. Read shared WORKFLOW from
`rerorriM-Mirrorer/ffxi-NPCmirror` (blob
`424d643fd63b944bd8534f455342b5328f1ca48c`); it matches the public copy.
Read the public source, existing passing tests, handoffs and the upstream root
module. Inspect personal source at `9375a66d75778744a865077e2f676458688fc65a`
and the individual port commits; do not overlay whole personal runtime files.
No personal branch, default settings, controller-profile or AHK changes.

| Improvement | Local feature commit | Personal source / behavior |
| --- | --- | --- |
| Shorter target-list pagination | `db3b662` | `2f462fa`; retain Back spell/page |
| Stable identity/storage gate and login keys | `5b31fc4` | `7c97012` and required guards/login dependencies |
| Default-set destinations | `1afc4ef` | `a390b06`; readable labels, stable execution keys |
| Save Only / Save Changes return | `292682a` | New implementation; saved entry selected in edit picker |

## Install safely

This is a **complete install**, not an update-only patch. Unload XIVCrossbar on
all clients first. Back up the installed public folder, including data/config.ini
and custom images. Install the ZIP's `xivcrossbar/` into Windower/addons. For an
upgrade, restore only the PUBLIC backup's data/config.ini and user-added images;
for fresh acceptance, leave user files absent and complete setup. Never run
personal and public variants together on one PC or round-trip personal catalogs
through this public implementation. Switching variants requires stopping the
current wrapper before unloading; this batch's public AHK itself is unchanged.
No settings.xml, config.ini, catalogs, binds, extracted caches or user data ship.
Rollback: unload all clients and restore the backed-up PUBLIC folder/data.

## Verification performed here — simulations only

- All 60 Lua sources parse using the existing Lua 5.4 runner and temporary
  normalization of inherited Windower string-literal method syntax. Lua 5.1,
  LuaJIT, luacheck, Windows, native Windower and AHK runtimes are unavailable;
  this is **not** Lua 5.1/API-aware static validation or live FFXI acceptance.
- Existing checks: 108 layout scenarios across six resolutions/three scales;
  compact command validation/state preservation; 200 menu cycles, 150 typed
  updates, 100 footer rebuilds; 30 crossbar/20 chooser rebuilds; cursor unload
  and deferred/idempotent object destruction.
- Pagination: 12 actual binder spell-page-two/three -> targets -> binding ->
  Back -> save scenarios across six resolutions. Target choices show at page
  one and Back restores Shellra II and the original page.
- Identity: actual initializer, observer and load/login/logout/keyboard handlers
  under mocks. Lobby/unknown server/missing or mismatched entity rejected;
  0.75-second tuple stability, transient retry, late correction and one reload,
  changed character IDs, actual Asura support, no-subjob identity, unconfirmed
  writes blocked, wrapper startup independent of identity, logout invalidation,
  login key-down/up ownership, ignored triggers, physical F-key passthrough.
- Destinations: real binder, slot save, root switch and player execution under
  mocks; all three Default sets, renamed display label, reciprocal same-slot
  switches, quick-switch return and replacement of stale action metadata.
- Save return: six resolutions, real binder and catalog callbacks with mocked
  writes; menu/command create, edit/rename, selection across three pages,
  Back-to-main selection, false/throwing writes with rollback, invalid/duplicate
  names, unsaved cancellation, Save & Bind/Back and 180 bounded repeat cycles.
- Scope checks compare public defaults, AHK, controller profiles and assets
  byte-for-byte with the remote baseline. Package checks enforce required new
  modules, no distributed user state, archive integrity and source-byte equality.

Repeat from repository root:

`python3 tests/run_lua.py tests/compact.lua tests/compact_command.lua tests/menu_resources.lua tests/ui_lifecycle.lua tests/character_identity.lua tests/profile_gate.lua tests/profile_lifecycle.lua tests/login_input.lua tests/crossbar_destinations.lua tests/custom_action_save_return.lua`

## First live tests — not yet performed

1. Verify `//xb status` ends `public-rc3-maintenance2` and reports the correct
   character/server; resource helper stays `public-cleanup1` (unchanged helper).
2. On Franklet 1280x720 and Lionstag 960x540, select a later-page spell, check
   targets immediately, go Back twice, bind and execute. Spot-check 3840x2160.
3. Load before login; test controller arrows/confirm/cancel, then login with a
   no-subjob character. Confirm no false lobby-server folders are created.
   Logout/relogin as another character, reload, zone and change jobs. A server
   remaining wrong beyond the settling interval cannot be predicted; a later
   observed correction reloads normally and does not delete existing folders.
4. Bind reciprocal Default/custom switches (same slot), then Job Default and
   All Jobs Default. Reload and repeat. Check Quick XB Switch returns after one
   action. Rebind an old label-based switch if necessary; no XML migration.
5. Create through menu and `//xb ca`, Save Only, edit the selected entry, rename
   across pages and Save Changes; edit another entry. Check Back, Save & Bind,
   draft cancellation, reload persistence and Options overlay restoration.
6. Repeat prior compact/fades/resource checks, Credits, Escape and fresh setup.
   Restart/unload one of two clients and confirm the other remains usable.

Public candidate remains unreleased. No forum post, PR or announcement. These
changes do not prove resolution of native d3d8.dll crashes, shared text loss or
personal input stickiness. Standard public help/unload modernization and all
personal-only controls/catalog ownership features remain outside this batch.

---

# Maintenance 2 per-feature development notes (retained)

Save-return implementation: new behavior, not an already-completed personal
port. After successful Save Only / Save Changes, return to the edit picker and
select the saved name at its sorted page/row/column. Preserve main-menu Back
selection; clear the completed draft. Failed/invalid saves remain in review;
Save & Bind keeps the existing binding path. Live: create from menu and command,
edit/rename several entries including a later-page entry, save then edit another,
Back to main menu, Save & Bind then Back, cancel an unsaved draft, and verify
persistence after reload. Public linked-copy propagation is still out of scope.

Default destinations port: personal a390b06 adapted without catalog ownership
changes. Tests exercise actual binder, slot save, root switch and action execution
for all fallback destinations, a renamed display label, reciprocal same-slot
switches and Quick XB Switch return after the next action. New action selection
clears stale switch/custom-action metadata. Live: bind reciprocal Default/custom
set switches, reload, then repeat with Job Default and All Jobs Default; test
Quick XB Switch's one-action return. Saved older bindings are not migrated.

Identity port: personal 7c97012 plus its character-identity/storage guards and
login-navigation dependency. Keep the public wrapper, profiles and defaults.
Simulations cover lobby/unknown-server/mismatched-entity rejection, stable
identity, late correction, character IDs, genuine Asura and blocked writes.
Live: load before login; use controller arrows/confirm/cancel, log in and verify
only the correct server/character hotbars load. Logout and select another
character; do not create data under a lobby/default server. Test a no-subjob
character, a reload, job changes and another client remaining usable.

Pagination port: personal published 2f462fa, adapted to public. Actual binder
methods pass 12 page-two/page-three -> targets -> binding -> Back -> save cases
across six resolutions. Lua fixture simulation only; live FFXI acceptance pending.
Retest Shellra II from a later spell page at 960x540 and 1280x720; targets should
appear immediately, Back should restore the spell/page, and binding should work.

---

# Complete installation + conversation handoff — October 15, 2026

Variant: **PUBLIC RC3 maintenance**. This delivery packages all currently implemented
runtime code and required images/themes. Pending ideas are documented, not
implemented. The runtime version remains unchanged.

Start with `xivcrossbar/docs/HANDOFF-PUBLIC-RC3.md` and the shared
`xivcrossbar/docs/BRANCH-MAP.md`. The exported package header records exact local
and published source checkpoints. The standalone handoff copies carry that
header too. Historical update-only instructions below apply to those earlier
ZIPs, not to this complete ZIP.

## Install and identify

1. Stop the currently running shared wrapper with //xb controller stop and
   unload XIVCrossbar on every client (//lua u xivcrossbar works in both builds).
2. Back up/move the existing addon folder. Copy this complete xivcrossbar folder
   into Windower/addons. Do not overlay or run public and personal together.
3. For clean setup leave data/config.ini absent; the wizard creates them. For
   an upgrade restore the matching variant's data/, config.ini and custom icons.
   Never use the installer as a source of empty user files.
4. Load //lua l xivcrossbar. Verify //xb status and //xb controller status,
   complete setup if needed, then use the focused checklist in the handoff.
5. If swapping variants later, repeat stop/unload and use their separate data
   backups. TrustMovement/Trust/AddonManager and native Windower libraries are
   separate dependencies and are not replaced by these installations.

## Evidence and next development

The three approved ports are implemented/pushed and simulation-tested, not yet
live-confirmed in public. Continue compact/fade/resource checks, Credits at both
small resolutions, Escape navigation, two-client restart independence and clean
setup. Stable server gate, target-list pagination, Default destinations and
standard unload/help remain selective-port candidates, not included features.

Additional conversation retrieval did not recover the other threads. This
handoff uses visible discussion, current source, recovered archives and cumulative
records; gaps and historical-only claims are identified. Documentation checks
verify current roles/defaults/commands and preserved branch separation. No new
Windows/FFXI acceptance is implied.

---

# Public RC3 Maintenance 1 — October 15, 2026

Runtime: `0.4.0-a.20261015.public-rc3-cleanup1`. Cumulative public-only ports:
immediate compact switching, corrected text stroke alpha, and resource cleanup.
New branch public/rc3-maintenance recovers the delivered RC3 + Icons/Credits/Escape
runtime. Personal controls, movement integration, personal defaults, catalog
propagation, icon relocation and palette changes are excluded. Master and the
personal development branch remain unchanged by these ports.

Install over the public RC3 runtime only: unload XIVCrossbar on all participating
clients, copy the installable xivcrossbar contents, then load again. No AHK
changes in this patch; the running public wrapper can stay. Do not overlay this
on a personal installation: it is a separate public candidate. No data, XML,
INI, settings, catalogs, bindings or images are shipped. Code rollback targets
the recovered RC3 public baseline, with user data preserved.

## Verification and live checklist

Available checks pass: 108 layouts (six resolutions x three scales x two/six-bar
variants), compact command validation/state preservation, 200 review/edit/bind/back
cycles, 150 text updates, 100 footer rebuilds using an upstream Windower List,
30 crossbar reconstructions, 20 chooser reconstructions, cursor unload after
root disposal, and idempotent deferred destruction. Lua 5.4 parsing uses temporary
normalization of inherited Windower string methods; this is not Lua 5.1, native
Windower drawing or Windows input execution. These checks do not prove a native
crash fix. Prior original public test groups are not claimed rerun here: their
sources were not in the recovered archive.

1. `//xb status`: reports public-rc3-cleanup1. `//xb compact`, explicit on/off,
   scale .6/1/1.5; toggle while choosing sets and editing a custom action. Draft,
   current set, drag position and bindings survive; both layouts fit.
2. Compare text fades in both layouts. No flickering outline; ordinary input,
   startup visibility and captions behave as before.
3. `//xb resources`: note counts on a closed menu, repeat edit/save/bind/back,
   return to the same screen and compare. Counts should settle, not grow every
   cycle. Unload/reload with a menu open; no disposed-object errors.
4. Native gameplay, addon menu, all six crossbar states, physical F-keys and
   Ctrl+F-key bindings remain correct. No personal profile is offered.
5. Remaining prior release checks: Credits at 960x540 and 1280x720; Escape from
   drafts/binding/chooser without native leakage; restart one client while another
   remains usable; final clean installation and setup guide review.

## New user feedback and next candidates

Default reciprocal switches on the personal build are live-confirmed. TrustMovement
is managed by AddonManager; no autoload integration is wanted here. Personal input
stickiness remains under investigation. Deferred public candidates for review:
stable world/server gating, shorter target-list pagination, Default destinations,
and the existing catalog-save navigation request. Future personal design: two L1
modes/banks, per-bank visibility, icon-picker organization and muted lockout colors.
Do not silently include those in this three-feature maintenance patch.

---

# Public RC3 Stroke 1 — October 15, 2026

Port corrected stroke_alpha calls in crossbar text, selector, binder, controller setup and chooser. The drawing mock rejects transparency arguments outside Windower's 0..1 range. The prior personal build was user-confirmed to fade text without flicker after this correction. Recheck public fades in both compact layouts; no palette or timing changes.

# Public RC3 Compact 1 — October 15, 2026

Immediate `//xb compact [on|off]` port only. Existing public settings and controller profiles are preserved; no personal controls or companion are included. Toggle during a draft, chooser use, trigger holds and at .6/1/1.5 scale; check all six bars and drag persistence. Simulated layout/command checks are run before delivery; Windows rendering and input require live testing.

# Public RC3 maintenance — recovered release checkpoint

Recovered RC3 + Icons/Credits/Escape from the delivered public runtime archive. The former local public snapshot ref is not present on GitHub; this branch explicitly recovers that archive and does not alter master or the personal branch.

Remaining prior public acceptance: Credits on both small layouts, Escape across menu types, explicit two-client restart independence, and final package/setup documentation review. Icon fit, ordinary controls, fresh setup, startup fade and restart itself were reported passing.

## RC3 Escape 1 — cumulative menu-exit patch (October 13, 2026)

User requests a small Escape patch. Runtime: 0.4.0-a.20261013.public-rc3-escape1.
Commit 19358ec adds a shared full-exit helper, reused by the normal Share close
path. Physical Escape exits binder menus/drafts/text fields, chooser overlays
and set-name entry, plus setup if open. It cancels the chooser's preview through
the existing cancellation path, closes menus, discards unsaved drafts, restores
hints, and releases the text input block. It does not simulate native Escape.
The keyboard handler owns Escape repeats and release after close; normal Escape
outside addon menus passes through. Focus reset clears any abandoned ownership.
Circle/Enter handling is unchanged, and wizard cancellation does not mark setup
complete or change readiness. Unsaved field changes are intentionally discarded.

All 49 Lua regression groups pass, including new full-exit routing tests for
main/review/binding/Credits/inline/chooser/chooser-text/setup, pre-initialization
setup cancellation, held repeat/release, and restored native/unrelated input.
Three cumulative runtime Lua files parse after temporary standard-Lua string
normalization. README and release README document the Escape behavior.

Delivery: cumulative three-Lua-file update plus README over complete RC3 with
or without Icons 1/Credits 1. No bindings/configuration/images/wrapper replaced.
Exact complete-RC3 rollback copies included outside the runtime folder.
Live checks: Escape from main menu, binding capture, inline edit and chooser over
a draft; every addon layer closes and one press does not cancel the native menu
beneath. Release it, then verify the next native Escape works. Circle still backs
one step. Credits 1 and explicit two-client restart confirmation remain pending;
icon alignment, startup and fresh setup/controls are user-confirmed passes.

---

## Icon live pass and branch/navigation discussion — October 13, 2026

User confirms patched icons "now fit the button slots perfectly." Icons 1's
native rendering is a live pass. Credits 1 visual results remain pending.

User proposes keeping a finalized release branch while developing personal
features separately, then porting generally useful fixes back. Recommended
starting point is the tested public release; the older personal branch remains
a reference for deliberately selected features. No branches created or changed
by this discussion record. Do not mark a new release trusted until its remaining
live checks pass.

Requested navigation consistency: physical Escape should exit all XIVCrossbar
menus like Share/Create, including text entry and chooser overlays. Current
code handles Escape as text cancel/back or chooser close, with no general menu
exit handler. Proposed release fix should share complete-exit behavior, consume
both key edges, retain Circle's one-step Back and leave native Escape alone when
no addon menu is open. No runtime Escape patch applied during this discussion.

---

## RC3 Credits 1 — cumulative Credits/icon update (October 13, 2026)

User authorizes repairing Credits; leaves stronger menu-gradient tuning for later
personal testing. Runtime: 0.4.0-a.20261013.public-rc3-credits1. Commit e7bbd33
corrects all avatar paths to images/credit_avatars/, removes manual newline
spacers from the responsive grid, and starts Credits on page 1 while preserving
the saved main-menu selection for Go Back. All original people and roles remain.
No shared selector or menu-gradient behavior changed.

The new Credits regression fails before the fix on inherited pagination. After
the fix it verifies all avatar files, entry count, saved main-menu return state,
and reachable in-grid entries at 960x540, 1280x720, 1600x900, 1920x1080,
2560x1440 and 3840x2160. All 48 Lua regression groups pass; three delivered
runtime files pass syntax checking after temporary Windower string normalization.

Delivery: three-file cumulative overlay over complete RC3, including Icons 1.
No base images/configuration/bindings included. Exact original RC3 rollback
files are included outside the runtime folder. //lua r xivcrossbar applies it.
Live checks: Credits displays icons/labels on Franklet and Lionstag, all entries
fit, Circle returns to the prior main-menu selection, Share exits, and native
spell/pet icons align after the included icon patch. Live visuals remain pending.

---

## RC3 live results and Credits report — October 13, 2026

User reports fresh setup went well, controller buttons work without bleed-through,
startup fade looks good, and //xb restart "works great." Restart itself is live
confirmed; the report does not separately confirm another client stayed usable
during that command, so retain that specific cross-client check as pending.
User does not notice a darker menu gradient, although the custom action screen
may be darker. Do not increase the gradient based on this observation alone.
RC3 Icons 1 visual result remains pending while the user checks it.

Credits: missing icons and misaligned entries on Franklet; nothing appears when
selected on Lionstag. Code inspection finds avatar paths omit the required
images/ prefix, Credits inherits the main-menu page number instead of starting
at page 1, and manual newline spacer entries assume the old grid arrangement.
These explain concrete missing-resource/pagination/layout risks; no Credits
runtime patch has been applied yet. Preserve credited people/roles when fixing.

---

## RC3 Icons 1 — native icon alignment patch (October 13, 2026)

User requests an icon-overflow patch while testing RC3. Runtime build:
0.4.0-a.20261013.public-rc3-icons1. Commit b6fb93d removes only the obsolete
4px right/down inset in load_action; geometry already sizes icons to 40px slots.
The artwork, slot dimensions, scaling, and action execution remain unchanged.

Extended item_icon_routes.lua exercises actual action loading through the real
geometry proxy. Dia fails the slot-origin assertion before the fix. Afterward,
spell/pet/job/weapon/item/custom/linked/mount paths align at scales 1, .6 and 1.5;
presentation and movement-cohesion checks pass. All 47 Lua regression groups
pass, and both changed runtime files parse after temporary standard-Lua
normalization of inherited Windower string methods. Native rendering remains
a live check.

Apply the two runtime files over the complete RC3 installation, then
//lua r xivcrossbar. No images/data/config.ini included or replaced. Rollback
files reproduce the exact complete-RC3 versions from commit 7568505.
Check Dia, Sic, Leave, Heel and Fight: icons should fill their slot without
spilling right/down. Compare an unaffected custom/item icon, then try scale .6
and restore the preferred scale. Continue the pending RC3 startup/restart checks.

---

## Live native XInput compatibility result — October 13, 2026

Lionstag: user enabled FFXI Gamepad Config's native XInput checkbox while retaining
the addon's PS5 DirectInput wrapper profile. After the proposed movement/camera,
native-menu, addon-menu and trigger-binding checks, the user reports: "Nice it
seems to work exactly the same." Overall compatibility pass on this setup;
individual checks were not separately reported. This does not establish that the
AHK XInput reader detects the controller or validate other controller hardware.
Runtime version was not reconfirmed; the latest explicitly reported installation
was RC2, so this is not recorded as an RC3 fresh-install pass.

RC3 fresh setup, revised startup/gradient and //xb restart across two clients
remain pending. Earlier lua r/unload multi-client checks passed; the remaining
restart check specifically concerns the restored //xb restart command.

Additional RC2 report: Dia, Sic, Leave, Heel and Fight icons spill outside slots
at //xb scale 1; reloading does not change their appearance. Screenshots supplied:
image(20261013-080954).png and image(20261013-081021).png. They were not inspected
because workspace access failed at that time. Shared icon sizing/cropping is a
hypothesis, not an established cause. Check on RC3 before marking it resolved.

Follow-up after workspace access returned: both screenshots inspected. The named
spell/pet icons visibly extend to the right/bottom of their slot frames. Current
ui.lua still adds +4/+4 to non-overridden icons (commented as centering 32px
icons), while ui_geometry.lua gives images an explicit 40x40 size and disables
native texture fitting. This is a concrete positioning/sizing mismatch present
in RC3 too. No runtime change made during this test-result documentation update.

---

## Public RC3 complete fresh-install candidate — October 12–13, 2026

User requests a complete fresh installation as server maintenance approaches.
Runtime: 0.4.0-a.20261013.public-rc3. Branch public/controller-profiles; local commits
only, no remote push. Relevant commits: 956dd5b relocated owned assets; a70f824 new
0.1/0.5/2 fade defaults; 408f36f startup independent of regular fades; 53ef7d5 subtle
black menu gradient; b7e79b4 adopts user's final README proposal with technical
corrections; 609d13d identifies the runtime candidate.

Startup now always uses LoadFadeIn when visibility permits, even with regular fades
off. Both always/oninput modes respect trigger interruption: normal FadeIn when on,
instant full opacity when off. After the intro, normal visibility resumes. Text
stays at fade endpoints, including startup with regular fades disabled; instant
interruption restores static hints as well as rows refreshed by recast checks.
Regular-fade toggles during startup preserve that phase rather than restarting it.

Menu normal alpha is 150 at the top, approximately 190 at the bottom; custom review
215 to approximately 235, black RGB throughout. Thirty-two additional strips use
only existing Windower primitive APIs, are created before foreground UI, share
bounds/visibility and are reused on repeated setup. No new image-generated artwork.
Other backgrounds/text entry fields are unchanged.

47 Lua regression groups pass; reader mappings match pinned upstream. Complete
package audit checks local module imports, each raster, icon-list references,
source-identical runtime files, relocated assets and provenance. Syntax checking
uses temporary standard-Lua normalization of inherited Windower string methods.
Windows live rendering of the new gradient/startup semantics and graceful restart
remain to test; previous positive results remain recorded below.

Installation: stop old script, unload on all clients, back up and move old folder
out of addons, extract the complete xivcrossbar folder. For true first-run testing,
do not copy config.ini/data initially; restore them later if desired while unloaded.
No game-client relog required for addon changes. Includes images. No player data,
config.ini, controller extras, personal L1 addon, AGATHOS/WORKFLOW/DESIGN, tests,
old install notes or unsupported alternative scripts are distributed. README and
asset provenance are user-required documentation. LIVE-CHECKS.txt stays outside
addon runtime. Rollback is the backed-up complete folder, not mixed Lua files.

Live checks after maintenance:
1. Fresh welcome -> PS5 input profile -> artwork -> assignments -> completion,
   menu navigation and one real binding; check status reports public-rc3.
2. Startup in always/oninput modes with regular fades on/off; no input reveal,
   trigger interruption and subsequent show/hide behavior; defaults 0.1/0.5/2.
3. Main menu and custom review gradients at 960x540 plus a larger resolution;
   page icons and golden cursor work from images/assets; chooser overlay hides
   and restores the full background coherently.
4. //xb restart with fades on/off, a menu/inline field/chooser open, repeated
   requests, saved binding persistence and another client remaining functional.
5. Optional native XInput checkbox test remains user-pending, not a requirement
   asserted for all controllers. Alternate physical hardware remains experimental.

Atomic wrapper startup lock and last-client shutdown remain on personal backlog,
not in RC3. No input-leakage patch is included: user suspects extra physical Enter
presses and heard a Circle targeting sound without establishing a target change.
Catalog edit propagation and other personal requests remain deferred.

---

## Final-candidate assets/defaults and narrowed scope — October 12, 2026

User explicitly requests only moving owned assets/ into images/assets/, not a
broader directory overhaul. Commit 956dd5b moves all 12 files byte-for-byte;
selectable-list page/button/cursor paths, README attribution paths and packaging
allowlist are updated. Theme/helper/iconpack directories are unchanged. 46 Lua
regression groups pass. An internal complete-package audit verifies 2155 files,
44 runtime Lua files, 2101 rasters, no missing local modules or indexed icons;
all moved assets including credits/provenance are present at new paths. No
user-facing new candidate is delivered yet; the audit archive is intermediate.

Commit a70f824 sets FadeIn=0.1, FadeOut=0.5, LoadFadeIn=2 defaults, with both README
copies updated. Saved settings remain preserved. Defaults parse and whitespace
checks pass. AutoHideExtraBars=true is already implemented in the prior update.

User now suspects keyboard Enter menu-selection attempts explain the input report;
controller Circle was a targeting sound during binding, not an established target
change. Do not call either a confirmed new leakage bug or a reproduced fix.
XInput native-config test still pending. No input code changes made.

Remaining candidate discussion/implementation: bottom-heavier black background
gradient, startup phase independent of gameplay fade toggle with trigger interruption
(short fade when enabled, instant when off), user's final README corrections/new
paths/defaults, then live restart checks and clean installation package. Mutex and
last-client shutdown remain explicitly deferred to personal development.

---

## Final-pass discussion: background, input leakage and startup policy — October 12, 2026

User explicitly requests discussion before changes. Wants menu background slightly
more opaque at the bottom than at the top. Current background is flat RGB 0/0/0:
normal alpha 150/255 (~59%); custom review alpha 215/255 (~84%). Button-entry
rectangle is also alpha 150 black; inline field alpha 240 RGB 16/26/48.
Suggested gradient: normal 150 top to 190 bottom; review 215 top to 235 bottom.
No rendering changes made.

New Franklet observation: Circle and several Enter presses leaked while creating
custom actions and binding. Exact loaded build, event sources and transition
sequence unspecified. Prior passes remain valid for their tested scenarios;
this newly reported path needs investigation. Physical Enter outside an active
field currently passes through intentionally; the committing Enter and its key-up
are supposed to be consumed. Controller Circle inside menus should be consumed.

User requests startup animation despite regular fades being disabled in always
mode, with immediate reveal on held triggers when fades are off. Proposed reading:
startup duration is independent of gameplay fade toggle in both always/oninput;
triggers interrupt with normal FadeIn when enabled, immediate opacity when off;
after startup ordinary visibility resumes. Confirm interpretation during discussion,
including oninput/no-trigger case when fades are off. No runtime change.

User explicitly moves atomic startup lock and optional last-client AHK shutdown
out of the release scope and onto the personal backlog. Live restart checks follow
these final-pass discussions. Do not silently reintroduce those deferred features.

---

## Fade/default clarification and post-release motivation — October 12, 2026

User plans to test FFXI native Enable XInput while the addon keeps its selected
profile; do not treat the native checkbox as a universal requirement before the
result. No test result supplied yet.

Current code: //xb fade off disables startup animation too. Always mode shows
immediately; oninput stays hidden until a trigger, then shows without fading;
explicit hidden mode stays hidden. AutoHideExtraBars=true is implemented and
shipped in preview38-restart defaults.lua; explicitly saved false remains.
The README note describes that default, not a separate runtime change.

Recorded <t> first/default where available as a post-release request. Collected
personal ports and deferred ideas in docs/PERSONAL-BACKLOG.md; distinguish existing
personal implementations from new proposals. No runtime or uploaded README changes.

---

## Last-client unload request and final README review — October 12, 2026

User wants on_unload_killahk to mean stop the wrapper only after the last client
using this addon unloads. Current public code forces the setting false and saves;
upstream b245aa5 ran killahk.bat on each enabled client's unload. Desired correction
needs loaded-addon client registration, not merely counting FFXI windows. Proposed
unique per-client records, removal on unload, wrapper-owned stop-if-unused decision,
reload handoff grace and stale-registration cleanup. This complements the proposed
atomic AHK startup lock. Neither change is implemented or live-tested yet.

Reviewed supplied local XIVCrossbar-README-Review-Final Proposal.md (Library
libfile_145b1887bf748191a6572507309fd8cc). Required corrections: //xb can n typo
must be //xb ca n; disable-native-XInput instruction must be scoped to tested
PS5 DirectInput configuration; //xb fade affects startup/manual visibility too,
not only autohide. Restore the requested AutoHideExtraBars=true default note.
Other user's cuts and ordering are intentional. Leave the uploaded proposal
unchanged for now; the existing README review remains under discussion.

Remaining small runtime work: atomic simultaneous-start guard; optional last-loaded
client shutdown. Delivered restart awaits user-reported live checks. Startup,
completion layout, extra bars with autohide, and multi-client unload/reload results
are already recorded. Catalog edit propagation/compact toggle/icon reorganization
and personal controls remain deferred.

---

## Simultaneous all-client wrapper startup investigation — October 12, 2026

User reports send @all lua l xivcrossbar appears to load multiple AHK scripts.
Exact installed build, process count and script paths have not been supplied.
Reviewed current preview38 code: each client's start_controller_wrappers checks
fresh controller-status.ini, then writes launch configuration and issues run.
There is no atomic claim between checking status and spawning. Several clients
can therefore request launch before the first wrapper writes its initial status.
AHK #SingleInstance Ignore is present, but documentation explicitly identifies
simultaneous-start detection as a limitation that can permit multiple instances.

Source: https://ahk4.us/docs/commands/_SingleInstance.htm (AutoHotkey v1 directive
documentation, Limitations). This establishes a plausible mechanism, not a confirmed
process/path diagnosis for this particular report. Different installed folders or
older scripts remain other possibilities if persistent duplicate processes are seen.
Suggested correction: an atomic, script-folder-scoped Windows lock in the AHK
wrapper, acquired before input/status ownership, so one process is the owner and
competing launches exit. Mere same-process-name checks are not atomic and cannot
distinguish separate scripts hosted by AutoHotkey. No runtime change in this pass.

---

## RC2 Restart update — October 12, 2026

User requests restoring //xb restart while reviewing documentation. Runtime:
0.4.0-a.20261012.public-preview38-restart. Implementation closes chooser/menu/setup,
ends dragging and text capture, releases owned gameplay keys, cancels pending
profile changes and fades out the bar before sending lua r xivcrossbar.
Repeated requests schedule one reload. During the fade, controller actions and
normal bar rendering are suppressed while the geometry fade continues ticking.
Disabled fades use zero delay. The shared AHK process is unchanged and survives
this reload. //xb reload remains XML-only; //lua r remains immediate.

46 Lua regression groups pass, including actual restart command dispatch, delayed
reload, one-shot scheduling, initialized/uninitialized interactions and fades off.
Runtime syntax and package byte checks also apply. Live restart remains untested.
README copies include the restored command; their review is still ongoing.

Delivery: cumulative eight-file overlay over complete RC2/Profiles2/Setup1/Setup2.
Includes AutoHideExtraBars=true for new configurations (existing saved settings
remain), all Setup 2 changes and restored restart. No images/data/config.ini or
README shipped. INSTALL.txt outside the addon root supplies installation and tests.

Live checks: //xb restart with fades on/off; restart with an addon menu, chooser
or inline text field open; quick repeated restart requests; binding persistence
and another loaded client's controller after the restart. Check status reports
preview38-restart. No fresh remap is required for these checks.

---

## Extra-bar visibility default — October 12, 2026

User requests hiding extra bars by default while reviewing the README.
AutoHideExtraBars changes from false to true; Hotbar.Number is unchanged.
This is the behavior already live-tested with extra bars enabled. Drawing and
input rules are unchanged. Both README copies describe the default and retained
saved settings. Existing explicit false values remain false until edited.
Change awaits the next installation package; the delivered Setup 2 ZIP still
contains the earlier false default. The existing downloaded README review copy
is not replaced during this piecemeal review; incorporate this note in the next
review/release document.

---

## README review draft — October 12, 2026

User approves correcting fallback wording and deferring catalog-edit propagation
for this public release; the feature remains wanted for personal development.
Readable field commands use name/alias/command, with n/a/c described as alternative
spellings rather than literal slash syntax. No runtime changes in this pass.

README.md and packaging/README-release.md now follow the user's proposal:
changes, prominent configuration screenshot, controls/IJKL illustration,
appearance, custom actions, help, installation, simplified profiles and credits.
A concise change summary remains at the end. Startup behavior and automatic
profile switching match Setup 2; old manual-switch instructions, retired settings,
API/status internals and development build history are removed. PS5 is live-tested;
alternate hardware remains experimental. Upgrade instructions use a fresh folder
with data/config.ini/custom icons restored from backup, not mixed old code.

Draft is for user review, not a newly approved complete release. Both documentation
copies match; local image/license/notice links and available command/profile forms
are checked. No addon test package or runtime version change prepared here.

---

## Setup 2 visual checks passed — October 12, 2026

User reports both the startup fade and completion screen look good, especially
the completion screen now that its intended layout is visible. Record both
visual checks as live passes. This general feedback does not separately confirm
every trigger-interruption/fades-off variant from the detailed checklist.

Remaining release work: final clean complete-install/rollback check, README
revision from the user's proposal, configuration illustrations and package audit.
Held-direction and menu-open focus cases can be checked during ordinary play;
the held-R2 case and two-client unload/reload checks have passed.

---

## Multi-client reload live result — October 12, 2026

User ran lua r xivcrossbar on Lionstag: Franklet still worked, and after switching
back Lionstag still worked. This establishes the requested two-client reload
check in the tested setup, alongside the earlier one-client unload pass. The
report does not identify whether Setup 2 has already been installed; do not
claim the new startup/completion changes are live-tested from this result.

---

## RC2 Setup 2 — startup reveal and completion layout (October 12, 2026)

Runtime: 0.4.0-a.20261012.public-preview37-setup2. Runtime commits: 28959f9
(completion-screen rows), 4ce57b8 (startup reveal without input), 7f25836
(trigger interruption). All 45 Lua regression groups pass; changed Lua parses
with temporary normalization of inherited Windower string-method syntax.

User held R2 while clicking away, then refocused while still holding it. The
crossbar stayed cleared and a command did not fire; no stuck movement, trigger
field or unexpected action. This live result confirms neutral-before-rearming
for that held-R2 scenario. Held direction and addon-menu variants remain pending.
The multi-client reload test means lua r xivcrossbar on one client, then check
both; one-client unload has already passed on Franklet/Lionstag.

Cumulative eight-file overlay for complete RC2, Profiles 2 or Setup 1. It includes
all six Setup 1 files plus ui_geometry.lua and visibility.lua. No images,
player data, config.ini, README or developer files are included. INSTALL.txt
sits outside the addon folder. Back up, stop the shared wrapper and unload this
addon on every client using the folder before replacing Lua; then load again.
No client relog required. Existing saved fade durations remain unchanged.

Live checks:
1. With autohide on and no controller input, loading reveals the bar fully,
   then fades out. LoadFadeIn defaults to 3s; change an existing saved 1.5 to 3
   while unloaded if you want that duration. Later input uses normal FadeIn.
2. Reload and press either trigger midway through startup. The bar should
   reach full visibility using normal FadeIn from its current opacity, rather
   than waiting for the long animation. Holding does not restart the fade.
3. With fades off, trigger-held bars appear immediately. Restore fades after.
4. Completion dialog rows are separated at 960x540 and a larger resolution.
   Existing installations need not remap merely to test gameplay.
5. Multi-client reload, held-direction/focus and menu-open focus variants.

Job-ability icon lookup reviewed: resource_generator.lua derives an iconpack
category/name path and recast-ID fallback (SP abilities include job IDs). The
menu and slot renderer prefer an existing iconpack file; saved slot/shared icon
handling is separate. No icon selection behavior changed.
README revision remains deferred until finalizing live tests.

---

## Two-client unload result and extra-bar explanation — October 12, 2026

User loaded Franklet and Lionstag, unloaded XIVCrossbar on Lionstag, and reports
Franklet still works. This confirms the shared wrapper survives one client's
unload in the tested setup. It does not yet establish all held-button/focus-switch
cases. User also reports button release feels much better than expected.

Pinned upstream README recommends AutoHideExtraBars=true for six bars and documents
HotbarOffsets.DoublePress.X/Y for LL/RR (bars 5/6). X offsets move the two sides
outward/inward symmetrically; Y applies to both. Negative Y moves them upward.
These settings remain available; AlternatePress offsets concern bars 3/4. Visible
extra bars can serve as a persistent view of their bindings if repositioned.
Author intent beyond the documented behavior is not established.

AHK emits press/release edges once, releases owned signals on focus change,
disconnect or exit, and requires neutral controls before rearming. Lua additionally
releases injected gameplay keys, clears local trigger/page state and retains menu
drafts across focus changes. Crossbar fade/text release presentation is Lua.
No runtime changes or package prepared for this result.

---

## RC2 Setup 1 live results and startup reveal — October 12, 2026

User reports tests 1, 2, 3, 5 and 6 passed: automatic switching, profile commands,
disconnected-profile recovery, draft/chooser/icon binding and reload persistence.
Test 4 remains pending with multiple clients. Test 7 mostly passes, but oninput
visibility delayed the startup fade until the first trigger press. Test 8 partially
passes: extra bars work with AutoHideExtraBars=true; false draws overlapping bars.

Startup correction committed at 4ce57b8: the ready crossbar starts its
welcome reveal without input, reaches full opacity for a rendered frame, then
returns to the normal visibility policy. Default LoadFadeIn is restored to 3s.
Explicit hidden mode and cutscene suppression remain respected; disabled fades
retain ordinary autohide. Existing saved fade durations are preserved: a saved
1.5 still needs changing to 3 to test the three-second welcome. No package yet;
the installed Setup 1 still has the delayed first reveal. The completion-screen
layout correction at 28959f9 is also awaiting delivery.

45 Lua regression groups pass, including the real prerender startup path with
controlled time, no input, readiness/hidden/cutscene guards, full opacity, normal
fade-out, held triggers and subsequent short fades. Whitespace checks pass.
Extra-bar coordinate methods and draw-policy rules match pinned upstream baseline
b245aa5; the overlapping positions with default offsets are inherited. No extra-bar
layout/default changes made; AutoHideExtraBars=true is the live-tested choice.

Remaining: multi-client focus/held-release and reload/unload checks; live startup
reveal and corrected completion-screen layout after delivery; clean complete-package
install/rollback audit, README update from the user's proposal and configuration
illustrations. Alternate controller hardware remains explicitly unverified.
No new features are required by this checkpoint. Do not repeatedly retest the full
passed list unless subsequent changes affect it.

---

## Cioara Setup 1 feedback — October 12, 2026

User reports setup completed on Cioara on Frank's PC and normal functioning so
far. Completion-screen screenshot shows overlapping success/help text and crowded
Share/Options artwork, matching Lionstag's earlier observation. Code placed the
first two text rows ten pixels apart regardless of resolution. Completion layout
now uses separate success, action-menu, chooser, new-set and exit rows. No setup
behavior changed. Fix committed for the next update; no package generated yet.

---

## RC2 Setup 1 — first-run profiles and automatic switching (October 12, 2026)

Runtime: 0.4.0-a.20261012.public-preview36-setup1. Previous live-tested profile
snapshot is preserved as tag testing/public-rc2-profiles2 at 7b58860. This pass is
restricted to the four agreed usability changes and the initial fade default.
README revision and catalog edit propagation remain deferred. AHK reader/transport
code is unchanged from the startup-file fix in Profiles 2.

### Installation

Run //xb controller stop on the old code, then unload XIVCrossbar on every client
using this folder. Back up the folder. Merge the supplied six files into
addons/xivcrossbar. Keep installed data/config.ini/images. Reload; no client relog.
This update includes all changed runtime files needed over original RC2 or its
Profiles 2 fix. Developer documents/tests stay outside the addon download.

### Live checks

1. //xb controller status: saved/running ps5-directinput, device 1, Apps, ready,
   connected=true. Retest one ordinary binding and addon-menu Cross/Circle/D-pad.
2. //xb controller profile xinput: no separate stop/start commands. Wait about
   two seconds, check status: running XInput. Disconnected is expected on the
   currently tested PS5 setup; it does not mean switching failed. Return with
   //xb controller profile ps5; check ready/connected=true and one bound action.
3. //xb controller profiles lists short names. Long profile names remain valid.
   Unknown names/out-of-range device values must leave the current selection intact.
   Optional device number remains supported. Manual start/stop remain available;
   an explicit stop cancels a pending automatic change.
4. //xb remap opens the input profile screen. Four options: PS5 DirectInput,
   Xbox/XInput, F710 DirectInput, FightPadPro DirectInput. Hover lifts the row two
   pixels up/left and returns it without accumulating offsets. Choose PS5: after
   detection, choose artwork separately, then Confirm/Cancel/Main Menu/Active Window.
   Intended PS5 face layout: Cross/Circle/Triangle/Square respectively. Complete
   existing confirmations; verify settings save and ordinary bindings still work.
5. Remap again; choose XInput. If disconnected, remain on profile choices with
   an explanatory message. Choose PS5 to recover. No console startup commands
   should be needed. Check at 960x540 and a larger resolution.
6. Fresh-install welcome test later: welcome click opens profile choices without
   starting AHK. Only selecting a profile starts its reader. Data/bindings need not
   be deleted for testing; preserve the normal installation separately.
7. //xb fade off/on and bare toggle act identically to //xb ui fade. Invalid values
   change nothing. New initial-load fade default is 1.5s; existing explicit saved
   Animation.LoadFadeIn values remain unchanged. To try it on an existing config,
   set LoadFadeIn to 1.5 while unloaded and reload.
8. Remaining release checks: multi-client/focus changes, additional bars 4-6,
   fresh setup without subjob, custom actions/icons/chooser draft, and persistence.

### Verification and implementation

44 Lua regression groups pass. New switch state machine waits for fresh stopped
status, includes a short post-ExitApp buffer, and verifies the actual running reader.
It polls only during a pending change, handles timeout/cancel/competing clients,
and avoids claiming success from a start request alone. Callback generations keep
closed/restarted setup from being reopened by an old completion. Actual wizard
mouse paths and geometry are tested at the small baseline plus existing larger
resolution tests. Local syntax normalization remains temporary for inherited
Windower string-method shorthand. Windows graphics and this exact automatic
switch behavior await live confirmation. No README package prepared in this pass.

---

## Lionstag live profile results — October 12, 2026

RC2 Profiles 1 PS5 DirectInput: status ready/connected, bare native-menu D-pad,
addon menu D-pad/Cross/Circle/Share, no action bleed-through, L2/R2 bound actions
without macro popup or target leakage, and optional IJKL targeting all passed.

RC2 Profiles 2 startup handoff: selected XInput now becomes running XInput,
Apps, source=launch-file. This supports the missing launch-arguments explanation;
startup-file fallback is live-confirmed. XInput devices 1, 2, 3 and 4 each report
disconnected/connected=false. Native FFXI stick movement/camera continue working,
which does not establish XInput exposure to AHK. Alternate XInput hardware behavior
remains unverified; a separate detection investigation can follow if desired.

Switching back via stop/profile ps5-directinput/start returns ready/connected=true
and a bound action executes successfully. No user configuration or binding repair
was needed. All results are user-reported on Lionstag; no claim of other controller
hardware validation. Profile short aliases/automatic stop-start and README proposal
are pending, not included in Profiles 2. No new package prepared for this checkpoint.

---

## RC2 Profiles 2 — startup handoff investigation (October 12, 2026)

Lionstag live RC2 Profiles 1 results: PS5 status ready/connected; native menu
D-pad, addon menu face/D-pad input without bleed-through, L2/R2 bound actions,
no macro palette/target leakage, and IJKL targeting all pass. Switching selected
profile to XInput still reported a running PS5 reader after stop/start; stop then
reported no fresh running status, but a new start again reported PS5.

Likely cause under investigation: launcher/script association omitting profile
arguments, causing the AHK default. Not yet proven; alternative includes another
client starting the PS5 reader. Profiles 2 writes a validated startup INI before
launch and reads it at AHK startup when profile arguments are absent. Status adds
origin=arguments/launch-file/default to identify the path actually used. Running
reader never rereads the handoff, preserving startup-only selection.

43 regression groups pass, including startup INI validation/write errors and
lifecycle ordering; mapping checks remain passing. Small overlay contains only
xivcrossbar.lua, controller_profiles.lua, ffxi_directinput.ahk plus outside-folder
installation instructions. Complete package also rebuilt. No profile auto-restart,
short aliases or catalog propagation changes included in this diagnostic fix.

Retest: stop current wrapper, unload addon, merge overlay, load, start selected
XInput, release buttons/focus FFXI and check controller status after one second.
If mismatch persists, return data/controller-status.ini and controller-launch.ini
and note other clients that might be loading XIVCrossbar. No relog required.

---

## RC2 Profiles 1 — selectable controller readers (October 12, 2026)

RC1 is preserved as tag `testing/public-rc1-preview34` at cc6b7bf and as the
previous complete download. Work is isolated on `public/controller-profiles`.
Runtime: 0.4.0-a.20261012.public-preview35-profiles1. This is a testing candidate,
not a claim of live validation of other controllers. No AHK v2 or personal controls.

### Install and test

1. While still on the old package, run `//xb controller stop`, release buttons,
   and unload XIVCrossbar on every client. Back up the installed folder. Merge
   the complete RC2 folder, preserving data/config.ini/custom assets; reload.
2. `//xb controller status`: saved ps5-directinput/device 1 and running
   ps5-directinput/apps should agree. Focus FFXI and wait one second before
   checking connected/ready. Release controls if waiting-neutral is reported.
3. PS5 regression: bare D-pad native menus; addon menu D-pad/Cross/Circle/Share;
   all slots on L2/R2; both-trigger arrangements; no macro popup or F-key target
   leakage; physical keyboard F7/F8 still target normally.
4. Focus switch while holding a face/D-pad/trigger, release, return. No automatic
   execution on rearm and no stuck native direction/trigger field. Reload the
   second client: it must reuse the shared wrapper, not replace its selection.
5. `//xb controller profiles`; save `//xb controller profile xinput 1` while
   the PS5 reader runs. Status must say selected XInput but running PS5. Start
   must refuse that mismatch. Stop, wait for completion, then start from the
   client with XInput selected. If changing through the wizard, use the console
   before input confirmation; artwork selection alone never selects a backend.
6. XInput: check connected status first. If disconnected, try device 2–4 with
   stop/profile/start; do not claim success from FFXI's checkbox alone. If detected,
   test each digital button, each trigger and both simultaneously; repeat step 3.
   Diagonal D-pad inputs may set two directions under XInput. Record any difference.
7. Return via stop/profile ps5-directinput 1/start. Verify ordinary actions and
   menus again. Invalid names and device numbers must leave the saved choice intact.
8. Optional hardware owners: F710/FightPadPro use corresponding profiles. The
   xinput-r1-chooser profile uses R1 for Options/set chooser; clear duplicate native
   R1 assignment. All alternate hardware profiles remain experimental.
9. Additional bars: in a backed-up test config increase Hotbar.Number to 6 and
   reload, then test both-trigger order variants and double-L2/double-R2 bars,
   binding/execution, scale/drag and AutoHideExtraBars on/off. Restore normal value.
10. Fresh installation: new setup/character without subjob; custom action creation,
    inline Enter protection, save/bind/draft-preserving chooser; Use Item icon;
    Superwarp; visibility/scale/drag; reload and job-change persistence. Check at
    960x540 and a larger resolution. User configuration screenshots are in README.

### Results and limits

43 Lua regression groups pass, including actual profile lifecycle handlers with
simulated wrapper status and pending-stop timing. Reader assignments are compared
with all three upstream DirectInput scripts; XInput digital flags and trigger
record offsets checked. These are offline checks, not Windows/AHK execution.
The standard syntax checker normalizes inherited Windower string-literal method
shorthand in a temporary copy only. No existing XML bindings changed here.
Status heartbeat uses data/controller-status.ini and is fresh for five seconds.
No fresh status does not prove that an old uninstrumented wrapper is absent.
SingleInstance ignore remains the final duplicate-process guard. Profile settings
are per client; running reader is shared. No running profile is changed by saving.

Retired new defaults: below1080, Controls.ToggleBattleMode and independent
use_directinput/use_xinput flags. Legacy XML keys remain unused. on_unload_killahk
remains forced false; explicit shared stop applies. InputTest/InputTrace remain
false by default. All release credits/comments now use A. README is current user
instructions; historical development information remains here and in git.

---

## Next-package notes — October 12, 2026

Contributor identity is A; apply it consistently to release credits. Before the next package,
search all authored credit/comment/documentation references to A and change
them to A; retain other authors and filenames whose identity is unrelated.
Do not prepare a new package yet. RC1 remains unchanged for current testing.
Review README around user-facing FFXIAH requests: Apps avoids native macro
palettes/Ctrl shortcut conflicts; menu/slot routing avoids duplicate input;
scaling/positioning/visibility; simpler custom actions; icon and persistence fixes.
Configuration guide: native macro actions are not universally forbidden; avoid
assigning them to L2/R2 used by this wrapper. Supplied annotated gamepad and IJKL
screenshots are candidates for inclusion after configuration validation.
Alternate upstream wrappers were excluded from RC1, not adapted: next discussion
must cover explicit backend selection/start/stop and shared transport contracts.

---

## Clean RC1 package audit — October 12, 2026

Packaging preserves the Preview 34 runtime build ID. No feature additions.
Local commits: 19fa1fa removes unconditional wrapper edge logging; 05d0589
removes missing Goring_Blade.png and PSD source entries from the legacy index.
Packaging recipe and distribution README are under packaging/; development
history remains in this checkout, excluded from the download.

Complete ZIP contains 2,151 files: 42 runtime Lua modules, 2,099 verified raster
assets, the tested PS5 DirectInput wrapper, attribution/provenance, theme assets,
icon index and its two upstream regeneration helpers, and a current README.
Excluded: all tests/internal design notes/preview install notes, probes and
unadapted wrappers, Python/Linux inputs, killahk.bat, config.ini, player data,
SVG/PSD source artwork and obsolete gamepad configuration screenshot.
No folder restructuring. LICENSE, NOTICE and menu asset credits retained.

All 41 regression groups pass. All 42 runtime Lua files parse in a temporary
copy after normalization of inherited Windower string-literal method syntax;
source remains unchanged. No missing local module or legacy icon-list entries.
Every packaged byte except the distribution README matches the audited checkout.
ZIP integrity passes; per-file hashes and exclusions are recorded outside the
addon in PACKAGE-AUDIT.json. Windows/AHK execution and fresh installation of this
exact clean ZIP still require live testing. Installed player data is not modified.

---

# Public Preview 34 — Options overlay and Execute Command removal

Version: `0.4.0-a.20261012.public-preview34`. Cumulative overlay with Preview 33
rollback. Preserve all current data/settings/images. Runtime commits 053e221 and
db62c25; local, not pushed. No AHK, item extraction or personal-control changes.

1. Apply and `//lua r xivcrossbar`; //xb status reports Preview 34.
2. Open Review/Save/Edit, hold Options. Draft remains readable underneath at
   roughly 45% foreground opacity. Choose Crossbar appears above it on a nearly
   opaque black panel with a gold highlight. Up/Down switches destination; header
   changes to Basic Crossbar/All Jobs Default Crossbar in its existing colors.
3. Release Options: exact opacity returns, including previously dim choices.
   Circle/Esc cancels and restores the prior set. Draft, field buffer and menu
   page stay intact. Repeat from main menu, combo capture and combo confirmation,
   including physically held triggers and text entry. No accidental bind/save.
4. Check 960x540 and 1280x720 first, then 1920x1080/3840x2160 when convenient.
   Heading and all list rows should fit within the screen, remain anchored above
   Options, and visibly layer over the menu. Inspect whether menu glyphs interfere
   with chooser labels; native graphics layering still requires this live check.
5. Open/close repeatedly and switch focus away/back: no duplicated chooser text,
   accumulating layers, stuck menu opacity or hidden-menu mouse selection.
6. Execute Command is absent; Remove a Binding is immediately before Credits.
   New command creation uses Custom Actions. Recheck any existing legacy raw
   binding; its type/execution remains untouched. No live bindings are migrated.
7. Continue retained release checks: ordinary Enter/text commit, item icons,
   destination labels, Check, disabled-catalog explanation, fresh setup and
   bindings surviving reload/job changes. Folder cleanup/config guide remain.

41 local Lua regression groups pass. Menu suspension now exercises live-object
opacity dim/restore rather than hiding. Overlay-layer tests verify bounded object
replacement, background-before-text creation, heading dimensions and gold/opaque
colors. Existing screen-clamp, controller ownership, draft persistence and all
other checks pass. Actual legacy raw-command dispatch remains verified after
menu removal. Changed runtime Lua parses in the local Lua 5.4 harness; actual
Windower renderer behavior and user preference still await the live checks.

---

# Public Preview 33 — personal-branch Options handoff

Version: `0.4.0-a.20261012.public-preview33`. Cumulative overlay with Preview 32
rollback. Preserve all user data/settings/images. Runtime checkpoints 0f1c820,
f4dbd6d; local only, not pushed. No AHK/personal companion or global asset moves.

User live feedback: Preview 31 consumes Enter during text editing and restores
normal behavior afterward. Preview 32 still failed to expose Options switching
across menu/binding/review states. Personal branch inspection identified its early
Options ownership and set_chooser_active menu suspension. Port the behavior using
public-branch object visibility snapshots rather than the personal menu geometry.
Preview 32 had navigation priority but did not suspend the obscuring modal menu.

1. Apply and `//lua r xivcrossbar`; //xb status reports Preview 33.
2. At the main menu, Review/Save/Edit, button-combo capture and combo confirmation,
   hold Options. The menu temporarily disappears and the set chooser is visible.
   Up/Down changes the selected set. Release Options: same menu, selector page,
   draft and text buffer return. No accidental confirm/bind/save or page turn.
3. Repeat while editing a field and with L2/R2 held during binding. Circle/Esc
   cancels chooser, restoring the previous set. Setup wizard ignores this handoff.
   A chooser button's release must not become a menu confirm/binding event.
4. Try unfinished Add New Set: another Options press dismisses it; release must
   not reopen it. Choosing/confirming a new set resumes an underlying draft.
5. Review/binding destination title and bind/unbind chat say Basic Crossbar or
   All Jobs Default Crossbar, with existing blue/white title colors. Actual names
   and XML keys remain Basic/default/etc; this is display clarification only.
6. Unlinked custom-command slots without an explicit icon show none.png's blue
   field. Catalog pickers show a full-size gear; valid linked artwork or explicit
   icon wins there. No default icon value is written to XML. Existing explicit
   gear icons remain explicit until the user clears them.
7. Recheck Enter commit/ordinary Enter, focus switching and ordinary slot commands.
   Focus cancellation resumes suspended menu state without saving anything.

40 local Lua regression groups pass. New fixture exercises the actual early
controller router and menu visibility handoff in four states, safe slot releases,
draft/text persistence, precise visibility restoration and consumed held-trigger
page gestures. Catalog tests cover explicit/linked/gear precedence without XML
mutation. Existing naming, disabled-choice, Check, icons, file-safety and Enter
checks pass; changed runtime Lua parses. Windows/FFXI checks still pending.

Release focus remains: live polish verification, fresh setup, bindings surviving
reload/job change, configuration guide and distributed-folder cleanup. Do not
restructure assets or personalize the main menu ahead of the playable release.

---

# Public Preview 32 — visible destinations and custom-action polish

Version: `0.4.0-a.20261012.public-preview32`. Cumulative overlay with Preview 31
rollback. Preserve all user data/settings/images. Runtime checkpoints de85a7f,
9b8d64d, 26bb1b6. Local commits, not pushed. No AHK/personal controls or asset moves.

1. Apply and `//lua r xivcrossbar`. Status identifies Preview 32.
2. Open a named custom-action draft. While on Review/Save, hold Options and use
   Up/Down to choose another set. Draft Name/Alias/Command/icon/link remain intact.
   Header changes to the destination's display name, blue for default/shared
   layers and white for ordinary sets. Save & Bind into that destination.
3. Review/Edit plus every combo capture/confirmation view share that set label.
   Sample spell, item, warp, custom action, Change Slot Icon, Change Action Icon
   and Remove a Binding. Switch a destination mid-combo; title follows and combo
   remains intact. Most paths reuse display_button_assigner/display_button_confirmer;
   45 action categories are covered by the shared-view fixtures at six sizes.
4. Create/bind a custom action with no chosen icon: full-size opaque gear appears
   with normal visibility fading. XML/catalog icon remains absent/blank. Choosing
   an explicit icon still wins. Valid linked action artwork also retains priority.
   Compare Custom Action and Edit/Delete pickers: default gear no longer has the
   erroneous four-pixel down/right offset. Test at 960x540 and 1280x720.
5. On an empty catalog in a separate fresh test installation, navigate onto
   Custom Action/Edit/Delete. Dark translucent red selection, red text, dim icons,
   no selection lift; Confirm explains how to create an action and stays there.
   Do not delete your live catalog just to test this. Blank-name Save choices
   remain skipped; only the three empty-catalog main-menu choices are focusable.
6. Main menu order: Ranged Attack > Attack > Check > Assist. Bind Check, target an
   NPC/enemy and execute: command is input /check <t>, icon check.png. Circle Back
   and Share Exit retain existing behavior.
7. Continue Preview 31 Enter checks and normal reload/job/focus/binding tests.
   Preview 31 is still awaiting live feedback; local tests are not confirmation.

38 isolated Lua regression groups pass. Tests exercise actual renderer fallback
without field mutation, actual set-switch adapter/title refresh with persistent
draft/combo state, all shared binding categories at six resolutions, unavailable
navigation/colors/no-lift, explanatory submit and saved Check dispatch. Runtime
Lua syntax checks pass. Windows/FFXI live checks remain pending.

Release checklist: fresh setup and binding persistence; controller configuration
screenshots/guide; trim the distributed folder to runtime/assets/licenses/use
instructions. Exclude AGATHOS/DESIGN/WORKFLOW, development history/tests and old
preview instructions from the community release archive; retain them in source
history/development materials. Preserve existing addon assets/third-party notices.
Do not undertake a global asset-path migration or Trust-state feature for release.

---

# Public Preview 31 — native Enter block and set-name geometry

Version: `0.4.0-a.20261012.public-preview31`. Cumulative overlay with Preview 30
rollback. Preserve user data/settings/images. Three local commits, not pushed.

User live result: Preview 30 Enter still leaked in Options/main-menu set creation
and initial/edit custom-action fields. Main-menu set-name box appeared upper-right.
Prior regression tested Lua event ownership but missed native-block lifetime:
set_capturing_text(false)/chooser clear released keyboard_blockinput during the
confirming down event. Keep native blocking through release, then prerender clears
it. No timed delay and no ordinary keyboard bindings changed.

1. Apply and `//lua r xivcrossbar`; status identifies Preview 31.
2. Test Options > Add New Set and main-menu Create New Set: type/press Enter.
   Name commits once, with no background chat/menu action. Main-menu entry panel
   and placeholder/typed caption stay centered at 960x540 and 1280x720.
3. Repeat bare `//xb ca` name entry and Edit Name/Alias/Command fields. Test
   short/held Enter; rejected blank names still permit retry after release.
4. After editing closes, regular Enter still works in game/chat. Recheck focus
   out/back, Circle Back and Share Exit. No stranded native keyboard block.
5. Preview 29 item extraction is now live-confirmed by the user: items work.
   Item/job code and AHK unchanged from Preview 30; ordinary binds remain intact.

37 Lua regression groups pass, including native command sequence around field
closure/held Enter/release/prerender/reset. Changed Lua parses. Live FFXI behavior
still requires the above check; earlier local checks did not establish the native
input timing. Follow-up polish and public-folder cleanup remain pending.

---

# Public Preview 30 — Enter commits only the active text field

Version: `0.4.0-a.20261012.public-preview30`. Cumulative overlay with Preview 29
rollback. Preserve all current data/settings/images. User has now authorized
consuming Enter while a text field is active; the Preview 29 discussion note
below records the earlier decision to defer. Runtime checkpoint is the Enter
ownership commit immediately preceding this packaging commit; local, not pushed.

1. Apply and `//lua r xivcrossbar`; status identifies Preview 30.
2. Open `//xb ca` or edit an existing action. Type a Name/Alias/Command and press
   Enter. It commits once. Neither down nor release should open chat/confirm
   anything behind the addon. Hold Enter briefly: no repeated submissions.
3. Try a rejected/empty name: the field remains active; release then press Enter
   again to retry normally. Circle/Share/controller confirm remain unchanged.
4. Repeat for set creation through the main menu and Options set chooser.
5. Outside text entry, Enter retains its existing game/chat behavior. Check it
   after editing and after switching focus out/back. No ordinary key bindings
   are changed. Focus/unload clears pending confirmation ownership.
6. Continue Preview 29 item/job checks below; those features are unchanged.

37 local Lua regression groups pass. Tests execute the actual keyboard callback's
Enter interception with binder/chooser field closure, rejected input, held repeat,
release and ordinary gameplay edges. Focus cleanup and syntax checks pass. Live
FFXI validation remains pending; the earlier confirming key-down was already
consumed, while release ownership was lost when editing closed.

---

# Public Preview 29 — expanded item records and one job-change notice

Version: `0.4.0-a.20261012.public-preview29`. Cumulative base overlay; rollback
restores Preview 28. Preserve all user data/settings/images. Runtime checkpoints:
034e69d (validated record layouts), fa862ec (quiet creation/job-change summary).
Local commits, not pushed. No AHK/controller mapping or keyboard-entry changes.

1. Apply the overlay and run `//lua r xivcrossbar`; status identifies Preview 29.
   `//xb reload` reloads bindings only, so it does not load updated Lua code.
2. Open Use Item on Franklet. Check identifiable items such as Instant Warp,
   food and crystals against their in-game icons. Bind one and confirm menu/slot
   show the same icon. Existing custom icon overrides remain intentional.
   The resolver uses a fresh `images/extracted_items_v5` cache without deleting
   older caches. No client restart or manual cache deletion is needed.
3. If an item remains wrong or falls back, send its displayed name/ID, a labeled
   screenshot when convenient and any new v5 .record.dat/.record.txt pairs.
   Diagnostics are now at most 5 KB per failed record; game DATs are read-only.
4. Change main/subjob when convenient. Crossbars load immediately, while chat
   waits 0.3 seconds after the latest event to consolidate related messages.
   Expect one XIVCrossbar line, for example:
   `[XIVCrossbar] Crossbar sets ready for DRK/RDM (created DRK-DEFAULT.xml, DRK-RDM.xml, DRK-WAR.xml).`
   Existing combinations get one line without the created list. XML backup
   notices disappear, but backup files are still made before original writes.
   Another addon's `JobChange: Changing...` lines are outside this change.
5. Recheck one binding after job change/reload. Current binds are retained;
   no recovery from older backups is requested or performed.
6. Deferred discussion: Enter committing a new/edited custom-action field leaks
   into gameplay. User requests no change yet and values keyboard freedom.
   Consider consuming only the active field's confirming press/release while
   leaving keyboard behavior outside editing intact; do not implement yet.

Evidence reviewed: upload/extracted_items_v4.zip, Lionstag_2026.10.12.log and
Franklet_2026.10.12(1).log, as supplied locally. Lionstag lines 132-138 announce
DRK-WAR/DRK-DEFAULT/DRK-RDM and backups. Franklet lines 229-230 announce WAR-WHM
and WAR-DEFAULT, then line 234 confirms Preview 28 was loaded. The newer item
messages have no secondary nil-offset error, confirming the raising guards.

Actual captured offsets establish 0x1400 spacing: offset 1,582,080 contains item
309 (515 * 3072 = 309 * 5120); usable offset 261,120 contains 4147 rather than
4181 (85 * 3072 = 51 * 5120). Other complete starts independently agree, while
several old offsets land in pixel data or zeros. No rotation/bitmap-format guess
was needed. Preserve the older Preview 28 notes as the earlier investigation.

Validation: 36 isolated Lua regression groups pass; changed runtime files parse
in the local Lua 5.4 harness. New coverage checks nonzero record offsets for both
sizes, index-zero ambiguity, stride reuse, pixel bytes, short-record rejection,
quiet real-style file creation and merged successful/failed job notifications.
Five complete neighboring records recovered from the user's captures were also
fed through the actual extractor locally. Independent Python decoding agrees on
all 5,120 output pixels. Those raw game records/generated images are not shipped.
This validates recovered neighbors, not the requested items at their correct
new offsets: live rendering of those requested items is still pending.

---

# Public Preview 28 — Windower guard compatibility and item diagnostics

Version: `0.4.0-a.20261012.public-preview28`. Cumulative base overlay; rollback
restores Preview 27 runtime. Preserve all bindings/settings/images. Runtime
commits d5b0191 and 12223e0; local only, not pushed. No AHK/personal controls or
menu layout changes. Item format/offset selection is not changed speculatively.

Live evidence: upload/Franklet_2026.10.12.log, 137 lines, reports Preview 26;
the item code is also unchanged in Preview 27. Seven failed IDs: 4413, 5885,
924, 4400, 8711, 922 and 8973. Each prints ID mismatch, absent bitmap and then
arithmetic on nil 'at'. Official Windower logger.lua source confirms its global
error() only logs and stores Lua's raising function in _raw.error. The public
guards had assumed standard Lua error semantics; tests now reproduce the actual
logger contract. Capture the raising function in player/storage/extractor.

User confirms fallbacks work; some images changed but none are correct. User
likes the quieter load status and explicitly declines binding-backup recovery;
leave current bindings as-is. No binding restoration is part of this build.

1. Apply overlay, then //lua r xivcrossbar; //xb status reports Preview 28.
   Stop/unload all clients first if following the full installation procedure.
2. Open Use Item on Franklet once. Validation failures should now print one
   useful message per failed ID, including requested/found IDs, source DAT and
   byte offset. No secondary nil-'at' error; menus and fallback icons remain usable.
3. Zip/upload images/extracted_items_v4 after this check, especially the numeric
   .record.dat and .record.txt pairs. Each raw record is only about 3 KB.
   Include one screenshot labeling a wrong displayed item if convenient.
   These actual bytes are needed to distinguish wrong record addressing from
   format/bitmap differences before changing the decoder. No client closure or
   full game-DAT upload is needed for these diagnostic captures.
4. Existing successful icons in older caches are not reused by the new resolver;
   old files remain untouched. Explicit custom iconpack overrides remain honored.
5. Recheck one ordinary binding, reload and the quiet loaded-sets status. The new
   raising guards also protect failed XML/save paths; destructive scenarios stay
   in isolated regression fixtures, not live character files.

34 local Lua regression groups pass, including Windower logger semantics, no
write after failed XML guards, and rejected-DAT evidence capture. Changed runtime
Lua parses. Real DAT decoding and Windows/Windower rendering still need the
record captures/live check. The provided log supports the guard-fallthrough
diagnosis, not a claim that all item-format problems are already solved.

---

# Public Preview 27 — missing defaults and job-change selection

Version: `0.4.0-a.20261012.public-preview27`. Cumulative upstream-base overlay
with Preview 26 runtime rollback. Preserve data, config.ini and original images.
Runtime checkpoints: 07e16b9 (missing defaults), 39de9ee (post-load selection);
local commits, not pushed. No AHK, item-extractor or layout changes.

1. Stop/unload, apply the xivcrossbar overlay and load/reload Lua. Status reports
   Preview 27. Verify current sets/bindings before further edits.
2. When convenient, switch main/subjob in-game. A valid current/shared set stays
   selected; otherwise the chooser picks a set that exists in the new job data.
   Switch back and confirm the previous job's saved bindings remain present.
   No nil-set error, empty display from a stale job-only name, or file deletion.
3. Create/save one disposable binding, reload, and recheck the current named set
   and default slots. Missing-layer/import cases are covered in isolated fixtures;
   do not delete live XML files merely to create a test scenario.
4. Repeat Alt+Tab with menus open/closed, ordinary Apps slot execution and native
   keyboard F7/F8. Keep the item-icon comparison from Preview 24 on the live list.
5. If slots remain missing, send the character XML folder including backups,
   settings.xml, current logs and //xb status before more binding changes.

32 Lua regression groups pass locally. New fixtures run the actual loader and
serializer to verify missing default files preserve already imported labels/
slots and repeated initialization retains extra bars. They also execute the
actual reload/job-change callback and default-only chooser selection. Changed
Lua files parse in the Lua 5.4 harness; Windows/Windower live validation remains
pending. This does not establish the cause of the user's earlier missing binds.

README now uses //xb remap for setup, explains one-screen custom actions in its
command table, names Hotbar.Number correctly, and distinguishes the tested
Windows DirectInput path from retained upstream wrappers. Main-menu order wording
matches Create Custom Action first. User-collected setup screenshots still need
to be supplied before incorporation into the final release guide.

---

# Public Preview 26 — preserve stored sets and inactive bars

Version: `0.4.0-a.20261011.public-preview26`. Cumulative base overlay with a
Preview 25 runtime rollback. Core fix a91a18f; local commits, not pushed.

Continuation audit found independent loader risks: display names were used as
set keys/scopes; empty sets were never constructed without a slot; omitted name
fields fell back to a numeric index; stored bars beyond the enabled count were
dropped before later saves. Regression fixtures reproduced these issues. The
loader now uses the XML tag for identity, retains the label, creates empty sets
and preserves inactive bars. Hidden labels no longer defeat legacy alias-only
commands. No display/layout, controller, icon-extractor or personal-control change.

1. Back up your current data, including .bak files. Stop/unload, apply the
   xivcrossbar overlay, and load/reload Lua. Status reports Preview 26.
2. Check the same character/job and active set before changing bindings. All
   existing named sets and slots should remain present. Repeat the Preview 25
   Alt+Tab checks below, with the addon menu open and closed.
3. If you already have extra bars disabled, their stored slots must survive a
   reload and a disposable binding save. Their UI/input stays disabled. Do not
   alter valuable data just to create this scenario; the fixture covers it.
4. If bindings still appear missing, send the character XML folder, .bak files,
   settings.xml, logs and //xb status output before further binding changes.
   Actual deletion/recovery remains unconfirmed without those files.

30 regression groups pass in the local Lua 5.4 harness; changed runtime syntax
checks pass. Added checks cover set-key/display-name separation, all-job scope,
empty sets, missing name, disabled bars and hidden-label fallback. Live Windows
behavior and actual extracted item images remain pending. This patch cannot
recover data absent from both current XMLs and backups.

---

# Public Preview 25 — focus-reset hotfix

Version: `0.4.0-a.20261011.public-preview25`. Cumulative overlay including the
Preview 24 safeguards; rollback restores Preview 23 (before the new focus
cleanup). Preserve data, config.ini and images. Runtime fix: 339663a; local only.
No AHK or item-extractor changes in this hotfix.

Live Preview 24 report: Alt+Tab causes action_binder.lua:455, attempt to call
consume_page_gesture (nil), with menus open or closed. The test incorrectly
mocked that nonexistent method. Corrected reset directly clears page_gesture
and its selector highlight. The revised regression loads the actual binder
reset methods and selector page-highlight method and verifies focus loss/gain
with open, closed and uninitialized menus. All 29 groups pass locally.

1. Back up current data and .bak files. Stop/unload, apply the overlay, then
   `//lua l xivcrossbar` (or `//lua r xivcrossbar` after replacing the files).
   `//xb reload` reloads bindings only and does not install new Lua code.
2. `//xb status` reports Preview 25 and the expected active set. Check your
   existing bindings before making new ones.
3. Alt+Tab out/in with the addon menu closed, then open. No 455 error. Test a
   held gameplay D-pad key, trigger, page gesture and inline text draft; focus
   cancels controller ownership without firing, paging or discarding the draft.
4. If bindings remain missing, retain/send data/hotbar/<server>/<character>
   including XML .bak files, settings.xml and current logs/status. Code review
   finds no binding write/delete in the focus handler; the interrupted display
   alone cannot establish disk deletion. Do not overwrite backups through new
   binding tests until the evidence is captured.
5. Item icons should depict the correct corresponding in-game items. Generic
   icons are fallbacks, not confirmed extracted images. Continue the Preview 24
   icon checks below; extraction's real DAT/image correctness remains unverified.

No new screenshots or character files were supplied with this error report.
The binding-loss report remains an open investigation, not a confirmed deletion
or a claimed recovery. The personal branch is unchanged.

---

# Public Preview 24 — load/save safeguards and item-icon review

Version: `0.4.0-a.20261011.public-preview24`. Cumulative overlay for the
qEagleStrikerp base installation. Rollback restores Preview 23 runtime. Preserve
config.ini, data, controller preferences and the original images folder. No
personal companion/controls, character bindings or compact toggle are included.
AHK scripts are unchanged. Five focused runtime commits: 3d389ef, 14c79ec,
09665eb, 34919be, a1bbf3f; all local, not pushed.

## Install and check in order

1. Back up the installed addon folder. `//xb controller stop`, unload on all
   clients, merge the package's xivcrossbar folder, then load. `//xb status`
   reports Preview 24. Existing sets/bindings should remain available.
2. Open Use Item and Trade Item. Compare a few recognizable icons with their
   in-game icons (Instant Warp, Honey or another item you have). Bind an item in
   a disposable slot and compare the menu/slot image. An older extracted binding
   should resolve through the fresh cache without rebinding. Explicit iconpack
   overrides still take precedence. Missing DAT images leave usable fallback
   icons and one chat diagnostic per failed ID per load.
3. If icons remain wrong, send the corresponding BMP from
   images/extracted_items_v3 (filenames are numeric item IDs), a game screenshot,
   chat/console diagnostics and the installed version. Do not delete old caches
   or close clients solely to refresh these images; Lua reload retries failures.
4. Create a disposable custom action, test an explicit command and a blank
   command with an existing Windower alias. Save/Bind, return with Circle, and
   reload. Existing actions and independent slot bindings remain intact.
5. Make a disposable binding change, inspect the affected `.xml.bak` files, and
   reload: every existing XML layer has its prior-save backup. Malformed XML,
   failed serialization and write failures are tested with isolated fixtures;
   do not corrupt live character files for this check.
6. Hold a gameplay D-pad direction, change focus to the other client, release,
   return and press once. Repeat with L2/L2+direction and R2/Circle: no stuck
   movement/trigger field, extra action or target change. Repeat while editing a
   custom field or set name: drafts survive focus changes. An ordinary held
   Options list closes on focus change.
7. Recheck physical F7/F8, ordinary Ctrl shortcuts, addon-only navigation with a
   native menu underneath, Share exit, Circle Back, and reload persistence.
   Inspect compact/full layout, scaling, dragging and fades at 960x540 and one
   larger resolution; no layout or input mapping change is intended here.

## Verification and limits

29 regression groups pass through the local Lua 5.4 harness, including actual
loader, serializer, binder, extraction and focus paths. Changed runtime files
parse; this is not a Windows AHK or Windower Lua 5.1 execution. Item tests use
synthetic DAT records with relocated bitmaps and known pixel colors, including
wrong IDs, absent headers, truncated data, failed writes and fallback routes.
Actual FFXI icon appearance and the multi-client focus behavior require live
confirmation. The existing corrupt-cursor bars and tiny first-frame caption
centering hop remain open/deferred; chooser fade-frame misalignment remains
deferred at the user's request.

Read-only personal-branch comparison led to targeted safeguard adaptations; its
shared-catalog migration/conflict checks, loaded-slot edit propagation, menu
skin/sounds and companion have not been imported. Catalogs remain per-character.
Compact on/off command remains deferred. Screenshot-guided gamepad installation
material is being collected by the user; no new screenshots were supplied in
this turn. README's old XInput/default and multi-screen review descriptions were
corrected. Public release still needs the live checks and final setup guide.

The FFXIAH bumper request was verified on page 4: Eyeshark requested bidirectional
bumper targeting while retaining D-pad navigation; HunterHog posted an XInput
Shift+Tab/Tab solution, and Moghedian posted a DirectInput example. No bumper
changes in Preview 24.

---

# Public Preview 23 — display names in binding feedback

Version: `0.4.0-a.20261011.public-preview23`. Cumulative overlay; rollback
restores Preview 22 runtime. Preserve config.ini/data; no AHK changes.
Implementation e076dd3; local only, no push.

1. Stop/unload, apply overlay and load. Bind a safe action in Basic: chat suffix
   should say Basic, matching the chooser. Clear the disposable binding and check
   the same display name. Repeat in a named test set if convenient.
2. Reload and verify the binding's stored set/key remains unchanged. The chat
   display is the only runtime change; all Preview 22 checks remain relevant.

Offline: feedback and actual custom-action binding regression checks pass; changed
Lua syntax/whitespace checks pass. Display-name lookup covers Basic, All Jobs
Default, a custom name and missing metadata. Live feedback confirmation pending.

Branch comparison performed against personal experiment/l1-companion-batch19 at
a7c59f9 (0.4.0-a.20261010.19-companion2), without modifying that repository. Both
have Apps transport/silent interception, readable XML slots, inline custom editing
and fallback/linked metadata, scale/fade work and trigger page navigation. Their
ui_fade.lua files are identical. Public has newer golden cursor/review, measured
caption retries, coherent movement, Options anchor/lifecycle, endpoint text
visibility, icon workflow repairs and hotbar read/write safeguards. Personal
retains the removable L1 addon, PS/touchpad/L3/R3/shoulder extras, shared
data/CustomActions.xml migration/write-conflict checks, FFXI panel skin/sounds,
lock/unlock drag tooling and extra menu/alias/grace controls. Public catalogs
remain character-specific. Selected integration is recommended; no port/merge
performed as part of this feedback-only change.

---

# Public Preview 22 — chooser lifecycle and temporary crossbar reveal

Version: `0.4.0-a.20261011.public-preview22`. Cumulative overlay; rollback
restores Preview 21 runtime. Preserve config.ini/data; no AHK/controller changes.
Implementation: 90cb7dd. Two local commits including documentation/package; no push.

Live Preview 21: the user confirms endpoint text visibility removes the fade
flicker and provides responsive trigger-release feedback. New report: blank or
abandoned New Set entry can leave the chooser stuck; ui.lua:1069 indexes nil
while lingering on that entry. Source confirms the non-existent Add New Set row
was used as player.active_environment; MP/TP checks indexed its missing hotbar.

1. Stop/unload, apply overlay and load. Status: Preview 22, Ready=true.
2. In auto visibility with no trigger held, hold Options: crossbar and set list
   appear, and Change crossbar sets caption disappears. Release Options on a
   real set: chooser/tooltip close and visibility returns to auto. Repeat from
   hidden mode; settings remain unchanged. Restore your preferred mode afterward.
3. Select Add New Set while holding Options, then release. Name entry stays open
   and the last real crossbar remains active/visible. Wait through MP/TP updates;
   no 1069 error. Blank entry then D-pad to a real set closes it and clears capture.
4. Repeat after typing a partial name: Escape closes without creating a set;
   Options press also closes, and its release must not reopen name entry. Another
   Options hold should work normally. Navigating while Options remains held keeps
   ordinary choosing open until release.
5. Enter a valid disposable set name and confirm with keyboard Enter. Set creation
   still works and closes entry. Existing sets and bindings are preserved.
6. Open a default set: tooltip follows its anchored list and disappears when the
   list closes. Share menu open/close must not resurrect a closed tooltip.
7. Check the Options image stays present while its caption is suppressed. The
   caption returns when chooser closes only if ordinary crossbar hints are shown.
8. Recheck ordinary bindings, new fade text behavior, custom actions and ijkl:
   `//xb dpad ijkl`; return with `//xb dpad arrows`.

Offline: 24 regression groups pass, including actual Options edge handling,
placeholder selection without changing live hotbar, draft cancellation, absent
/sparse vitals tables, caption visibility and temporary hidden-mode reveal.
Changed runtime syntax/whitespace checks pass. Live lifecycle behavior is pending.

Tooltip opinion: useful fallback information, but the current long block and
advice against playing from default sets need a future copy review. No tooltip
wording changes here. Other controller support remains deferred. Cursor bars
still need a close screenshot; tiny first-frame caption centering hop remains.

---

# Public Preview 21 — text endpoints and Options-anchored chooser

Version: `0.4.0-a.20261011.public-preview21`. Cumulative overlay; rollback
restores Preview 20 runtime files. Preserve config.ini and data; no AHK changes.

Preview 20 live: captions briefly begin off-center then immediately center; whole
crossbar moves together; text still flickers during fades; cursor is stronger but
has reported corrupt-looking bars; name label is white; Execute Command icons
work. The first-frame text-position hop remains, pending further refinement.

Changes: 9d50212 (text endpoints), f4ec134 (Options anchor/tooltip), df07696
(two-line help). Text visibility now switches at fade endpoints, avoiding partly
faded glyphs. It is hidden at close start even while opacity is still 1; recast
show requests cannot reveal it during the transition. Images fade continuously.

1. Stop/unload, apply overlay, load. Status: Preview 21, Ready=true.
2. Test initial fade, then trigger-only fade in/out. All crossbar text should
   disappear when close starts and return only when full fade-in completes.
   Reverse a fade mid-way; text stays hidden until the bar reaches full opacity.
3. Disable fades briefly: ordinary immediate text visibility still works. Reenable.
4. Open set chooser. Its lower-left corner aligns to the Options image's lower-left
   corner, unless constrained by screen edges/list height. It grows upward in
   15-pixel rows. On a default set, the 400x218 tooltip aligns along the chooser's
   bottom, to its right when it fits or left otherwise, clamped to the screen.
5. Drag or use Move Crossbar with D-pad. Reopen chooser and change scale: list and
   tooltip stay anchored. Check 960x540 and a larger resolution.
6. New Custom Action: first help line unchanged. Second line is exactly:
   Or use: //xb ca name <name of action> | //xb ca alias <label for action> | //xb ca command <console command to fire>
   It stays on one centered line, fitting the available panel width as needed.
7. Check normal bindings, custom review navigation, cursor animation and icon
   workflows remain intact. A close screenshot of cursor bars is still needed
   to distinguish baked texture artifacts from rendering artifacts. No further
   cursor artwork changes in this package.

Offline: all 23 regression groups pass; changed runtime Lua syntax and whitespace
checks pass. Coverage includes fade reversal/endpoints and repeated show requests,
Options screen anchor, tooltip side selection/clamping and retained movement.
Four small local commits including documentation/delivery; no push/public posting.

---

# Public Preview 20 — layout, movement, fades and icon workflows

Version: `0.4.0-a.20261011.public-preview20`. Cumulative overlay for the base
qEagleStrikerp installation; rollback restores Preview 19 runtime files. Preserve
config.ini and data. No AHK changes; no bulk images/sounds.

Implementation commits: 08f931f (stable redraws), 8cd08bd (movement/tooltip),
04d8f9c (cursor opacity), 556c9db (deferred captions/review), a6b677b (icon flow).
All local; no GitHub push or public posting.

Live evidence: Lionstag 960x540; image(7).png confirmation starts near screen center;
image(8).png initial prompt similarly displaced; image(9).png Share/Options hints
separated from the crossbar; image(10).png review help displaced, cursor/highlight
absent; image(20261011-220842).png shows native cursor visibility. Width-unavailable
at initial placement remains an inference from these images, not a captured native
measurement. Rechecking on render directly handles that condition. Offline Preview
19 tests assumed immediate measurements and did not catch the live failure.

1. Stop/unload, apply the overlay and load. Status: Preview 20, Ready=true.
2. At 960x540, Use Item: choose an item, check centered combo prompt and captured
   confirmation. Repeat with Trade Item, a custom action, Superwarp and Remove
   a Binding. Check both long/short captions at a larger resolution too.
3. Open New Custom Action from the menu: Custom Action Name label is white while
   other unnamed fields remain pink. Enter a name; review buttons have the golden
   background and animated cursor. Three help lines stay centered within the panel.
4. Check cursor visibility against the native cursor reference; animation timing
   and selected-text yellow are unchanged. Inline typing hides the selector as
   before; confirm/cancel and Save & Bind -> Circle preserve the committed draft.
5. Drag the crossbar: slots, text, Share/Options images/captions stay together.
   Use Move Crossbar with the D-pad too. Open the set chooser on a default set
   with its explanatory tooltip, drag the bar and check list/background/highlight/
   tooltip all follow it. Repeat after closing/reopening and reloading.
6. Check initial fade and trigger-only fade in/out, including compact mode. Text
   should fade steadily. Redraw churn was fixed; whether this resolves the live
   flicker still needs confirmation. Report which labels flicker if it persists.
7. Change Slot Icon: choose icon first, capture a bound combo and confirm. Its
   command/alias remain unchanged. Circle from combo returns to icons. Selecting
   an empty/fallback-only slot warns and permits another selection, without saving.
8. Change Action Icon: select a binding then icon. Check a matching slot without
   its own icon on another set; explicit slot icons stay unchanged.
9. Execute Command is after Remove a Binding, immediately before Credits. Icon
   images should now appear. Existing name-based commands remain compatible.
10. Ordinary actions, trigger priority, bare menu controls, F7/F8 and reload
    persistence remain working. Keep native hat-switch menu input disabled.

Offline: 22 regression groups pass, including delayed native-width simulation,
all shared binding captions at six resolutions, unchanged glyph setter suppression,
whole-bar/tooltip movement, new/saved review paths, icon-first slot confirmation,
legacy Execute Command image paths and fresh selector setup order. Changed runtime
Lua syntax and whitespace checks pass. Live graphics confirmation is pending.

The personal L1 companion remains outside this public preview. Broken extracted
item icons are a separate outstanding issue; this package repairs Execute Command
icon paths, not the item icon extractor.

---

# Public Preview 19 — binding caption centering

Version: `0.4.0-a.20261011.public-preview19`. Cumulative overlay; rollback
restores Preview 18 runtime. Preserve config.ini/data; no AHK changes.

Preview 18 live: selecting an icon for a new custom action returns directly to
review (first test passed). User reports Use Item binding text offset right at
960x540. Review found the confirmation caption still used character-count width;
the initial combo prompt already used measured width. Both now use that method.

1. Stop/unload, apply overlay and load. Status should report Preview 19, Ready=true.
2. Use Item: choose an item, check centered initial prompt, capture a combo and
   check centered confirmation. Circle backs out without changing bindings.
3. Check Trade Item, Superwarp, Custom Action, Remove a Binding, Change Icon and
   Set Icon Across Jobs. Both prompts should share the panel's horizontal center.
4. Controller hints stay in their corners. Ordinary binding/execution behavior
   is unchanged; confirm one safe echo/custom action and verify it executes once.

Offline: actual shared prompt/confirmation methods pass for every action type at
960x540, 1280x720, 1600x900, 1920x1080, 2560x1440 and 3840x2160 using nonuniform
glyph widths. Existing review-layout and custom-review checks also pass; changed
Lua syntax and whitespace checks pass. Live centering remains pending.

Discussion backlog, not included here: white Custom Action Name label before
naming; much more opaque cursor; rename Change Slot Icon/Change Action Icon;
icon-first slot-icon workflow; move Execute Command after Remove a Binding before
Credits; investigate blank Execute Command icons. Selected text stays as in
Preview 18 per the user's latest preference. No push/public posting.

---

# Public Preview 18 — custom review and menu polish

Version: `0.4.0-a.20261011.public-preview18`. Cumulative overlay; rollback
restores Preview 17 runtime files. No AHK changes; preserve config.ini and data.

Live Preview 17 on Lionstag: Ready=true, Setup=false (state nil); face buttons
work. User reports the low-resolution menu, cursor, selection colors and page
turning look good. Requested brighter yellow, increased cursor opacity and review
navigation refinements are included here. The existing icon-selection code already
intended to return to review; the exact reported route to binding was not reproduced.
An explicit return destination now protects the custom picker from category changes.

1. Stop/unload, copy the overlay and load again. Verify Preview 18 and Ready=true.
2. Check the brighter selected text and cursor at 960x540; Create Custom Action
   comes first. Empty-catalog actions stay present but disabled.
3. Create a named draft from the menu. Choose Icon: Clear Icon is first, folders
   still navigate normally; choosing an icon returns directly to review. Reopen
   the picker and clear it, then cancel out of a folder/root and verify the draft.
4. Link Action: Skip (no linked metadata) comes first. Select a real action and
   return to review; reopen and skip to remove metadata. Clear buttons are absent
   from review, which now has seven choices. Check both a new and saved action.
5. Check centered two-line help and button-combo captions for Change Icon and
   Set Icon Across Jobs. Confirm hints still match saved controller assignments.
6. Save & Bind, then Circle: draft remains. Exit: draft is discarded. Canceling
   inline typing discards only unconfirmed text; already committed fields remain.
7. Bind a command linked to a spell/ability and verify command execution, icon,
   MP/TP cost and recast presentation. Recheck ordinary bindings and F7/F8.

Offline: all 17 regression groups and changed-file syntax pass; coverage includes
icon choice/clear/back independent of category, draft return and text bounds at
six resolutions. Live refinements remain pending. Two implementation commits plus
one delivery/documentation commit, local only.

---

# Public Preview 17 — no-subjob initialization

Version: `0.4.0-a.20261011.public-preview17`. Cumulative base overlay; rollback
restores Preview 16 runtime files. Fix commit: `8bdb398`. No AHK changes.
Keep existing data and config.ini; the package excludes those and bulk images.

Lionstag finished the face-button wizard in Preview 16, then reported player.lua
165 concatenating nil sub_job, followed by skillchains.lua 345 indexing a missing
buff table. The new load message aborted initialize before ready=true and before
skillchains.load. Unlike the status message, existing storage already supported
NOSUB. This repairs that regression and guards early buff-removal packets.

1. Stop/unload using `//xb controller stop` then `//lua u xivcrossbar`, copy the
   overlay and `//lua l xivcrossbar`. Preserve the saved setup assignments.
2. Run `//xb status`: Preview 17, Ready=true, Setup=false. Check the console for
   errors; report exact lines if initialization still fails.
3. Bare Triangle opens the native menu, Square selects the active window, Cross
   confirms and Circle cancels. D-pad moves only addon selection with its menu
   open; outside it, D-pad follows arrows/ijkl. Native hat switches stay disabled.
4. Test trigger-held slot actions, ordinary keyboard F7/F8 and reload persistence.
5. When controls pass, turn `//xb inputtrace off`. No need to rerun setup unless
   assignments themselves differ from the intended buttons.

Offline: 17 regression groups pass; root/player/storage syntax passes. The actual
skillchain packet handler is tested separately because untouched upstream syntax
elsewhere in that module is Windower-specific. Live readiness/input confirmation
is pending. No GitHub push or public posting.

---

# Public Preview 16 — setup readiness gate

Version: `0.4.0-a.20261011.public-preview16`. Cumulative overlay; rollback
restores Preview 15. Only xivcrossbar.lua changed at runtime. Stop wrapper,
unload, copy xivcrossbar and load again. Existing settings/bindings are retained.

Lionstag_2026.10.11.log raw lines 739-750 and 757-762 show Apps DIK221, R2
DIK88 and Cross DIK63 arriving in setup state 3. R2/Cross have capture=true,
ready=false, blocked=false. The router's unconditional readiness gate therefore
discarded both before the wizard. This update permits setup input while not
ready; outside setup the original readiness protection remains.

1. At first Confirm assignment, hold R2 and tap Cross. The prompt should now
   advance to Cancel. Assign Circle, Triangle (Main Menu), Square (Active Window).
2. On Save Changes, confirm with R2+Cross, then complete the final confirmation.
   Let the addon reload and run `//xb status`: Ready should be true, Setup false.
   If Ready remains false, send status and the console error output so the
   initialization failure can be investigated separately.
3. Recheck bare menu buttons, ordinary bindings and F7/F8 keyboard behavior.
4. Turn `//xb inputtrace off` once the result has been recorded.

Offline: all 16 regression groups pass, including setup input while ready=false
and refusing gameplay input in that same state; changed-file syntax passes.
Observed cause of dropped setup events is established; why full initialization
remained incomplete still requires evidence. Live completion remains unverified.
Local fix commit `9bdb0bb`; packaging/docs follow. No push or public post.

# Public Preview 15 — raw setup input diagnostics

Version: `0.4.0-a.20261011.public-preview15`. Cumulative overlay; rollback
restores Preview 14. Over Preview 14, only xivcrossbar.lua changed at runtime.
Stop/unload before copying, then load again; retain settings and character data.

Evidence: AHK log records Apps and R2/F12 + Cross/F5 edges with clean releases.
A temporary Windower #f5 echo executed from controller. User restored silent
#f5 binding. Existing inputtrace was silent; it logged after capture/readiness
checks, so absence did not identify which check failed.

1. During button assignment, run `//xb status` and `//xb inputtrace on`.
   Report Ready/Setup/Capture status and the trace enabling message.
2. Close chat/console, release all buttons, focus FFXI, hold R2 and tap Cross;
   release. Send all RAW and BLOCKED lines from this attempt. Raw trace includes
   physical typing too while setup is open, so missing controller lines can be
   compared with keyboard lines.
3. Run `//xb inputtrace off` afterwards. No binding replacement needed.

Offline controller/setup regressions and changed-file syntax pass. Tests verify
raw messages precede capture=false, ready=false and blocked=true filtering.
No AHK or controller-routing behavior changes. Cause remains unconfirmed.
Local diagnostic commit `7a26e74`; packaging/docs follow. No push or public post.

# Public Preview 14 — setup hover feedback

Version: `0.4.0-a.20261011.public-preview14`. Cumulative overlay; rollback
restores Preview 13. Stop wrapper, unload, copy xivcrossbar and reload. Bulk
images/sounds, settings and character data are excluded; keep existing files.

1. Welcome: hover the click prompt. Text lifts 2 px up/left with a faint white
   alpha glow. Leave the text: position restores and glow disappears. Clicking
   anywhere inside the welcome background panel still advances to controller
   choices and starts the wrapper.
2. Controller choices: hover each image; image and name lift 2 px up/left.
   Move away: restore. Hitboxes remain fixed, including at image boundaries.
3. Check normal keyboard typing during setup still works. Controller signaling
   is unchanged: continue Preview 13's inputtrace/log investigation below.

Offline setup regression checks cover repeat hover without accumulating shifts,
restoration, fixed click regions, prompt-only glow and hiding during navigation.
Changed-file syntax and whitespace pass. Live appearance still needs review.
Local hover commit `009b273`; package/docs checkpoint follows. No push or post.

# Public Preview 13 — setup keyboard correction

Version: `0.4.0-a.20261011.public-preview13`. Cumulative overlay; rollback
restores Preview 12. Stop wrapper, unload, copy xivcrossbar and load again.
No character data, settings, bulk images or sounds are shipped.

Preview 12 layout passed live on Lionstag. Button assignment still failed;
inputtrace reported nothing. Physical typing failed during setup (Space was
reported to pass). The early setup dispatcher added in Preview 12 consumed
unrelated physical keys; this update passes them through.

1. With setup open, type `//xb inputtrace on` normally, then close the chat input.
   Ordinary typing/console Insert should work; controller setup still owns its
   face buttons and triggers.
2. Release all controller buttons, return focus to FFXI, then hold R2 and tap
   Cross. Record trace output or its absence. The missed confirmation cause
   remains unknown; do not treat this update as a confirmed controller fix.
3. Inspect `addons/xivcrossbar/data/input-transport.log` immediately after that
   attempt. Send the last startup block and subsequent lines. This establishes
   whether the wrapper emitted Apps capture, R2/F12 and Cross/F5 edges.
4. Turn `//xb inputtrace off` after the check. Existing layout/ordinary binding
   checks remain in the previous preview sections below.

Offline: setup keyboard pass-through and controller transport tests pass;
changed-file syntax and whitespace pass. No AHK changes in this update.
Local commit `e1d7630` corrects keyboard ownership; packaging/docs follow.
No push or public post.

# Public Preview 12 — first-run controller setup

Version: `0.4.0-a.20261011.public-preview12`. Cumulative overlay for the base
qEagleStrikerp installation or any previous public preview. Rollback restores
Preview 11. Stop the wrapper, unload, copy xivcrossbar including assets/menu,
and reload. Existing settings, images, sounds and character bindings are retained.

Reported on Lionstag at 960x540: setup did not accept R2+Cross; controller layout
heading overlapped images and the background looked incorrectly scaled. Code
inspection found setup already independent of crossbar scaling, but old insets
made the inner background height negative. ~~Ordinary trigger activation returned before forwarding R2 to the setup wizard.~~
Correction: that explanation was a misread; the original code did forward R2.
Cioara successfully completed fresh setup. Lionstag still cannot confirm on
Preview 12, and inputtrace showed no events with the wrapper running.

1. First-run setup (or `//xb remap` with existing configuration): welcome text
   and controller choices fit inside a centered panel. Select PlayStation by
   mouse; hitboxes should coincide with images. Heading/subtitle stay separate.
2. Hold R2 and press/release Cross: advance from Confirm to Cancel. Then assign
   Circle for Cancel, Triangle for Main Menu, Square for Active Window. Each
   press advances once; a bare face press without a trigger does not assign.
3. On Save Changes, use R2+Cross to save. Complete the last confirmation and
   verify reload, normal menu navigation, trigger bindings and absence of leaks.
4. After setup, `//xb scale 0.6` still affects the crossbar independently. Reopen
   remap only if desired: its fixed-size layout remains readable.
5. Resume Preview 11 XML/set persistence and Preview 10 UI checks below.

Offline: 16 regression groups and changed-file syntax pass. New tests exercise
actual setup input dispatch with actual wizard methods, positive panel dimensions,
heading/image separation and mouse hitboxes at 960x540, 1280x720, 1920x1080 and
3840x2160. Windows/FFXI first-run completion still requires live verification.
Local commits: `3cc952e` setup routing; `e84937a` panel layout and regression.
No push or public post.

# Public Preview 11 — XML failure protection and chat feedback

Version: `0.4.0-a.20261011.public-preview11`.
Cumulative overlay: includes Preview 10 UI changes; rollback restores Preview 10.
Stop the wrapper and unload before copying the ZIP's xivcrossbar folder. Keep
existing images, sounds, settings and character data; include assets/menu.

Reported Preview 9 results: test 1 passed; test 2 passed with requested picker
refinements; tests 3 and 4 passed. R2+Circle binding feedback showed a strange
glyph before Basic. Creating a new set failed at player.lua:204 (`contents` nil).
Controller disappeared from game utilities; exact surface/cause not yet known.

1. Before retrying, preserve copies of the current hotbar XML files. Send the
   exact entered set name and affected XML/log to identify the parse failure.
   This update reports the file and XML parser error and refuses hotbar writes
   after failed loading. It does not repair an already damaged file.
2. Bind an echo to R2+Circle: one echo, unchanged targeting, readable chat ending
   `R2 + Circle - Basic.` (or the selected set's name).
3. Create a uniquely named set such as `Preview Eleven` through the menu;
   confirm chat feedback, bind an echo, then reload and verify persistence.
   A file-specific XML error means stop this test and retain the XML for review.
4. Invalid names such as `Slash/Name` or `Question?` should be rejected while
   existing sets and bindings remain available. Renaming has the same validation.
5. Continue Preview 10's name-first entry, cursor, selection lift and trigger
   paging checks below. These visual changes have not been confirmed live yet.

Offline: all 15 regression groups pass; changed-file syntax and whitespace pass.
New tests exercise the actual loader's nil/wrong-root cases and both storage
write guards, including automatic default-file creation. Windows controller
availability and the original XML failure's cause remain unverified.
Local commits: `9b61a25` load/write protection and set validation; `302451e`
ASCII chat feedback. Documentation/package checkpoint follows. No push or post.

# Public Preview 10 — name-first creation and menu navigation

Version: `0.4.0-a.20261011.public-preview10`.
Maintenance initially interrupted Preview 9 testing. Follow-up: tests 1-4
passed, subject to the recorded picker design changes. Set creation later failed
at player.lua:204. Preview 10 UI changes remain awaiting live verification.

Install the cumulative overlay after stopping the wrapper and unloading. Copy
all of xivcrossbar, including the small **assets/menu** folder. Bulk images,
sounds, config.ini and character data are excluded. Rollback restores Preview 9.

1. Bare `//xb ca` and menu Create Custom Action immediately open Custom Action
   Name entry; no option buttons above it. Other fields are inactive. Empty name
   and duplicate name confirmation stay in entry. A unique name unlocks the
   review. Enter or controller Confirm commits; Circle cancels to the command's
   exit or the menu page, respectively. Typing must not open native menus/chat.
2. `//xb ca Bow` still opens a named review directly; existing exact names edit.
   Alias/Command defaults remain green in parentheses and blank in XML. Recheck
   Save Only, Save & Bind, Circle return, name-only alias execution and reload.
3. Navigate with D-pad and mouse: selected icon, frame and label lift 2 px up
   and left; the previous option restores. Golden cursor follows selection,
   glints at 12 fps and disappears with the menu. Check its brightness/placement
   and the warm brown/gold selection at 960×540 and a larger resolution.
4. Icon picker: top-level Goring Blade sample is absent; weaponskill icons in
   their own folders remain. Directory/PNG selection and Circle back work.
5. A multi-page list: L2 highlights Previous, R2 highlights Next. No turn until
   release; one turn per gesture. Face/D-pad input while held consumes the turn.
   Both trigger orders select their respective directions and commit once.
   Rounded dark-blue buttons show L2/R2 icons; active buttons become brown/gold.
   Option selection stays in place or moves to the nearest valid last-page entry.
6. Ordinary binding combos still work, including trigger+Circle. Trigger input
   while binding must capture the combo rather than turn a page. Bare Circle,
   Cross, Share, Options and physical F7/F8 retain the tested behavior.
7. Continue unfinished Preview 9 checks below: typing isolation, new set flow,
   Superwarp, dragging/visibility, fade text and persistence across reloads.

Offline: 14 regression groups pass, plus changed-file Lua syntax and whitespace.
Cursor lifecycle is exercised against the actual playback helper; selector
position restoration and name-gated drawing have regression coverage. Windows
FFXI rendering/input still require the checks above. No public posting yet.

# Public Preview 9 — release candidate testing, October 11, 2026

Version: `0.4.0-a.20261011.public-preview9`. Cumulative update overlay for a
qEagleStrikerp base install. Keep your existing images, sounds, settings and
character data. Copy only the ZIP's `xivcrossbar` contents over that installation;
do not copy the rollback folder. Stop the old wrapper and unload before copying.
Restart with controls released. No personal L1 companion is included.

**First checks, in order:**

1. `//xb status`: Preview 9, PS5 DirectInput / apps; input diagnostics off.
   Native movement/camera work; disable native D-pad/face/trigger assignments
   and hat-switch menu input as in the tested setup. Bare Triangle opens the
   game menu, Square focuses selection, Cross confirms, Circle cancels.
2. `//xb ca`: Save options are dim and skipped until Custom Action Name is
   supplied. Explore Choose Icon before naming: folders open without errors;
   Circle returns. Enter a name and repeat Choose Icon, pick an icon, return.
3. Edit Name/Alias/Command inline; type spaces, punctuation, both Shifts and
   `input /echo Preview nine`. No inventory, action menu or native chat opens.
   Enter commits; Circle cancels; Escape exits. Then type normally in the game
   and open/close the console with Insert. Check this before longer testing.
   If typing becomes blocked after leaving an editor, unload the addon; if
   necessary run `//keyboard_blockinput 0` from Windower's console.
4. Save & Bind a real echo; Circle from binding restores the review, Share
   exits. Reopen by exact name. Save blank-command Bow and verify alias/name
   fallback. Reload and confirm both actions and bindings persist.
5. Menu Create New Set: type a disposable name, Enter; one creation message,
   back to main menu, no alias/icon/bind steps. Switch to the set explicitly.
   Repeat the name: reject without losing its existing bindings. Test the
   Options chooser's Add New Set text entry too, including spaces/punctuation.
6. Superwarp main icon is Home Point. Bind a known unlocked destination anew;
   verify its crystal icon and actual warp. Existing old bindings are preserved.
   Also confirm Execute Command's icon and no picker errors in other lists.
7. `//xb scale 0.6`, `hide`, `show`, `auto`, `autohide off`: actions continue
   working in each mode. Check full and compact fades for caption flicker.
   Explicit show should redraw without needing a reload.
8. Drag with a menu open. Open Move Crossbars while hidden: bar becomes visible,
   D-pad and drag both move it; Circle leaves and restores prior visibility.
   Position persists after reload. Menu choices still respond to mouse clicks.
9. First row is Custom Action/Create/Edit/Delete; four columns maximum, more
   spacing, Remove Binding immediately before Credits. Check 960×540,
   1280×720, 1600×900, 1920×1080, 2560×1440 and 3840×2160 as available.
10. Regression: L2/R2 and both trigger orders, face and D-pad actions each fire
    once; no target change/native macro popup; physical F7/F8 and Ctrl binds
    retain their normal functions. Test client switching and wrapper stop/start.
    Binding/clearing messages appear once in chat with the correct combo/set.

**Recorded live baseline:** Preview 8 Insert behavior improved; ordinary
Apps-trigger actions, navigation, Bow fallback, IJKL, dragging, scaling and reload
persistence passed. Preview 8 had typing leakage, icon-picker crashes, unnamed
save failures, menu Create New Set misrouting and text fade flicker. These are
fixed in code here and remain live-test targets, not claimed live passes.

**Offline validation:** 13 Lua regression groups, changed-runtime syntax and
patch whitespace checks. Review anchors checked at six resolutions. Tests use
Lua 5.4 with Windower stubs; no Windows/FFXI/AHK execution here. A whole-repo
parse encounters unchanged Windower string-method syntax in skillchains.lua;
that dependency is not rewritten by this update.

**Deferred:** Help/status wording review together, Display/Controls menu,
caret/paste editing, general item-icon extraction repair, other controller
wrappers/XInput, visual polishing and the personal companion. No new Display
menu or personal-control features are introduced.

**Rollback:** stop wrapper, unload, copy `rollback/xivcrossbar` back over the
addon. It restores the runtime files changed since Preview 8; extra unused new
modules may remain. Your data/assets stay untouched. Keep a separate backup of
your own data before testing set creation/deletion.

# Public Preview 8 — first live-test corrections, October 11, 2026

Version: `0.4.0-a.20261011.public-preview8`. Cumulative BASE update only.
Stop the old AHK process and unload before overlaying; restart with all buttons
released. This version installs AHK's keyboard hook so physical Apps/Ctrl checks
can distinguish injected presses. Quiet modifier edges are logged to
`data/input-transport.log`. Windows behavior remains to be verified.

1. Test Insert before and after one bare Cross press/release, with console open
   and closed. Also check a trigger/slot press, focus away/back, and ordinary
   typing. If Insert fails, preserve the transport log; do not assume fixed.
2. Open the chooser and hover Add New Set: no ui.lua:758 error should recur.
   Create a disposable set normally; retain the duplicate-protection check.
3. Binding screen: bottom-right Confirm is dim before a combo is captured;
   Back dims while triggers are held. Both become normal at confirmation.
   Bare Circle returns, trigger+Circle remains bindable, Share exits.
4. Main options stay at most four per row, centered with uniform spacing.
   Create Custom Action and Remove Binding exchange positions; other order stays.
5. No Allow stpc diagnostic. Default now true; explicit retained false settings
   need manual change to AllowSTPCForSelfTargetedActions=true, then reload.

Live Preview 7 report: all tested L2/R2/combined-trigger face and D-pad slots
execute without native input leakage; echo binding and name-only Bow work;
right/left Shift, punctuation, Save & Bind return and IJKL targeting work.
Unresolved: native gameplay/chat typing leakage in inline fields; Insert after
Cross (hook correction awaits test); welcome text flicker; review-screen clarity;
text editing has only append/backspace, not arrow-key caret navigation.

Offline checks cover chooser placeholders and sparse sets plus the prior nine
regression groups. AHK's hook behavior cannot be verified in this Linux runtime.
Runtime checkpoint before wrapper correction: 7de59f6.

# Public Preview 7 — direct-action Go Back correction, October 11, 2026

Version: `0.4.0-a.20261011.public-preview7`. Same cumulative BASE installation
rules as Preview 6. Native menus and addon D-pad/Confirm/Back/Exit passed live
in Preview 6. Switch Target -> binding -> Circle hit a missing selection-state
error at action_binder.lua:1303; this update restores the original main-menu page
for direct binding entries (Switch Target, View Map, Last Synth, Remove Binding).
Offline regression covers all four entries. Retest those paths with bare Circle.

Insert became usable after stopping AHK. This is recorded as an unresolved
transport interaction, not established as a stuck Apps modifier. Wrapper code
is unchanged. Restart with all controls released, then test Insert before any
controller press and after a simple press/release. Do not hold controller keys
while opening the console. If it recurs, preserve data/input-transport.log.

# Public Preview 6 — optional gameplay D-pad letters, October 10, 2026

Version: `0.4.0-a.20261011.public-preview6` (UTC stamp).
Same cumulative BASE update installation rules as Preview 5 below.

## Short first play-through

Start with diagnostics off (`//xb inputtest off`, `//xb inputtrace off`).
Use Preview 6 already supplied; the extra smoke checks changed no runtime code.

- Open `//xb ca "Bow"`, edit one field using right Shift, cancel that edit with
  Circle, then Save & Bind. Circle back once to verify the review survives.
- Execute one known bound action with a trigger: one action, stable target,
  no native macro pop-up. Confirm bare Cross/Circle still behave normally.
- Try `//xb dpad ijkl` with your native keyboard assignments. Browse the addon
  menu, execute a D-pad slot, then restore `//xb dpad arrows`.
- Drag the crossbar somewhere pleasant, reload, and keep playing. The position,
  action and D-pad choice should survive. Report the first surprise as it happens.

Deeper multi-client and resolution checks below can wait for the next session.
Additional offline checks exercise real review drawing calls at all six sizes,
inline rectangles, long-value truncation, unsaved draft isolation, and actual
D-pad command persistence/release/invalid-input handling. These check geometry
and behavior, not rendered font widths or the game's response.

## Detailed checks

1. Default `//xb dpad arrows`: bare D-pad sends regular arrow keys.
2. `//xb dpad ijkl`: Up=I, Left=J, Down=K, Right=L. Test your chosen native
   keyboard assignments. The addon changes output, not FFXI's configuration.
3. Verify addon menu navigation and trigger-held slot actions remain unchanged
   in letter mode, without native letter-key leakage from those contexts.
4. Switch mode while holding a direction: old gameplay output must release;
   release and press again for the new mode. Check focus loss also releases it.
5. Bare `//xb dpad` toggles; reload preserves the mode. Restore arrows when done.
   Letter mode can type letters into native chat; check that tradeoff explicitly.

Offline checks cover all four letter mappings, ordinary face-button output,
logical menu/slot routing, and release ownership across a mode change. Eight
regression checks and changed runtime syntax pass. Windows live tests pending.
Implementation checkpoint: 53b780b. Help text remains reserved for joint review.

# Public Preview 5 — three focused fixes, October 10, 2026

Version: `0.4.0-a.20261011.public-preview5` (UTC build stamp).
Same cumulative BASE update and installation rules as Preview 4 below.
Help text is deliberately unchanged pending review together.

1. Create a disposable set, bind one action, then try creating the same name
   again using different capitalization. The command must reject it and preserve
   bindings through reload. Also check reserved names and ordinary new creation.
2. In a custom action, set Command to spaces only. Bind and execute: it should
   use Alias, then Catalog Name if Alias is also spaces only. Catalog XML keeps
   the entered values; executable slot fallback agrees with the review.
3. Edit an inline field using right Shift for capitals and punctuation. Hold
   both Shift keys, release either, and verify the other still works. Verify
   ordinary unshifted typing after releasing both.

Eight offline checks pass, including actual set creation preserving existing
bindings, real slot binding whitespace fallback and both Shift press/release
orders. Changed runtime files pass syntax checks. In-game checks remain pending.
Local checkpoints: b0236f1 (sets), a19ea51 (fallback), b1c692f (Shift).

# Public Preview 4 — single-screen custom actions, October 11, 2026

Version: `0.4.0-a.20261011.public-preview4`. Cumulative BASE experiment update;
use the installation and rollback instructions below. This is not a personal
Batch 19 overlay. No settings, profiles, images, sounds or companion included.
Existing base assets are required. Catalogs remain per character.

## Live checks for this preview

1. Open `//xb ca "Bow"`. Check Catalog Name, green `(Bow)` Alias and Command,
   and optional `(none)` fields. Save Only. Verify no command is filled into
   CustomActions.xml. Bind it from Custom Actions and execute a known Bow alias.
2. Open the same exact name: it should edit that record. Test the old
   `//xb ca new <name>` and `//xb ca a/n/c <value>` forms.
3. Edit fields inline: spaces, uppercase letters, punctuation and a semicolon
   command chain. Enter commits; Circle cancels; clearing Alias/Command restores
   green defaults. Check no typing reaches native chat or triggers gameplay.
4. Save & Bind, then Circle back to review. Verify the saved draft survives.
   Bind a slot and check exactly one execution with no native input leakage.
   Trigger+Circle must remain bindable; bare Circle goes back.
5. Choose an optional icon or linked action, cancel or accept, and return to
   review. Clear each. Reject blank catalog names and duplicate renames.
6. Open Create Custom Action from the menu: Circle returns to the main menu;
   command-opened review exits. Confirm unrelated set/icon workflows still work.
7. Inspect at 960x540, 1280x720, 1600x900, 1920x1080, 2560x1440 and 3840x2160.
   All nine review choices, values, inline field and hints should fit. Confirm
   ordinary lists restore their normal layout after leaving review.
8. Reload and verify records and bound slots survive. Repeat on another client
   with its own catalog. Retest targeting, scaling, dragging and visibility.

Offline checks pass: real review transitions, command compatibility, effective
fallbacks, duplicate-name validation, and the actual XML serializer leaving
blank defaults absent. Existing transport, bounds, visibility, presentation and
mouse checks also pass. Lua syntax checked through Lua 5.4; Windows/Windower Lua
5.1, controller input and visual appearance still require the live checks above.

# Public Preview 3 — directly draggable crossbar, October 10, 2026

Version: `0.4.0-a.20261011.public-preview3`. Same BASE-experiment installation
rules as Preview 2 below. This cumulative update needs existing assets and is
not an overlay for personal Batch 19. No settings, profiles, images or sounds.

Left-click and drag the visible crossbar, then release to save. No lock/unlock.
Test at scales 1 and 0.6, in compact and full layouts: all slots, labels, recasts,
trigger backgrounds and indicators move together. Reload must preserve exactly
the new position. Verify normal clicks outside the bar still reach the game.
Hidden bars and bars under the addon menu/chooser must not capture mouse input.
Changing visibility during a drag finishes and saves that gesture.

The existing offset calculation added saved values twice; this preview applies
them once. Old nonzero positions may consequently move once on first install;
drag to your preferred position and reload to verify it stays there.
Local mouse-gesture checks pass; actual Windows dragging remains untested.
Source checkpoint for scaling/fades: d80d453; documentation: e31f12c.

# Public Preview 2 — crossbar scaling and fades, October 10, 2026

Version: `0.4.0-a.20261011.public-preview2` (UTC build stamp).
This UPDATE ZIP is for the upstream-based Apps experiment, **not the personal
Batch 19 install**. Preserve the whole existing folder before applying it.
No images, sounds, data, character profiles, config.ini or personal companion are
included. Existing base assets are required. Stop the wrapper, unload every
client, overlay the included xivcrossbar folder on that BASE installation, then
load again. Do not overlay this on our personal branch: its catalog/editor
behavior differs. Keep the two installations separate.

Commands: `//xb ui scale 0.6` (range 0.25-2), `//xb ui fade [on|off]`
(bare toggles), and the existing visibility commands below. Settings persist.
Defaults: scale 1; fades enabled; FadeIn 0.24 seconds, FadeOut 1 second,
LoadFadeIn 3 seconds. Animation values are editable in data/settings.xml.
Menu scaling, page animation, FFXI skin and sounds are not part of this port.

## Live checks for this preview

1. Confirm version using `//xb inputstatus`. Use `//xb inputtest off` and
   `//xb inputtrace off` if retained experimental settings enable them.
2. At scale 1, compare the base layout; then try 0.6, 0.8 and restore 1.
   Check labels, costs, recasts, controller hints and trigger backgrounds stay
   aligned in both full and compact layouts. Check three/four/six bars as used.
3. Test Lionstag at 960x540 and Franklet at 1280x720; larger screens when handy.
   Scaling the bar must leave the binder unchanged. Reload preserves the scale.
4. `//xb autohide on`: hold/release triggers to reveal/hide the bar. Release and
   quickly press again while fading: opacity should reverse smoothly.
5. `//xb ui hide`: slot actions still execute, but no icons or combat indicators
   appear. `//xb ui show` restores the bar. Test changing sets while hidden.
6. Toggle fades off/on. Off should immediately show/hide; on restores smooth
   transitions. Initial load uses the longer welcome fade.
7. Repeat target-preservation, ordinary menu navigation, physical F7/F8, reload
   and two-client checks from the earlier routing record.

Local checks cover actual geometry surfaces/primitives, time-based reversal,
complete hiding, disabled fades, routing and six menu bounds. Available parser
is Lua 5.4; Windower and Windows AHK execution still require your live checks.
Rollback: stop wrapper/unload, restore the backed-up base folder, and reload.

# Public coherent update — development checkpoint, October 10, 2026

Branch: `public/coherent-update`. This is work in progress, not a delivered ZIP.
Upstream master was checked through GitHub on October 10 and still resolves to
`15d8381dfad0f9efdb84fe2d24655afc150faec4`, matching our existing runtime snapshot.
Starting local checkpoint: `0865014`. No personal companion or personal controls
are imported. No commits have been pushed and no PR has been opened.

The first implementation adds `ControllerModifier` (`apps`, default, or `ctrl`).
Lua capture, silent bindings and wrapper startup use the same selected modifier.
This is **not** an exact reproduction of the upstream wrapper: it retains our
context routing and edge ownership. Ctrl mode intentionally reserves Ctrl+F1-F12
and may bring up native macros; Apps is recommended.

Changing transport requires stopping the shared wrapper, unloading every client,
editing ControllerModifier consistently in their settings, and loading again.
The first client starts the shared wrapper; existing processes do not hot-reload.
There is deliberately no runtime toggle that could split Lua/wrapper state.
Neither mode restores personal bindings overwritten on its reserved combinations.

Local routing checks pass for both markers. Windows/AHK startup arguments, Ctrl
mode, and transitions require live tests before this is presented as supported.
Menu positioning now uses one centered panel independently of crossbar offsets;
logical bounds are checked at 960x540, 1280x720, 1600x900, 1920x1080, 2560x1440,
and 3840x2160. Selectors have positive page capacity and at most four columns.
This is not yet independent menu scaling or proof every detailed screen fits.
Live check: opening the first menu should align backdrop/title/options at each
resolution, including with nonzero crossbar Style offsets. Check deeper dialogs.
Visibility commands now persist: `//xb ui hide`, `show`, `auto`, and
`//xb autohide [on|off]` (bare toggles). Hidden mode does not disable actions.
~~This initial port has immediate transitions, not our personal branch fades.~~
Preview 2 adds the existing elapsed-time fades and coherent crossbar scaling.
Live checks: hiding keeps slot actions working; auto shows only while triggers
are held; show restores the bar; reload/set changes respect the selected mode.
Still pending: independent menu scaling, navigation, editor fixes,
clean user README and packaging. Earlier test records follow unchanged.

## October 9 live checkpoint and shutdown diagnosis
All eight slots and tested trigger combinations passed silent interception; addon menu isolation, bare Cancel, and native keyboard F7/F8 passed. Bare Triangle should become main menu and Square active-window focus in the next test.
Shutdown cause found: v1 label-style OnExit handler ended with return, cancelling normal termination. Changed it to ExitApp after release cleanup; live validation still pending. This correction is not included in the already delivered Test3 ZIP.

# Apps + F1-F12 Test 3 — silent native interception

Overlay the included xivcrossbar.lua onto the Test 2 base experiment. Reload the addon in each client (//lua r xivcrossbar). No AHK or profile changes; preserve current bindings and settings.
Real output: //xb inputtest off. Trace: //xb inputtrace off.
On load this build reserves Apps+F1-F12 using Windower bind commands targeting xivcrossbar inputconsume. Installation announcements may appear once per load; button presses produce no interception echo. Unload unbinds these twelve combinations. Existing personal bindings on these combinations are replaced, not restored automatically; record and restore them manually if desired. Plain F-keys and Ctrl/Alt binds are untouched.

Live evidence: Apps+F7 test echo prevented self-targeting while both the real slot echo and ordinary Cancel/menu Back still worked. Lua's blocked-flag handling is deliberately unchanged; test other keys before altering it.

First test: target someone else; hold R2 and tap Circle in Input Test. Expect one slot echo, unchanged target, no interception message. Then bare Circle cancels. Next repeat all eight slot buttons and trigger states while checking native targeting/menu leakage. With both menus open, only addon selection should move. Plain keyboard F-keys without Apps retain native behavior.

Wrapper shutdown, held-focus cleanup and 540p layout remain deferred. Rollback: restore Test 2 xivcrossbar.lua and reload; restore any desired personal Apps binds afterward.

---
# Apps + F1-F12 Test 2 — 2026-10-09

Build: 0.4.0-a.20261009.base-apps-fkeys-test2. Real output ON; trace OFF.
Transport commit: 3dde617. Shutdown and held-focus cleanup remain unresolved and deferred.

## Install into the existing BASE experiment
Exit the old ffxi_directinput.ahk through Task Manager if necessary before replacing files. Unload xivcrossbar in both clients. This ZIP contains only the changed runtime files and the two snapshot profiles; overlay its xivcrossbar folder onto the existing BASE-APPS-UNCOMMON-TEST1 installation. It is not a patch for the personal Apps-L1 build.
Back up the current data/hotbar/Fenrir/Franklet and Lionstag folders first: supplied XMLs replace those profiles with the October 8 17:55 snapshot. No settings.xml is supplied.
Load/reload xivcrossbar, then run //xb inputtest off and //xb inputtrace off IN EACH CLIENT: existing settings override defaults.
Keep native HAT Switches DISABLED, native sticks enabled, DirectInput enabled.

## Binding provenance
Franklet BST-WHM and BST-DEFAULT, Lionstag RDM mappings, and all other supplied character XMLs come from xivcrossbar_10-8-2026-1755-return-testing.zip. These are the latest available copies here, not a claim about changes made afterward.
Original actions and bars are preserved. A separate Input Test set was added to Franklet BST-WHM and Lionstag RDM-NOSUB. All 32 slots execute real input /echo commands identifying character, bar, and slot. Use the existing set chooser (hold Options, D-pad Up/Down, release Options) to select Input Test. Lionstag must be RDM/NOSUB for that set; other jobs use their original snapshot bars.

## Live tests, one at a time
1. With no addon menu or trigger, D-pad moves the game menu; Cross confirms and Circle cancels.
2. Select Input Test. Hold L2 and press each direction/face: exactly one labeled echo per press. Repeat with R2, L2 then R2, and R2 then L2. Check target and native menu cursor for leakage.
3. Use the original Basic set for real BST/pet commands as desired; watch target preservation, especially Circle/F7.
4. With both addon and game menus open, D-pad moves only the addon selection; Cross confirms, Circle backs out.
5. Keyboard F1-F12 WITHOUT Apps retains native behavior. Do not retain the manual #f7 test bind during the Lua-only leakage check; restore your personal bind afterward if desired.
6. Toggle //xb inputtrace on only if diagnosing failures. //xb inputtest on restores dummy mode.

Prior live results: HAT disabled blocks native D-pad but keeps sticks/camera. Uncommon transport routed all trigger states and menu directions; held repeats did not duplicate actions. Held focus switch needed one clearing press. Mail/MediaSelect launched Windows applications; Kanji and MyComputer lacked useful DIKs; BrowserSearch opened Start. These candidates are replaced entirely by F1-F12 in this test.

Rollback: exit the wrapper, unload addon, restore Test1 runtime files and backed-up profiles, reload. Restore native HAT only if returning to native D-pad routing.

---
## Previous test record

# Base Apps + uncommon signals — Test 1, October 9, 2026

## What this package is

An isolated PS5 DirectInput experiment based on qEagleStrikerp/xivcrossbar master
commit `15d8381dfad0f9efdb84fe2d24655afc150faec4` (August 1, 2026).
Runtime source and assets were verified against upstream blob hashes. The local
baseline is a runtime snapshot, not a clone of upstream Git ancestry; editable
PSD source artwork and README screenshots are omitted from the installation.
Branch: `experiment/apps-uncommon-signals`. See CHECKPOINTS.txt for local commits.
No commits have been pushed. Existing personal development remains separate.

Version: `0.4.0-a.20261009.base-apps-test1`.
This includes the base UI and features, not the personal Batch 17/18 visual,
custom-action editor, shared-catalog, L1 bar, PS, or touchpad modifications.

## Changes and defaults

- Apps replaces Ctrl capture. No global unbind of F1–F12 or Ctrl shortcuts.
- Every digital input below sends the same signal in every context.
- Lua chooses ordinary gameplay, crossbar, setup, binder, text, or set chooser.
- Press ownership persists until release; repeated downs are suppressed.
- Entering a trigger/menu context releases generated held gameplay keys.
- Dummy gameplay and slot commands ON; trace ON. Existing XML is not needed.
- PS5 mapping: Cross confirms, Circle cancels, Square opens native main menu,
  Triangle changes active window. DirectInput wrapper only; XInput and other
  supplied upstream scripts are not remapped and must not be launched here.
- One persistent AHK v1 script; loading another client does not replace it.
- Stop: `//xb controller stop` or Ctrl+Alt+F12. Start: `//xb controller start`.
  The stop command affects this new script, not an already-running old wrapper.
- No timed automatic shutdown. Explicit stop is provided.

## Candidate signal table

None of these twelve has been confirmed by this new live test. The DIK column
is the expected DirectInput code, not an observed result. AHK explicitly requests
both a virtual key and scan code. UNMAPPED results must be investigated.

| Controller | Candidate | AHK output | Expected DIK |
|---|---|---|---|
| D-pad Up | Kana | vk15sc070 | 112 |
| D-pad Right | Convert | vk1Csc079 | 121 |
| D-pad Down | Nonconvert | vk1Dsc07B | 123 |
| D-pad Left | Kanji | vk19sc094 | 148 |
| Cross | Yen | vkDCsc07D | 125 |
| Square | Mail | vkB4sc16C | 236 |
| Circle | Media Select | vkB5sc16D | 237 |
| Triangle | My Computer | vkB6sc16B | 235 |
| Share/Create | Browser Favorites | vkABsc166 | 230 |
| Options | Browser Search | vkAAsc165 | 229 |
| L2 | Browser Back | vkA6sc16A | 234 |
| R2 | Browser Forward | vkA7sc169 | 233 |

Apps (DIK 221) is held while any of these inputs is held. No F-key slot or trigger
markers are emitted. Japanese input mode or Windows application/browser effects
are possible; the user explicitly chose these candidates for testing.

## Install without mixing builds

1. On Franklet and Lionstag, unload XIVCrossbar. Their reported older
   `0.4.0-a.20261008.17-Apps-L1` build does not have controller stop. Exit its AHK
   wrapper through its tray icon or the identified process. Also exit the old
   HIGH-FKEY-PROBE script and unload fkeyprobe if still loaded. Keep clients open.
2. Move the current `addons/xivcrossbar` folder into a backup location outside
   `addons`. Preserve the whole folder, especially data and controller settings.
3. Put this package's new `xivcrossbar` folder into `addons`. This is a fresh
   install, NOT an overlay. Do not copy personal data/settings into this test.
   It supplies config.ini; resources and blank profiles generate on first load.
4. Clear native gamepad assignments for D-pad and the twelve buttons above.
   Keep analog movement/camera. This test does not translate L1/R1/L3/R3/PS/Mute
   or touchpad. Retain any native personal assignment you wish for those buttons.
5. Load only the test client first: `//lua l xivcrossbar`.
   Run `//xb inputstatus`; confirm the test version and InputTest=true.
6. FFXI must be focused. Release all twelve buttons before testing; focus changes
   require neutral input before the script rearms. Run plugin and AHK v1 required.

## Live tests — first signal identity, then routing

1. Tap each of the twelve buttons individually. Expect one named DOWN and UP
   with the DIK above. Face/D-pad presses outside menus also print a gameplay
   dummy message. Share opens the original binder; close it with Share before
   continuing single-button checks. Options shows the chooser while held.
2. Any UNMAPPED/DIK=0 or unexpected Windows effect: note the physical button and
   stop that part of the test. Send chat log plus data/input-transport.log.
   Do not assume a missing signal is successful because AHK logged it.
3. Hold L2 and tap each direction/face: expect eight dummy slot messages on bar 1.
   Hold R2: bar 2. Hold both: bar 3 with the default three-bar configuration.
   Four/six-bar trigger order and double-taps remain the upstream implementation.
4. Open the binder with Share; RELEASE Share and both triggers. Directions should
   navigate it without a trigger. Cross confirms and Circle cancels according to
   the base UI. No gameplay or crossbar action messages should occur alongside
   menu input. This is real menu navigation; avoid saving bindings during routing
   checks unless deliberately testing the binder. No new menu design is included.
5. Hold Options and test Up/Down to change sets. Other slot buttons are consumed
   without firing actions, including while a trigger is also held.
6. Hold a face button while opening/closing a menu or changing triggers. No new
   action should fire merely because the context changed. Release and press again
   to act in the new context. Check focus switches require release before rearming.
7. Press physical keyboard F1–F12, including F7 while holding R2: they should keep
   their ordinary behavior and not execute dummy slots. Ctrl macro behavior should
   remain available on the physical keyboard; Apps controller input should not
   open native Ctrl macro palettes.
8. Stop with `//xb controller stop`, verify digital translation ceases; start with
   `//xb controller start`. Check Ctrl+Alt+F12 as the script-only emergency stop.
9. After signal identity and dummy routing pass, `//xb inputtest off` enables real
   gameplay key translation and existing bound slot execution. Re-enable with
   `//xb inputtest on`. A bare command toggles. `//xb inputtrace off|on` controls
   logging. This package has blank crossbars unless you deliberately bind actions.

The dummy mode reports held edges but does not exercise real native arrow repeat.
Real key holds, release on focus loss, multi-client behavior, Windows effects,
and AHK execution require live testing. Do not label those passed from local tests.

## Rollback

Stop this script (Ctrl+Alt+F12 works outside FFXI), unload the test addon, move
its folder aside, restore the complete previous `xivcrossbar` backup, and load it.
Restore native D-pad assignments if returning to the old routing design. No old
bindings/settings were overwritten because installations were kept separate.

## Local validation

Changed Lua files parse in the available Lua 5.4 runtime; no Lua 5.1/Windower
runtime or Windows AHK interpreter is present here. Tests cover twelve unique
logical candidates, held ownership, repeats, dummy key and actual slot execution,
menu routing, chooser exclusion, transitions, capture-loss release, physical F7,
and unmapped logging. Unchanged upstream uses Windower Lua syntax extensions
(e.g. string-literal :format); a blanket standard-Lua parse cannot validate those.

## Prior evidence and materials

- First higher-F probe: F13/F14/F15 received as 100/101/102. F19/F20 received as 0.
- October 9 supplied HIGH-FKEY-PROBE.log records all twelve F13–F24 outputs with
  376 downs and 376 ups. Franklet's supplied chat log includes distinct 100–102,
  repeated zeros, and an annotated L2/R2 test yielding zero. Do not map zeros.
- Franklet/laptop baseline is Batch 17 Apps-L1, not Cioara's complete Batch 18.
- ~~The long log proved automatic shutdown failed.~~ Correction: the user may
  have reset the probe; a timer failure is unconfirmed. This version uses explicit
  stop controls rather than assuming a timed diagnostic session.
- Deferred: configurable mappings, personal addon/L1 palette extraction, keybind
  combinations beyond this fixed layout, //xb move / always-draggable experiment.

Sources: https://github.com/qEagleStrikerp/xivcrossbar/tree/15d8381dfad0f9efdb84fe2d24655afc150faec4
and https://docs.windower.net/commands/keymapping/.


## Retained credits branch history

# Current Development Status - Credits menu centering

2026-11-12, rerorriM-Mirrorer/xivcrossbar, feat/contributor-credits-20261112.
Baseline a7ef335dd09077a88e2bcb2dde0bc09f4dde8c29. User confirms portraits look correct when bound;
Credits and icon picker portraits sit above/left inside their frames. Corrected
sized-image inset to (40 - image size) / 2 relative to the frame origin, shared
by both menus. Bound-slot assets, ordinary menu icons and controller behavior
are unchanged. Regression now checks both portrait/frame coordinate differences.
Local execution is unavailable (workspace connection failed). GitHub CI run
43262471284 passed all 54 Lua suites and the Windows x86 native/AHK checks at
source d63c16bf4a505542dddea0c3c9c7bdceb20bb2b5. Live centering confirmation remains pending. Install the
updated ui/selectablelist.lua, retaining prior portrait assets, and reload XB
one client at a time. Next step: confirm centering on both menu screens.

## Previous status (retained)

# Current Development Status - Contributor credits and forum-post draft

2026-11-12, rerorriM-Mirrorer/xivcrossbar, feat/contributor-credits-20261112.
Starting published consolidated baseline ba07c84. Read current GitHub AGENTS.md,
WORKFLOW.md and TESTING.md before changes. Scope: supplied Credits.zip assets,
Credits screen/default icon picker and an edited draft of Pasted text(8).txt.
No settings, controller routing, native DLL or hotbar changes.

Preserved all original credit roles, added supplied contributor names/aliases
without inventing contribution details, and A's repository-owner GitHub portrait.
20 credits rows, 19 unique portrait icons. Static 64x64 aspect-fitted PNGs with
transparent padding; first GIF frame used. Aeliya/Akirane supplied images are
matching placeholder-style avatars, retained as provided. Existing SirEdeonX
credit uses the newer supplied portrait. Default icon picker Credits directory
keeps exact contributor spelling while saving ordinary relative PNG paths.
Third-party icon packs may copy that directory; no custom packs overwritten.
Portrait sources recorded under images/credit_avatars/SOURCES.md.

Focused regression: production Credits screen emits 20 rows with retained roles;
all portrait/icon PNG signatures verified; icon-folder labels and menu resource
regressions pass. 138 Lua sources parse under Lua 5.4 with temporary Windower
syntax normalization. GitHub Actions run 43250952846 at published
11eda09d582c6b366a1152a6485d5dd001bd0aef passed all 54 Lua suites,
Windows x86 native fixtures/module loading, AHK discovery/reader/lifecycle
and package assembly. All 19 selector PNGs decode as 64x64 RGBA. Local and
published runtime trees match. Actual Windower rendering/icon binding and
pagination remain live tests; no live FFXI pass claimed. Forum BBCode tag
balance was checked locally, not rendered or posted on FFXIAH.

Forum draft uses conservative BBCode, original personal introduction/thanks,
feature/FAQ groupings, corrected ribbon command names and explicit pending
release/dependency placeholders. No forum posting occurred. Draft avoids claiming
future menu/editor features are delivered and retains the settings-save race and
focus-switch leak as release issues. No source-contribution claims beyond the
user-supplied names and previously established role labels.

INSTALL: overlay the credit patch onto consolidated ba07c84; reload XB one client
at a time. No reader/client restart. Existing settings-save race remains deferred;
do not broadcast settings-changing commands. Test Credits page navigation and
ordinary slot/custom-action icon selection from Default icon pack > Credits.
Next: live visual acceptance, confirm displayed contributor names and complete
release/settings review before publishing the forum draft.

---

# Current Development Status - Consolidated controller, PS and SetName overlay

2026-11-12 (America/Chicago). Repository rerorriM-Mirrorer/xivcrossbar,
branch release/consolidated-overlay-20261112. Packaging-only consolidation
from test/set-name-hud-20261112 source 8152dec (runtime caf89a7).
Includes Extra Controls 462002c, permissive PS/fresh modifier 0a5540b,
initial SetName UI/independent offset commands, and latest menu-visible set
name/persistent-double-tap captions from the user's attached overlay.
All 22 runtime paths were compared against the layered ZIPs and CI source;
no new runtime behavior was introduced. The payload includes the new controller
DLLs even for users who have not installed Extra Controls yet. No layering needed.

Verification: GitHub Actions 43241843720 at caf89a791a18204ebd55d3cad07e2501a2053358
passed Lua and Windows jobs: 53 Lua suites/136 parsed sources, x86 native
fixtures/loading, AHK discovery/reader/lifecycle and package assembly. Artifact
13956275380 downloaded and its GitHub SHA256 verified. Five focused local
suites rerun for this consolidation passed, including layout, set captions,
fresh modifier arrival, personal controls, extra messages and presets. Lua
runs use Lua 5.4 with temporary Windower syntax normalization. No new live
FFXI/controller/desktop test is claimed. PS behavior and Default labels at
banklabeloffset 0 3 were previously confirmed good by the user; new camera,
touchpad and latest menu/persistent-caption acceptance remain pending.

INSTALL THIS ZIP ONCE: stop reader, CLOSE ALL FFXI clients, back up addon,
overlay the included xivcrossbar folder, then restart/load clients and reader.
Do not overlay earlier controller/PS/SetName ZIPs afterward. No settings XML,
hotbars, bindings or personal data are shipped. Keep current settings and label
offsets. Existing Me settings apply; if the new tests are disabled, use
//xb me zoom on and //xb me map on individually, one client at a time. Avoid
reapplying a whole preset just to enable these tests; it resets other preferences.
Default/Legacy keep private shortcuts off. See INSTALL-CONSOLIDATED.txt.

Deferred, unchanged: shared settings.xml write collision after simultaneous
client saves (recovered uploaded XML separately); no cross-process locking or
atomic replacement fix yet. Avoid broadcast settings-changing commands such
as //all xb me. Intermittent native D-pad targeting on focus handoff also remains
open; held modifiers now enter fresh press handling but do not prove native
leak fixed. EventBars taking precedence over chatlog remains a requested future
change, not implemented. Settings/command exposure review, compact/tight and
optional trigger-field appearances remain separate work. No binding-menu
redesign or unrelated development was included. Rollback requires all clients
closed and restoration of the prior matching runtime/DLL backup.

---

# Current Development Status - Menu-visible set name and persistent extra captions VERIFIED

2026-11-12 (America/Chicago). Repository rerorriM-Mirrorer/xivcrossbar,
branch test/set-name-hud-20261112. Tested source checkpoint
caf89a791a18204ebd55d3cad07e2501a2053358, based on
79f832454bedc3cbc7279aba9d6bcf2f87c69843. GitHub Actions
run 43241843720 PASSED both Lua and Windows jobs. 136 Lua sources parsed
under temporary Windower syntax normalization; the full Lua regression
suite passed, including tests/set_name_label.lua for persistent versus
autohidden double-tap captions, full-mode hint icons/text, combined/shoulder
suppression, binder/chooser menu-visible set name and live title update.
Windows 2022 x86 native fixtures, module loading, PS5 AHK discovery/reader
fixtures and package assembly passed. Artifact ID 13956275380 uploaded.
These are mock/static/CI passes, NOT live FFXI testing. Live acceptance
of the new visibility rules remains pending user testing.

The first CI check on commit 8ea6edc, run 43241645917, failed a
mock-only chooser_text assertion because tests/compact.lua left the reused
singleton chooser_open=true. The fixture now explicitly resets that flag to
match the closed-chooser state seen in the game's render pass. Runtime UI
logic was unchanged by this correction. Follow-up run 43241843720 passed.

Runtime change from the preceding set-name overlay is ONLY ui.lua.
A delta overlay may therefore include just ui.lua, with WORKFLOW.md and
TESTING.md beside it inside the xivcrossbar folder. Keep existing saved
settings, prior patch files, AHK and DLLs; overlay ui.lua and run
//lua r xivcrossbar. No full game, controller-reader or DLL restart.
User confirmed //xb banklabeloffset 0 3 looks excellent for Default
Compact and Full; 0 9 is the provisional Legacy Compact reference.
These are observations, not new hardcoded offsets. Potential future layout
names: Full, Compact, Tight. Actual in-game checks requested: legacy
persistent double-taps 5/6 retain set name and full hints; Default/Me
nonpersistent double-taps hide them; combined 3/4 hide; shoulder 7/8/9
hide; binder and Options chooser keep set name, including on live set
switch, while full hints remain hidden in menus. Check autohide/hold,
fade, long names, compact and full.

---

# Current Development Status - Persistent double-tap captions and menu-visible set name

2026-11-12 (America/Chicago), rerorriM-Mirrorer/xivcrossbar,
branch test/set-name-hud-20261112. Starting published source:
79f832454bedc3cbc7279aba9d6bcf2f87c69843.
Read current GitHub AGENTS.md, WORKFLOW.md, TESTING.md.
User confirmed Default Compact and Full trigger captions and set name
look excellent with //xb banklabeloffset 0 3. Legacy Compact appearance
may prefer 0 9. Future layout naming proposal: Full, Compact, Tight.
These are observed tuning references, not new automatic mode-specific
offset settings; the existing position controls and settings are unchanged.

AutoHideExtraBars=false is the Legacy preset setting that keeps double-
tap banks visible. The set-name caption and, in full mode, Share/Options
hints now remain shown while selecting double-tap banks 5/6 only if
AutoHideExtraBars=false. Combined banks 3/4 and shoulders 7/8/9
still hide them immediately. When AutoHideExtraBars=true, double-tap
banks still hide them. The set-name caption remains visible whenever
the binder or set chooser is open, regardless of the preview bank,
and retains live set name updates; full-layout hints stay hidden in
menus. Normal whole-HUD autohide/fade remains owned by geometry.

Changed runtime: ui.lua only. Changed mocked regression:
tests/set_name_label.lua. README and cumulative TESTING.md are updated.
Existing saved offsets, controller bridge, AHK, DLL, other presets,
and binding XML remain untouched. Testing: please exercise persistent
and autohidden extra bank options, combo/shoulder precedence, binder
and Options chooser open/close, immediate title change, both compact/
full, fade/autohold. CI/static status to follow; no live FFXI execution
has been carried out by the assistant.

---

# Current Development Status - Set-name HUD offset command verification

2026-11-12 (America/Chicago), repository rerorriM-Mirrorer/xivcrossbar,
test/set-name-hud-20261112. Successfully verified published code checkpoint
bae90c1845d575c7f134126b24ce0e01b6f183a0 on GitHub Actions run
43237098828. This documentation update does not modify that tested runtime.
Ubuntu Lua regression suite PASSED, including real command-path tests for
//xb setnameoffset: numeric validity, saved offsets, bare status,
reset to 0,0, and isolation of the trigger-label positions; the HUD
mock also passed shared compact/full caption anchors and contextual hiding.
136 Lua files parsed using temporary Windower Lua 5.4 normalization.
Windows 2022 x86 native fixtures and module loading both PASSED (2/2),
AutoHotkey v2 discovery/reader fixtures PASSED, and matched installable
artifact 13953950452 was uploaded successfully. All CI jobs PASSED.
These are static/mock/CI checks, not a Windower/FFXI visual test.

Test/install: GitHub Actions run 43237098828 contains the full-folder
installable artifact. For a minimal UI-only overlay, copy ui.lua,
xivcrossbar.lua, theme.lua, libs/preset_base.lua,
libs/personal_preset.lua, libs/settings_presets.lua and
libs/command_help.lua from the artifact onto matching relative
addon paths, retaining existing data/character settings, and
//lua r xivcrossbar. Do not replace the controller AHK or native DLLs
for this change. Existing saved BankLabelOffsetY=-63 remains until
//xb banklabeloffset 0 0 or a full preset reapplication. Set-name
offset begins at 0,0; //xb setnameoffset <x> <y> changes only
that label. Verify in-game on both Compact and Full, all presets,
with single, combined, double-tap and shoulder banks; check
autohide/hold/fades, job changes, long titles, 4K/laptop clients.
The visual test is pending user confirmation.

---

# Set-name HUD test refinement - independent set-name offsets

2026-11-12. Branch test/set-name-hud-20261112. User requested an
independent position command for the set-name label. Added
//xb setnameoffset <x> <y>, with bare status, numeric validation,
immediate live relayout and character-setting persistence. Default 0,0.
The preset values retain zero offsets and do not alter bank label positions.
Regression coverage checks independent position and reset; the real display
preset test fixture now provides the new UI method. First CI attempt
43236384558 failed in a display-only fixture (nil set_set_name) after
136 Lua sources parsed; this fixture correction is included. Recheck full
CI before claiming automated pass; actual FFXI appearance remains untested.

---

# Current Development Status - Set-name caption and shared label anchors

2026-11-12 (America/Chicago), rerorriM-Mirrorer/xivcrossbar,
branch test/set-name-hud-20261112. Starting published source:
0a5540bcdfc829b533393fd3d314180bfdde4d4f (fix/settings-inheritance).
Read current AGENTS.md, WORKFLOW.md and TESTING.md from GitHub before editing.
Isolated UI test only; existing personal controller baseline is untouched.

Requested: Full Legacy/Default/Me labels share the old Legacy (0,0) baseline;
compact labels align six pixels above the actual bank top regardless of preset.
Current set caption: all uppercase, one font-size smaller than trigger captions,
matching amber stroke and alpha, centered between L2 and R2 on caption rail.
It follows UI scale, fade and set/job changes. It and full-mode Share/Options
hints are visible only when no bank or single L2/R2 is selected; immediately
hidden on combined/double/shoulder banks or addon menus. //xb setname toggles
bare/on/off/status. No clickable chooser entry point is added in this test.

Runtime overlay files: ui.lua, xivcrossbar.lua, theme.lua,
libs/preset_base.lua, libs/personal_preset.lua, libs/settings_presets.lua,
libs/command_help.lua. Back up existing files; keep directory paths, overlay
only the seven Lua files, then //lua r xivcrossbar. No controller-reader restart,
AHK replacement, DLL change, data XML replacement or full client restart.
Preset definitions now use zero offset. Existing saved character settings may
still carry -63; //xb banklabeloffset 0 0 normalizes the position without
resetting other Me settings or bindings. Reapplying Default/Me also resets it,
but may reset other preset preferences.

Mock checks: tests/set_name_label.lua, tests/legacy_extra_bars.lua and
modified tests/xi_layout.lua cover centered caption geometry, visibility and
compact/full switches. Run all Lua suites, parse Lua 5.1 syntax, and inspect
CI before accepting. Live FFXI remains UNTESTED: inspect Full and Compact,
Legacy/Default/Me, 3-6 trigger banks, idle/L2/R2/combined/double/shoulder,
menu open/close, no-trigger AutoHold, autohide and fade transitions; compare
4K and laptop widths and very long set names. Switch/rename sets and jobs;
verify matching alpha/stroke and //xb setname bare/on/off/status, including
opacity 0. Do not claim tests are in-game until user confirms.

---

# Current Development Status - Permissive PS and fresh modifier arrival

2026-11-12 (America/Chicago), rerorriM-Mirrorer/xivcrossbar, branch
fix/settings-inheritance. Starting published source 462002c. Read current
GitHub AGENTS.md, WORKFLOW.md and TESTING.md before editing. Compared old
personal AHK v1 source 52bfa1d directly. User reports restrictive PS behavior
and requests held triggers read as new presses on the destination.

PS: last non-FFXI application with suitable window fallback; last FFXI client
with existing-client fallback on return. No 30-second timer, gameplay/chat/
menu/event gate, recent-PS-departure requirement, or live message-ready gate.
Retains Me PS setting, on/test/off, valid HWND/PID checks, fresh-edge latch,
and old shoulder/trigger chord exclusion. Face buttons and stick motion no
longer block PS. Minimized targets are restored. Hardware must still expose
PS and the selected profile must be PS5 DirectInput.

Held-modifier handoff now routes fresh trigger downs on the destination instead
of directly seeding state flags. Existing combined trigger order is retained.
An imported held double-tap bank starts with a fresh single trigger press;
no double tap is synthesized. Shoulders enter transport as fresh held presses
without firing targeting/set-cycle shortcuts. Already-held switching slot
buttons remain consumed until release; handoff packet sequence dedup remains.
Internal handoff presses may initialize during receiver join before ordinary
message filtering is ready. Focus/readiness/chat/menu guards still apply.

This change does NOT claim to fix the independently reported intermittent
native-targeting leak. Native hook/foreground-quarantine changes are deferred;
no DLL or timeout values change. Test fresh modifier arrival and native blocking
as separate observations. Verification: five focused local Lua suites passed and 135 sources parsed
under Lua 5.4 with temporary Windower syntax normalization. Windows CI run
43215915365 at 192675b8dffd4c83fdd5676de0323a15e3648fdc passed all 52 Lua
suites, x86 native fixtures/module loading, AHK v2.0.19 discovery and actual
reader/profile/lifecycle fixtures including permissive PS decisions. Live
FFXI/window-switch acceptance remains; CI does not exercise your desktop.
This verification entry is documentation-only. Next: PS and handoff acceptance, then native leak capture.

INSTALL: //xb controller stop, overlay Lua/AHK files, //lua r xivcrossbar on
each client, then //xb controller start. No full client restart; keep existing
matching extra-controls DLLs. Existing //xb me settings apply, with //xb me ps
on to enable if needed. No personal data/settings shipped.

---

# Current Development Status - Extra controls routing and Me shortcut tests

2026-11-12 (America/Chicago), rerorriM-Mirrorer/xivcrossbar, branch
fix/settings-inheritance. Starting published source cbd8a21. Read current
GitHub AGENTS.md, WORKFLOW.md and TESTING.md before editing. User reports
previous personal controls feel good; no live acceptance of this batch yet.

Adds negotiated 23-control reader messages and native extra-capture capability.
New logical controls: L3/R3, PS, touchpad click, mute, right-stick Up/Right/Down/Left.
Unassigned inputs remain native. PS keeps its existing private AHK window toggle.
PS5 DirectInput candidates use buttons 11/12/13/14/15 and axes Z/Rz; mute is
driver-dependent and may not be exposed. F710 exposes L3/R3 where available;
no invented fightpad extras. Standard XInput supports L3/R3 and right stick,
not PS/Guide/touchpad/mute. Touch surface gestures and independent paddles
are not available from these joystick APIs. Record InputTrace/diagnostics to
verify actual device outputs; these mappings are not claimed hardware-tested.

Under //xb me: CameraZoom and TouchpadMap default on. Private controls
//xb me zoom on|off and //xb me map on|off save live without addon reload.
L1 first, centered right stick then Up holds period (zoom in), Down holds comma
(zoom out). Native vertical camera movement is suppressed while this shortcut
owns the axis. Release, focus loss, stale lease, disable/menu/test or reader
shutdown releases generated keys. A held stick is not adopted across clients.
L1 + fresh touchpad sends toggle ffxidb once; bare touchpad is unchanged.
Other modifiers, held slot buttons, menus and chat suppress these shortcuts.
Default/Legacy leave both shortcuts off. Existing shoulder correction, PS,
set cycling, neutral/client movement modes and held-modifier handoff remain.
The camera keys assume the user's period/comma bindings, not auto-detection.

All 52 Lua suites passed; 135 sources parsed under Lua 5.4 with temporary
Windower syntax normalization. Host g++ C++17 native fixture and generated
mapping consistency passed. Windows CI run 43209235016 at published
7b29831b09f61b83e241d5e65e905cf2ec5dc952 passed Lua, x86 MSVC native
fixtures, module loading, AHK v2.0.19 discovery and actual reader/profile/
lifecycle fixtures including new zoom decisions and 23-control messages.
Artifact 13939982729 downloaded and its GitHub SHA256 verified. Initial
Windows run found an outdated Lua registration fixture callback count; the
fixture now verifies the extra capability/export and passes. Cleanup was also
reviewed to reset zoom arming on client/reader changes. This verification
update is documentation-only; delivered runtime equals the successful build. Live PS5 input identity, camera
zoom/axis blocking, touchpad toggle, L3 native TargetNPC, client switches,
release cleanup and Default/Legacy native behavior remain to test.

INSTALL: stop reader, close ALL FFXI clients, overlay matched Lua/AHK/native
files, restart clients and use //xb me. This one expanded hook install needs
a client restart. Future Lua/reader changes within these routes can use addon
reload/reader restart without closing FFXI. No data/settings files overwritten.
Rollback: close clients and restore the previous matched runtime/DLLs.
Next: user live acceptance; no configurable action-map UI introduced.

---

# Current Development Status - Shoulder correction

2026-11-12. Repository rerorriM-Mirrorer/xivcrossbar, branch
fix/settings-inheritance. Starting published source 0f46235.
User reports the other personal controls feel good. Restored revision 3
shoulder tabbing only with an existing target; removed R2 TargetNPC dispatch
and command. Old saved R2TargetNPC=true is harmless. Legacy fallback R1
behavior is preserved from before the personal-controls patch. L1+R1 NPC
shortcut remains removed. No native DLL changes: addon reload is sufficient.

Verification: all 51 Lua suites passed and 134 sources parsed under Lua 5.4
with temporary Windower syntax normalization; no live FFXI test performed here. Test untargeted shoulders,
targeted reverse/forward cycling, both shoulder chord orders, R2 with an old
saved flag, and existing PS/set/movement controls. Next: live acceptance and
a separately scoped configurable personal-action map.

Correction to the historical batch below: targetless shoulder cycling and R2
TargetNPC were unintended and are superseded by this entry. Earlier results
are preserved as the record of that delivered build.

---

# Current Development Status - Optional personal controls and combined handoff test

2026-11-12 (America/Chicago). rerorriM-Mirrorer/xivcrossbar,
fix/settings-inheritance. Starting local cbf0827 matches published fc10a3d.
Read current GitHub AGENTS.md, WORKFLOW.md and TESTING.md before edits. The
held-modifier package is still untested in FFXI by the user; this delivery
combines its runtime files and matching newly built native DLLs with this batch.
Trust interpretation is explicitly deferred to the separate Trust conversation.
No Trust files, settings or bindings are changed here.

Me now owns ShoulderBanks.PersonalControls: Enabled, R2TargetNPC, PSButton,
SetCycling and MovementArm. Legacy/Default initialize these disabled with client
movement arming. Me enables them and selects neutral arming; //xb me applies
and reloads as before. Nested test controls do not reload:
//xb me status; //xb me controls on|off; //xb me r2target on|off;
//xb me ps on|off; //xb me sets on|off; //xb me movement client|neutral.
Nested changes require the Me preset; its master OFF disables new shortcuts
and returns movement arming to the original client-focus rule. Existing bridge
movement off/test/on remains available. No public top-level command is added.
Controller profile/device and saved bindings remain preserved.

Removed TargetNPC from both shoulder-target paths. With shoulder targeting on,
L1 sends Shift-Tab and R1 Tab even without a target; simultaneous shoulders do
not acquire an NPC. The combined shoulder bank remains usable. R2 TargetNPC is
optional: a fresh bare R2 press in gameplay with no native menu, other modifiers
or held action targets an NPC, then retains ordinary R2-bank behavior. Adopted
R2 holds across focus do not synthesize this action. InputTest suppresses the
real TargetNPC command. No R2 release or repeat action is added.

Set controls (user selected cycle, not chooser): hold L2 then freshly press L1
for previous; hold R2 then freshly press R1 for next. Uses existing chooser order
and wraps, filters the Add New sentinel and respects Shared visibility. Trigger
first is required; both triggers, held action buttons, setup/text/Trust menus
and repeat downs cannot cycle. A new native capability gates the chord so the
shoulder does not leak into native navigation. Native v1 ABI memory sizes stay
unchanged; hook/policy files must match this build.

PS was rebuilt as controller_ps.ahk. User selected bare PS only, no shoulder-PS
combos. One global physical edge latch spans focus changes. A valid foreground
non-FFXI window is remembered; bare PS from eligible gameplay selects it and
arms a 30 s return to the originating FFXI HWND/PID. Release and press PS again
outside to return. Invalid/reused handles, desktop/taskbar, expired returns,
held PS, chords, inactive/test/off modes and non-PS5 profiles cannot activate
unintended windows. Test mode only reports the decision. Outside polling uses
the existing profile-slot reader, not a hardcoded device-number PS read. Visit
the preferred non-FFXI window with Alt-Tab once so the reader can remember it.

Movement: client preserves one signal per client-focus session after stable
center. Neutral emits at most one signal per centered-to-movement gesture.
Center threshold <12%, movement threshold >=24%, stable-center interval 100 ms.
A held/uncentered stick cannot repeatedly signal. Neutral consumes an attempt
even when Trust/eligibility is unavailable; no delayed replay after readiness
changes. Client mode retains its prior readiness retry semantics. The exact
30 ms vk1D/sc07B pulse and matching Trust receiver lease remain unchanged.
See docs/TRUST-STICK-HANDOFF.md: park/stop semantics, idempotent receipts and
movement-owned cleanup belong to Trust and are not implemented by this patch.

All 51 local Lua suites passed (134 sources parsed with temporary Windower
syntax normalization under Lua 5.4); final targeted routing/preset/bridge reruns
and host g++ C++17 native fixtures passed. Windows 2022 CI run 43193701625 at bca4f2778b7e6cc30dca21400925c7d83f39fe03
passed both jobs: complete Lua regression, x86 MSVC build/native fixtures,
pinned AutoHotkey v2.0.19 discovery and real reader/profile/lifecycle fixtures,
including new PS and stick-arming decisions and the inherited focus handoff.
Artifact 13932391017 downloaded with its GitHub SHA256 verified. The original
windows-latest run remained queued, so the native workflow is now pinned to
Windows 2022 for reproducible builds. This verification update is docs-only. New AHK fixtures test
client/neutral arming, PS latch/return/chord/expiry/off decisions and existing
held-modifier focus transfer. No live FFXI or real desktop PS switching pass
is claimed. Existing timer text-settling flicker remains a separate pending fix.

INSTALL: combined incremental package over the preset/layout build; installing
fc10a3d separately is NOT required. Stop shared reader with //xb controller stop,
unload XIVCrossbar and CLOSE ALL FFXI processes before replacing native DLLs.
Back up addon files; overlay the matching xivcrossbar folder; restart FFXI,
load XB per client, start the reader if needed, then //xb me to activate this
test group. Begin with all buttons released. No settings/hotbars are overwritten.
Rollback requires closing FFXI and restoring matching Lua/AHK/native files.
The optional global Me XML is separately supplied, never auto-installed.
WORKFLOW.md and cumulative TESTING.md remain inside the addon payload.

Live: first test held L1/R1/L2/R2 transfer, including combined/double banks and
consume-until-release switching buttons. Then test individual Me switches,
R2 TargetNPC, targetless Tab/Shift-Tab and no combined-chord NPC acquisition.
Test set cycling order/wrap and unchanged bindings. Test PS outside/back with
release, chords and stale windows. Use bridge movement test mode to compare
client and neutral cadence before enabling real Trust messages. Verify Default
and Legacy disable personal controls, bare gameplay remains native, and old
partial installs do not advertise the new set-chord capability.

---

# Current Development Status - Held-modifier handoff between FFXI clients

2026-11-11 (America/Chicago). rerorriM-Mirrorer/xivcrossbar,
fix/settings-inheritance. Starting local source 63d6169 matches published
37ce5f1. Current GitHub AGENTS.md, WORKFLOW.md and TESTING.md read before edits.
User reported L1 held across a window switch was lost while native D-pad input
reached the destination. Requested all four logical modifiers to carry, while
already-held action buttons remain consumed until release. The prior Legacy
layout/preset fix is included in the source baseline; this is a controller batch.

Reader: a direct FFXI-to-FFXI switch snapshots held logical L2/R2/L1/R1 and the
last published active trigger bank. On a matching capable destination lease,
only modifiers still physically held are adopted. All other currently-held
buttons are seeded without down edges, so they must be released and pressed
again. Ordinary startup, reconnect and non-FFXI transitions retain neutral
rearming. Existing mappings, controller profile selection and slot scanning
are unchanged. Alternate R1-as-chooser mappings retain their existing semantics.

Lua: token-checked resume records restore modifier/bank state directly, without
routing synthetic presses, opening double-tap windows or shoulder targeting.
Double-tap and ordered combined banks are retained where the destination's
trigger layout supports them; otherwise its normal compatible bank is used.
Receiver validates mask/range/sequence/token, and ignores duplicate records.
Source lease cleanup releases old ownership. Old DLLs do not advertise the
handoff capability, so readers retain neutral gating rather than half-enabling.

Native: the matching hook and policy adopt preheld modifiers without action
edges, quarantine already-held action buttons through release, and cover the
foreground-to-Lua heartbeat gap. DirectInput state/buffered and XInput paths
share suppression policy. The v1 policy ABI memory layout is unchanged. A new
module capability field gates Lua/reader handoff. Native build workflow now runs
for this development branch to build x86 DLLs and execute Windows/AHK fixtures.

Local verification: all 50 Lua regression suites passed and 132 sources parsed
with temporary Windower syntax normalization under Lua 5.4. New tests exercise
all modifier masks, bank preservation, fresh input, invalid/duplicate records
and the real adoption callback. Host g++ C++17 native fixture passed, including
focus-gap quarantine, modifier combinations and consume-until-release after
modifier release. Windows CI run 43139719439 at published source d5d4ea42f7bbe32f5fee77b87cdeed14cf49eee9
passed both jobs: all Lua suites, x86 MSVC build/native fixtures, pinned official
AutoHotkey v2.0.19 discovery smoke, and real AHK reader/profile/lifecycle plus
handoff fixtures. Downloaded artifact 13909251690 matched its GitHub SHA256
and passed ZIP integrity checks. Packaged DLLs are x86 and taken directly from
that build. No live FFXI handoff success is claimed. This verification update
changes documentation only; runtime source is identical to that CI checkpoint. Canonical ASCII chat-output convention is adopted here.

INSTALL: This batch changes the loaded native bridge DLL. Stop the shared
reader, unload XIVCrossbar on every client, and CLOSE ALL FFXI processes before
replacing native DLLs; Lua reload alone cannot replace the loaded hook. Back up
the current addon/native/reader files. Overlay the matching controller patch,
restart FFXI, load XIVCrossbar on each client and run //xb controller start once.
Start with all buttons released. Keep profile/device consistent across clients.
No settings/hotbars are replaced. Roll back by closing FFXI and restoring the
backed-up Lua, AHK and DLL files together. Do not mix hook/policy versions.

Live acceptance: on two clients, hold each of L1, R1, L2 and R2, use a bound
window-switch action, and keep the modifier held. Destination should display
the matching bank, with no native D-pad/face leak or repeated switch. Release
only the action and press a fresh action without releasing the modifier. Repeat
both triggers, both shoulders, double-tap trigger banks and 4/6-bank trigger
order. Release modifier before the switching direction and verify that direction
stays blocked until released. Check rapid round trips, chat/addon menus, leaving
FFXI for another app, disconnect/reconnect, reader stop/restart and foreground
changes with no modifier. Native bare gameplay should remain normal.

Pending separate issue: the timer text-settling blink from the provided render
capture is not part of this controller change.

---

# Current Development Status — ASCII reload feedback and Legacy bank spacing

2026-11-11. Repository rerorriM-Mirrorer/xivcrossbar, branch
fix/settings-inheritance. Starting local checkpoint cb77d9d is source-identical
to published 89bec17. Current GitHub AGENTS.md, WORKFLOW.md and TESTING.md read
before editing. User live report: preset reload feedback rendered the UTF-8
em dash as an unwanted Japanese character. Requested capitalized plain messages,
Legacy compact bank labels matching Default/Me placement, extra bars farther
outward, and smaller vertical separation in compact only. Full Legacy labels
were reported good and their relative placement is retained.

Feedback is now exactly [XIVCrossbar] Default reloading, Legacy reloading,
or Me reloading. No dash or other non-ASCII character is emitted by these
three preset confirmations. Other existing messages are outside this change.

Legacy's extra banks retain regular cross geometry and move 90 logical pixels
outward on each side. Full layout retains the configured -180 vertical offset;
compact uses 60% of that offset (-108 with current Legacy settings), reducing
the gap while keeping the pair above and outside the regular bars. Switching
compact/full recalculates all slot surfaces and labels through existing layout
machinery. No extra offset accumulation or new saved-setting fields are added.
Legacy compact headers anchor six pixels above the actual top of each bank,
matching Default/Me's compact gap despite Legacy's different slot row order.
Full Legacy header placement and regular bar positions remain unchanged.

Targeted checks pass: actual command branch emits exact ASCII captions and
saves/reloads once; invalid arguments cannot reload. Legacy geometry checks
cover both extra banks/all slots, three full/compact round trips, preserved
full labels/artwork and matching Default/Me header gaps. All 49 regression
suites passed in one complete run; all 131 Lua sources parsed with temporary
Windower syntax normalization under Lua 5.4. Git diff whitespace checks pass.
No Windows, Lua 5.1 or live FFXI fix confirmation
is claimed. The prior diagnostic also identified timer text-settling blinks;
that is a separate pending repair and is not changed in this batch.

Install: incremental patch over the Settings Presets build. Unload XIVCrossbar
on each client, back up replaced code, overlay the xivcrossbar folder, and load.
No settings/hotbar data or AHK/native files are supplied; no controller or FFXI
restart is needed. Existing Legacy settings are adapted at render time, so
there is no need to replace settings.xml or reapply the preset to get spacing.
Rollback by unloading and restoring the backed-up code. WORKFLOW.md, TESTING.md
and README.md accompany the payload inside the addon folder.

Live acceptance: invoke //xb default, //xb legacy and //xb me and check the
capitalized readable messages. In Legacy compare full and compact, including
several toggles: unchanged full labels, compact labels above their bars, extra
pair wider than the main pair and closer vertically when compact. Check normal
HUD scale and small windows, captions/recasts remaining attached to their slots,
and no drift after repeated toggles. Verify Default/Me appearance is unchanged.

---

# Current Development Status — Legacy / Default / Me settings presets

2026-11-11. Repository rerorriM-Mirrorer/xivcrossbar, branch
fix/settings-inheritance. Starting local checkpoint cda8a49 is source-identical
to published 2d78c17. Current GitHub AGENTS.md, WORKFLOW.md and TESTING.md read
before edits. User confirmed the gold success flash looks great. Publication
permission was explicitly granted; the earlier push block is superseded.

Commands: //xb legacy, //xb default, //xb me. Each applies a complete owned
settings snapshot, saves for the current character and gracefully reloads Lua.
Controller profile/device and input-test/trace selections are preserved. Saved
hotbar bindings, custom actions and XML set names are never rewritten. Existing
//xb new <name> still creates a named set. //xb display retains its existing display/visibility behavior.
Fresh-install defaults now come from the Default preset; existing saved settings
continue to override missing-value defaults normally. Presets explicitly reset
the fields they own, so personal values cannot leak into another preset.

Legacy: original full layout and original trigger artwork; Show visibility;
extra double-tap pair aligned above regular bars, 180 logical pixels higher;
Shared on; shoulders/targeting off; event bars off; original set names. Upstream
master xivcrossbar.lua explicitly hides at status 4. Upstream chooser selects
the alphabetically first non-fallback set (usually Basic), not a hardcoded Main.
That startup rule is retained, with our existing safe fallback for sparse files.
Five trigger banks are used so the requested always-visible extra pair exists.
This is an intentional presentation exception to upstream's three-bank default.

Default: XI compact, On Input, Auto hold 0, Shared on; same legacy startup rule;
shoulders and shoulder targeting off; held bars available during events; extra
bars hidden until used; trigger scaling and slot glow on. Me: uploaded global
snapshot plus Cioara overrides, XI compact/Always, Auto hold 3, Shared off,
job/subjob fallback set (internal default) selected on reload, shoulders and
targeting enabled, event bars available, skillchain/lockout indicators hidden.
If the job/subjob fallback is absent, safe legacy selection is used.
Default/Me use newer display labels; named-set XML content is preserved.
All three keep subdued bank labels, recast-ready flash and gold success flash.
Slot rumble and L2/R2-to-L1/R1 navigation changes remain deferred.

The separately supplied optional-settings/settings-me-global.xml is NOT an
automatic install payload. It contains one global section with Cioara overrides
folded in, Shared off and job/subjob startup; no character sections. It retains
the uploaded PlayStation 5 DirectInput / Device 2 selection. To use it, unload
XIVCrossbar on every client sharing this folder, back up data/settings.xml, copy
this file there as settings.xml, then load. This deliberately replaces existing
character overrides. The normal //xb me command preserves hardware selection.

Source for personal values: settings(20261111-220202).xml (uploaded this chat).
No hotbar/custom-action user data are included. Testing package: incremental
code patch over current development build; WORKFLOW.md, TESTING.md and README.md
inside xivcrossbar; optional settings kept outside the installable addon folder.
Back up replaced code before overlay. Preset commands reload the addon; no FFXI
or AHK restart is needed. Rollback: unload and restore code/settings backups.

Verification: across the full-suite run and targeted reruns, all 48 regression
suites passed; all 130 Lua sources parsed through temporary Windower syntax
normalization under Lua 5.4. Checks include all nine preset transitions,
controlled resets, hardware preservation, actual chooser startup selection,
legacy extra-bank coordinates/artwork and updated fresh defaults. Five existing
fixtures now explicitly specify old starting layouts, disabled glow, event-bar
expectations or configured label opacity instead of assuming old defaults.
Standalone XML parsed and checked for global-only scope, folded overrides and
requested Me values. Git diff whitespace checks pass. No Windows, AHK, Lua 5.1
or live FFXI preset test is claimed.

Live acceptance: switch legacy -> default -> me -> legacy; verify labels,
startup set after reload, Shared chooser visibility, shoulders,
event behavior, extra-bank separation, both flashes, animations and indicators.
Verify existing bindings are intact, controller selection unchanged, and test
small windows/HUD scale. Independently try the optional global settings copy
with backups and confirm no previous character overrides remain active.

---

# Current Development Status — Gold-white confirmed-action flash

2026-11-11. Repository rerorriM-Mirrorer/xivcrossbar, branch
fix/settings-inheritance, starting source checkpoint 729bb68. Lua-only visual
batch; existing AHK/native companion versions are unchanged. Current GitHub
AGENTS.md, WORKFLOW.md and TESTING.md were read before this work. The final
local commit is identified in the delivery; it is not a published remote head.

Requested: a white outer glow with a slightly more opaque golden-white center,
about 2–3 times slower than recast-ready feedback, on confirmed Attack/Disengage,
Summon/Release, Assault/Retreat, Trust/Return, weaponskill execution and completed
uninterrupted spells. Implemented 0.4 s fade (ready flash remains 0.15 s), white
border alpha 156, center RGB 255/235/174 alpha 184. Existing textures are reused;
success and ready animations have independent lifetimes. New cooldowns cannot
cancel the success fade. The overlay follows bank scale, position and opacity.

One pending request is armed from the actual accepted typed slot action,
resolved against the pre-press pet/trust state. Another press replaces it.
Own spell/WS/JA completion packets are matched by category and resource ID;
WS misses and spell resists still count as execution. Cast interruption cancels.
Requests expire after 3 s unless a matching spell-start packet extends the cast
window to 30 s. Other actors, custom macros, items and unrequested actions do
not independently start this feedback. Attack, Assault/Retreat and Return use
observed player/pet/party transitions; Release also accepts its own action packet.
Confirmation is queued through the next render tick so an automatic summon or
Release environment reload does not erase it before it can be drawn. Hidden
banks, menus, slot reloads, zones, jobs, logout and unload clear stale feedback.

Packet/state correlation is bounded and intentionally conservative, not a new
action scheduler: changing sets or pressing another action can discard an older
pending result. A delayed avatar-swap sequence can outlive its initial request
window; do not infer a failed summon merely from absence of this visual.
Arbitrary macros and other pet abilities are outside this first success batch.

Verification: all 46 regression suites passed in the temporary Windower-syntax-
normalized Lua 5.4 harness; all 125 Lua sources parsed. The new tracker/UI tests
cover actor/ID matching, interruption, expiry, duplicates, state transitions,
independent cooldown timing and hidden/rebound cleanup. After inspecting the
existing textures, the success border uses the original recast-glow asset; the
tracker, success UI and recast suites were rerun after that final texture choice.
Two existing event-extraction fixtures gained mocks for the new tracker.
Git diff whitespace checks pass.
No live FFXI, Windows renderer or Lua 5.1 pass is claimed. Last user-confirmed
behavior remains stable current play and the earlier grey availability feedback.

Install this incremental patch over the current public development installation
(including the previous Blood Pact MP patch). Unload XIVCrossbar, back up the
replaced files, overlay the xivcrossbar folder, then load it on each client.
Do not replace data/hotbar/settings folders. No FFXI or AHK restart is required.
Rollback: unload, restore those files, remove libs/action_success.lua if newly
added, then load again. WORKFLOW.md and this cumulative record accompany the
payload inside the addon folder. Public directory restructuring remains deferred.

Live acceptance: try Attack then Disengage; summon then Release (including an
automatic pet-set switch); Assault then Retreat; summon/return a Trust; a WS
that hits and one that misses; a normal completed spell, a resist and an
interrupted cast. Verify the gold center fading over the start of recast,
white border, hidden-bank/menu behavior, compact/full layout, HUD scale/fades,
and no flash from party actions or a rejected command. Check a long cast and
fast consecutive presses. Report timing, opacity and whether the border reads
clearly at normal playing scale before extending to other pet actions/items.

Publication remains local: an earlier automatic approval review rejected the
GitHub push because the destination/private-source publication was unverified.
No push is retried in this batch.

---

# Current Development Status — Personal three-character hotbar data overlay

2026-11-11. Code baseline fe2a2b9 on fix/settings-inheritance; no runtime code change.
User-provided hotbar(1).zip SHA256 736e71c87d33246561c4ee7a74bc0422463af61d9b13643259bde34e7a1acefd.
Data-only payload: Shared.xml, CustomActions.xml and WHM-DEFAULT.xml for Cioara,
Myrr and Clairvaux. L1 Down stop-follow; Circle trust pauseall; Triangle explicit
stopall/echo/follow-me sequence. Both banks based on Cioara, R1 Up mount-all.
Remove only the three WHM L2-double-press NPC overrides. Preserve Ready, All Jobs
Default and unrelated job bindings/catalog entries. Corresponding catalog records
updated alongside inline commands. No mount/follow coupling in this batch.

Nine XML parse/roundtrip and structural checks passed; shoulder banks identical;
non-targeted Shared/catalog content unchanged; WHM changes exactly the requested
removals. Trust command source on test/party-stealth checked for native pauseall
IPC; follow stopall/mount-all source inspected. No FFXI live pass is claimed.
Install precautions and rollback are in INSTALL-HOTBAR.md inside the payload.
Unload XIVCrossbar on all three clients before overlay, preserve current folders
as backup, then load again. No FFXI/reader restart. Personal data is delivered
as a separate artifact, not added to repository defaults or public runtime.
This documentation commit remains local pending earlier publication approval.

---

# Current Development Status — Blood Pact MP display

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Starting checkpoint `53074ee`. User reports missing MP costs on Blood Pacts.

2026-11-11 delivery: `XIVCrossbar-Blood-Pact-MP-Patch.zip`.
The resource generator hardcoded every job ability's MP cost to zero. Generate
Windower MP values for BloodPactRage/BloodPactWard only; preserve zero for Monster
entries whose mp_cost represents Ready charges. The crossbar's initial cost
label and ongoing affordability checks now resolve pact MP directly from installed
Windower job_abilities, so old generated caches work immediately without deletion
or a forced regeneration. Existing MP colours, hide-cost settings and insufficient
MP treatment are retained. Spell/WS and arbitrary macro behavior stay unchanged.
These are resource/base MP costs; dynamic/gear-adjusted costs are not calculated.

Validation: 44 mocked Lua suites passed; 122 Lua sources parsed under Lua 5.4
with temporary Windower syntax normalization. New tests cover Rage and Ward,
legacy cached zero values, zero-base-cost entries, Ready-charge exclusion and
spell/ability ID collisions. Existing UI/layout/cost regression suites pass.
No in-game FFXI confirmation or Windows/Lua 5.1 execution is claimed.

Overlay on current build, reload XIVCrossbar on every client. No FFXI or reader
restart, and no user-data files are supplied. Live: check one Rage and one Ward
with a positive base MP cost; verify normal MP colour and insufficient-MP state,
Hide Action Cost, and existing recast behavior. Zero-base/dynamic pacts should
not receive an invented cost. Source checked: Windower/Resources job_abilities;
restore code/layout and controller behavior otherwise unchanged. Local publication
only pending the earlier GitHub push approval. Directory restructure remains deferred.

---

# Current Development Status — All-profile-slot reading survives normal commands

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Starting checkpoint `77bcfcc`. User observed normal input with the opt-in reader
but no scan row; uploaded controller-all-slots.log proves slot-2 scans between
10:55:28 and 10:59:36 UTC. Uploaded controller-status(1).ini has no scan markers,
so it cannot establish the same writer. User then changed PS5 device to 1, which
could restart the old single-device reader. User now authorizes all backend slots
regardless of selected device number, including normal startup/profile commands.

2026-11-11 delivery: `XIVCrossbar-All-Slots-Integrated-Patch.zip`.
Normal ffxi_directinput.ahk always scans the selected profile's backend. The
controller-all-slots.ahk entry remains a compatible alias, no longer required.
Status always publishes scan_mode and reader_build=profile-slots2, reader script
and connected/active slots. The source log includes PID/script to correlate
writers. All-slot Lua status matching ignores device-number differences, while
profile/protocol/liveness remain mandatory. Reader leases also retain profile
validation but no longer reject a client because its saved device differs.
Device-only selection therefore preserves a matching all-slot reader. Profile
changes may restart it but always return to full backend scanning. Legacy readers
without scan_mode retain strict number matching and must be stopped for upgrade.

IMPORTANT: this removes reader/lease number gating, not native guard attachment
selection. Status labels the saved number Guard Device, with Running / All Slots
and Reader Slots showing the sampling scope. Device 1 can still affect the native
hook's attachment even while the reader gets input from physical slot 2. Automatic
native matching/multi-device filtering is NOT implemented. Check native leakage
when testing additional pads; do not interpret reader acceptance as proof that
all game-side devices are intercepted. Each profile still uses one mapping and
one backend. Same-profile multi-source held states retain any-down/all-up logic.

Install: `//xb controller stop`, wait for exit, overlay ZIP, then reload
XIVCrossbar on clients and run `//xb controller start` if needed. Normal startup
now starts the scanning reader. No manual AHK test launch or FFXI restart.
Check `//xb controller status` for Reader Slots / All profile slots. Try selecting
PS5 device 1 while the pad remains in slot 2: input sampling should continue,
with connected slot 2 reported. Check other clients with differing saved numbers,
reconnect, duplicate presses, holds and native leakage. If status is odd, send the
new controller-status.ini and controller-all-slots.log; marker/PID/script fields
now permit correlation. Rollback requires restoring prior reader and messages
files plus controller_profiles.lua/xivcrossbar.lua from the preceding test ZIP,
stopping and restarting the reader. That restores opt-in behavior.

Verification: 43 mocked Lua suites and 120 normalized Lua 5.4 parse checks. New
runtime profile-matching test proves an all-slot reader accepts numbers 1/16 when
status says 2, rejects a different profile/protocol, preserves the running process
for a device-only request, and retains legacy/stopped-reader rules. Existing
DirectLink source expectations updated to require profile ownership without
number gating. Windows harness now requires all-slot/build markers for ordinary
launches and profile restarts; single-slot decode fixtures call the single-slot
reader directly. Windows/AHK tests remain unexecuted (no interpreter available).
No new live/hardware pass is claimed. Mapping generation check passed.
Publication remains local pending earlier GitHub push approval.

---

# Current Development Status — Selected-profile all-slot reader experiment

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Starting checkpoint `149b10e`. User authorizes scanning all addresses for the
selected profile/backend, without cross-profile mapping detection or mixing.

2026-11-11 delivery: `XIVCrossbar-All-Profile-Slots-Test.zip`.
Normal launcher remains single-device. Optional `controller-all-slots.ahk`
starts the same shared reader with all-slot mode enabled. It retains the saved
profile, reads only that backend (WinMM/DirectInput addresses 1–16 or XInput 1–4),
and applies the unchanged profile mapping to every address. Raw per-source input
is combined into one logical stream after mapping: any-source down, all-sources
up. There is no per-source profile inference or PS/Xbox mapping combination.
Newly connected sources must release all mapped buttons and PS before acceptance.
Disconnected sources drop their held state. Movement uses the strongest single
source vector rather than adding axes; PS retains correct pressed/released edges.

The same existing mutex prevents competing readers. Existing focus, DirectLink,
menu/Trust and last-client lifecycle paths remain. Test startup clears a stale
stop marker only after acquiring the mutex. Status and unified diagnostics add
scan mode/connected/active slot fields. Source changes go to
`data/controller-all-slots.log` (bounded at 2 MiB). Entries contain profile,
connected/active slots and per-slot 14-button bitmasks/PS state; they do not prove
physical identity or distinguish virtual duplicates automatically.

IMPORTANT: saved device number/status matching and the native guard attachment
remain unchanged for compatibility. Reader sampling ignores that number in test
mode. Another pad may still leak native input because the game/guard attachment
has not been redesigned. This experiment measures overlap and input acceptance;
it does not establish automatic native matching. Near-simultaneous duplicate
sources may still produce extra edges if their reported holds do not overlap.

## Install and try (FFXI may remain open)
1. Run `//xb controller stop`, wait for the current reader to exit (about 2s).
2. Overlay this ZIP's xivcrossbar folder on the current installation. Keep data.
3. Run `controller-all-slots.ahk` from inside the xivcrossbar folder with AHK v2.
   It reads the saved profile from data/controller-launch.ini. Do not change
   profiles during this run: the addon's profile switch starts the normal reader.
4. Reload XIVCrossbar on clients for the added status/diagnostic fields. A running
   test reader already matches the saved profile and is retained by startup.
5. Release controls, focus FFXI, run `//xb controller status`; Reader Slots should
   say All profile slots (test). Device number still describes the saved/native
   selection; it is not the test reader's input gate.
6. Try one controller, reconnect it, then additional compatible controllers over
   USB/Bluetooth. Check buttons, trigger banks, menus, holds, client switching,
   duplicate actions and native leakage. All addresses use the selected profile:
   a different-model pad is not automatically assigned a different mapping.
7. Send data/controller-all-slots.log plus a unified diagnostic if anything is odd.
Rollback: `//xb controller stop`, wait for exit, then `//xb controller start`.
That starts the regular single-device reader again. No FFXI restart is required.
To restore original files entirely, restore ffxi_directinput.ahk from the previous
build; the optional extra scripts can remain unused.

## Verification and limits
Five mocked Lua suites passed (diagnostics, runtime launch planning, startup
notices, client registry and profile lifecycle); all 119 Lua files parsed after
temporary Windower normalization. Mapping generation check and include closure
checks passed. Normal and test entry points resolve their seven/eight script
include closures respectively. Python packager compiles. Windows AHK regression
fixture extended for overlap, final-source release/disconnect, neutral arming,
slot 16, XInput range restriction and no-device behavior. Its staging harness now
copies controller_slots.ahk. THESE AHK TESTS WERE NOT EXECUTED: no Windows/AHK
runtime is available here. No controller or live FFXI acceptance is claimed.
Run tests/public_ahk_v2.ps1 with an AHK v2 interpreter on Windows for those checks.
This is an opt-in experiment, not the public beta release default. Earlier
settings write-path/release packaging work remains pending. Commits remain local
pending the earlier GitHub publication approval.

---

# Current Development Status — Black Magic and Summoner binder restoration

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Starting checkpoint `3cfe04b`; GitHub head remains the older published baseline
pending the previous push approval. User reports Black Magic alphabetic ordering,
unorganized/unfiltered Blood Pacts, and spirits mixed into the summon list.

2026-11-11 delivery: `XIVCrossbar-Binder-Magic-Pacts-Patch.zip`.
Black Magic joins White Magic/Bard songs in ascending resource-ID order.
SummonerPact entries put all regular summons before spirits, with ascending ID
inside each group. Blood Pact Rage/Ward now use the prior Pact Binding 1 helper
and level catalog from published source `9f6eac6`: current main/sub SMN level
plus learned, level-eligible summon spells determine binding eligibility.
No pet or active Astral Flow is required to list/bind those pacts. Sort eligible
pacts by required level, then avatar name, then ID. Preserve entry IDs/targets,
custom artwork and generic/shipped Rage/Ward fallback icons. Missing JP data in
the shared spell chooser now defaults to zero. Existing binding assignments and
execution requirements are unchanged.

Catalog provenance: `libs/blood_pact_levels.lua` restored verbatim from
`9f6eac6` (GitHub blob `21160111d73b499b0b0b4278aebfbf2b095c8ddb`). Original
level data derives from LandSandBoat abilities.sql plus official Siren Ward
levels, as documented in the prior personal Pact Binding 1 delivery. This batch
restores that catalog rather than claiming a new current-data audit. Unmapped
pacts remain omitted; merits/JP/Astral Flow remain game-use restrictions, not
additional binding filters. Wyvern/other pet actions do not enter SMN lists.

Validation: 42 mocked Lua suites passed; 119 sources parsed under Lua 5.4 after
temporary Windower syntax normalization. New test executes the actual Rage/Ward,
Black Magic and summoning chooser functions with mocked UI/game data; exercises
main/sub SMN levels, learned/unlearned avatars, above-level exclusion, no native
pet-availability dependency, summon group order, missing JP data, targets and
icon fallback. Existing Trust/White Magic/Song sorts and UI regressions pass.
No live FFXI, Windows or Lua 5.1 execution is claimed.

Install as an overlay on the current build, then reload XIVCrossbar on every
client. No FFXI restart or reader change. Cumulative payload includes preceding
config/availability/flicker changes plus two Rage/Ward fallback icons. User data
is not supplied. Live: check Black Magic order, both pact lists without a pet,
with/without Astral Flow, and the summons/spirit boundary. Verify learned avatars
and level-eligible pacts, then bind one entry and check its target/label/icon.
Flicker-fix live confirmation and all-address reader experiment remain pending.

---

# Current Development Status — Availability colour flicker repair

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Starting checkpoint `3b4d954`. User reports flickering on Cioara and supplied
`client-20261111-090448-656456-2-client.log` (Library source
`libfile_8eb5eb0983548191b76aaead5e2f284a`). Read the attached copy directly.

2026-11-11 evidence: 30-second diagnostic, 1715 frames, full render ring had
51108 overwritten records. Retained drawing entries span the tail of the capture
and contain 5999 native.color calls, with 2999 object/frame pairs containing
both 255/255/255 and 130/130/130. Visibility is Always at both endpoints.
This proves repeated opposing drawing calls, not which pixels Windows displayed;
it does not establish the absence of earlier visibility transitions.

The preceding availability change reset icon/label colours before applying grey
on each frame. Windower may draw between setters. Remove the early icon reset
and choose the final icon/label colours once at the end of each slot update.
Keep normal/menu shades, grey availability, original label colours on recovery,
existing pet/trust cues and geometry/fades unchanged.

Validation: 41 mocked Lua suites and 115 Lua source parse checks under Lua 5.4
with temporary Windower syntax normalization. The availability test executes
the actual final-colour block, requires one write per icon/label, checks recovery
and menu shading, and rejects the original early reset. UI regression suites
cover existing layouts and fades. No live FFXI confirmation or GPU capture.

Delivery: `XIVCrossbar-Availability-Flicker-Patch.zip`; overlay current build and
reload XIVCrossbar on every client. No FFXI restart or native/reader update.
Includes current companion/config files for consistency. Live: leave the same
unavailable slots visible on Cioara; confirm stable grey, then change availability
and open/close the binder to check normal/menu colours. If flicker persists,
repeat the diagnostic while it occurs. All-address AHK experiment remains deferred.
Local commit only: GitHub publication remains pending earlier push approval.

---

# Current Development Status — Grey availability and controller wording

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Starting checkpoint `e47d8e0`. User confirmed synced red tint worked, then chose
the original grey for all availability causes; pink is deferred.

2026-11-11 delivery: `XIVCrossbar-Grey-Controller-Messages-Patch.zip`.
Known JA/WS availability now uses the game's lists regardless of Level Sync;
missing known actions use grey (130/130/130) instead of red. Ordinary pet-command
and existing pet/trust availability rules remain. No bindings are rewritten.
Spell eligibility and arbitrary macro interpretation are not expanded here.

Visibility feedback and status display `On Input`, `Always`, or `Hidden` while
saved values remain unchanged. Normal startup feedback is `Starting controller...`,
`Controller ready.` (green after a matching connected ready heartbeat), and
`Controller already running.` A cancelled launch cannot announce ready. A bounded
10-second readiness check reports a missing controller or incomplete readiness
with `//xb controller status` as the next step. Normal startup no longer includes
the device/modifier string; detailed status retains profile and device selection.

Checks: 41 mocked Lua suites and 115 temporarily normalized Lua 5.4 source parse
checks. New tests exercise actual startup code with observed heartbeat, duplicate
start, selection mismatch, cancellation, missing device and absent heartbeat;
formatting checks verify green survives chat formatting and visibility captions.
Availability tests cover both synced and unrestricted characters. No Windows,
Lua 5.1 or live FFXI validation is claimed for this batch.

Install over the current working build; reload XIVCrossbar on every client.
No FFXI restart. Prior config ownership changes are included for a coherent overlay.
Live checks: show/auto/hide feedback, startup with pad connected/disconnected,
and JA/WS grey/restoration inside and outside sync. Last user-confirmed visual
checkpoint is the preceding red availability build; grey revision is pending.
GitHub publication remains blocked pending the earlier explicit push approval.

Message audit proposals (not changed in this batch): replace shared-wrapper stop
request with `Stopping controller for all clients...`; make selection mismatch
feedback name a corrective command; reduce repeated selected/running fields in
normal status while retaining diagnostics; make native-hook failures state the
specific recovery action. Preserve diagnostic detail rather than hiding faults.
Next separate experiment: all-address input aggregation in the AHK reader.
That experiment is not included in this payload.

---

# Current Development Status — Synced action availability tint

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Starting checkpoint `6960169` includes the prior config ownership repair; that
commit remains local because automatic approval review rejected its GitHub push.
User approved dimming/red treatment for abilities and WS unavailable under sync.

2026-11-11 delivery: `XIVCrossbar-Synced-Actions-Patch.zip`.
While buff 269 (Level Sync) or 143 (Level Restriction) is active, sample
`windower.ffxi.get_abilities()` every 250 ms. Known job abilities (including
job-ability-backed pet actions) and weaponskills absent from their respective
lists receive a dim red icon tint and muted red label. Linked custom actions
use their linked metadata; arbitrary macros, spells, unknown actions and ordinary
pet commands are unchanged. No bindings or action dispatch are altered.
Availability restoration resets the tint; unavailable slots do not advertise
skillchain opportunities or recast-ready flashes. Missing API/list data leaves
the availability cue inactive rather than guessing. The game's lists can reflect
weapon/unlock restrictions as well as levels; red means unavailable under the
current restriction, not proof of a specific level requirement.

Validation: 40 mocked Lua suites passed. 114 Lua sources parsed under Lua 5.4
with temporary Windower syntax normalization. New tests cover list membership,
JA/WS ID separation, learned pet actions versus pet commands, linked actions,
unknown metadata, empty/missing lists, sync/restriction removal, tint restoration
and the actual UI sampling block. Full existing UI, Auto hold and config registry
regressions passed. No live FFXI or Lua 5.1 execution was available for this batch.

Install over the current working build and reload XIVCrossbar on every client;
no client restart or native/reader update. Package includes the earlier config
ownership files to keep this overlay coherent. No data/settings are supplied.
Live check: bind one low-level and one higher-level JA/WS, enter sync, verify
only unavailable actions tint, change synced level, then remove sync and verify
normal colors return. Check a bound WS after a weapon change while synced and
confirm recast dimming, compact/full layouts and fades remain readable.

References checked: Windower/Lua wiki FFXI-Functions (`get_abilities`) and
Windower/Resources `resources_data/buffs.lua`; existing GearSwap consumers use
these numeric ID lists. Current installed game-list refresh timing needs live
confirmation. Prior malformed XML/concurrent saves investigation remains open.

---

# Current Development Status — Config registry ownership repair

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `fix/settings-inheritance`.
Source checkpoint: `c01ba0db0d71c3ee38dcff0c24f095e2998bda71` (same tree as local
Auto hold checkpoint `7bbf996`). User reports Auto hold now behaves as intended,
but shared `libs/config.lua:339` raises `meta` nil.

The private config copy advertised itself as `_libs.config`, while addon modules
also used a mutable global `config` reference. Private and shared config copies
have separate settings registries; a shared save cannot own a private table.
The private module now leaves the shared singleton intact and explicitly loads
it for companion libraries. All five addon config consumers keep a local import
of the private module. Global inheritance and Auto hold behavior remain intact.

Validation: 39 mocked Lua suites passed and 112 Lua sources parsed under Lua 5.4
with temporary Windower syntax normalization. New ownership test executes private
load/save with stubbed parsing, serialization, collections and I/O, verifies both
registries save independently after global replacement, and checks all consumers
import explicitly. UI fixtures now mock that explicit import. This is not live
Windower/FFXI verification, nor a reproduction using the user's installed library.

Install `XIVCrossbar-Config-Ownership-Patch.zip` over the current patched build;
reload XIVCrossbar on every client. No native DLL/reader change or FFXI restart.
Change Auto hold, reload, and check it persists without the config error. Then
continue normal multibox play. Malformed XML/concurrent writes remain unresolved.

---

# Current Development Status — Auto hold keeps the idle layout visible

Baseline `5fb06921a0a9a8f86c26320da9f6f16ec7881671`.
Auto hold now extends visibility after release while the displayed bank follows
the current input. Releasing the last trigger or shoulder restores the normal
Show-mode idle layout during the hold. The 75 ms two-trigger handoff is unchanged.

Run `//xb auto` and `//xb autohold 1.5`. Release each regular trigger,
combined trigger, double-tap and shoulder bank. The ordinary layout should remain
visible briefly, then fade. Press another trigger during the hold and verify it
takes priority immediately. Check scaling and fades both on and off.
Live visual confirmation is pending.

---

# Current Development Status — Settings inheritance

The uploaded working build remains the runtime baseline, with revision 3 default.
The user confirmed recurring Cioara overrides resembling addon defaults.

A reproduction executed the Windower config.lua source and supporting libraries
through Lua 5.4 with syntax-only compatibility normalization. Myrr saving a file
with global compact=true, five bars, and only a Cioara opacity override produced
Cioara compact=false and three bars. The addon-local library copy instead
preserved only Cioara's explicit opacity override. The shared Windower library
is not modified. Original library license is retained in the local copy.

Install this patch and reload XIVCrossbar on all clients using this addon.
Test one client saving a preference, then reload another and check its global
inheritance and explicit character preferences. Existing explicit overrides,
including previously manufactured overrides, are preserved.

This fixes the reproduced inheritance defect. Concurrent saves and malformed
XML remain under investigation. This simulated result does not establish which
Windower library version is installed on the user's PC.

---

# Current Development Status — November 10, 2026 — Reloadable actions and armed PS probe

Branch `feat/reloadable-controller-logic`. Starting checkpoint
`ceeb3a599123fddb2ab7b1b6ab490a684b2b9adf`.

Close FFXI before installing this matching hook and policies. The hook dispatches
numbered actions to the loaded policy under its callback mutex. Tab/Shift+Tab
implementation is now inside each policy DLL. Future compatible action changes
can be installed using a new numbered policy and Lua update.

1. Load logic 3 and enable bank targeting. Check targetless L1+R1 acquisition
   and selected-target L1/R1 cycling on press. Switch policies live.
2. Run `controller-discovery.ahk`, release controls, and press PS. Select
   its responding row, then choose Arm selected PS input and confirm the
   API, slot and button. Set the addon's PS bridge off during the probe.
3. Focus a non-FFXI application, return to FFXI, then press PS. Press PS
   again to return to that same client. Disarm PS ends
   the probe. A device-list change disarms it automatically.
4. Identify a pad with a face-button press, select the desired row/profile,
   and confirm to copy its selection command. Paste in FFXI and check live
   polls with `//xb nativepad status`.

The scanner retains duplicate entries and logs the visible inventory.
Automatic persistent reconnect identity and matching against FFXI's polled
device remain future work. PS requires an exposed button event in this probe.
Physical acceptance is pending.

---

# Current Development Status — November 10, 2026 — Controller discovery diagnostic

Branch `feat/reloadable-controller-logic`. Starting checkpoint
`1b83d8312d7f13a0fc51794246ba34ea497f99c2`.

Run `controller-discovery.ahk` with AutoHotkey v2. Release all buttons,
press a face button, then PS separately. The utility enumerates all 16 WinMM
slots used by the current DirectInput reader and all four XInput slots.
It shows every responding entry. Select a row and profile, then confirm to
copy the existing profile-selection command. Paste it into FFXI and inspect
`//xb nativepad status` for game polls. Save the report after testing PS.

Controller type detection uses the reported name and requires confirmation.
This diagnostic cannot prove two API entries represent the same physical pad,
or establish persistent identity across a reconnect. Device list changes
reset its button baseline. Guard matching and reconnect identity work remain
pending the physical-device report.

The Windows workflow parses the script and exercises enumeration without
controllers. Hardware selection and PS detection require live testing.

---

# Current Development Status — November 10, 2026 — Targeting on press

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `feat/reloadable-controller-logic`.
Starting checkpoint `7cc8e4ebf9628a4bded5f5d33c95ae8ed9d06224`.
This overlay uses the matching Windows x86 hook and policy binaries from that
checkpoint. Close FFXI before replacing the hook. Keep the existing addon data.

1. Wait for the guard, then run `//xb nativepad logic 3` and
   `//xb bank targeting on`.
2. With no target, hold one shoulder and press the other. Confirm that
   `/targetnpc` runs immediately on the second press, in either order.
   Single presses should leave the target empty.
3. With a target selected, press L1 and R1 separately. Confirm Shift+Tab and
   Tab happen on press. A simultaneous chord and all releases send no
   targeting action. With staggered presses, the first shoulder can cycle
   immediately and the second does not acquire an NPC.
4. Check the combined bank, native menus and chat, and switch to revision 1
   to confirm the previous behavior remains available.

Mocked Lua routing covers these press edges. Live FFXI acceptance is pending.

---

# Current Development Status — November 10, 2026 — Shoulder targeting revision 3

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `feat/reloadable-controller-logic`.
Starting checkpoint `c5fc9eb4169c0320fd96b9e34adb993a37541e65`.
Install the matching resident DLL with FFXI closed. Keep the addon data.
The resident hook adds guarded Shift+Tab. The ownership ABI is unchanged.

1. Wait for the native guard, then run `//xb nativepad logic 3` and
   `//xb bank targeting on`. Tap both shoulders, in both orders. The last
   release should send `/targetnpc` once.
2. With no target, each shoulder tap alone should leave the target empty.
   With a target selected, R1 should send Tab and L1 should send Shift+Tab.
3. Hold a shoulder longer than 350 ms, use a bank slot, press a trigger, or
   open a menu while held. Confirm the release does not send a shortcut.
   Verify a bound combined-bank slot still fires once. Try a native menu,
   chat, and a client switch.
4. Switch to logic 1 or 2 and confirm the previous R1 behavior returns.
   The Xbox RB chooser profile retains its chooser assignment.

The routing fixture checks the real Lua callback for both shoulder orders,
target eligibility, and cancellation. The Windows fixture compares native
ownership across all three revisions. Live FFXI acceptance is pending.

---

# Current Development Status — November 10, 2026 — Reloadable controller logic

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `feat/reloadable-controller-logic`.
Starting checkpoint `162efaeab0931d928236c6f11721c5b803962cd5`.
The x86 hook remains resident and loads its ownership policy from a numbered
DLL. Both trial revisions implement the current shoulder and trigger rules.

1. Back up the installed addon and data, close all FFXI clients, and overlay
   the matching test build. Keep the existing data. Start FFXI, wait for the
   guard, and confirm that `//xb nativepad status` shows revision 1.
2. Release the pad and run `//xb nativepad logic 2`. Confirm the status shows
   revision 2 and that trigger banks, shoulder banks, and native menu input
   behave as before. Repeat with revision 1, without closing FFXI.
3. Try `//xb nativepad logic 999999`. The current revision should remain active.
   On a second client, verify the first client's swap did not change its revision.
4. Hold a shoulder or trigger across a swap. A fresh press after releasing the
   pad should work. Check both XInput and DirectInput, including a native menu.

The Windows fixture checks the ABI, rejection of missing and incompatible
modules, revision swaps while polling, and cleanup of the previous module.
The actual controller and FFXI checks above require a live session.

---

# Current Development Status — November 10, 2026 — Keyboard ownership and HUD controls

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `83af1ec65ff72eab5d5e601965a61b51839ebb09`.
Windower 4 public beta, using the matching Event banks build as the overlay base.
The user reported keyboard navigation reaching FFXI beneath remap and custom-action screens.

1. With a native menu underneath, open `//xb remap` and try the arrows, Enter,
   keypad Enter, and Escape. Hold Enter from profile selection into the next
   page. Hold Escape as the addon screen closes. Release each before trying
   a fresh key. The native menu should only receive the fresh press after
   the addon gives up keyboard ownership.
2. Repeat through Create Custom Action, its text fields, icon picker, and
   review. A physical arrow press should move one step. Enter should commit
   or advance once. Back out with Escape and check the native menu and camera.
3. Check setup and `//xb controller status`, `//xb nativepad status`,
   `//xb diagnose status`, and `//xb help`. Check the PlayStation 5 label,
   waiting for client focus or game polls, and an actual hook failure.
4. Run `//xb auto` and `//xb autohold 1.5`. Release a single trigger,
   a centered bank, or a visible shoulder bank. The last displayed bank
   should stay briefly before fading. Native controls should resume on
   release according to the existing controller rules. The 75 ms center
   handoff still applies while a trigger stays held. Repeat with fades off,
   and check `//xb show`, `//xb hide`, focus loss, and Event bars.
5. With trigger scaling on, try both slot name alignments. Text should
   retain its size while following the bank. Try `//xb costalign left`,
   `center`, and `right` with changing MP, TP, and quantities, then add a
   `//xb costoffset <x> <y>` and restart to confirm persistence.

All 37 mocked Lua suites passed and 109 sources parsed under the test runner's
Lua 5.4 syntax normalization. The starting branch had a stale lockout visibility
test fixture. Its input now supplies the effective visibility mode. Live
keyboard propagation, controller status, and visual checks remain pending.

---

# Current Development Status — November 10, 2026 — Event banks

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `41dd0e319a91cc1da9f8d404b9a0f7d15ee6535b`.
The user reported losing access to crossbar commands during a warp event.

1. Overlay the patch and run `//xb restart`, then `//xb eventbars on`.
   In Show, start a dialogue choice or warp event. The bars should tuck
   away while idle and appear when a trigger or visible shoulder bank
   is held. Release it, then finish the event and check Show returns.
2. Repeat in Auto. Try L2/R2, both trigger orders where configured,
   double taps, and enabled L1/R1/L1+R1 banks. Try a bound NPCMirror
   command or window-switch action while the choice is open.
3. Check that chat and addon menus retain input ownership. `//xb hide`
   keeps gameplay bars hidden. `//xb eventbars off` restores the prior
   Event behavior. The preference is independent of the display preset.

Six mocked Lua suites passed. They cover Event visibility in both
modes, restoring Show after Event, native shoulder capture masks, and
Lua slot dispatch during Event. Live choice and warp checks are pending.

---

# Current Development Status — November 10, 2026 — Shoulder banks in battle

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `f792bcd385da400b780f83782eed2b1c87eaeb83`.
The user confirmed the bank labels now center correctly. They reported
shoulder-bank slots and drawing being suppressed in battle and requested
a silent automatic DirectInput match.

1. Overlay the patch and run `//xb restart`. Automatic success is quiet.
   `//xb nativepad status` still includes the match when the single-device
   fallback was used. An attachment failure still reports itself.
2. With shoulder banks enabled and visible, engage and hold L1, R1, and
   L1+R1. Confirm each bank appears and a bound slot dispatches once with
   the battle palette open. Check normal trigger priority.
3. Outside combat, confirm a native menu retains shoulder-slot ownership.
   Check chat, cutscenes and addon menus. R1 targeting still respects the
   native menu flag.

Six mocked Lua suites passed, including capture masks, actual Lua
dispatch under the native battle menu flag, and quiet automatic matching.
Live combat and DirectInput startup confirmation are pending.

---

# Current Development Status — November 10, 2026 — Trust Return and recast glow

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `cefdd12ca00c655cc6947529979e88fa2e109511`.
The user confirmed cost offsets felt good and reported Moogle's portrait
turning into a white square on Return. They also saw a bright white square
on the first recast-ready flash.

1. Apply the patch and run `//xb restart`. Summon Moogle from a typed Trust
   slot. It should keep its summon portrait, change its name to Return,
   and show a pink X at the recast timer position.
2. Press the Return slot and watch the party list. Once Moogle is gone,
   the X should clear and the summon label should return. Repeat with
   a Trust whose slot has a custom portrait.
3. With Recast Flash on, check the first recast-ready flash after restart
   and compare it to later flashes. The texture is now configured at
   zero opacity during the cooldown. Native image settings are isolated
   per surface. The first visible FFXI frame still needs confirmation.

Six mocked Lua suites passed, including native and custom portrait
preservation, the Return-to-summon transition, and early glow setup.

---

# Current Development Status — November 10, 2026 — Bank caption centering

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `56d752211935051ebdf38653e3d5ecea8c324e7d`.
The user confirmed independent outline colors and liked the recast timers.
Several rarely shown banks still appeared right of center. A hidden
caption could spend the full width-settling window without drawing,
and a zero-width fallback could persist after native extents recovered.

1. Apply the patch and run `//xb restart`. Wait before first showing
   `R2x2`, `L2x2`, the combined bank, and `L1+R1`. Compare each label
   with its own bank at a horizontal bank label offset of zero.
2. Check a recast timer. It is nudged 2 layout pixels right, with
   its vertical anchor still 13 pixels below the top of the 40-pixel slot.

Five mocked Lua suites passed, including hidden captions and recovery
after a zero-width fallback. Live centering is pending.

---

# Current Development Status — November 10, 2026 — HUD text rendering

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `e55e9a7018652d8adc7e9a8b36417a891b433b54`.

The user reported outline color changes after bank opacity updates and
restart, blinking centered slot names during TriggerScale, and uneven
bank-label placement. The saved XML has black slot outlines and centered
slot names. The supplied diagnostic is input-only and predates the report.
Windower retains the supplied text options table, so HUD text objects now
receive independent native settings. Centered text keeps stable font metrics
during bank scaling. Bank labels anchor to the full width of their own bank.

1. Apply the patch and run `//xb restart`. Set `//xb slotlabelstroke black`
   and `//xb banklabelopacity 60`. The bank outline should stay gold.
   Restart and check both again.
2. With `//xb slotlabelalign center`, rapidly switch trigger banks and look
   for caption blinking. With horizontal bank offset zero, compare the
   `R2x2` and `L1+R1` labels with the actual widths of their own banks.
3. Use an action with a recast. Check the centered white size-10 timer
   with a black outline. Try `//xb costoffset -8 -24` to move costs and
   item counts toward the top-right. `0 0` restores the old anchor.

Seven mocked Lua suites passed, including a Windower-style shared-settings
regression, stationary font metrics during trigger scaling, timer placement,
and cost offset application. In-game alignment and readability are pending.

---

# Current Development Status — November 9, 2026 — Label layout controls

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `f4b4c0c862d38b5ba8955f7cf9a299903ab77d65`.
In the live build the user saw some bank labels overlap slot action names
and reported that their outlines appeared to change together. The two
label types have independent outline colors. Slot amber uses the original
darker amber. The bank outline uses the brighter binding-highlight gold.

1. Overlay the Lua patch and run `//xb restart`.
2. Try `//xb banklabeloffset 0 -8` and `//xb slotlabeloffset 0 4`.
   Positive offsets move right and down. `0 0` resets each anchor.
3. Use `//xb slotlabelalign center`, then `left`. Check captions while
   switching sets, layouts and banks.
4. Try `//xb banklabelopacity 160`, `0`, then `255`. The setting affects
   the bank label's fill and outline. Check it during a fade.
5. Try `//xb slotlabelstroke amber`, then `black`. Watch that only
   slot action names change outline color. Restart and check persistence.

Seven Lua suites passed with mocked Windower surfaces, including separate
outline colors, offset geometry, centered-to-left text settling, and
bank opacity composed with fades. Live spacing is pending.

---

# Current Development Status — November 9, 2026 — Bank label styling

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `bcf081d82fa6cadaf7267a170fe4fc38212a4412`.
The first label pass was larger and darker than desired in FFXI. Slot
captions continued to inherit the saved theme stroke. The revised bank
font is 6% smaller before Windower rounds the rendered size to an integer.
It uses the brighter binding-field gold and stays fixed through bank
scale and slide while still following bank and HUD fades. Moving or
scaling the whole HUD still moves or scales the labels.

1. Overlay the patch and run `//xb restart`. Compare labels with
   TriggerScale on. Check size, contrast and position as banks switch.
2. Use `//xb banklabels off` during a fade, then `//xb banklabels on`.
   Check that bank labels alone are hidden and restored.
3. Try `//xb slotlabelstroke amber` and `//xb slotlabelstroke black`.
   Check that only slot action names change outline color. Restart to
   verify both settings persist.

Seven Lua suites with mocked Windower surfaces passed. Live contrast
and perceived size are pending.

---

# Current Development Status — November 9, 2026 — Crossbar labels

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `c88ac80d4d27491635942ed4a4b7eea2fe32e098`.
The user reported the combined-bank release patch did the trick in FFXI.

Each visible bank now has a white label with a dark amber outline between its
two upper slots. The labels follow the bank position, scale, slide, and
existing text fade policy.

1. Overlay the Lua patch and run `//xb restart`. With both side banks shown,
   check `L2` and `R2` placement in compact and full layout.
2. In five-bank mode, hold both triggers to check `R2+L2`, and double-tap
   each trigger for `L2x2` and `R2x2`. In six-bank mode check both trigger
   orders, `R2>L2` and `L2>R2`.
3. Check the shoulder labels `L1`, `R1`, and `L1+R1` when their banks are
   visible. Move or scale the HUD and verify the labels stay centered.
4. In Auto, repeat quick paired releases with Fade On and Off and check
   that the center label disappears with its bank.

Six Lua suites with mocked Windower surfaces cover label text, layout
anchors, bank ownership, visibility and release/fade behavior. Font
placement and amber contrast still need a live FFXI check.

---

# Current Development Status — November 9, 2026 — Combined-bank release

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `92065c119a532fe5aa03bfa0496670f15bd48eae`.

In Auto, the combined L2/R2 bank keeps its visual selection for 75 ms after
the first release. A second release within the window fades or hides the
center by itself. If one trigger stays down, the side pair replaces the
center in the next draw after the window. Gameplay continues to route using
the physical triggers.

1. Overlay the Lua patch and run `//xb restart`. Use Auto with TriggerScale.
2. With Fade On, hold both triggers and release them in quick succession.
   Check that only the center fades. Repeat while still moving into center.
3. Hold both, release one and keep the other held. Check that the side pair
   takes over without the center fading on top. Press a slot immediately
   after the first release to verify that the remaining trigger owns input.
4. Repeat with Fade Off. A quick paired release should hide the center
   directly. A sustained single trigger should reveal the side pair.
5. Repeat both trigger orders in six-bank mode. Confirm a trigger repress
   or opening the addon menu clears a pending handoff.

The capture ending in `215759-744394-1-client.log` contains 44 paired
releases from center. Twelve were routed together, and 31 more arrived
within 75 ms. Six Lua test suites passed with mocked Windower surfaces,
including both fade settings, both TriggerScale settings, same-frame
releases, re-press, menu cancellation, and the preserved travel into center.
Live FFXI verification is pending.

---

# Current Development Status — November 9, 2026 — Compact HUD hints

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `fd6c68a06ffc9fa2dd6981828ee74ea79b978f32`.
Compact mode skips creation of the Options/Share HUD hints. Switching from
full to compact disposes the hint images and captions immediately, including
during a fade. The set chooser computes its anchor from the layout.

1. Overlay the Lua patch and run `//xb restart`.
2. In XI compact and Auto, tap L2/R2 rapidly with Fade On, then Off, then
   On again. Options and Share hints should stay absent.
3. Hold Options in compact and check that the chooser opens at its normal
   anchor. Switch to full and verify both hints return, then back to compact.
4. If a hint still flashes, capture one occurrence and stop immediately.
   Capture state includes the actual layout, fade option and hint allocation.
   Fade commands are recorded separately from high-volume draw calls.

### November 9 — Options hint follow-up

The full capture ending in `215434-528375-7-client.log` recorded 137 routed
L2/R2 edges. The render ring overwrote 222,563 entries and retained roughly
the last half-second, without enough data to identify the flashing object.
Mocked layout and lifecycle tests check compact startup, removal of full
hints during interrupted fades, and restoration without growing the live
resource count. Live FFXI verification remains pending.

---

# Current Development Status — November 9, 2026 — Set chooser rendering

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `29730f1347238a6d8835df72fd7098e554e74e01`.
The Lua overlay keeps bank visibility in the render pass and writes each
slot's resolved icon directly when a set changes. In the binder, an inherited
source badge replaces the cost and recast overlay for its slot.

1. Overlay the Lua patch and run `//xb restart`.
2. With XI, Auto and Fade On, hold Options, highlight Add New Set, then
   release Options. Watch that only the side bars fade. Repeat after entering
   and backing out of name entry, in compact and full layouts.
3. Scroll quickly through sets with different bindings and shared inherited
   icons. Check that the selected set's art stays steady between changes.
4. With the binder open, hold Options and scroll sets. Inherited ALL/JOB
   badges should stay steady, with no MP/TP cost flashing underneath. Close
   the binder and check that regular costs and recast overlays return.
5. In XI compact, tap L2 and R2 quickly with Fade On and again with Fade Off.
   If the Options hint still flashes, start `//xb diagnose start render`,
   reproduce once and run `//xb diagnose stop` immediately.

### November 9 — Set chooser and hint diagnostic evidence

The compact full capture ending in `214606-288162-1-client.log` retained the
late set-scroll rendering and overwrote 98,982 render records. The supplied
full-size set, Options hint, and inherited-badge captures recorded input only.
The later full capture ending in `215242-454624-6-client.log` retained 522
same-frame repeated image path writes and 95 same-frame show/hide pairs for
text surfaces. The render trace redacts art paths and caption contents. The
set-refresh fixture asserts that inherited badges and costs no longer issue
competing visibility calls, and that refreshing a set preserves the current
reveal in compact and full layouts. The Options flash still needs an isolated
render capture if it persists. Live visual verification is pending.

---

# Current Development Status — November 9, 2026 — Superwarp city folders

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `0c8a53f89557214f8644477be88ea8bede5eea9e`.
This ports the November 7 Public Beta Superwarp city-folder overlay from
its `206bbde` base into the current binder.

Apply the combined Lua patch and run `//xb restart`. Open Action Binder,
choose Superwarp, and check that Bastok, San d'Oria, and Windurst appear
before the remaining alphabetical destinations. Choose a numbered Home
Point or Survival Guide and verify the stored command. Back from binding
should restore the city page. Back again should restore the root city row.

The Lua fixture covers the three folders, 38 numbered Home Points,
3 Survival Guides, scope preservation, and both Back transitions. Warp
landing landmarks still need in-game confirmation.

---

# Current Development Status — November 9, 2026 — Custom-action icon picker

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `2e459a0015ef57f883a5ced63300cb86aea9e21b`.

Overlay the Lua patch and run `//xb restart`. Edit the Quests custom
action, select Choose Icon, and confirm the title identifies Quests.
Open a folder and check its breadcrumb. Without switching focus, tap
R2 then L2 and repeat after Back and re-entry. A trigger already held
on entry must be released before it can page on the next press.

The user reported that paging resumed after focus changed. The fixture
covers stale binder trigger flags and successful paging in both
directions. If it still stalls in Windower, collect a full diagnostic
through the failing taps and focus change so the input and render paths
can be compared.

---

# Current Development Status — November 9, 2026 — Delete from custom-action review

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `45f9fdb`, with the XI preset and keyboard changes in
this batch. Apply the combined Lua overlay and run `//xb restart`.

Edit an existing custom action and check that Delete Custom Action is
last, after Link Action. Enter confirmation, then press Escape or Back.
The draft should return intact. If you changed the name without saving,
confirmation should still identify the original catalog entry. Confirm
on a disposable entry and check the catalog. An unsaved new action
should have no Delete option.

The Lua fixture exercises the real review and catalog callbacks for
cancel, unsaved rename, failed write, and successful deletion. Live
keyboard capture and menu rendering remain to verify.

---

# Current Development Status — November 9, 2026 — Modal keyboard ownership

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `45f9fdb`, with the XI preset changes in this batch.

Apply the Lua patch and run `//xb restart`. Open remap or a custom-action
review over a native menu. Try each arrow, Enter, and Escape. The native
keyboard should be blocked while the addon screen owns it. Tap an arrow
and wait a second. The cursor should only move once. Controller D-pad
holds should still repeat. Try typing a name, going Back, changing focus
between clients, and closing the addon while holding a navigation key.
Verify normal native keyboard input returns on leaving the addon menu.

Lua checks cover one-step dispatch, release after changing screens, and
guard transitions. Verify the Windower input block in a live client.

---

# Current Development Status — November 9, 2026 — XI preset and set labels

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint `45f9fdbd4bf20872c248548c36866ec8f1e8d552`.

Apply the Lua patch and run `//xb restart`. Reapply `//xb display xi` to
activate Slot Glow, Recast Flash, and TriggerScale in an existing XI setup.
Check the toggles with their individual status commands. Override them
individually to compare effects.

Open the set chooser and both set-switch pickers. Verify ALL, the main-job
abbreviation, the job/subjob pair, and Main. With no subjob, the job-pair
label uses the main job alone. Try switching with existing bindings and
by saved key. Switch to Legacy and verify the previous labels return.

Local Lua checks exercise the preset and destination keys. Live drawing
and keyboard ownership are separate acceptance checks.

---

# Current Development Status — November 9, 2026 — Setup selection controls

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Starting checkpoint `d5a3793018f73b1691808ea3d20683b9044f1d20`.
Windower 4 x86 and the existing AutoHotkey v2 reader.

Cioara completed setup on the attachment-recovery build after manually
selecting PlayStation 5, Device 2 and then clicking the profile tile.
The initial click alone did not proceed. The exact cause of that
initial failure remains open. Device discovery is a separate pass.

Overlay this Lua patch on the attachment-recovery build and run
`//xb restart`. Then use `//xb remap` on a client you are comfortable
remapping. A first-time installation can also test the Welcome page.
Use the same device slot that already worked on Cioara.

1. On Welcome, check the Enter-or-click prompt and tap Enter. Hold it
   long enough to repeat and verify that it advances only one page.
2. On Input Profile and Button Artwork, use the arrow keys, hover a
   different tile, then resume with the keyboard. The animated gold
   cursor and amber highlight should follow one shared selection.
   Confirm once by keyboard and once by mouse on separate passes.
3. Open setup over an FFXI menu. Click blank panel space, right-click,
   and scroll inside and outside the panel. FFXI should receive only
   outside input. Drag from inside to outside and outside to inside.
   Each release belongs to the side that received the press.
4. Confirm artwork and verify the cursor disappears. Map buttons with
   the existing controller prompts. Cancel and reopen setup to check
   that the previous click cannot activate a new page.

The Lua fixture exercises the real wizard handlers with a simulated
Windower host. Physical input capture, visuals, and panel layering
remain live acceptance checks.

---

# Current Development Status — November 9, 2026 — Native attachment recovery

Repository `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Starting checkpoint `03aa76ad921dd41b46ff966ba43dc6fc7b931664`.
Build `0.4.0-beta1.20261109.hook1`, Windower 4 x86 and AutoHotkey v2.

Cioara reported that FFXI read the DualSense over USB and the reader showed
PlayStation 5, Device 2, Connected and Ready. Profile selection succeeded,
then the native hook was unavailable and face-button mapping stalled.
A similar hook failure was reported over Bluetooth. The exact failed
operation was unavailable in that build.

Install the complete matching x86 build with all FFXI clients and the
shared reader closed. Keep the existing bindings and controller settings.

1. Connect the DualSense by USB and start Cioara. Leave the reader on Device 2.
   Check `//xb controller status` and `//xb nativepad status`. If the fallback
   is used, chat reports the sole-controller match for Device 2. The guard
   still needs FFXI to poll the selected device and DirectLink to join.
2. With filtering active, select the layout and map R2 plus a face button.
   The setup prompt should advance once and FFXI should receive no
   underlying face-button action. Verify bare native input after setup.
3. If attachment still fails, copy the full Hook Unavailable line with its
   operation and hex code. `//xb nativepad status` repeats it. With the
   intended device connected, `//xb nativepad auto` retries once.
4. Repeat after a clean Bluetooth launch with its detected reader slot.
   With two controllers connected, confirm the fallback does not select an
   arbitrary device. A valid Windows joystick-ID mapping still takes priority.

Local Lua fixtures cover failed status persistence, retry reset and detail
propagation. The portable C++ input fixture passes. The Windows host fixture
now checks the DLL's Lua attachment error return. Actual USB and Bluetooth
attachment in FFXI remains the acceptance check.

---

# November 8, 2026 — Getting started and command help

Branch `integration/shoulder-banks`. Overlay this Lua patch on the
input diagnostics build at `2c7e8a2` and run `//xb restart`.

- Run bare `//xb`, `//xb help`, and `//xb ?`. Each should print the same
  six-line guide. Check Share and Options on PlayStation, View and Menu
  on standard Xbox, and RB on the Xbox R1-chooser profile.
- Run `//xb typo` and `//xb help typo`. Each should name the invalid
  command or topic and print the same short guide.
- Try `//xb help sets`, `//xb help bindings`, `//xb help display`,
  `//xb help controller`, `//xb help diagnostics`, and `//xb help all`.
  Each topic should open on its own and `all` should print all five.
- Check `//xb inputtest status` and `//xb inputtrace status`. Try each
  with a misspelled option and confirm status stays the same. Test the
  explicit on and off options, then restore the original settings.

Lua fixture checks cover the command dispatch and chat output. Windower
chat wrapping and physical controller labels await in-game confirmation.

# Current Development Status — November 8, 2026 — Input-first diagnostics

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint: `4ef0784f8a583d60eb1c66699e06deb4842ecd51`.
Build: `0.4.0-beta1.20261107.diagnostics2`.

Install the matching x86 artifact with FFXI and its shared reader stopped.
Preserve `data/`. Restore the previous program files with both stopped
to roll back.

- Run bare `//xb diagnose`. Press a native D-pad direction, then test a
  held direction followed by L1, an L1 slot, and R2 takeover. Add a
  multiword mark and stop. The single log should link reader sequence,
  Lua receipt, route and slot outcome. It should include native masks
  where available and contain no render events.
- Repeat over Trust with `bridge menu test`, then live. Check the
  difference between dry-run status and a claimed navigation edge.
  Move focus to another client during the capture. Its AHK input
  should not appear in the original client's reader feed.
- Start a `render` capture and check that extents and positions remain
  while captions and paths are omitted. `full` includes both streams.
  `snapshot` saves state only. Test a pre-login capture without a
  known PID and confirm the wrapper feed is explicitly omitted.
- Test two clients requesting the one shared reader and verify the
  existing reader capture continues. Wait for the save message before
  sharing files. Explicit user marks are included.
- Reader stages use QPC wall-time deltas and record stages at or above
  8 ms during a capture. Native masks are observed samples. Neither
  source establishes what the FFXI UI actually did.

Local fixtures cover capture profiles, stream merging, PID request
shape, redaction, snapshot isolation and message sequence propagation.
Live FFXI and two-client diagnostics remain pending.

---

# Current Development Status — November 8, 2026 — Optional controller bridges

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint: `514e03240b5b5bdbd07aeae00da33c8a86bbbf43`.
Build: `0.4.0-beta1.20261107.bridge-test1`.

Install the complete matching x86 artifact with FFXI closed and the
shared AutoHotkey reader stopped. Keep `data/`. Restore the previous
program files with the clients and reader stopped to roll back.

All features default off. Run `//xb bridge all test`, then
`//xb bridge status`. Test mode reports decisions and adds no native
suppression, Trust output, or focus switch. `//xb inputtest on` also
forces any saved live bridge into test mode.

1. Use the matching Trust build that publishes controller-menu leases
   and integrated movement leases. Open Trust over a native menu. In
   test mode check the “Would route” line. In live mode run
   `//xb bridge menu on` and test a single press, direction repeat,
   Confirm, Back, and a text field. Hold a direction when closing the
   Trust lease and verify native input resumes only after release.
2. With `//xb bridge movement test`, focus an FFXI client with the stick
   centered and move it. Check the reader decision in status. Switch
   clients and check Send and Ready separately. With `on`, verify Trust
   receives its dedicated signal once and native analog movement stays
   intact. Ready waits for a ready receiver and gameplay. The current
   Trust receiver identifies movement leases by character window title,
   as on the personal build.
3. On PS5 DirectInput, focus a named non-FFXI window, return manually to
   FFXI, then tap PS. Test mode reports the remembered destination.
   Live mode switches once. Release and press again within 30 seconds
   to return to the originating FFXI client. A hold, another pressed
   controller button, or a menu blocks a fresh switch. Verify both
   clients and make sure an expired return does not steal focus.
4. With `//xb bridge all off`, check the ordinary beta controls and
   verify the reader reports no new bridge actions.

Portable Lua/native fixtures cover mode and ownership boundaries.
The first Windows run built and passed both native fixtures, then stopped
because the reader test staging list omitted the new AHK include.
Windows x86/AHK CI and actual FFXI/Trust observations are separate
checks. Live input and focus-switch acceptance remain pending.

---

# Current Development Status — November 8, 2026 — Trigger and job parity

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint: `adba856143afdbe4247afae4cdfcb22eda7e1edc`.
Test build: `0.4.0-beta1.20261107.personal-parity1`.

Install the matching x86 artifact with FFXI closed and the reader
stopped. Keep your data folder. Roll back by restoring the preceding
program files with FFXI closed and the reader stopped.

- Use `//xb triggerbanks 5` to reload in five-bank mode. Test both trigger
  orders, then double-tap L2 and R2 separately. Both orders use saved
  bar 3, double taps keep bars 5 and 6, and saved bar 4 returns when
  switching back to six. Check the binding preview and confirmation too.
- With `//xb triggerscale on`, swap from the side pair to the combined
  or shoulder bank and back. Check fast reversals, menus, Always and
  Autohide. The two sides move inward or outward and crossfade with the
  center over 90 ms. Existing scale easing is still 60 ms.
- Bind a learned Trust as a typed spell. Expect the summoned Trust to
  show Return on its own slot and dismiss by name. Check unlearned spells,
  pet-only actions with no pet, and command bindings with linked metadata.
- On SMN, check Assault/Retreat with the pet idle and engaged, and
  paired Attack/Disengage against a concrete target. A matching avatar
  or spirit slot shows Release. A different summon releases, waits for
  the pet to disappear, and casts once. Try zoning and another action
  during the wait. Selector-style attacks remain ordinary attacks.
- Run `//xb jobsets` on a job with eligible magic or pet commands. It
  explicitly creates missing editable category sets for the current
  job/subjob. It preserves existing sets and slots. Run it twice to
  confirm the second invocation adds zero.

Local fixtures cover the five-bank surfaces and interrupted animation,
real dispatch for Trust/pet actions and summon replacement, and additive
job sets. Gamepad visuals and action acceptance remain pending in FFXI.

---

# Current Development Status — November 7, 2026 — Playable shoulder banks

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint: `eb63165f56a34a256216547f3c699124c4a7a5f2`.
Test build: `0.4.0-beta1.20261107.shoulder-slots1`.

L1, R1 and L1+R1 now have eight playable slots each. The normal binder
previews and edits them, even while disabled. Named bank records in
the character's Shared.xml keep bindings separate from job/subjob files
and numbered crossbars. The slot executor and centered combined-trigger
layout are shared with existing bars. Targeting keeps its separate toggle.

Install the full matching Windows x86 artifact with FFXI closed and the
shared reader stopped. Keep the existing data directory. Roll back by
closing FFXI, stopping the reader, and restoring the prior program files.

1. In the ordinary binder choose a Console Command, e.g. `input /echo L1 slot`.
   On Enter Button Combo hold L1 and press a direction or face button.
   Release it, then confirm the tentative binding.
2. Run `//xb bank l1 on`. Hold L1 and press that same slot. Expect the
   centered bank, one command and no native slot action. Release L1 first
   with a direction still held. The direction must stay owned until release.
3. Hold L1, hold L2 or R2, and confirm the trigger bar wins. Release the
   trigger with L1 still held. The L1 bank returns. A slot held across
   either change must not fire twice. Test both shoulder chord orders.
4. Use `//xb bank l1 hide` to test dispatch without drawing and
   `//xb bank l1 off` to restore native input. Re-enable, switch jobs,
   and reload to verify the same slot remains bound. Check binder delete
   and icon changes. On the RB chooser profile, test L1 only.
5. Check menus, focus, chat and older installations with all banks off.
   The earlier R1 targeting live checks still apply.

Simulated coverage includes the real binder confirmation path, shared
storage routing, action execution across sets, centered layout and
trigger priority, and native ownership through release. Physical
controller and in-game behavior remain to be checked.

---

# Current Development Status — November 7, 2026 — R1 targeting and bank selection

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint: `9450d8c71806f44100d542d9e0e6f6f5beefa76d`.
Test build: `0.4.0-beta1.20261107.shoulder-targeting1`.

R1 targeting is opt-in and uses the acknowledged controller stream.
It takes ownership of fresh, unmodified R1 only in gameplay. The Lua
router chooses `/targetnpc` or a Tab tap on the press edge. The receiver
waits for a matching extended reader and native bridge before enabling
targeting. The alternate RB chooser profile keeps its existing role.
The first transport checkpoint passed Windows x86 and Lua CI. Local
checks for this batch cover real routing with simulated inputs, parsed
shoulder chords, portable native ownership, and source packaging.
Actual FFXI targeting and Tab delivery remain to be checked.

## Live test

Install the x86 CI artifact with the matching DLL, Lua and AHK files.
Stop the shared reader before swapping files and preserve the existing
`data/` directory. Restart the FFXI client if it still has the previous
DLL loaded, then start the updated reader. To roll back, disable
targeting with `//xb bank targeting off`, stop the reader, and restore
the prior addon folder and DLL with the clients closed.

1. With targeting off, confirm native R1 behaves as before.
2. Run `//xb bank targeting on`. Clear your target and tap R1 near an NPC.
   Expect the same selection as `/targetnpc`. Tap R1 with a target and
   compare with physical Tab. Hold R1 for a moment and release it.
   Expect one action per press.
3. Try L1 then R1, both shoulders in the same sample, and R1 then L1.
   The first two send no shortcut. R1 first can send once before the
   later L1 edge. R1 while L2/R2 is down should pass through normally.
4. Repeat during a native menu, addon menu, dialogue, or chat entry, and
   switch focused clients while holding R1. No targeting shortcut should
   fire there or replay on focus return.
5. The alternate Xbox chooser must still open on RB. On standard
   XInput and DualSense, compare native passthrough when disabled.

## Bank scaffold

`//xb bank <l1|r1|both> <on|off|show|hide>` saves separate enabled and
visible preferences. All three banks start disabled. Selection is traced
under BANK when diagnostics are active. Check that L2/R2 preempt the
selected shoulder bank, and releasing the trigger restores the selection
if the shoulder remains held. Action storage, binder destinations, slot
dispatch, and centered rendering are the next milestones.

---

# Current Development Status — November 7, 2026 — Shoulder input transport

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `integration/shoulder-banks`.
Source checkpoint: `d7c6b6b98b79a0e5fac06633a8ba56ac65e96e1c`.
Personal behavior reference: `72e7b6dfb9df0d5832d143af37081a6d489691fe`.

The first milestone adds L1 and R1 observation to the generated hardware
maps and the existing acknowledged stream. Extended clients can lease
14 inputs. The current router still leases 12 and native shoulder
ownership is unchanged. The alternate XInput profile continues to use
RB only for its chooser. The additional DirectInput mappings use Joy5
and Joy6, as on the personal DualSense. Physical FightPad and F710
mapping confirmation remains pending.

Local generated-mapping and portable C++ fixture checks pass. The Lua
fixture covers rejection on ordinary leases and ordered shoulder edges
on an extended lease. The Windows workflow builds the actual x86 DLL
and runs the AutoHotkey fixture. Hardware tests remain pending.

Next milestones are ownership, dispatch and the binder, persistent shared
bindings, and centered rendering. The agreed optional command is
`//xb bank targeting on|off`, off by default. On eligible R1 down,
run `/targetnpc` with no selected target or send Tab with one selected.
Holding and releasing send nothing further. If both shoulders are down
in the same input sample, send neither shortcut. If the other shoulder
arrives later, entering the chord sends no additional shortcut. Verify
menus, trigger priority, each chord order and focus rearming before a
live testing package.

---

# Current Development Status — November 7, 2026 — Compact Options hint

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `616293cca78745eb01cd622127956a40281e0798`.

Myrr reported an Options icon flash while rapidly tapping R2.
`Myrr-20261107-185138-475080-1-Myrr.log` shows repeated idle/trigger
transitions with the addon menu closed. The render buffer overwrote older
events and retained 2,065 alpha, 1,415 position, and 1,289 size calls.
These are Lua drawing calls. The capture does not identify the flashed
icon or measure GPU cost.

Ported the compact visibility policy from personal commit `a572fca`.
Compact hints start hidden and leave the draw list immediately, even
during a fade. Full-layout hints still follow the normal crossbar fade.
The chooser hides its overlapping caption directly. The opacity pass
skips fully hidden surfaces and applies the current opacity on reveal.

Overlay this Lua patch on the special-bank TriggerScale build. Reload
XIVCrossbar. In XI compact with fades and TriggerScale on, rapidly tap R2
with Autohide and then Always visibility. Repeat after closing the binder
and chooser. Options and Share hints should stay hidden in compact.
Check that switching to full layout restores the hints and Options still
opens the chooser. The compact fixture covers 108 layouts and interrupted
fades. The text-fade fixture checks zero fade alpha writes for a hidden
image and correct opacity on reveal. In-game confirmation is pending.

---

# Current Development Status — November 7, 2026 — Special-bank TriggerScale

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `0071f3078b1f120b664ae94a674627da2463a32c`.

With TriggerScale enabled, combined and double-tap banks grow by the saved
shift. When a special bank closes and the regular pair is visible, both
return from the smaller scale. With no trigger held they settle at 100%;
a remaining single trigger uses its regular scale targets. The bounce uses
the 60 ms easing. Autohide still decides when banks are visible.

Check with `//xb show`, both combined orders, both double taps, and rapid
release/repress. Repeat with fades and Autohide. The Lua fixture covers
special-bank scaling, field alignment, the return midpoint, and the
hidden case. Live feel is pending. Overlay the 60 ms TriggerScale build.

---

# Current Development Status — November 7, 2026 — 60 ms TriggerScale

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `67060a6a3c846f095e391cd682ab8ab25c90258a`.

The user requested a faster TriggerScale. The bank animation keeps the
same easing curve and now takes 60 ms. The opacity fade still follows its
own settings. The Lua fixture checks the midpoint at 30 ms and completion
while a longer opacity fade is still in progress. Live feel is pending.
This patch overlays the symmetric TriggerScale build.

---

# Current Development Status — November 7, 2026 — Symmetric trigger scale

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `206bbde2a35c6342a8f3eceb3ebc1b435d96a8d3`.
The user liked Myrr's XI layout and requested symmetric scale with fades.

- With `//xb triggerscale on` and `//xb triggerscale 1`, both banks rest at
  100% of HUD scale. Hold R2 for 101% right and 99% left. Hold L2 for the
  reverse. A saved 99% small scale becomes a 1% shift without editing XML.
  The number in the command now denotes a percent shift.
- Check `//xb fade on` with XI, then repeat with fade off. Check Always and
  Autohide, rapid trigger reversals, combined and double-tap banks, and the
  addon menu. The animation stays centered and uses the existing 120 ms
  easing. Menus and special banks use normal scale.
- Automated Lua tests check centered scale above/below 100%, saved 99%,
  opacity running alongside scaling, and fade-off immediate hide. Live
  feel remains to be checked. This Lua patch overlays the XI layout build.

---

# Current Development Status — November 7, 2026 — XI compact spacing and artwork

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `8c6767c199cbe1bf891f303633274d17772763fb`.
The user approved the softer recast flash and requested tighter XI spacing.

- Select `//xb display xi`, turn `//xb triggerscale off`, and use
  `//xb show` to compare both banks. At 1×, standard compact XI uses
  touching side tiles, a 4 px gap between vertically stacked tiles, and a
  16 px gap between the L2 and R2 banks. The alternate layout preserves its
  split grouping. Saved HUD scale and offsets apply to the entire layout.
- Compare occupied and empty slots. Empty XI frames have a shaded top
  and brighter lower lip. Four new warm-white field textures are fitted
  around the active bank or its two clusters. Check single, combined,
  double-tap and binding-preview states.
- Switch to `//xb display legacy` while compact. Original spacing,
  empty-slot artwork, dark fields and thicker square-ended combat strips
  should return. Legacy leaves compact enabled so spacing is easy to compare.
- Lua fixtures cover live layout changes, empty visibility, field fitting,
  and the Legacy skillchain ribbon shape. In-game density, label readability
  and asset appearance are pending. This patch overlays the soft recast build.

---

# Current Development Status — November 7, 2026 — Softer recast-ready flash

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `a759b530f21e162a9e7a74ccd496af95a521501c`.

The user found the nearly opaque white square looked like a graphical glitch.
The new texture combines a translucent warm-white fill and a brighter
feathered edge. Both fade together over 150 ms. The center peaks around
34% opacity and the edge around 56% before any bar fade.
The gold confirmed-action animation is deferred.

Keep `//xb recastflash on` and compare the softer effect at the end of a
visible cooldown. Check it in compact mode, during trigger scaling, and
alongside the held gold border. Automated tests cover the view size,
placement, initial opacity, decay, and existing trigger rules. Live
appearance is pending. This patch overlays the recast-flash build.

---

# Current Development Status — November 7, 2026 — Recast-ready flash and glow release fix

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `353d2776358a0bb12088b7b6dcde7fe0619d4bf7`.
The user reported the rounded ribbons looked better and is continuing live checks.

Myrr's 30-second capture showed accepted up edges for the affected inputs.
For example, DirectLink sequence 17 lit glow object 274, while sequence 18,
its matching release, hid 276. Both logs show button-up activity during
song casts and refusals. The glow release lookup swapped Circle and Square
relative to the action path. Press and release now use the same slot map.
This fix concerns visual ownership and preserves action selection.

Enable `//xb recastflash on` and keep the bank visible through a cooldown.
At observed positive-to-zero recast, the slot flashes white at alpha 250
and falls to zero over 100 ms. It works independently of slotglow. Initially
ready, rebound, hidden and menu-covered slots do not replay a ready flash.
Repeat Myrr's Circle and Square song holds, releasing one at a time, and
check that only the released border clears.

Lua tests cover mapped release, simultaneous recasts, decay, nil samples,
rebind, hidden banks, menu and hide cleanup. Live visual testing is pending.
The patch changes Lua only and can overlay the combat strips build.

---

# Current Development Status — November 7, 2026 — Combat ribbons and brighter slot glow

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `bd18fb813165fe9bfbaefdcd886245d3b084bf58`.
The user reported the feathered frame was too dim at all three levels.

- In XI, check the translucent white pre-skillchain ribbon and black edge,
  then the more opaque TP-blue/white flash during the open window. In Legacy,
  check the configured waiting/open colors. Switch presets during a window
  and verify the color changes without waiting for the next chain.
- Spell, weaponskill, and job ability lockouts retain their XI tint ramps
  and Legacy colors. XI autoattack uses pale pink before the estimate and
  pale green past it, while Legacy keeps its configured red/green colors.
  All three strips use thinner rounded fills and backings.
- Test `//xb skillchain 255`, `//xb lockout 255`, and `//xb autoattack 255`
  independently. Check off, on, and status. Lockout on restores the saved
  per-action values. Autoattack off or zero hides it and stops swing tracking.
- Gold frame alphas are now 250 ready, 190 unavailable, and 145 empty.
  The core of the stroke is white, its feather is gold, and the tile
  center is transparent. Check the held border alongside the XI pulse.
- Automated Lua checks cover ribbon phase colors, commands, and held glow.
  In-game colors, brightness and strip positioning are pending. This
  delivery changes Lua and artwork, with no native DLL source changes.

---

# Current Development Status — November 7, 2026 — Feathered slot glow

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `ce809fd18f9d178517e3ca029fb5e5ce9c79f730`.

The user reported the held XI slot pulse was faint and the gold border
was hard to see. The settled pulse now uses alpha 96 instead of 72, with
the initial flash and timing retained. `//xb slotglow on` uses a dedicated
feathered gold outline around the tile. The outline remains dimmer on
unavailable actions and faintest on empty slots.

Hold a slot with XI selected to compare the settled pulse. Enable slotglow
and compare ready, unavailable and empty slots. Repeat with Legacy to see
the gold frame without the XI pulse, then test compact layout and trigger
scaling. Check both the feather and brightness at the normal play resolution.
The texture and Lua fixture cover a transparent center, alpha falloff,
brightness ordering, held opacity and alignment. Live appearance is pending.
The native DLL is the same source baseline as the preceding package.

---

# Current Development Status — November 7, 2026 — Gold slot hold border

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `d4ec6145d6d90c103d1b98647e8a1123fbca7eeb`.

- `//xb slotglow on` enables the saved opt-in. Hold a slot button with a
  trigger and check that a soft gold border brightens on press, settles
  while held, and clears on release. Quick taps have a 60 ms minimum.
- Compare a ready action, an action on cooldown or without MP/TP, and an
  empty slot. The border should be progressively fainter. Try two buttons
  at once, bank switches, menu opening, focus loss, and Autohide.
- Test with Legacy and XI, including fade-off trigger scaling. The gold
  border can run with the existing white flash and XI pulse. It indicates
  input receipt, and does not predict server acceptance.
- Lua regression fixtures cover brightness ordering, simultaneous holds,
  layer compatibility, bank geometry, release, and cleanup. In-game
  brightness and timing are pending.

---

# Current Development Status — November 7, 2026 — Trigger scale animation

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `2850a526ad3d378d6225a837792f6648bc7c33b4`.
The two-client native handoff and physical F710/FightPadPro checks remain open.

- `//xb fade off` then `//xb triggerscale on` opts in. The shared idle
  size defaults to 95% of HUD scale. `//xb triggerscale 0.90` sets it to
  90%, with 75–100% accepted. `//xb triggerscale status` reports the option.
- With Always visibility, hold L2 or R2 and check the selected side reaches
  normal size while the other stays small. On release both settle at the
  saved small size. Each bank keeps its center through the 120 ms transition.
- With Autohide, the selected single bank opens small and pops to full size.
  Releasing the last trigger hides immediately. Combined and double-tap banks
  draw at full size. Fade-on mode and menus use normal scale.
- The Lua fixtures exercise positions, scale endpoints, fields, special
  banks, menu behavior and immediate hiding with mocked Windower drawings.
  In-game timing, readability and alignment still need live review.
- Deferred design notes: larger centered italic white timers, possible
  upper-right MP/TP costs, and centered action labels.

---

# Current Development Status — November 7, 2026 — Shared physical controller mappings

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint for this two-commit batch: `bccffc33e80a4248cdbf8cf9b06745a8b8deb003`.
The most recent user-confirmed Xbox result was the earlier isolation run.

The reader and DLL now consume generated physical tables from
`packaging/controller_mappings.json`. PS5 and F710 share a layout,
FightPadPro keeps its face-button order, and both XInput profiles use
physical LT/RT. The alternate still uses RB for the chooser.
Logical DirectLink codes and saved bindings stay compatible.

Generation consistency, the portable C++ mapping fixture, the Lua suite
and exact-source staging were checked locally. Windows CI verifies the
generated files and runs the real x86 and AHK fixtures before packaging.
Use the complete artifact, including `controller_mappings.ahk` and the
matching DLL. Close all FFXI clients and stop the shared reader before
installing. See the next section for the live two-client lifecycle check.
Physical F710 and FightPadPro checks remain open. Animations are the next batch.

---

# Current Development Status — November 7, 2026 — Addon-owned native hooks

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `bccffc33e80a4248cdbf8cf9b06745a8b8deb003`.

The user accepted the Xbox isolation result for community experimentation.
Physical LT/RT are restored. No additional local Xbox hardware round is planned.

The addon now suspends the native guard and releases controller ownership on
wrapper stop, logout, or graceful restart. Unload also detaches this client's
hooks by default. The shared wrapper follows the last-client policy. The
native bridge starts in pass-through until it receives a Lua context and
rearms from neutral after a lost message lease. Native pad status separates
filtering from pass-through and reports the hook state. The DLL stays pinned
because detachment does not establish that every callback has returned.

The local Lua suite passed, including independent mocked clients, wrapper
stop/restart, same-reader login recovery, reload, and detach reporting. The
portable C++ fixture passed. Windows CI builds the DLL and exercises concurrent
XInput polling across detach/reattach. This is a hook test, not DLL unloading.

Live Windower check with two clients on the same profile: unload one addon
with its trigger held and confirm native controls return immediately. Switch
to the second client and confirm the wrapper is still running and its guard
works. Reload the first addon, release to neutral, and verify a fresh chord.
On wrapper stop/start, inspect `//xb nativepad status` and repeat the handoff.
Close all clients before installing or replacing the matching x86 package.

---

# Current Development Status — November 7, 2026 — Standard XInput triggers

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `959414d8432ee4c22e03429a754212d4ab1095d8`.

- The user reported the Xbox isolation run worked well enough to leave further
  physical XInput experimentation to the community. The earlier wired Xbox
  360 LT spikes remain recorded below. There is no additional local Xbox
  hardware run planned.
- Standard XInput uses physical LT and RT again. The temporary LB substitution
  and unconditional LT masking were removed from the reader and native
  bridge. Both XInput profiles use the original trigger threshold, and the
  alternate profile still uses RB for the chooser.
- A nonnumeric DirectInput POV sample now follows the existing disconnect
  path, releasing held input and waiting for neutral before rearming. The
  AHK regression covers unavailable POV, a centered hat, and a diagonal.
- The portable C++ ownership and mapping fixture and local Lua suite passed.
  Windows x86 CI runs the native and AHK fixtures and packages the complete
  addon on the published commit. These checks do not exercise live FFXI.
- Close all FFXI clients and stop the shared reader before installing the
  complete matching x86 artifact. Preserve existing settings and bindings.
  The next controller milestone is addon-owned hook lifecycle and shared
  Windows mapping definitions.

---

# Current Development Status — November 7, 2026 — Friendly icon-picker folder labels

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`, starting
source checkpoint `7cad8004dc6b98a830a9663d39d9340d700c7a58`. Most recent user live feedback: White Magic
ascending ID and weaponskills descending ID preferred. Job Ability, Song and
Trust role/portrait sorting remain awaiting live acceptance.

## Icon-picker labels only

The navigable icon picker presents folder names in friendly title case,
including Blue Magic, Rune Enchantments, Phantom Rolls, Weapon Skills,
Pet Commands and the acronym UI. Breadcrumbs use the same visual labels.
The underlying folder names, selection IDs, relative icon paths, casing,
stored icon fields, artwork fallback and icon pack contents are unchanged.
The separate legacy flat picker is not changed because it has no folder rows.

The user-provided `test.zip` contains a curated default icon pack:
553 PNG icons versus 900 PNG icons in the original repository default
iconpack; 41 Trust portraits, all 91 UI assets, 24 Job-folder files and
selected other categories remain. Its `icon_list.txt` listed 464 entries,
all present, with no unlisted non-UI PNGs. The user's archive remains a
personal test asset and was not uploaded to the public GitHub repository.

Verification: `tests/icon_picker_folder_labels.lua` asserts visual
labels and breadcrumbs while checking that navigation and saved paths
continue using actual names. The existing Lua tests and Windows CI
are run on the published commit. No Windower/FFXI in-game test of the
new labels has been performed yet.

Installation: replace only `addons/xivcrossbar/action_binder.lua` on
the current Public Beta branch, run `//xb restart`, and open the
Change Slot Icon / Change Action Icon folder picker. Inspect folder rows
and nested folder title, select an existing icon, and verify it saves
and displays after reload. No icon files are included or changed.

---

# Current Development Status — November 7, 2026 — Job Abilities, Songs, Trust portrait/role sort experiment

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`, starting source checkpoint
`9d070b9353ffc2af96263f7d55c48a108db4af12`. Last user-observed FFXI behavior: White Magic ascending IDs and
weaponskills descending IDs both preferred over the former alphabetical lists.

## Action binder order (test batch)

- Job Abilities: ascending resource ID; available/eligible abilities and excluded
  submenus remain unchanged.
- Bard Songs: ascending spell ID; White Magic remains ascending ID; Weaponskills
  remain descending ID. Other magic and ability categories retain prior ordering.
- Trusts: custom name-specific portrait found in the ACTIVE icon pack first,
  unportrayed Trusts second. Within both sections, role precedence is:
  passive/non-interactive special, healer, tank, support, offensive caster,
  physical ranged, then melee/unclassified, with ascending spell ID ties.
  Roles are a curated and incomplete presentation taxonomy; unidentified Trusts
  fall to the final bucket. 'Special' means untargetable passive aura, not every
  alter ego whose wiki job is called Special. Portrait availability is checked
  in the user's selected icon pack, with unchanged fallback to game spell icons.
- No changes to custom icon files, icon_list.txt, generators, known spells,
  action targets, bindings, saved settings, AHK, native blocker, or controller.
- The existing `images/icons/iconpacks/default/GENERATE_ICON_LIST.bat`
  refreshes `icon_list.txt` after manual PNG deletions. The batch script calls
  `BatchSubstitute.bat` to strip the current absolute path; this test does
  not run or alter either script.
- Verified before publishing: Lua 5.4 syntax parse after source-preserving
  Windower string normalization; comparator fixture on 11 sample Trusts
  and prior JA/Songs/White/WS sort markers. In-game Trust and JA/Song
  selection results still need live verification. Automated CI runs after push.
- Install only `addons/xivcrossbar/action_binder.lua` from this commit and
  `//xb restart`. Return to the selector and inspect order/icons.
  Restore prior `action_binder.lua` to reverse.

References for curated roles (not normative): FFXI official Trust role
description and community Trust spell-icon role families. Curation is
experimental, with no claim of an exhaustive live roster mapping.

---

# Current Development Status — November 7, 2026 — White Magic and weaponskill ordering experiment

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch `experiment/messages-native-all-profiles`.
Source checkpoint: `7bec8ad2db74662feb42bc8d7425c62f5f4f8cb1`. User confirmed in FFXI that the standalone White Magic
ascending-ID patch was substantially more natural to browse than alphabetical.
This commit preserves that tested White Magic behavior and tries **descending
resource ID** for the weaponskill selection list only.

## Selection ordering test

- `action_binder.lua`: White Magic `a.id < b.id` (prior standalone live
  experiment), weaponskills `a.id > b.id` (new, awaiting in-game feedback).
  All other magic and ability menus retain their existing alphabetical sort.
- No changes to spell/WS eligibility, known actions, targets, icons, gamepad,
  AHK, native DLL, saved data, action execution, or bindings.
- User is independently curating the default icon pack; icon files were not changed.
- Static verification: targeted source diff and comparator/order assertions.
  No FFXI live test of descending WS order yet. Ascending IDs are not the same
  as required combat skill or learned level; this is an exploratory sort.
- Install: replace only `addons/xivcrossbar/action_binder.lua` while unloaded
  or outside the binder, then `//xb restart`. Check White Magic retains ascending
  IDs, weaponskills appear descending, and other lists remain alphabetical.
- Reversal: restore the prior `action_binder.lua` from backup.

Delivery: single-file standalone patch built from the user's previously tested
White Magic patch, with one additional weaponskill comparator change.

---

# Current Development Status — November 7, 2026 — Xbox 360 LB/L2 isolation test

Repository: `rerorriM-Mirrorer/xivcrossbar`, branch
`experiment/messages-native-all-profiles`. Source checkpoint:
`75becceaa35599f942bc4bb5c7931e08e149b332`. Temporary input-only experiment; NOT live verified.

## Wired Xbox 360 input substitution

**Superseded November 7:** The branch restored standard LT/RT. This section
records the isolation build and is retained as test history.

The standalone XInput probe observed unintended LT peaks of 80–146/255 when
moving the analog sticks. Previous native/message diagnostics independently
showed phantom logical button 11 edges under both sticks and no dropped
messages. This build isolates the noisy sensor without changing Lua bindings:

- Standard `xinput`: LB -> logical button 11 (L2), including double taps and
  LB+RT chords. The AHK reader ignores analog LT even above its former 4/255
  threshold. RT and other logical controls remain unchanged.
- The native XInput guard captures LB according to logical L2 ownership and
  sets physical LT to zero while its focused, live guard is active. If the
  guard is unavailable/stopped, native behavior still fails open.
- `xinput-r1-chooser` (`xinputalt`) and PS5/F710/FightPadPro remain unchanged.
  No existing character bindings, display logic, DirectLink transport, or
  timing machinery was modified.

**Installation/test:** Stop the shared wrapper, close every FFXI process,
back up the addon, and install the complete matching Windows x86 artifact,
including its newly built `native/xb_gamepad_messages.dll`. Select
`//xb controller profile xinput`, use `//xb controller status` and
`//xb nativepad status`, and test LB hold/release, LB double tap, LB+RT,
ordinary RT, analog-stick movement with no phantom L2, bare navigation,
chat, native menu, and rearming after focus switch or addon stop. Run
`//xb diagnose` on the analog-stick test and compare button-11 edges.

**Verification:** Initial Windows CI run 42356792441 compiled the x86 DLL,
passed both C++ native fixtures and the Lua suite, but stopped before packaging
because the AHK fixture still expected LT >4 to activate standard XInput.
The fixture was updated to exercise standard LB, ignore even LT=255, and
preserve the alternate physical-LT behavior. The replacement CI result and
live Windower/FFXI verification remain pending. This batch does not implement automatic unloading
of the native DLL. The bridge currently pins its module; the agreed request
to load/unload it with addon or wrapper lifecycle remains outstanding and
must be addressed separately, after this test.

---

# Current Development Status — November 7, 2026

Lockout visibility fix for `experiment/messages-native-all-profiles` in
`rerorriM-Mirrorer/xivcrossbar`, based on `9f5b3ef`.

## Lockout strip with Auto

Lionstag reported the lockout bars were hard to see. Previously the strip
only updated while the crossbar was visible and inherited its opacity.
The strip can now show at its configured opacity after the slots fade out
in Auto. It still respects explicit Hide, per-action opacity, and Event
visibility. The skillchain indicator remains independently configurable.

Unload XIVCrossbar and overlay this cumulative Lua patch on the `cbbad60`
native test install or its first display-preset patch. Load the addon and
select `//xb display xi`. Cast a short spell, release the trigger before
completion, and check that only the lockout strip appears afterward.
Repeat with a weaponskill and a job ability. Keep `//xb skillchain off`
during the check to verify the controls are independent.

The local Lua suite passed, including triggerless Auto visibility,
independent opacity, expiry, explicit Hide and status-4 cases. Live
FFXI visibility is pending.

---

# Current Development Status — November 7, 2026

Display preset patch for `experiment/messages-native-all-profiles` in
`rerorriM-Mirrorer/xivcrossbar`, based on `cbbad60`. Lionstag confirmed
PS5 startup, binding icon cleanup, and Up/Down blocking with both triggers
at a Survival Guide. A bound echo still needs a live check.

## Display presets and Event visibility

`//xb display` toggles presets, with XI selected on first use. Use
`//xb display legacy`, `//xb display xi`, or `//xb display status` explicitly.
The preset saves immediately. Existing installs use their current appearance
until a preset is selected.

- Legacy uses always-visible bars, configured MP/TP and lockout colors,
  no crossbar fades, and the original shared flash. It keeps the current layout.
- XI selects compact, trigger-driven visibility, crossbar and text fades,
  pale green affordable MP, blue affordable TP, and pink insufficient costs.
  The lockout bars transition from gray-blue to green for spells, pink for
  weaponskills, or blue for job abilities. The independent slot pulses sit
  above the normal flash.
- Auto can show the main bars when a trigger is held during status 4.
  Always-visible mode hides the main bars during status 4.

Overlay this Lua patch onto the complete `cbbad60` native test install with
the addon unloaded. Load it again and switch presets while in game. Test
an affordable and unaffordable spell, TP crossing 1,000, one of each lockout
type, then reload and check the saved preset. At a Survival Guide compare
Auto with a held trigger and Legacy. Check simultaneous slot pulses and
focus or trigger release while a slot is held.

The full Lua suite passed, including preset save/apply, cost threshold,
lockout endpoints, status 4 and DirectLink release. Live visuals are pending.

---

# Current Development Status — November 7, 2026

Hotfix for `experiment/messages-native-all-profiles` in `rerorriM-Mirrorer/xivcrossbar`,
based on `7f8fd18`.

## Binding preview cleanup

Lionstag's diagnostic showed the Attack preview stayed visible when Back
returned from Enter Button Combo to the target picker. The binder now
clears the combo panel, glyphs, action icon and captions when leaving that
page. Back from confirmation to the combo page still shows the preview.
The menu-resource fixture verifies image disposal and panel visibility on Back.

## Native module startup

The user reported the generic DLL compatibility warning on the previous
messages build. The archived DLL was PE32 and contained the PID callback.
The exact reason the live process rejected it was not captured. This build
uses a distinct DLL and entry point, separates file-load, Lua API and
process-ID diagnostics, and tests the module's registration with a Windows
Lua 5.1 API fixture. Close every FFXI process before installing the complete
build. Check `//xb nativepad status` and keep any new error verbatim.

---

# Current Development Status — November 7, 2026

Messages-only native guard test branch `experiment/messages-native-all-profiles`
in `rerorriM-Mirrorer/xivcrossbar`, starting from native experiment
`6c77a2602963be82fb5a8c0e67355adec350cd1a`. The prior public beta and
controller fallback remain available as separate builds.

## All-profile native blocking and DirectLink

The Windows reader sends twelve ordered DirectLink edges for every profile.
Each focused FFXI process publishes its own PID, profile, device, and token.
The guard waits for native game polls, neutral, and a reader heartbeat.
Without a compatible live hook or reader, FFXI keeps normal native controls.
No Apps/Ctrl or F-key capture, synthetic gameplay arrows, or IJKL routing
remains in this Windows path. Login, dialogue, and bare gameplay use the
existing FFXI Gamepad Config. Keep those assignments enabled.

Install the complete Windows x86 artifact in a backed-up test install. Stop
the old shared reader and close every FFXI process before replacing the DLL.
See BETA-QUICKSTART.md and native/README.md. Roll back by restoring the backed-up
addon with every process closed. No character settings or bindings ship.

| Profile | Physical check | Result |
| --- | --- | --- |
| xinput | Xbox A/B/X/Y, LT/RT, D-pad, View/Menu | Pending |
| xinputalt | Xbox RB opens chooser, Menu stays native | Pending |
| ps5 | DualSense DirectInput, Create/Options, both trigger orders | Pending |
| f710 | DirectInput mode, face labels and hat including diagonals | Pending |
| fightpadpro | DirectInput face ordering, Start/Select, D-pad and triggers | Pending |

For each profile, verify controller and native status, login, dialogue, bare
native controls, single/combined/double-tap chords, binder, chooser, chat,
and release ordering. Verify a held native direction stays native when a
trigger is pressed and a captured direction returns to FFXI after trigger
release. Check focus handoff between two clients, reader stop/start,
disconnect/reconnect and unload. XInput DLL variants and multiple attached
DirectInput devices need separate physical results.

All 22 local Lua fixtures passed, with 85 parsed sources. The portable C++
ownership and mapping fixture also passed. Windows CI and live FFXI are
separate checks. CI builds the x86 DLL and runs the Windows loader and AHK fixtures.
The first Windows run (42347180849) compiled and passed the x86 native tests.
The AHK fixture exposed that the detached lease still reported one neutral
transition as consumed. The reader now reports inactivity immediately. The
old review-key fixture was also updated for the separated callbacks. Use the
GitHub workflow result for the published head to verify Windows status.

---

# Current Development Status

Binding-screen polish on `experiment/native-gamepad-bridge`, based on
GitHub checkpoint `83d0fba` in `rerorriM-Mirrorer/xivcrossbar`. The user
preferred the original cursor height with the restored bounce. GripRumble
remains a separate optional test companion.

## 2026-11-06 — Binding preview and menu title backing

The binding screen shows a centered action icon and label above its prompt.
A translucent green tint marks the chosen slot only during binding
confirmation. The existing amber field marks the preview bank. Binder and
controller setup titles use a padded, semi-opaque text background. The
cursor stays at its normal height and long non-final-column captions are
fitted to leave a gap for it. Windower text still draws above image
primitives. The title backing can reduce overlap around the heading, but
other addons retain control of their own visibility.

Overlay the patch into Windower's addons folder and run `//xb restart`.
Try a spell, a custom action with a distinct alias and icon, and an existing
binding. Check that the preview stays visible while trying triggers. Choose a
slot on a single, combined, or double-tap bank, and verify the green tint on
that slot. Back out and confirm separately. Check compact and standard
layouts, a long neighboring label, and the title with EnemyBar2 open.

Local Lua regressions passed for preview redraw, Back, resource cleanup,
custom Save & Bind, crossbar destinations, compact geometry, text settling,
and combat overlay. Color, placement, and third-party layering still need
a live client check.

---

## 2026-11-07 — Slot acceptance tap and cursor alignment

Overlay the XIVCrossbar patch and run `//xb restart`. The cursor keeps the
bounce and returns to its original height except where a left-hand label
extends into its space. Check Select Action Type and a neighboring long label.

To try rumble, install GripRumble 0.1.17 separately and restart its Windows
helper. Load GripRumble and use `//grip slotpress` to feel the reference tap.
Enable the cue for the current XIVCrossbar load with `//xb slotrumble on`.
Run the following checks with the existing flash behavior.

- Valid bound action, regular switch, and quick switch: one tap per press.
- Empty slot, missing destination, and pet command without a pet: no tap.
- `//xb inputtest on`: dummy press still flashes and sends no tap. Turn
  Input Test off afterward.
- `//xb slotrumble off`: disable the tap. Reloading also turns it off.
  With GripRumble absent, action dispatch and flash still work.

The tap reports local acceptance. Combat cues still report the game result.
Lua simulation passed accepted and rejected actions, both switch types,
Input Test, cue opt-in and absence, and cursor positioning. Existing
crossbar-destination and menu resource regressions passed. The companion's
cue table and Lua command passed static checks. Live controller testing is
pending. The release build can remove the single emit call and test command.

---

## 2026-11-07 — Golden cursor bounce and caption clearance

The complete cursor sprites now step down one pixel every two frames and
reset at the end of the loop. The selectable-list cursor sits above the
caption line because Windower text renders above image primitives.

A local Lua fixture passed the six-frame sequence and reset, alignment of
the four image layers, sizing, hide, and cleanup checks. The live check is
to overlay the patch, run `//xb restart`, and watch the cursor loop in
`//xb menu`, including in a column beside a long label and on page controls.

---

## 2026-11-07 — Golden cursor crop correction

The transparent divider rows are at atlas y=0, 21, 42, and 63. The six
32×20 crops now start at y=1, 22, and 43. Local checks verified that each
crop covers exactly one complete sprite and that all six saved PNGs match
their atlas crops pixel for pixel. The renderer and animation are unchanged.

Back up the existing cursor folder, overlay the patch in Windower's
`addons` folder, run `//xb restart`, and open `//xb menu`. Check both
arrow edges through a full loop. Live verification of the new crops is pending.

---

## 2026-11-07 — Golden cursor atlas extraction

The six cursor frames now use the DXT3 alpha indicated by the original
`51.DAT` atlas. Decoding the same payload as DXT5 reproduced the previous
PNGs exactly. Crop bounds, frame order, and playback timing are preserved.

Local checks passed for the source hash, all 3,840 alpha samples against
the raw DXT3 nibbles, and all six PNG round trips. In-game appearance is pending.

Back up `images/assets/menu/cursor`, overlay the patch into Windower's
`addons` folder, and run `//xb restart`. Open `//xb menu` and watch the
cursor on one option and while moving between options. Check for dark lines
and legibility. To roll back, restore the cursor folder and restart the addon.

---

# Menu browsing and compact startup

- User reported repeated successful Trust paging. Cold startup could render Full while saved Compact was true. UI setup now reads the current setting after character initialization.
- Icon browsing and recursive icon selection use Windower directory APIs. Picker directions repeat after 350 ms and wrap along the current row or column, skipping unavailable cells. Release, page changes, focus loss, and closing the picker cancel repeat.
- Live: cold-start Compact, enter nested icon folders without a console flash, and hold all four directions in a sparse picker. Cursor texture cleanup and inherited icon flicker remain open.

---

# Graceful XIVCrossbar unload command

- User confirmed the shared AHK wrapper exited on unload and returned smoothly on load. Added `//xb unload` using the existing fade and cleanup path, followed by Windower unload.
- Live: verify the alias follows the same shutdown path, then repeat with a second loaded client to confirm the shared reader stays alive until the last unload.

---

# Shared AHK last-client shutdown

- Ported the personal branch owner-file registry. AHK keeps running while any registered client is loaded, including minimized clients. After the final unload it waits two seconds before exiting. StopWrapperAfterLastClient defaults on and can be set false in settings. The old forced-off field does not override this setting.
- Live: update the Lua and AHK files as a set, restart the old wrapper, test one client and then two clients. Unload one client first, then the last. Confirm a quick reload within the grace period keeps the wrapper running.

---

# Held-trigger handoff

- Closing the XIVCrossbar menu keeps the held trigger bank available immediately. In automatic guard mode, releasing the final owned trigger returns held D-pad directions to FFXI after 120 ms. Face-button ownership remains through release. Buffered DirectInput replays a held POV value when space is available.
- Live: close the addon menu while holding each trigger, use a fresh face press, then hold a direction and release the trigger first. Check release before the delay and menu Cancel separately. DLL update requires a full client restart.

---

# Skillchain indicator opacity command

- `//xb skillchain off` sets opacity to zero; `on` restores the built-in default (220). The bare command toggles, and `status` reports the current opacity. Changes save and apply without a reload.
- Live check: toggle off and on during a skillchain window and confirm the indicator and saved value follow the setting.

---

# Native FFXI menus and crossbar chords

- Native FFXI menu_open no longer gates the guard or Lua controller router. Bare controls retain native passthrough; L2/R2 chords work over ordinary and battle menus. Chat still yields to native input, and XIVCrossbar menus still own their inputs. Automatic guard startup no longer prints the poll reminder.
- Live: test L2 and R2 with AutoHide over native main and battle menus, plus bare Up/Circle and addon-menu Cancel. Lua-only change; reload XIVCrossbar.

---

# Native hook detachment on addon unload

- Enabled by default. `//xb diagnose native detach off|on` changes the persisted option. Wrapper stop still disables filtering without detaching. Addon unload restores native entry points while retaining the pinned DLL and trampolines for in-flight callbacks. Reload with a ready wrapper re-enables the hooks.
- Live retest: load the guard, unload XIVCrossbar while AHK stays running, verify native controls, reload, and verify the guard and filtering return. Replacing the DLL still requires restarting FFXI.

---

# Automatic native guard alongside AHK

- Experimental default: start the guard once a matching AHK reader reports ready. AHK remains the sole addon action source. Missing/stale readers disable the guard; native poll activity is required before skipping bare keyboard equivalents.
- The guard filters polled and buffered trigger chords and addon-menu presses. Buffered ownership advances in event order and peek reads do not commit it. Native menus/chat use Windower context flags; validate the native battle palette separately.
- `//xb diagnose native pass` saves the opt-out, `//xb diagnose native auto` restores the default, and `//xb diagnose native status` reports the active guard.
- Live: leave FFXI bindings assigned, verify bare inputs, menu Cancel ownership, R2+Up release ordering, AHK stop/restart, client focus handoff, and Xbox parity. Trust and other addons are not yet live-verified against this guard.

---

# Live Up/Circle probe with AHK

- Lionstag confirmed native suppression with AHK stopped and raw/masked values 0x001, 0x040, and 0x041. With AHK running the native menu still reacted, consistent with the Lua gameplay fallback synthesizing keyboard equivalents.
- During the probe, bare Up and Circle no longer synthesize gameplay keys. Existing injected holds are released on activation. XIVCrossbar menu and trigger-chord actions retain their normal routing.
- Retest in a native main menu with AHK running, then try R2+Circle and restore passthrough.

---

# Buffered takeover ownership scaffold

- Portable fixture covers the proposed default Up/Circle passthrough, explicit capture override, and a captured Up surviving trigger release and a menu or policy change. Buffered consumers can distinguish captured release edges from fresh native presses. The live diagnostic hook retains its existing behavior.

---

# Buffered DirectInput diagnostic with AHK running

- Lionstag confirmed the LuaCore loader and raw Up/Circle masks, with buffered DirectInput reads preventing suppression in the prior build.
- Native input passes through by default. Use `//xb diagnose native block` with AHK running, `//xb diagnose native status` for counters, and `//xb diagnose native pass` to restore passthrough. This probe does not inject Lua actions. It filters both polled and buffered Up/Circle for the selected device, waiting for neutral before arming.
- Live check: keep AHK running and verify native Up/Circle only are suppressed, diagonals retain the other direction, other native binds and AHK crossbars continue to work, and passthrough restores fresh Up/Circle presses. Buffered full takeover remains out of scope for this diagnostic.

---

# Native probe — Windower C module and Circle\n\n- Lionstag reached addon setup but Windower had no ffi module. The bridge now uses package.loadlib and resolves the already-loaded LuaCore.dll exports. Missing exports return a loader error without installing hooks.\n- Probe mode captures D-pad Up and Circle/B together, including separate release ownership. The other controls remain native. Live acceptance remains pending.\n\n---\n
# AHK v2 shortcut startup

- The bootstrap creates a validated interpreter shortcut. Subsequent starts use the shortcut and the current profile handoff, with one bootstrap retry if the reader does not start. Stop or unload cancels the pending retry.
- Live check: first bootstrap may show a console. Stop and restart after discovery and confirm that the cached launch starts without it.

---

# Native gamepad bridge experiment — public AHK v2 baseline

- Experimental branch starts at public v2 checkpoint 9b718705f1276a940a2c672eb17ae6dd220c04ae. Session-only opt-in adds a per-process XInput and polled DirectInput hook, isolated Up probe, and Lua takeover route. See native/README.md for setup and rollback.
- Portable C++ fixture passed for Up-only filtering, unrelated inputs, release ownership, neutral rearm and both layouts. Simulated public Lua regression suite passed. Windows x86 build and DLL-load fixture run in the experimental workflow.
- Live FFXI verification pending for both APIs, especially the DirectInput polling implementation and format, LuaJIT DLL loading, context transitions and multiclient handoff. Buffered DirectInput is detected and left in pass-through.

---

# November 6, 2026 — Public v2 menu preview

- XIVCrossbar menus keep the HUD visible with dimmer icons and hide gameplay trigger fields. The binder exposes its selected bank for an amber field during binding selection and confirmation. Native FFXI menu routing is outside this change.
- A trigger held while the addon menu owns input must return to neutral before it can activate a gameplay slot.
- Simulated Lua regression suite passed. Live: check Select Trust paging, single/combined/double-tap bank previews in compact and standard layouts, and closing the menu while holding R2.

---

# November 6, 2026 — Public AHK v2 conversion audit

- Keep diagnostic request cleanup failures local to the diagnostic poll.
- Native fixture now forces a failed snapshot flush and checks that pending events survive and publish on retry. Physical DirectInput and XInput testing remains open.

---

# November 6, 2026 — Public AHK v2 snapshot write recovery

- Lionstag live report: DirectLink FileMove failed with a count of one and escaped the OSError handler. The snapshot writer now catches generic file-operation errors and lets the existing flush cadence retry unacknowledged events. The cause of the failed replacement is unconfirmed.
- Live retest: repeat controller use after setup on Lionstag. Confirm a failed replacement does not interrupt polling and that subsequent input recovers.

---

# November 6, 2026 — Public AHK v2 DirectInput hotfix

- Live report: selecting a DirectInput profile crashed on the first connected poll with invalid array index 5. The reader now appends eight buttons after the four POV entries.
- The Windows fixture calls the production reader with a simulated connected joystick. Recheck profile selection and controller input on physical hardware.

---

# Current Development Status — November 6, 2026 — Public Beta AHK v2 Test 1

- Branch `development/public-ahk-v2` starts at public Beta 1 commit `1f928a80e6187a772615c16b99d957625dff7ff1`. Personal v2 reference `ad368145a2790a5d947bb132f75c17732545ac66`. Read the current development guidance and testing history from both branches.
- Converted the public reader and its two supporting modules in place. Adapted interpreter discovery, the per-installation mutex, explicit shutdown and reader identity diagnostics. Kept the public profiles, Lua receiver, public defaults, routing and on-disk protocol. The public explicit stop and restart model remains in use.
- Native Windows CI covers both interpreter bitnesses, startup through CMD and launch INI, direct argument selection for all five profiles, duplicate-reader rejection, stop/restart and refusal of a non-AHK executable. The package job requires both native jobs and reruns the existing simulated Lua suite. This does not measure physical input.
- First live pass: one DualSense and one client. Confirm startup and the configured profile, IJKL and face bindings, L2/R2 and simultaneous/double trigger order, native menus, custom-action menus, diagnostic save and stop/restart. Compare against public v1 with equivalent settings.
- Then exercise two to four clients, rapid trigger input, held keys through focus changes, neutral rearm, reload/unload and disconnect/reconnect. Check for stale events, stuck keys, and duplicate or wrong-transport input. Test F710, FightPadPro and both XInput routes with actual hardware before accepting them.
- Recheck historical compact Options-hint flicker and diagnostic-save memory failure in game. Follow README for a whole-folder install and rollback. This testing branch is for live acceptance before any community release decision.

---

# Current Development Status — October 29, 2026 — Public Beta 1 Fresh-Install Defaults

- **Working repository/branch:** `rerorriM-Mirrorer/xivcrossbar`, `release/beta1-ps5-directlink`, following known-good automated `combatui1` checkpoint `50a67ee5f76f210c3c49f678dfac8f7ec4dfbbf4`; runtime `0.4.0-beta1.20261029.ps5-directlink-freshdefaults1`. Personal `development/directlink`, last-known-good stable/master and RC3 are untouched.
- **Requested new defaults (only):** `GameplayDPad='ijkl'` (bare gameplay D-pad arrows route via I/J/K/L), `Animation.TextFade=true` (text follows animated slots), `AutoAttackIndicator.Enabled=false` (do not estimate swings, default bar opacity remains zero), `VisibilityMode='oninput'` (trigger-based AutoHide). Existing fade times `0.1s` in, `0.5s` out, `2s` startup, and `TextSettling=true` remain unchanged. No new timer or command was introduced.
- **Important AutoHide finding:** `visibility.should_show('oninput', trigger_held, cutscene, startup_reveal)` has no elapsed-time post-trigger retention: it becomes false immediately after release, then the existing `FadeOut=0.5` completes. User is choosing whether a possible future 3/9/15/30-second hold duration belongs in beta, particularly considering longtime users. No such hold duration exists in this checkpoint; the decision is deferred.
- **Upgrade behavior:** Saved `data/settings.xml` values take precedence if already present. An installation upgraded from a base version which never serialized these new fields will receive the updated defaults for missing fields, which may surprise people accustomed to always-visible bars or bare arrow targeting. The short setup now specifically requires I/J/K/L assigned to FFXI **Menu/Target Cursor**, or `//xb dpad arrows`; the old always-visible mode remains available through `//xb show`/`//xb autohide off`, endpoint text via `//xb textfade off`, and swing tracking via `//xb autoattack on`. Treat these as fresh/missing-field defaults, not forced per-character overrides.
- **Regression coverage:** Updated `tests/textfade.lua` and `tests/combat_ui_beta1.lua` for the requested default changes while retaining explicit opt-outs. Added `tests/new_defaults_beta1.lua` for IJKL transport mappings, startup reveal/cutscene/trigger visibility, unchanged fade times, default tracking and text fade and compatibility of saved alternatives. These are simulated Lua tests, not a live Windower/FFXI validation; latest docs-head GitHub CI is to be confirmed.
- **Delivery:** Focused defaults-only change; continue preserving cumulative TESTING entries below, no direct modifications to saved character data, no new GitHub prerelease or stable promotion. `BETA-QUICKSTART.md` and README were updated with the requirements, settings and no-delay caveat. Any test installation ZIP must include README, WORKFLOW and cumulative TESTING inside the `xivcrossbar` folder.

---
# Current Development Status — October 29, 2026 — Public Beta 1 Combat Overlays and Options Cancel Parity

- **Repository and source baseline:** `rerorriM-Mirrorer/xivcrossbar`, `release/beta1-ps5-directlink`. Starting known CI-pass remote head `5def65d9ba3d194510c8a8feeeeebf8684b3d1c5`, runtime now `0.4.0-beta1.20261029.ps5-directlink-combatui1`. Personal `development/directlink`, public RC3 and master were not changed.
- **User request:** Include three known personal fixes before the public beta release: hide both skillchain indicator primitives at skillchain opacity zero, independently disable all autoattack swing estimation with `//xb autoattack off` (without conflating that with hiding the bar), and restore ordinary slot-frame art when a skillchain helper animation no longer applies. Audit other menu changes not yet brought from personal. No speculative feature work.
- **Skillchain bars:** `ui.lua:display_skillchain_indicator` now first checks `self.theme.skillchain_window_opacity == 0`, hides BOTH progress/background prims, then returns; the previous active-timer drawing path is unchanged at nonzero opacity. Setting remains XML `SkillchainIndicator.Opacity=0`, not a new CLI.
- **Autoattack estimate:** Added `AutoAttackIndicator.Enabled=true` to defaults; carried via `theme.lua` as `aa_enabled`; `ui:set_autoattack_enabled` gates recording/engagement/pause tracking and redraws, resets historic interval/estimate/engagement on changes, and invalidates older scheduled pause callbacks by generation. `xivcrossbar.lua` gates melee, WS, JA and gain/lose buff processing when disabled. `//xb autoattack [on|off|status]` saves and reports this independently of opacity; when switching ON during battle it resumes from fresh engagement state. Existing bar hide at `AutoAttackIndicator.Opacity=0` is preserved, but this does not stop estimation unless Enabled=false. `status` and `help` now list the toggle. Real game attacks are unaffected.
- **Contextual frame:** When a rendered action lacks a valid skillchain property, `ui:check_recasts` restores base `slot_frame` artwork and full alpha even if it is warming up, eliminating the prior sticky animated helper frame; a valid skillchain property continues its existing animated-frame presentation. No icon assets or frame sequences changed.
- **Additional menu regression discovered and fixed:** Beta's root Options/set chooser calls `action_binder:is_cancel_button(button)` for face-button cancel, but the beta binder lacked that function. Ported only the personal layout-aware mapping (PS/Xbox/GameCube/Nintendo) to prevent a nil-method error and honor saved cancel mappings. Existing root chooser logic is unchanged.
- **Other menu parity findings (audit only, not automatically imported):** Most underlying custom-action Review/Save & Bind, physical Review arrows/Enter/Escape, page navigation/back state, compact-specific hints, list drawing and menu layout are already in beta. Personal SMN Blood Pact picker uses `libs/blood_pacts` and filters native currently available pacts, whereas public binder still populates Rage/Ward by scanning broad resource entries. Personal chooser displays the old Basic set as `Main` and has personal catalog bank names; this is deliberately private rather than a public release requirement. Personal first-install profile selector offers extended reader profiles, which are explicitly unavailable in public and not to be ported. The proposed setup R2 live-highlight was discussion only and has not been implemented as a shared base change. No wholesale binder diff was imported.
- **Verification:** Added `tests/combat_ui_beta1.lua`, dynamically executing extracted public `ui.lua` skillchain primitive visibility and autoattack estimate state/toggle functions under mocked Windower; tests both opacity zero/positive, record/stop/reset behavior, pending callback isolation, saved default/theme propagation, and real slot-frame reset snippet. Added four-layout Options cancel regression against actual `action_binder.lua` helper. Existing suites include DirectLink edge/login, custom-action editor return, review keyboard, simulated text settling, text fading, compact grids, status/help formatting, diagnostics and package integrity. Automated results are Linux Lua 5.4 with temporary Windower source normalization; do not describe as native FFXI.
- **Live acceptance pending:** On an isolated beta installation, set `SkillchainIndicator.Opacity=0` in XML and confirm neither bar nor background remains visible while an SC timer is running; then test a nonzero opacity. Set `//xb autoattack off` and confirm no estimator runs or renders, re-enable and confirm fresh learning without stale results; retain existing zero-opacity bar visibility mode. Switch into/out of an eligible WS/SC hint during recast warmup and verify the normal slot frame returns. Open Options chooser and press the configured controller Cancel face button; confirm no Lua error. Previous compact Options flicker and diagnostic save memory regression still await direct in-game verification.
- **Release boundary:** Automated regression and packaging completion on the documentation-head commit must still be checked before distributing. No GitHub tag/release or native hardware acceptance is claimed. Keep full history below and include `WORKFLOW.md` / `TESTING.md` inside the installable addon ZIP.

---
# Current Development Status — October 29, 2026 — Public Beta 1 Review Keyboard and Color-Coded Messages

- **Repo/branch and source checkpoint:** \`rerorriM-Mirrorer/xivcrossbar\` on \`release/beta1-ps5-directlink\`; starting published head \`444ca7c2b989c5817b8ee6ec0316e34369cdcb98\`, runtime target \`0.4.0-beta1.20261029.ps5-directlink-releaseui1\`. This patch alters only Beta 1. Personal \`development/directlink\`, RC3 and stable/master are unchanged.
- **User request:** Port the already-developed physical keyboard navigation in custom-action Save/Review (arrows for navigation, Enter to choose, Escape to back out), and migrate remaining public user-facing chat messages to the agreed BattleStations-inspired style, **no feature creep**. Remind the user after delivery to ask about polishing remaining messages in the *personal* DirectLink branch.
- **Review keyboard:** Ported \`libs/controller/review_keyboard.lua\` from personal. A new \`action_binder:is_keyboard_review()\` predicate limits handling to visible \`EDIT_CUSTOM_ACTION_REVIEW\` and \`CONFIRM_CUSTOM_ACTION\` screens, not inline text fields or set chooser. Root physical \`controller_keyboard\` invokes review handler **before** generic Escape and text confirmation; gated by game focus, no prior block, not restarting, no chooser, no field-owned Enter. Edge ownership through key-up prevents typematic repeat, pre-held key activation and Enter/Escape release leaking into FFXI. The DirectLink message path is intentionally excluded. Old input text entry, controller face/menu binds and gameplay routing remain intact.
- **Chat presentation:** Added \`libs/chat_status.lua\` and \`libs/chat_help.lua\` adapted from the personal formatters, with the project's additional palette: [XIVcrossbar] purple 200, headings purple and separators 140, syntax/labels blue 207, descriptions/values white 0, ready/ON green 158, pending 140, errors 167. The original root single-color help is replaced with grouped full \`//xb\` syntax + explanatory arrow on chat channel 0. Root \`//xb status\` and \`//xb controller status\` now have readable headings/field rows, state and relevant input mode (rather than dense raw counters). Root command responses, argument errors formerly printed exclusively to the console, binding and set feedback, \`action_binder.lua\`, \`player.lua\`, \`ui/icon_extractor.lua\`, \`gamepad_converter.lua\`, diagnostic callbacks, controller responses and display toggles now use the common formatting emitter. Existing input diagnostics \`[XIVCrossbar test]\` remain explicitly diagnostic chatter; log file content and user-authored commands are not recolored or rewritten.
- **Regressions and tests:** \`tests/review_keyboard.lua\` ports the six-key fixture and exercises the *actual public root keyboard prefix* with mocked Windower keyboard handling, including field-owned Enter and DirectLink isolation. \`tests/chat_formatting.lua\` asserts the help/status palette, binding values, errors, green ON, chat-only standard output and absence of console-only argument errors. Existing isolated testing fixtures (\`compact_command\`, \`crossbar_destinations\`, \`custom_action_save_return\`, \`login_input\`, \`profile_gate\`, \`profile_lifecycle\`, \`shared_command_regressions\`) supply a chat emitter where extracted handlers previously expected direct console output. Automated CI passed for the runtime checkpoint including simulated Lua 5.4 Windower syntax-normalized source/regressions, Python syntax and full install packaging; latest documentation-head CI still to be verified.
- **Scope limitation:** No native Windows/AHK/FFXI live run. Color rendering with Windower's actual \`chat\` library and physical keyboard focus/blocked behavior are inferred from the existing personal implementation and simulated checks. The previously observed compact hint flicker and diagnostic memory failure still await user testing on the recent beta.
- **Minimal live acceptance:** Open a saved custom-action Review screen: arrow keys move the highlighted choice, Enter selects it, Escape goes back, and typing into Name/Alias/Command still works. Verify \`//xb help\`, \`//xb status\`, and \`//xb controller status\` for purple headings/identity, blue commands/labels, white values, green readiness and red errors. Check no physical key escapes to FFXI during Review, and native arrow/Enter keys remain unchanged outside the addon. \`BETA-QUICKSTART.md\` documents only the short setup/new command list.
- **Release boundary:** This remains a public *beta* candidate, not stable; GitHub packaging alone is not a tagged prerelease or live acceptance. Continue to keep distinct whole-folder backups and never merge with personal \`data/\` or source.

---

# Current Development Status — October 29, 2026 — Beta 1 Caption Settling and Terse User Guide

- **Working repository/branch:** `rerorriM-Mirrorer/xivcrossbar`, `release/beta1-ps5-directlink`, following verified previous beta source head `0a3c74205b1be8a78c7340b4896368889fdd447f` and existing runtime `0.4.0-beta1.20261029.ps5-directlink-textfade1`. The existing personal build is the narrowly inspected source of the previously user-tested text-measurement technique; **personal `development/directlink`, RC3 and `master` were not changed**.
- **User request:** Fix the text/caption flicker with the established settling approach, confirm inline keyboard editing on the custom-action Save/Review screen, and provide a terse new-user README with only additional setup and public commands. Do not introduce personal companion banks, layout changes or new input routes.
- **Keyboard editing already present, no code change:** `action_binder.lua` supports `EDIT_CUSTOM_ACTION_REVIEW`, `display_inline_custom_action_entry` and `custom_action_review_field` for Name, Alias, Command; Save Only returns to catalog, Save & Bind continues to button assignment. Prior `tests/custom_action_save_return.lua` and menu resource regressions already covered this behavior; not ported or rewritten.
- **Caption flicker repair:** Added the personal-derived bounded frame-based `ui/text_measure.lua` (two matching valid widths on distinct prerender frames, 512-entry bounded key cache, eight-frame fallback), wrapped *only text* object measurement and three native alpha channels in public `ui/resources.lua`, switched centered-label paths in `ui_geometry.lua` and `ui/text_layout.lua` to `measure_width`/commit only after correct positioning, and begin the measurement frame at the start of public prerender. Newly changed captions are transparent while a native extent from the preceding caption might be returned. This preserves UI ownership and public resource API, avoids importing personal image assets/renderer/shortcuts, and does not modify menu or controller routing.
- **Text fade compatibility:** The previous `//xb textfade [on|off|status]` remains independently configurable and defaults OFF. During measurement suppression, requested text, stroke and backdrop opacities are remembered; after committing a stable center, the native alpha is restored to the current fade value. No new fade timings or startup behavior.
- **Setting and command:** `TextSettling=true` by default, saved in settings, with `//xb textsettle [on|off|status]` as the optional comparison/diagnostic switch. Version `0.4.0-beta1.20261029.ps5-directlink-settling1`.
- **Terse newcomer guide:** `BETA-QUICKSTART.md` included alongside `README.md` in the installable addon folder. It limits guidance to the extra AHK v1 single-reader/setup constraints, PS5 DirectLink profile and FFXI gamepad duplicate-key avoidance, optional IJKL mapping, new toggle/status commands, and a short note about the already working inline custom-action editor. Full README and historic TESTING are preserved.
- **Regression plan and limitations:** Existing 71-source Lua parse and regression suites, compact grid, menu lifecycle, diagnostics, local libs and text fading run in Linux Lua 5.4 with temporary Windower syntax normalization. New `tests/textsettle.lua` reproduces stale width / two consecutive stable frame samples, cache reuse, bounded fallback, real proxy/native alpha suppression, fade restoration, and object cleanup. The behavior was previously user-confirmed in the personal build; **this new public port has NOT been live-tested in Windower 4 or FFXI**. Windower's proprietary native measurement timing and appearance still need real-world verification. Previous compact hint flicker and diagnostic save memory failures were observed on older builds and remain unconfirmed after their targeted simulated fixes.
- **Focused live acceptance when convenient:** Keep the beta installed separately from the personal build; in game use `//xb textsettle status` (ON), `//xb fade on`, `//xb textfade on` and change a bound alias/repeatedly open and close binder menus while switching bars. Watch for delayed labels vs wrong-position flashes, and check that editing Save/Review retains inline keyboard input. Restore `//xb textfade off` for original endpoint opacity; no exhaustive feature audit is needed.
- **Publishing boundary:** New GitHub test ZIP and remote-head SHA must match the final documentation commit. CI/static or simulated success is not a native Windows/Windower/FFXI acceptance and does not create a GitHub prerelease.

---

# Current Development Status — October 29, 2026 — Beta 1 Optional Text Fading (No Other Feature Port)

- **Repository/branch:** `rerorriM-Mirrorer/xivcrossbar` / `release/beta1-ps5-directlink`; base was upstream qEagleStrikerp source `15d8381dfad0f9efdb84fe2d24655afc150faec4`. Prior beta runtime/source head `47ef6cf5fe8088871986cb0a88d6b363abcf8fab`. Personal `development/directlink`, public RC3 and `master` remain untouched.
- **User request:** Add only the existing personal feature to make crossbar text fade with artwork, then enumerate user-visible improvements over the upstream base. User previously said **NO FEATURE CREEP**; this is a single requested opt-in appearance feature, not the personal renderer or a command/help redesign.
- **Implementation:** `//xb textfade [on|off|status]` and `//xb ui textfade` control a saved `Animation.TextFade` boolean; bare command toggles. Defaults **OFF** to preserve the previous endpoint-visible caption behavior. `theme.apply` carries the preference to `ui:setup`, and `ui_geometry.lua` changes only alpha/visibility for native text surfaces. With option ON, text glyph, backdrop and stroke opacity follow crossbar fades, including through a deferred fade-out; `set_text_fade` can apply immediately mid-fade without recreating surfaces, modifying input or recentering labels. Regular `//xb fade` behavior and durations are independent and unchanged. The personal text measurement, settling algorithm, and banks are NOT ported.
- **Implementation source commits:** `5d84c0f` defaults; `9e4996e` theme; `d636aca` geometry; `eb0fbd3` UI initialization; `344f5ae` root command/help/version; `673a326` and later fixture corrections for `tests/textfade.lua`. Cumulative history below is preserved.
- **Verification:** The dedicated Lua 5.4 simulated `tests/textfade.lua` checks old default, persisted saved preference wiring, intermediate glyph/backdrop/stroke alpha, retained text through fade-out, live off/on change, unaffected image fade, and command source wiring. Existing controller, menu, resources and diagnostics suites run in CI with temporary syntax normalization. **No native Windower 4/FFXI visual acceptance has been performed**; text fading's appearance and potential flicker remain in-game checks.
- **Beta's previously observed live issues remain historically recorded below:** Old public controller/help message formatting, compact Options-hint flicker and `Diagnostic save failed: not enough memory` were observed on an earlier beta. Targeted compact-hint and streaming-save fixes passed CI but have not been re-tested in FFXI; do not call them confirmed resolved.
- **Focused next check:** On the isolated beta installation, run `//xb status`, `//xb fade on`, `//xb textfade status`, `//xb textfade on`, then reveal/hide the crossbar with `//xb auto` and L2/R2. Confirm text and strokes fade in/out with images, text remains centered, and `//xb textfade off` restores endpoint-only labels. Verify preference after `//lua r xivcrossbar`. No other feature acceptance is required for this change.
- **Release state:** Source-only/simulated candidate pending final documentation-head CI packaging and optional public beta prerelease. Do not claim tag, GitHub Release, native AHK acceptance, or stable promotion based on the CI results.

---

# Current Development Status — October 29, 2026 — Beta 1 Stabilization: Diagnostic Memory and Compact Hint

- **User-observed live blockers:** On the freshly loaded Beta 1 after the xml2 module fix, the old public formatting remained in `//xb controller status` and help output; the Options/Share UI hint flashed into view in compact mode; `//xb diagnose` eventually printed **"Diagnostic save failed: not enough memory"**. User explicitly requested **NO FEATURE CREEP**, a working/releasable beta, and asked for the text-with-bars fade command and why InputTest was recommended.
- **Scope correction:** `//xb inputtest on` was an inappropriate recommendation for unified diagnostic acceptance: it changes actual slot actions to dummy messages, and the 30-second diagnosis should observe real input. The next test must start with `//xb inputtest off`. Extra set-management tests were inherited functionality, not new Beta 1 requirements, and are outside the focused acceptance pass. Public RC3 messaging/help formatting was intentionally not ported from personal in this patch; personal `//xb textfade on|off|status` is **absent** from Beta 1, whose renderer retains endpoint text visibility.
- **Confirmed compact-state exposure:** `ui.lua:show_button_hints()` previously unconditionally showed four controller hint objects. Calling it from any menu/fade pathway could momentarily revive Options/Share while compact even though other callers try to suppress them. The show function now hard-blocks this if `self.is_compact`, using existing `hide_button_hints()`. No additional rendering engine or UI feature is imported.
- **Diagnostic memory-pressure remediation:** `diagnostic_session.lua` previously cloned up to 12,000 Lua events plus up to 6,000 render trace events and the AHK feed into a sorted array and built a large `table.concat` body before the single file write. `diagnostic_bridge.lua` now provides `write_stream` to write each merged chronological line to an adjacent temporary file, close it, and atomically rename it into the final result. `diagnostic_session.lua` uses a three-way chronological merge over existing Lua, render and lazily parsed AHK streams. It does not build a full extra result table/string in production; buffer caps, all event sources and AHK cleanup behavior remain unchanged. The old in-memory writer is retained solely as a compatibility path for isolated fake-filesystem tests.
- **Confidence and uncertainty:** The final-allocation spike is an identified design problem compatible with the user's **"not enough memory"** report, but the exact native allocation failure has not been independently reproduced. The new code substantially reduces save-time allocations; Windows/Windower in-game testing is still required. A process already severely memory-constrained could still fail.
- **Regression coverage:** Updated `tests/diagnostic_beta1.lua` to require streaming (the legacy writer raises an error in the stress fixture), merge >3,000 observations, check chronological output, confirm LUA/RENDER/AHK presence and capped-event drop reporting, and check the compact hint guard. Prior diagnostics, module-loader, controller and UI source suites are retained. Source tests use Linux Lua 5.4 temporary syntax normalization, not native Windower 4 Lua 5.1.
- **Runtime:** `0.4.0-beta1.20261029.ps5-directlink-diagstream1`. Includes previous `libs/xml2` loader hotfix; no changes to profile input mappings, custom action catalogs, text settling, message formatting, or personal banks. Personal `development/directlink`, RC and master remain unchanged.
- **Exact in-game next pass:** (1) Confirm version with `//xb status`; (2) `//xb inputtest off`; (3) `//xb compact on` and open/close crossbars and Options menu during fades; no compact hint should flash; (4) run **one** `//xb diagnose`, perform real L2/R2/bare-button inputs for 30 seconds, and confirm `Diagnostic saved` plus one log under `data/diagnostics/`. If save still fails, preserve console output and `data/diagnostics/` temporary result, without trying another simultaneous diagnostic client. Keep separate entire-folder backup of the personal installation.
- **Release gate:** Linux CI and packaging need to succeed at the latest documentation-complete head before distribution. In-game native acceptance is **pending**. The previously documented other diagnostic limitations (overlapping AHK client capture, incomplete native gameplay key-down logging, no Lua crash-time checkpoints, forced unload race) remain open; do not treat them as resolved. No stable/master promotion or public release claim.

---

# Current Development Status — October 29, 2026 — Beta 1 Diagnostic Test 1 Library-Loader Hotfix

- **Repository / branch:** `rerorriM-Mirrorer/xivcrossbar` / `release/beta1-ps5-directlink`. The previously published complete diagnostic bundle was built from source `1bf559fab4e9771b992b2095439ea58b45e511e0` (the preceding runtime source was `2e4a95af9cd3385d9c9bde30808a4c5c1cdc7502`). Personal development branch, stable/master and other public release branches remain untouched.
- **User-provided live startup failure (October 29):** Attempted loading the complete Beta 1 diagnostic ZIP produced a Windower Lua module-not-found search listing `libs/xml2.lua`, `libs/xml2.dll`, `plugins/libs/libs` and `addons/libs/libs` locations. The ZIP **does include** `xivcrossbar/libs/xml2.lua`; it was a **search-path issue**, not evidence that an XML DLL needs installing. Full exact console trace was not supplied, so this root-cause conclusion is strongly indicated by module search locations rather than independently reproduced in native Windower.
- **Code change:** Added a small initialization block in `xivcrossbar.lua` that normalizes `windower.addon_path` separators, appends `<addon folder>/?.lua` to the Lua `package.path` if absent, and leaves the existing shared Windower module paths first. This makes the existing `require('libs/xml2')` and other `require('libs/...')` calls resolve bundled addon-local modules without requiring copies in the shared `addons/libs/` directory. The addon content, controller transport, diagnostics, render tracing and saved settings are otherwise unchanged. The resulting runtime identifies as `0.4.0-beta1.20261029.ps5-directlink-diag1-libfix1`.
- **Regression addition:** New `tests/local_library_loader.lua` simulates Windower's shared library search without an addon-local search path, confirms that a bundled module cannot initially load, executes the actual startup bootstrap with Windows-style backslashes, then confirms it resolves the addon-local `libs/kebab_casify` and checks referenced `libs/*` files are present. The Linux regression runner performs temporary Windower-literal normalization and uses Lua 5.4; **this does not constitute native Windower 4/Lua 5.1 or FFXI acceptance**.
- **Previous diagnostic limitations unchanged:** One shared AHK capture can be replaced by an overlapping client, normal gameplay native key-down is underreported in the trace, Lua data is not crash-checkpointed, and forced unload may merge a stale AHK checkpoint. These remain explicitly documented in the October 25 preflight audit below; do not treat them as fixed.
- **Full install / rollback:** Stop the shared controller wrapper, unload XIVCrossbar on every client, move the current `addons/xivcrossbar/` folder out of the addons directory to preserve settings and personal art, and extract the **complete replacement ZIP** so `addons/xivcrossbar/xivcrossbar.lua` and `addons/xivcrossbar/libs/xml2.lua` both exist. Never copy beta-local `libs/` files into Windower's shared `addons/libs/`, overlay this version on the personal addon, or look for a standalone XML DLL. On failure, preserve the console trace; restore the entire backup folder to roll back.
- **Next validation:** Confirm `//lua l xivcrossbar` loads, `//xb status` reports `...-libfix1`, PS5 profile initialization works, and `//xb diagnose snapshot` can save its own per-character log. Native Windower/AutoHotkey and FFXI controller testing remains pending.

---

# Current Development Status — October 25, 2026 — Beta 1 Diagnostic Test 1 Preflight Code Audit (No Runtime Patch)

- **Repository/branch/source audited:** `rerorriM-Mirrorer/xivcrossbar`, `release/beta1-ps5-directlink`, `2e4a95af9cd3385d9c9bde30808a4c5c1cdc7502`. Audit of the complete packaged beta, not the personal development renderer. **No runtime changes in this audit**; do not describe the build as in-game tested or new ZIP as delivered.
- **Method:** Manual pre-release static code review of AHK physical poll and shared diagnostic request, DirectLink event/ack stream and Lua lease, input routing, unified-session lifecycle, public resource/geometry observation, and test assertions. Prior CI for source checkpoint: GitHub Actions run `40188209234`, all Linux Lua/static/package steps passed. **Native AHK/Windows/Windower and live FFXI acceptance remain pending**.
- **Confirmed diagnostic coverage gap (medium):** `xivcrossbar.lua` logs native key-down in login context, but not the normal gameplay `transport:gameplay_key` / `setkey ... down` path (approx. lines 1932–1939). A missed action in-game may therefore show a Lua receiver event but lack the expected native-request trace. Remedy: trace immediately before all native key send sites, checking for parity without injecting extra keys.
- **Confirmed shared-reader conflict (medium/high for multibox diagnosis):** `controller_diagnostics.ahk:DiagTick` accepts any new `on <id> <character>` request and closes/replaces an ongoing AHK capture. No ownership/active-session gate or per-client response exists; overlapping `//xb diagnose` commands on separate clients leave a partial AHK section in one log. Remedy: reject the second request with explicit busy status, or later design a multi-subscriber observation feed.
- **Confirmed capture-durability limitation (medium):** `diagnostic_session.lua` buffers Lua observations until stop/deadline. Only AHK stages periodic files. A process crash or freeze before stop can lose the Lua/render portion entirely; "partial on unload" only applies to graceful Lua unload. Remedy: checkpoint a bounded partial Lua capture periodically outside high-frequency input handlers, with careful timing and error reporting.
- **Confirmed stop/unload race (medium):** Normal `stop` provides 0.75s for AHK to process its off request; `force` on unload immediately merges and can read a previous periodic AHK checkpoint before off/final write, silently omitting the last events. Remedy: carry a completion/closed marker and report incomplete merge; avoid claiming full AHK capture without proof.
- **Minor normal-path observation overhead:** `DiagTick` checks for a request roughly every 100 ms even when disabled; `ui/resources.lua` allocates weak render-trace metadata on UI object creation with tracing disabled. Not proven harmful; can optimize if profiling establishes impact.
- **Live-only/open risks:** AHK v1 native parsing and FILETIME/encoding, FFXI window title matching a character lease, rapid input overlap, true frame timing and old caption/fade flickers cannot be accepted by the Linux simulated suites. The beta intentionally did not import personal text settling.
- **Recommendation:** A focused diagnostic correctness patch before relying on the single-file capture for difficult controller bugs; then CI, native Windows syntax check if available, and controlled game acceptance. Keep existing diagnostic ZIP as unverified test candidate until patched or independently observed.

---

# Current Development Status — October 25, 2026 — Beta 1 Diagnostic Test 1

- **Repository/branch:** `rerorriM-Mirrorer/xivcrossbar` / `release/beta1-ps5-directlink`. Original public base `a73a6c6754a1edccd6515a7b641733e044a1f7f9`. Personal `development/directlink` and stable/master branches remain unchanged.
- **Runtime:** `0.4.0-beta1.20261025.ps5-directlink-diag1`; retains all Beta 1 PS5-only DirectLink/other-profile Apps behavior. No companion banks or personal shortcut controls added.
- **Requested behavior:** On-demand `//xb diagnose` creates a fresh, unique per-character 30-second diagnostic file under `xivcrossbar/data/diagnostics/`. Single file merges AHK physical/poll/Apps/DirectLink snapshots, Lua message sequences/acceptance, native key requests, snapshots, routed input contexts, and opt-in public render observation. `mark`, `stop`, `status` and `snapshot` commands supported. No append to earlier captures. AHK writes a bounded **temporary** `data/diagnostics-staging/<session>.ahk`, overwritten periodically (about once/second); Lua merges the last snapshot and removes it upon successful save. The single shared AHK reader supports one AHK diagnostic session at a time.
- **Rendering port:** Copied personal `ui/render_trace.lua` observation engine with a read-only event list API; instrumented public `ui/resources.lua` and `ui_geometry.lua` to observe their existing native calls, text extents, centering, object creation/disposal and contextual frame gaps. Did **not** port personal `ui/geometry.lua`, text settling, replacement UI algorithms or banks. Trace does not observe GPU pixels. Suppressed extra native getter calls: no rendering methods or layout decisions changed on purpose.
- **Performance/safety:** Trace is disabled until requested. Lua writes the final capture once after 30 seconds (or a stop), with a 0.75-second grace for the AHK feed. AHK checkpoints bounded in-memory events and uses a maximum ~512 KiB feed; Lua and render buffers are bounded; overflow counts are reported. Full state is sampled at start/end, not every frame. Logging can itself affect timing, especially during rich UI changes. On unload, partial capture is attempted. Keyboard text/chat contents are not recorded by this controller route; logical controller events and filenames include character identity.
- **Available verification:** Source/regression CI on the working branch executes `python3 tests/run_lua.py tests/*.lua` on Lua 5.4 with documented temporary Windower syntax normalization, parses every Lua source, checks the upstream Python launcher, and builds an exact-source complete installation. New `tests/diagnostic_beta1.lua` covers unique files per request, AHK feed merge, Lua/render ordering, manual marks, stop handoff, unload, caps, render proxy call parity and existing extent result. First CI run after adding the test failed because the isolated fixture omitted LuaSocket; the fixture was corrected to use a deterministic test clock. **Native Windows AutoHotkey, Windower, FFXI, and controller hardware remain untested**; no timing-speed or visual correction is claimed.
- **Previous user-confirmed behavior:** Public RC3 original Apps input and setup worked; personal Survival Guide controller route was successful in a separate development branch. Neither verifies this beta.
- **Release state:** Diagnostic test candidate only. No tagged community release/PR or promotion to master. Next action is one controlled in-game PS5 acceptance recording, then review any trace anomalies.

## Single-file Beta 1 diagnostic acceptance checklist

1. **Back up the installed variant's complete folder**, including configuration/data. Stop the shared reader with `//xb controller stop`, unload XIVCrossbar on all clients, and install this ZIP as a complete `Windower/addons/xivcrossbar/` folder. Do not overlay private/personal settings, do not nest folders, and do not run an old controller AHK in parallel. To roll back, stop/unload and restore that complete backup.
2. Load `//lua l xivcrossbar`; select `//xb controller profile ps5`. Confirm `//xb status` version ends in `ps5-directlink-diag1` and `//xb controller status` reports the selected profile and running AHK route.
3. On **Franklet** (1280×720), run `//xb diagnose`. Use L2/R2 crossbars, bare face/D-pad, Options/Share, in-world and native menus, and an NPC dialogue. Mark any odd behavior with `//xb diagnose mark`. Stop early with `//xb diagnose stop` or let it finish automatically.
4. **Wait until chat says "Diagnostic saved"**, then send the **single newly created** file from `addons/xivcrossbar/data/diagnostics/`. If it instead reports failure, preserve both the error and `data/diagnostics-staging/` temporary AHK feed. AHK events may be absent if the controller wrapper was stopped, focus changed before request, or the temporary file could not be read; the report should identify that rather than silently imply completeness.
5. Repeat on **Killala or Lionstag** (960×540). Test rapid taps, trigger overlaps, a change of FFXI window focus and one menu transition. Verify a second capture gets a different filename and does not append to or overwrite the first.
6. Compare FPS responsiveness and UI visuals with tracing **off** and **on**. Inspect render 'native.text', 'extents', 'center-*', 'surface-retire' and frame-gap lines. If text suddenly appears misaligned or the log reports overwritten events, record it. No extra render instrumentation should be imported from personal until such regressions are understood.
7. Other F710/XInput/FightPadPro input profiles preserve their Apps route but are not necessarily hardware-verified. Continue previous Beta 1 and Maintenance 2 acceptance requirements below.

## Development notes

The Beta 1 trace merges events by Unix-epoch observation timestamps. AHK uses Windows system FILETIME, and Lua uses LuaSocket wall time; this can correlate broad timing but cannot prove the moment FFXI visibly acted. AHK logs *sampled* 10ms controller state, so a tap entirely between polls cannot be reconstructed. Low-volume preview is intentionally used to avoid perturbing the very scheduler being investigated. The capture records only the addon-controlled drawing calls and does not show GPU pixels or other addons' rendering.

---

# Current Development Status — October 25, 2026 (America/Chicago) — Beta 1 PS5 DirectLink Test 1

- **Repository / branch:** `rerorriM-Mirrorer/xivcrossbar` / `release/beta1-ps5-directlink`; founded from the published public RC3 source `a73a6c6754a1edccd6515a7b641733e044a1f7f9`. Upstream reference: qEagleStrikerp/xivcrossbar `15d8381dfad0f9efdb84fe2d24655afc150faec4`.
- **Runtime:** `0.4.0-beta1.20261025.ps5-directlink-test1`; AutoHotkey v1 shared reader with ordinary PS5-only acknowledged button stream. Other PS5 setup/login and F710/FightPadPro/XInput/XInput-alt inputs retain Apps+F1-F12; no companion banks or personal shortcuts.
- **Implementation:** Lua message receiver `controller_messages.lua`, per-character focused lease `controller_lease.lua`, AHK publisher `controller_messages.ahk`, PS5 route in `ffxi_directinput.ahk`, and source-preserving integration into the existing public `xivcrossbar.lua` keyboard router. Message-token/sequence/ack snapshots, stale heartbeat recovery, cancellation, immediate neutral rearm, no queued action replay after cancel. AHK polling uses `SetBatchLines,-1`; PS5 diagonal POV continuity; physical keyboard F-key ownership is kept separate from message holds. Non-PS5 profiles use the old input path.
- **Compatibility:** Original upstream `FFXI_Input.py` and `FFXI_Input.sh` copied into root, unmodified. Historical controller AHK variants and diagnostic files copied under `compat/upstream/` unchanged, for reference only; *not* additional launched profiles. Linux scripts and optional historic AHK utilities are **not** live-tested.
- **Source baseline for acceptance:** Code checkpoint `de106a12264c80ccb061bee2ba5df99114e689ad` (message-input handling and tests). Subsequent status/documentation-only changes do not modify runtime unless explicitly noted. The final published head is in the handoff and GitHub history.
- **Available verification:** GitHub Actions on the Beta 1 branch executes `python3 tests/run_lua.py tests/*.lua` on Lua 5.4 shared library with temporary Windower-literal normalization, 12 top-level suites including the new acknowledged DirectLink/keyboard-owner suite, 64 Lua source parses, upstream Steam Deck Python syntax, and exact-source complete-folder packaging. At least the preceding runtime checkpoint `bcece71b8e16bdb9ad2553c2563cc373665713bd` passed CI; the final acceptance artifact must come from a **successful run at the latest head**. This is **static/simulated** verification only, NOT native AutoHotkey, Windower, FFXI, or controller hardware testing.
- **Last user-confirmed live behavior:** Original public RC3 controller setup, basic Apps routing, startup fade, restart and Icons1 succeeded. Personal development branch confirmed Survival Guide controller operation separately. Neither proves Beta 1 DirectLink in this public branch.
- **Current release gate:** Unreleased test candidate; no community release, upstream PR, stable promotion or in-game acceptance. Personal development and public/master branches unchanged. The user's **one focused live acceptance pass** is next.

## Beta 1 complete installation and rollback

1. Download the artifact from the latest successful GitHub Actions **Beta 1 verification and installable ZIP** workflow run at the published release branch. Its ZIP must contain **one `xivcrossbar/` addon folder** with `README.md`, `WORKFLOW.md`, `TESTING.md`, code, compatible auxiliary references, images and themes; it is NOT an incremental patch.
2. **Before installing:** stop the existing shared wrapper with `//xb controller stop` and unload XIVCrossbar on **every client**. Back up/move the entire existing addon folder (including `data/`, `config.ini`, custom icons/artwork) somewhere outside Windower/addons. Do not overlay Beta 1 atop the personal version or merge their catalogs/data. Only one variant can run from that addon path at a time.
3. Extract the artifact's `xivcrossbar/` directly into Windower/addons; it must NOT become `xivcrossbar/xivcrossbar/`. For an isolated first pass use a fresh Beta 1 setup. Never copy personal settings into the public fork. Load `//lua l xivcrossbar` on each participating client and choose `//xb controller profile ps5` (device 1 unless intentionally changed).
4. Confirm `//xb status` says `beta1.20261025.ps5-directlink-test1`. Open `//xb controller status` after login: PS5 route should report DirectLink messages; before login/setup it may show Apps. Ensure another controller script is not running.
5. **Single live pass:** Cross/Square/Circle/Triangle and D-pad in bare gameplay and native menus; L2, R2, L2→R2, R2→L2 and optional doubletap bars; fast trigger+slot combinations, roll over a diagonal; Options chooser and Share, custom-action editor and Back/Escape; in-world NPC dialogue/status 4; normal physical F-keys and Ctrl+F-keys; two game clients switching focus/one-client reload/unload; save/reload/scale/compact at 1280×720 and 960×540. Record missing/doubled input, menu leakage, stuck keys, and character or screen-resolution effects. Validate fresh login wizard if possible; no-subjob storage/missions remain part of public Maintenance 2 acceptance.
6. If anything fails, note the exact sequence and capture `//xb controller status`, wrapper `data/controller-status.ini`, and the relevant Windower console/chat output. No need to collect logs for each success. Some non-PS5 profiles require unavailable physical hardware and must remain clearly marked **untested**.
7. **Rollback:** Stop Beta 1 reader, unload every client, remove Beta 1 folder, restore the original complete addon folder and its own state, reload. Never mix the public and personal `data` stores.

## Source regression and acceptance rationale

- New `tests/directlink_beta1.lua` exercises actual Lua message parser: ordered trigger-before-face, up events, seq/ack dedupe, stale snapshots, invalid sequence gap, same-snapshot cancellation, heartbeat watchdog and new token, plus source guards for PS5-only messages, absent personal banks, preserved other profiles and Apps key transport.
- Updated existing `tests/login_input.lua` exercises the named real root keyboard handler, pre-login keys and physical F-key passthrough even when a matching DirectLink logical button is held.
- Updated mock `tests/profile_lifecycle.lua` includes the new lease close lifecycle. Existing regression histories below remain applicable but **are not additional in-game testing for this build**.
- Native Windows AutoHotkey v1 syntax/joystick polling, transient title-matched leases, FFXI dialogue inputs, rapid taps and actual multi-client control are still pending. Static tests alone cannot establish latency improvements or reliability under Windower/FFXI.

---

# Current Development Status — October 18, 2026 (America/Chicago)

- **Repository / branch:** `rerorriM-Mirrorer/xivcrossbar` / `public/rc3-maintenance`; working source began at published `dc5e02efa05fdbb3ac75a66887744fc24fb61535`.
- **Runtime:** `0.4.0-a.20261016.public-rc3-maintenance2`; public Apps-key AHK remains unchanged. No DirectLink transport or personal bindings are added in this pass.
- **Current change:** Repaired legacy `sw`/`switch` handling and multiword set keys; made `copy`/`move`, `alias` and `icon` respect `Hotbar.Number`; removed unreachable `set` code; consolidated the mis-signed action callback so own job abilities refresh spell availability. Added regression coverage, the final-status workflow rule and the missing `AGENTS.md` entry point. Aligned package-document placement with the canonical shared convention (inside the installable addon folder).
- **Last user-confirmed live behavior:** Original RC3 setup and controller routing, startup fade, restart and Icons1 were reported working. Maintenance 1 public ports and Maintenance 2 remain pending dedicated live regression.
- **Verification:** All 11 top-level Lua regression files passed with `python3 tests/run_lua.py tests/*.lua`. All 61 Lua sources parsed with the documented Lua 5.4 normalization fallback. This is source/simulated verification, not native Lua 5.1/Windower/FFXI acceptance.
- **Still to test in FFXI:** `sw`/`switch` with empty/multiword names; CLI edits with three and six bars; job-ability spell refresh; all public Maintenance 2 pagination, identity, destinations and save-return cases; multi-client wrapper, menu and resolution regressions.
- **Next development:** Live-test the complete public Maintenance 2 candidate, then consider selective generic DirectLink architecture ports before promotion to `master` or a public tagged release.
- **Publication correction:** The October 16 initial push was blocked, but a later authorized push succeeded. The public branch had reached `dc5e02e` before this task. Earlier dated notes below preserve the original failed-attempt history; they are not the current remote state.
- **Delivery:** Source-and-test checkpoint only; no new ZIP, upstream pull request, community announcement or live FFXI run. Final pushed commit is reported in the GitHub handoff.

---

# Public RC3 Maintenance 2 — complete testing installation — October 16, 2026

Runtime: `0.4.0-a.20261016.public-rc3-maintenance2`.
Branch: `public/rc3-maintenance`. Package header records the final local commit.
GitHub source baseline: `2c41936a5b095b73f3615b3ba241e413ae846126`.
~~**NOT PUBLISHED:** the environment approval check denied the first push. No
alternative push mechanism was attempted. Ask Max to confirm publishing these
commits to the existing public branch. Do not describe this delivery as pushed.~~
**October 18 correction:** This was true for the initial October 16 attempt;
the branch was subsequently published through the authorized GitHub workflow,
with `dc5e02e` as its verified pre-maintenance source head.

## Request, workflow and source baseline

Max requested review of NPCmirror's current WORKFLOW.md first, then all four
previously identified public candidates. Read shared WORKFLOW from
`rerorriM-Mirrorer/ffxi-NPCmirror` (blob
`424d643fd63b944bd8534f455342b5328f1ca48c`); it matches the public copy.
Read the public source, existing passing tests, handoffs and the upstream root
module. Inspect personal source at `9375a66d75778744a865077e2f676458688fc65a`
and the individual port commits; do not overlay whole personal runtime files.
No personal branch, default settings, controller-profile or AHK changes.

| Improvement | Local feature commit | Personal source / behavior |
| --- | --- | --- |
| Shorter target-list pagination | `db3b662` | `2f462fa`; retain Back spell/page |
| Stable identity/storage gate and login keys | `5b31fc4` | `7c97012` and required guards/login dependencies |
| Default-set destinations | `1afc4ef` | `a390b06`; readable labels, stable execution keys |
| Save Only / Save Changes return | `292682a` | New implementation; saved entry selected in edit picker |

## Install safely

This is a **complete install**, not an update-only patch. Unload XIVCrossbar on
all clients first. Back up the installed public folder, including data/config.ini
and custom images. Install the ZIP's `xivcrossbar/` into Windower/addons. For an
upgrade, restore only the PUBLIC backup's data/config.ini and user-added images;
for fresh acceptance, leave user files absent and complete setup. Never run
personal and public variants together on one PC or round-trip personal catalogs
through this public implementation. Switching variants requires stopping the
current wrapper before unloading; this batch's public AHK itself is unchanged.
No settings.xml, config.ini, catalogs, binds, extracted caches or user data ship.
Rollback: unload all clients and restore the backed-up PUBLIC folder/data.

## Verification performed here — simulations only

- All 60 Lua sources parse using the existing Lua 5.4 runner and temporary
  normalization of inherited Windower string-literal method syntax. Lua 5.1,
  LuaJIT, luacheck, Windows, native Windower and AHK runtimes are unavailable;
  this is **not** Lua 5.1/API-aware static validation or live FFXI acceptance.
- Existing checks: 108 layout scenarios across six resolutions/three scales;
  compact command validation/state preservation; 200 menu cycles, 150 typed
  updates, 100 footer rebuilds; 30 crossbar/20 chooser rebuilds; cursor unload
  and deferred/idempotent object destruction.
- Pagination: 12 actual binder spell-page-two/three -> targets -> binding ->
  Back -> save scenarios across six resolutions. Target choices show at page
  one and Back restores Shellra II and the original page.
- Identity: actual initializer, observer and load/login/logout/keyboard handlers
  under mocks. Lobby/unknown server/missing or mismatched entity rejected;
  0.75-second tuple stability, transient retry, late correction and one reload,
  changed character IDs, actual Asura support, no-subjob identity, unconfirmed
  writes blocked, wrapper startup independent of identity, logout invalidation,
  login key-down/up ownership, ignored triggers, physical F-key passthrough.
- Destinations: real binder, slot save, root switch and player execution under
  mocks; all three Default sets, renamed display label, reciprocal same-slot
  switches, quick-switch return and replacement of stale action metadata.
- Save return: six resolutions, real binder and catalog callbacks with mocked
  writes; menu/command create, edit/rename, selection across three pages,
  Back-to-main selection, false/throwing writes with rollback, invalid/duplicate
  names, unsaved cancellation, Save & Bind/Back and 180 bounded repeat cycles.
- Scope checks compare public defaults, AHK, controller profiles and assets
  byte-for-byte with the remote baseline. Package checks enforce required new
  modules, no distributed user state, archive integrity and source-byte equality.

Repeat from repository root:

`python3 tests/run_lua.py tests/compact.lua tests/compact_command.lua tests/menu_resources.lua tests/ui_lifecycle.lua tests/character_identity.lua tests/profile_gate.lua tests/profile_lifecycle.lua tests/login_input.lua tests/crossbar_destinations.lua tests/custom_action_save_return.lua`

## First live tests — not yet performed

1. Verify `//xb status` ends `public-rc3-maintenance2` and reports the correct
   character/server; resource helper stays `public-cleanup1` (unchanged helper).
2. On Franklet 1280x720 and Lionstag 960x540, select a later-page spell, check
   targets immediately, go Back twice, bind and execute. Spot-check 3840x2160.
3. Load before login; test controller arrows/confirm/cancel, then login with a
   no-subjob character. Confirm no false lobby-server folders are created.
   Logout/relogin as another character, reload, zone and change jobs. A server
   remaining wrong beyond the settling interval cannot be predicted; a later
   observed correction reloads normally and does not delete existing folders.
4. Bind reciprocal Default/custom switches (same slot), then Job Default and
   All Jobs Default. Reload and repeat. Check Quick XB Switch returns after one
   action. Rebind an old label-based switch if necessary; no XML migration.
5. Create through menu and `//xb ca`, Save Only, edit the selected entry, rename
   across pages and Save Changes; edit another entry. Check Back, Save & Bind,
   draft cancellation, reload persistence and Options overlay restoration.
6. Repeat prior compact/fades/resource checks, Credits, Escape and fresh setup.
   Restart/unload one of two clients and confirm the other remains usable.

Public candidate remains unreleased. No forum post, PR or announcement. These
changes do not prove resolution of native d3d8.dll crashes, shared text loss or
personal input stickiness. Standard public help/unload modernization and all
personal-only controls/catalog ownership features remain outside this batch.

---

# Maintenance 2 per-feature development notes (retained)

Save-return implementation: new behavior, not an already-completed personal
port. After successful Save Only / Save Changes, return to the edit picker and
select the saved name at its sorted page/row/column. Preserve main-menu Back
selection; clear the completed draft. Failed/invalid saves remain in review;
Save & Bind keeps the existing binding path. Live: create from menu and command,
edit/rename several entries including a later-page entry, save then edit another,
Back to main menu, Save & Bind then Back, cancel an unsaved draft, and verify
persistence after reload. Public linked-copy propagation is still out of scope.

Default destinations port: personal a390b06 adapted without catalog ownership
changes. Tests exercise actual binder, slot save, root switch and action execution
for all fallback destinations, a renamed display label, reciprocal same-slot
switches and Quick XB Switch return after the next action. New action selection
clears stale switch/custom-action metadata. Live: bind reciprocal Default/custom
set switches, reload, then repeat with Job Default and All Jobs Default; test
Quick XB Switch's one-action return. Saved older bindings are not migrated.

Identity port: personal 7c97012 plus its character-identity/storage guards and
login-navigation dependency. Keep the public wrapper, profiles and defaults.
Simulations cover lobby/unknown-server/mismatched-entity rejection, stable
identity, late correction, character IDs, genuine Asura and blocked writes.
Live: load before login; use controller arrows/confirm/cancel, log in and verify
only the correct server/character hotbars load. Logout and select another
character; do not create data under a lobby/default server. Test a no-subjob
character, a reload, job changes and another client remaining usable.

Pagination port: personal published 2f462fa, adapted to public. Actual binder
methods pass 12 page-two/page-three -> targets -> binding -> Back -> save cases
across six resolutions. Lua fixture simulation only; live FFXI acceptance pending.
Retest Shellra II from a later spell page at 960x540 and 1280x720; targets should
appear immediately, Back should restore the spell/page, and binding should work.

---

# Complete installation + conversation handoff — October 15, 2026

Variant: **PUBLIC RC3 maintenance**. This delivery packages all currently implemented
runtime code and required images/themes. Pending ideas are documented, not
implemented. The runtime version remains unchanged.

Start with `xivcrossbar/docs/HANDOFF-PUBLIC-RC3.md` and the shared
`xivcrossbar/docs/BRANCH-MAP.md`. The exported package header records exact local
and published source checkpoints. The standalone handoff copies carry that
header too. Historical update-only instructions below apply to those earlier
ZIPs, not to this complete ZIP.

## Install and identify

1. Stop the currently running shared wrapper with //xb controller stop and
   unload XIVCrossbar on every client (//lua u xivcrossbar works in both builds).
2. Back up/move the existing addon folder. Copy this complete xivcrossbar folder
   into Windower/addons. Do not overlay or run public and personal together.
3. For clean setup leave data/config.ini absent; the wizard creates them. For
   an upgrade restore the matching variant's data/, config.ini and custom icons.
   Never use the installer as a source of empty user files.
4. Load //lua l xivcrossbar. Verify //xb status and //xb controller status,
   complete setup if needed, then use the focused checklist in the handoff.
5. If swapping variants later, repeat stop/unload and use their separate data
   backups. TrustMovement/Trust/AddonManager and native Windower libraries are
   separate dependencies and are not replaced by these installations.

## Evidence and next development

The three approved ports are implemented/pushed and simulation-tested, not yet
live-confirmed in public. Continue compact/fade/resource checks, Credits at both
small resolutions, Escape navigation, two-client restart independence and clean
setup. Stable server gate, target-list pagination, Default destinations and
standard unload/help remain selective-port candidates, not included features.

Additional conversation retrieval did not recover the other threads. This
handoff uses visible discussion, current source, recovered archives and cumulative
records; gaps and historical-only claims are identified. Documentation checks
verify current roles/defaults/commands and preserved branch separation. No new
Windows/FFXI acceptance is implied.

---

# Public RC3 Maintenance 1 — October 15, 2026

Runtime: `0.4.0-a.20261015.public-rc3-cleanup1`. Cumulative public-only ports:
immediate compact switching, corrected text stroke alpha, and resource cleanup.
New branch public/rc3-maintenance recovers the delivered RC3 + Icons/Credits/Escape
runtime. Personal controls, movement integration, personal defaults, catalog
propagation, icon relocation and palette changes are excluded. Master and the
personal development branch remain unchanged by these ports.

Install over the public RC3 runtime only: unload XIVCrossbar on all participating
clients, copy the installable xivcrossbar contents, then load again. No AHK
changes in this patch; the running public wrapper can stay. Do not overlay this
on a personal installation: it is a separate public candidate. No data, XML,
INI, settings, catalogs, bindings or images are shipped. Code rollback targets
the recovered RC3 public baseline, with user data preserved.

## Verification and live checklist

Available checks pass: 108 layouts (six resolutions x three scales x two/six-bar
variants), compact command validation/state preservation, 200 review/edit/bind/back
cycles, 150 text updates, 100 footer rebuilds using an upstream Windower List,
30 crossbar reconstructions, 20 chooser reconstructions, cursor unload after
root disposal, and idempotent deferred destruction. Lua 5.4 parsing uses temporary
normalization of inherited Windower string methods; this is not Lua 5.1, native
Windower drawing or Windows input execution. These checks do not prove a native
crash fix. Prior original public test groups are not claimed rerun here: their
sources were not in the recovered archive.

1. `//xb status`: reports public-rc3-cleanup1. `//xb compact`, explicit on/off,
   scale .6/1/1.5; toggle while choosing sets and editing a custom action. Draft,
   current set, drag position and bindings survive; both layouts fit.
2. Compare text fades in both layouts. No flickering outline; ordinary input,
   startup visibility and captions behave as before.
3. `//xb resources`: note counts on a closed menu, repeat edit/save/bind/back,
   return to the same screen and compare. Counts should settle, not grow every
   cycle. Unload/reload with a menu open; no disposed-object errors.
4. Native gameplay, addon menu, all six crossbar states, physical F-keys and
   Ctrl+F-key bindings remain correct. No personal profile is offered.
5. Remaining prior release checks: Credits at 960x540 and 1280x720; Escape from
   drafts/binding/chooser without native leakage; restart one client while another
   remains usable; final clean installation and setup guide review.

## New user feedback and next candidates

Default reciprocal switches on the personal build are live-confirmed. TrustMovement
is managed by AddonManager; no autoload integration is wanted here. Personal input
stickiness remains under investigation. Deferred public candidates for review:
stable world/server gating, shorter target-list pagination, Default destinations,
and the existing catalog-save navigation request. Future personal design: two L1
modes/banks, per-bank visibility, icon-picker organization and muted lockout colors.
Do not silently include those in this three-feature maintenance patch.

---

# Public RC3 Stroke 1 — October 15, 2026

Port corrected stroke_alpha calls in crossbar text, selector, binder, controller setup and chooser. The drawing mock rejects transparency arguments outside Windower's 0..1 range. The prior personal build was user-confirmed to fade text without flicker after this correction. Recheck public fades in both compact layouts; no palette or timing changes.

# Public RC3 Compact 1 — October 15, 2026

Immediate `//xb compact [on|off]` port only. Existing public settings and controller profiles are preserved; no personal controls or companion are included. Toggle during a draft, chooser use, trigger holds and at .6/1/1.5 scale; check all six bars and drag persistence. Simulated layout/command checks are run before delivery; Windows rendering and input require live testing.

# Public RC3 maintenance — recovered release checkpoint

Recovered RC3 + Icons/Credits/Escape from the delivered public runtime archive. The former local public snapshot ref is not present on GitHub; this branch explicitly recovers that archive and does not alter master or the personal branch.

Remaining prior public acceptance: Credits on both small layouts, Escape across menu types, explicit two-client restart independence, and final package/setup documentation review. Icon fit, ordinary controls, fresh setup, startup fade and restart itself were reported passing.

## RC3 Escape 1 — cumulative menu-exit patch (October 13, 2026)

User requests a small Escape patch. Runtime: 0.4.0-a.20261013.public-rc3-escape1.
Commit 19358ec adds a shared full-exit helper, reused by the normal Share close
path. Physical Escape exits binder menus/drafts/text fields, chooser overlays
and set-name entry, plus setup if open. It cancels the chooser's preview through
the existing cancellation path, closes menus, discards unsaved drafts, restores
hints, and releases the text input block. It does not simulate native Escape.
The keyboard handler owns Escape repeats and release after close; normal Escape
outside addon menus passes through. Focus reset clears any abandoned ownership.
Circle/Enter handling is unchanged, and wizard cancellation does not mark setup
complete or change readiness. Unsaved field changes are intentionally discarded.

All 49 Lua regression groups pass, including new full-exit routing tests for
main/review/binding/Credits/inline/chooser/chooser-text/setup, pre-initialization
setup cancellation, held repeat/release, and restored native/unrelated input.
Three cumulative runtime Lua files parse after temporary standard-Lua string
normalization. README and release README document the Escape behavior.

Delivery: cumulative three-Lua-file update plus README over complete RC3 with
or without Icons 1/Credits 1. No bindings/configuration/images/wrapper replaced.
Exact complete-RC3 rollback copies included outside the runtime folder.
Live checks: Escape from main menu, binding capture, inline edit and chooser over
a draft; every addon layer closes and one press does not cancel the native menu
beneath. Release it, then verify the next native Escape works. Circle still backs
one step. Credits 1 and explicit two-client restart confirmation remain pending;
icon alignment, startup and fresh setup/controls are user-confirmed passes.

---

## Icon live pass and branch/navigation discussion — October 13, 2026

User confirms patched icons "now fit the button slots perfectly." Icons 1's
native rendering is a live pass. Credits 1 visual results remain pending.

User proposes keeping a finalized release branch while developing personal
features separately, then porting generally useful fixes back. Recommended
starting point is the tested public release; the older personal branch remains
a reference for deliberately selected features. No branches created or changed
by this discussion record. Do not mark a new release trusted until its remaining
live checks pass.

Requested navigation consistency: physical Escape should exit all XIVCrossbar
menus like Share/Create, including text entry and chooser overlays. Current
code handles Escape as text cancel/back or chooser close, with no general menu
exit handler. Proposed release fix should share complete-exit behavior, consume
both key edges, retain Circle's one-step Back and leave native Escape alone when
no addon menu is open. No runtime Escape patch applied during this discussion.

---

## RC3 Credits 1 — cumulative Credits/icon update (October 13, 2026)

User authorizes repairing Credits; leaves stronger menu-gradient tuning for later
personal testing. Runtime: 0.4.0-a.20261013.public-rc3-credits1. Commit e7bbd33
corrects all avatar paths to images/credit_avatars/, removes manual newline
spacers from the responsive grid, and starts Credits on page 1 while preserving
the saved main-menu selection for Go Back. All original people and roles remain.
No shared selector or menu-gradient behavior changed.

The new Credits regression fails before the fix on inherited pagination. After
the fix it verifies all avatar files, entry count, saved main-menu return state,
and reachable in-grid entries at 960x540, 1280x720, 1600x900, 1920x1080,
2560x1440 and 3840x2160. All 48 Lua regression groups pass; three delivered
runtime files pass syntax checking after temporary Windower string normalization.

Delivery: three-file cumulative overlay over complete RC3, including Icons 1.
No base images/configuration/bindings included. Exact original RC3 rollback
files are included outside the runtime folder. //lua r xivcrossbar applies it.
Live checks: Credits displays icons/labels on Franklet and Lionstag, all entries
fit, Circle returns to the prior main-menu selection, Share exits, and native
spell/pet icons align after the included icon patch. Live visuals remain pending.

---

## RC3 live results and Credits report — October 13, 2026

User reports fresh setup went well, controller buttons work without bleed-through,
startup fade looks good, and //xb restart "works great." Restart itself is live
confirmed; the report does not separately confirm another client stayed usable
during that command, so retain that specific cross-client check as pending.
User does not notice a darker menu gradient, although the custom action screen
may be darker. Do not increase the gradient based on this observation alone.
RC3 Icons 1 visual result remains pending while the user checks it.

Credits: missing icons and misaligned entries on Franklet; nothing appears when
selected on Lionstag. Code inspection finds avatar paths omit the required
images/ prefix, Credits inherits the main-menu page number instead of starting
at page 1, and manual newline spacer entries assume the old grid arrangement.
These explain concrete missing-resource/pagination/layout risks; no Credits
runtime patch has been applied yet. Preserve credited people/roles when fixing.

---

## RC3 Icons 1 — native icon alignment patch (October 13, 2026)

User requests an icon-overflow patch while testing RC3. Runtime build:
0.4.0-a.20261013.public-rc3-icons1. Commit b6fb93d removes only the obsolete
4px right/down inset in load_action; geometry already sizes icons to 40px slots.
The artwork, slot dimensions, scaling, and action execution remain unchanged.

Extended item_icon_routes.lua exercises actual action loading through the real
geometry proxy. Dia fails the slot-origin assertion before the fix. Afterward,
spell/pet/job/weapon/item/custom/linked/mount paths align at scales 1, .6 and 1.5;
presentation and movement-cohesion checks pass. All 47 Lua regression groups
pass, and both changed runtime files parse after temporary standard-Lua
normalization of inherited Windower string methods. Native rendering remains
a live check.

Apply the two runtime files over the complete RC3 installation, then
//lua r xivcrossbar. No images/data/config.ini included or replaced. Rollback
files reproduce the exact complete-RC3 versions from commit 7568505.
Check Dia, Sic, Leave, Heel and Fight: icons should fill their slot without
spilling right/down. Compare an unaffected custom/item icon, then try scale .6
and restore the preferred scale. Continue the pending RC3 startup/restart checks.

---

## Live native XInput compatibility result — October 13, 2026

Lionstag: user enabled FFXI Gamepad Config's native XInput checkbox while retaining
the addon's PS5 DirectInput wrapper profile. After the proposed movement/camera,
native-menu, addon-menu and trigger-binding checks, the user reports: "Nice it
seems to work exactly the same." Overall compatibility pass on this setup;
individual checks were not separately reported. This does not establish that the
AHK XInput reader detects the controller or validate other controller hardware.
Runtime version was not reconfirmed; the latest explicitly reported installation
was RC2, so this is not recorded as an RC3 fresh-install pass.

RC3 fresh setup, revised startup/gradient and //xb restart across two clients
remain pending. Earlier lua r/unload multi-client checks passed; the remaining
restart check specifically concerns the restored //xb restart command.

Additional RC2 report: Dia, Sic, Leave, Heel and Fight icons spill outside slots
at //xb scale 1; reloading does not change their appearance. Screenshots supplied:
image(20261013-080954).png and image(20261013-081021).png. They were not inspected
because workspace access failed at that time. Shared icon sizing/cropping is a
hypothesis, not an established cause. Check on RC3 before marking it resolved.

Follow-up after workspace access returned: both screenshots inspected. The named
spell/pet icons visibly extend to the right/bottom of their slot frames. Current
ui.lua still adds +4/+4 to non-overridden icons (commented as centering 32px
icons), while ui_geometry.lua gives images an explicit 40x40 size and disables
native texture fitting. This is a concrete positioning/sizing mismatch present
in RC3 too. No runtime change made during this test-result documentation update.

---

## Public RC3 complete fresh-install candidate — October 12–13, 2026

User requests a complete fresh installation as server maintenance approaches.
Runtime: 0.4.0-a.20261013.public-rc3. Branch public/controller-profiles; local commits
only, no remote push. Relevant commits: 956dd5b relocated owned assets; a70f824 new
0.1/0.5/2 fade defaults; 408f36f startup independent of regular fades; 53ef7d5 subtle
black menu gradient; b7e79b4 adopts user's final README proposal with technical
corrections; 609d13d identifies the runtime candidate.

Startup now always uses LoadFadeIn when visibility permits, even with regular fades
off. Both always/oninput modes respect trigger interruption: normal FadeIn when on,
instant full opacity when off. After the intro, normal visibility resumes. Text
stays at fade endpoints, including startup with regular fades disabled; instant
interruption restores static hints as well as rows refreshed by recast checks.
Regular-fade toggles during startup preserve that phase rather than restarting it.

Menu normal alpha is 150 at the top, approximately 190 at the bottom; custom review
215 to approximately 235, black RGB throughout. Thirty-two additional strips use
only existing Windower primitive APIs, are created before foreground UI, share
bounds/visibility and are reused on repeated setup. No new image-generated artwork.
Other backgrounds/text entry fields are unchanged.

47 Lua regression groups pass; reader mappings match pinned upstream. Complete
package audit checks local module imports, each raster, icon-list references,
source-identical runtime files, relocated assets and provenance. Syntax checking
uses temporary standard-Lua normalization of inherited Windower string methods.
Windows live rendering of the new gradient/startup semantics and graceful restart
remain to test; previous positive results remain recorded below.

Installation: stop old script, unload on all clients, back up and move old folder
out of addons, extract the complete xivcrossbar folder. For true first-run testing,
do not copy config.ini/data initially; restore them later if desired while unloaded.
No game-client relog required for addon changes. Includes images. No player data,
config.ini, controller extras, personal L1 addon, AGATHOS/WORKFLOW/DESIGN, tests,
old install notes or unsupported alternative scripts are distributed. README and
asset provenance are user-required documentation. LIVE-CHECKS.txt stays outside
addon runtime. Rollback is the backed-up complete folder, not mixed Lua files.

Live checks after maintenance:
1. Fresh welcome -> PS5 input profile -> artwork -> assignments -> completion,
   menu navigation and one real binding; check status reports public-rc3.
2. Startup in always/oninput modes with regular fades on/off; no input reveal,
   trigger interruption and subsequent show/hide behavior; defaults 0.1/0.5/2.
3. Main menu and custom review gradients at 960x540 plus a larger resolution;
   page icons and golden cursor work from images/assets; chooser overlay hides
   and restores the full background coherently.
4. //xb restart with fades on/off, a menu/inline field/chooser open, repeated
   requests, saved binding persistence and another client remaining functional.
5. Optional native XInput checkbox test remains user-pending, not a requirement
   asserted for all controllers. Alternate physical hardware remains experimental.

Atomic wrapper startup lock and last-client shutdown remain on personal backlog,
not in RC3. No input-leakage patch is included: user suspects extra physical Enter
presses and heard a Circle targeting sound without establishing a target change.
Catalog edit propagation and other personal requests remain deferred.

---

## Final-candidate assets/defaults and narrowed scope — October 12, 2026

User explicitly requests only moving owned assets/ into images/assets/, not a
broader directory overhaul. Commit 956dd5b moves all 12 files byte-for-byte;
selectable-list page/button/cursor paths, README attribution paths and packaging
allowlist are updated. Theme/helper/iconpack directories are unchanged. 46 Lua
regression groups pass. An internal complete-package audit verifies 2155 files,
44 runtime Lua files, 2101 rasters, no missing local modules or indexed icons;
all moved assets including credits/provenance are present at new paths. No
user-facing new candidate is delivered yet; the audit archive is intermediate.

Commit a70f824 sets FadeIn=0.1, FadeOut=0.5, LoadFadeIn=2 defaults, with both README
copies updated. Saved settings remain preserved. Defaults parse and whitespace
checks pass. AutoHideExtraBars=true is already implemented in the prior update.

User now suspects keyboard Enter menu-selection attempts explain the input report;
controller Circle was a targeting sound during binding, not an established target
change. Do not call either a confirmed new leakage bug or a reproduced fix.
XInput native-config test still pending. No input code changes made.

Remaining candidate discussion/implementation: bottom-heavier black background
gradient, startup phase independent of gameplay fade toggle with trigger interruption
(short fade when enabled, instant when off), user's final README corrections/new
paths/defaults, then live restart checks and clean installation package. Mutex and
last-client shutdown remain explicitly deferred to personal development.

---

## Final-pass discussion: background, input leakage and startup policy — October 12, 2026

User explicitly requests discussion before changes. Wants menu background slightly
more opaque at the bottom than at the top. Current background is flat RGB 0/0/0:
normal alpha 150/255 (~59%); custom review alpha 215/255 (~84%). Button-entry
rectangle is also alpha 150 black; inline field alpha 240 RGB 16/26/48.
Suggested gradient: normal 150 top to 190 bottom; review 215 top to 235 bottom.
No rendering changes made.

New Franklet observation: Circle and several Enter presses leaked while creating
custom actions and binding. Exact loaded build, event sources and transition
sequence unspecified. Prior passes remain valid for their tested scenarios;
this newly reported path needs investigation. Physical Enter outside an active
field currently passes through intentionally; the committing Enter and its key-up
are supposed to be consumed. Controller Circle inside menus should be consumed.

User requests startup animation despite regular fades being disabled in always
mode, with immediate reveal on held triggers when fades are off. Proposed reading:
startup duration is independent of gameplay fade toggle in both always/oninput;
triggers interrupt with normal FadeIn when enabled, immediate opacity when off;
after startup ordinary visibility resumes. Confirm interpretation during discussion,
including oninput/no-trigger case when fades are off. No runtime change.

User explicitly moves atomic startup lock and optional last-client AHK shutdown
out of the release scope and onto the personal backlog. Live restart checks follow
these final-pass discussions. Do not silently reintroduce those deferred features.

---

## Fade/default clarification and post-release motivation — October 12, 2026

User plans to test FFXI native Enable XInput while the addon keeps its selected
profile; do not treat the native checkbox as a universal requirement before the
result. No test result supplied yet.

Current code: //xb fade off disables startup animation too. Always mode shows
immediately; oninput stays hidden until a trigger, then shows without fading;
explicit hidden mode stays hidden. AutoHideExtraBars=true is implemented and
shipped in preview38-restart defaults.lua; explicitly saved false remains.
The README note describes that default, not a separate runtime change.

Recorded <t> first/default where available as a post-release request. Collected
personal ports and deferred ideas in docs/PERSONAL-BACKLOG.md; distinguish existing
personal implementations from new proposals. No runtime or uploaded README changes.

---

## Last-client unload request and final README review — October 12, 2026

User wants on_unload_killahk to mean stop the wrapper only after the last client
using this addon unloads. Current public code forces the setting false and saves;
upstream b245aa5 ran killahk.bat on each enabled client's unload. Desired correction
needs loaded-addon client registration, not merely counting FFXI windows. Proposed
unique per-client records, removal on unload, wrapper-owned stop-if-unused decision,
reload handoff grace and stale-registration cleanup. This complements the proposed
atomic AHK startup lock. Neither change is implemented or live-tested yet.

Reviewed supplied local XIVCrossbar-README-Review-Final Proposal.md (Library
libfile_145b1887bf748191a6572507309fd8cc). Required corrections: //xb can n typo
must be //xb ca n; disable-native-XInput instruction must be scoped to tested
PS5 DirectInput configuration; //xb fade affects startup/manual visibility too,
not only autohide. Restore the requested AutoHideExtraBars=true default note.
Other user's cuts and ordering are intentional. Leave the uploaded proposal
unchanged for now; the existing README review remains under discussion.

Remaining small runtime work: atomic simultaneous-start guard; optional last-loaded
client shutdown. Delivered restart awaits user-reported live checks. Startup,
completion layout, extra bars with autohide, and multi-client unload/reload results
are already recorded. Catalog edit propagation/compact toggle/icon reorganization
and personal controls remain deferred.

---

## Simultaneous all-client wrapper startup investigation — October 12, 2026

User reports send @all lua l xivcrossbar appears to load multiple AHK scripts.
Exact installed build, process count and script paths have not been supplied.
Reviewed current preview38 code: each client's start_controller_wrappers checks
fresh controller-status.ini, then writes launch configuration and issues run.
There is no atomic claim between checking status and spawning. Several clients
can therefore request launch before the first wrapper writes its initial status.
AHK #SingleInstance Ignore is present, but documentation explicitly identifies
simultaneous-start detection as a limitation that can permit multiple instances.

Source: https://ahk4.us/docs/commands/_SingleInstance.htm (AutoHotkey v1 directive
documentation, Limitations). This establishes a plausible mechanism, not a confirmed
process/path diagnosis for this particular report. Different installed folders or
older scripts remain other possibilities if persistent duplicate processes are seen.
Suggested correction: an atomic, script-folder-scoped Windows lock in the AHK
wrapper, acquired before input/status ownership, so one process is the owner and
competing launches exit. Mere same-process-name checks are not atomic and cannot
distinguish separate scripts hosted by AutoHotkey. No runtime change in this pass.

---

## RC2 Restart update — October 12, 2026

User requests restoring //xb restart while reviewing documentation. Runtime:
0.4.0-a.20261012.public-preview38-restart. Implementation closes chooser/menu/setup,
ends dragging and text capture, releases owned gameplay keys, cancels pending
profile changes and fades out the bar before sending lua r xivcrossbar.
Repeated requests schedule one reload. During the fade, controller actions and
normal bar rendering are suppressed while the geometry fade continues ticking.
Disabled fades use zero delay. The shared AHK process is unchanged and survives
this reload. //xb reload remains XML-only; //lua r remains immediate.

46 Lua regression groups pass, including actual restart command dispatch, delayed
reload, one-shot scheduling, initialized/uninitialized interactions and fades off.
Runtime syntax and package byte checks also apply. Live restart remains untested.
README copies include the restored command; their review is still ongoing.

Delivery: cumulative eight-file overlay over complete RC2/Profiles2/Setup1/Setup2.
Includes AutoHideExtraBars=true for new configurations (existing saved settings
remain), all Setup 2 changes and restored restart. No images/data/config.ini or
README shipped. INSTALL.txt outside the addon root supplies installation and tests.

Live checks: //xb restart with fades on/off; restart with an addon menu, chooser
or inline text field open; quick repeated restart requests; binding persistence
and another loaded client's controller after the restart. Check status reports
preview38-restart. No fresh remap is required for these checks.

---

## Extra-bar visibility default — October 12, 2026

User requests hiding extra bars by default while reviewing the README.
AutoHideExtraBars changes from false to true; Hotbar.Number is unchanged.
This is the behavior already live-tested with extra bars enabled. Drawing and
input rules are unchanged. Both README copies describe the default and retained
saved settings. Existing explicit false values remain false until edited.
Change awaits the next installation package; the delivered Setup 2 ZIP still
contains the earlier false default. The existing downloaded README review copy
is not replaced during this piecemeal review; incorporate this note in the next
review/release document.

---

## README review draft — October 12, 2026

User approves correcting fallback wording and deferring catalog-edit propagation
for this public release; the feature remains wanted for personal development.
Readable field commands use name/alias/command, with n/a/c described as alternative
spellings rather than literal slash syntax. No runtime changes in this pass.

README.md and packaging/README-release.md now follow the user's proposal:
changes, prominent configuration screenshot, controls/IJKL illustration,
appearance, custom actions, help, installation, simplified profiles and credits.
A concise change summary remains at the end. Startup behavior and automatic
profile switching match Setup 2; old manual-switch instructions, retired settings,
API/status internals and development build history are removed. PS5 is live-tested;
alternate hardware remains experimental. Upgrade instructions use a fresh folder
with data/config.ini/custom icons restored from backup, not mixed old code.

Draft is for user review, not a newly approved complete release. Both documentation
copies match; local image/license/notice links and available command/profile forms
are checked. No addon test package or runtime version change prepared here.

---

## Setup 2 visual checks passed — October 12, 2026

User reports both the startup fade and completion screen look good, especially
the completion screen now that its intended layout is visible. Record both
visual checks as live passes. This general feedback does not separately confirm
every trigger-interruption/fades-off variant from the detailed checklist.

Remaining release work: final clean complete-install/rollback check, README
revision from the user's proposal, configuration illustrations and package audit.
Held-direction and menu-open focus cases can be checked during ordinary play;
the held-R2 case and two-client unload/reload checks have passed.

---

## Multi-client reload live result — October 12, 2026

User ran lua r xivcrossbar on Lionstag: Franklet still worked, and after switching
back Lionstag still worked. This establishes the requested two-client reload
check in the tested setup, alongside the earlier one-client unload pass. The
report does not identify whether Setup 2 has already been installed; do not
claim the new startup/completion changes are live-tested from this result.

---

## RC2 Setup 2 — startup reveal and completion layout (October 12, 2026)

Runtime: 0.4.0-a.20261012.public-preview37-setup2. Runtime commits: 28959f9
(completion-screen rows), 4ce57b8 (startup reveal without input), 7f25836
(trigger interruption). All 45 Lua regression groups pass; changed Lua parses
with temporary normalization of inherited Windower string-method syntax.

User held R2 while clicking away, then refocused while still holding it. The
crossbar stayed cleared and a command did not fire; no stuck movement, trigger
field or unexpected action. This live result confirms neutral-before-rearming
for that held-R2 scenario. Held direction and addon-menu variants remain pending.
The multi-client reload test means lua r xivcrossbar on one client, then check
both; one-client unload has already passed on Franklet/Lionstag.

Cumulative eight-file overlay for complete RC2, Profiles 2 or Setup 1. It includes
all six Setup 1 files plus ui_geometry.lua and visibility.lua. No images,
player data, config.ini, README or developer files are included. INSTALL.txt
sits outside the addon folder. Back up, stop the shared wrapper and unload this
addon on every client using the folder before replacing Lua; then load again.
No client relog required. Existing saved fade durations remain unchanged.

Live checks:
1. With autohide on and no controller input, loading reveals the bar fully,
   then fades out. LoadFadeIn defaults to 3s; change an existing saved 1.5 to 3
   while unloaded if you want that duration. Later input uses normal FadeIn.
2. Reload and press either trigger midway through startup. The bar should
   reach full visibility using normal FadeIn from its current opacity, rather
   than waiting for the long animation. Holding does not restart the fade.
3. With fades off, trigger-held bars appear immediately. Restore fades after.
4. Completion dialog rows are separated at 960x540 and a larger resolution.
   Existing installations need not remap merely to test gameplay.
5. Multi-client reload, held-direction/focus and menu-open focus variants.

Job-ability icon lookup reviewed: resource_generator.lua derives an iconpack
category/name path and recast-ID fallback (SP abilities include job IDs). The
menu and slot renderer prefer an existing iconpack file; saved slot/shared icon
handling is separate. No icon selection behavior changed.
README revision remains deferred until finalizing live tests.

---

## Two-client unload result and extra-bar explanation — October 12, 2026

User loaded Franklet and Lionstag, unloaded XIVCrossbar on Lionstag, and reports
Franklet still works. This confirms the shared wrapper survives one client's
unload in the tested setup. It does not yet establish all held-button/focus-switch
cases. User also reports button release feels much better than expected.

Pinned upstream README recommends AutoHideExtraBars=true for six bars and documents
HotbarOffsets.DoublePress.X/Y for LL/RR (bars 5/6). X offsets move the two sides
outward/inward symmetrically; Y applies to both. Negative Y moves them upward.
These settings remain available; AlternatePress offsets concern bars 3/4. Visible
extra bars can serve as a persistent view of their bindings if repositioned.
Author intent beyond the documented behavior is not established.

AHK emits press/release edges once, releases owned signals on focus change,
disconnect or exit, and requires neutral controls before rearming. Lua additionally
releases injected gameplay keys, clears local trigger/page state and retains menu
drafts across focus changes. Crossbar fade/text release presentation is Lua.
No runtime changes or package prepared for this result.

---

## RC2 Setup 1 live results and startup reveal — October 12, 2026

User reports tests 1, 2, 3, 5 and 6 passed: automatic switching, profile commands,
disconnected-profile recovery, draft/chooser/icon binding and reload persistence.
Test 4 remains pending with multiple clients. Test 7 mostly passes, but oninput
visibility delayed the startup fade until the first trigger press. Test 8 partially
passes: extra bars work with AutoHideExtraBars=true; false draws overlapping bars.

Startup correction committed at 4ce57b8: the ready crossbar starts its
welcome reveal without input, reaches full opacity for a rendered frame, then
returns to the normal visibility policy. Default LoadFadeIn is restored to 3s.
Explicit hidden mode and cutscene suppression remain respected; disabled fades
retain ordinary autohide. Existing saved fade durations are preserved: a saved
1.5 still needs changing to 3 to test the three-second welcome. No package yet;
the installed Setup 1 still has the delayed first reveal. The completion-screen
layout correction at 28959f9 is also awaiting delivery.

45 Lua regression groups pass, including the real prerender startup path with
controlled time, no input, readiness/hidden/cutscene guards, full opacity, normal
fade-out, held triggers and subsequent short fades. Whitespace checks pass.
Extra-bar coordinate methods and draw-policy rules match pinned upstream baseline
b245aa5; the overlapping positions with default offsets are inherited. No extra-bar
layout/default changes made; AutoHideExtraBars=true is the live-tested choice.

Remaining: multi-client focus/held-release and reload/unload checks; live startup
reveal and corrected completion-screen layout after delivery; clean complete-package
install/rollback audit, README update from the user's proposal and configuration
illustrations. Alternate controller hardware remains explicitly unverified.
No new features are required by this checkpoint. Do not repeatedly retest the full
passed list unless subsequent changes affect it.

---

## Cioara Setup 1 feedback — October 12, 2026

User reports setup completed on Cioara on Frank's PC and normal functioning so
far. Completion-screen screenshot shows overlapping success/help text and crowded
Share/Options artwork, matching Lionstag's earlier observation. Code placed the
first two text rows ten pixels apart regardless of resolution. Completion layout
now uses separate success, action-menu, chooser, new-set and exit rows. No setup
behavior changed. Fix committed for the next update; no package generated yet.

---

## RC2 Setup 1 — first-run profiles and automatic switching (October 12, 2026)

Runtime: 0.4.0-a.20261012.public-preview36-setup1. Previous live-tested profile
snapshot is preserved as tag testing/public-rc2-profiles2 at 7b58860. This pass is
restricted to the four agreed usability changes and the initial fade default.
README revision and catalog edit propagation remain deferred. AHK reader/transport
code is unchanged from the startup-file fix in Profiles 2.

### Installation

Run //xb controller stop on the old code, then unload XIVCrossbar on every client
using this folder. Back up the folder. Merge the supplied six files into
addons/xivcrossbar. Keep installed data/config.ini/images. Reload; no client relog.
This update includes all changed runtime files needed over original RC2 or its
Profiles 2 fix. Developer documents/tests stay outside the addon download.

### Live checks

1. //xb controller status: saved/running ps5-directinput, device 1, Apps, ready,
   connected=true. Retest one ordinary binding and addon-menu Cross/Circle/D-pad.
2. //xb controller profile xinput: no separate stop/start commands. Wait about
   two seconds, check status: running XInput. Disconnected is expected on the
   currently tested PS5 setup; it does not mean switching failed. Return with
   //xb controller profile ps5; check ready/connected=true and one bound action.
3. //xb controller profiles lists short names. Long profile names remain valid.
   Unknown names/out-of-range device values must leave the current selection intact.
   Optional device number remains supported. Manual start/stop remain available;
   an explicit stop cancels a pending automatic change.
4. //xb remap opens the input profile screen. Four options: PS5 DirectInput,
   Xbox/XInput, F710 DirectInput, FightPadPro DirectInput. Hover lifts the row two
   pixels up/left and returns it without accumulating offsets. Choose PS5: after
   detection, choose artwork separately, then Confirm/Cancel/Main Menu/Active Window.
   Intended PS5 face layout: Cross/Circle/Triangle/Square respectively. Complete
   existing confirmations; verify settings save and ordinary bindings still work.
5. Remap again; choose XInput. If disconnected, remain on profile choices with
   an explanatory message. Choose PS5 to recover. No console startup commands
   should be needed. Check at 960x540 and a larger resolution.
6. Fresh-install welcome test later: welcome click opens profile choices without
   starting AHK. Only selecting a profile starts its reader. Data/bindings need not
   be deleted for testing; preserve the normal installation separately.
7. //xb fade off/on and bare toggle act identically to //xb ui fade. Invalid values
   change nothing. New initial-load fade default is 1.5s; existing explicit saved
   Animation.LoadFadeIn values remain unchanged. To try it on an existing config,
   set LoadFadeIn to 1.5 while unloaded and reload.
8. Remaining release checks: multi-client/focus changes, additional bars 4-6,
   fresh setup without subjob, custom actions/icons/chooser draft, and persistence.

### Verification and implementation

44 Lua regression groups pass. New switch state machine waits for fresh stopped
status, includes a short post-ExitApp buffer, and verifies the actual running reader.
It polls only during a pending change, handles timeout/cancel/competing clients,
and avoids claiming success from a start request alone. Callback generations keep
closed/restarted setup from being reopened by an old completion. Actual wizard
mouse paths and geometry are tested at the small baseline plus existing larger
resolution tests. Local syntax normalization remains temporary for inherited
Windower string-method shorthand. Windows graphics and this exact automatic
switch behavior await live confirmation. No README package prepared in this pass.

---

## Lionstag live profile results — October 12, 2026

RC2 Profiles 1 PS5 DirectInput: status ready/connected, bare native-menu D-pad,
addon menu D-pad/Cross/Circle/Share, no action bleed-through, L2/R2 bound actions
without macro popup or target leakage, and optional IJKL targeting all passed.

RC2 Profiles 2 startup handoff: selected XInput now becomes running XInput,
Apps, source=launch-file. This supports the missing launch-arguments explanation;
startup-file fallback is live-confirmed. XInput devices 1, 2, 3 and 4 each report
disconnected/connected=false. Native FFXI stick movement/camera continue working,
which does not establish XInput exposure to AHK. Alternate XInput hardware behavior
remains unverified; a separate detection investigation can follow if desired.

Switching back via stop/profile ps5-directinput/start returns ready/connected=true
and a bound action executes successfully. No user configuration or binding repair
was needed. All results are user-reported on Lionstag; no claim of other controller
hardware validation. Profile short aliases/automatic stop-start and README proposal
are pending, not included in Profiles 2. No new package prepared for this checkpoint.

---

## RC2 Profiles 2 — startup handoff investigation (October 12, 2026)

Lionstag live RC2 Profiles 1 results: PS5 status ready/connected; native menu
D-pad, addon menu face/D-pad input without bleed-through, L2/R2 bound actions,
no macro palette/target leakage, and IJKL targeting all pass. Switching selected
profile to XInput still reported a running PS5 reader after stop/start; stop then
reported no fresh running status, but a new start again reported PS5.

Likely cause under investigation: launcher/script association omitting profile
arguments, causing the AHK default. Not yet proven; alternative includes another
client starting the PS5 reader. Profiles 2 writes a validated startup INI before
launch and reads it at AHK startup when profile arguments are absent. Status adds
origin=arguments/launch-file/default to identify the path actually used. Running
reader never rereads the handoff, preserving startup-only selection.

43 regression groups pass, including startup INI validation/write errors and
lifecycle ordering; mapping checks remain passing. Small overlay contains only
xivcrossbar.lua, controller_profiles.lua, ffxi_directinput.ahk plus outside-folder
installation instructions. Complete package also rebuilt. No profile auto-restart,
short aliases or catalog propagation changes included in this diagnostic fix.

Retest: stop current wrapper, unload addon, merge overlay, load, start selected
XInput, release buttons/focus FFXI and check controller status after one second.
If mismatch persists, return data/controller-status.ini and controller-launch.ini
and note other clients that might be loading XIVCrossbar. No relog required.

---

## RC2 Profiles 1 — selectable controller readers (October 12, 2026)

RC1 is preserved as tag `testing/public-rc1-preview34` at cc6b7bf and as the
previous complete download. Work is isolated on `public/controller-profiles`.
Runtime: 0.4.0-a.20261012.public-preview35-profiles1. This is a testing candidate,
not a claim of live validation of other controllers. No AHK v2 or personal controls.

### Install and test

1. While still on the old package, run `//xb controller stop`, release buttons,
   and unload XIVCrossbar on every client. Back up the installed folder. Merge
   the complete RC2 folder, preserving data/config.ini/custom assets; reload.
2. `//xb controller status`: saved ps5-directinput/device 1 and running
   ps5-directinput/apps should agree. Focus FFXI and wait one second before
   checking connected/ready. Release controls if waiting-neutral is reported.
3. PS5 regression: bare D-pad native menus; addon menu D-pad/Cross/Circle/Share;
   all slots on L2/R2; both-trigger arrangements; no macro popup or F-key target
   leakage; physical keyboard F7/F8 still target normally.
4. Focus switch while holding a face/D-pad/trigger, release, return. No automatic
   execution on rearm and no stuck native direction/trigger field. Reload the
   second client: it must reuse the shared wrapper, not replace its selection.
5. `//xb controller profiles`; save `//xb controller profile xinput 1` while
   the PS5 reader runs. Status must say selected XInput but running PS5. Start
   must refuse that mismatch. Stop, wait for completion, then start from the
   client with XInput selected. If changing through the wizard, use the console
   before input confirmation; artwork selection alone never selects a backend.
6. XInput: check connected status first. If disconnected, try device 2–4 with
   stop/profile/start; do not claim success from FFXI's checkbox alone. If detected,
   test each digital button, each trigger and both simultaneously; repeat step 3.
   Diagonal D-pad inputs may set two directions under XInput. Record any difference.
7. Return via stop/profile ps5-directinput 1/start. Verify ordinary actions and
   menus again. Invalid names and device numbers must leave the saved choice intact.
8. Optional hardware owners: F710/FightPadPro use corresponding profiles. The
   xinput-r1-chooser profile uses R1 for Options/set chooser; clear duplicate native
   R1 assignment. All alternate hardware profiles remain experimental.
9. Additional bars: in a backed-up test config increase Hotbar.Number to 6 and
   reload, then test both-trigger order variants and double-L2/double-R2 bars,
   binding/execution, scale/drag and AutoHideExtraBars on/off. Restore normal value.
10. Fresh installation: new setup/character without subjob; custom action creation,
    inline Enter protection, save/bind/draft-preserving chooser; Use Item icon;
    Superwarp; visibility/scale/drag; reload and job-change persistence. Check at
    960x540 and a larger resolution. User configuration screenshots are in README.

### Results and limits

43 Lua regression groups pass, including actual profile lifecycle handlers with
simulated wrapper status and pending-stop timing. Reader assignments are compared
with all three upstream DirectInput scripts; XInput digital flags and trigger
record offsets checked. These are offline checks, not Windows/AHK execution.
The standard syntax checker normalizes inherited Windower string-literal method
shorthand in a temporary copy only. No existing XML bindings changed here.
Status heartbeat uses data/controller-status.ini and is fresh for five seconds.
No fresh status does not prove that an old uninstrumented wrapper is absent.
SingleInstance ignore remains the final duplicate-process guard. Profile settings
are per client; running reader is shared. No running profile is changed by saving.

Retired new defaults: below1080, Controls.ToggleBattleMode and independent
use_directinput/use_xinput flags. Legacy XML keys remain unused. on_unload_killahk
remains forced false; explicit shared stop applies. InputTest/InputTrace remain
false by default. All release credits/comments now use A. README is current user
instructions; historical development information remains here and in git.

---

## Next-package notes — October 12, 2026

Contributor identity is A; apply it consistently to release credits. Before the next package,
search all authored credit/comment/documentation references to A and change
them to A; retain other authors and filenames whose identity is unrelated.
Do not prepare a new package yet. RC1 remains unchanged for current testing.
Review README around user-facing FFXIAH requests: Apps avoids native macro
palettes/Ctrl shortcut conflicts; menu/slot routing avoids duplicate input;
scaling/positioning/visibility; simpler custom actions; icon and persistence fixes.
Configuration guide: native macro actions are not universally forbidden; avoid
assigning them to L2/R2 used by this wrapper. Supplied annotated gamepad and IJKL
screenshots are candidates for inclusion after configuration validation.
Alternate upstream wrappers were excluded from RC1, not adapted: next discussion
must cover explicit backend selection/start/stop and shared transport contracts.

---

## Clean RC1 package audit — October 12, 2026

Packaging preserves the Preview 34 runtime build ID. No feature additions.
Local commits: 19fa1fa removes unconditional wrapper edge logging; 05d0589
removes missing Goring_Blade.png and PSD source entries from the legacy index.
Packaging recipe and distribution README are under packaging/; development
history remains in this checkout, excluded from the download.

Complete ZIP contains 2,151 files: 42 runtime Lua modules, 2,099 verified raster
assets, the tested PS5 DirectInput wrapper, attribution/provenance, theme assets,
icon index and its two upstream regeneration helpers, and a current README.
Excluded: all tests/internal design notes/preview install notes, probes and
unadapted wrappers, Python/Linux inputs, killahk.bat, config.ini, player data,
SVG/PSD source artwork and obsolete gamepad configuration screenshot.
No folder restructuring. LICENSE, NOTICE and menu asset credits retained.

All 41 regression groups pass. All 42 runtime Lua files parse in a temporary
copy after normalization of inherited Windower string-literal method syntax;
source remains unchanged. No missing local module or legacy icon-list entries.
Every packaged byte except the distribution README matches the audited checkout.
ZIP integrity passes; per-file hashes and exclusions are recorded outside the
addon in PACKAGE-AUDIT.json. Windows/AHK execution and fresh installation of this
exact clean ZIP still require live testing. Installed player data is not modified.

---

# Public Preview 34 — Options overlay and Execute Command removal

Version: `0.4.0-a.20261012.public-preview34`. Cumulative overlay with Preview 33
rollback. Preserve all current data/settings/images. Runtime commits 053e221 and
db62c25; local, not pushed. No AHK, item extraction or personal-control changes.

1. Apply and `//lua r xivcrossbar`; //xb status reports Preview 34.
2. Open Review/Save/Edit, hold Options. Draft remains readable underneath at
   roughly 45% foreground opacity. Choose Crossbar appears above it on a nearly
   opaque black panel with a gold highlight. Up/Down switches destination; header
   changes to Basic Crossbar/All Jobs Default Crossbar in its existing colors.
3. Release Options: exact opacity returns, including previously dim choices.
   Circle/Esc cancels and restores the prior set. Draft, field buffer and menu
   page stay intact. Repeat from main menu, combo capture and combo confirmation,
   including physically held triggers and text entry. No accidental bind/save.
4. Check 960x540 and 1280x720 first, then 1920x1080/3840x2160 when convenient.
   Heading and all list rows should fit within the screen, remain anchored above
   Options, and visibly layer over the menu. Inspect whether menu glyphs interfere
   with chooser labels; native graphics layering still requires this live check.
5. Open/close repeatedly and switch focus away/back: no duplicated chooser text,
   accumulating layers, stuck menu opacity or hidden-menu mouse selection.
6. Execute Command is absent; Remove a Binding is immediately before Credits.
   New command creation uses Custom Actions. Recheck any existing legacy raw
   binding; its type/execution remains untouched. No live bindings are migrated.
7. Continue retained release checks: ordinary Enter/text commit, item icons,
   destination labels, Check, disabled-catalog explanation, fresh setup and
   bindings surviving reload/job changes. Folder cleanup/config guide remain.

41 local Lua regression groups pass. Menu suspension now exercises live-object
opacity dim/restore rather than hiding. Overlay-layer tests verify bounded object
replacement, background-before-text creation, heading dimensions and gold/opaque
colors. Existing screen-clamp, controller ownership, draft persistence and all
other checks pass. Actual legacy raw-command dispatch remains verified after
menu removal. Changed runtime Lua parses in the local Lua 5.4 harness; actual
Windower renderer behavior and user preference still await the live checks.

---

# Public Preview 33 — personal-branch Options handoff

Version: `0.4.0-a.20261012.public-preview33`. Cumulative overlay with Preview 32
rollback. Preserve all user data/settings/images. Runtime checkpoints 0f1c820,
f4dbd6d; local only, not pushed. No AHK/personal companion or global asset moves.

User live feedback: Preview 31 consumes Enter during text editing and restores
normal behavior afterward. Preview 32 still failed to expose Options switching
across menu/binding/review states. Personal branch inspection identified its early
Options ownership and set_chooser_active menu suspension. Port the behavior using
public-branch object visibility snapshots rather than the personal menu geometry.
Preview 32 had navigation priority but did not suspend the obscuring modal menu.

1. Apply and `//lua r xivcrossbar`; //xb status reports Preview 33.
2. At the main menu, Review/Save/Edit, button-combo capture and combo confirmation,
   hold Options. The menu temporarily disappears and the set chooser is visible.
   Up/Down changes the selected set. Release Options: same menu, selector page,
   draft and text buffer return. No accidental confirm/bind/save or page turn.
3. Repeat while editing a field and with L2/R2 held during binding. Circle/Esc
   cancels chooser, restoring the previous set. Setup wizard ignores this handoff.
   A chooser button's release must not become a menu confirm/binding event.
4. Try unfinished Add New Set: another Options press dismisses it; release must
   not reopen it. Choosing/confirming a new set resumes an underlying draft.
5. Review/binding destination title and bind/unbind chat say Basic Crossbar or
   All Jobs Default Crossbar, with existing blue/white title colors. Actual names
   and XML keys remain Basic/default/etc; this is display clarification only.
6. Unlinked custom-command slots without an explicit icon show none.png's blue
   field. Catalog pickers show a full-size gear; valid linked artwork or explicit
   icon wins there. No default icon value is written to XML. Existing explicit
   gear icons remain explicit until the user clears them.
7. Recheck Enter commit/ordinary Enter, focus switching and ordinary slot commands.
   Focus cancellation resumes suspended menu state without saving anything.

40 local Lua regression groups pass. New fixture exercises the actual early
controller router and menu visibility handoff in four states, safe slot releases,
draft/text persistence, precise visibility restoration and consumed held-trigger
page gestures. Catalog tests cover explicit/linked/gear precedence without XML
mutation. Existing naming, disabled-choice, Check, icons, file-safety and Enter
checks pass; changed runtime Lua parses. Windows/FFXI checks still pending.

Release focus remains: live polish verification, fresh setup, bindings surviving
reload/job change, configuration guide and distributed-folder cleanup. Do not
restructure assets or personalize the main menu ahead of the playable release.

---

# Public Preview 32 — visible destinations and custom-action polish

Version: `0.4.0-a.20261012.public-preview32`. Cumulative overlay with Preview 31
rollback. Preserve all user data/settings/images. Runtime checkpoints de85a7f,
9b8d64d, 26bb1b6. Local commits, not pushed. No AHK/personal controls or asset moves.

1. Apply and `//lua r xivcrossbar`. Status identifies Preview 32.
2. Open a named custom-action draft. While on Review/Save, hold Options and use
   Up/Down to choose another set. Draft Name/Alias/Command/icon/link remain intact.
   Header changes to the destination's display name, blue for default/shared
   layers and white for ordinary sets. Save & Bind into that destination.
3. Review/Edit plus every combo capture/confirmation view share that set label.
   Sample spell, item, warp, custom action, Change Slot Icon, Change Action Icon
   and Remove a Binding. Switch a destination mid-combo; title follows and combo
   remains intact. Most paths reuse display_button_assigner/display_button_confirmer;
   45 action categories are covered by the shared-view fixtures at six sizes.
4. Create/bind a custom action with no chosen icon: full-size opaque gear appears
   with normal visibility fading. XML/catalog icon remains absent/blank. Choosing
   an explicit icon still wins. Valid linked action artwork also retains priority.
   Compare Custom Action and Edit/Delete pickers: default gear no longer has the
   erroneous four-pixel down/right offset. Test at 960x540 and 1280x720.
5. On an empty catalog in a separate fresh test installation, navigate onto
   Custom Action/Edit/Delete. Dark translucent red selection, red text, dim icons,
   no selection lift; Confirm explains how to create an action and stays there.
   Do not delete your live catalog just to test this. Blank-name Save choices
   remain skipped; only the three empty-catalog main-menu choices are focusable.
6. Main menu order: Ranged Attack > Attack > Check > Assist. Bind Check, target an
   NPC/enemy and execute: command is input /check <t>, icon check.png. Circle Back
   and Share Exit retain existing behavior.
7. Continue Preview 31 Enter checks and normal reload/job/focus/binding tests.
   Preview 31 is still awaiting live feedback; local tests are not confirmation.

38 isolated Lua regression groups pass. Tests exercise actual renderer fallback
without field mutation, actual set-switch adapter/title refresh with persistent
draft/combo state, all shared binding categories at six resolutions, unavailable
navigation/colors/no-lift, explanatory submit and saved Check dispatch. Runtime
Lua syntax checks pass. Windows/FFXI live checks remain pending.

Release checklist: fresh setup and binding persistence; controller configuration
screenshots/guide; trim the distributed folder to runtime/assets/licenses/use
instructions. Exclude AGATHOS/DESIGN/WORKFLOW, development history/tests and old
preview instructions from the community release archive; retain them in source
history/development materials. Preserve existing addon assets/third-party notices.
Do not undertake a global asset-path migration or Trust-state feature for release.

---

# Public Preview 31 — native Enter block and set-name geometry

Version: `0.4.0-a.20261012.public-preview31`. Cumulative overlay with Preview 30
rollback. Preserve user data/settings/images. Three local commits, not pushed.

User live result: Preview 30 Enter still leaked in Options/main-menu set creation
and initial/edit custom-action fields. Main-menu set-name box appeared upper-right.
Prior regression tested Lua event ownership but missed native-block lifetime:
set_capturing_text(false)/chooser clear released keyboard_blockinput during the
confirming down event. Keep native blocking through release, then prerender clears
it. No timed delay and no ordinary keyboard bindings changed.

1. Apply and `//lua r xivcrossbar`; status identifies Preview 31.
2. Test Options > Add New Set and main-menu Create New Set: type/press Enter.
   Name commits once, with no background chat/menu action. Main-menu entry panel
   and placeholder/typed caption stay centered at 960x540 and 1280x720.
3. Repeat bare `//xb ca` name entry and Edit Name/Alias/Command fields. Test
   short/held Enter; rejected blank names still permit retry after release.
4. After editing closes, regular Enter still works in game/chat. Recheck focus
   out/back, Circle Back and Share Exit. No stranded native keyboard block.
5. Preview 29 item extraction is now live-confirmed by the user: items work.
   Item/job code and AHK unchanged from Preview 30; ordinary binds remain intact.

37 Lua regression groups pass, including native command sequence around field
closure/held Enter/release/prerender/reset. Changed Lua parses. Live FFXI behavior
still requires the above check; earlier local checks did not establish the native
input timing. Follow-up polish and public-folder cleanup remain pending.

---

# Public Preview 30 — Enter commits only the active text field

Version: `0.4.0-a.20261012.public-preview30`. Cumulative overlay with Preview 29
rollback. Preserve all current data/settings/images. User has now authorized
consuming Enter while a text field is active; the Preview 29 discussion note
below records the earlier decision to defer. Runtime checkpoint is the Enter
ownership commit immediately preceding this packaging commit; local, not pushed.

1. Apply and `//lua r xivcrossbar`; status identifies Preview 30.
2. Open `//xb ca` or edit an existing action. Type a Name/Alias/Command and press
   Enter. It commits once. Neither down nor release should open chat/confirm
   anything behind the addon. Hold Enter briefly: no repeated submissions.
3. Try a rejected/empty name: the field remains active; release then press Enter
   again to retry normally. Circle/Share/controller confirm remain unchanged.
4. Repeat for set creation through the main menu and Options set chooser.
5. Outside text entry, Enter retains its existing game/chat behavior. Check it
   after editing and after switching focus out/back. No ordinary key bindings
   are changed. Focus/unload clears pending confirmation ownership.
6. Continue Preview 29 item/job checks below; those features are unchanged.

37 local Lua regression groups pass. Tests execute the actual keyboard callback's
Enter interception with binder/chooser field closure, rejected input, held repeat,
release and ordinary gameplay edges. Focus cleanup and syntax checks pass. Live
FFXI validation remains pending; the earlier confirming key-down was already
consumed, while release ownership was lost when editing closed.

---

# Public Preview 29 — expanded item records and one job-change notice

Version: `0.4.0-a.20261012.public-preview29`. Cumulative base overlay; rollback
restores Preview 28. Preserve all user data/settings/images. Runtime checkpoints:
034e69d (validated record layouts), fa862ec (quiet creation/job-change summary).
Local commits, not pushed. No AHK/controller mapping or keyboard-entry changes.

1. Apply the overlay and run `//lua r xivcrossbar`; status identifies Preview 29.
   `//xb reload` reloads bindings only, so it does not load updated Lua code.
2. Open Use Item on Franklet. Check identifiable items such as Instant Warp,
   food and crystals against their in-game icons. Bind one and confirm menu/slot
   show the same icon. Existing custom icon overrides remain intentional.
   The resolver uses a fresh `images/extracted_items_v5` cache without deleting
   older caches. No client restart or manual cache deletion is needed.
3. If an item remains wrong or falls back, send its displayed name/ID, a labeled
   screenshot when convenient and any new v5 .record.dat/.record.txt pairs.
   Diagnostics are now at most 5 KB per failed record; game DATs are read-only.
4. Change main/subjob when convenient. Crossbars load immediately, while chat
   waits 0.3 seconds after the latest event to consolidate related messages.
   Expect one XIVCrossbar line, for example:
   `[XIVCrossbar] Crossbar sets ready for DRK/RDM (created DRK-DEFAULT.xml, DRK-RDM.xml, DRK-WAR.xml).`
   Existing combinations get one line without the created list. XML backup
   notices disappear, but backup files are still made before original writes.
   Another addon's `JobChange: Changing...` lines are outside this change.
5. Recheck one binding after job change/reload. Current binds are retained;
   no recovery from older backups is requested or performed.
6. Deferred discussion: Enter committing a new/edited custom-action field leaks
   into gameplay. User requests no change yet and values keyboard freedom.
   Consider consuming only the active field's confirming press/release while
   leaving keyboard behavior outside editing intact; do not implement yet.

Evidence reviewed: upload/extracted_items_v4.zip, Lionstag_2026.10.12.log and
Franklet_2026.10.12(1).log, as supplied locally. Lionstag lines 132-138 announce
DRK-WAR/DRK-DEFAULT/DRK-RDM and backups. Franklet lines 229-230 announce WAR-WHM
and WAR-DEFAULT, then line 234 confirms Preview 28 was loaded. The newer item
messages have no secondary nil-offset error, confirming the raising guards.

Actual captured offsets establish 0x1400 spacing: offset 1,582,080 contains item
309 (515 * 3072 = 309 * 5120); usable offset 261,120 contains 4147 rather than
4181 (85 * 3072 = 51 * 5120). Other complete starts independently agree, while
several old offsets land in pixel data or zeros. No rotation/bitmap-format guess
was needed. Preserve the older Preview 28 notes as the earlier investigation.

Validation: 36 isolated Lua regression groups pass; changed runtime files parse
in the local Lua 5.4 harness. New coverage checks nonzero record offsets for both
sizes, index-zero ambiguity, stride reuse, pixel bytes, short-record rejection,
quiet real-style file creation and merged successful/failed job notifications.
Five complete neighboring records recovered from the user's captures were also
fed through the actual extractor locally. Independent Python decoding agrees on
all 5,120 output pixels. Those raw game records/generated images are not shipped.
This validates recovered neighbors, not the requested items at their correct
new offsets: live rendering of those requested items is still pending.

---

# Public Preview 28 — Windower guard compatibility and item diagnostics

Version: `0.4.0-a.20261012.public-preview28`. Cumulative base overlay; rollback
restores Preview 27 runtime. Preserve all bindings/settings/images. Runtime
commits d5b0191 and 12223e0; local only, not pushed. No AHK/personal controls or
menu layout changes. Item format/offset selection is not changed speculatively.

Live evidence: upload/Franklet_2026.10.12.log, 137 lines, reports Preview 26;
the item code is also unchanged in Preview 27. Seven failed IDs: 4413, 5885,
924, 4400, 8711, 922 and 8973. Each prints ID mismatch, absent bitmap and then
arithmetic on nil 'at'. Official Windower logger.lua source confirms its global
error() only logs and stores Lua's raising function in _raw.error. The public
guards had assumed standard Lua error semantics; tests now reproduce the actual
logger contract. Capture the raising function in player/storage/extractor.

User confirms fallbacks work; some images changed but none are correct. User
likes the quieter load status and explicitly declines binding-backup recovery;
leave current bindings as-is. No binding restoration is part of this build.

1. Apply overlay, then //lua r xivcrossbar; //xb status reports Preview 28.
   Stop/unload all clients first if following the full installation procedure.
2. Open Use Item on Franklet once. Validation failures should now print one
   useful message per failed ID, including requested/found IDs, source DAT and
   byte offset. No secondary nil-'at' error; menus and fallback icons remain usable.
3. Zip/upload images/extracted_items_v4 after this check, especially the numeric
   .record.dat and .record.txt pairs. Each raw record is only about 3 KB.
   Include one screenshot labeling a wrong displayed item if convenient.
   These actual bytes are needed to distinguish wrong record addressing from
   format/bitmap differences before changing the decoder. No client closure or
   full game-DAT upload is needed for these diagnostic captures.
4. Existing successful icons in older caches are not reused by the new resolver;
   old files remain untouched. Explicit custom iconpack overrides remain honored.
5. Recheck one ordinary binding, reload and the quiet loaded-sets status. The new
   raising guards also protect failed XML/save paths; destructive scenarios stay
   in isolated regression fixtures, not live character files.

34 local Lua regression groups pass, including Windower logger semantics, no
write after failed XML guards, and rejected-DAT evidence capture. Changed runtime
Lua parses. Real DAT decoding and Windows/Windower rendering still need the
record captures/live check. The provided log supports the guard-fallthrough
diagnosis, not a claim that all item-format problems are already solved.

---

# Public Preview 27 — missing defaults and job-change selection

Version: `0.4.0-a.20261012.public-preview27`. Cumulative upstream-base overlay
with Preview 26 runtime rollback. Preserve data, config.ini and original images.
Runtime checkpoints: 07e16b9 (missing defaults), 39de9ee (post-load selection);
local commits, not pushed. No AHK, item-extractor or layout changes.

1. Stop/unload, apply the xivcrossbar overlay and load/reload Lua. Status reports
   Preview 27. Verify current sets/bindings before further edits.
2. When convenient, switch main/subjob in-game. A valid current/shared set stays
   selected; otherwise the chooser picks a set that exists in the new job data.
   Switch back and confirm the previous job's saved bindings remain present.
   No nil-set error, empty display from a stale job-only name, or file deletion.
3. Create/save one disposable binding, reload, and recheck the current named set
   and default slots. Missing-layer/import cases are covered in isolated fixtures;
   do not delete live XML files merely to create a test scenario.
4. Repeat Alt+Tab with menus open/closed, ordinary Apps slot execution and native
   keyboard F7/F8. Keep the item-icon comparison from Preview 24 on the live list.
5. If slots remain missing, send the character XML folder including backups,
   settings.xml, current logs and //xb status before more binding changes.

32 Lua regression groups pass locally. New fixtures run the actual loader and
serializer to verify missing default files preserve already imported labels/
slots and repeated initialization retains extra bars. They also execute the
actual reload/job-change callback and default-only chooser selection. Changed
Lua files parse in the Lua 5.4 harness; Windows/Windower live validation remains
pending. This does not establish the cause of the user's earlier missing binds.

README now uses //xb remap for setup, explains one-screen custom actions in its
command table, names Hotbar.Number correctly, and distinguishes the tested
Windows DirectInput path from retained upstream wrappers. Main-menu order wording
matches Create Custom Action first. User-collected setup screenshots still need
to be supplied before incorporation into the final release guide.

---

# Public Preview 26 — preserve stored sets and inactive bars

Version: `0.4.0-a.20261011.public-preview26`. Cumulative base overlay with a
Preview 25 runtime rollback. Core fix a91a18f; local commits, not pushed.

Continuation audit found independent loader risks: display names were used as
set keys/scopes; empty sets were never constructed without a slot; omitted name
fields fell back to a numeric index; stored bars beyond the enabled count were
dropped before later saves. Regression fixtures reproduced these issues. The
loader now uses the XML tag for identity, retains the label, creates empty sets
and preserves inactive bars. Hidden labels no longer defeat legacy alias-only
commands. No display/layout, controller, icon-extractor or personal-control change.

1. Back up your current data, including .bak files. Stop/unload, apply the
   xivcrossbar overlay, and load/reload Lua. Status reports Preview 26.
2. Check the same character/job and active set before changing bindings. All
   existing named sets and slots should remain present. Repeat the Preview 25
   Alt+Tab checks below, with the addon menu open and closed.
3. If you already have extra bars disabled, their stored slots must survive a
   reload and a disposable binding save. Their UI/input stays disabled. Do not
   alter valuable data just to create this scenario; the fixture covers it.
4. If bindings still appear missing, send the character XML folder, .bak files,
   settings.xml, logs and //xb status output before further binding changes.
   Actual deletion/recovery remains unconfirmed without those files.

30 regression groups pass in the local Lua 5.4 harness; changed runtime syntax
checks pass. Added checks cover set-key/display-name separation, all-job scope,
empty sets, missing name, disabled bars and hidden-label fallback. Live Windows
behavior and actual extracted item images remain pending. This patch cannot
recover data absent from both current XMLs and backups.

---

# Public Preview 25 — focus-reset hotfix

Version: `0.4.0-a.20261011.public-preview25`. Cumulative overlay including the
Preview 24 safeguards; rollback restores Preview 23 (before the new focus
cleanup). Preserve data, config.ini and images. Runtime fix: 339663a; local only.
No AHK or item-extractor changes in this hotfix.

Live Preview 24 report: Alt+Tab causes action_binder.lua:455, attempt to call
consume_page_gesture (nil), with menus open or closed. The test incorrectly
mocked that nonexistent method. Corrected reset directly clears page_gesture
and its selector highlight. The revised regression loads the actual binder
reset methods and selector page-highlight method and verifies focus loss/gain
with open, closed and uninitialized menus. All 29 groups pass locally.

1. Back up current data and .bak files. Stop/unload, apply the overlay, then
   `//lua l xivcrossbar` (or `//lua r xivcrossbar` after replacing the files).
   `//xb reload` reloads bindings only and does not install new Lua code.
2. `//xb status` reports Preview 25 and the expected active set. Check your
   existing bindings before making new ones.
3. Alt+Tab out/in with the addon menu closed, then open. No 455 error. Test a
   held gameplay D-pad key, trigger, page gesture and inline text draft; focus
   cancels controller ownership without firing, paging or discarding the draft.
4. If bindings remain missing, retain/send data/hotbar/<server>/<character>
   including XML .bak files, settings.xml and current logs/status. Code review
   finds no binding write/delete in the focus handler; the interrupted display
   alone cannot establish disk deletion. Do not overwrite backups through new
   binding tests until the evidence is captured.
5. Item icons should depict the correct corresponding in-game items. Generic
   icons are fallbacks, not confirmed extracted images. Continue the Preview 24
   icon checks below; extraction's real DAT/image correctness remains unverified.

No new screenshots or character files were supplied with this error report.
The binding-loss report remains an open investigation, not a confirmed deletion
or a claimed recovery. The personal branch is unchanged.

---

# Public Preview 24 — load/save safeguards and item-icon review

Version: `0.4.0-a.20261011.public-preview24`. Cumulative overlay for the
qEagleStrikerp base installation. Rollback restores Preview 23 runtime. Preserve
config.ini, data, controller preferences and the original images folder. No
personal companion/controls, character bindings or compact toggle are included.
AHK scripts are unchanged. Five focused runtime commits: 3d389ef, 14c79ec,
09665eb, 34919be, a1bbf3f; all local, not pushed.

## Install and check in order

1. Back up the installed addon folder. `//xb controller stop`, unload on all
   clients, merge the package's xivcrossbar folder, then load. `//xb status`
   reports Preview 24. Existing sets/bindings should remain available.
2. Open Use Item and Trade Item. Compare a few recognizable icons with their
   in-game icons (Instant Warp, Honey or another item you have). Bind an item in
   a disposable slot and compare the menu/slot image. An older extracted binding
   should resolve through the fresh cache without rebinding. Explicit iconpack
   overrides still take precedence. Missing DAT images leave usable fallback
   icons and one chat diagnostic per failed ID per load.
3. If icons remain wrong, send the corresponding BMP from
   images/extracted_items_v3 (filenames are numeric item IDs), a game screenshot,
   chat/console diagnostics and the installed version. Do not delete old caches
   or close clients solely to refresh these images; Lua reload retries failures.
4. Create a disposable custom action, test an explicit command and a blank
   command with an existing Windower alias. Save/Bind, return with Circle, and
   reload. Existing actions and independent slot bindings remain intact.
5. Make a disposable binding change, inspect the affected `.xml.bak` files, and
   reload: every existing XML layer has its prior-save backup. Malformed XML,
   failed serialization and write failures are tested with isolated fixtures;
   do not corrupt live character files for this check.
6. Hold a gameplay D-pad direction, change focus to the other client, release,
   return and press once. Repeat with L2/L2+direction and R2/Circle: no stuck
   movement/trigger field, extra action or target change. Repeat while editing a
   custom field or set name: drafts survive focus changes. An ordinary held
   Options list closes on focus change.
7. Recheck physical F7/F8, ordinary Ctrl shortcuts, addon-only navigation with a
   native menu underneath, Share exit, Circle Back, and reload persistence.
   Inspect compact/full layout, scaling, dragging and fades at 960x540 and one
   larger resolution; no layout or input mapping change is intended here.

## Verification and limits

29 regression groups pass through the local Lua 5.4 harness, including actual
loader, serializer, binder, extraction and focus paths. Changed runtime files
parse; this is not a Windows AHK or Windower Lua 5.1 execution. Item tests use
synthetic DAT records with relocated bitmaps and known pixel colors, including
wrong IDs, absent headers, truncated data, failed writes and fallback routes.
Actual FFXI icon appearance and the multi-client focus behavior require live
confirmation. The existing corrupt-cursor bars and tiny first-frame caption
centering hop remain open/deferred; chooser fade-frame misalignment remains
deferred at the user's request.

Read-only personal-branch comparison led to targeted safeguard adaptations; its
shared-catalog migration/conflict checks, loaded-slot edit propagation, menu
skin/sounds and companion have not been imported. Catalogs remain per-character.
Compact on/off command remains deferred. Screenshot-guided gamepad installation
material is being collected by the user; no new screenshots were supplied in
this turn. README's old XInput/default and multi-screen review descriptions were
corrected. Public release still needs the live checks and final setup guide.

The FFXIAH bumper request was verified on page 4: Eyeshark requested bidirectional
bumper targeting while retaining D-pad navigation; HunterHog posted an XInput
Shift+Tab/Tab solution, and Moghedian posted a DirectInput example. No bumper
changes in Preview 24.

---

# Public Preview 23 — display names in binding feedback

Version: `0.4.0-a.20261011.public-preview23`. Cumulative overlay; rollback
restores Preview 22 runtime. Preserve config.ini/data; no AHK changes.
Implementation e076dd3; local only, no push.

1. Stop/unload, apply overlay and load. Bind a safe action in Basic: chat suffix
   should say Basic, matching the chooser. Clear the disposable binding and check
   the same display name. Repeat in a named test set if convenient.
2. Reload and verify the binding's stored set/key remains unchanged. The chat
   display is the only runtime change; all Preview 22 checks remain relevant.

Offline: feedback and actual custom-action binding regression checks pass; changed
Lua syntax/whitespace checks pass. Display-name lookup covers Basic, All Jobs
Default, a custom name and missing metadata. Live feedback confirmation pending.

Branch comparison performed against personal experiment/l1-companion-batch19 at
a7c59f9 (0.4.0-a.20261010.19-companion2), without modifying that repository. Both
have Apps transport/silent interception, readable XML slots, inline custom editing
and fallback/linked metadata, scale/fade work and trigger page navigation. Their
ui_fade.lua files are identical. Public has newer golden cursor/review, measured
caption retries, coherent movement, Options anchor/lifecycle, endpoint text
visibility, icon workflow repairs and hotbar read/write safeguards. Personal
retains the removable L1 addon, PS/touchpad/L3/R3/shoulder extras, shared
data/CustomActions.xml migration/write-conflict checks, FFXI panel skin/sounds,
lock/unlock drag tooling and extra menu/alias/grace controls. Public catalogs
remain character-specific. Selected integration is recommended; no port/merge
performed as part of this feedback-only change.

---

# Public Preview 22 — chooser lifecycle and temporary crossbar reveal

Version: `0.4.0-a.20261011.public-preview22`. Cumulative overlay; rollback
restores Preview 21 runtime. Preserve config.ini/data; no AHK/controller changes.
Implementation: 90cb7dd. Two local commits including documentation/package; no push.

Live Preview 21: the user confirms endpoint text visibility removes the fade
flicker and provides responsive trigger-release feedback. New report: blank or
abandoned New Set entry can leave the chooser stuck; ui.lua:1069 indexes nil
while lingering on that entry. Source confirms the non-existent Add New Set row
was used as player.active_environment; MP/TP checks indexed its missing hotbar.

1. Stop/unload, apply overlay and load. Status: Preview 22, Ready=true.
2. In auto visibility with no trigger held, hold Options: crossbar and set list
   appear, and Change crossbar sets caption disappears. Release Options on a
   real set: chooser/tooltip close and visibility returns to auto. Repeat from
   hidden mode; settings remain unchanged. Restore your preferred mode afterward.
3. Select Add New Set while holding Options, then release. Name entry stays open
   and the last real crossbar remains active/visible. Wait through MP/TP updates;
   no 1069 error. Blank entry then D-pad to a real set closes it and clears capture.
4. Repeat after typing a partial name: Escape closes without creating a set;
   Options press also closes, and its release must not reopen name entry. Another
   Options hold should work normally. Navigating while Options remains held keeps
   ordinary choosing open until release.
5. Enter a valid disposable set name and confirm with keyboard Enter. Set creation
   still works and closes entry. Existing sets and bindings are preserved.
6. Open a default set: tooltip follows its anchored list and disappears when the
   list closes. Share menu open/close must not resurrect a closed tooltip.
7. Check the Options image stays present while its caption is suppressed. The
   caption returns when chooser closes only if ordinary crossbar hints are shown.
8. Recheck ordinary bindings, new fade text behavior, custom actions and ijkl:
   `//xb dpad ijkl`; return with `//xb dpad arrows`.

Offline: 24 regression groups pass, including actual Options edge handling,
placeholder selection without changing live hotbar, draft cancellation, absent
/sparse vitals tables, caption visibility and temporary hidden-mode reveal.
Changed runtime syntax/whitespace checks pass. Live lifecycle behavior is pending.

Tooltip opinion: useful fallback information, but the current long block and
advice against playing from default sets need a future copy review. No tooltip
wording changes here. Other controller support remains deferred. Cursor bars
still need a close screenshot; tiny first-frame caption centering hop remains.

---

# Public Preview 21 — text endpoints and Options-anchored chooser

Version: `0.4.0-a.20261011.public-preview21`. Cumulative overlay; rollback
restores Preview 20 runtime files. Preserve config.ini and data; no AHK changes.

Preview 20 live: captions briefly begin off-center then immediately center; whole
crossbar moves together; text still flickers during fades; cursor is stronger but
has reported corrupt-looking bars; name label is white; Execute Command icons
work. The first-frame text-position hop remains, pending further refinement.

Changes: 9d50212 (text endpoints), f4ec134 (Options anchor/tooltip), df07696
(two-line help). Text visibility now switches at fade endpoints, avoiding partly
faded glyphs. It is hidden at close start even while opacity is still 1; recast
show requests cannot reveal it during the transition. Images fade continuously.

1. Stop/unload, apply overlay, load. Status: Preview 21, Ready=true.
2. Test initial fade, then trigger-only fade in/out. All crossbar text should
   disappear when close starts and return only when full fade-in completes.
   Reverse a fade mid-way; text stays hidden until the bar reaches full opacity.
3. Disable fades briefly: ordinary immediate text visibility still works. Reenable.
4. Open set chooser. Its lower-left corner aligns to the Options image's lower-left
   corner, unless constrained by screen edges/list height. It grows upward in
   15-pixel rows. On a default set, the 400x218 tooltip aligns along the chooser's
   bottom, to its right when it fits or left otherwise, clamped to the screen.
5. Drag or use Move Crossbar with D-pad. Reopen chooser and change scale: list and
   tooltip stay anchored. Check 960x540 and a larger resolution.
6. New Custom Action: first help line unchanged. Second line is exactly:
   Or use: //xb ca name <name of action> | //xb ca alias <label for action> | //xb ca command <console command to fire>
   It stays on one centered line, fitting the available panel width as needed.
7. Check normal bindings, custom review navigation, cursor animation and icon
   workflows remain intact. A close screenshot of cursor bars is still needed
   to distinguish baked texture artifacts from rendering artifacts. No further
   cursor artwork changes in this package.

Offline: all 23 regression groups pass; changed runtime Lua syntax and whitespace
checks pass. Coverage includes fade reversal/endpoints and repeated show requests,
Options screen anchor, tooltip side selection/clamping and retained movement.
Four small local commits including documentation/delivery; no push/public posting.

---

# Public Preview 20 — layout, movement, fades and icon workflows

Version: `0.4.0-a.20261011.public-preview20`. Cumulative overlay for the base
qEagleStrikerp installation; rollback restores Preview 19 runtime files. Preserve
config.ini and data. No AHK changes; no bulk images/sounds.

Implementation commits: 08f931f (stable redraws), 8cd08bd (movement/tooltip),
04d8f9c (cursor opacity), 556c9db (deferred captions/review), a6b677b (icon flow).
All local; no GitHub push or public posting.

Live evidence: Lionstag 960x540; image(7).png confirmation starts near screen center;
image(8).png initial prompt similarly displaced; image(9).png Share/Options hints
separated from the crossbar; image(10).png review help displaced, cursor/highlight
absent; image(20261011-220842).png shows native cursor visibility. Width-unavailable
at initial placement remains an inference from these images, not a captured native
measurement. Rechecking on render directly handles that condition. Offline Preview
19 tests assumed immediate measurements and did not catch the live failure.

1. Stop/unload, apply the overlay and load. Status: Preview 20, Ready=true.
2. At 960x540, Use Item: choose an item, check centered combo prompt and captured
   confirmation. Repeat with Trade Item, a custom action, Superwarp and Remove
   a Binding. Check both long/short captions at a larger resolution too.
3. Open New Custom Action from the menu: Custom Action Name label is white while
   other unnamed fields remain pink. Enter a name; review buttons have the golden
   background and animated cursor. Three help lines stay centered within the panel.
4. Check cursor visibility against the native cursor reference; animation timing
   and selected-text yellow are unchanged. Inline typing hides the selector as
   before; confirm/cancel and Save & Bind -> Circle preserve the committed draft.
5. Drag the crossbar: slots, text, Share/Options images/captions stay together.
   Use Move Crossbar with the D-pad too. Open the set chooser on a default set
   with its explanatory tooltip, drag the bar and check list/background/highlight/
   tooltip all follow it. Repeat after closing/reopening and reloading.
6. Check initial fade and trigger-only fade in/out, including compact mode. Text
   should fade steadily. Redraw churn was fixed; whether this resolves the live
   flicker still needs confirmation. Report which labels flicker if it persists.
7. Change Slot Icon: choose icon first, capture a bound combo and confirm. Its
   command/alias remain unchanged. Circle from combo returns to icons. Selecting
   an empty/fallback-only slot warns and permits another selection, without saving.
8. Change Action Icon: select a binding then icon. Check a matching slot without
   its own icon on another set; explicit slot icons stay unchanged.
9. Execute Command is after Remove a Binding, immediately before Credits. Icon
   images should now appear. Existing name-based commands remain compatible.
10. Ordinary actions, trigger priority, bare menu controls, F7/F8 and reload
    persistence remain working. Keep native hat-switch menu input disabled.

Offline: 22 regression groups pass, including delayed native-width simulation,
all shared binding captions at six resolutions, unchanged glyph setter suppression,
whole-bar/tooltip movement, new/saved review paths, icon-first slot confirmation,
legacy Execute Command image paths and fresh selector setup order. Changed runtime
Lua syntax and whitespace checks pass. Live graphics confirmation is pending.

The personal L1 companion remains outside this public preview. Broken extracted
item icons are a separate outstanding issue; this package repairs Execute Command
icon paths, not the item icon extractor.

---

# Public Preview 19 — binding caption centering

Version: `0.4.0-a.20261011.public-preview19`. Cumulative overlay; rollback
restores Preview 18 runtime. Preserve config.ini/data; no AHK changes.

Preview 18 live: selecting an icon for a new custom action returns directly to
review (first test passed). User reports Use Item binding text offset right at
960x540. Review found the confirmation caption still used character-count width;
the initial combo prompt already used measured width. Both now use that method.

1. Stop/unload, apply overlay and load. Status should report Preview 19, Ready=true.
2. Use Item: choose an item, check centered initial prompt, capture a combo and
   check centered confirmation. Circle backs out without changing bindings.
3. Check Trade Item, Superwarp, Custom Action, Remove a Binding, Change Icon and
   Set Icon Across Jobs. Both prompts should share the panel's horizontal center.
4. Controller hints stay in their corners. Ordinary binding/execution behavior
   is unchanged; confirm one safe echo/custom action and verify it executes once.

Offline: actual shared prompt/confirmation methods pass for every action type at
960x540, 1280x720, 1600x900, 1920x1080, 2560x1440 and 3840x2160 using nonuniform
glyph widths. Existing review-layout and custom-review checks also pass; changed
Lua syntax and whitespace checks pass. Live centering remains pending.

Discussion backlog, not included here: white Custom Action Name label before
naming; much more opaque cursor; rename Change Slot Icon/Change Action Icon;
icon-first slot-icon workflow; move Execute Command after Remove a Binding before
Credits; investigate blank Execute Command icons. Selected text stays as in
Preview 18 per the user's latest preference. No push/public posting.

---

# Public Preview 18 — custom review and menu polish

Version: `0.4.0-a.20261011.public-preview18`. Cumulative overlay; rollback
restores Preview 17 runtime files. No AHK changes; preserve config.ini and data.

Live Preview 17 on Lionstag: Ready=true, Setup=false (state nil); face buttons
work. User reports the low-resolution menu, cursor, selection colors and page
turning look good. Requested brighter yellow, increased cursor opacity and review
navigation refinements are included here. The existing icon-selection code already
intended to return to review; the exact reported route to binding was not reproduced.
An explicit return destination now protects the custom picker from category changes.

1. Stop/unload, copy the overlay and load again. Verify Preview 18 and Ready=true.
2. Check the brighter selected text and cursor at 960x540; Create Custom Action
   comes first. Empty-catalog actions stay present but disabled.
3. Create a named draft from the menu. Choose Icon: Clear Icon is first, folders
   still navigate normally; choosing an icon returns directly to review. Reopen
   the picker and clear it, then cancel out of a folder/root and verify the draft.
4. Link Action: Skip (no linked metadata) comes first. Select a real action and
   return to review; reopen and skip to remove metadata. Clear buttons are absent
   from review, which now has seven choices. Check both a new and saved action.
5. Check centered two-line help and button-combo captions for Change Icon and
   Set Icon Across Jobs. Confirm hints still match saved controller assignments.
6. Save & Bind, then Circle: draft remains. Exit: draft is discarded. Canceling
   inline typing discards only unconfirmed text; already committed fields remain.
7. Bind a command linked to a spell/ability and verify command execution, icon,
   MP/TP cost and recast presentation. Recheck ordinary bindings and F7/F8.

Offline: all 17 regression groups and changed-file syntax pass; coverage includes
icon choice/clear/back independent of category, draft return and text bounds at
six resolutions. Live refinements remain pending. Two implementation commits plus
one delivery/documentation commit, local only.

---

# Public Preview 17 — no-subjob initialization

Version: `0.4.0-a.20261011.public-preview17`. Cumulative base overlay; rollback
restores Preview 16 runtime files. Fix commit: `8bdb398`. No AHK changes.
Keep existing data and config.ini; the package excludes those and bulk images.

Lionstag finished the face-button wizard in Preview 16, then reported player.lua
165 concatenating nil sub_job, followed by skillchains.lua 345 indexing a missing
buff table. The new load message aborted initialize before ready=true and before
skillchains.load. Unlike the status message, existing storage already supported
NOSUB. This repairs that regression and guards early buff-removal packets.

1. Stop/unload using `//xb controller stop` then `//lua u xivcrossbar`, copy the
   overlay and `//lua l xivcrossbar`. Preserve the saved setup assignments.
2. Run `//xb status`: Preview 17, Ready=true, Setup=false. Check the console for
   errors; report exact lines if initialization still fails.
3. Bare Triangle opens the native menu, Square selects the active window, Cross
   confirms and Circle cancels. D-pad moves only addon selection with its menu
   open; outside it, D-pad follows arrows/ijkl. Native hat switches stay disabled.
4. Test trigger-held slot actions, ordinary keyboard F7/F8 and reload persistence.
5. When controls pass, turn `//xb inputtrace off`. No need to rerun setup unless
   assignments themselves differ from the intended buttons.

Offline: 17 regression groups pass; root/player/storage syntax passes. The actual
skillchain packet handler is tested separately because untouched upstream syntax
elsewhere in that module is Windower-specific. Live readiness/input confirmation
is pending. No GitHub push or public posting.

---

# Public Preview 16 — setup readiness gate

Version: `0.4.0-a.20261011.public-preview16`. Cumulative overlay; rollback
restores Preview 15. Only xivcrossbar.lua changed at runtime. Stop wrapper,
unload, copy xivcrossbar and load again. Existing settings/bindings are retained.

Lionstag_2026.10.11.log raw lines 739-750 and 757-762 show Apps DIK221, R2
DIK88 and Cross DIK63 arriving in setup state 3. R2/Cross have capture=true,
ready=false, blocked=false. The router's unconditional readiness gate therefore
discarded both before the wizard. This update permits setup input while not
ready; outside setup the original readiness protection remains.

1. At first Confirm assignment, hold R2 and tap Cross. The prompt should now
   advance to Cancel. Assign Circle, Triangle (Main Menu), Square (Active Window).
2. On Save Changes, confirm with R2+Cross, then complete the final confirmation.
   Let the addon reload and run `//xb status`: Ready should be true, Setup false.
   If Ready remains false, send status and the console error output so the
   initialization failure can be investigated separately.
3. Recheck bare menu buttons, ordinary bindings and F7/F8 keyboard behavior.
4. Turn `//xb inputtrace off` once the result has been recorded.

Offline: all 16 regression groups pass, including setup input while ready=false
and refusing gameplay input in that same state; changed-file syntax passes.
Observed cause of dropped setup events is established; why full initialization
remained incomplete still requires evidence. Live completion remains unverified.
Local fix commit `9bdb0bb`; packaging/docs follow. No push or public post.

# Public Preview 15 — raw setup input diagnostics

Version: `0.4.0-a.20261011.public-preview15`. Cumulative overlay; rollback
restores Preview 14. Over Preview 14, only xivcrossbar.lua changed at runtime.
Stop/unload before copying, then load again; retain settings and character data.

Evidence: AHK log records Apps and R2/F12 + Cross/F5 edges with clean releases.
A temporary Windower #f5 echo executed from controller. User restored silent
#f5 binding. Existing inputtrace was silent; it logged after capture/readiness
checks, so absence did not identify which check failed.

1. During button assignment, run `//xb status` and `//xb inputtrace on`.
   Report Ready/Setup/Capture status and the trace enabling message.
2. Close chat/console, release all buttons, focus FFXI, hold R2 and tap Cross;
   release. Send all RAW and BLOCKED lines from this attempt. Raw trace includes
   physical typing too while setup is open, so missing controller lines can be
   compared with keyboard lines.
3. Run `//xb inputtrace off` afterwards. No binding replacement needed.

Offline controller/setup regressions and changed-file syntax pass. Tests verify
raw messages precede capture=false, ready=false and blocked=true filtering.
No AHK or controller-routing behavior changes. Cause remains unconfirmed.
Local diagnostic commit `7a26e74`; packaging/docs follow. No push or public post.

# Public Preview 14 — setup hover feedback

Version: `0.4.0-a.20261011.public-preview14`. Cumulative overlay; rollback
restores Preview 13. Stop wrapper, unload, copy xivcrossbar and reload. Bulk
images/sounds, settings and character data are excluded; keep existing files.

1. Welcome: hover the click prompt. Text lifts 2 px up/left with a faint white
   alpha glow. Leave the text: position restores and glow disappears. Clicking
   anywhere inside the welcome background panel still advances to controller
   choices and starts the wrapper.
2. Controller choices: hover each image; image and name lift 2 px up/left.
   Move away: restore. Hitboxes remain fixed, including at image boundaries.
3. Check normal keyboard typing during setup still works. Controller signaling
   is unchanged: continue Preview 13's inputtrace/log investigation below.

Offline setup regression checks cover repeat hover without accumulating shifts,
restoration, fixed click regions, prompt-only glow and hiding during navigation.
Changed-file syntax and whitespace pass. Live appearance still needs review.
Local hover commit `009b273`; package/docs checkpoint follows. No push or post.

# Public Preview 13 — setup keyboard correction

Version: `0.4.0-a.20261011.public-preview13`. Cumulative overlay; rollback
restores Preview 12. Stop wrapper, unload, copy xivcrossbar and load again.
No character data, settings, bulk images or sounds are shipped.

Preview 12 layout passed live on Lionstag. Button assignment still failed;
inputtrace reported nothing. Physical typing failed during setup (Space was
reported to pass). The early setup dispatcher added in Preview 12 consumed
unrelated physical keys; this update passes them through.

1. With setup open, type `//xb inputtrace on` normally, then close the chat input.
   Ordinary typing/console Insert should work; controller setup still owns its
   face buttons and triggers.
2. Release all controller buttons, return focus to FFXI, then hold R2 and tap
   Cross. Record trace output or its absence. The missed confirmation cause
   remains unknown; do not treat this update as a confirmed controller fix.
3. Inspect `addons/xivcrossbar/data/input-transport.log` immediately after that
   attempt. Send the last startup block and subsequent lines. This establishes
   whether the wrapper emitted Apps capture, R2/F12 and Cross/F5 edges.
4. Turn `//xb inputtrace off` after the check. Existing layout/ordinary binding
   checks remain in the previous preview sections below.

Offline: setup keyboard pass-through and controller transport tests pass;
changed-file syntax and whitespace pass. No AHK changes in this update.
Local commit `e1d7630` corrects keyboard ownership; packaging/docs follow.
No push or public post.

# Public Preview 12 — first-run controller setup

Version: `0.4.0-a.20261011.public-preview12`. Cumulative overlay for the base
qEagleStrikerp installation or any previous public preview. Rollback restores
Preview 11. Stop the wrapper, unload, copy xivcrossbar including assets/menu,
and reload. Existing settings, images, sounds and character bindings are retained.

Reported on Lionstag at 960x540: setup did not accept R2+Cross; controller layout
heading overlapped images and the background looked incorrectly scaled. Code
inspection found setup already independent of crossbar scaling, but old insets
made the inner background height negative. ~~Ordinary trigger activation returned before forwarding R2 to the setup wizard.~~
Correction: that explanation was a misread; the original code did forward R2.
Cioara successfully completed fresh setup. Lionstag still cannot confirm on
Preview 12, and inputtrace showed no events with the wrapper running.

1. First-run setup (or `//xb remap` with existing configuration): welcome text
   and controller choices fit inside a centered panel. Select PlayStation by
   mouse; hitboxes should coincide with images. Heading/subtitle stay separate.
2. Hold R2 and press/release Cross: advance from Confirm to Cancel. Then assign
   Circle for Cancel, Triangle for Main Menu, Square for Active Window. Each
   press advances once; a bare face press without a trigger does not assign.
3. On Save Changes, use R2+Cross to save. Complete the last confirmation and
   verify reload, normal menu navigation, trigger bindings and absence of leaks.
4. After setup, `//xb scale 0.6` still affects the crossbar independently. Reopen
   remap only if desired: its fixed-size layout remains readable.
5. Resume Preview 11 XML/set persistence and Preview 10 UI checks below.

Offline: 16 regression groups and changed-file syntax pass. New tests exercise
actual setup input dispatch with actual wizard methods, positive panel dimensions,
heading/image separation and mouse hitboxes at 960x540, 1280x720, 1920x1080 and
3840x2160. Windows/FFXI first-run completion still requires live verification.
Local commits: `3cc952e` setup routing; `e84937a` panel layout and regression.
No push or public post.

# Public Preview 11 — XML failure protection and chat feedback

Version: `0.4.0-a.20261011.public-preview11`.
Cumulative overlay: includes Preview 10 UI changes; rollback restores Preview 10.
Stop the wrapper and unload before copying the ZIP's xivcrossbar folder. Keep
existing images, sounds, settings and character data; include assets/menu.

Reported Preview 9 results: test 1 passed; test 2 passed with requested picker
refinements; tests 3 and 4 passed. R2+Circle binding feedback showed a strange
glyph before Basic. Creating a new set failed at player.lua:204 (`contents` nil).
Controller disappeared from game utilities; exact surface/cause not yet known.

1. Before retrying, preserve copies of the current hotbar XML files. Send the
   exact entered set name and affected XML/log to identify the parse failure.
   This update reports the file and XML parser error and refuses hotbar writes
   after failed loading. It does not repair an already damaged file.
2. Bind an echo to R2+Circle: one echo, unchanged targeting, readable chat ending
   `R2 + Circle - Basic.` (or the selected set's name).
3. Create a uniquely named set such as `Preview Eleven` through the menu;
   confirm chat feedback, bind an echo, then reload and verify persistence.
   A file-specific XML error means stop this test and retain the XML for review.
4. Invalid names such as `Slash/Name` or `Question?` should be rejected while
   existing sets and bindings remain available. Renaming has the same validation.
5. Continue Preview 10's name-first entry, cursor, selection lift and trigger
   paging checks below. These visual changes have not been confirmed live yet.

Offline: all 15 regression groups pass; changed-file syntax and whitespace pass.
New tests exercise the actual loader's nil/wrong-root cases and both storage
write guards, including automatic default-file creation. Windows controller
availability and the original XML failure's cause remain unverified.
Local commits: `9b61a25` load/write protection and set validation; `302451e`
ASCII chat feedback. Documentation/package checkpoint follows. No push or post.

# Public Preview 10 — name-first creation and menu navigation

Version: `0.4.0-a.20261011.public-preview10`.
Maintenance initially interrupted Preview 9 testing. Follow-up: tests 1-4
passed, subject to the recorded picker design changes. Set creation later failed
at player.lua:204. Preview 10 UI changes remain awaiting live verification.

Install the cumulative overlay after stopping the wrapper and unloading. Copy
all of xivcrossbar, including the small **assets/menu** folder. Bulk images,
sounds, config.ini and character data are excluded. Rollback restores Preview 9.

1. Bare `//xb ca` and menu Create Custom Action immediately open Custom Action
   Name entry; no option buttons above it. Other fields are inactive. Empty name
   and duplicate name confirmation stay in entry. A unique name unlocks the
   review. Enter or controller Confirm commits; Circle cancels to the command's
   exit or the menu page, respectively. Typing must not open native menus/chat.
2. `//xb ca Bow` still opens a named review directly; existing exact names edit.
   Alias/Command defaults remain green in parentheses and blank in XML. Recheck
   Save Only, Save & Bind, Circle return, name-only alias execution and reload.
3. Navigate with D-pad and mouse: selected icon, frame and label lift 2 px up
   and left; the previous option restores. Golden cursor follows selection,
   glints at 12 fps and disappears with the menu. Check its brightness/placement
   and the warm brown/gold selection at 960×540 and a larger resolution.
4. Icon picker: top-level Goring Blade sample is absent; weaponskill icons in
   their own folders remain. Directory/PNG selection and Circle back work.
5. A multi-page list: L2 highlights Previous, R2 highlights Next. No turn until
   release; one turn per gesture. Face/D-pad input while held consumes the turn.
   Both trigger orders select their respective directions and commit once.
   Rounded dark-blue buttons show L2/R2 icons; active buttons become brown/gold.
   Option selection stays in place or moves to the nearest valid last-page entry.
6. Ordinary binding combos still work, including trigger+Circle. Trigger input
   while binding must capture the combo rather than turn a page. Bare Circle,
   Cross, Share, Options and physical F7/F8 retain the tested behavior.
7. Continue unfinished Preview 9 checks below: typing isolation, new set flow,
   Superwarp, dragging/visibility, fade text and persistence across reloads.

Offline: 14 regression groups pass, plus changed-file Lua syntax and whitespace.
Cursor lifecycle is exercised against the actual playback helper; selector
position restoration and name-gated drawing have regression coverage. Windows
FFXI rendering/input still require the checks above. No public posting yet.

# Public Preview 9 — release candidate testing, October 11, 2026

Version: `0.4.0-a.20261011.public-preview9`. Cumulative update overlay for a
qEagleStrikerp base install. Keep your existing images, sounds, settings and
character data. Copy only the ZIP's `xivcrossbar` contents over that installation;
do not copy the rollback folder. Stop the old wrapper and unload before copying.
Restart with controls released. No personal L1 companion is included.

**First checks, in order:**

1. `//xb status`: Preview 9, PS5 DirectInput / apps; input diagnostics off.
   Native movement/camera work; disable native D-pad/face/trigger assignments
   and hat-switch menu input as in the tested setup. Bare Triangle opens the
   game menu, Square focuses selection, Cross confirms, Circle cancels.
2. `//xb ca`: Save options are dim and skipped until Custom Action Name is
   supplied. Explore Choose Icon before naming: folders open without errors;
   Circle returns. Enter a name and repeat Choose Icon, pick an icon, return.
3. Edit Name/Alias/Command inline; type spaces, punctuation, both Shifts and
   `input /echo Preview nine`. No inventory, action menu or native chat opens.
   Enter commits; Circle cancels; Escape exits. Then type normally in the game
   and open/close the console with Insert. Check this before longer testing.
   If typing becomes blocked after leaving an editor, unload the addon; if
   necessary run `//keyboard_blockinput 0` from Windower's console.
4. Save & Bind a real echo; Circle from binding restores the review, Share
   exits. Reopen by exact name. Save blank-command Bow and verify alias/name
   fallback. Reload and confirm both actions and bindings persist.
5. Menu Create New Set: type a disposable name, Enter; one creation message,
   back to main menu, no alias/icon/bind steps. Switch to the set explicitly.
   Repeat the name: reject without losing its existing bindings. Test the
   Options chooser's Add New Set text entry too, including spaces/punctuation.
6. Superwarp main icon is Home Point. Bind a known unlocked destination anew;
   verify its crystal icon and actual warp. Existing old bindings are preserved.
   Also confirm Execute Command's icon and no picker errors in other lists.
7. `//xb scale 0.6`, `hide`, `show`, `auto`, `autohide off`: actions continue
   working in each mode. Check full and compact fades for caption flicker.
   Explicit show should redraw without needing a reload.
8. Drag with a menu open. Open Move Crossbars while hidden: bar becomes visible,
   D-pad and drag both move it; Circle leaves and restores prior visibility.
   Position persists after reload. Menu choices still respond to mouse clicks.
9. First row is Custom Action/Create/Edit/Delete; four columns maximum, more
   spacing, Remove Binding immediately before Credits. Check 960×540,
   1280×720, 1600×900, 1920×1080, 2560×1440 and 3840×2160 as available.
10. Regression: L2/R2 and both trigger orders, face and D-pad actions each fire
    once; no target change/native macro popup; physical F7/F8 and Ctrl binds
    retain their normal functions. Test client switching and wrapper stop/start.
    Binding/clearing messages appear once in chat with the correct combo/set.

**Recorded live baseline:** Preview 8 Insert behavior improved; ordinary
Apps-trigger actions, navigation, Bow fallback, IJKL, dragging, scaling and reload
persistence passed. Preview 8 had typing leakage, icon-picker crashes, unnamed
save failures, menu Create New Set misrouting and text fade flicker. These are
fixed in code here and remain live-test targets, not claimed live passes.

**Offline validation:** 13 Lua regression groups, changed-runtime syntax and
patch whitespace checks. Review anchors checked at six resolutions. Tests use
Lua 5.4 with Windower stubs; no Windows/FFXI/AHK execution here. A whole-repo
parse encounters unchanged Windower string-method syntax in skillchains.lua;
that dependency is not rewritten by this update.

**Deferred:** Help/status wording review together, Display/Controls menu,
caret/paste editing, general item-icon extraction repair, other controller
wrappers/XInput, visual polishing and the personal companion. No new Display
menu or personal-control features are introduced.

**Rollback:** stop wrapper, unload, copy `rollback/xivcrossbar` back over the
addon. It restores the runtime files changed since Preview 8; extra unused new
modules may remain. Your data/assets stay untouched. Keep a separate backup of
your own data before testing set creation/deletion.

# Public Preview 8 — first live-test corrections, October 11, 2026

Version: `0.4.0-a.20261011.public-preview8`. Cumulative BASE update only.
Stop the old AHK process and unload before overlaying; restart with all buttons
released. This version installs AHK's keyboard hook so physical Apps/Ctrl checks
can distinguish injected presses. Quiet modifier edges are logged to
`data/input-transport.log`. Windows behavior remains to be verified.

1. Test Insert before and after one bare Cross press/release, with console open
   and closed. Also check a trigger/slot press, focus away/back, and ordinary
   typing. If Insert fails, preserve the transport log; do not assume fixed.
2. Open the chooser and hover Add New Set: no ui.lua:758 error should recur.
   Create a disposable set normally; retain the duplicate-protection check.
3. Binding screen: bottom-right Confirm is dim before a combo is captured;
   Back dims while triggers are held. Both become normal at confirmation.
   Bare Circle returns, trigger+Circle remains bindable, Share exits.
4. Main options stay at most four per row, centered with uniform spacing.
   Create Custom Action and Remove Binding exchange positions; other order stays.
5. No Allow stpc diagnostic. Default now true; explicit retained false settings
   need manual change to AllowSTPCForSelfTargetedActions=true, then reload.

Live Preview 7 report: all tested L2/R2/combined-trigger face and D-pad slots
execute without native input leakage; echo binding and name-only Bow work;
right/left Shift, punctuation, Save & Bind return and IJKL targeting work.
Unresolved: native gameplay/chat typing leakage in inline fields; Insert after
Cross (hook correction awaits test); welcome text flicker; review-screen clarity;
text editing has only append/backspace, not arrow-key caret navigation.

Offline checks cover chooser placeholders and sparse sets plus the prior nine
regression groups. AHK's hook behavior cannot be verified in this Linux runtime.
Runtime checkpoint before wrapper correction: 7de59f6.

# Public Preview 7 — direct-action Go Back correction, October 11, 2026

Version: `0.4.0-a.20261011.public-preview7`. Same cumulative BASE installation
rules as Preview 6. Native menus and addon D-pad/Confirm/Back/Exit passed live
in Preview 6. Switch Target -> binding -> Circle hit a missing selection-state
error at action_binder.lua:1303; this update restores the original main-menu page
for direct binding entries (Switch Target, View Map, Last Synth, Remove Binding).
Offline regression covers all four entries. Retest those paths with bare Circle.

Insert became usable after stopping AHK. This is recorded as an unresolved
transport interaction, not established as a stuck Apps modifier. Wrapper code
is unchanged. Restart with all controls released, then test Insert before any
controller press and after a simple press/release. Do not hold controller keys
while opening the console. If it recurs, preserve data/input-transport.log.

# Public Preview 6 — optional gameplay D-pad letters, October 10, 2026

Version: `0.4.0-a.20261011.public-preview6` (UTC stamp).
Same cumulative BASE update installation rules as Preview 5 below.

## Short first play-through

Start with diagnostics off (`//xb inputtest off`, `//xb inputtrace off`).
Use Preview 6 already supplied; the extra smoke checks changed no runtime code.

- Open `//xb ca "Bow"`, edit one field using right Shift, cancel that edit with
  Circle, then Save & Bind. Circle back once to verify the review survives.
- Execute one known bound action with a trigger: one action, stable target,
  no native macro pop-up. Confirm bare Cross/Circle still behave normally.
- Try `//xb dpad ijkl` with your native keyboard assignments. Browse the addon
  menu, execute a D-pad slot, then restore `//xb dpad arrows`.
- Drag the crossbar somewhere pleasant, reload, and keep playing. The position,
  action and D-pad choice should survive. Report the first surprise as it happens.

Deeper multi-client and resolution checks below can wait for the next session.
Additional offline checks exercise real review drawing calls at all six sizes,
inline rectangles, long-value truncation, unsaved draft isolation, and actual
D-pad command persistence/release/invalid-input handling. These check geometry
and behavior, not rendered font widths or the game's response.

## Detailed checks

1. Default `//xb dpad arrows`: bare D-pad sends regular arrow keys.
2. `//xb dpad ijkl`: Up=I, Left=J, Down=K, Right=L. Test your chosen native
   keyboard assignments. The addon changes output, not FFXI's configuration.
3. Verify addon menu navigation and trigger-held slot actions remain unchanged
   in letter mode, without native letter-key leakage from those contexts.
4. Switch mode while holding a direction: old gameplay output must release;
   release and press again for the new mode. Check focus loss also releases it.
5. Bare `//xb dpad` toggles; reload preserves the mode. Restore arrows when done.
   Letter mode can type letters into native chat; check that tradeoff explicitly.

Offline checks cover all four letter mappings, ordinary face-button output,
logical menu/slot routing, and release ownership across a mode change. Eight
regression checks and changed runtime syntax pass. Windows live tests pending.
Implementation checkpoint: 53b780b. Help text remains reserved for joint review.

# Public Preview 5 — three focused fixes, October 10, 2026

Version: `0.4.0-a.20261011.public-preview5` (UTC build stamp).
Same cumulative BASE update and installation rules as Preview 4 below.
Help text is deliberately unchanged pending review together.

1. Create a disposable set, bind one action, then try creating the same name
   again using different capitalization. The command must reject it and preserve
   bindings through reload. Also check reserved names and ordinary new creation.
2. In a custom action, set Command to spaces only. Bind and execute: it should
   use Alias, then Catalog Name if Alias is also spaces only. Catalog XML keeps
   the entered values; executable slot fallback agrees with the review.
3. Edit an inline field using right Shift for capitals and punctuation. Hold
   both Shift keys, release either, and verify the other still works. Verify
   ordinary unshifted typing after releasing both.

Eight offline checks pass, including actual set creation preserving existing
bindings, real slot binding whitespace fallback and both Shift press/release
orders. Changed runtime files pass syntax checks. In-game checks remain pending.
Local checkpoints: b0236f1 (sets), a19ea51 (fallback), b1c692f (Shift).

# Public Preview 4 — single-screen custom actions, October 11, 2026

Version: `0.4.0-a.20261011.public-preview4`. Cumulative BASE experiment update;
use the installation and rollback instructions below. This is not a personal
Batch 19 overlay. No settings, profiles, images, sounds or companion included.
Existing base assets are required. Catalogs remain per character.

## Live checks for this preview

1. Open `//xb ca "Bow"`. Check Catalog Name, green `(Bow)` Alias and Command,
   and optional `(none)` fields. Save Only. Verify no command is filled into
   CustomActions.xml. Bind it from Custom Actions and execute a known Bow alias.
2. Open the same exact name: it should edit that record. Test the old
   `//xb ca new <name>` and `//xb ca a/n/c <value>` forms.
3. Edit fields inline: spaces, uppercase letters, punctuation and a semicolon
   command chain. Enter commits; Circle cancels; clearing Alias/Command restores
   green defaults. Check no typing reaches native chat or triggers gameplay.
4. Save & Bind, then Circle back to review. Verify the saved draft survives.
   Bind a slot and check exactly one execution with no native input leakage.
   Trigger+Circle must remain bindable; bare Circle goes back.
5. Choose an optional icon or linked action, cancel or accept, and return to
   review. Clear each. Reject blank catalog names and duplicate renames.
6. Open Create Custom Action from the menu: Circle returns to the main menu;
   command-opened review exits. Confirm unrelated set/icon workflows still work.
7. Inspect at 960x540, 1280x720, 1600x900, 1920x1080, 2560x1440 and 3840x2160.
   All nine review choices, values, inline field and hints should fit. Confirm
   ordinary lists restore their normal layout after leaving review.
8. Reload and verify records and bound slots survive. Repeat on another client
   with its own catalog. Retest targeting, scaling, dragging and visibility.

Offline checks pass: real review transitions, command compatibility, effective
fallbacks, duplicate-name validation, and the actual XML serializer leaving
blank defaults absent. Existing transport, bounds, visibility, presentation and
mouse checks also pass. Lua syntax checked through Lua 5.4; Windows/Windower Lua
5.1, controller input and visual appearance still require the live checks above.

# Public Preview 3 — directly draggable crossbar, October 10, 2026

Version: `0.4.0-a.20261011.public-preview3`. Same BASE-experiment installation
rules as Preview 2 below. This cumulative update needs existing assets and is
not an overlay for personal Batch 19. No settings, profiles, images or sounds.

Left-click and drag the visible crossbar, then release to save. No lock/unlock.
Test at scales 1 and 0.6, in compact and full layouts: all slots, labels, recasts,
trigger backgrounds and indicators move together. Reload must preserve exactly
the new position. Verify normal clicks outside the bar still reach the game.
Hidden bars and bars under the addon menu/chooser must not capture mouse input.
Changing visibility during a drag finishes and saves that gesture.

The existing offset calculation added saved values twice; this preview applies
them once. Old nonzero positions may consequently move once on first install;
drag to your preferred position and reload to verify it stays there.
Local mouse-gesture checks pass; actual Windows dragging remains untested.
Source checkpoint for scaling/fades: d80d453; documentation: e31f12c.

# Public Preview 2 — crossbar scaling and fades, October 10, 2026

Version: `0.4.0-a.20261011.public-preview2` (UTC build stamp).
This UPDATE ZIP is for the upstream-based Apps experiment, **not the personal
Batch 19 install**. Preserve the whole existing folder before applying it.
No images, sounds, data, character profiles, config.ini or personal companion are
included. Existing base assets are required. Stop the wrapper, unload every
client, overlay the included xivcrossbar folder on that BASE installation, then
load again. Do not overlay this on our personal branch: its catalog/editor
behavior differs. Keep the two installations separate.

Commands: `//xb ui scale 0.6` (range 0.25-2), `//xb ui fade [on|off]`
(bare toggles), and the existing visibility commands below. Settings persist.
Defaults: scale 1; fades enabled; FadeIn 0.24 seconds, FadeOut 1 second,
LoadFadeIn 3 seconds. Animation values are editable in data/settings.xml.
Menu scaling, page animation, FFXI skin and sounds are not part of this port.

## Live checks for this preview

1. Confirm version using `//xb inputstatus`. Use `//xb inputtest off` and
   `//xb inputtrace off` if retained experimental settings enable them.
2. At scale 1, compare the base layout; then try 0.6, 0.8 and restore 1.
   Check labels, costs, recasts, controller hints and trigger backgrounds stay
   aligned in both full and compact layouts. Check three/four/six bars as used.
3. Test Lionstag at 960x540 and Franklet at 1280x720; larger screens when handy.
   Scaling the bar must leave the binder unchanged. Reload preserves the scale.
4. `//xb autohide on`: hold/release triggers to reveal/hide the bar. Release and
   quickly press again while fading: opacity should reverse smoothly.
5. `//xb ui hide`: slot actions still execute, but no icons or combat indicators
   appear. `//xb ui show` restores the bar. Test changing sets while hidden.
6. Toggle fades off/on. Off should immediately show/hide; on restores smooth
   transitions. Initial load uses the longer welcome fade.
7. Repeat target-preservation, ordinary menu navigation, physical F7/F8, reload
   and two-client checks from the earlier routing record.

Local checks cover actual geometry surfaces/primitives, time-based reversal,
complete hiding, disabled fades, routing and six menu bounds. Available parser
is Lua 5.4; Windower and Windows AHK execution still require your live checks.
Rollback: stop wrapper/unload, restore the backed-up base folder, and reload.

# Public coherent update — development checkpoint, October 10, 2026

Branch: `public/coherent-update`. This is work in progress, not a delivered ZIP.
Upstream master was checked through GitHub on October 10 and still resolves to
`15d8381dfad0f9efdb84fe2d24655afc150faec4`, matching our existing runtime snapshot.
Starting local checkpoint: `0865014`. No personal companion or personal controls
are imported. No commits have been pushed and no PR has been opened.

The first implementation adds `ControllerModifier` (`apps`, default, or `ctrl`).
Lua capture, silent bindings and wrapper startup use the same selected modifier.
This is **not** an exact reproduction of the upstream wrapper: it retains our
context routing and edge ownership. Ctrl mode intentionally reserves Ctrl+F1-F12
and may bring up native macros; Apps is recommended.

Changing transport requires stopping the shared wrapper, unloading every client,
editing ControllerModifier consistently in their settings, and loading again.
The first client starts the shared wrapper; existing processes do not hot-reload.
There is deliberately no runtime toggle that could split Lua/wrapper state.
Neither mode restores personal bindings overwritten on its reserved combinations.

Local routing checks pass for both markers. Windows/AHK startup arguments, Ctrl
mode, and transitions require live tests before this is presented as supported.
Menu positioning now uses one centered panel independently of crossbar offsets;
logical bounds are checked at 960x540, 1280x720, 1600x900, 1920x1080, 2560x1440,
and 3840x2160. Selectors have positive page capacity and at most four columns.
This is not yet independent menu scaling or proof every detailed screen fits.
Live check: opening the first menu should align backdrop/title/options at each
resolution, including with nonzero crossbar Style offsets. Check deeper dialogs.
Visibility commands now persist: `//xb ui hide`, `show`, `auto`, and
`//xb autohide [on|off]` (bare toggles). Hidden mode does not disable actions.
~~This initial port has immediate transitions, not our personal branch fades.~~
Preview 2 adds the existing elapsed-time fades and coherent crossbar scaling.
Live checks: hiding keeps slot actions working; auto shows only while triggers
are held; show restores the bar; reload/set changes respect the selected mode.
Still pending: independent menu scaling, navigation, editor fixes,
clean user README and packaging. Earlier test records follow unchanged.

## October 9 live checkpoint and shutdown diagnosis
All eight slots and tested trigger combinations passed silent interception; addon menu isolation, bare Cancel, and native keyboard F7/F8 passed. Bare Triangle should become main menu and Square active-window focus in the next test.
Shutdown cause found: v1 label-style OnExit handler ended with return, cancelling normal termination. Changed it to ExitApp after release cleanup; live validation still pending. This correction is not included in the already delivered Test3 ZIP.

# Apps + F1-F12 Test 3 — silent native interception

Overlay the included xivcrossbar.lua onto the Test 2 base experiment. Reload the addon in each client (//lua r xivcrossbar). No AHK or profile changes; preserve current bindings and settings.
Real output: //xb inputtest off. Trace: //xb inputtrace off.
On load this build reserves Apps+F1-F12 using Windower bind commands targeting xivcrossbar inputconsume. Installation announcements may appear once per load; button presses produce no interception echo. Unload unbinds these twelve combinations. Existing personal bindings on these combinations are replaced, not restored automatically; record and restore them manually if desired. Plain F-keys and Ctrl/Alt binds are untouched.

Live evidence: Apps+F7 test echo prevented self-targeting while both the real slot echo and ordinary Cancel/menu Back still worked. Lua's blocked-flag handling is deliberately unchanged; test other keys before altering it.

First test: target someone else; hold R2 and tap Circle in Input Test. Expect one slot echo, unchanged target, no interception message. Then bare Circle cancels. Next repeat all eight slot buttons and trigger states while checking native targeting/menu leakage. With both menus open, only addon selection should move. Plain keyboard F-keys without Apps retain native behavior.

Wrapper shutdown, held-focus cleanup and 540p layout remain deferred. Rollback: restore Test 2 xivcrossbar.lua and reload; restore any desired personal Apps binds afterward.

---
# Apps + F1-F12 Test 2 — 2026-10-09

Build: 0.4.0-a.20261009.base-apps-fkeys-test2. Real output ON; trace OFF.
Transport commit: 3dde617. Shutdown and held-focus cleanup remain unresolved and deferred.

## Install into the existing BASE experiment
Exit the old ffxi_directinput.ahk through Task Manager if necessary before replacing files. Unload xivcrossbar in both clients. This ZIP contains only the changed runtime files and the two snapshot profiles; overlay its xivcrossbar folder onto the existing BASE-APPS-UNCOMMON-TEST1 installation. It is not a patch for the personal Apps-L1 build.
Back up the current data/hotbar/Fenrir/Franklet and Lionstag folders first: supplied XMLs replace those profiles with the October 8 17:55 snapshot. No settings.xml is supplied.
Load/reload xivcrossbar, then run //xb inputtest off and //xb inputtrace off IN EACH CLIENT: existing settings override defaults.
Keep native HAT Switches DISABLED, native sticks enabled, DirectInput enabled.

## Binding provenance
Franklet BST-WHM and BST-DEFAULT, Lionstag RDM mappings, and all other supplied character XMLs come from xivcrossbar_10-8-2026-1755-return-testing.zip. These are the latest available copies here, not a claim about changes made afterward.
Original actions and bars are preserved. A separate Input Test set was added to Franklet BST-WHM and Lionstag RDM-NOSUB. All 32 slots execute real input /echo commands identifying character, bar, and slot. Use the existing set chooser (hold Options, D-pad Up/Down, release Options) to select Input Test. Lionstag must be RDM/NOSUB for that set; other jobs use their original snapshot bars.

## Live tests, one at a time
1. With no addon menu or trigger, D-pad moves the game menu; Cross confirms and Circle cancels.
2. Select Input Test. Hold L2 and press each direction/face: exactly one labeled echo per press. Repeat with R2, L2 then R2, and R2 then L2. Check target and native menu cursor for leakage.
3. Use the original Basic set for real BST/pet commands as desired; watch target preservation, especially Circle/F7.
4. With both addon and game menus open, D-pad moves only the addon selection; Cross confirms, Circle backs out.
5. Keyboard F1-F12 WITHOUT Apps retains native behavior. Do not retain the manual #f7 test bind during the Lua-only leakage check; restore your personal bind afterward if desired.
6. Toggle //xb inputtrace on only if diagnosing failures. //xb inputtest on restores dummy mode.

Prior live results: HAT disabled blocks native D-pad but keeps sticks/camera. Uncommon transport routed all trigger states and menu directions; held repeats did not duplicate actions. Held focus switch needed one clearing press. Mail/MediaSelect launched Windows applications; Kanji and MyComputer lacked useful DIKs; BrowserSearch opened Start. These candidates are replaced entirely by F1-F12 in this test.

Rollback: exit the wrapper, unload addon, restore Test1 runtime files and backed-up profiles, reload. Restore native HAT only if returning to native D-pad routing.

---
## Previous test record

# Base Apps + uncommon signals — Test 1, October 9, 2026

## What this package is

An isolated PS5 DirectInput experiment based on qEagleStrikerp/xivcrossbar master
commit `15d8381dfad0f9efdb84fe2d24655afc150faec4` (August 1, 2026).
Runtime source and assets were verified against upstream blob hashes. The local
baseline is a runtime snapshot, not a clone of upstream Git ancestry; editable
PSD source artwork and README screenshots are omitted from the installation.
Branch: `experiment/apps-uncommon-signals`. See CHECKPOINTS.txt for local commits.
No commits have been pushed. Existing personal development remains separate.

Version: `0.4.0-a.20261009.base-apps-test1`.
This includes the base UI and features, not the personal Batch 17/18 visual,
custom-action editor, shared-catalog, L1 bar, PS, or touchpad modifications.

## Changes and defaults

- Apps replaces Ctrl capture. No global unbind of F1–F12 or Ctrl shortcuts.
- Every digital input below sends the same signal in every context.
- Lua chooses ordinary gameplay, crossbar, setup, binder, text, or set chooser.
- Press ownership persists until release; repeated downs are suppressed.
- Entering a trigger/menu context releases generated held gameplay keys.
- Dummy gameplay and slot commands ON; trace ON. Existing XML is not needed.
- PS5 mapping: Cross confirms, Circle cancels, Square opens native main menu,
  Triangle changes active window. DirectInput wrapper only; XInput and other
  supplied upstream scripts are not remapped and must not be launched here.
- One persistent AHK v1 script; loading another client does not replace it.
- Stop: `//xb controller stop` or Ctrl+Alt+F12. Start: `//xb controller start`.
  The stop command affects this new script, not an already-running old wrapper.
- No timed automatic shutdown. Explicit stop is provided.

## Candidate signal table

None of these twelve has been confirmed by this new live test. The DIK column
is the expected DirectInput code, not an observed result. AHK explicitly requests
both a virtual key and scan code. UNMAPPED results must be investigated.

| Controller | Candidate | AHK output | Expected DIK |
|---|---|---|---|
| D-pad Up | Kana | vk15sc070 | 112 |
| D-pad Right | Convert | vk1Csc079 | 121 |
| D-pad Down | Nonconvert | vk1Dsc07B | 123 |
| D-pad Left | Kanji | vk19sc094 | 148 |
| Cross | Yen | vkDCsc07D | 125 |
| Square | Mail | vkB4sc16C | 236 |
| Circle | Media Select | vkB5sc16D | 237 |
| Triangle | My Computer | vkB6sc16B | 235 |
| Share/Create | Browser Favorites | vkABsc166 | 230 |
| Options | Browser Search | vkAAsc165 | 229 |
| L2 | Browser Back | vkA6sc16A | 234 |
| R2 | Browser Forward | vkA7sc169 | 233 |

Apps (DIK 221) is held while any of these inputs is held. No F-key slot or trigger
markers are emitted. Japanese input mode or Windows application/browser effects
are possible; the user explicitly chose these candidates for testing.

## Install without mixing builds

1. On Franklet and Lionstag, unload XIVCrossbar. Their reported older
   `0.4.0-a.20261008.17-Apps-L1` build does not have controller stop. Exit its AHK
   wrapper through its tray icon or the identified process. Also exit the old
   HIGH-FKEY-PROBE script and unload fkeyprobe if still loaded. Keep clients open.
2. Move the current `addons/xivcrossbar` folder into a backup location outside
   `addons`. Preserve the whole folder, especially data and controller settings.
3. Put this package's new `xivcrossbar` folder into `addons`. This is a fresh
   install, NOT an overlay. Do not copy personal data/settings into this test.
   It supplies config.ini; resources and blank profiles generate on first load.
4. Clear native gamepad assignments for D-pad and the twelve buttons above.
   Keep analog movement/camera. This test does not translate L1/R1/L3/R3/PS/Mute
   or touchpad. Retain any native personal assignment you wish for those buttons.
5. Load only the test client first: `//lua l xivcrossbar`.
   Run `//xb inputstatus`; confirm the test version and InputTest=true.
6. FFXI must be focused. Release all twelve buttons before testing; focus changes
   require neutral input before the script rearms. Run plugin and AHK v1 required.

## Live tests — first signal identity, then routing

1. Tap each of the twelve buttons individually. Expect one named DOWN and UP
   with the DIK above. Face/D-pad presses outside menus also print a gameplay
   dummy message. Share opens the original binder; close it with Share before
   continuing single-button checks. Options shows the chooser while held.
2. Any UNMAPPED/DIK=0 or unexpected Windows effect: note the physical button and
   stop that part of the test. Send chat log plus data/input-transport.log.
   Do not assume a missing signal is successful because AHK logged it.
3. Hold L2 and tap each direction/face: expect eight dummy slot messages on bar 1.
   Hold R2: bar 2. Hold both: bar 3 with the default three-bar configuration.
   Four/six-bar trigger order and double-taps remain the upstream implementation.
4. Open the binder with Share; RELEASE Share and both triggers. Directions should
   navigate it without a trigger. Cross confirms and Circle cancels according to
   the base UI. No gameplay or crossbar action messages should occur alongside
   menu input. This is real menu navigation; avoid saving bindings during routing
   checks unless deliberately testing the binder. No new menu design is included.
5. Hold Options and test Up/Down to change sets. Other slot buttons are consumed
   without firing actions, including while a trigger is also held.
6. Hold a face button while opening/closing a menu or changing triggers. No new
   action should fire merely because the context changed. Release and press again
   to act in the new context. Check focus switches require release before rearming.
7. Press physical keyboard F1–F12, including F7 while holding R2: they should keep
   their ordinary behavior and not execute dummy slots. Ctrl macro behavior should
   remain available on the physical keyboard; Apps controller input should not
   open native Ctrl macro palettes.
8. Stop with `//xb controller stop`, verify digital translation ceases; start with
   `//xb controller start`. Check Ctrl+Alt+F12 as the script-only emergency stop.
9. After signal identity and dummy routing pass, `//xb inputtest off` enables real
   gameplay key translation and existing bound slot execution. Re-enable with
   `//xb inputtest on`. A bare command toggles. `//xb inputtrace off|on` controls
   logging. This package has blank crossbars unless you deliberately bind actions.

The dummy mode reports held edges but does not exercise real native arrow repeat.
Real key holds, release on focus loss, multi-client behavior, Windows effects,
and AHK execution require live testing. Do not label those passed from local tests.

## Rollback

Stop this script (Ctrl+Alt+F12 works outside FFXI), unload the test addon, move
its folder aside, restore the complete previous `xivcrossbar` backup, and load it.
Restore native D-pad assignments if returning to the old routing design. No old
bindings/settings were overwritten because installations were kept separate.

## Local validation

Changed Lua files parse in the available Lua 5.4 runtime; no Lua 5.1/Windower
runtime or Windows AHK interpreter is present here. Tests cover twelve unique
logical candidates, held ownership, repeats, dummy key and actual slot execution,
menu routing, chooser exclusion, transitions, capture-loss release, physical F7,
and unmapped logging. Unchanged upstream uses Windower Lua syntax extensions
(e.g. string-literal :format); a blanket standard-Lua parse cannot validate those.

## Prior evidence and materials

- First higher-F probe: F13/F14/F15 received as 100/101/102. F19/F20 received as 0.
- October 9 supplied HIGH-FKEY-PROBE.log records all twelve F13–F24 outputs with
  376 downs and 376 ups. Franklet's supplied chat log includes distinct 100–102,
  repeated zeros, and an annotated L2/R2 test yielding zero. Do not map zeros.
- Franklet/laptop baseline is Batch 17 Apps-L1, not Cioara's complete Batch 18.
- ~~The long log proved automatic shutdown failed.~~ Correction: the user may
  have reset the probe; a timer failure is unconfirmed. This version uses explicit
  stop controls rather than assuming a timed diagnostic session.
- Deferred: configurable mappings, personal addon/L1 palette extraction, keybind
  combinations beyond this fixed layout, //xb move / always-draggable experiment.

Sources: https://github.com/qEagleStrikerp/xivcrossbar/tree/15d8381dfad0f9efdb84fe2d24655afc150faec4
and https://docs.windower.net/commands/keymapping/.


## 2026-11-12: Credits portrait fitting and attribution follow-up

Request: bound avatars to the supplied frames, deduplicate Aliekber as
Programming/Art, remove library wording, verify four avatar identities and review
upstream credits. Credits opt into a 32x32 image size and a 4px frame inset;
ordinary menu icons retain their previous sizing. Aliekber has one row. Added
posimagi for the explicitly attributed upstream Skillchains update. Refreshed
Akirane/Ivaar/BlueSummersC from verified GitHub repository owners (identicons);
Aeliya remains the supplied placeholder because no replacement was verified.
Source URLs and bounded research notes are in images/credit_avatars/SOURCES.md.

Validation: targeted production Credits callback and menu-resource renderer tests
cover all 20 entries, bounded image sizing, assets and cleanup. Static/mocked
checks are not in-game rendering verification. Live check requested: open Credits,
confirm all portraits fit and remain centered, then check ordinary action icons
and the default icon pack's Credits picker. Apply as an overlay and reload the
addon one client at a time; no controller/DLL restart is required. Outstanding
settings-save concurrency and focus-handoff observations remain deferred.

The default icon picker Credits folder uses the same 32px bounded rendering as
the Credits screen, while preserving 64px source portraits for crossbar slots.

Final verification: all 54 local Lua suites passed; 138 Lua sources parsed after
temporary Windower syntax normalization. Final code commit 34c132632d2a0ada049b69f6b710f9b996b66f56
passed GitHub run 43254581718: Lua and Windows x86 native/AHK build, fixtures,
parse/startup/profile/lifecycle smoke checks. Local/published Git trees matched.
The 15-file overlay was byte-checked against the committed sources and contains
README, WORKFLOW, TESTING and portrait provenance. No live FFXI test was performed.


## 2026-11-12: Correct credit menu frame-relative inset

User screenshot confirms bound portraits are correct but both menus are offset.
~~The preceding 32px sizing patch placed portraits at a 4px frame inset.~~
Correction: its -1 offset was relative to the already-inset frame origin, so it
placed portraits 1px above/left. The shared renderer now derives a 4px inset
from the 40px frame and 32px image. The earlier mocked check only asserted size;
the updated test checks X and Y coordinates against the actual adjacent frame.
No local checks or live FFXI checks can be claimed for this follow-up. GitHub
checks and publication status are reported with the delivered commit.

Verification update: GitHub run 43262471284 passed both jobs (54 Lua suites,
Windows native/AHK checks) at d63c16bf4a505542dddea0c3c9c7bdceb20bb2b5.
The runtime delivery is one file, ui/selectablelist.lua; no new portrait assets
are necessary. No local or live FFXI check was performed for this correction.


## 2026-11-12: Settings cleanup final verification

Published code checkpoint 8524858d17059d89d02009db392136042dc844d1 passed
GitHub Actions run 43268730614 (Lua and Windows x86 jobs). Local 58-suite
regression run passed; subsequent count-import validation passed its targeted
schema test and the final full CI suite. 143 Lua sources parsed with temporary
Windower string-method normalization. Controller mapping generation is unchanged
and its --check passes. No AHK, DLL, installed settings or hotbar files changed.
The final documentation commit does not change the tested runtime. Review and
next steps are in docs/SETTINGS-CLEANUP.md; live FFXI acceptance is still pending.
