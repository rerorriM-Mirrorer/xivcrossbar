# XIVCrossbar branch map and shared working rules

Checkpoint: October 16, 2026, America/Chicago. Collaborative author: A.

Maintenance 2 public additions are committed locally but NOT published: the
GitHub push was denied by the environment approval check. Do not retry via
another transport. Ask Max to confirm publishing to public/rc3-maintenance.
Package headers identify the local source commit; the table's published
checkpoint remains the earlier remote runtime, not this new delivery.

## Choose the correct line before editing

Repository: https://github.com/rerorriM-Mirrorer/xivcrossbar

| Line | Branch | Runtime baseline | Published runtime checkpoint before this documentation delivery |
| --- | --- | --- | --- |
| NEW personal development, rebuilt from public RC3 | personal/ps5extended | 0.4.0-a.20261014.personal8-sets1; AHK Controls=8.1 | 59f1950acdec61002333f5491f334b26c2243ba9 |
| Public release candidate, maintenance after RC3 | public/rc3-maintenance | 0.4.0-a.20261016.public-rc3-maintenance2 (local) | 93624052f8cb170d47f5747d11d6ad0aeb6665ee |
| LEGACY personal development before the RC3 rebuild | Historical packages/source only | Batch-era Apps/L1 experiments | Do not invent a current branch/ref or use it as the baseline |

Package TESTING.md records the exact source commit and publication status used
to build that package. October 15's handoff-only delivery left runtime versions
unchanged; October 16's public Maintenance 2 intentionally increments its version.
Verify the branch, commit, clean/dirty state and runtime before working.

The old local public/rc3-snapshot reference and public-rc3-snapshot-20261013 tag
were described in historical notes but were not available on GitHub during this
review. The new public maintenance branch explicitly recovers the delivered RC3
archive plus Icons/Credits/Escape patches. Its initial recovery is local ab7af8c,
published f70be63c2a16cae3243b4d80f3f38a47c535a7be. Do not describe it as a
verified checkout of the unavailable ref.

Local and published commit SHAs differ because source commits were transferred
through the GitHub connector. Corresponding file trees were checked. Future
agents should use published SHAs for a GitHub checkout, and retain local SHAs as
provenance only. Do not assume a local hash is fetchable from GitHub.

## Current separation

Both builds contain Apps+F1-F12 input routing, silent F-key interception,
controller profile selection, draggable/scalable crossbars, responsive menus,
single-screen custom action review, extracted item icons, Superwarp fixes,
Options chooser overlays, and RC3 Icons/Credits/Escape repairs. Both now have
instant compact switching, correct stroke alpha and explicit drawing cleanup.
Public Maintenance 2 also ports shorter target-list pagination, stable
in-world identity/storage gating (including pre-login navigation), and stable
Default-set switch destinations. It newly implements Save Only / Save Changes
returning to the editable catalog. These public changes need live acceptance.

The NEW personal line additionally has PS5 Extended controls, personal defaults,
movement signaling, named-mutex duplicate protection, last-client shutdown,
global plus character catalogs with linked-copy updates, MP-cost refinements,
rounded indicators and textfade/autoattack controls. Stable identity, target-page correction and Default
destinations are now shared behaviors; Save Only return is implemented in public
Maintenance 2, not claimed implemented in the inspected personal checkpoint.

The public line excludes those personal additions unless separately ported and
tested. In particular it has no L1 companion, no PS5 Extended profile and no
TrustMovement dependency. Its default is PS5 DirectInput, ordinary arrows,
always-visible/noncompact bars, and three bars. Personal defaults are Extended,
IJKL, oninput, compact and six bars. Saved settings can override defaults.

## Installing and testing two builds

Both install as Windower/addons/xivcrossbar, register xb/xcb/xivcrossbar, and
emit the same Apps signals. They are alternate installations. Test one variant
at a time on a Windows PC; two wrapper processes from different folders would
both observe the focused FFXI window and can duplicate input. The per-install
mutex in the personal build does not coordinate two separate install folders.
Separate PCs can use different builds independently.

To switch on one PC: stop the current wrapper, unload XIVCrossbar on all clients,
back up/move the installed folder, install the other complete folder, and load.
Lua reload alone does not replace a running AHK script. Do not rename the addon
or load both copies to try to achieve isolation. Distinct code folders and data
copies can be kept outside addons while inactive.

Complete packages contain images/themes and all required runtime modules, but no
user data, settings.xml, config.ini, catalogs, binds, extracted caches or local
controller preferences. A clean install runs setup and creates its own data.
For personal play restore data/ and config.ini from the PERSONAL backup and any
user-added icons. For public acceptance prefer a fresh disposable setup or a
separate copy of the PUBLIC backup. Do not round-trip working personal catalog
data through the older public catalog implementation as a test.

## Workflow and evidence

Read root WORKFLOW.md (AGATHOS, DESIGN and shared addon standards). Max wants
frequent concise progress reports, small coherent commits, GitHub pushes and
identifiable test packages. GitHub development is authorized; publishing a forum
post or messaging other people is not authorized by that permission.

Keep README focused on use/configuration and a cumulative changelog. Keep
TESTING.md cumulative, newest checks first; correct old conclusions explicitly
rather than silently erasing history. Testing ZIP roots contain TESTING.md,
WORKFLOW.md and the installable xivcrossbar/ folder. These handoffs are inside
xivcrossbar/docs/ and also supplied separately for new conversations.

Default command standards: help/status/restart/unload; useful help on bare or
invalid commands; chat-only output with fragment colors (140 separators, 167
headings, 200 prefix/arrow, 207 syntax, 0 descriptions). The personal build has
newer help than public; do not claim the public help was fully modernized here.
Keep reload (data refresh) distinct from restart (full Lua reload).

Record separately: implemented, user-confirmed live, simulated, suspected,
deferred and rejected/superseded. A mock passing is not Windows/FFXI acceptance.
No Windows native AHK/FFXI runtime is available in this workspace. Existing Lua
checks use Lua 5.4 with temporary normalization of inherited Windower string
syntax; do not call that Lua 5.1 verification. AHK lexical and translated-pure-
function tests do not validate native SendEvent delivery.

The personal input stickiness and native pol.exe crash cause remain unresolved.
Shared text loss was observed across addons and native console; the concrete
XIVCrossbar resource leak is fixed, but do not equate that with a proven crash
fix. Do not replace Windower libraries or unrelated addons speculatively.

## Environments and historical evidence

Fenrir is Max's current server; historical Phoenix characters were mentioned.
Do not hardcode Fenrir or delete Asura folders: correct identity gating must
also work for actual Asura users. Main tests: Franklet 1280x720, Lionstag 960x540,
Killalasisasa 1600x900; Frank's PC 3840x2160. Simulations also cover 1920x1080 and
2560x1440. PS5 DirectInput is the live-tested controller path. Native FFXI's
XInput checkbox also reportedly left that tested setup working; AHK's XInput
reader could not detect that controller in slots 1-4, so other profiles remain
experimental. Retain native stick movement/camera, disable duplicate button
assignments and hat switches. The menu-down calibration issue was native POV/
axis assignment; never bind menu cursor to the trigger slider.

There were four XIVCrossbar conversations according to Max. Additional-history
retrieval returned no matches during this handoff; coverage is the visible
conversation, current source, commits, cumulative TESTING and recovered delivery
archives. This is not a claim to have recovered every original message. Numerous
early image attachments were missing/unreadable; their colors/layouts were
implemented from later discussion/source. Do not claim to have viewed those
missing screenshots or sampled their pixels.

## Transfer fixes deliberately

Use separate worktrees/branches and review individual commits. Shared UI files
overlap heavily: branches are not interchangeable overlay layers. Never copy
the whole personal ui.lua/xivcrossbar.lua/AHK into public. Port the smallest
coherent behavior, adapt dependent helpers and tests, preserve public defaults,
then record its live acceptance. Current public port commits: compact 5242a8e,
stroke 084e72b, cleanup 9362405. Public Maintenance 2 local commits: pagination
db3b662, identity/login 5b31fc4, Default destinations 1afc4ef, save return 292682a.
Their public live acceptance remains pending. Personal
controls, L1 banks, icon migration and lockout palette are separate design work.
