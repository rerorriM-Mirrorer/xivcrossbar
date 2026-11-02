# Pact Binding 1 — November 2, 2026

Blood Pact: Rage/Ward selectors list pacts at or below the current main/sub SMN
level for learned, level-eligible avatar spells. No pet needs to be out, and
Astral Flow need not be active merely to bind its pact. The summon spell chooser
already uses learned spells/job levels rather than the active pet; its JP lookup
now tolerates missing job-point data.

Binding eligibility does not promise immediate execution: the appropriate pet,
MP, recast, Astral Flow, merits or JP gifts may still be required by the game.
The level catalog deliberately describes binding levels, not all execution
unlocks. Wyvern breaths and unrelated pet abilities are not added to SMN lists.

The console's repeated errors at skillchains.lua lines 119 and 251 follow
Searing Light publishing nil skillchain properties. Elemental-only attacks now
leave resonance unchanged. Missing/unknown property lists are safe, and normal
skillchains, burst hints and Chainbound formatting retain their behavior.

## Installation

Use on the current personal AHK v2 installation with Pet Actions 1 and existing
assets. This Lua-only overlay includes Pet Toggle 1 and Summon Toggle 1. Back up
the eight supplied runtime files; unload xivcrossbar on all clients, overlay the
folder, then load it again. Keep installed AHK files and data. No wrapper restart
is required. Restore the eight backed-up files and reload for rollback.
Runtime suffix: `20261102.directlink1-ahkv2-pactbinding1`.

## Live checks pending

1. Without any summon, open both Blood Pact binding lists: confirm your learned
   avatars' level-eligible pacts, including Searing Light for Carbuncle.
2. Summon/dismiss/change avatars and reopen: the binding lists should stay the
   same. Verify unlearned summons and above-level pacts stay absent.
3. Check the summoning spell binding list with and without a pet. Existing
   matching-summon-to-Release slot behavior is retained.
4. Use Searing Light with Astral Flow: confirm no repeated skillchain errors.
   Then check an ordinary physical skillchain and a magic-burst hint.
5. Without a pet, bound Blood Pacts still dim/block; check Assault/Retreat and
   summon/Release toggles and page retention remain correct.

## Catalog sources

- Windower resource IDs/names/categories: https://github.com/Windower/Resources/blob/master/resources_data/job_abilities.lua
- SMN binding levels: https://github.com/LandSandBoat/server/blob/base/sql/abilities.sql
- Siren Ward levels: official February 12, 2020 update, https://forum.square-enix.com/ffxi/threads/56444-February-12-2020-%28JST%29-Version-Update
- Additional level-99 entries Pacifying Ruby and Regal Gash supplement the
  server table. Unmapped/new resource IDs are omitted until cataloged.

Local regression tests simulate actual chooser and tracker paths. Windows,
controller and FFXI acceptance remain pending. Per-Trust dismissal is deferred.
