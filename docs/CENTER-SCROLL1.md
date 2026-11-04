# Center and Scroll 1

Personal development/ahk-v2-migration patch over Summon Swap 1 (e09c04c). Copy the included xivcrossbar files over the existing addon, then reload xivcrossbar. Retain data, custom artwork and newer Trust/AHK files.

## Centering

Run `//xb center on` (or bare `//xb center`). The main bars center horizontally while retaining their vertical offset. All companion bank modes use the centered panel above the main slot footprint with a 12 scaled-pixel gap. The command now reports its state; `//xb status` shows Main and Companion centering separately.

The earlier implementation wrote the flag into companion bank storage but read it from main style settings while rendering. This explains the reported unchanged L1 position. Both views now read the actual separate bank state, and screen-boundary clamping does not disable centering. The main renderer also receives its centering mode explicitly through setup/movement. No saved coordinates are replaced while centered.

`//xb center off` uses the saved offsets/anchor. Main dragging/pos disables main centering; companion dragging/pos disables companion centering. `center on` restores both. Bank-save failure is reported.

## R1 native-menu scrolling

| R1 + D-pad | Native key | Function |
| --- | --- | --- |
| Up | Ctrl+Left | Ten items up |
| Down | Ctrl+Right | Ten items down |
| Left | Alt+Left | Previous item list |
| Right | Alt+Right | Next item list |

This applies while a native menu is open and R1 Menu Actions is on. The existing all-native-menus policy remains, including NPC menus. Held keys release on button release or menu closure.

Inherited defaults update immediately. Exact saved Fast Up/Down defaults using Ctrl+Up/Down without custom icons adopt the corrected defaults once. Custom aliases, keys, commands and icons remain authoritative; later explicit edits are preserved across reload. No R1 face changes or L1 Trust Menu move are included: the proposed R1 Cross NPC interaction / Triangle Trust Menu layout awaits the single-command NPCMirror work.

## Live acceptance

After reload, run center on and hold L1/R1: both companion modes should appear at the same horizontal center above the main bars. Check compact/alternate layout and your scale. Use center off/on and check manual dragging plus reload. No Windows/in-game acceptance is claimed by local tests.

Open an inventory/item list; hold R1 and test Up/Down ten-item jumps and Left/Right list changes. Release each key and close the menu during a hold; check no stuck modifiers. Retest your existing face/custom bindings. The latest Return/summon replacement changes remain included in the branch.
