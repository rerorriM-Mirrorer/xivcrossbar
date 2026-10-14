# Personal controls and future work

## Current: Personal 5

`//xb textfade on` uses continuous text/stroke/background opacity with the bar.
`off` restores the current endpoint timing and remains the default. Bare toggles;
`status` reports. The saved setting is Animation.TextFade. Startup uses it too,
without restarting the active fade, changing positions or replacing objects.

`//xb autoattack off` stops and clears the optional estimator. On starts fresh;
bare toggles and status reports. AutoAttackIndicator.Enabled defaults to true
for compatibility, independently of its existing Opacity=0. This affects no game
attack command. The first swing now establishes a baseline; the second supplies
the first interval. Histories reset on disengagement, logout and disabling.
Pause deadlines replace scheduled callbacks, including overlapping/extended
WS/JA pauses. Opacity zero alone permits sampling; Enabled=false bypasses it.
Enabling preserves your saved opacity and colors.

### Work while hidden

| Area | What hiding stops | What can continue |
| --- | --- | --- |
| Crossbar | Recast drawing after its closing fade | Input routing and bound commands, shared action/status handlers |
| Skillchain indicator | Fill/background drawing at Opacity=0 | Bundled tracker and buff state for on-slot chain/burst cues |
| Swing indicator | Drawing at Opacity=0 | Learning unless Enabled=false; that switch bypasses sampling, clock reads and pause work |
| Consumables | Visibility does not own this cache | Action/item events; initial polling unregisters after the first successful cache build |
| Personal wrapper | Visibility does not own this process | Its 10ms hardware poll and PS focus controls |
| Extended context | No visibility-dependent stop | Context-file refresh at most every 250ms while unchanged, so AHK knows which input context is active |

Hidden UI objects still occupy memory and the common geometry transform can
touch their stored drawing state. AA off is a processing gate, not a claim that
the entire addon consumes no CPU. No live CPU benchmark was performed. For
other addons, inspect render/timer/packet registrations and hide/disable handlers
before treating invisible as inactive. Some event-driven caches should stay
current while frame-by-frame drawing or optional estimators can stop. Standalone
Skillchains, EnemyBar2 and GilTracker were not audited during this patch.

### Instance lock and proposed last-client shutdown

The current ffxi_directinput.ahk acquires a named Windows mutex before writing
status or sending keys. Its name contains a hash of the lowercase script
directory. Within one Windows session, the first wrapper holds the handle; a
simultaneous duplicate sees the object already exists and exits. This covers
manual duplicate launches too. Exit closes the handle; Windows also closes it
if the process terminates, so no stale lock file remains. Unrelated AHK scripts
and copies installed in other directories use separate identities.
Reference: [Microsoft CreateMutexW](https://learn.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-createmutexw).

This controls how many wrappers run. It does not count which clients use one.
Last-client shutdown remains pending; on_unload_killahk currently stores the
preference without taking action. Proposed policy:

1. Each loaded XIVCrossbar registers a lease identified by game process/window,
   before login/setup, with its unload preference and a periodic heartbeat.
2. Unloading removes that client's lease. The wrapper stays while any other
   live consumer remains; FFXI windows without the addon do not count.
3. The last departing client's on_unload_killahk=true requests shutdown; false
   keeps the wrapper. A short reload grace lets a replacement lease cancel the
   request, including //xb restart and lua r.
4. Reconcile dead processes/stale leases without trusting old files alone, then
   release owned keys, publish stopped status and exit.

Reuse the existing setting; a synonymous second toggle is unnecessary. Manual
launches must not immediately exit before a client registers. Explicit //xb
controller stop remains an immediate shared stop. Client identity, crash cleanup
and reload grace still need implementation and multi-client live tests. Current
per-character personal context files cannot serve as this registry: they only
serve the extended profile and are created after login.

## Personal 4 controls retained

Completed shoulder taps now target immediately on release. The 250ms window
recognizes a second tap without delaying the first. On a completed double tap,
Escape is sent to the current client before switching: its 40ms pulse finishes and
keys release to the old window before focus moves. A focus/context change or
new controller input cancels the queued switch. With no different client, no
Escape or switch is generated. Combinations consume a still-held shoulder tap.

PS5 Extended remains the fresh default. Older saved base-PS5 profiles migrate
once, including when Windower reloads per-character settings. The
PersonalProfileMigrated marker preserves later explicit controller choices.
Other profiles, device choices and appearance settings are retained. Extended
still uses the DirectInput reader; its profile name is ps5-extended.

R1+Square remains available for a later assignment. The confirmed Mic/Mute
number is **Joy15**, recovered from Max's October 2 JoystickTest result; PS was
Joy13 and the current tested touchpad is Joy14. The proposed gated Mute probe
bank remains separate work. Optional F15 command testing is ready in the probe
README and never starts with XIVCrossbar.

MP-cost defaults match review green, RGB194,253,195 (#C2FDC3); insufficient MP
uses review pink, RGB255,149,151 (#FF9597). Saved normal colors are preserved.
Recast-only dimming retains the normal MP color. Timing-bar ends use inset caps without changing
timers. Stroke Alpha now uses the correct 0–255 API. Texts.Color.Alpha and the
feedback overshoot issue remain separate cleanup items.

### Defaults 1 follow-up

Fresh settings now use ControllerProfile=ps5-extended, GameplayDPad=ijkl,
VisibilityMode=oninput, iscompact=true, enable_superwarp_all=true and
on_unload_killahk=true. Existing XML values are retained. Personal setup's first
profile card selects PS5 Extended so completing setup keeps that default.
The public build's defaults and profile list remain separate. The unload flag
is now preserved, but last-client shutdown behavior is still pending; normal
unload continues leaving the shared wrapper alive.

The public candidate is approved to receive instant //xb compact switching.
This records the requested port; it does not publish or change the frozen public
snapshot yet. No other public default change is implied.

Color reference: [COLOR-SETTINGS.md](COLOR-SETTINGS.md). Defaults 1 made no palette
or wiring changes; Personal 3 changes MP green and fixes Stroke.Alpha below.
Texts.Color.Alpha remains unused.
Feedback.Speed also has a legacy overshoot edge case when subtracting past zero.

Probe follow-up: Mute is now recovered as Joy15. Design a temporary Mute-held bank,
with visible HELD/RELEASED feedback and
candidate keys emitted only while held and FFXI focused. The gated bank is not
implemented here. It must be isolated from the normal controller wrapper and
cleanup must release candidate keys before the Apps modifier.

Enable `//xb controller profile ps5extended` on each participating client.
Ordinary `ps5` keeps the base controller mapping. Use Apps capture. The public
snapshot's files were recovered without changes; new work stays on the personal
branch. Small updates apply over Personal 2 Complete, which supplies the images
and the full runtime base.

| Controller input | Current personal output |
| --- | --- |
| Bare L1 release | Immediate F10, unless another button consumed the held shoulder |
| Bare R1 release | Immediate F8, unless another button consumed the held shoulder |
| Double L1 tap | First tap F10; second tap Escape, then previous FFXI client |
| Double R1 tap | First tap F8; second tap Escape, then next FFXI client |
| R1 + Triangle | Ctrl + Numpad Plus, once on Triangle press |
| R1 + Circle | Direct Escape, once on Circle press |
| R1 + Cross | Direct Enter, once on Cross press |
| R1 + D-pad Up/Down | Bare arrows initially; Alt+arrow after horizontal input has latched Alt |
| R1 + D-pad Left/Right | Alt + Left/Right; Alt latch remains until R1 releases |
| L1 + Cross | Ctrl + Space, once on Cross press |
| Bare touchpad short tap | Backtick on touchpad release |
| Bare touchpad 500ms hold | Backtick once; Escape once on release in the same focused FFXI client |
| L1 + touchpad short tap | Tab once on touchpad down |
| L1 + touchpad 500ms hold | F15 once after the initial Tab; no release Tab |
| Bare L3 / R3 | H / R on release |
| Hold R3, then press L3 | Comma held until L3 releases; no H/R |
| Hold L3, then press R3 | Period held until R3 releases; no H/R |
| PS tap | Existing stable next-client order; restore last client when none is focused |
| PS 500ms hold | Return to recent non-FFXI app; no extra tap on release |

No held bare Ctrl/Alt is emitted by the shoulders. Ctrl belongs to the explicit
Cross/Triangle shortcuts; Alt belongs to the R1 arrows. L2/R2 bindings and addon
menus retain priority. Bare Circle/Cross still pass through XIVCrossbar's normal
Lua handling; R1's direct Escape/Enter are keyboard-style input for testing Trust.
No Trust-specific integration is added. A combination consumes its shoulder's tap
and pending double tap; opening a menu or changing focus cancels pending outputs.

Single shoulder taps no longer wait. The **250ms** window recognizes a second tap.
Shoulder taps/doubles operate while FFXI is focused; PS retains its ability to
restore focus from another app. Unlisted shoulder combinations retain the base
button behavior and consume that shoulder's targeting tap. If an inventory
arrow overlaps a direct shortcut, that arrow must be released before reuse.
The second tap starts within that interval and must itself be released within
250ms of its press. If it becomes a combination or a long hold, the double tap
is canceled. Alt stays latched through other R1 combinations. Direct
Enter/Escape/Ctrl shortcuts temporarily suspend it through their key-up, then
restore it while R1 remains held in gameplay; this preserves their original
output. Menus, triggers and focus changes retain priority over personal input.
Releasing all relevant buttons rearms after focus/disconnect.
For stick-click combinations, keep the first click held while pressing the
second; simultaneous samples establish no order and produce no guessed chord.
The second click owns the held comma/period even if the first is released;
both must return neutral before another pair. Bare H/R happen on release.
Analog camera inputs are untouched;
L1+stick zoom has been removed.

The PS button and shoulder double taps share the same list. Initial order is
reverse current Windows stacking order, then kept stable while the wrapper runs.
New clients append to it and closed clients are removed. It is not alphabetical
or guaranteed login order. Previous/next wrap around that list; with one client
they return to that same window. A wrapper restart rebuilds the list.

Local `data/personal-controller.ini` preferences (never supplied in the ZIP):

```ini
[Personal]
PSHoldAction=focus
DoubleTapMs=250
```

Valid DoubleTapMs: 100–600. Existing files default to 250 if that key is missing;
the previous RightStickAxis entry is now unused. Stop/start the wrapper after
editing. PSHoldAction=minimize retains the older individual-window minimize loop.

`//xb compact` toggles immediately; `//xb compact on` / `off` explicitly select
and save. `//xb ui compact` is equivalent. Layout changes preserve position,
scale, bindings, selected set, menu draft, chooser and fade/recast state. Compact
hides the Share/Options artwork as before; their controller functions still work.

An optional probe lives at `tools/keyprobe/README.md`. It never starts with the
addon. F13–F15 are our previously established signals. Higher F-keys need a
retest; international/browser candidates are listed there with their limitations.

### Still later

Dedicated L1/R1 crossbars, combined shoulder bars, mode switching, personal menu
changes, catalog-edit propagation, target-choice refinement, companion modules,
last-client shutdown, icons/colors and additional addon visibility shortcuts.
Those remain separate from this input/compact test.

## Personal 1 record (superseded mapping follows)

The public snapshot is `public/rc3-snapshot`, tagged
`public-rc3-snapshot-20261013` at `0259ad1`. Its runtime is RC3 plus Icons 1,
Credits 1 and Escape 1. Icon alignment, startup, setup/controls and restart
itself have live passes; Credits, Escape and explicit two-client restart
confirmation were still pending when the snapshot was preserved.

New branch: `personal/ps5extended`, starting from that snapshot. The older
personal branch remains untouched and serves as a reference. Personal features
are implemented here; broadly useful fixes can be ported individually after
testing. No new personal behavior belongs in the frozen public snapshot.

## Personal 1

Enable with `//xb controller profile ps5extended` on each participating client.
The command saves the profile and uses the existing automatic wrapper switch.
Disable with `//xb controller profile ps5`. The hidden profile is absent from
the setup wizard, public profile list and public README. Use Apps capture.

| Controller input | Output |
| --- | --- |
| PS tap | Cycle FFXI clients in a stable order; restore the last client if another app is focused |
| PS hold, 500ms while FFXI is focused | Activate the most recently observed non-FFXI app; no extra tap on release |
| Touchpad alone | F8 |
| L1 + touchpad tap | Backtick on touchpad release |
| L1 + touchpad hold, 500ms | Shift + backtick once; no release tap |
| Bare L3 | H |
| Bare R3 | R |
| L1 | Ctrl |
| L1 + right stick up/down | Period/comma; repeat while held |
| R1 | Alt |
| R1 + D-pad | Alt + corresponding arrow key |
| L1 + Cross | Ctrl + Space |

Touchpad combos temporarily release controller-owned Ctrl so the output is the
requested backtick/Shift-backtick. Personal gameplay combos defer to addon menus,
text entry and L2/R2 crossbars. Keys claimed by a combo stay suppressed until
physical release; changing focus or revealing a menu does not fire a held action.
Genuine keyboard modifiers remain keyboard-owned.

`personal_controls.ahk` owns hardware combinations, tap/hold timing, Windows
switching and personal key releases. `personal_controls.lua` publishes a short
per-character context lease under `data/personal-controls/`. Root Lua only hooks
that context into existing input/lifecycle events. The wrapper remains one
process; this is not the later L1 companion.

Local preferences are created at `data/personal-controller.ini`:

```ini
[Personal]
PSHoldAction=focus
RightStickAxis=R
```

`PSHoldAction=minimize` retains the older minimize-all loop, whose individual
WinMinimize calls explain the observed stair-step. The new default uses focus
switching instead. Right-stick axis R is an initial PS5 assumption requiring live
confirmation; `//xb controller status` reports its current value. U/V/Z are
accepted alternatives. Stop/restart the wrapper after editing this file.
Native camera input remains assigned in FFXI, so the zoom experiment may also
tilt the camera. A centered axis must be observed before zoom arms; other
personal controls do not depend on axis calibration.

The personal wrapper acquires an installation-scoped Windows mutex before
registering exit/status ownership. A duplicate launch exits quietly, and exit
closes the handle. This strengthens concurrent startup handling in this branch;
it does not kill unrelated AHK scripts. Optional last-client shutdown is deferred.

## Later personal priorities

- Catalog edits update bound copies; catalog deletion continues leaving existing
  bindings usable. Deletion already avoids removing copied slot bindings.
- Immediate `//xb compact` toggle without reload, preserving drafts and bindings.
- Personal menu: remove unused options, reorganize entries, then try temporary
  controller crossbars for menu selection. Keep the footer off.
- Target choice: offer valid `<t>` choices consistently and make them first.
  Current choices derive from Windower spell/ability/item target flags and a few
  corrections for status-removal/Haste and Pianissimo songs. The picker maps
  those flags to `<me>`, `<stpt>`, `<stal>`, `<stpc>`, `<stnpc>`, `<t>`, `<st>` and
  `<bt>`; it currently gates `<t>` on NPC/Enemy flags rather than all valid targets.
- Stronger/personal menu gradient and further FFXI palette/layout adjustments.
- Icon catalog folders, paths, defaults and personal exclusions/additions.
- Separate L1 companion and additional personal combinations; no companion here.
- Optional shutdown of the shared wrapper when the final client unloads.
- A credit avatar, chosen together; other README-only contributors could get
  entries/avatars later. Existing Credits entries are preserved in this batch.
