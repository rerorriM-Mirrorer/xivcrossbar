# Bank Faces 1

Lua-only patch over Center and Scroll 1 (8b2ef04), development/ahk-v2-migration. Copy the included xivcrossbar files over the addon and reload. Preserve data, artwork and newer Trust/AHK files.

Factory defaults and explicit Cioara preset now use these face bindings in both Closed and Menu contexts:

| Button | Label | Command |
| --- | --- | --- |
| R1 Cross | NPC | npc |
| R1 Square | Target | npc target |
| R1 Triangle | Menu | trust menu |
| L1 Triangle | empty | empty |

R1 Circle remains npc cancel. All D-pad entries, L1 Down and other L1 faces remain as before, including native-menu scrolling. No Follow/Stay/Mount or broad clearing is included. Custom saved bindings remain authoritative; installation does not rewrite data or automatically apply the Cioara preset.

To adopt only these four slots on an existing character with explicit saved entries:

```text
//xb bank r default cross
//xb bank r default square
//xb bank r default triangle
//xb bank l default triangle
```

For explicit Menu-context overrides, repeat with menu before default:

```text
//xb bank r menu default cross
//xb bank r menu default square
//xb bank r menu default triangle
//xb bank l menu default triangle
```

NPCMirror t31 development documentation verifies bare npc/interact are one-press interaction, while npc target only acquires/shares the NPC without opening it. Use the matching current NPCMirror build for those behaviors. No NPCMirror changes are shipped.

Local checks cover actual physical face routing, preset/default contexts, saved custom/cleared preservation, native menus and cutscene guards. These use mocked observations in Lua 5.4 with temporary Windower syntax normalization. Live FFXI acceptance remains: verify R1 Cross opens/interacts, Square only targets, Triangle toggles personal Trust menu, and L1 Triangle is empty after selective adoption. Retest unchanged scrolling, Cancel and positioning.
