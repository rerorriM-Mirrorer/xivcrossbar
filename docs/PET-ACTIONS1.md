# Pet Actions 1 — November 1, 2026

Personal development/ahk-v2-migration, starting local source
12493807cb776d80a39f98d6a123ed053b2f4456. Runtime suffix
`directlink1-ahkv2-petactions1`. Publication status is in the handoff.

## Behavior

Typed pet commands and pet-dependent generated abilities dim when their required
pet is absent or has zero HP. Pressing one is blocked before command dispatch
and before any temporary-page return. A short yellow tagged message explains
that no pet/avatar is summoned, throttled for repeated presses. Ordinary summon
spells and pet-producing job abilities remain available.

The shared policy covers type=pet commands, generated pet command metadata,
BST Ready-category abilities, and SMN Blood Pact categories. Blood Pacts and
Avatar's Favor require a recognized avatar. Release/Assault/Retreat accept a
recognized avatar or elemental spirit. Other typed pet commands require a living
pet. Existing summoned names are recognized without changing jobs, settings or
labels. This checks presence/type, not every level, pact availability, animation,
range, target, or other in-game restriction. Those existing game checks remain.

Render availability and button dispatch use the same predicate. Render samples
pet/player state once per recast pass; dispatch samples again at press time.
Pet recovery restores normal brightness only when MP/TP, cooldown and warmup
states allow it. It does not reset a Blood Pact recast.

Release no longer forces Basic (displayed as Main), and a Release press on a
temporary quick-switch page also stays on that page. The normal temporary-page
return for other actions and summon-to-avatar-page behavior remain.

With a recognized avatar or elemental spirit summoned, the ordinary Attack
binding now sends Assault followed by Attack On. While engaged, the same
binding's Disengage behavior sends Retreat followed by Attack Off. Current
status comes from the live player state. Concrete current target <t>, battle
target <bt> and numeric targets are supported. The existing labels/icons stay
unchanged, including the normal Attack/Disengage toggle.

Selector-style targets such as <stnpc> retain their ordinary single attack
command for this trial: sending Assault immediately would run before the user
confirms a selection. No automatic retry or delayed companion action is queued.
Without a summon, including with a BST pet or wyvern, the existing player attack
behavior remains. Typed pet controls such as standalone Assault retain their own
normal commands. Arbitrary custom/ex/ct macro text is not parsed or rewritten;
linked display metadata alone does not impose a pet requirement on a macro.

## Install and test

Back up the addon, stop the wrapper and unload XIVCrossbar on all clients,
overlay the cumulative ZIP, then reload. Existing addon assets are required.
The package includes Five Banks 1 and Shoulder Banks 2 plus the full coherent
AHK v2 runtime/Lua closure. It supplies no settings, character bindings, icons,
caches or machine-specific shortcut. The saved bank count and controller device
selection are preserved. AHK/startup/polling are unchanged.

Live checks:

1. With no pet, check Release/Assault/Retreat and actual Blood Pact slots dim.
   Press each: no pet command or page return; one concise explanatory notice.
   Summoning spells must remain usable.
2. Summon an avatar: check slots recover except for existing cooldown/MP/TP
   restrictions. Use Attack on a concrete target: verify avatar Assault and
   player engagement both happen. Use Disengage: verify Retreat and disengagement.
3. Use Release from an avatar/temporary page: verify the page stays selected.
   Check dimming after the pet disappears, and recovery after another summon.
4. With an elemental spirit, Release/Assault/Retreat remain usable but actual
   avatar Blood Pacts remain dim. With a non-SMN pet, ordinary pet controls work
   while the player's Attack retains its previous behavior.
5. Check normal actions, custom macros, target selectors, recasts, page switching,
   focus changes and existing five-bank/companion behavior.

Local tests execute the actual dispatch and rendering methods with controlled
Windower state. They cover absent/dead/avatar/spirit/BST pets, summon exceptions,
blocked dispatch, repeated notice suppression, both Release return paths,
Attack/Disengage command pairs, selector/custom exceptions and ordinary temporary
returns. Full renderer tests cover no-pet dimming, recovery, spirit/avatar
requirements, retained recast dimming and slot replacement. The render fixture
initially used normalized keys against an identity-name mock; correcting fixture
metadata restored the intended real recast branch. No runtime change was made to
satisfy that fixture mismatch.

These are local Lua 5.4 tests with temporary Windower syntax normalization, not
native Windows, physical-controller or FFXI execution. Command submission is
verified; the game accepting both members of a combat pair remains a live check.

Rollback: stop/unload and restore the complete backed-up code, then reload.
No binding migration was performed. Restore a coherent v2 include set.
