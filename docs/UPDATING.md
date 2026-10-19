# Updating and copying bank positions

## Cumulative code update

The Hint Cleanup 1 code-only ZIP contains all current installable code, including
the earlier Banks, Hold Recovery and Bank Layout work. Apply this one archive
over an existing complete DirectLink installation; earlier code patches are not
needed. It omits PNG/JPG images (including theme artwork), not runtime Lua/AHK.
It cannot supply a fresh installation or repair missing art. Complete packages
remain available through the same builder without --no-images.

1. Unload xivcrossbar. Back up the current addon folder.
2. Extract/merge the ZIP into the addons directory so xivcrossbar/ui.lua replaces
   the existing file. Avoid a nested xivcrossbar/xivcrossbar directory.
3. Keep existing data/, config.ini, images/ and themes/ content. The archive
   contains no personal settings or ordinary crossbar XML.
4. Load xivcrossbar. `//xb inputstatus` reports runtime
   `0.4.0-a.20261019.directlink1-hintfix1`. PACKAGE-INFO.txt records the exact
   source commit, tree, package kind and wrapper version. A ZIP copied to disk
   without reloading does not change the running version.

From Bank Layout 1 or Hold Recovery 1, Lua reload is sufficient. Older wrappers
must be updated/restarted to Controls 9.10-holdfix for the previously delivered
hold recovery; see HOLD-RECOVERY.md. This hint fix does not change the wrapper.
Never replace a newer build with an older cumulative archive.

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

## Next cleanup, with compatibility preserved

Bank settings should have their own `data/companion_banks.xml`: definitions,
Closed/Menu bindings, policies, titles and the two panel geometries together.
Main font/size/scale should continue to come from the main settings unless a
user explicitly overrides a supported option. This is a proposal, not a file
that this build already loads.

First implement and test a versioned import of existing per-character and global
bank settings, including older L1 settings. A dedicated file becomes authoritative
only after successful persistence; retain the original settings as recovery
input and never re-import over later edits. Test reload, partial files, failed
writes and per-character inheritance before removing obsolete sections.

Then move runtime modules into coherent libs/ and ui/ locations with updated
require paths and compatibility shims where external consumers need them. Move
assets last, with a central path resolver and fallback for installed custom
icons/themes. Windows case sensitivity differences and user art must be tested.
No runtime module or asset paths change in Hint Cleanup 1. This keeps the bug fix
independently testable and avoids making users migrate settings and art together.
