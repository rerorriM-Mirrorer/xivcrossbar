# XIVCrossbar NPC Owned Input 1 — t33 companion test

**Requires NPCMirror 0.1.4-t33** for the new owner route. Keep current controller `data/` and user saved bank bindings. This patch overlays `xivcrossbar.lua`, `libs/controller/personal_controls.lua`, and new `libs/controller/npc_actions.lua`. The rest of the working XIVCrossbar tree remains installed.

## Why this change exists

A native physical Cross can have **different owners**: bare native dialogue confirm versus R1+Cross bank `npc`, L1 face shortcut, or other menu/trust control. NPCMirror's previous second decoder interpreted the raw `buttons1` file independently. That was redundant and could disagree during fresh stream attachment, lost modifier state, or context transitions.

XIVCrossbar already owns this decision in `companion_banks:edge`. After that call completes, t33 emits `npc controller edge enter|esc <seq> <button_token>` to the **local** NPCMirror only when (a) the bank assigned `ordinary` ownership, (b) button is fresh physical Cross/Circle down, and (c) active game context is cutscene. No new native key action is sent by this marker; the existing ordinary pipeline continues to control the game. A saved R1 Cross `npc` command, native R1 menu key, and any L1 controls never become the marker.

`libs/controller/personal_controls.lua` adds `npc_owner=xivcrossbar` to the fresh per-character input lease only while DirectLink button-message mode is active. NPCMirror validates local name, fresh lease timestamp and exact `button_token`, suppresses its raw edge parser, and accepts each resulting sequence at most once. When the marker is unavailable, NPCMirror falls back to its older raw observer. This does not alter AHK source, native Enter delivery, R1 bindings, menu scrolling, controller display or user XML.

## Testing

Install matching t33 NPCMirror on each client first or together. On a Signet NPC or other normal NPC, press **R1+Cross once** to execute `//npc`; do not press R1+Cross again for dialogue. Then use **bare Cross**. Expect only bare Cross to cause NPCMirror follower Enter, and full native choice to follow when menus match. `//npc controller status` should show `source=XIVCrossbar-owned` with a current extended controller lease. Test R1+Circle and R1+Square too: neither is a bare Cancel/Enter.

The new `tests/npc_actions.lua`, lease, controller-message and bank-cutscene regressions run in CI under Lua 5.1 or 5.4 as appropriate; **this is not Windows hardware/FFXI acceptance**. The separate AHK v2 wrapper and physical controller have not been changed or live-tested by this patch.

Rollback: restore previous `xivcrossbar.lua` and `libs/controller/personal_controls.lua` files and keep `libs/controller/npc_actions.lua` unused, or restore the entire known-good XIVCrossbar folder. No saved settings need changing; restore NPCMirror as a matching package if necessary.
