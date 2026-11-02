# Pet Toggle 1 — November 2, 2026

Either typed `pet` Assault or Retreat binding serves as the same toggle:

| Living avatar/spirit state | Display and press |
| --- | --- |
| Idle | Assault, using the existing enemy selector or `<t>` for a saved Retreat slot |
| Engaged | Retreat, targeting `<me>` |
| Missing/dead | Dimmed and blocked with the existing short notice |

Pet status drives this, independently of player engagement. Standard captions
and artwork follow the effective command; explicit custom labels/icons remain.
Saved XML is unchanged. The separate Attack/Disengage action retains its existing
player-plus-summon behavior; the pet toggle sends only its pet command.
Arbitrary custom macros, BST Fight/Heel and PUP commands are unchanged.
Summon-to-Release and per-Trust `/refa` toggles are later batches.

## Install

Use on the current personal AHK v2 installation with Pet Actions 1. Back up the
four supplied runtime files. Unload xivcrossbar on every client, overlay the
`xivcrossbar` folder into the installed addon, then load it again. Existing
assets and dependencies are required. No AHK files are supplied: preserve the
newer Trust movement/leadership integration already installed. No wrapper
restart or saved-data replacement is required. Restore the backed-up Lua files
and reload to roll back.

The ZIP contains four Lua runtime files and documentation only. Runtime suffix:
`20261102.directlink1-ahkv2-pettoggle1`. Its manifest records the source commit.

## Live acceptance pending

1. On an existing typed Retreat slot (Cioara’s SMN default layout has one),
   summon Carbuncle: confirm Assault caption/artwork and successful targeting.
2. Once the pet engages, confirm Retreat caption/artwork and that pressing it
   recalls the pet. Confirm it returns to Assault after actual disengagement.
3. Check pet and player can be in different combat states without confusing
   the toggle. Verify an existing typed Assault slot behaves identically.
4. Release/lose the pet: confirm dimming, no command and the short notice.
5. Switch pages/banks and reload: confirm correct caption and no stale icon.
   Verify custom labels/icons and ordinary macros remain usable.

Local dispatch/render regressions and layout checks supplement these checks;
no Windows/controller/FFXI acceptance is claimed.
