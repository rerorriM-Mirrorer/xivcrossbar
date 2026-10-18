# Controller reference — DirectLink companion banks 1

Current runtime directlink1-banks1; Controls=9.9-banks. Profile/readers, ordinary
buttons and R3 F8 below remain applicable. The L1/R1 mapping sections below are
historical and superseded by [the complete current bank map](SHOULDER-BANKS.md).
L1 inventory changes to scrolling/emotes in native menus; L1L2 imports saved
commands; R1 navigates Trust with Triangle Open/Square Close; R1R2 is empty for
chosen NPC interactions. Both ordered shoulder-first banks are implemented.
Lua owns these actions, including native-key requests to AHK. The panels share
compact geometry, hide in native menus and are editable with //xb bank.

---

# Historical controller reference — Personal 9 Test 6

Author A. Runtime directlink1-r1test1; wrapper Controls=9.6-r1-r. This describes
the delivered source, including the momentary L1 layers from Test 3. Saved face
roles, D-pad mode, bar actions and companion assignments remain per-character.

## Readers and profile names

Use `//xb controller profile <name> [device]`. Status shows selected and running
profiles; wait for them to match. Stop/start replaces the shared wrapper for all
clients. DirectInput devices are 1–16; XInput devices are 1–4.

| Short name | Full profile | Reader and extra controls |
| --- | --- | --- |
| x, ps5extended | ps5-extended | PS5 DirectInput plus all personal shoulder/PS/touch/click controls below |
| ps5 | ps5-directinput | Common PS5 reader without personal controls; useful comparison |
| f710 | f710-directinput | Experimental DirectInput; same logical transport |
| fightpadpro | fightpadpro-directinput | Experimental DirectInput; different face-button numbers |
| xinput | xinput | Experimental Xbox-compatible reader; Back/Start menu signals |
| xinputalt | xinput-r1-chooser | XInput variant: RB replaces Start as the set-chooser signal |

`x` always means PS5 Extended, not XInput. The private personal profile is
accepted even though the ordinary `controller profiles` list omits it.
Private `//xb x [device]` selects the extended profile. `//xb r2`, `//xb r3`
and `//xb both` toggle acquisition; append on/off/status for explicit control.
Both enables both unless both are already on, in which case it disables both.
All these profiles use this project's shared AHK reader. Selecting ps5 does
not run the untouched upstream PS5 script.

## Message controls and status

`//xb messages` toggles; on/off set explicitly; status reports the saved setting.
`//xb controller status` reports the wrapper route, sent/ack and write errors.
Each client publishes its own transport selection. Tokens/neutral handoffs prevent
old held gestures from carrying into a new client or route. Complete snapshots
retain unacknowledged edges; heartbeat advances every 100 ms and Lua clears held
input after 350 ms without advancement. A stale queue cancels before actions are
replayed. An unloaded/logged-out client may return to the keyboard route only at
neutral after its lease expires. Native AHK/file timing is still a live check.

## Common button transport

PS5 Extended defaults to ordered button messages in Test 6. AHK sends no Apps
or F-keys for these twelve buttons. Lua feeds the messages into the same router,
choosing gameplay, addon navigation or a slot. The table below describes the
legacy signal/physical mapping. `//xb messages off` restores that route; other
profiles keep it. Return neutral when switching, and restart Lua AND AHK on install.
With keyboard transport, AHK holds Apps while sending the logical F1–F12 edges.
Plain keyboard F-keys remain available. Older optional Ctrl transport exists;
Apps is the intended default to avoid native macro palettes.

| Physical/logical button | AHK signal | DirectInput PS5/F710 Joy | FightPadPro Joy | XInput |
| --- | --- | --- | --- | --- |
| D-pad Up | Apps+F1 | POV 0 | POV 0 | D-pad Up |
| D-pad Right | Apps+F2 | POV 9000 | POV 9000 | D-pad Right |
| D-pad Down | Apps+F3 | POV 18000 | POV 18000 | D-pad Down |
| D-pad Left | Apps+F4 | POV 27000 | POV 27000 | D-pad Left |
| Cross / bottom | Apps+F5 | 2 | 3 | A |
| Square / left | Apps+F6 | 1 | 2 | X |
| Circle / right | Apps+F7 | 3 | 4 | B |
| Triangle / top | Apps+F8 | 4 | 1 | Y |
| Share / Back | Apps+F9 | 9 | 9 | Back |
| Options / Start | Apps+F10 | 10 | 10 | Start; RB in xinputalt |
| L2 / LT | Apps+F11 | 7 | 7 | Left trigger >4/255 |
| R2 / RT | Apps+F12 | 8 | 8 | Right trigger >4/255 |

DirectInput diagonal POV readings retain one adjacent direction, never both.
The current PS5 trigger route reads binary Joy7/Joy8. There is no light/hard
press distinction. Analog triggers could support thresholds if read through
their analog channels, but those channels must first be identified for this
controller/driver. Face buttons and stick clicks are digital in this route.

## Bare gameplay and native menus

The usual saved PS mapping is below; remapping can change the four face roles.
Lua `setkey` drives native gameplay. This is distinct from AHK injecting a real
keyboard event that another addon's keyboard listener can receive.

| Input | Output / purpose |
| --- | --- |
| Bare Cross | Enter / confirm |
| Bare Circle | Escape / cancel |
| Bare Triangle | Numpad Minus / main menu |
| Bare Square | Numpad Plus / active in-game window |
| Bare D-pad, personal default IJKL | Up I; Right L; Down K; Left J |
| Bare D-pad, arrows mode | Corresponding arrow |
| Share | Open/close action editor; ignored while editing a text field |
| Options held | Show set chooser; Up/Down change selection; release accepts/hides |
| Keyboard Escape in addon UI | Close/cancel addon UI; owned through key-up to prevent native leakage |
| Keyboard Enter in addon text entry | Confirm the text field; owned through key-up |

`//xb dpad ijkl` or `//xb dpad arrows` selects the native D-pad output. IJKL
requires the matching FFXI Menu/Target Cursor assignments shown in README.
Setup, login, addon menus and crossbar activation own the signals differently.
Native menu Escape remains useful: it backs out of the native menu.

## L1 rendering and routing

Bare L1 emits no native keyboard key. AHK publishes a show event through the
personal companion mailbox; Lua updates the layer and draws its surfaces. Release
publishes release/hide. L1 then L2 publishes bank instead, in the same location.
The keyboard companion's Ctrl shortcuts are separate outputs on fresh slot presses.
Lua explicitly checks info.menu_open and info.chat_open before rendering either
companion. Native menus also revoke the bank execution token. This behavior remains.

Ordinary buttons now use an ordered message stream by default on profile x.
The existing Apps+F-number route remains selectable. Lua decides native gameplay
versus addon menu versus crossbar action in a shared routing function.
Personal shortcuts still make some decisions in AHK. Moving those meanings into
Lua would consolidate routing; that consolidation is still a future change. Test 6 changes ordinary button transport.

## PS5 Extended personal layer

These apply to profile x only. Physical Joy numbers are L1=5, R1=6, L3=11,
R3=12, PS=13, touchpad=14, mute=15.

| Gesture | Current behavior |
| --- | --- |
| L1 held / released | Reveal / hide shortcut companion; no mode toggle or client switch |
| L1, then L2 | Replace shortcuts with saved action bank in the same location |
| Release L2 while retaining L1 | Reveal shortcuts again |
| Release L1 while retaining L2 from the bank | Hide; consume remaining L2 until release |
| L2, then L1 | Retain ordinary L2 crossbar until L2 releases |
| L1/L2 in the same sampled poll | Prefer ordinary L2 |
| R2 during companion gesture | Ordinary R2 priority |
| L1+Up / Right / Down / Left | Ctrl+I / Ctrl+M / Ctrl+E / Ctrl+J, once per fresh direction press |
| L1+Cross / Square / Triangle | Ctrl+Space / Ctrl+Q / Ctrl+S, once per fresh press |
| L1+Circle | Reserved; consumed with no Escape |
| L1+R1 | Tab once when the second shoulder is pressed |
| R1+D-pad | Corresponding plain arrow held with the direction |
| R1+Cross / Circle | AHK Enter / Escape directly |
| R1+Triangle | AHK Ctrl+Numpad Plus |
| R1+Square | Ordinary Square signal; no special personal binding |
| Bare R1 press / unused release | No output on press; R once on release. Any chord consumes the hold |
| R1+R2 | Ordinary R2 crossbar; no Alt latch |
| Bare L3 release | H |
| Bare R3 release | R |
| R3, then L3 | Comma held by L3; requires both neutral before rearming |
| L3, then R3 | Period held by R3; requires both neutral before rearming |
| Bare touchpad short release | Backtick |
| Bare touchpad held 500 ms | Backtick once; Escape on release to close the peek |
| PS fresh press | Toggle recent non-FFXI application / last FFXI client; hold adds nothing |
| Mute | No assigned personal output |

Movement and camera sticks retain their native FFXI assignments. The wrapper
observes the movement axes for TrustMovement's existing takeover signal; it does
not replace their movement. With the companion loaded, that signal fires once
per newly piloted FFXI client, not after every return to stick center.

R1 sends R only on an unused release. Chords, focus/context loss, uncertain leases
and physical modifiers/R cancel the pending tap. Touch/click shortcuts
are suppressed by shoulders and other active combos. A newly revealed companion
never executes a direction/face button already held. Focus, menu/text/setup,
disconnect and stale-context loss cancel personal gestures and require neutral.
There are no native Ctrl/Alt shoulder-pair latches. Their horizontal inventory
uses remain candidates for deliberate, brief menu-only chords, not installed
bindings in this version. Existing R1 plain arrows remain useful for Trust UI.

The saved bank uses **1 Left, 2 Down, 3 Right, 4 Up, 5 Square, 6 Cross, 7 Circle,
8 Triangle**. `//xb l1 <slot> <alias> <command...>` edits it; `append`, `clear`,
`status`, `help` and `preview bank` are available. Bank actions save per character;
the installer does not replace them. Empty slots do nothing. These are the
L1-then-L2 entries; the first L1 shortcut layer is currently fixed.

Both companion layers use the same saved position/lock and follow the main
compact spacing, 40px icons and CrossbarScale. `//xb l1 scale crossbar` follows
it; a numeric scale opts out. `unlock`, `lock`, `pos`, `resetpos` and previews
allow editing without holding the controller.

## Ordinary six trigger bars

| Gesture | Internal bar | XML name |
| --- | --- | --- |
| L2 held | 1 | hotbar_l |
| R2 held | 2 | hotbar_r |
| R2, then L2 | 3 | hotbar_rl |
| L2, then R2 | 4 | hotbar_lr |
| L2 twice, hold second press within 0.5 s | 5 | hotbar_ll |
| R2 twice, hold second press within 0.5 s | 6 | hotbar_rr |

Each has eight slots: Left, Down, Right, Up, Square, Cross, Circle, Triangle.
The selected set supplies the action, with Default → Job Default → All Jobs
Default fallbacks when applicable. Main displays the internal basic set; it is
not an additional provider to other sets. Trigger paging in an addon menu uses
that menu's page controls rather than executing the corresponding gameplay bar.

## Target acquisition — R3 only by default

```
//xb controller target
//xb controller target r2 on
//xb controller target r3 on
//xb controller target both on
//xb controller target both off
```

Test 5 adopts R3 on / R2 off once for existing saved settings, then respects
later commands. Bare R1 never sends F8. Shared defaults off for new settings;
explicit saved Shared choices are retained.

R2 trial: a fresh, unmodified R2 from gameplay emits plain F8 down/up first,
then the ordinary R2 event (Apps+F12 only with keyboard transport). R3 trial: a fresh, unmodified R3 emits F8 on
press; an otherwise unused R3 still sends R on release. No repeat while held.
Settings save separately per character and reach the shared wrapper through the
current client's lease. Changing them requires a neutral rearm.

Neither trial fires inside reported native/XIVCrossbar menus, chat, setup, cutscenes, an existing
Apps capture, held keyboard modifiers/F8, or overlapping face/D-pad/shoulder/stick
combos. R2+face in the very same sampled poll skips acquisition and retains the
ordinary combo. R3→L3 zoom gets the initial F8; L3→R3 does not. Acquisition can
retarget; test each option separately before enabling both.

The existing SendEvent delay separates F8 down/up; no Sleep or global key-delay
change was added. Nominal delay is 10 ms; this trace's emitted edges often sit
15–16 ms apart. Two extra native sends can add roughly 30 ms on that system.
Output ordering does not guarantee FFXI has finished updating its target before
an immediately following slot action; native acceptance remains pending.

## Why AHK and Lua both participate

AHK reads the hardware, owns native injected keys and handles application focus.
Lua owns the addon UI, binding tables, fallback/action rules and which button
events may reach native gameplay. Both the ordinary message route and companion
communicate without extra gameplay keybindings.

A future direct face-button AHK route could use Lua's context and saved mapping,
and might serve Trust's keyboard UI more consistently. It must choose one owner
on key-down, retain that owner through key-up, and never also forward the same
press as a message or Apps/F-key action. Moving the sender does not remove that decision
or guarantee lower latency; it adds dependence on the context channel. Trust's
keyboard.lua listens to Windower keyboard events. Whether native setkey follows
the same route needs a controlled in-game comparison. R1+Cross/Circle may become
redundant after that test; R1+Triangle is a distinct modified command.

## Current diagnostic findings

The supplied 30-second October 16 trace has six no-matching-lease misses. One
15 ms gap is followed by approximately 4.4 s of personal disarm while L1 stays
held. Button filtering also removes keys during enumeration, allowing the next
entry to be skipped; the trace contains matching one-poll signal leaks.

Test 4 retries a missing lease once; if still unknown, an already armed session
pauses new downs for at most 100 ms. Physical transport releases pass through;
new actions require a current valid lease. A true stale/menu/focus/token change
still cancels/rearms. Masking finishes before released filter entries are deleted.
These fix observed failure paths; they do not establish the cause of every
sticky input on Frank's desktop. The trace has slow polls up to 125 ms.

`//xb controller trace on` captures 30 s; off stops early. The appended buffered
log is data/controller-input-trace.log. Current captures identify Controls=9.6-r1-r
and log pauses/prefires. Compare off first, then R2, then R3 on the same client.

Sources: current personal source; supplied controller-input-trace.log;
[AHK v1 controller input](https://github.com/AutoHotkey/AutoHotkeyDocs/blob/v1/docs/lib/GetKeyState.htm),
[enumeration rules](https://github.com/AutoHotkey/AutoHotkeyDocs/blob/v1/docs/lib/For.htm),
[key delays](https://github.com/AutoHotkey/AutoHotkeyDocs/blob/v1/docs/lib/SetKeyDelay.htm),
and [Trust keyboard input](https://github.com/rerorriM-Mirrorer/trust/blob/main/cylibs/ui/input/keyboard.lua).
