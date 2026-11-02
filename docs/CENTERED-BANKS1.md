# Centered Banks 1 — November 2, 2026

Lua-only patch for the personal development/ahk-v2-migration branch, based on L1 Party 1 (89d0947). Copy the included xivcrossbar files over the existing addon, retaining data and newer Trust/AHK files, then reload xivcrossbar. WORKFLOW.md and TESTING.md travel inside the addon folder.

Main bars center their actual left/right slot span at the current scale and layout. Their saved vertical offset remains effective. Companion banks share a centered panel above the main slot footprint with a 12 scaled-pixel gap. Saved X/Y values remain available. No character/job sets or slot files are replaced. No unused bank is enabled.

`//xb center on` enables both centered modes; `//xb center off` returns to saved positions. Main `//xb pos x y` or dragging switches that component to manual positioning. Companion position commands/dragging switch the companion group to manual positioning. Existing linked-panel movement behavior remains.

Factory L1 faces: Cross **Ready** (`trust ready`, assist artwork), Circle **Stand Down** (`trust standdown`, red disengage artwork), Square **Toggle** (`trust toggle`, return-trust artwork), Triangle **Menu** (`trust menu`, red custom-actions gear). Explicit Icon overrides retain precedence. Latest Trust owns the commands and acknowledgments; no wrapper/AHK or stick transport changes.

Saved explicit bindings and labels remain authoritative. To deliberately adopt just these four closed-context factory slots:

```text
//xb bank l default cross
//xb bank l default circle
//xb bank l default square
//xb bank l default triangle
```

If using separate L1 Menu bindings, selectively adopt a face there with `//xb bank l menu default cross` (and circle/square/triangle). Do not apply the broad Cioara preset merely to update these four slots.

R1 factory Menu directions are Left Alt+Left, Right Alt+Right, Up Ctrl+Up, Down Ctrl+Down, held until released. As explicitly selected, this uses the existing native-menu-open signal, including NPC menus; item-only detection is not claimed. Face entries and closed-context directions remain unchanged. Fresh R1 banks and an explicitly applied Cioara preset enable Menu Actions. Per your follow-up, existing R1 Menu Actions is enabled once on adoption too; later explicit off remains respected. Exact old factory raw-direction Menu entries without custom icons adopt the new defaults once; custom Menu bindings stay untouched. The manual command remains:

```text
//xb bank r menuactions on
```

If its Menu directions are explicitly saved rather than inherited, reset only the intended direction, for example `//xb bank r menu default left`; repeat right/up/down as desired. Avoid broad defaults/preset commands when retaining custom slots.

## Verification and live acceptance

Local Lua 5.4 harness normalizes inherited Windower string-method syntax temporarily. Real UI geometry matrix covers six resolutions, three scales, normal/alternate layouts and multiple bar counts, preserving saved offsets. Bank checks cover chords releasing on button release/menu close and preservation of explicit policy/custom entries. This is simulated/static validation, not in-game or Windows acceptance.

In game: compare main/companion horizontal centers; retain the desired main height; check all held bank modes overlap; check custom artwork and untouched bindings; test R1 list cycling/fast scrolling and release after menu closure; verify Ready/Stand Down/Toggle/Menu with current Trust; verify ordinary sticks remain known-good. Test manual dragging and center on/off recovery.
