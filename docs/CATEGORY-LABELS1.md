# Category Labels 1 — November 2, 2026

| Display label | Stable saved key | Artwork |
| --- | --- | --- |
| Weaponskill | weapon-skills | Main-menu sword icon, same chooser inset |
| Job Ability | job-abilities | Main-menu ability icon, same chooser inset |
| Rage | blood-pact-rage | Main-menu SMN icon |
| Ward | blood-pact-ward | Main-menu SMN icon |
| Pet | pet-commands | Existing Pet Command crab icon |

Summoning, White Magic, Trusts and other categories retain their existing
presentation. Legacy Weaponskill/Job Ability image paths intentionally go
through the same shared asset resolver as the main menu, including overrides.

On reload, only exact previous generated labels are corrected. Stable keys and
all slot data remain; customized labels and separate existing sets are preserved.
This also corrects saved category labels when their capability is not currently
active. Ordinary future saves persist corrected labels. Existing manually bound
shortcut aliases/artwork remain their saved values; newly selected category
switches get the corrected labels/artwork. Rebind/change those shortcuts during
the later layout review if needed.

## Delete or consolidate

The existing command is `//xb deleteset "Old Utility"` (or its actual saved key).
It removes that entire set and its bindings from the currently loaded layers.
Default, Job Default, All Jobs Default and Shared are protected. Display labels
may differ from saved keys: use the actual key when they do. The command warns
about quick-switch references, rather than repairing every referencing action
or every job's files automatically.

Generated capability keys are recreated on reload while eligible. This patch
does not change that behavior or add permanent category suppression. Do not use
deletion as the first consolidation step. Review current data per character,
choose the set to retain, transfer wanted bindings and update all switch links,
then remove redundant sets deliberately. The previous data snapshot predates
recent in-game edits and is not authoritative for deleting current sets.

No sets are merged or deleted by this update. No current character XML or
custom icons are shipped/replaced.

## Install and verify

Apply after Trust and Sets 1. Back up libs/job_crossbars.lua,
ui/action_binder.lua and xivcrossbar.lua. Unload xivcrossbar on all clients,
overlay the supplied folder and reload. AHK, assets and data stay in place;
no wrapper restart is needed. Runtime suffix:
`20261102.directlink1-ahkv2-categorylabels1`.

Restore those three backed-up runtime files and reload for code rollback.
The label correction is in memory until an ordinary save; retain hotbar backups
if you want to undo a subsequently saved label change.

Check the set chooser and Switch Crossbars/Quick XB Switch picker. Confirm the
five corrected names, menu-matching icons, unchanged custom names/slots and
unchanged Summoning/White Magic/Trusts. Duplicate sets remain for the later
per-character review. Local chooser/load/save regressions pass; live acceptance
of the correction remains pending.
