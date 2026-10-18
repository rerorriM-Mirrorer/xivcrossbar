# DirectLink — Unbound, Snapshot 1

The current development identity is **XIVCrossbar DirectLink — Unbound**.
See [the snapshot record](docs/SNAPSHOT-DIRECTLINK-UNBOUND-1.md) and current README/TESTING.
Preserve `snapshot/directlink-unbound-20261016`; continue on `development/directlink`.
The snapshot preserves the live-tested Personal Test 6. Current development
adds chooser/render diagnostics and the R1 behavior below; see README/TESTING.
The chronological Personal notes below remain historical provenance.

---

# DirectLink real IJKL checkpoint 1

Runtime directlink1-realkeys1; Controls=9.7-realkeys. Restart Lua AND the wrapper.
Default OFF. //xb realkeys on requires profile x, messages on, dpad ijkl and
inputtest off. Return to neutral. Ordinary D-pad Up/Right/Down/Left emits AHK
I/L/K/J while its DirectLink equivalent is masked. Existing triggers, L1/R1
chords, R1 unused-release R, R3 F8/R and native-menu companion hiding remain.
Chat/XIV editors, triggers, other buttons and physical modifiers exclude the
real-key route. Context/chord loss releases owned keys; consumed directions
remain masked until physical release. //xb realkeys off restores Lua output.
Controller status distinguishes configuration, wrapper support and permission;
permission alone does not prove a key fired. This thread does not change Trust.
Source/simulated checks pass; native Windows/FFXI/Trust acceptance is pending.

---

# DirectLink R1 checkpoint 1

Runtime directlink1-r1test1; Controls=9.6-r1-r. Restart Lua AND the shared wrapper.
Bare R1 sends R once on unused release. Any controller chord consumes the hold,
even if the other button releases before R1. Existing R1 arrows/confirm/cancel/
Trust shortcut and L1+R1 Tab remain. Focus/context/lease loss cancels a pending tap;
physical modifiers/R and outstanding generated keys suppress it. R3 keeps its
F8-on-press / R-on-unused-release behavior. No L1 remap or transport change.
Source/simulated checks pass; live Windows/FFXI acceptance is pending.

---

# Historical Personal 9 Test 6 — message-based controller experiment

Runtime personal9-l1test6; Controls=9.5-messages. Restart Lua AND the wrapper.
PS5 Extended defaults to messages; //xb messages off restores Apps/F-keys after
neutral, and on restores messages. Bare toggles; status reports configuration.
//xb controller status reports active route, sent/ack, write failures and version.

The twelve ordinary buttons, including L2/R2 and face/D-pad slots, share one
ordered stream into existing Lua routing. No Apps/F-key signals are emitted in
this mode. Native Lua key translation and personal L1/R1/touch/click/targeting
paths remain. Both trigger orders and double-tap bars are retained; companions
still hide in native menus. No inventory/wardrobe remap is included.

Queued taps are acknowledged; advancing heartbeats distinguish a live writer
from an unchanged file. Focus/lifecycle/timeout changes cancel held input.
Route/client/writer changes require neutral. Source and simulated validation
passes; native responsiveness, Windows file operations and FFXI acceptance are
pending. The prior Test 5 complete installer remains a comparison build.

---

# Historical Personal 9 Test 5 — controls


Runtime personal9-l1test5; Controls=9.4-input. Restart Lua and the shared wrapper.
The user reports controllers feeling good and likes native menus hiding both L1
companions. Preserve that behavior and the current combinations.

R3 F8 on press / R on unused release is the personal default. R2 F8 is off; bare
R1 is unassigned. Existing settings adopt R3-only once, then later choices persist.
Shared defaults off, retaining explicit saved choices. Private //xb x selects
PS5 Extended; //xb r2, //xb r3, //xb both toggle acquisition. Explicit on/off/status
and all long forms remain. Both enables both unless both were already on.

Set changes no longer clear populated captions before replacement; identical
labels reuse native text. This source/simulated fix still needs native visual
acceptance. No timing or broad inventory/wardrobe/Trust remap is installed.
See docs/CONTROLLER-REFERENCE.md for the complete current map and routing.

---

# Historical Personal 9 Test 4 — input routing


Runtime personal9-l1test4; Controls=9.3-input. All Test 3 momentary layers and
Main/compact changes remain. See docs/CONTROLLER-REFERENCE.md for the complete
current controller list and mapping. Wrapper AND Lua restart are required.

The supplied log identifies missing-lease disarming and AHK filter enumeration
leaks. Test 4 masks before deleting filter entries; uncertain lease reads get a
retry/short no-new-downs pause, preserving a valid session without authorizing
actions from stale context. True stale/menu/focus/token changes still cancel.
This is not a claim that every desktop input problem has been solved.

//xb controller target r2 on and r3 on enable independent, default-off F8 trials.
Both off restores prior targeting. R2 emits F8 down/up before Apps+F12; R3 emits
F8 on press, retaining R on unused release. Only fresh unmodified gameplay presses
qualify. R3-first zoom also gets F8, L3-first zoom does not. Native send delay is
retained, so extra sends have a measurable cost to compare live. No direct-AHK
bare-face rewrite or pressure-sensitive trigger mapping is installed.

The separate binding pack preserves Cioara's supplied bar, clears only L2 D-pad
for Franklet/Lionstag, and reconciles the older global catalog against newer
linked slot values. Optional inventory/party actions stay separate.

---

# Historical Personal 9 Test 3 — momentary layers

Runtime personal9-l1test3; Controls=9.2-layers. Read README and TESTING for the
current mapping and pending native acceptance. AHK wrapper restart is required.

| Gesture | Current behavior |
| --- | --- |
| L1 held / released | Shortcut companion visible / hidden; no bare-press toggle |
| L1 then L2 | Saved action bank in the same location; no native modifier latch |
| Release L2, keep L1 | Reveal shortcuts; held slots do not execute on reveal |
| Release L1, keep L2 | Hide and consume L2 until release |
| L2 then L1, or same sampled press | Ordinary L2 crossbar priority |
| R1+R2 | Ordinary R2 crossbar; no Alt latch |
| R1 / L1+R1 / PS | F8 on unused release / Tab / application focus toggle |
| R3 | Existing R on release; ordered click zoom retained; no new F8 |

Existing L1 shortcuts and eight saved bank entries are retained. Main is a
display alias for default Basic; internal basic keys, file scope and fallbacks
are unchanged. Companion 40px PS icon slots use the main compact coordinates and
follow its CrossbarScale by default. Position/lock persist; numeric l1 scale can
opt out, and l1 scale crossbar restores following. Bank execution goes from AHK
events directly to Lua console commands, without extra gameplay keybindings.

Sticky input remains unresolved; no current trace was supplied in this request.
See README for the AHK/Lua route table and ps5/x comparison. Inventory remaps,
R1 action bar, R2 targeting and R3 split-press ideas remain proposals.

The chronological records below describe their own historical deliveries.

---

# Historical Personal 9 Test 2 — compact slots and controller diagnosis

Runtime personal9-l1test2, Controls=9.1-diag. x aliases ps5-extended; ps5extended
remains accepted. The standard ps5 profile uses the same base wrapper without
the personal layer, making it useful for comparison but not an untouched
upstream-script test. The companion is tighter and uses native themed icon slots.
All Test 1 control mappings remain, including the symmetric native Ctrl/Alt pairs.

User confirmed L1-left/echo and mode switching working live, likes the display,
and reports severe remaining stickiness on Frank's computer. No cause established.
Use //xb controller trace on for an optional 30-second raw/routed/output/timing
capture with each profile; status shows timing maxima and lease-miss counts.
Stop the trace before reading its buffered log. No input timing changes made.

## Agreed next design and open choices — not implemented

- Trigger first (L2 then L1) MUST retain the ordinary L2 crossbar. Current native
  modifier pairs still accept both orders; ordered routing is a next-pass change.
- Shoulder first then trigger selects a separate Ctrl/Alt companion; releasing
  the trigger while still holding the shoulder should reveal the shoulder layer
  again. Reveal must not execute a newly exposed held-button action.
- Consider one L1 keyboard reference instead of a mode toggle, plus R1 reference
  with unused bare-release F8, and a separate R1-then-R2 bar upper-right. Whether
  L1/R1 swap Ctrl/Alt schemas is not decided. Native directional menu/list controls
  and Trust's direct D-pad navigation remain important.
- Inventory cluster: unused job-ability/magic shortcuts could become Sack/Wardrobe
  accesses; do not fill every slot just because it exists. Bindings not changed yet.
- R2 combat cluster may add native F8 acquisition before Apps+F12, plus temporary
  magic/ability/item submenus. Timing/retarget rules still experimental; no F8
  pulse or extra delay was added. Apps+F8 remains Triangle, not the R2 signal.
- Basic is the ordinary selected top layer, not a special fallback provider for
  every other set. Main is a candidate display name; no keys/files renamed.
  Shared can be another selectable top layer across jobs but is not a fallback
  provider to other sets. Its display/execution fallback discrepancy is retained
  pending the user's design choice; do not silently make it standalone here.

---

# Historical Personal 9 Test 1 prototype (October 16, 2026)

Runtime personal9-l1test1; wrapper Controls=9.0-l1. The Personal 8 mappings below
remain applicable except **bare L1 release now toggles keyboard/bank mode**, not
client switching, and **L1+directions/face buttons use the editable bank in bank
mode**. Keyboard mode retains the listed Ctrl shortcuts. An L1 combination
consumes the tap in either release order; no double-tap delay is introduced.

The eight-slot bank and mode save per character, separately from trigger-bar
sets. Slots are 1 Left, 2 Down, 3 Right, 4 Up, 5 Square, 6 Cross, 7 Circle,
8 Triangle. New banks are empty. See README and `//xb l1 help` for assignment,
append, clearing, mode, scale, position, lock and preview commands. Canonical
commands use `//xb l1`, not a separate addon or global alias.

The two-diamond reference fades in keyboard mode and remains visible in bank
mode. Normal gameplay buttons still require no L1 and remain unaffected. The
companion has independent scale/position, explicit drag unlock and screen clamps.
L1+R1 Tab and native Ctrl/Alt pairs retain priority. Main bars are not forced
visible. Native/addon menus and cutscenes hide the companion; only a fresh
foreground gameplay context accepts bank events. A held button does not execute
on focus regain, menu closure or reconnect. The wrapper must be restarted.
Keyboard-mode Ctrl menu toggles remain usable inside native menus; chat/text
entry blocks personal gestures. Bank actions and mode taps require gameplay.

The Lua mode is authoritative. AHK keeps native Ctrl-key ownership and publishes
ordered per-client L1 event snapshots, retaining unacknowledged edges. Each
context/session token expires at menu/focus/mode transitions; a render stall over
0.5 seconds also rearms. Snapshots older than one wallclock second are rejected.
AHK waits for the toggle acknowledgment/new token and then physical neutral.
No F13/F14/media transport or global event hook is added. The bridge's 20ms read
interval and native scheduling are not a measured latency guarantee.

All new runtime features are implemented for testing, not user-confirmed live.
Existing sticky/doubling input and cutscene-reveal reports remain unresolved.
The chronological sections below are **historical**, including headings that
formerly called Personal 8 the current version and said no companion existed.

---

# Historical Personal 8 keyboard controls

Runtime: personal8-sets1 (includes Controls1). Wrapper reports personal_version=8.1. PS5 Extended
only; ordinary controller profiles keep the shared Apps transport. The supplied
movement_signal.ahk bridge is retained, with its per-FFXI-client takeover latch.
No L1 companion or double-tap mode is enabled.

| Input | Output |
| --- | --- |
| Bare L1 release | Next FFXI client immediately; no F10, Escape or double-tap delay |
| Bare R1 release | F8 (retained); double taps have no special action |
| L1 + D-pad Up / Down / Left / Right | Ctrl+I / Ctrl+E / Ctrl+J / Ctrl+M, once on D-pad press |
| L1 + Cross / Triangle / Square | Ctrl+Space / Ctrl+S / Ctrl+Q, once on face press |
| L1 + Circle / touchpad / L3 / R3 / PS / Mute | Reserved; no personal output or bare-button fallback |
| L1 + R1 | Tab once when the second shoulder is pressed |
| R1 + D-pad | Corresponding plain arrow held with the D-pad |
| R1 + Triangle / Circle / Cross | Ctrl+Numpad Plus / Escape / Enter, retained |
| L1 + L2 | Hold Ctrl immediately; release after BOTH buttons release |
| R1 + R2 | Hold Alt immediately; release after BOTH buttons release |
| D-pad during either native modifier pair | Corresponding native arrow; no crossbar slot |
| Bare touchpad | Backtick on short release; 500ms peek emits backtick then Escape on release in same client |
| Bare L3 / R3 | H / R on release, retained |
| Ordered R3 then L3 / L3 then R3 | Comma / period held by second click, retained |
| PS press | Focus recent non-FFXI app from FFXI; restore last FFXI client from another app |

Unassigned R1 combinations retain their previous behavior. Combinations consume
L1/R1 singles. New input after focus/disconnect/menu changes requires physical
neutral; held inputs do not acquire new meaning. Native modifier pairs remain in
navigation mode until both members release; overlapping pairs hold both modifiers.
Menus, text and setup cancel native pairs immediately and require neutral before
rearming. Within a pair, face buttons are consumed, avoiding modifier+confirm
accidents. Outside these explicit native pairs, ordinary L2/R2 bindings retain
priority over the personal shortcuts.

The wrapper releases Apps and outstanding F-key signals before native modifiers.
It releases owned arrows before modifiers, without releasing genuine keyboard
keys. Native Ctrl/Alt behavior during these deliberate pairs is intentional.
Old PSHoldAction/DoubleTapMs settings are retained but unused by this mapping.
PS toggles on press, so a hold adds no action. Last-client shutdown and the
installation mutex continue sharing one controller process.

DirectInput POV diagonals retain one adjacent cardinal direction until a cardinal
or neutral is reached. This avoids the former neutral gaps without firing two
crossbar slots from one diagonal. It is a plausible contributor to the user's
sticky-D-pad observation, not a proven diagnosis of that whole session.

Binding conventions for a later L1 bank remain the existing 1 Left, 2 Down,
3 Right, 4 Up, 5 Square, 6 Cross, 7 Circle, 8 Triangle. That bank is deferred.

The historical notes below describe preceding mappings and deliveries.

---

# Current personal controls — verified against the shipped AHK source

These are the `ps5extended` gameplay overrides, unchanged by Personal 7 cleanup.
Menus/text entry and L2/R2 crossbars take priority. Bare L1/R1 no longer hold
Ctrl/Alt continuously. Unlisted combinations retain ordinary button handling
and consume a shoulder's targeting tap.

| Input | Output |
| --- | --- |
| Bare L1 tap | F10 immediately on release |
| Bare R1 tap | F8 immediately on release |
| Double L1 tap | Escape pulse to old client, then previous FFXI client |
| Double R1 tap | Escape pulse to old client, then next FFXI client |
| L1 + Cross | Ctrl + Space once on Cross press |
| L1 + touchpad | Tab immediately on touchpad press |
| L1 + touchpad held 500ms | F15 additionally; the earlier Tab is not retracted |
| R1 + Triangle | Ctrl + Numpad Plus once on Triangle press |
| R1 + Circle | Direct keyboard Escape once on Circle press |
| R1 + Cross | Direct keyboard Enter once on Cross press |
| R1 + D-pad Up/Down | Keyboard arrows; Alt joins if already latched by horizontal input |
| R1 + D-pad Left/Right | Alt + corresponding arrow; Alt stays latched until R1 release |
| Bare touchpad tap | Backtick on release |
| Bare touchpad held 500ms | Backtick once at threshold; Escape on release in the same focused FFXI client |
| Bare L3 / R3 | H / R on release |
| Hold R3, then press L3 | Comma held while the second click (L3) remains held |
| Hold L3, then press R3 | Period held while the second click (R3) remains held |
| PS tap | Next client; restore last client when no FFXI client has focus |
| PS held 500ms | Return to recent non-FFXI app; no extra switch on release |
| Mute | Joy15 identified; no ordinary personal shortcut assigned |

The 250ms shoulder double-tap window does not delay the first F8/F10. The first
tap may target; a recognized second tap sends a 40ms Escape pulse before switching
to a different client. No different client means no Escape/switch. Client order
is retained during the wrapper session; new clients append. PS restores the last
client from another app. `controller.ini` can retain the alternate Personal
PSHoldAction=minimize behavior; focus is the default.

R1+Square has no personal override. Both shoulder clicks must return neutral
after an ordered stick-click pair; simultaneous clicks choose neither order.
L1+analog-stick zoom was removed. No L1/R1 companion crossbars are included.

# Personal 7 shared-text failure review

The user observed Balloon, XIVParty and native console text disappearing while
NPCMirror interacted with a home crystal. Earlier text loss preceded a native
pol.exe/d3d8.dll access violation. The new incident has no matching native fault
record yet. Simultaneous missing text is a symptom, not proof of a common cause.

Reviewed sources, retrieved October 14, 2026:

- Windower/Lua master `addons/libs/texts.lua` and `images.lua`: strong registries
  retain objects until destroy. Hide only changes visibility. This confirms the
  temporary-object retention fixed in XIVCrossbar. The installed library copies
  were not supplied; no shared Windower library is replaced by this package.
- `rerorriM-Mirrorer/Balloon`, `Balloon.lua` and `ui.lua`: three persistent text
  objects (message/name/timer) and six persistent images. Incoming dialogue
  updates these objects; it does not recreate text for each line in this source.
  Portrait/timing work may still affect responsiveness independently. Another
  concurrent Balloon development package may differ from this repository snapshot.
- `rerorriM-Mirrorer/XivParty`, `xivparty.lua`, `uiText.lua`, `uiContainer.lua`:
  text creation has an explicit disposal path, container disposal recurses to
  children, and logout disposes the view. `//xp debug refcount` reports its own
  counts. Full class/disabled-element lifecycle and installed layout were not
  exhaustively tested; this does not rule out another leak or rendering issue.
- ConsoleBGPlus 0.1.19, matching the supplied console load banner, recovered
  from its delivery ZIP: retained labels and cached/reused frame primitives;
  excess pieces are deleted and unload deletes labels/primitives. Its frame
  fade changes its own objects. It sets native console font/color/activity on
  settings application, but does not render or erase the native output buffer.
  `//cbg diagnose` saves `ConsoleBGPlus/data/diagnostics.txt`; native console font
  and text-buffer state lack documented getters in that implementation.
- Native console output is handled by Windower, outside these Lua text objects.
  A font/render-resource failure is plausible when both that output and addon
  text vanish, but a process dump or controlled comparison is needed to locate it.

No Balloon, XIVParty, ConsoleBGPlus or Windower core code is changed here. First
compare the same clean-client scenario with the XIVCrossbar cleanup installed.
Record `//xb resources`, `//xp debug refcount`, and `//cbg diagnose` while healthy
and, if practical, again when text fails; chat output can remain in Logger files
even when it cannot be drawn. Compare manual interaction with NPCMirror later
while holding other variables steady. Avoid repeated addon reloads as a recovery
experiment after a shared text failure; a fresh process gives a useful baseline.

---

# Personal 6 current lifecycle and catalog behavior

- The wrapper may run before login; only confirmed character/server identity permits hotbar writes.
- Global and character custom-action catalogs are both visible. `//xb catalog global|character|status` chooses where new actions save; global defaults. Edits remain source-owned and associated bindings update by identity. Deletion keeps executable snapshots.
- The wrapper mutex still prevents duplicates. Last-client shutdown now honors `on_unload_killahk` after a two-second reload grace. Minimized and pre-login registered clients count; another client unloading does not stop your wrapper.
- `//xb unload` gracefully unloads; `//xb restart` fully reloads; `//xb reload` re-reads hotbars. Settings/data are not included in testing packages.
- Icon organization, personal menu ordering, mute probe, further target choices and L1 companion remain future work. Independent trigger-field fade stays dormant.

The development notes below are historical; their earlier “pending” shutdown statements describe the preceding deliveries.

---

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
