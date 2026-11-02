# Summon Toggle 1 — November 2, 2026

A typed summoning spell slot (for example Carbuncle) becomes `/pet "Release" <me>`
while that same living avatar/spirit is out. Its caption/artwork become Release.
After dismissal/death, the saved summon spell, label, custom icon and target
return. Slots for other summons remain summoning spells. Name matching ignores
case, spaces and punctuation. Trust spells, BST/PUP commands and arbitrary
custom macro text are unchanged.

Release stays on the current crossbar, including temporary quick-switch pages.
It uses Release's own recast rather than inheriting summon-spell MP cost or
cooldown. Press-time dispatch checks live state; XML is never rewritten.

## Install and rollback

This Lua-only overlay applies to the current personal AHK v2/Pet Actions 1
installation and includes Pet Toggle 1. Existing assets/dependencies are required.
Back up the four supplied runtime files; unload xivcrossbar on all clients,
overlay the `xivcrossbar` folder into the installed addon, then load it again.
Preserve installed AHK files, including the newer Trust leadership/movement
integration. No AHK files or saved data are supplied. No wrapper restart is
needed. Restore the four backed-up Lua files and reload to roll back.

Runtime suffix: `20261102.directlink1-ahkv2-summontoggle1`. The package manifest
identifies its published source commit and file checksums.

## Live checks pending

1. With no pet, use a typed Carbuncle slot: confirm ordinary summoning.
2. Once Carbuncle appears, confirm that slot shows Release. Other summon slots
   must retain their own spells. Press Release: confirm dismissal with no page
   return; the slot should restore its original summon and custom presentation.
3. Repeat while engaged, at low/zero MP and while the summon spell is on recast.
   Release should remain independent of the spell's cost/cooldown.
4. Summon another avatar: Carbuncle's slot stays Carbuncle. Repeat the toggle
   with an elemental spirit and with a summon whose name contains spaces.
5. Check pet death, page/bank changes and addon reload for stale labels/dimming.
   Verify Assault/Retreat still follows pet engagement and ordinary macros work.

Local tests exercise actual dispatch/render paths, zero-MP and recast transitions,
quick-page retention and saved-action immutability. They are not live acceptance.
Per-Trust `/refa` toggles and shared Trust placement are a subsequent batch.
