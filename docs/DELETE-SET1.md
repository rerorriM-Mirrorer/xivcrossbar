# Delete Set 1 — November 2, 2026

```
//xb deleteset Trust
//xb deleteset "Switch"
//xb restoreset Trusts
```

Deletion first matches an exact saved key (case-insensitive), then a unique
shown label, then a generated-category alias. For example a set displayed as
Switch can have a key such as all-switch; it can now be deleted by its display
label. Trust also finds generated Trusts if no exact key/display label matched.
Ambiguous labels are rejected with the matching saved keys: choose the intended
key explicitly. No fuzzy deletion is used.

Deletion removes the entire selected set and its bindings through the existing
hotbar save/backups. Default, Job Default, All Jobs Default and Shared remain
protected. A failed load/login blocks deletion. Failed hotbar saving restores
the current in-memory set; existing multi-layer backups remain the recovery
mechanism if an underlying write failed partway through.

Generated category keys no longer immediately return. Their automatic creation
is disabled in config under HiddenCategorySets, scoped by server, character,
main and subjob. Other characters/job combinations are unaffected. No sets or
settings are deleted merely by installing this patch: state changes only when
you invoke the commands.

`//xb restoreset <category>` clears that disabled flag. Reload then creates the
category if the current jobs/learned spells allow it. Deleted bindings remain
deleted: use hotbar backups to recover those. An existing manually recreated set
is left intact even while automatic creation is disabled.

Current-job quick-switch references are counted and reported after deletion;
they are not automatically repaired or removed. Other job files and arbitrary
custom command strings are not scanned. Review links before consolidating sets.

If saving the config flag fails after the hotbar deletion succeeds, chat says
so explicitly; the category may return after settings are reloaded. Config and
hotbar files are separate saves, not a cross-file atomic transaction.

## Install and rollback

Apply after Trust and Sets 1 / Category Labels 1. Back up the five runtime files
supplied: xivcrossbar.lua, libs/defaults.lua, libs/player.lua,
libs/job_crossbars.lua and libs/set_names.lua (the last is new). Unload
xivcrossbar on every client, overlay the folder and load it again. No AHK, assets
or user data are supplied. Runtime suffix: 20261102.directlink1-ahkv2-deleteset1.

Code rollback restores backed-up files (remove the newly supplied set_names.lua
if desired). Restore relevant hotbar backups to undo actual deletions. Keeping
config suppression flags does not restore bindings; older code ignores them.

## Live checks pending

1. On a set you intend to remove, try deletion by its shown label and confirm
   the indicated saved key. Verify the correct set disappears after reload.
2. For an intentionally empty generated Trusts set, delete using Trust or Trusts;
   confirm it stays absent after reload and after logging back into this job.
3. Run restoreset Trusts; confirm an eligible empty category returns.
4. Confirm another character/job still has its normal generated categories.
5. Check active-set fallback, protected defaults and duplicate-label rejection.

Local tests exercise actual delete/restore handlers, category load/selection,
scoped persistence state and failure rollback. Native Windows/controller/FFXI
acceptance remains pending. No installed user sets were deleted during testing.
