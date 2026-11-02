# Trust and Sets 1 — November 2, 2026

## Trust summon and dismiss

A typed Trust magic slot summons its Trust when absent. While that named Trust
is in the current party/zone (NPC spawn type 14), it shows `Dismiss <name>` with
its portrait and sends `input /refa "<party name>"`. Unity `(UC)` spell names
match their shorter party names. Explicit custom artwork is retained; missing
portrait artwork falls back to the original spell icon. Actual execution
rechecks state. Dismissal stays on the current page, including quick-switch
pages, and ignores summon-spell MP/recast restrictions. The game still enforces
its own dismissal permissions and combat restrictions.

Unlearned Trust spells remain bindable via explicit commands/data and dim/block
with a short throttled notice when used. The regular learned-Trust picker keeps
its existing filtering. This batch does not distribute common Trust bindings.
Arbitrary custom macros remain unchanged. Existing avatar Release and pet
Assault/Retreat toggles are included.

## Quick binding commands

```
//xb l  <button> "Label" "Command"
//xb r  <button> "Label" "Command"
//xb ll <button> "Label" "Command"
//xb rr <button> "Label" "Command"
//xb lr <button> "Label" "Command"
//xb rl <button> "Label" "Command"
```

Example: `//xb r cross "Quick Test" "input /echo Hello"`.
Use controller button names such as `cross`, `square`, `up`, or slot names
`ll/ld/lr/lu/rl/rd/rr/ru` (d-pad then face positions), or numbers 1–8.
Quote the label and complete command. Commands retain Windower syntax exactly;
use `input /...` for in-game actions.

L/R select trigger banks 1/2; LL/RR select double taps 5/6 when available.
LR/RL share bank 3 with three or five banks; four/six banks retain distinct
ordered banks (RL=3, LR=4). Numeric IDs in explicit commands remain literal.
An unavailable bank/button or malformed arguments are rejected before writing.

Shorthand targets the currently selected crossbar set. It creates a GLOBAL
custom action with the supplied name/alias/command and basic gear icon, regardless
of the normal catalog save-scope preference. Repeating an identical shorthand
entry reuses its identity. A conflicting global label is rejected: choose a
new label or edit the existing catalog entry deliberately. Character-catalog
entries remain separate. The slot is attached to the reusable catalog identity.
Catalog creation precedes slot saving; a slot-save failure can leave the reusable
catalog entry available for a retry. Existing file locking/backups still apply.

Keep the explicit form for a named set:
`//xb set <set> <bar> <button> <type> "Action" [target] [alias] [icon]`.
This retains its existing behavior and does not create a catalog entry.

## Capability crossbar sets

| Capability | Default set key |
| --- | --- |
| White / Black / Blue Magic | white-magic / black-magic / blue-magic |
| Songs / Ninjutsu / Summoning / Geomancy | songs / ninjutsu / summoning / geomancy |
| Learned Trust magic | trusts |
| Job Abilities / Weapon Skills | job-abilities / weapon-skills |
| SMN | blood-pact-rage / blood-pact-ward / pet-commands |
| BST | ready / pet-commands |
| PUP / DRG | pet-commands |
| COR | phantom-rolls / quick-draw |
| SCH / DNC | stratagems / dances |
| RUN | rune-enchantments / wards / effusions |

Magic capabilities follow main/subjob resource levels (individual spells need
not already be learned to make the category available). Trusts require at least
one learned eligible Trust. Categories are added only if their key is absent;
existing names and slots are retained. Sets start with ordinary slot inheritance
and can contain any action type. They are generated in memory on load, then
persist through ordinary binding/saving using existing XML scope rules. Saved
sets remain editable even if the current job no longer grants their category.
Deleting/renaming a generated category key allows the default to reappear on reload.

Open the set chooser or use `//xb bar white-magic` (substitute a listed key).
In the binder, choose Switch Crossbars or Quick XB Switch to bind a destination
with its existing category artwork. No switches are automatically placed onto
your existing bars: individual slot placement and shared Trust positions remain
for the later binding review. Inventory stays on All Jobs Default.

## Install, rollback and live checks

Use the current personal AHK v2/Pet Actions 1 installation with existing assets.
The Lua-only overlay includes previous pet/summon toggles and Pact Binding 1.
Back up the eleven supplied runtime files, unload xivcrossbar on every client,
overlay the folder, then load it again. Keep installed AHK files and data; no
wrapper restart is required. Runtime suffix: `20261102.directlink1-ahkv2-trustsets1`.
To roll back, restore backed-up Lua files and reload. New catalog/binding edits
are saved data; restore the relevant catalog/hotbar backups to undo those edits.

1. Bind a learned Trust through the normal picker. Summon/dismiss it using the
   same slot; check portrait, caption, named dismissal and page retention.
2. Check zero MP and summon recast do not dim/block dismissal. An absent,
   unlearned Trust should dim/block with one short notice on press.
3. Check a Unity Trust, an II variant, party departure, zoning and reload.
4. On a disposable slot, try the shorthand above, repeat it on another slot,
   and verify one global gear action. Try a conflicting command under the same
   label: the conflict should leave the catalog and destination slot unchanged.
5. Check LR/RL shared behavior in three/five banks and distinct behavior in
   four/six, plus unavailable double taps in smaller configurations.
6. On current main/subjobs, inspect category sets, switch to them, and bind an
   unrelated action. Existing layouts and inventory positions should remain.
7. Verify avatar Release, Assault/Retreat and Blood Pact lists still work.

Local dispatch/render, catalog routing, chooser and load/rollback regressions
supplement these steps. Native Windows/controller/FFXI acceptance is pending.
