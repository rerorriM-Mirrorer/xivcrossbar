# Shoulder Banks 2 — shared position, toggle editing and aliases

Personal development/ahk-v2-migration. Starting local checkpoint
1971b66e407654815dddf16fe4888c95144b4235. Runtime suffix
`directlink1-ahkv2-shoulderbanks2`. Publication status is in the handoff.

All five companion banks now draw at the same position, using the existing
saved L1 anchor. Dragging or setting the position from any bank updates that
anchor. The former right coordinates are synchronized during movement/drawing
for compatibility. The earlier spacing-preserving link/unlink behavior is
superseded; `bank link on|off` is retired, and the old saved LinkedPositions
field is ignored. Per-side scale and lock preferences otherwise remain.

One bank draws at a time: an explicit preview/edit wins, then the held bank;
at rest an eligible Always L1 takes priority over Always R1. Holding both
shoulders selects L1R1. Editing a different bank replaces the previous edit
preview. The new combined bank retains its eight empty default slots and
replaces the old Tab shortcut; disabling L1R1 restores that old shortcut.
Trust's open-menu input ownership and existing trigger-first routing remain.

Bare edit toggles whether the requested bank is pinned/unlocked for dragging.
Explicit edit on/off remains idempotent. Selecting edit on another bank
switches to its preview. Position is per character, saved in companion_banks.xml.

## Aliases

| Short | Full bank |
| --- | --- |
| l | l1 |
| r | r1 |
| lr, rl | l1r1 |
| l2 | l1l2 |
| r2 | r1r2 |

Full names still work. All these aliases work in each bank command below,
including both layer arguments of swap. Use `//xb bank <bank>` for status.
These are aliases following `bank`, not new root `//xb l` commands.

## Complete command reference

Replace `<bank>` with any full name or alias above. `<button>` accepts Left,
Down, Right, Up, Square, Cross, Circle, Triangle or a slot number 1–8.
`[menu]` selects alternate menu bindings; otherwise edits affect normal bindings.
Use `menuactions on` if the bank should switch to alternate menu bindings.

```text
//xb bank <bank> help
//xb bank <bank> status [details]
//xb bank <bank> edit [on|off]
//xb bank <bank> preview
//xb bank <bank> pos <x> <y>
//xb bank <bank> resetpos
//xb bank <bank> scale crossbar|<0.4-2>
//xb bank <bank> lock|unlock
//xb bank <bank> enable|disable
//xb bank <bank> show|hide
//xb bank <bank> display held|always
//xb bank <bank> menus on|off
//xb bank <bank> menuactions on|off
//xb bank <bank> cutscenes on|off
//xb bank <bank> [menu] <button> <label> <command...>
//xb bank <bank> [menu] key <button> <label> <key> [hold]
//xb bank <bank> [menu] append <button> <command...>
//xb bank <bank> [menu] clear <button>
//xb bank <bank> [menu] default <button>
//xb bank <bank> [menu] defaults
//xb bank swap <bank> <bank>
//xb bank preset cioara apply
```

`help` lists all bank commands. `show/hide` controls drawing, while
`enable/disable` controls bank input. `menus` controls drawing over native
menus; `menuactions` controls the alternate bindings. `cutscenes` is a retained
legacy preference: deliberate held banks already work during dialogue, subject
to existing ownership guards. `clear` reserves an empty slot, `default` restores
one shipped action, and `defaults` restores all eight in the selected context.
`append` extends an existing command binding. The explicit Cioara preset resets
L1/R1 and shoulder-trigger defaults; it leaves the combined bank unchanged.

Examples:

```text
//xb bank l edit
//xb bank r edit
//xb bank r edit
//xb bank lr cross Together input /echo Combined bank
//xb bank lr menu key up Previous alt+left
//xb bank swap l r
```

The first edit starts L1 editing; the second switches to R1; the third ends it.

## Install, verification and rollback

Back up the addon and data/companion_banks.xml, stop the wrapper and unload
XIVCrossbar on all clients, overlay the cumulative ZIP, then reload. It includes
all current v2 runtime/Lua files and workflow/testing documents, but no settings,
bindings, assets, generated shortcuts or runtime cache. Existing addon assets
are required. The PC's controller device 2 setting is preserved.

Local verification uses the Lua 5.4 runner with temporary Windower syntax
normalization. Tests cover shared movement/edge clamping, all aliases across
commands and both swap arguments, edit toggles and explicit idempotence, single
preview ownership, combined shoulder transitions, saved XML and prior behavior.
Native Windows/controller/FFXI acceptance remains pending; AHK is unchanged.

Live-check: preview each bank at the same anchor; toggle/edit/drag using l, r,
lr; verify one preview and correct feedback; reload and confirm the shared
position and bindings persist. Test both shoulder orders and return transitions.
Restore complete backed-up code plus companion_banks.xml together for rollback.
