# XIVCrossbar Public — RC3 maintenance and release handoff

Prepared October 15, 2026, America/Chicago. Author: A.

## Start here

Continue public/rc3-maintenance in
https://github.com/rerorriM-Mirrorer/xivcrossbar. Runtime baseline:
0.4.0-a.20261015.public-rc3-cleanup1. Published runtime checkpoint:
93624052f8cb170d47f5747d11d6ad0aeb6665ee; local source counterpart:
dfdd7612cf4bbd07ddb0514cdabf2ed4534817e7. Package TESTING.md records the exact
new documentation/source checkpoint. This complete delivery adds handoffs and
installation guidance, not additional gameplay features.

This is public RC3 + Icons/Credits/Escape + the three approved maintenance ports:
instant compact switching, corrected stroke alpha and bounded drawing resources.
It is NOT the personal line or a patch stack that can be combined with it.
Read docs/BRANCH-MAP.md and root WORKFLOW.md/TESTING.md before changing code.

End goal: a clean, playable, documented Apps-key update for qEagleStrikerp's
XIVCrossbar, offered first to FFXIAH for community testing. The principal benefits
are removing native macro popups, avoiding native/menu double input, retaining
physical F-key/Ctrl shortcuts, better small-window layout/scale/drag/visibility,
and simpler custom actions. Avoid introducing personal controls to justify a
public release. Extra controller readers are experimental, transparently labeled.
No forum post, PR submission or public release announcement has been performed.

## Complete installation — public candidate only

This ZIP is a COMPLETE xivcrossbar folder, with all required images, themes,
setup screenshots, license/NOTICE and the shared AHK v1 wrapper. It is not the
previous Maintenance1 update patch. No old installation is required for its code
or assets. No user data, bindings, catalogs, settings.xml, config.ini, caches or
local controller preferences are distributed.

Stop the active wrapper (`//xb controller stop`) and unload XIVCrossbar on all
clients. Move the existing addon folder aside. Install this entire xivcrossbar/
folder into Windower/addons. For fresh acceptance, leave data/config.ini absent
and let the wizard create them. For an upgrade test, restore a copy of the PUBLIC
backup's data/ and config.ini and any custom images. Keep separate copies from
the new personal line, whose catalog metadata/ownership differs. Do not feed
working personal catalogs through the public implementation merely to compare.

Both variants install under the same name, use the same commands and send the
same Apps signals. Test them one at a time per Windows PC, not as two live addon
folders or two wrappers. Other PCs can independently test the other build.
Unload/stop before switching variants. Lua reload does not replace running AHK.
Rollback means restoring the backed-up public installation with all clients
unloaded and its wrapper stopped; keep newly created binds separately if wanted.

Requires Windower4 and AutoHotkey v1.1.33+ in the v1 series, associated with .ahk.
AHK v2 is intentionally excluded. Native FFXI gamepad configuration must disable
hat switches and duplicate face/D-pad/trigger assignments; keep native movement
and camera sticks. Macro keys can remain assigned to other buttons, not the
L2/R2/face buttons supplied here. images/setup includes both the gamepad guide
and the four-step FFXI IJKL targeting guide. Do not clear stick movement/camera.

## First live checklist

1. Fresh setup: welcome hover/click, reader profile, button artwork, R2+requested
   face button registration and completion screen. Keyboard text entry must not
   remain blocked. Test a no-subjob character too. `//xb status` must say
   public-rc3-cleanup1. `//xb controller status` shows the selected/running reader,
   device, fresh status, connected and ready. No ps5extended choice exists here.
2. Gameplay: bare D-pad, Cross confirm, Circle cancel, Triangle game menu and
   Square active-window focus with the intended PS5 mapping. Then XB menu:
   D-pad moves only XB selection, Cross confirms, Circle backs one step, Share
   fully exits. Native menu beneath must stay still. Physical F7/F8 retain native
   targeting when pressed on the keyboard; triggered slots must not target self.
3. Bind one echo on D-pad and face buttons in L2, R2 and ordered-both bars. For
   optional bars4-6, set Hotbar.Number in test settings then reload. Preserve
   AutoHideExtraBars=true. Check ordered/double-tap selection and held-release.
4. Custom actions: `//xb ca`, valid-name gating, inline space/punctuation/Shift,
   Enter commit without leakage and Circle cancel. Choose/clear icon and linked
   metadata return to review. Name-only Bow falls back to your alias/name. Save
   & Bind, back to draft, Options chooser overlay and selected destination label.
5. `//xb compact`, explicit on/off, scale .6/1/1.5, drag then reload. Toggle while
   in a draft and while chooser is open; preserve position, scale, set and draft.
   Compare text fades in both layouts for the repaired stroke flicker.
6. `//xb resources`: compare the SAME screen before/after repeated edit/save/bind/
   back and set changes. Counts should settle, not grow on every cycle. Reload
   with a menu open; no disposed-object/cursor callback error.
7. Credits at 960x540 and 1280x720: artwork, aligned labels and reachable entries;
   Circle returns to prior main-menu selection; Share exits. Escape from main,
   inline field, review, binder, chooser and chooser text closes all XB layers;
   after release, a new ordinary Escape still cancels native menus normally.
8. Two clients: `//xb restart` on one while the other remains usable, then repeat
   from the other client. Ordinary Lua reload and unloading one client must not
   prevent the other using its running wrapper. Controller stop/start is shared.
9. Fresh install without copied defaults: login intro, oninput/always visibility,
   triggers interrupting intro, hide/show/auto, direct //xb reload versus full
   restart, new set and binding persistence across job changes. Revisit later-
   page spell targeting and login-before-world behavior if considering the next
   personal fixes for porting.

Focus these tests on Franklet1280x720 and Lionstag960x540 first; spot-check
3840x2160 on Frank's PC. The full six-resolution grid remains in simulations.
Do not mark this new maintenance build released merely because earlier RC3
controls passed. Keep short result notes identifying version, character, res,
fresh/upgrade setup and the exact failed step.

## Last live milestone and evidence

User confirmed original RC3 fresh setup/controller routing without bleed-through,
startup fade, //xb restart itself, and Icons1 fitting Dia/Sic/Leave/Heel/Fight.
The new compact feature and corrected stroke were live-confirmed on personal,
but their public ports still need live regression. Credits1 and Escape1 were
implemented with simulations; specific live confirmations across the cases above
were not recovered. Explicit another-client-still-usable during //xb restart
was also not separately confirmed. Do not convert partial reports into passes.

Public maintenance was recovered from the delivered RC3 runtime archive because
the old local snapshot branch/tag were unavailable on GitHub. It is not a fresh
upstream install plus only Ctrl-to-Apps substitutions. Lua and wrapper routing,
menus, storage safeguards, icon extraction, wizard and rendering received fixes.
The personal branch was built from that RC3 line, rather than from the legacy
personal experiments. This provenance matters when transferring code.

Public commits published October15:

| Change | Published commit | Local source |
| --- | --- | --- |
| Recover delivered RC3 public runtime | f70be63c2a16cae3243b4d80f3f38a47c535a7be | ab7af8c |
| Immediate compact command | 5242a8ec49f125fddcc17ca0dae37d59fd0a53be | 03e3d27 |
| Correct text stroke units | 084e72b3b4a921fa7aa756627fee143d635d1663 | c249484 |
| Resource ownership and disposal | 93624052f8cb170d47f5747d11d6ad0aeb6665ee | dfdd761 |

Latest code tests: 108 compact layouts across six resolutions/three scales;
command validation/state preservation; 200 actual menu review/edit/bind/back
cycles, 150 typed updates and100 footer rebuilds against an upstream Windower
List fixture; 30 full crossbar and20 chooser rebuilds; cursor unload and idempotent
deferred destruction.51 Lua files parsed using a Lua5.4 fallback and temporary
Windower string-method normalization. These are simulated/API-mock tests, not
native Windower, Lua5.1 or AHK runtime execution. The original49 public test
groups described in old notes were not in the recovered source archive and were
not claimed rerun. New tests are in Git; omitted from the install folder.

## Current public behavior and defaults

Profiles: ps5 (PS5 DirectInput, tested), f710, fightpadpro, xinput and xinputalt
(R1 chooser) experimental. Commands select a reader; wizard button artwork only
selects labels/face roles. Optional device1-16 DirectInput or1-4 XInput. A PS5
test did not appear in any AHK XInput slot even though FFXI's own checkbox could
be enabled without disrupting the tested DirectInput game setup. These are
independent readers; never infer AHK XInput acceptance from FFXI's checkbox.

Base wrapper sends Apps+F1..F12 in order Up,Right,Down,Left,Cross,Square,Circle,
Triangle,Share,Options,L2,R2. Lua chooses native gameplay keys or addon navigation
or XML slot execution. Silent Apps binds block native F-key leaks. The physical
keyboard row and Ctrl+F-key shortcuts are left alone in Apps mode. A retained
ControllerModifier=ctrl path exists but is untested/unsupported here; wrapper,
Lua and bindings must match, with the wrapper stopped/all clients unloaded when
changing it. Do not imply all old Ctrl keybinding conflicts disappear in Ctrl mode.

Gameplay D-pad defaults arrows; //xb dpad ijkl sends I/J/K/L and requires the
in-game movement-page rebinding shown in the screenshots for desired targeting.
Bare toggles; //xb dpad arrows restores arrows. PS5 tested face roles are Cross
Enter, Circle Escape, Triangle NumpadMinus/game menu and Square NumpadPlus/focus.
The setup can change roles. Addon menus consume face/D-pad; keyboard Enter is
normal outside active text entry, so pressing it there can still be native input.

Fresh defaults: ps5-directinput/device1/Apps, three bars, noncompact, always-visible,
AutoHideExtraBars=true, enable_superwarp_all=false, on_unload_killahk=false,
normal fades enabled .1s in/.5s out/2s startup. Startup fade runs even with regular
fade off; triggers interrupt to normal reveal/immediate full opacity. Public Lua
forces old on_unload_killahk false to protect a shared process. It does not have
the new personal owner registrations/mutex/last-client semantics. Do not promise
last-client shutdown or hidden personal controls in this package.

Useful public commands: //xb help/status/resources; reload(binding data),
restart(graceful full Lua reload); //lua u xivcrossbar unloads; controller status/start/stop/profiles/
profile <name> [device]; dpad [ijkl|arrows]; compact [on|off]; scale <.25..2>;
hide/show/auto; autohide [on|off]; fade [on|off]; remap; inputtrace [on|off].
New custom actions: ca [name], ca new <name> compatibility, ca name/n, alias/a,
command/c. Preserve set/clear/copy/move/icon/alias/set-management legacy commands.
Personal catalog/textfade/autoattack commands are not public ports yet.
A dedicated //xb unload command is also not present in this public handler; use
//lua u xivcrossbar. Adding the standard unload/help behavior is a review candidate.

Custom action review is one screen with inline editing. Name is unique; Alias
is label and may duplicate. Blank alias/command remain blank in XML; fallback
is Alias->Name and Command->Alias->Name. Semicolon chains should be typed inline
because Windower can split chat/console commands despite quotes. Name gating,
default green parentheses, white edited text, unavailable red/dim choices and
explanatory confirmation messages are implemented. A linked spell/ability supplies
icon/recast/cost metadata, not execution. Catalog edits updating existing bound
copies/global+private coordinated catalogs belong to the personal line, not this one.

Options chooser overlays rather than replaces the open menu, preserving a draft
and destination label. Crossbar/hints/tooltip move together; dragging also works
with addon menus open. Menu entries have max four columns and responsive layout;
disabled choices can be visited/explained. Create/Choose/Edit/Delete Custom Action
start the menu, Check follows common attack actions, Remove Binding is near the
end, Credits last; Execute Command is removed from visible main menu but its
legacy bindings/code remain. Change Slot Icon affects a slot; Change Action Icon
changes name-based SharedIcons lookup. Neither should be confused with catalog
link propagation. Item icons decode by item ID into images/extracted_items_v5,
with shared menu/slot resolution and fallback if extraction fails. Superwarp
execution is independent of its icon; the separate Superwarp addon is required.

## Release scope and next decisions

The original reason for sharing was addressing actual FFXIAH requests: Ctrl+F9-
F12/GearSwap conflicts, native macro palettes, D-pad interaction beneath the
overlay, scaling/off-screen menus, hide/show without disabling commands, bumper
targeting possibilities and confusing custom command creation. Frame this as a
tested DirectInput update with experimental other profiles, not universal hardware
support. It is fine to acknowledge AI-assisted coding with human direction/live
testing and traceable code; no claim of an upstream endorsement or accepted PR.

The new personal fixes worth reviewing next, not secretly included here:
1. Shorter target-list page clamp (personal local724bf0f): fixes later-page spell
   -> small target list with blank options. Preserve Back selection/page.
2. Stable in-world server/character gate (local90dd1d7): avoid bogus lobby server
   data and a later identity correction; retain controller login functionality.
3. Default/JobDefault/AllJobsDefault switch destinations by stable key (35716c0):
   user-confirmed reciprocal switching on personal. Include display-name feedback.
4. Save Only edit returning to custom-action list (pending in both lines).

Other possible polish: chat-only modernized help/status, code/comment cleanup,
review startup/transition guards, empty-name/new-set persistence and error paths,
resource-count diagnostics during repeated setup/job changes. Treat public as a
release candidate; do not endlessly add personal features before community tests.
No L1 banks, per-bar visibility, private PS controls, icon relocation, lockout
palette redesign, trigger-field fade or expanded Superwarp folders in this scope.

The native d3d8.dll access violation and cross-addon missing text remain unresolved.
Cleanup fixes demonstrated resource retention; it is not proof of crash resolution.
Menu input stickiness is a newer personal report; investigate there before porting
an unproven timing change to public. Low-resolution spell page bug/gating should
be assessed before claiming final release quality.

Final delivery tasks after acceptance: review concise README/install guide and
the screenshots; verify all required assets/licenses/credits; omit data/config,
logs, probes, test fixtures, source psd/svg leftovers and development baggage from
the eventual general release. These handoffs/testing docs are intentionally in
this testing package. The two complete installers are independently installable,
not dependent overlays. Retain a known-good tag/checkpoint and user rollback path.
Develop/share on the public branch without overwriting the personal installation.

## Historical links and deferred minutiae

FFXIAH thread: https://www.ffxiah.com/forum/topic/55374/xivcrossbar-a-gamepad-macro-addon/
Relevant user-provided post IDs: Ctrl conflicts3779808; menu sizing3778079;
base icons3751386; D-pad underneath3721401; macro popup3633237; hide3633701;
bumper targeting3621915; set deletion/target choices3618108. Earlier authors'
workarounds were valid context; avoid claiming they merely overlooked Apps.
Native gamepad propagation and the keyboard transport had to be addressed together.

Menu L2/R2 button art: Antoine Plu's PlayStation controller icons, Figma community
file968584708653901737; keep existing CC BY4.0 attribution and provenance under
images/assets/menu. Animated golden cursor provenance is retained there too.
Do not assign missing credit icons or remove credited people casually.

Unfinished visual details discussed across the project include a stronger bottom
gradient, first-frame centering hop, background band alignment, contextual hint
brightness during binding, subtle bind confirmation animation, additional quiet
navigation sounds and page button placement. Most rendering issues had subsequent
fixes; only reopen a historical symptom if it still reproduces on this runtime.
Independent menu/footer experiments and icon-path reorganization remain personal.
Full prior discussion was not recovered by history search; current source and
cumulative TESTING are the evidence ledger, not a reconstructed perfect transcript.
