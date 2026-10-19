# Bank layout and typography test 1 — October 19, 2026

Source baseline d6a12c8d8356d6abd3e4f747f2130d24dea1ee27. Author A.
Runtime directlink1-banklayout1 / unchanged Controls 9.10-holdfix.

Use `//xb bank <layer>` consistently for all four layers, including R1.
For existing personal banks, swap L1/R1 once and assign Quests in both contexts:

```
//xb bank swap l1 r1
//xb bank l1l2 cross Quests input /quest
//xb bank l1l2 menu cross Quests input /quest
```

This preserves all current commands, including overrides and factory-resolved
entries. Positions remain left/right rather than following the swapped bank.
The updated explicit Cioara preset already includes these changes; applying it
also resets its other companion definitions, so it is not the existing-user
upgrade route. Keep the current settings and use the three commands above.

`//xb bank l1 edit on` pins/unlocks the left bank for mouse-only dragging. Edit
off unpins/locks. The same form works for r1/l1l2/r1r2. Hidden-bank edit previews
can draw temporarily; input is never armed by the preview. `hide` ends a pinned
preview. Typographic font/size follows main Texts settings and CrossbarScale.

Use `//xb pos` for main copyable coordinates and `//xb bank l1 status` /
`//xb bank r1 status` for copyable panel coordinates. Settings live in
`data/settings.xml`, Style.OffsetX/Y and CompanionBanks.LeftPanel/RightPanel.X/Y.
Main offsets use screen-centre/bottom anchoring; bank positions are absolute UI
pixels. Use matching client UI resolution and scale when copying locations.
No Ctrl+drag grid snapping is implemented by this update.

---

# Companion banks — checkpoint 3

October 19, 2026. Author A. Runtime directlink1-banks3 / Controls 9.9-banks.
Starting source a572fcac584b351d1db6af921766f2da50f8df67.

New per-layer controls: `//xb bank <layer> show|hide`, `menus on|off`, and
`menuactions on|off`. Short r1/r1r2/l1l2 editors accept the same operations.
Bare `//xb l1` retains its historical L1L2 meaning; use `//xb bank l1`.
Show/hide only affects drawing. Menus controls drawing over native menu_open;
menuactions off always selects the Closed commands and labels. Default policy
remains visible, hidden over native menus, automatic Menu actions enabled.
Trust menu visibility is not inferred from the native flag.

The optional `//xb bank preset cioara apply` copies Cioara's uploaded ordinary
bar commands to L1 NPC/tests and R1 party, copies current L1 closed/menu bindings
to L1L2 inventory, and sets R1R2 to Trust menu navigation. Read the README for
the exact map and dependency notes. Apply explicitly after backing up settings;
all four companion definitions are replaced, ordinary/job XML is untouched.
The current inventory entries are cloned, including personal assignments and
saved menu scrolling/emotes. R1 can draw over menus; R1R2 is hidden; menu actions
start off on all four banks. Turn on L1L2 menu actions for automatic scrolling.
This avoids treating the battle command menu as proof of an item menu. Automatic
native menu-type detection is not implemented. The original factory defaults
below are unchanged and still restored by default/defaults commands.

Next live acceptance: four bank roles, hidden R1R2 Trust navigation, native-menu
R1 visibility, inventory commands while engaged/menu_open, and optional scrolling.
The persistent compact Options flash remains unresolved after the previous fix.
The one-command live test/screenshot runner remains authorized, not shipped.

---

# Historical checkpoint 2

October 18, 2026. Author A. Runtime directlink1-banks2, unchanged Controls 9.9-banks.
Starting source: 549e5d86df4919eb82e4c5085aed892b6db9f775.

Short forms `//xb r1r2`, `//xb r1` and `//xb l1l2` route to the same bank editor;
all arguments are identical, and bare reports status. `//xb l1` remains the
legacy L1L2 editor. Use `//xb bank l1` for the bare L1 bank.

| R1→R2 button | Shipped console command |
| --- | --- |
| Triangle | `npcmirror interact` |
| Square | `npcmirror stop` |
| Cross | `npcmirror enter` (guarded session step) |
| Circle | `npcmirror esc` (guarded session recovery) |
| Up | `slowenter all once` (raw Enter, same-PC clients, initiator last) |
| Down | `slowenter all once esc` (raw Escape, same ordering) |
| Left | `npcmirror call` |
| Right | `npcmirror status` |

The shipped map is the same in Closed and Menu contexts. NPCMirror/SlowEnter
own execution and their respective safeguards; no Send wrapper or simulated
shortcut is added here. Raw SlowEnter taps bypass its choice/chat/target guards.
SlowEnter v1.4.0+ must be installed on each participating client. This only binds
the existing commands; it does not resolve the reported raw-all-client delivery
issue. Existing status-4 cutscene input suppression remains: this checkpoint
does not enable the bank inside every NPC event. Test ordinary gameplay/native
menu use first; event access needs a separate, deliberately scoped input path.

## Overwrite, clear and restore

```
//xb r1r2 triangle "My action" input /echo custom
//xb r1r2 default triangle
//xb r1r2 defaults
//xb r1r2 menu defaults
//xb r1r2 clear triangle
//xb r1r2 status
```

Assignments create saved overrides. `default <button>` removes that override
and follows the hardcoded action AND label again. `defaults` restores eight
slots in the selected context only. `menu defaults` restores Menu entries.
Clear deliberately suppresses that slot, including future factory changes.
Restoration never changes positions/scale/lock or the other bank/context.
L1L2's factory entries are empty; its migrated personal commands remain overrides
until explicitly reset. `append` materializes an inherited console command as
an override before adding to it. Status marks every entry default/override.

CompanionBanks v2 stores Kind=default for inherited entries. Version-1 migration
recognizes unchanged shipped L1/R1 entries and converts them to inheritance;
custom assignments and explicitly cleared L1/R1 slots remain overrides. Empty
v1 R1R2 slots adopt the newly requested NPC defaults once. Because v1 did not
record whether an empty R1R2 slot was unused or explicitly cleared, both adopt;
use clear again to suppress it permanently under v2. The old L1 recovery section
and all panel preferences remain untouched. A fresh XML reload preserves both
inheritance and clear/override choices.

## Original crossbar binding syntax

```
//xb set <set> <bar> <slot> <type> <action> [target] [alias] [icon]
//xb set basic r2r2 triangle ex "input /jump"
//xb set basic r2l2 circle ex "npcmirror esc"
```

The set is explicit; basic is the internal key for Main. `ex` executes console
text. The new explicit bar aliases map l2=1, r2=2, r2l2=3, l2r2=4, l2l2=5,
r2r2=6; l/r/rl/lr/ll/rr and numbers still work. Shape names use the selected
controller layout, and numeric or ll/ld/lr/lu/rl/rd/rr/ru slot names also remain.
These are aliases within the original set API, not new top-level trigger-bank
editors. Bare //xb r2 remains the existing F8 test toggle. Direct assignment of
original job bars through the companion-style label/command API remains future
work, since those bars also carry set, action type, target, icon and metadata.

Command verification sources: NPCMirror main aab69c26d068d409754cc9c9f2e0ffc5a9bc3163,
npcmirror.lua/README; SlowEnter dev/se-toggle dc8341dd8b932c87e33b04c92d358f71f2d17f04,
slowenter.lua/README; current root set_action_command and gamepad_converter.
All tests are simulated/static; dependency/native game success is not inferred.

---

# Historical companion banks — implemented checkpoint 1

Author A. October 18, 2026. Development source baseline f13829a7a5ca9f6715ee1337a77722bc078dae38.
Runtime `0.4.0-a.20261018.directlink1-banks1`, Controls `9.9-banks`.
Implementation and simulated verification are complete; Windows/FFXI acceptance
is pending. The earlier proposal follows as historical context.

## Current saved definitions

`data/settings.xml` holds `CompanionBanks.Version=1`, four banks (`L1`, `L1L2`,
`R1`, `R1R2`), and `LeftPanel`/`RightPanel`. Each bank has `Closed` and `Menu`
sections, with Slot1–Slot8 entries containing Alias, Kind, Command, Key and Hold.
The rendering labels and executor read the same entry. Slot order remains
Left, Down, Right, Up, Square, Cross, Circle, Triangle; named buttons are easier.
Panel scale/position/lock are shared by the two layers on that side. The right
panel starts at the upper-right edge on its first reveal; resetpos recovers it.

Migration copies existing `L1.SlotN` Alias/Command entries into L1L2 Closed only
once. It retains the entire old L1 section. Cleared/new edits survive reload;
defaults declare the complete XML shape to preserve Windower's casing/types.
Settings are character-specific through Windower config. Temporary `.ini`,
`.buttons` and legacy `.l1` files are communication, never binding storage.

| Button | L1, game menu closed | L1, game menu open | R1, either context |
| --- | --- | --- | --- |
| Up | Items: Ctrl+I | Ctrl+Left | Up (held) |
| Right | Equipment: Ctrl+E | Alt+Right | Right (held) |
| Down | `input /wardrobe2` | Ctrl+Right | Down (held) |
| Left | `input /wardrobe` | Alt+Left | Left (held) |
| Triangle | `input /case` | `input /wave` | `trust menu open` |
| Square | `input /sack` | `input /bow` | `trust menu close` |
| Circle | `input /satchel` | Nod: `input /yes` | Escape |
| Cross | `input /jump` | `input /jump` | Enter |

L1L2 retains migrated Closed commands; its Menu entries start empty. R1R2 starts
empty in both contexts, reserving all eight slots for chosen NPC commands.
Native-menu visibility is independent of action permission: both panels hide
over the game menu while the table's Menu actions remain available. The broad
menu flag cannot identify individual item/NPC menus. Trust interprets its own
navigation and validation; its explicit Open/Close support is still required.
`input /yes` is the native nod emote; no Shortcuts dependency is added.

## Commands

```
//xb bank l1 status
//xb bank l1l2 triangle "Test echo" input /echo Bank-test
//xb bank l1 menu triangle Wave input /wave
//xb bank l1 menu key up "List previous" ctrl+left
//xb bank r1 key left Left left hold
//xb bank r1r2 clear cross
//xb bank r1r2 preview
//xb bank r1 scale crossbar
//xb bank r1 scale 0.8
//xb bank r1 pos 600 70
//xb bank r1 unlock
//xb bank r1 lock
//xb bank r1 resetpos
```

`//xb l1` remains the L1L2 compatibility editor, including numeric assignment,
append/clear and panel controls. `l1 preview keyboard` previews bare L1 and
`l1 preview bank` previews L1L2. `bank <layer> menu ...` edits only Menu entries;
omitting menu edits Closed. Empty entries consume the slot. Preview lasts six
seconds and never arms physical execution. Console commands are literal Windower
command text, not Lua. Native keys accept a letter/digit, F1–F12, arrows, Enter,
Escape, Space, Tab or NumpadAdd, optionally prefixed by ctrl+, alt+ or shift+.
Default key actions pulse; explicit hold lasts until release/cancellation.
`status` reports both context maps, active layer, counters and native ack progress.

## Routing and cancellation

Updated AHK negotiates bank protocol=1, then reports ordinary buttons plus L1/R1
in the same sequenced stream. Same-sample trigger downs precede shoulders, then
slots. L1-first then L2 selects L1L2; L2-first stays ordinary until L2 releases.
R1/R2 has the same rule. Releasing the trigger first reveals the bare shoulder;
releasing the shoulder first consumes its remaining bank trigger until release.
An opposite ordinary trigger takes priority. Held slots are consumed across layer
or native-menu changes. Existing L1+R1 Tab and unused-release R1 R remain; using
any R1 chord consumes its release. R3 F8/native click behavior remains in AHK.

Lua chooses console actions directly, or queues native key edges in the existing
context lease. AHK validates the complete output snapshot and a fixed key
vocabulary, owns physical-style key delivery and acknowledges IDs in the input
stream. Quick down/up pairs stay queued and get a nonblocking minimum 40ms hold.
Output IDs increase across cancellation, so a late acknowledgment cannot retire
a new action. Held key/modifier owners are reconciled together; physical keyboard
ownership is preserved. A request acknowledgment proves routing, not game success.

Focus/client/session changes, chat, cutscene, addon editor, disconnect, missing
leases and overdue output cancel owned keys and pending actions. Communication
recovery/session changes require neutral; native-menu transitions alone allow
fresh L1 menu actions while the shoulder stays held. Input cancellation preempts
earlier commands in the same snapshot. More than 64 queued output edges or an
unacknowledged output older than 350ms resets the session; no late replay.
Native key output waits for prior input/cancel acknowledgments. Lua gets its
native game-menu context each frame/event; it does not infer command success.

Older Lua ignores the new capability; older wrappers retain their old personal
map and legacy L1 mailbox. Full bank controls require both updated components,
profile x, messages ON and inputtest OFF. Neither public RC3 nor the frozen
Unbound snapshot is changed. Graphical/catalog assignment remains future work.

---

# Historical shoulder-bank proposal and previous storage

Author A. October 18, 2026. Current direct-R1 shortcut checkpoint follows
a30638dd1475fab9a7b8f094578c596eba3eb38e on development/directlink.
This document proposes the full bank system; only the two R1 Trust commands
are implemented by this checkpoint.

## What exists now

| Layer | Action source | Persistence / editing |
| --- | --- | --- |
| L1 | personal_controls.ahk fixed Ctrl shortcuts; l1_bank.lua reference labels | Not editable bank entries yet. |
| L1 then L2 | l1_bank.lua executes the saved console command | Installed data/settings.xml, L1.Slot1 through Slot8, each Alias/Command. //xb l1 edits this layer. |
| R1 | AHK arrows/Enter/Escape; unused release R. Square/Triangle request direct Trust close/open through Lua. | Existing native shortcuts remain code; the two command strings are in the Lua receiver. No editable R1 bank settings yet. |
| R1 then R2 | Proposed NPC interaction layer | Not implemented or stored yet. |

L1 slot numbering is Left, Down, Right, Up, Square, Cross, Circle, Triangle.
For example //xb l1 1 Wardrobe "input /wardrobe" writes the L1->L2 Left slot;
it does not change bare L1. //xb l1 status reports that current bank.
Config.save writes the current character's settings through Windower config.
These entries are not in job bar XMLs or CustomActions.xml. The data/personal-
controls/*.ini/.l1/.buttons files are temporary communication, not binding storage.

Current R1 commands require profile x, messages ON, updated Lua and Controls 9.8.
Square sends trust menu close; Triangle sends trust menu open. A matching Trust
test addendum supplies explicit Open; older Trust builds may route open through
their default menu handler. Close affects Trust's menu stack, with eligible saves
and validation; it does not dismiss NPC dialogue or other addons' menus.
That addendum is published at Trust commit
17d0f9cc1e8dd400c70ae8411e4ff805d9868129; only commands/MenuCommands.lua needs
updating at runtime over the existing compatible Menu options Test 4 install.

windower.send_command('trust menu close') enters Windower's command dispatcher
directly. The // prefix is the game-chat way to invoke that dispatcher. Sending
input //trust ... would add the game/chat input path. Native menu arrows and
scroll shortcuts can still require AHK keyboard delivery; a console command does
not replace every keyboard input the FFXI client accepts.

## Proposed configuration

Keep character-specific bank definitions with current Windower settings, rather
than scattering them across AHK and job files. Introduce a versioned
CompanionBanks section in data/settings.xml with named L1, L1L2, R1, R1R2 layers.
Each layer supports closed-menu and native-menu entries. Keep two panel position/
scale/lock settings: left for L1/L1L2, right for R1/R1R2. Both layers on each side
reuse the same panel and compact geometry.

Each slot initially needs a label, action kind (console command or native key),
command or key/modifier values, and native-menu permission. Slot buttons use
names such as left, up, square and triangle instead of requiring numeric memory.
Rendering reads the same definition as execution, so a label cannot keep saying
Ctrl+Q after its action becomes Sack. Stable custom-action catalog references can
be added later without copying commands into every job set.

Migrate existing L1.SlotN Alias/Command into CompanionBanks.L1L2 once, preserving
user content and the old section for recovery. Seed bare L1/R1 from current or
explicitly chosen mappings only when no saved entry exists. A schema version
makes this adoption one-time, so later releases do not overwrite personal edits.
Keep //xb l1 as a compatibility editor for L1L2. Proposed new commands are
//xb bank <l1|l1l2|r1|r1r2> <button> <label> <command...>, plus key assignment,
clear, status and preview. These new bank commands are not available yet.

## Input and context ownership

Use one ordered shoulder/button stream into one Lua bank state machine. Lua
chooses the layer and evaluates context, then either executes a console command
or requests the required native key down/up from AHK. AHK remains the hardware
reader and native key sender. The two R1 menu requests in this checkpoint are a
small use of the existing stream, not the complete bidirectional key service.

Preserve physical order: L2 before L1 stays ordinary L2; L1 before L2 reveals
L1L2. Releasing L2 while L1 remains held reveals bare L1. Apply the equivalent
rule on R1/R2 when adding that ordered bank. Same-sample trigger/shoulder presses
prefer ordinary bars. Preserve existing L1+R1 Tab rather than filling every
possible combination; define priority explicitly if both sides overlap.

A press retains its owner until release. Changing menus/layers consumes any
already-held slot; it cannot turn that same hold into another action. A used R1
hold never emits the unused-release R. Focus, chat, cutscene, disconnect, stale
communication and addon/editor transitions release owned native keys and cancel
pending actions. Rearm at neutral for session/client changes.

Keep native-menu visibility and action permission separate. Companions remain
hidden over native menus by default, while explicitly menu-capable actions can
run. Existing arbitrary saved L1L2 commands migrate as closed-menu-only. Trust
open/close and deliberate native scroll/navigation can allow native menus.
Chat, text capture and XIVCrossbar editors have priority over personal banks.
The broad menu_open flag does not identify which NPC/item menu is displayed.

## Intended layers

| Layer | Intended role |
| --- | --- |
| L1, native menu closed | Up Items/Ctrl+I; Right Equipment/Ctrl+E; Left Wardrobe; Down Wardrobe 2; Triangle Case; Square Sack; Circle Satchel; Cross Jump. Use direct input / commands for the game actions. |
| L1, native menu open | Up Ctrl+Left; Down Ctrl+Right; Left Alt+Left; Right Alt+Right; Triangle Wave; Square Bow; Circle Nod; Cross Jump. Native key chords for scrolling; direct commands for emotes. |
| L1->L2 | Mostly free for testing/utility entries; NPC use remains an option, not prefilled. Preserve existing saved entries. |
| R1 | Trust navigation/reference: arrows, confirm/back, Triangle Open, Square Close; bare unused release R. |
| R1->R2 | NPCMirror/NPC interaction commands once their precise verbs are chosen; upper-right panel. Preserve R2-first ordinary bars. |

The L1 context maps above remain desired changes, not installed mappings.
Avoid using display visibility as permission to execute an action, and avoid
guessing commands for the unfilled NPC layer.

## Implementation batches

1. Deliver/test the direct R1 open/close shortcuts and Trust's explicit Open.
2. Add versioned configuration/migration plus typed command/key execution and
   an editable-bank API. Test old settings and source-owned press releases.
3. Move bare L1 and L1L2 onto it; add contextual native-menu mapping and shared
   labels/rendering while preserving ordered ordinary trigger behavior.
4. Move R1 onto the same definition, add its compact reference, then implement
   ordered R1R2 and its chosen NPC entries. Validate both release orders and
   simultaneous edges before extending other controller profiles.

Use simulated state/ownership tests for the context/order boundaries, followed
by Windows/FFXI tests for keyboard delivery, menu interception and multibox
handoff. AHK messages cannot by themselves confirm that a game command succeeded.
