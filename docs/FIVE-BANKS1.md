# Five Banks 1 — November 1, 2026

Personal development/ahk-v2-migration, starting local source
91b768f4a743cdbe8264e96dd881384934915678. Runtime suffix
`directlink1-ahkv2-fivebanks1`. Publication status is in the handoff.

## Choose five banks

Unload XIVCrossbar on all clients before editing data/settings.xml. Change the
existing Hotbar/Number setting in the applicable character section (or the global
section when the character inherits it) to 5, then load the addon again:

```xml
<Hotbar>
    <Number>5</Number>
</Hotbar>
```

This is an excerpt: edit the existing Number value, preserving all other fields.
A character-specific value overrides the global value. Default remains 6; the
package does not change your saved count or supply a settings file.

| Input | Saved bank in five-bank mode |
| --- | --- |
| L2 | 1 |
| R2 | 2 |
| Both triggers, either order | 3 |
| Double L2, hold second press | 5 |
| Double R2, hold second press | 6 |

The action binder selects these same IDs. Its combined hint uses a plus rather
than an ordered arrow. Trigger-name command aliases L2R2/LR and R2L2/RL both
address bank 3 in this mode. LL/L2L2 and RR/R2R2 remain banks 5 and 6.

## Changing the count does not split, copy or merge saved actions

| Configured count | R2 then L2 | L2 then R2 | Double L2 | Double R2 |
| --- | --- | --- | --- | --- |
| 3 | 3 | 3 | 1 | 2 |
| 4 | 3 | 4 | 1 | 2 |
| 5 | 3 | 3 | 5 | 6 |
| 6 | 3 | 4 | 5 | 6 |

For 3 -> 4, the old shared bindings remain in bank 3, while L2 then R2 selects
bank 4. It uses any saved bank-4 actions or applicable inherited defaults;
otherwise it is empty. No automatic duplication happens.

For 6 -> 5, bank 4 is retained in the saved XML but is not selected/drawn by
normal controller input. Switching back to 4 or 6 exposes it again. Double-tap
bank IDs stay 5/6, preserving existing assignments. Numeric command IDs remain
literal, so explicit commands can still maintain a retained bank 4. Internally,
five-bank mode allocates capacity for six stable IDs and suppresses bank 4;
this does not turn the saved Number setting into 6 or renumber any actions.
L1/R1 companion-bank aliases follow their own bank command namespace.

## Install and test

Back up the addon and settings, stop the wrapper, unload XIVCrossbar on all
clients, overlay this cumulative personal v2 ZIP, set Number to 5 while unloaded,
then load again. Includes Shoulder Banks 2 shared positioning/edit toggle/aliases
and the full coherent v2 runtime. No assets, character bindings, data/settings,
caches or machine-specific shortcuts are supplied. Existing assets required.
AHK/controller startup and polling are unchanged; device 2 selection is retained.

Local tests exercise actual DirectLink receiver/root routing for counts 3/4/5/6,
both trigger orders, both double-taps, actual binder selection and hints, command
alias mode roundtrips, retained numeric IDs and complete renderer hiding of bank 4.
Compact geometry is tested for 144 scenarios across six resolutions, three scales,
counts 2/4/5/6 and both layout modes. These are local Lua 5.4 checks with temporary
Windower string-method normalization, not native Windows/FFXI execution.

Live-check: use an echo in shared bank 3 and distinct echoes in double-tap banks;
confirm both trigger orders give the same shared action, both double-taps select
their own actions, and the binder edits those exact banks. Check compact/full
layouts, held/release transitions and focus/menu behavior. Switch 5 -> 6 and
confirm bank 4 and all existing bindings remain intact, then return to 5.

Rollback by stopping/unloading, restoring the complete backed-up code and
settings together, and reloading. Do not mix v1/v2 include sets.
