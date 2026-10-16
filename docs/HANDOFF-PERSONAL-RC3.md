# Current continuation — Personal 9 L1 Test 2 (October 16, 2026)

personal9-l1test2 / Controls=9.1-diag: x alias, tighter themed companion slots and
optional 30-second wrapper tracing. Test 1 controls/binds remain. Save Only was
already implemented in Test 1. L1-left/echo and mode switching are user-confirmed
live; Frank's PC still has substantial sticky input. Do not claim a cause or fix.
Compare ps5 vs x with current selected/running status; both use the shared reader.
Trace: //xb controller trace on|off, log data/controller-input-trace.log (buffered).
Read TESTING/PERSONAL's current sections for the exact A/B test and agreed but
unimplemented trigger-order, return-to-shoulder, inventory and combat-bar ideas.
No public changes, bank collapse, Ctrl/Alt swap, Basic rename or R2 F8 experiment.

---

# Historical continuation — Personal 9 L1 Test 1 (October 16, 2026)

Author: A. Branch personal/ps5extended. Runtime personal9-l1test1; Controls=9.0-l1.
The earlier handoff below remains a historical record. Its statements that L1
is pending or switches clients and Save Only closes the editor are superseded.

Implemented: successful Save Only returns to the scoped catalog record selected
on its page; failed saves preserve drafts and Save & Bind is unchanged. L1 has
two saved modes: existing keyboard shortcuts plus fading reference, and one
editable eight-slot command bank plus persistent companion. Bare unused L1 tap
toggles modes, not clients; combinations consume the tap. Native modifier pairs,
R1/PS/touchpad/movement and normal trigger routing remain. The bank has command
editing, append, clear, scale/position/drag lock/reset/preview under //xb l1.

New modules: l1_bank.lua, l1_transport.lua, l1_view.lua. Main integrates their
context lifecycle and drawing; personal_controls.ahk publishes acknowledged
token-scoped snapshots. personal_controls.lua publishes complete leases with
the current mode/token/ack. No extra keyboard signal, separate addon, new
L1 global alias or Trust autoloader. Complete test ZIP includes the unchanged
TrustMovement 0.1.1 companion separately from xivcrossbar/.

Read current README/PERSONAL/TESTING before older notes. Stop the shared wrapper
and unload all clients before installing. Preserve user data/config.ini/icons.
Native AHK/Windows/FFXI acceptance is pending; general sticky-input and cutscene
reveal issues are NOT claimed fixed. Next: live basic press/release/focus/menu/
native-pair testing with harmless echo commands, then editor/catalog expansion.
The ZIP's TESTING header identifies exact local and published source commits.

---

# Historical XIVCrossbar Personal — NEW RC3-based development handoff

Prepared October 15, 2026, America/Chicago. Author: A.

## Start here

This is the NEW personal line rebuilt from public RC3 plus Icons/Credits/Escape.
It is NOT the older Batch-era personal branch. Continue on personal/ps5extended
in https://github.com/rerorriM-Mirrorer/xivcrossbar. Runtime baseline is
0.4.0-a.20261014.personal8-sets1; shared wrapper Controls=8.1; resource helper
cleanup6. Published runtime checkpoint: 59f1950acdec61002333f5491f334b26c2243ba9;
local counterpart: 3d616cd720c597c1b579551bbeddc1a20f730f26. Exact handoff delivery
commits are in package TESTING.md. No runtime behavior changes in this delivery.

Read docs/BRANCH-MAP.md and root WORKFLOW.md/TESTING.md next. The public candidate
has a separate maintenance branch. The older personal code is a reference for
selected ideas, not an installation to overlay or a baseline to replace this one.

Immediate priorities: investigate missed/sticky/doubling input; restore dependable
cutscene trigger reveal; implement Save Only returning to the custom-action list.
Then develop the two L1 modes/banks. Pending ideas below are NOT implemented.
TrustMovement is already managed by AddonManager: no automatic loader is needed.
Reciprocal switches between Default bars are user-confirmed working.

## Complete installation and first checks

This package is a COMPLETE xivcrossbar installation, with images, themes,
licenses, setup screenshots and required modules. No data/config.ini/settings,
catalogs, binds or controller preferences are included. Do not overlay the
public update ZIP on this install. Stop the shared wrapper and unload all clients
before switching code. Install the entire xivcrossbar/ folder. For normal play,
restore your personal data/, config.ini and custom icons from its backup. To
test clean setup leave those out. Existing values override newly generated
defaults. Keep docs and rollback folders outside a live data directory.

Both public and personal use the same addon identity and controller signals;
only one variant/wrapper should run per PC at a time. Their setup/backups remain
separate. AddonManager must point to whichever xivcrossbar folder is active.

1. `//xb status` -> personal8-sets1; `//xb controller status` -> selected/running
   ps5-extended, Controls=8.1, connected and ready. Correct character storage
   appears after the world/server tuple settles. `//xb controller profile
   ps5extended` explicitly selects the personal profile; ps5 selects ordinary.
2. Bare D-pad, Cross/Circle, Triangle/Square; then L2/R2 slot actions and all six
   bar states. No native macro popup outside deliberate Ctrl/Alt pairs, no F7
   target change. Physical keyboard F-keys and Ctrl shortcuts remain available.
3. Run personal shortcuts from the table below. Check release order of native
   modifier pairs, focus switches, menu transitions and disconnect/reconnect.
4. Observe the reported stickiness with bare D-pad versus R1 arrows versus
   modifier-pair arrows. Collect `//xb inputtrace on` briefly, then off, plus
   controller status and console log. Current trace is Lua-side; it cannot yet
   prove the hardware/AHK side of a double or delayed edge.
5. In a cutscene/dialogue where the bar previously stayed hidden, note `//xb
   status` visibility mode and test holding L2/R2. Distinguish absent rendering
   from a trigger the Lua handler did not receive. Keep SlowEnter reachable.
6. Login from character selection without a manual addon restart; verify Fenrir
   bindings and no new spurious Asura profiles. Retest job/no-subjob changes.
7. Custom catalog creation/edit/bind on two clients, reload and deletion. Compare
   `//xb resources` on the same screen after repeated cycles. Check later-page
   spells reach their target list immediately and Back restores the spell page.

The package adds detailed checklists, not a claim those unresolved live tests
have passed. Your existing Default reciprocal-switch pass is retained as a pass.

## Physical input and routing map

AHK v1.1.33+ reads the PS5 DirectInput controller and emits Apps+F1-F12 for base
inputs. Lua uses Apps as capture and context to choose gameplay, XB menu, setup,
text, chooser or crossbar action. Silent Windower bindings consume native F-key
behavior. Actual slot commands come from XML/action execution, not those binds.

| Physical input | AHK output | Bare gameplay Lua output | Trigger-held slot |
| --- | --- | --- | --- |
| D-pad Up | Apps+F1 (DIK59) | I, or Up in arrows mode | 4 |
| D-pad Right | Apps+F2 (DIK60) | L, or Right | 3 |
| D-pad Down | Apps+F3 (DIK61) | K, or Down | 2 |
| D-pad Left | Apps+F4 (DIK62) | J, or Left | 1 |
| Cross, Joy2 | Apps+F5 (DIK63) | Enter | 6 |
| Square, Joy1 | Apps+F6 (DIK64) | Numpad Plus, active-window selection | 5 |
| Circle, Joy3 | Apps+F7 (DIK65) | Escape | 7 |
| Triangle, Joy4 | Apps+F8 (DIK66) | Numpad Minus, game main menu | 8 |
| Share/Create, Joy9 | Apps+F9 (DIK67) | XB menu; exits full XB menu when open | none |
| Options, Joy10 | Apps+F10 (DIK68) | Set chooser/overlay | none |
| L2, Joy7 | Apps+F11 (DIK87) | Left trigger marker | selects bar |
| R2, Joy8 | Apps+F12 (DIK88) | Right trigger marker | selects bar |

Apps is DIK221. It is held for any base signal, not only triggers. Ordinary
physical F-keys without the marker pass through. Button roles can be changed
by config.ini/setup; this table is the user's PlayStation mapping. Lua gameplay
outputs are deliberate setkey down/up pairs. Addon menus consume D-pad/face
signals, with Cross confirm, Circle back and Share full exit. Escape exits all
XB menus; Enter commits an active text field and is otherwise normal keyboard
input. Options can open a chooser over a draft/binding context.

| Bar | Physical activation | XML hotbar tag |
| --- | --- | --- |
| 1 | L2 | hotbar_l |
| 2 | R2 | hotbar_r |
| 3 | R2 then L2 | hotbar_rl |
| 4 | L2 then R2 | hotbar_lr |
| 5 | Double L2 | hotbar_ll |
| 6 | Double R2 | hotbar_rr |

Slot convention is 1 Left (slot_ll), 2 Down (slot_ld), 3 Right (slot_lr), 4 Up
(slot_lu), 5 Square (slot_rl), 6 Cross (slot_rd), 7 Circle (slot_rr), 8 Triangle
(slot_ru). In memory they remain slot_1..8; XML uses readable tags. slot_zz is
an empty serialization sentinel, not a ninth user button. Preserve this order
for the future L1 bank; Max briefly proposed another numbering then withdrew it.

## CURRENT personal AHK overrides — not future L1 behavior

L1=Joy5, R1=Joy6, L3=Joy11, R3=Joy12, PS=Joy13, touchpad=Joy14, Mute=Joy15.
Personal overrides apply only to ps5-extended and gameplay contexts. They emit
ordinary keyboard/Windows actions before base Apps routing; Windower may still
intercept them. They are not XML slot actions.

| Input | Installed output |
| --- | --- |
| Bare L1 release | Next FFXI client; immediate, no double-tap delay |
| Bare R1 release | F8 |
| L1 + D-pad Up / Down / Left / Right | Ctrl+I / Ctrl+E / Ctrl+J / Ctrl+M once |
| L1 + Cross / Triangle / Square | Ctrl+Space / Ctrl+S / Ctrl+Q once |
| L1 + Circle / touchpad / L3 / R3 / PS / Mute | Reserved and consumed; no output |
| L1 + R1 | Tab once on the second shoulder press |
| R1 + D-pad | Held plain arrows |
| R1 + Triangle / Circle / Cross | Ctrl+Numpad Plus / direct Escape / direct Enter |
| R1 + Square | No special override; ordinary routing |
| L1 + L2 | Hold Ctrl immediately until BOTH buttons release |
| R1 + R2 | Hold Alt immediately until BOTH buttons release |
| D-pad during either native pair | Corresponding arrows, no crossbar slot |
| Bare touchpad short tap | Backtick on release |
| Bare touchpad 500ms hold | Backtick at threshold; Escape on release in same focused FFXI client |
| Bare L3 / R3 release | H / R |
| Hold R3 then press L3 | Comma held while second click L3 is held |
| Hold L3 then press R3 | Period held while second click R3 is held |
| PS press | Focus recent non-FFXI app; press again from outside to restore last client |
| Bare Mute | Unassigned |

Combos consume shoulder singles. Both clicks must return neutral after an ordered
pair; simultaneous samples do not guess order. Native Ctrl/Alt pairs preempt
Apps/F-key slots, can overlap, and deliberately remain latched until both members
release. Other L2/R2 crossbars take priority over personal shortcuts. Focus loss,
disconnect, XB menus/text/setup cancel owned keys; rearm requires neutral. No
controller input should fire an action merely because a context becomes visible.
Sticks still use native movement/camera; no analog zoom translation is active.

## Shared wrapper, movement and lifecycle

ffxi_directinput.ahk is the shared reader/router; despite the name it selects
DirectInput or XInput profiles. Includes: personal_controls.ahk,
personal_gestures.ahk, controller_clients.ahk and movement_signal.ahk. Keep them
together. No AHK v2 variant is included. The personal wrapper's named Windows
mutex derives from its installation directory and is acquired before output.
Duplicate/manual/simultaneous launches from that folder exit; another folder has
another lock. It does not mean profiles differ independently per character.
One running wrapper has one selected profile/device/modifier. Lua's profile
command coordinates a shared stop/start; use consistent profiles across clients.

Last-client shutdown is implemented: Lua sessions register owner files without
requiring an ffi module; minimized and pre-login clients count. The last client's
on_unload_killahk preference is honored after a two-second reload grace. Unloading
one of multiple clients should keep the wrapper. Explicit `//xb controller stop`
stops it for everyone. AHK exit handler finishes with ExitApp after releases.

Movement integration is preserved, not separately bundled Trust/TrustMovement.
The sibling addon is addons/trustmovement (commands //tm), not testmovement.
AHK observes left-stick magnitude >=0.24, checks fresh receiver readiness and
gameplay context, then sends vk1Dsc07B (NonConvert/Muhenkan, DIK123) for 30ms.
It is independent of Apps/F-keys; Blind preserves held modifiers. One signal
per newly piloted FFXI client; recentering and desktop trips do not rearm it.
TrustMovement live mode requests trust follow me, then trust assist me. Its test
mode only reports; mode is saved. Max has it in AddonManager, so do not add an
XIVCrossbar autoloader. Wrapper status/log plus //tm status isolate sender versus
receiver; log is data/trust-movement.log. Trust's quiet movement patch is a
separate installation, not to be overwritten by these packages.

## Storage, custom actions and built-in behaviors

Server is resolved from windower.ffxi.get_info().server through resources.servers;
there is no user-selected fallback server. profile_gate.lua waits for logged-in,
known server, valid zone and matching player/entity name+ID stable for 0.75s.
The root observer runs every .25s even after ready; a later stable identity
correction requests one normal Lua reload. Character storage remains gated,
while the wrapper can already provide controller login controls. Old Asura files
are retained, never deleted. This earlier legacy idea was recovered/adapted here.

Bindings live under data/hotbar/<server>/<character>/: job-subjob, JOB-DEFAULT,
ALL-JOBS-DEFAULT, Shared.xml and per-character icon/catalog files. NOSUB is used
when appropriate. Shared global custom-action catalog is data/CustomActions.xml.
Both character and global catalogs are read; global is the default save target.
`//xb catalog global|character|status` chooses new-entry destination. Same-named
records from both sources remain visible with [Global]/[Character] labels; name-
only lookup prefers the selected save scope. Edit/delete follows the selected
record's source ownership. See custom_catalog.lua/player.lua for exact rules.

Catalog saves are coordinated fresh read/modify/write operations, not a stale
whole-catalog overwrite from another client. Provenance uses catalog_scope,
catalog_id, catalog_name and catalog_last_action/alias/icon/linked_action/type.
Those snapshots let current catalog edits update fields that still match the
last catalog value while retaining deliberate slot overrides. Deleted records
leave executable bound copies usable; ambiguous old copies are not guessed.
Catalog refresh while the menu is closed notices other clients' edits. Existing
data is preserved; packages must never distribute a working character's XML.

Custom action Name is the unique catalog key; Alias is the displayed label and
need not be unique. Blank Alias falls back to Name; blank Command to Alias then
Name. Blank XML fields stay blank: fallback is display/execution behavior.
`//xb ca`, `//xb ca <name>`, compatibility `//xb ca new <name>`, and readable
name/alias/command plus n/a/c field commands remain. Inline typing supports
semicolons; a quoted chat command can still be split by Windower before Lua.
The review is one screen, Name first, defaulted Alias/Command green/parenthesized,
changed values white. Name label stays white; save buttons are unavailable until
a valid name. Icon choice returns to review; clear/skip is in the icon/link
pickers rather than extra review buttons. Save & Bind enters the common binder.

No-icon raw/custom slots use none.png visually while the catalog/menu uses the
gear icon; do not fill XML just to display a default. Linked action metadata
supplies an underlying spell/ability's recast, cost/availability/icon cues for a
raw command, without changing the command. Explicit icon overrides remain.
Change Slot Icon affects one bound slot; Change Action Icon uses SharedIcons.xml
name-based lookup. It is not a live catalog link. Execute Command is removed
from the main menu but its legacy code/bindings remain usable. Attack's normal
special action/alias drives engaged/disengaged artwork; do not apply the special
case to a custom action simply named Attack. Trust-summoned/Return Trust artwork
is an unimplemented idea, not a current behavior.

Set chooser is an overlay: menu stays underneath, dimmed and input-suspended;
closing resumes the exact draft. Chooser forces bar visibility temporarily,
hides Change crossbar sets hint while open, and follows the Options anchor.
Immediate compact switching and dragging move associated hints/tooltip together.
Binding messages and menu destination titles use display names plus Crossbar.
Default/Job Default/All Jobs Default are first in switch destinations; commands
store stable environment keys, not display names. Reciprocal same-slot switching
now passed live; quick-switch one-action return still deserves a live check.

## Defaults and command reminders

Fresh settings: Extended/device1/Apps, IJKL, oninput, compact, six bars,
AutoHideExtraBars=true, enable_superwarp_all=true, catalog save global,
on_unload_killahk=true; InputTest/Trace false; normal fades enabled with .1s in,
.5s out, 2s startup. Saved values stay authoritative. One-time personal profile
migration adopts Extended for older base-PS5 settings, then respects later
explicit choices. Do not repeatedly force an installed user's preferences.

Useful commands: //xb help, status, resources, reload (binding data), restart
(graceful full Lua reload), unload; //xb controller status/start/stop/profile;
//xb dpad ijkl|arrows; //xb compact [on|off]; //xb scale <.25..2>;
//xb hide/show/auto; //xb autohide [on|off]; //xb fade [on|off];
//xb textfade [on|off|status]; //xb autoattack [on|off|status];
//xb catalog [global|character|status]; //xb inputtrace [on|off];
//xb remap. Preserve existing new/bar/set/clear/copy/move/rename/deleteset/icon/
alias command distinctions; don't invent shorthand that conflicts with them.

TextFade=false preserves endpoint timing (text appears when fully revealed and
disappears when fading out starts). True fades text and corrected stroke with
the bar. The stroke API fix was live-confirmed to remove the earlier flicker;
keep both display choices. MP normal green is RGB194/253/195; insufficient MP
pink255/149/151; TP remains254/222/0. Texts.Color.Alpha is still unwired.
Rounded timing bars share the crossbar transform. Skillchain opacity0 hides fill
and backing, while bundled tracking still supports slot cues. AA opacity0 hides
only its display; //xb autoattack off actually stops/resets its estimator.
The estimator defaults enabled for compatibility, so a fresh invisible AA bar can
still do work. COLOR-SETTINGS.md details these differences and dormant settings.

## Confirmed fixes versus unresolved issues

Implemented and simulated: stable login observer, provenance surviving XML reload,
coordinated catalogs, last-client registration, resource ownership, pagination,
Default destinations, current controls and shape/layout transformations. Recent
runtime review parsed 88 Lua sources with the Lua5.4 fallback; pure AHK decisions
had 33 translated-JS scenarios plus six lexical/include checks. Native AHK/FFXI
execution is not available here. See tests/ in Git, not inside the runtime ZIP.

User-confirmed in the evolving line: compact toggle, stroke-flicker correction,
ordinary crossbar routing/no target leak in earlier accepted tests, item icons,
menu appearance/selection/page animation, cleanup4 menu recovery and reciprocal
Default switching. Later failures and retests must not be erased by those passes.

Open input report: delayed/missed presses, nonresponsiveness and a doubling-ish
D-pad feel. personal_controls.lua rewrites a context file at most every .25s;
AHK reads it while polling at 10ms. A partial read can produce unknown, cancel
personal keys and require neutral. This is a plausible source of interruption,
NOT a reproduced Windows root cause. Check physical/native duplicate input,
held-key repeat and POV diagonal ownership too. The movement hook does not wait
for a stick to move before polling other controls. Trace real down/up ownership
before broad timing/debounce changes. Ctrl/Alt pair latching until both buttons
release is deliberate and can itself feel held if one member remains pressed.

Open cutscene report: some scenes suppress bars even with triggers. visibility.lua
allows trigger reveal in oninput, but always mode still returns false during
cutscenes. Status-change code also hides immediately before prerender reconciles.
Inspect effective saved mode, received trigger edges and rendering state. Do not
claim the always-mode inconsistency explains an oninput failure. Explicit hidden
mode should remain an intentional manual choice unless Max asks otherwise.

Crash/text loss: pol.exe1.18.13.0, local PlayOnlineViewer/d3d8.dll4.8.2.134,
exception c0000005, offset0000eefd. Text disappeared in Balloon, XIVParty, native
console and Superwarp's box before earlier crashes. Leaked transient drawing
objects were demonstrated and fixed; a process-wide crash cause is not proven.
cleanup1-3 exposed Windower List numeric metadata errors; cleanup4 guarded owned
objects; cleanup5 removed stale inline references and made cursor teardown
idempotent; cleanup6 clamps pages when switching to a shorter target list.
Use //xb resources on matching screens and relevant logs, not invisibility as
evidence of no CPU or no retained resources. PERSONAL.md retains cross-addon audit.

## Pending work — priority and small details

1. Input/context handoff investigation, cutscene trigger access, and Save Only
   after editing through the menu returning to its catalog list. Save & Bind
   can exit after binding. Changing set mid-draft must continue preserving it.
2. L1 mode change: remove bare-L1 client switching; bare unused tap toggles
   personal-keyboard mode versus editable bank. Mode1 shows a fading reference
   bar with current Ctrl/menu shortcuts; mode2 keeps its separately positioned
   bank persistent. Combos consume mode taps. Preserve L2/R2 and menu priorities,
   no action on reveal or focus regain, no double-tap gesture delay. This code
   does not exist yet; do not advertise it as installed.
3. Reuse selected old companion ideas: compact two-diamond layout upper-left,
   own scale/drag, tiny numbers1..8, PlayStation button icons with alias below,
   commands //l1 <slot> <alias> <command> and append for semicolon chains. The old
   independent addon exists only in the legacy Batch19 reference. Future menu
   editor/binding to an L1-only bank was proposed but is not yet designed.
   Per-bank autohide should support inheriting global behavior before optional
   overrides; do not force all main trigger bars visible/overlapping.
4. Icon organization: picker sees selected iconpack only; native spells/abilities
   live in sibling directories. Separate user-selectable icons from internal
   UI assets in the picker first. ui contains controller art, frames/backgrounds,
   fallback overlays AND some useful icons. Keep current paths working and add
   compatibility before any folder migration. Preserve icon_list.txt and its
   generator; it is a catalog, not an in-game arrangement definition. Numeric
   spell/ability artwork needs friendly resource names. mappoint/partymember/
   returntrust images are not proof those actions are implemented.
5. Personal main menu: hide/reorder unused choices, then perhaps temporary
   controller crossbars for menu selection (higher priority than warp folders).
   Keep footer off until a useful design exists. Do not remove Cross/Circle
   contextual hints. Current main menu custom-actions first: create/choose/edit/
   delete; Remove Binding near end; Execute Command removed. Future consolidation
   of deletion into review was discussed, not implemented.
6. Lockout colors: muted reds/greys while locked, optional subtle blue/green-grey
   ending, no abrupt green success implication. Spell final15% and JA after1s
   are current display thresholds, not server readiness measurements. WS/JA use
   2s; spell defaults3s. New palette/interpolation and stronger lower-background
   opacity are deferred. Independent trigger-field fade can remain dormant.
7. Small UX backlog: binding hints brighten when combo captured; possible small
   slot-bound animation; first-frame centering hop/old cursor artifacts should
   be rechecked if they recur; review fields/helper text spacing at all scales;
   quiet menu-open/close, page and cursor sounds plus future re-recording. Some
   old screenshots were missing; don't claim sampled colors from them.
8. Set scope without all- naming prefixes, clearer create-in-current/global
   choice and display names independent from keys remain undecided. //xb new
   currently has existing scope behavior; do not silently change it. Separate
   linked metadata default/no-link and target choices retain current behavior;
   <t> first is already implemented in supported personal target lists.
9. Much later: area/folder/recent/available Superwarp integration; trigger-only
   left/right visibility; trust summon/return icon tracking; personal asset
   sorting; more programmable R1 bank/extra-button gestures and nonstandard-key
   probes. Do not reopen the Fn/media-key transport experiment by default.

## Retired experiments and references

Do not restore Ctrl transport: Apps plus silent F-key bindings is the accepted
transport. Ctrl is only intentional personal keyboard shortcuts/pairs. Higher
F-key probe: F13/F14/F15 were recognized, later face F-keys produced DIK0; media
keys opened VLC/mail/default-app/Start/window switching. No higher-F migration
is currently active. Manual key probe lives tools/keyprobe and never auto-loads;
Mute-gated probing is an idea, not implemented. F13 was an old L1 marker only.

Retired: switch Back in party binds; PS cycling/minimize/hold behaviors; shoulder
double-tap client cycling; bare L1 F10; L1 touchpad Tab/F15; analog L1-stick zoom;
old Alt latch on horizontal R1 directions. Their historical notes remain below
current tables in PERSONAL.md; the top current table and actual source prevail.
PS/touchpad/shoulder actions must not be inferred from those older tables.

Latest supplied snapshot: xivcrossbar-snapshot-10-15-2026.zip (Library
libfile_95a5892e901881919538de060ccabeec), console(20261015-133537).log
(libfile_9bace240bc88819194d7350247aab53d). It matched cleanup4 runtime except
the supplied movement-integrated wrapper, adopted at local dc4cbae/published
f76136b before later controls/gate/destination changes. Old local references:
review/old-personal/batch19-test2/l1 and profile_gate.lua. Those scratch paths
may disappear; use retained packages/history when absent. The snapshot contains
user data: never turn it into distributed default bindings.

Party template intent: Cioara/Myrr/Clairvaux/Killala-family focus switches, Trust
Ready/start/stopall/assist-follow, party NPC targeting, SlowEnter/NPCMirror and
map/check/attack utility commands. Latest rename was alias Ready and name
Party- Ready. Exact reusable catalogs/binds were separate user-requested XML
deliveries; do not ship them in this code installation or invent NPCMirror
commands from this rough reminder. Follow current addon documentation for those.
