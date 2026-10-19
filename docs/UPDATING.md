# Updating and copying bank positions

## Cleanup 1 cumulative update

Runtime: `0.4.0-a.20261019.directlink1-cleanup1`; unchanged Controls 9.10-holdfix.
This code-only ZIP contains all current installable code, not a sequence of delta
patches. It works over an existing complete DirectLink installation and recognizes
its old image paths. New installations require a complete package with artwork.
PACKAGE-INFO.txt records the exact source checkpoint and package kind.

1. Unload XIVCrossbar in **all clients** and back up the addon folder.
2. Merge the ZIP into the addons directory, replacing code. Avoid a nested
   xivcrossbar/xivcrossbar folder. Keep data/, config.ini and existing images.
3. To finish the physical folder cleanup, double-click `finish-cleanup.bat` in
   xivcrossbar. It moves existing artwork to the canonical folders, removes
   identical duplicates and backs up modified retired Lua modules. It can be
   rerun. For a non-writing preview, run `tools/Finish-Cleanup.ps1 -Preview` in
   PowerShell. The helper requires Windows PowerShell; native execution remains
   part of live acceptance. If skipped/stopped, legacy asset paths still work.
4. Load XIVCrossbar. Bank settings migrate automatically for every saved character.
   Check `//xb inputstatus` for the runtime above, then `//xb status` for the bank
   storage path and character. Test one character's banks before loading the rest.

Bank Layout/Hold Recovery users only need Lua reloaded; this batch changes no
AHK behavior. Older wrappers still need Controls 9.10-holdfix for the previously
delivered hold-recovery feature (see HOLD-RECOVERY.md).

The folder helper moves differing legacy art into `images/overrides/`, which
wins over stock artwork. If two different custom overrides already exist, it
keeps both and reports the conflict. Modified retired root Lua modules go to
`data/cleanup-backup/<timestamp>/`; their code is preserved for review, not
silently merged into the new modules. The helper does not edit personal settings.

## Bank settings and recovery

All bank commands, visibility/menu policies, titles, old L1 editor data and the
left/right panel geometries now save in `data/companion_banks.xml`. The global
section supplies defaults; character sections store differences. Main fonts,
main scaling and main crossbar positions remain in `data/settings.xml`.

The first migration imports all existing global/character bank data before
removing the old bank sections from the main file. Unrelated main settings bytes
are preserved. The original is retained at
`data/settings.xml.before-bank-cleanup.bak`. Later bank saves retain the previous
bank file at `data/companion_banks.xml.bak` and use the existing atomic Windows
replacement/lock backend. Interrupted `.pending` files remain recovery input.
Failed/invalid/newer files are reported and are not overwritten. A hand-created
partial bank file without the import-complete marker does not authorize deleting
unimported legacy sections.

Once migrated, edit the separate bank file or use the existing `//xb bank ...`
commands. Old sections are recovery input, not a second live settings source.
Unload before hand-editing XML. Never ship another character's entire settings
file just to copy positions. To downgrade, unload all clients and restore the
backed-up addon/settings together; the pre-migration backup does not contain bank
edits made after migration. Keep the current bank file too.

## Current folders

| Location | Purpose |
| --- | --- |
| xivcrossbar.lua | Addon entry point |
| libs/banks/ | Bank ownership, persistence, native output and legacy compatibility |
| libs/controller/ | Lua controller transport, routing and profiles |
| libs/ | Player/storage/actions and supporting logic |
| ui/ | Crossbar, banks, chooser, binder, geometry and asset resolver |
| images/icons/default/ | Default named icon pack |
| images/icons/default/fallback/ | Numeric resource/category fallback icons |
| images/icons/<pack>/ | Alternate icon packs |
| images/themes/ | Frame, slot and battle-notice themes |
| images/overrides/ | Preserved custom artwork that wins over shipped art |
| images/assets/, images/setup/, images/credit_avatars/ | Structural menu/setup/credit art; paths retained |
| resources/ | Windower-generated spell/ability metadata; existing cache paths retained |
| docs/, tests/, packaging/, examples/, tools/ | Documentation, regressions, package builders, templates and utilities |

The shared AHK wrapper and its includes remain at the root to preserve startup
and include paths. Legacy Lua require names resolve through a bootstrap alias
map; internal code uses canonical paths. Saved custom icons and generated
resource metadata using old image paths remain valid through ui/assets.lua.
The icon chooser scans canonical, override and legacy pack locations, deduplicates
stems and includes fallback icons.

## Copy Cioara's positions without replacing bindings

From the supplied settings(20261019-212625).xml, the `cioara` section stores:

| Setting | X | Y |
| --- | ---: | ---: |
| CompanionBanks.LeftPanel | 1657 | 1669 |
| CompanionBanks.RightPanel | 1957 | 1675 |
| Style offsets (main crossbars) | 35 | -146 |

Run in each destination client's chat:

```text
//xb bank l1 pos 1657 1669
//xb bank r1 pos 1957 1675
```

L1 and L1L2 share LeftPanel; R1 and R1R2 share RightPanel. These two commands
cover all four banks and save the positions without modifying commands or
visibility. The main crossbars are separate; to copy those too:

```text
//xb pos 35 -146
```

Panel scale inherits global FollowCrossbar=true in this attachment. Match the
main CrossbarScale (1 in the supplied global section), client UI resolution and
Style spacing for matching visual placement. Positions are absolute UI pixels;
smaller clients clamp them to the visible area. Run `//xb bank l1 status` and
`//xb bank r1 status` for current panel values; `//xb pos` prints main offsets.
Do not copy the entire settings file: it includes per-character bank commands
and unrelated preferences. For mouse-only adjustment use `//xb bank l1 edit on`
or `//xb bank r1 edit on`, then the matching `edit off` after dragging.
