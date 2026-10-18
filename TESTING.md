# Current Development Status — October 18, 2026 (America/Chicago)

- **Repository / branch:** `rerorriM-Mirrorer/xivcrossbar` / `public/rc3-maintenance`; working source began at published `dc5e02efa05fdbb3ac75a66887744fc24fb61535`.
- **Runtime:** `0.4.0-a.20261016.public-rc3-maintenance2`; public Apps-key AHK remains unchanged. No DirectLink transport or personal bindings are added in this pass.
- **Current change:** Repaired legacy `sw`/`switch` handling and multiword set keys; made `copy`/`move`, `alias` and `icon` respect `Hotbar.Number`; removed unreachable `set` code; consolidated the mis-signed action callback so own job abilities refresh spell availability. Added regression coverage, the final-status workflow rule and the missing `AGENTS.md` entry point. Aligned package-document placement with the canonical shared convention (inside the installable addon folder).
- **Last user-confirmed live behavior:** Original RC3 setup and controller routing, startup fade, restart and Icons1 were reported working. Maintenance 1 public ports and Maintenance 2 remain pending dedicated live regression.
- **Verification:** All 11 top-level Lua regression files passed with `python3 tests/run_lua.py tests/*.lua`. All 61 Lua sources parsed with the documented Lua 5.4 normalization fallback. This is source/simulated verification, not native Lua 5.1/Windower/FFXI acceptance.
- **Still to test in FFXI:** `sw`/`switch` with empty/multiword names; CLI edits with three and six bars; job-ability spell refresh; all public Maintenance 2 pagination, identity, destinations and save-return cases; multi-client wrapper, menu and resolution regressions.
- **Next development:** Live-test the complete public Maintenance 2 candidate, then consider selective generic DirectLink architecture ports before promotion to `master` or a public tagged release.
- **Publication correction:** The October 16 initial push was blocked, but a later authorized push succeeded. The public branch had reached `dc5e02e` before this task. Earlier dated notes below preserve the original failed-attempt history; they are not the current remote state.
- **Delivery:** Source-and-test checkpoint only; no new ZIP, upstream pull request, community announcement or live FFXI run. Final pushed commit is reported in the GitHub handoff.

---

# Public RC3 Maintenance 2 — complete testing installation — October 16, 2026

Runtime: `0.4.0-a.20261016.public-rc3-maintenance2`.
Branch: `public/rc3-maintenance`. Package header records the final local commit.
GitHub source baseline: `2c41936a5b095b73f3615b3ba241e413ae846126`.
~~**NOT PUBLISHED:** the environment approval check denied the first push. No
alternative push mechanism was attempted. Ask Max to confirm publishing these
commits to the existing public branch. Do not describe this delivery as pushed.~~
**October 18 correction:** This was true for the initial October 16 attempt;
the branch was subsequently published through the authorized GitHub workflow,
with `dc5e02e` as its verified pre-maintenance source head.

## Request, workflow and source baseline

Max requested review of NPCmirror's current WORKFLOW.md first, then all four
previously identified public candidates. Read shared WORKFLOW from
`rerorriM-Mirrorer/ffxi-NPCmirror` (blob
`424d643fd63b944bd8534f455342b5328f1ca48c`); it matches the public copy.
Read the public source, existing passing tests, handoffs and the upstream root
module. Inspect personal source at `9375a66d75778744a865077e2f676458688fc65a`
and the individual port commits; do not overlay whole personal runtime files.
No personal branch, default settings, controller-profile or AHK changes.

| Improvement | Local feature commit | Personal source / behavior |
| --- | --- | --- |
| Shorter target-list pagination | `db3b662` | `2f462fa`; retain Back spell/page |
| Stable identity/storage gate and login keys | `5b31fc4` | `7c97012` and required guards/login dependencies |
| Default-set destinations | `1afc4ef` | `a390b06`; readable labels, stable execution keys |
| Save Only / Save Changes return | `292682a` | New implementation; saved entry selected in edit picker |

## Install safely

This is a **complete install**, not an update-only patch. Unload XIVCrossbar on
all clients first. Back up the installed public folder, including data/config.ini
and custom images. Install the ZIP's `xivcrossbar/` into Windower/addons. For an
upgrade, restore only the PUBLIC backup's data/config.ini and user-added images;
for fresh acceptance, leave user files absent and complete setup. Never run
personal and public variants together on one PC or round-trip personal catalogs
through this public implementation. Switching variants requires stopping the
current wrapper before unloading; this batch's public AHK itself is unchanged.
No settings.xml, config.ini, catalogs, binds, extracted caches or user data ship.
Rollback: unload all clients and restore the backed-up PUBLIC folder/data.

## Verification performed here — simulations only

- All 60 Lua sources parse using the existing Lua 5.4 runner and temporary
  normalization of inherited Windower string-literal method syntax. Lua 5.1,
  LuaJIT, luacheck, Windows, native Windower and AHK runtimes are unavailable;
  this is **not** Lua 5.1/API-aware static validation or live FFXI acceptance.
- Existing checks: 108 layout scenarios across six resolutions/three scales;
  compact command validation/state preservation; 200 menu cycles, 150 typed
  updates, 100 footer rebuilds; 30 crossbar/20 chooser rebuilds; cursor unload
  and deferred/idempotent object destruction.
- Pagination: 12 actual binder spell-page-two/three -> targets -> binding ->
  Back -> save scenarios across six resolutions. Target choices show at page
  one and Back restores Shellra II and the original page.
- Identity: actual initializer, observer and load/login/logout/keyboard handlers
  under mocks. Lobby/unknown server/missing or mismatched entity rejected;
  0.75-second tuple stability, transient retry, late correction and one reload,
  changed character IDs, actual Asura support, no-subjob identity, unconfirmed
  writes blocked, wrapper startup independent of identity, logout invalidation,
  login key-down/up ownership, ignored triggers, physical F-key passthrough.
- Destinations: real binder, slot save, root switch and player execution under
  mocks; all three Default sets, renamed display label, reciprocal same-slot
  switches, quick-switch return and replacement of stale action metadata.
- Save return: six resolutions, real binder and catalog callbacks with mocked
  writes; menu/command create, edit/rename, selection across three pages,
  Back-to-main selection, false/throwing writes with rollback, invalid/duplicate
  names, unsaved cancellation, Save & Bind/Back and 180 bounded repeat cycles.
- Scope checks compare public defaults, AHK, controller profiles and assets
  byte-for-byte with the remote baseline. Package checks enforce required new
  modules, no distributed user state, archive integrity and source-byte equality.

Repeat from repository root:

`python3 tests/run_lua.py tests/compact.lua tests/compact_command.lua tests/menu_resources.lua tests/ui_lifecycle.lua tests/character_identity.lua tests/profile_gate.lua tests/profile_lifecycle.lua tests/login_input.lua tests/crossbar_destinations.lua tests/custom_action_save_return.lua`

## First live tests — not yet performed

1. Verify `//xb status` ends `public-rc3-maintenance2` and reports the correct
   character/server; resource helper stays `public-cleanup1` (unchanged helper).
2. On Franklet 1280x720 and Lionstag 960x540, select a later-page spell, check
   targets immediately, go Back twice, bind and execute. Spot-check 3840x2160.
3. Load before login; test controller arrows/confirm/cancel, then login with a
   no-subjob character. Confirm no false lobby-server folders are created.
   Logout/relogin as another character, reload, zone and change jobs. A server
   remaining wrong beyond the settling interval cannot be predicted; a later
   observed correction reloads normally and does not delete existing folders.
4. Bind reciprocal Default/custom switches (same slot), then Job Default and
   All Jobs Default. Reload and repeat. Check Quick XB Switch returns after one
   action. Rebind an old label-based switch if necessary; no XML migration.
5. Create through menu and `//xb ca`, Save Only, edit the selected entry, rename
   across pages and Save Changes; edit another entry. Check Back, Save & Bind,
   draft cancellation, reload persistence and Options overlay restoration.
6. Repeat prior compact/fades/resource checks, Credits, Escape and fresh setup.
   Restart/unload one of two clients and confirm the other remains usable.

Public candidate remains unreleased. No forum post, PR or announcement. These
changes do not prove resolution of native d3d8.dll crashes, shared text loss or
personal input stickiness. Standard public help/unload modernization and all
personal-only controls/catalog ownership features remain outside this batch.

---

# Maintenance 2 per-feature development notes (retained)

Save-return implementation: new behavior, not an already-completed personal
port. After successful Save Only / Save Changes, return to the edit picker and
select the saved name at its sorted page/row/column. Preserve main-menu Back
selection; clear the completed draft. Failed/invalid saves remain in review;
Save & Bind keeps the existing binding path. Live: create from menu and command,
edit/rename several entries including a later-page entry, save then edit another,
Back to main menu, Save & Bind then Back, cancel an unsaved draft, and verify
persistence after reload. Public linked-copy propagation is still out of scope.

Default destinations port: personal a390b06 adapted without catalog ownership
changes. Tests exercise actual binder, slot save, root switch and action execution
for all fallback destinations, a renamed display label, reciprocal same-slot
switches and Quick XB Switch return after the next action. New action selection
clears stale switch/custom-action metadata. Live: bind reciprocal Default/custom
set switches, reload, then repeat with Job Default and All Jobs Default; test
Quick XB Switch's one-action return. Saved older bindings are not migrated.

Identity port: personal 7c97012 plus its character-identity/storage guards and
login-navigation dependency. Keep the public wrapper, profiles and defaults.
Simulations cover lobby/unknown-server/mismatched-entity rejection, stable
identity, late correction, character IDs, genuine Asura and blocked writes.
Live: load before login; use controller arrows/confirm/cancel, log in and verify
only the correct server/character hotbars load. Logout and select another
character; do not create data under a lobby/default server. Test a no-subjob
character, a reload, job changes and another client remaining usable.

Pagination port: personal published 2f462fa, adapted to public. Actual binder
methods pass 12 page-two/page-three -> targets -> binding -> Back -> save cases
across six resolutions. Lua fixture simulation only; live FFXI acceptance pending.
Retest Shellra II from a later spell page at 960x540 and 1280x720; targets should
appear immediately, Back should restore the spell/page, and binding should work.

---

# Complete installation + conversation handoff — October 15, 2026

Variant: **PUBLIC RC3 maintenance**. This delivery packages all currently implemented
runtime code and required images/themes. Pending ideas are documented, not
implemented. The runtime version remains unchanged.

Start with `xivcrossbar/docs/HANDOFF-PUBLIC-RC3.md` and the shared
`xivcrossbar/docs/BRANCH-MAP.md`. The exported package header records exact local
and published source checkpoints. The standalone handoff copies carry that
header too. Historical update-only instructions below apply to those earlier
ZIPs, not to this complete ZIP.

## Install and identify

1. Stop the currently running shared wrapper with //xb controller stop and
   unload XIVCrossbar on every client (//lua u xivcrossbar works in both builds).
2. Back up/move the existing addon folder. Copy this complete xivcrossbar folder
   into Windower/addons. Do not overlay or run public and personal together.
3. For clean setup leave data/config.ini absent; the wizard creates them. For
   an upgrade restore the matching variant's data/, config.ini and custom icons.
   Never use the installer as a source of empty user files.
4. Load //lua l xivcrossbar. Verify //xb status and //xb controller status,
   complete setup if needed, then use the focused checklist in the handoff.
5. If swapping variants later, repeat stop/unload and use their separate data
   backups. TrustMovement/Trust/AddonManager and native Windower libraries are
   separate dependencies and are not replaced by these installations.

## Evidence and next development

The three approved ports are implemented/pushed and simulation-tested, not yet
live-confirmed in public. Continue compact/fade/resource checks, Credits at both
small resolutions, Escape navigation, two-client restart independence and clean
setup. Stable server gate, target-list pagination, Default destinations and
standard unload/help remain selective-port candidates, not included features.

Additional conversation retrieval did not recover the other threads. This
handoff uses visible discussion, current source, recovered archives and cumulative
records; gaps and historical-only claims are identified. Documentation checks
verify current roles/defaults/commands and preserved branch separation. No new
Windows/FFXI acceptance is implied.

---

# Public RC3 Maintenance 1 — October 15, 2026

Runtime: `0.4.0-a.20261015.public-rc3-cleanup1`. Cumulative public-only ports:
immediate compact switching, corrected text stroke alpha, and resource cleanup.
New branch public/rc3-maintenance recovers the delivered RC3 + Icons/Credits/Escape
runtime. Personal controls, movement integration, personal defaults, catalog
propagation, icon relocation and palette changes are excluded. Master and the
personal development branch remain unchanged by these ports.

Install over the public RC3 runtime only: unload XIVCrossbar on all participating
clients, copy the installable xivcrossbar contents, then load again. No AHK
changes in this patch; the running public wrapper can stay. Do not overlay this
on a personal installation: it is a separate public candidate. No data, XML,
INI, settings, catalogs, bindings or images are shipped. Code rollback targets
the recovered RC3 public baseline, with user data preserved.

## Verification and live checklist

Available checks pass: 108 layouts (six resolutions x three scales x two/six-bar
variants), compact command validation/state preservation, 200 review/edit/bind/back
cycles, 150 text updates, 100 footer rebuilds using an upstream Windower List,
30 crossbar reconstructions, 20 chooser reconstructions, cursor unload after
root disposal, and idempotent deferred destruction. Lua 5.4 parsing uses temporary
normalization of inherited Windower string methods; this is not Lua 5.1, native
Windower drawing or Windows input execution. These checks do not prove a native
crash fix. Prior original public test groups are not claimed rerun here: their
sources were not in the recovered archive.

1. `//xb status`: reports public-rc3-cleanup1. `//xb compact`, explicit on/off,
   scale .6/1/1.5; toggle while choosing sets and editing a custom action. Draft,
   current set, drag position and bindings survive; both layouts fit.
2. Compare text fades in both layouts. No flickering outline; ordinary input,
   startup visibility and captions behave as before.
3. `//xb resources`: note counts on a closed menu, repeat edit/save/bind/back,
   return to the same screen and compare. Counts should settle, not grow every
   cycle. Unload/reload with a menu open; no disposed-object errors.
4. Native gameplay, addon menu, all six crossbar states, physical F-keys and
   Ctrl+F-key bindings remain correct. No personal profile is offered.
5. Remaining prior release checks: Credits at 960x540 and 1280x720; Escape from
   drafts/binding/chooser without native leakage; restart one client while another
   remains usable; final clean installation and setup guide review.

## New user feedback and next candidates

Default reciprocal switches on the personal build are live-confirmed. TrustMovement
is managed by AddonManager; no autoload integration is wanted here. Personal input
stickiness remains under investigation. Deferred public candidates for review:
stable world/server gating, shorter target-list pagination, Default destinations,
and the existing catalog-save navigation request. Future personal design: two L1
modes/banks, per-bank visibility, icon-picker organization and muted lockout colors.
Do not silently include those in this three-feature maintenance patch.

---

# Public RC3 Stroke 1 — October 15, 2026

Port corrected stroke_alpha calls in crossbar text, selector, binder, controller setup and chooser. The drawing mock rejects transparency arguments outside Windower's 0..1 range. The prior personal build was user-confirmed to fade text without flicker after this correction. Recheck public fades in both compact layouts; no palette or timing changes.

# Public RC3 Compact 1 — October 15, 2026

Immediate `//xb compact [on|off]` port only. Existing public settings and controller profiles are preserved; no personal controls or companion are included. Toggle during a draft, chooser use, trigger holds and at .6/1/1.5 scale; check all six bars and drag persistence. Simulated layout/command checks are run before delivery; Windows rendering and input require live testing.

# Public RC3 maintenance — recovered release checkpoint

Recovered RC3 + Icons/Credits/Escape from the delivered public runtime archive. The former local public snapshot ref is not present on GitHub; this branch explicitly recovers that archive and does not alter master or the personal branch.

Remaining prior public acceptance: Credits on both small layouts, Escape across menu types, explicit two-client restart independence, and final package/setup documentation review. Icon fit, ordinary controls, fresh setup, startup fade and restart itself were reported passing.

## RC3 Escape 1 — cumulative menu-exit patch (October 13, 2026)

User requests a small Escape patch. Runtime: 0.4.0-a.20261013.public-rc3-escape1.
Commit 19358ec adds a shared full-exit helper, reused by the normal Share close
path. Physical Escape exits binder menus/drafts/text fields, chooser overlays
and set-name entry, plus setup if open. It cancels the chooser's preview through
the existing cancellation path, closes menus, discards unsaved drafts, restores
hints, and releases the text input block. It does not simulate native Escape.
The keyboard handler owns Escape repeats and release after close; normal Escape
outside addon menus passes through. Focus reset clears any abandoned ownership.
Circle/Enter handling is unchanged, and wizard cancellation does not mark setup
complete or change readiness. Unsaved field changes are intentionally discarded.

All 49 Lua regression groups pass, including new full-exit routing tests for
main/review/binding/Credits/inline/chooser/chooser-text/setup, pre-initialization
setup cancellation, held repeat/release, and restored native/unrelated input.
Three cumulative runtime Lua files parse after temporary standard-Lua string
normalization. README and release README document the Escape behavior.

Delivery: cumulative three-Lua-file update plus README over complete RC3 with
or without Icons 1/Credits 1. No bindings/configuration/images/wrapper replaced.
Exact complete-RC3 rollback copies included outside the runtime folder.
Live checks: Escape from main menu, binding capture, inline edit and chooser over
a draft; every addon layer closes and one press does not cancel the native menu
beneath. Release it, then verify the next native Escape works. Circle still backs
one step. Credits 1 and explicit two-client restart confirmation remain pending;
icon alignment, startup and fresh setup/controls are user-confirmed passes.

---

## Icon live pass and branch/navigation discussion — October 13, 2026

User confirms patched icons "now fit the button slots perfectly." Icons 1's
native rendering is a live pass. Credits 1 visual results remain pending.

User proposes keeping a finalized release branch while developing personal
features separately, then porting generally useful fixes back. Recommended
starting point is the tested public release; the older personal branch remains
a reference for deliberately selected features. No branches created or changed
by this discussion record. Do not mark a new release trusted until its remaining
live checks pass.

Requested navigation consistency: physical Escape should exit all XIVCrossbar
menus like Share/Create, including text entry and chooser overlays. Current
code handles Escape as text cancel/back or chooser close, with no general menu
exit handler. Proposed release fix should share complete-exit behavior, consume
both key edges, retain Circle's one-step Back and leave native Escape alone when
no addon menu is open. No runtime Escape patch applied during this discussion.

---

## RC3 Credits 1 — cumulative Credits/icon update (October 13, 2026)

User authorizes repairing Credits; leaves stronger menu-gradient tuning for later
personal testing. Runtime: 0.4.0-a.20261013.public-rc3-credits1. Commit e7bbd33
corrects all avatar paths to images/credit_avatars/, removes manual newline
spacers from the responsive grid, and starts Credits on page 1 while preserving
the saved main-menu selection for Go Back. All original people and roles remain.
No shared selector or menu-gradient behavior changed.

The new Credits regression fails before the fix on inherited pagination. After
the fix it verifies all avatar files, entry count, saved main-menu return state,
and reachable in-grid entries at 960x540, 1280x720, 1600x900, 1920x1080,
2560x1440 and 3840x2160. All 48 Lua regression groups pass; three delivered
runtime files pass syntax checking after temporary Windower string normalization.

Delivery: three-file cumulative overlay over complete RC3, including Icons 1.
No base images/configuration/bindings included. Exact original RC3 rollback
files are included outside the runtime folder. //lua r xivcrossbar applies it.
Live checks: Credits displays icons/labels on Franklet and Lionstag, all entries
fit, Circle returns to the prior main-menu selection, Share exits, and native
spell/pet icons align after the included icon patch. Live visuals remain pending.

---

## RC3 live results and Credits report — October 13, 2026

User reports fresh setup went well, controller buttons work without bleed-through,
startup fade looks good, and //xb restart "works great." Restart itself is live
confirmed; the report does not separately confirm another client stayed usable
during that command, so retain that specific cross-client check as pending.
User does not notice a darker menu gradient, although the custom action screen
may be darker. Do not increase the gradient based on this observation alone.
RC3 Icons 1 visual result remains pending while the user checks it.

Credits: missing icons and misaligned entries on Franklet; nothing appears when
selected on Lionstag. Code inspection finds avatar paths omit the required
images/ prefix, Credits inherits the main-menu page number instead of starting
at page 1, and manual newline spacer entries assume the old grid arrangement.
These explain concrete missing-resource/pagination/layout risks; no Credits
runtime patch has been applied yet. Preserve credited people/roles when fixing.

---

## RC3 Icons 1 — native icon alignment patch (October 13, 2026)

User requests an icon-overflow patch while testing RC3. Runtime build:
0.4.0-a.20261013.public-rc3-icons1. Commit b6fb93d removes only the obsolete
4px right/down inset in load_action; geometry already sizes icons to 40px slots.
The artwork, slot dimensions, scaling, and action execution remain unchanged.

Extended item_icon_routes.lua exercises actual action loading through the real
geometry proxy. Dia fails the slot-origin assertion before the fix. Afterward,
spell/pet/job/weapon/item/custom/linked/mount paths align at scales 1, .6 and 1.5;
presentation and movement-cohesion checks pass. All 47 Lua regression groups
pass, and both changed runtime files parse after temporary standard-Lua
normalization of inherited Windower string methods. Native rendering remains
a live check.

Apply the two runtime files over the complete RC3 installation, then
//lua r xivcrossbar. No images/data/config.ini included or replaced. Rollback
files reproduce the exact complete-RC3 versions from commit 7568505.
Check Dia, Sic, Leave, Heel and Fight: icons should fill their slot without
spilling right/down. Compare an unaffected custom/item icon, then try scale .6
and restore the preferred scale. Continue the pending RC3 startup/restart checks.

---

## Live native XInput compatibility result — October 13, 2026

Lionstag: user enabled FFXI Gamepad Config's native XInput checkbox while retaining
the addon's PS5 DirectInput wrapper profile. After the proposed movement/camera,
native-menu, addon-menu and trigger-binding checks, the user reports: "Nice it
seems to work exactly the same." Overall compatibility pass on this setup;
individual checks were not separately reported. This does not establish that the
AHK XInput reader detects the controller or validate other controller hardware.
Runtime version was not reconfirmed; the latest explicitly reported installation
was RC2, so this is not recorded as an RC3 fresh-install pass.

RC3 fresh setup, revised startup/gradient and //xb restart across two clients
remain pending. Earlier lua r/unload multi-client checks passed; the remaining
restart check specifically concerns the restored //xb restart command.

Additional RC2 report: Dia, Sic, Leave, Heel and Fight icons spill outside slots
at //xb scale 1; reloading does not change their appearance. Screenshots supplied:
image(20261013-080954).png and image(20261013-081021).png. They were not inspected
because workspace access failed at that time. Shared icon sizing/cropping is a
hypothesis, not an established cause. Check on RC3 before marking it resolved.

Follow-up after workspace access returned: both screenshots inspected. The named
spell/pet icons visibly extend to the right/bottom of their slot frames. Current
ui.lua still adds +4/+4 to non-overridden icons (commented as centering 32px
icons), while ui_geometry.lua gives images an explicit 40x40 size and disables
native texture fitting. This is a concrete positioning/sizing mismatch present
in RC3 too. No runtime change made during this test-result documentation update.

---

## Public RC3 complete fresh-install candidate — October 12–13, 2026

User requests a complete fresh installation as server maintenance approaches.
Runtime: 0.4.0-a.20261013.public-rc3. Branch public/controller-profiles; local commits
only, no remote push. Relevant commits: 956dd5b relocated owned assets; a70f824 new
0.1/0.5/2 fade defaults; 408f36f startup independent of regular fades; 53ef7d5 subtle
black menu gradient; b7e79b4 adopts user's final README proposal with technical
corrections; 609d13d identifies the runtime candidate.

Startup now always uses LoadFadeIn when visibility permits, even with regular fades
off. Both always/oninput modes respect trigger interruption: normal FadeIn when on,
instant full opacity when off. After the intro, normal visibility resumes. Text
stays at fade endpoints, including startup with regular fades disabled; instant
interruption restores static hints as well as rows refreshed by recast checks.
Regular-fade toggles during startup preserve that phase rather than restarting it.

Menu normal alpha is 150 at the top, approximately 190 at the bottom; custom review
215 to approximately 235, black RGB throughout. Thirty-two additional strips use
only existing Windower primitive APIs, are created before foreground UI, share
bounds/visibility and are reused on repeated setup. No new image-generated artwork.
Other backgrounds/text entry fields are unchanged.

47 Lua regression groups pass; reader mappings match pinned upstream. Complete
package audit checks local module imports, each raster, icon-list references,
source-identical runtime files, relocated assets and provenance. Syntax checking
uses temporary standard-Lua normalization of inherited Windower string methods.
Windows live rendering of the new gradient/startup semantics and graceful restart
remain to test; previous positive results remain recorded below.

Installation: stop old script, unload on all clients, back up and move old folder
out of addons, extract the complete xivcrossbar folder. For true first-run testing,
do not copy config.ini/data initially; restore them later if desired while unloaded.
No game-client relog required for addon changes. Includes images. No player data,
config.ini, controller extras, personal L1 addon, AGATHOS/WORKFLOW/DESIGN, tests,
old install notes or unsupported alternative scripts are distributed. README and
asset provenance are user-required documentation. LIVE-CHECKS.txt stays outside
addon runtime. Rollback is the backed-up complete folder, not mixed Lua files.

Live checks after maintenance:
1. Fresh welcome -> PS5 input profile -> artwork -> assignments -> completion,
   menu navigation and one real binding; check status reports public-rc3.
2. Startup in always/oninput modes with regular fades on/off; no input reveal,
   trigger interruption and subsequent show/hide behavior; defaults 0.1/0.5/2.
3. Main menu and custom review gradients at 960x540 plus a larger resolution;
   page icons and golden cursor work from images/assets; chooser overlay hides
   and restores the full background coherently.
4. //xb restart with fades on/off, a menu/inline field/chooser open, repeated
   requests, saved binding persistence and another client remaining functional.
5. Optional native XInput checkbox test remains user-pending, not a requirement
   asserted for all controllers. Alternate physical hardware remains experimental.

Atomic wrapper startup lock and last-client shutdown remain on personal backlog,
not in RC3. No input-leakage patch is included: user suspects extra physical Enter
presses and heard a Circle targeting sound without establishing a target change.
Catalog edit propagation and other personal requests remain deferred.

---

## Final-candidate assets/defaults and narrowed scope — October 12, 2026

User explicitly requests only moving owned assets/ into images/assets/, not a
broader directory overhaul. Commit 956dd5b moves all 12 files byte-for-byte;
selectable-list page/button/cursor paths, README attribution paths and packaging
allowlist are updated. Theme/helper/iconpack directories are unchanged. 46 Lua
regression groups pass. An internal complete-package audit verifies 2155 files,
44 runtime Lua files, 2101 rasters, no missing local modules or indexed icons;
all moved assets including credits/provenance are present at new paths. No
user-facing new candidate is delivered yet; the audit archive is intermediate.

Commit a70f824 sets FadeIn=0.1, FadeOut=0.5, LoadFadeIn=2 defaults, with both README
copies updated. Saved settings remain preserved. Defaults parse and whitespace
checks pass. AutoHideExtraBars=true is already implemented in the prior update.

User now suspects keyboard Enter menu-selection attempts explain the input report;
controller Circle was a targeting sound during binding, not an established target
change. Do not call either a confirmed new leakage bug or a reproduced fix.
XInput native-config test still pending. No input code changes made.

Remaining candidate discussion/implementation: bottom-heavier black background
gradient, startup phase independent of gameplay fade toggle with trigger interruption
(short fade when enabled, instant when off), user's final README corrections/new
paths/defaults, then live restart checks and clean installation package. Mutex and
last-client shutdown remain explicitly deferred to personal development.

---

## Final-pass discussion: background, input leakage and startup policy — October 12, 2026

User explicitly requests discussion before changes. Wants menu background slightly
more opaque at the bottom than at the top. Current background is flat RGB 0/0/0:
normal alpha 150/255 (~59%); custom review alpha 215/255 (~84%). Button-entry
rectangle is also alpha 150 black; inline field alpha 240 RGB 16/26/48.
Suggested gradient: normal 150 top to 190 bottom; review 215 top to 235 bottom.
No rendering changes made.

New Franklet observation: Circle and several Enter presses leaked while creating
custom actions and binding. Exact loaded build, event sources and transition
sequence unspecified. Prior passes remain valid for their tested scenarios;
this newly reported path needs investigation. Physical Enter outside an active
field currently passes through intentionally; the committing Enter and its key-up
are supposed to be consumed. Controller Circle inside menus should be consumed.

User requests startup animation despite regular fades being disabled in always
mode, with immediate reveal on held triggers when fades are off. Proposed reading:
startup duration is independent of gameplay fade toggle in both always/oninput;
triggers interrupt with normal FadeIn when enabled, immediate opacity when off;
after startup ordinary visibility resumes. Confirm interpretation during discussion,
including oninput/no-trigger case when fades are off. No runtime change.

User explicitly moves atomic startup lock and optional last-client AHK shutdown
out of the release scope and onto the personal backlog. Live restart checks follow
these final-pass discussions. Do not silently reintroduce those deferred features.

---

## Fade/default clarification and post-release motivation — October 12, 2026

User plans to test FFXI native Enable XInput while the addon keeps its selected
profile; do not treat the native checkbox as a universal requirement before the
result. No test result supplied yet.

Current code: //xb fade off disables startup animation too. Always mode shows
immediately; oninput stays hidden until a trigger, then shows without fading;
explicit hidden mode stays hidden. AutoHideExtraBars=true is implemented and
shipped in preview38-restart defaults.lua; explicitly saved false remains.
The README note describes that default, not a separate runtime change.

Recorded <t> first/default where available as a post-release request. Collected
personal ports and deferred ideas in docs/PERSONAL-BACKLOG.md; distinguish existing
personal implementations from new proposals. No runtime or uploaded README changes.

---

## Last-client unload request and final README review — October 12, 2026

User wants on_unload_killahk to mean stop the wrapper only after the last client
using this addon unloads. Current public code forces the setting false and saves;
upstream b245aa5 ran killahk.bat on each enabled client's unload. Desired correction
needs loaded-addon client registration, not merely counting FFXI windows. Proposed
unique per-client records, removal on unload, wrapper-owned stop-if-unused decision,
reload handoff grace and stale-registration cleanup. This complements the proposed
atomic AHK startup lock. Neither change is implemented or live-tested yet.

Reviewed supplied local XIVCrossbar-README-Review-Final Proposal.md (Library
libfile_145b1887bf748191a6572507309fd8cc). Required corrections: //xb can n typo
must be //xb ca n; disable-native-XInput instruction must be scoped to tested
PS5 DirectInput configuration; //xb fade affects startup/manual visibility too,
not only autohide. Restore the requested AutoHideExtraBars=true default note.
Other user's cuts and ordering are intentional. Leave the uploaded proposal
unchanged for now; the existing README review remains under discussion.

Remaining small runtime work: atomic simultaneous-start guard; optional last-loaded
client shutdown. Delivered restart awaits user-reported live checks. Startup,
completion layout, extra bars with autohide, and multi-client unload/reload results
are already recorded. Catalog edit propagation/compact toggle/icon reorganization
and personal controls remain deferred.

---

## Simultaneous all-client wrapper startup investigation — October 12, 2026

User reports send @all lua l xivcrossbar appears to load multiple AHK scripts.
Exact installed build, process count and script paths have not been supplied.
Reviewed current preview38 code: each client's start_controller_wrappers checks
fresh controller-status.ini, then writes launch configuration and issues run.
There is no atomic claim between checking status and spawning. Several clients
can therefore request launch before the first wrapper writes its initial status.
AHK #SingleInstance Ignore is present, but documentation explicitly identifies
simultaneous-start detection as a limitation that can permit multiple instances.

Source: https://ahk4.us/docs/commands/_SingleInstance.htm (AutoHotkey v1 directive
documentation, Limitations). This establishes a plausible mechanism, not a confirmed
process/path diagnosis for this particular report. Different installed folders or
older scripts remain other possibilities if persistent duplicate processes are seen.
Suggested correction: an atomic, script-folder-scoped Windows lock in the AHK
wrapper, acquired before input/status ownership, so one process is the owner and
competing launches exit. Mere same-process-name checks are not atomic and cannot
distinguish separate scripts hosted by AutoHotkey. No runtime change in this pass.

---

## RC2 Restart update — October 12, 2026

User requests restoring //xb restart while reviewing documentation. Runtime:
0.4.0-a.20261012.public-preview38-restart. Implementation closes chooser/menu/setup,
ends dragging and text capture, releases owned gameplay keys, cancels pending
profile changes and fades out the bar before sending lua r xivcrossbar.
Repeated requests schedule one reload. During the fade, controller actions and
normal bar rendering are suppressed while the geometry fade continues ticking.
Disabled fades use zero delay. The shared AHK process is unchanged and survives
this reload. //xb reload remains XML-only; //lua r remains immediate.

46 Lua regression groups pass, including actual restart command dispatch, delayed
reload, one-shot scheduling, initialized/uninitialized interactions and fades off.
Runtime syntax and package byte checks also apply. Live restart remains untested.
README copies include the restored command; their review is still ongoing.

Delivery: cumulative eight-file overlay over complete RC2/Profiles2/Setup1/Setup2.
Includes AutoHideExtraBars=true for new configurations (existing saved settings
remain), all Setup 2 changes and restored restart. No images/data/config.ini or
README shipped. INSTALL.txt outside the addon root supplies installation and tests.

Live checks: //xb restart with fades on/off; restart with an addon menu, chooser
or inline text field open; quick repeated restart requests; binding persistence
and another loaded client's controller after the restart. Check status reports
preview38-restart. No fresh remap is required for these checks.

---

## Extra-bar visibility default — October 12, 2026

User requests hiding extra bars by default while reviewing the README.
AutoHideExtraBars changes from false to true; Hotbar.Number is unchanged.
This is the behavior already live-tested with extra bars enabled. Drawing and
input rules are unchanged. Both README copies describe the default and retained
saved settings. Existing explicit false values remain false until edited.
Change awaits the next installation package; the delivered Setup 2 ZIP still
contains the earlier false default. The existing downloaded README review copy
is not replaced during this piecemeal review; incorporate this note in the next
review/release document.

---

## README review draft — October 12, 2026

User approves correcting fallback wording and deferring catalog-edit propagation
for this public release; the feature remains wanted for personal development.
Readable field commands use name/alias/command, with n/a/c described as alternative
spellings rather than literal slash syntax. No runtime changes in this pass.

README.md and packaging/README-release.md now follow the user's proposal:
changes, prominent configuration screenshot, controls/IJKL illustration,
appearance, custom actions, help, installation, simplified profiles and credits.
A concise change summary remains at the end. Startup behavior and automatic
profile switching match Setup 2; old manual-switch instructions, retired settings,
API/status internals and development build history are removed. PS5 is live-tested;
alternate hardware remains experimental. Upgrade instructions use a fresh folder
with data/config.ini/custom icons restored from backup, not mixed old code.

Draft is for user review, not a newly approved complete release. Both documentation
copies match; local image/license/notice links and available command/profile forms
are checked. No addon test package or runtime version change prepared here.

---

## Setup 2 visual checks passed — October 12, 2026

User reports both the startup fade and completion screen look good, especially
the completion screen now that its intended layout is visible. Record both
visual checks as live passes. This general feedback does not separately confirm
every trigger-interruption/fades-off variant from the detailed checklist.

Remaining release work: final clean complete-install/rollback check, README
revision from the user's proposal, configuration illustrations and package audit.
Held-direction and menu-open focus cases can be checked during ordinary play;
the held-R2 case and two-client unload/reload checks have passed.

---

## Multi-client reload live result — October 12, 2026

User ran lua r xivcrossbar on Lionstag: Franklet still worked, and after switching
back Lionstag still worked. This establishes the requested two-client reload
check in the tested setup, alongside the earlier one-client unload pass. The
report does not identify whether Setup 2 has already been installed; do not
claim the new startup/completion changes are live-tested from this result.

---

## RC2 Setup 2 — startup reveal and completion layout (October 12, 2026)

Runtime: 0.4.0-a.20261012.public-preview37-setup2. Runtime commits: 28959f9
(completion-screen rows), 4ce57b8 (startup reveal without input), 7f25836
(trigger interruption). All 45 Lua regression groups pass; changed Lua parses
with temporary normalization of inherited Windower string-method syntax.

User held R2 while clicking away, then refocused while still holding it. The
crossbar stayed cleared and a command did not fire; no stuck movement, trigger
field or unexpected action. This live result confirms neutral-before-rearming
for that held-R2 scenario. Held direction and addon-menu variants remain pending.
The multi-client reload test means lua r xivcrossbar on one client, then check
both; one-client unload has already passed on Franklet/Lionstag.

Cumulative eight-file overlay for complete RC2, Profiles 2 or Setup 1. It includes
all six Setup 1 files plus ui_geometry.lua and visibility.lua. No images,
player data, config.ini, README or developer files are included. INSTALL.txt
sits outside the addon folder. Back up, stop the shared wrapper and unload this
addon on every client using the folder before replacing Lua; then load again.
No client relog required. Existing saved fade durations remain unchanged.

Live checks:
1. With autohide on and no controller input, loading reveals the bar fully,
   then fades out. LoadFadeIn defaults to 3s; change an existing saved 1.5 to 3
   while unloaded if you want that duration. Later input uses normal FadeIn.
2. Reload and press either trigger midway through startup. The bar should
   reach full visibility using normal FadeIn from its current opacity, rather
   than waiting for the long animation. Holding does not restart the fade.
3. With fades off, trigger-held bars appear immediately. Restore fades after.
4. Completion dialog rows are separated at 960x540 and a larger resolution.
   Existing installations need not remap merely to test gameplay.
5. Multi-client reload, held-direction/focus and menu-open focus variants.

Job-ability icon lookup reviewed: resource_generator.lua derives an iconpack
category/name path and recast-ID fallback (SP abilities include job IDs). The
menu and slot renderer prefer an existing iconpack file; saved slot/shared icon
handling is separate. No icon selection behavior changed.
README revision remains deferred until finalizing live tests.

---

## Two-client unload result and extra-bar explanation — October 12, 2026

User loaded Franklet and Lionstag, unloaded XIVCrossbar on Lionstag, and reports
Franklet still works. This confirms the shared wrapper survives one client's
unload in the tested setup. It does not yet establish all held-button/focus-switch
cases. User also reports button release feels much better than expected.

Pinned upstream README recommends AutoHideExtraBars=true for six bars and documents
HotbarOffsets.DoublePress.X/Y for LL/RR (bars 5/6). X offsets move the two sides
outward/inward symmetrically; Y applies to both. Negative Y moves them upward.
These settings remain available; AlternatePress offsets concern bars 3/4. Visible
extra bars can serve as a persistent view of their bindings if repositioned.
Author intent beyond the documented behavior is not established.

AHK emits press/release edges once, releases owned signals on focus change,
disconnect or exit, and requires neutral controls before rearming. Lua additionally
releases injected gameplay keys, clears local trigger/page state and retains menu
drafts across focus changes. Crossbar fade/text release presentation is Lua.
No runtime changes or package prepared for this result.

---

## RC2 Setup 1 live results and startup reveal — October 12, 2026

User reports tests 1, 2, 3, 5 and 6 passed: automatic switching, profile commands,
disconnected-profile recovery, draft/chooser/icon binding and reload persistence.
Test 4 remains pending with multiple clients. Test 7 mostly passes, but oninput
visibility delayed the startup fade until the first trigger press. Test 8 partially
passes: extra bars work with AutoHideExtraBars=true; false draws overlapping bars.

Startup correction committed at 4ce57b8: the ready crossbar starts its
welcome reveal without input, reaches full opacity for a rendered frame, then
returns to the normal visibility policy. Default LoadFadeIn is restored to 3s.
Explicit hidden mode and cutscene suppression remain respected; disabled fades
retain ordinary autohide. Existing saved fade durations are preserved: a saved
1.5 still needs changing to 3 to test the three-second welcome. No package yet;
the installed Setup 1 still has the delayed first reveal. The completion-screen
layout correction at 28959f9 is also awaiting delivery.

45 Lua regression groups pass, including the real prerender startup path with
controlled time, no input, readiness/hidden/cutscene guards, full opacity, normal
fade-out, held triggers and subsequent short fades. Whitespace checks pass.
Extra-bar coordinate methods and draw-policy rules match pinned upstream baseline
b245aa5; the overlapping positions with default offsets are inherited. No extra-bar
layout/default changes made; AutoHideExtraBars=true is the live-tested choice.

Remaining: multi-client focus/held-release and reload/unload checks; live startup
reveal and corrected completion-screen layout after delivery; clean complete-package
install/rollback audit, README update from the user's proposal and configuration
illustrations. Alternate controller hardware remains explicitly unverified.
No new features are required by this checkpoint. Do not repeatedly retest the full
passed list unless subsequent changes affect it.

---

## Cioara Setup 1 feedback — October 12, 2026

User reports setup completed on Cioara on Frank's PC and normal functioning so
far. Completion-screen screenshot shows overlapping success/help text and crowded
Share/Options artwork, matching Lionstag's earlier observation. Code placed the
first two text rows ten pixels apart regardless of resolution. Completion layout
now uses separate success, action-menu, chooser, new-set and exit rows. No setup
behavior changed. Fix committed for the next update; no package generated yet.

---

## RC2 Setup 1 — first-run profiles and automatic switching (October 12, 2026)

Runtime: 0.4.0-a.20261012.public-preview36-setup1. Previous live-tested profile
snapshot is preserved as tag testing/public-rc2-profiles2 at 7b58860. This pass is
restricted to the four agreed usability changes and the initial fade default.
README revision and catalog edit propagation remain deferred. AHK reader/transport
code is unchanged from the startup-file fix in Profiles 2.

### Installation

Run //xb controller stop on the old code, then unload XIVCrossbar on every client
using this folder. Back up the folder. Merge the supplied six files into
addons/xivcrossbar. Keep installed data/config.ini/images. Reload; no client relog.
This update includes all changed runtime files needed over original RC2 or its
Profiles 2 fix. Developer documents/tests stay outside the addon download.

### Live checks

1. //xb controller status: saved/running ps5-directinput, device 1, Apps, ready,
   connected=true. Retest one ordinary binding and addon-menu Cross/Circle/D-pad.
2. //xb controller profile xinput: no separate stop/start commands. Wait about
   two seconds, check status: running XInput. Disconnected is expected on the
   currently tested PS5 setup; it does not mean switching failed. Return with
   //xb controller profile ps5; check ready/connected=true and one bound action.
3. //xb controller profiles lists short names. Long profile names remain valid.
   Unknown names/out-of-range device values must leave the current selection intact.
   Optional device number remains supported. Manual start/stop remain available;
   an explicit stop cancels a pending automatic change.
4. //xb remap opens the input profile screen. Four options: PS5 DirectInput,
   Xbox/XInput, F710 DirectInput, FightPadPro DirectInput. Hover lifts the row two
   pixels up/left and returns it without accumulating offsets. Choose PS5: after
   detection, choose artwork separately, then Confirm/Cancel/Main Menu/Active Window.
   Intended PS5 face layout: Cross/Circle/Triangle/Square respectively. Complete
   existing confirmations; verify settings save and ordinary bindings still work.
5. Remap again; choose XInput. If disconnected, remain on profile choices with
   an explanatory message. Choose PS5 to recover. No console startup commands
   should be needed. Check at 960x540 and a larger resolution.
6. Fresh-install welcome test later: welcome click opens profile choices without
   starting AHK. Only selecting a profile starts its reader. Data/bindings need not
   be deleted for testing; preserve the normal installation separately.
7. //xb fade off/on and bare toggle act identically to //xb ui fade. Invalid values
   change nothing. New initial-load fade default is 1.5s; existing explicit saved
   Animation.LoadFadeIn values remain unchanged. To try it on an existing config,
   set LoadFadeIn to 1.5 while unloaded and reload.
8. Remaining release checks: multi-client/focus changes, additional bars 4-6,
   fresh setup without subjob, custom actions/icons/chooser draft, and persistence.

### Verification and implementation

44 Lua regression groups pass. New switch state machine waits for fresh stopped
status, includes a short post-ExitApp buffer, and verifies the actual running reader.
It polls only during a pending change, handles timeout/cancel/competing clients,
and avoids claiming success from a start request alone. Callback generations keep
closed/restarted setup from being reopened by an old completion. Actual wizard
mouse paths and geometry are tested at the small baseline plus existing larger
resolution tests. Local syntax normalization remains temporary for inherited
Windower string-method shorthand. Windows graphics and this exact automatic
switch behavior await live confirmation. No README package prepared in this pass.

---

## Lionstag live profile results — October 12, 2026

RC2 Profiles 1 PS5 DirectInput: status ready/connected, bare native-menu D-pad,
addon menu D-pad/Cross/Circle/Share, no action bleed-through, L2/R2 bound actions
without macro popup or target leakage, and optional IJKL targeting all passed.

RC2 Profiles 2 startup handoff: selected XInput now becomes running XInput,
Apps, source=launch-file. This supports the missing launch-arguments explanation;
startup-file fallback is live-confirmed. XInput devices 1, 2, 3 and 4 each report
disconnected/connected=false. Native FFXI stick movement/camera continue working,
which does not establish XInput exposure to AHK. Alternate XInput hardware behavior
remains unverified; a separate detection investigation can follow if desired.

Switching back via stop/profile ps5-directinput/start returns ready/connected=true
and a bound action executes successfully. No user configuration or binding repair
was needed. All results are user-reported on Lionstag; no claim of other controller
hardware validation. Profile short aliases/automatic stop-start and README proposal
are pending, not included in Profiles 2. No new package prepared for this checkpoint.

---

## RC2 Profiles 2 — startup handoff investigation (October 12, 2026)

Lionstag live RC2 Profiles 1 results: PS5 status ready/connected; native menu
D-pad, addon menu face/D-pad input without bleed-through, L2/R2 bound actions,
no macro palette/target leakage, and IJKL targeting all pass. Switching selected
profile to XInput still reported a running PS5 reader after stop/start; stop then
reported no fresh running status, but a new start again reported PS5.

Likely cause under investigation: launcher/script association omitting profile
arguments, causing the AHK default. Not yet proven; alternative includes another
client starting the PS5 reader. Profiles 2 writes a validated startup INI before
launch and reads it at AHK startup when profile arguments are absent. Status adds
origin=arguments/launch-file/default to identify the path actually used. Running
reader never rereads the handoff, preserving startup-only selection.

43 regression groups pass, including startup INI validation/write errors and
lifecycle ordering; mapping checks remain passing. Small overlay contains only
xivcrossbar.lua, controller_profiles.lua, ffxi_directinput.ahk plus outside-folder
installation instructions. Complete package also rebuilt. No profile auto-restart,
short aliases or catalog propagation changes included in this diagnostic fix.

Retest: stop current wrapper, unload addon, merge overlay, load, start selected
XInput, release buttons/focus FFXI and check controller status after one second.
If mismatch persists, return data/controller-status.ini and controller-launch.ini
and note other clients that might be loading XIVCrossbar. No relog required.

---

## RC2 Profiles 1 — selectable controller readers (October 12, 2026)

RC1 is preserved as tag `testing/public-rc1-preview34` at cc6b7bf and as the
previous complete download. Work is isolated on `public/controller-profiles`.
Runtime: 0.4.0-a.20261012.public-preview35-profiles1. This is a testing candidate,
not a claim of live validation of other controllers. No AHK v2 or personal controls.

### Install and test

1. While still on the old package, run `//xb controller stop`, release buttons,
   and unload XIVCrossbar on every client. Back up the installed folder. Merge
   the complete RC2 folder, preserving data/config.ini/custom assets; reload.
2. `//xb controller status`: saved ps5-directinput/device 1 and running
   ps5-directinput/apps should agree. Focus FFXI and wait one second before
   checking connected/ready. Release controls if waiting-neutral is reported.
3. PS5 regression: bare D-pad native menus; addon menu D-pad/Cross/Circle/Share;
   all slots on L2/R2; both-trigger arrangements; no macro popup or F-key target
   leakage; physical keyboard F7/F8 still target normally.
4. Focus switch while holding a face/D-pad/trigger, release, return. No automatic
   execution on rearm and no stuck native direction/trigger field. Reload the
   second client: it must reuse the shared wrapper, not replace its selection.
5. `//xb controller profiles`; save `//xb controller profile xinput 1` while
   the PS5 reader runs. Status must say selected XInput but running PS5. Start
   must refuse that mismatch. Stop, wait for completion, then start from the
   client with XInput selected. If changing through the wizard, use the console
   before input confirmation; artwork selection alone never selects a backend.
6. XInput: check connected status first. If disconnected, try device 2–4 with
   stop/profile/start; do not claim success from FFXI's checkbox alone. If detected,
   test each digital button, each trigger and both simultaneously; repeat step 3.
   Diagonal D-pad inputs may set two directions under XInput. Record any difference.
7. Return via stop/profile ps5-directinput 1/start. Verify ordinary actions and
   menus again. Invalid names and device numbers must leave the saved choice intact.
8. Optional hardware owners: F710/FightPadPro use corresponding profiles. The
   xinput-r1-chooser profile uses R1 for Options/set chooser; clear duplicate native
   R1 assignment. All alternate hardware profiles remain experimental.
9. Additional bars: in a backed-up test config increase Hotbar.Number to 6 and
   reload, then test both-trigger order variants and double-L2/double-R2 bars,
   binding/execution, scale/drag and AutoHideExtraBars on/off. Restore normal value.
10. Fresh installation: new setup/character without subjob; custom action creation,
    inline Enter protection, save/bind/draft-preserving chooser; Use Item icon;
    Superwarp; visibility/scale/drag; reload and job-change persistence. Check at
    960x540 and a larger resolution. User configuration screenshots are in README.

### Results and limits

43 Lua regression groups pass, including actual profile lifecycle handlers with
simulated wrapper status and pending-stop timing. Reader assignments are compared
with all three upstream DirectInput scripts; XInput digital flags and trigger
record offsets checked. These are offline checks, not Windows/AHK execution.
The standard syntax checker normalizes inherited Windower string-literal method
shorthand in a temporary copy only. No existing XML bindings changed here.
Status heartbeat uses data/controller-status.ini and is fresh for five seconds.
No fresh status does not prove that an old uninstrumented wrapper is absent.
SingleInstance ignore remains the final duplicate-process guard. Profile settings
are per client; running reader is shared. No running profile is changed by saving.

Retired new defaults: below1080, Controls.ToggleBattleMode and independent
use_directinput/use_xinput flags. Legacy XML keys remain unused. on_unload_killahk
remains forced false; explicit shared stop applies. InputTest/InputTrace remain
false by default. All release credits/comments now use A. README is current user
instructions; historical development information remains here and in git.

---

## Next-package notes — October 12, 2026

Contributor identity is A; apply it consistently to release credits. Before the next package,
search all authored credit/comment/documentation references to A and change
them to A; retain other authors and filenames whose identity is unrelated.
Do not prepare a new package yet. RC1 remains unchanged for current testing.
Review README around user-facing FFXIAH requests: Apps avoids native macro
palettes/Ctrl shortcut conflicts; menu/slot routing avoids duplicate input;
scaling/positioning/visibility; simpler custom actions; icon and persistence fixes.
Configuration guide: native macro actions are not universally forbidden; avoid
assigning them to L2/R2 used by this wrapper. Supplied annotated gamepad and IJKL
screenshots are candidates for inclusion after configuration validation.
Alternate upstream wrappers were excluded from RC1, not adapted: next discussion
must cover explicit backend selection/start/stop and shared transport contracts.

---

## Clean RC1 package audit — October 12, 2026

Packaging preserves the Preview 34 runtime build ID. No feature additions.
Local commits: 19fa1fa removes unconditional wrapper edge logging; 05d0589
removes missing Goring_Blade.png and PSD source entries from the legacy index.
Packaging recipe and distribution README are under packaging/; development
history remains in this checkout, excluded from the download.

Complete ZIP contains 2,151 files: 42 runtime Lua modules, 2,099 verified raster
assets, the tested PS5 DirectInput wrapper, attribution/provenance, theme assets,
icon index and its two upstream regeneration helpers, and a current README.
Excluded: all tests/internal design notes/preview install notes, probes and
unadapted wrappers, Python/Linux inputs, killahk.bat, config.ini, player data,
SVG/PSD source artwork and obsolete gamepad configuration screenshot.
No folder restructuring. LICENSE, NOTICE and menu asset credits retained.

All 41 regression groups pass. All 42 runtime Lua files parse in a temporary
copy after normalization of inherited Windower string-literal method syntax;
source remains unchanged. No missing local module or legacy icon-list entries.
Every packaged byte except the distribution README matches the audited checkout.
ZIP integrity passes; per-file hashes and exclusions are recorded outside the
addon in PACKAGE-AUDIT.json. Windows/AHK execution and fresh installation of this
exact clean ZIP still require live testing. Installed player data is not modified.

---

# Public Preview 34 — Options overlay and Execute Command removal

Version: `0.4.0-a.20261012.public-preview34`. Cumulative overlay with Preview 33
rollback. Preserve all current data/settings/images. Runtime commits 053e221 and
db62c25; local, not pushed. No AHK, item extraction or personal-control changes.

1. Apply and `//lua r xivcrossbar`; //xb status reports Preview 34.
2. Open Review/Save/Edit, hold Options. Draft remains readable underneath at
   roughly 45% foreground opacity. Choose Crossbar appears above it on a nearly
   opaque black panel with a gold highlight. Up/Down switches destination; header
   changes to Basic Crossbar/All Jobs Default Crossbar in its existing colors.
3. Release Options: exact opacity returns, including previously dim choices.
   Circle/Esc cancels and restores the prior set. Draft, field buffer and menu
   page stay intact. Repeat from main menu, combo capture and combo confirmation,
   including physically held triggers and text entry. No accidental bind/save.
4. Check 960x540 and 1280x720 first, then 1920x1080/3840x2160 when convenient.
   Heading and all list rows should fit within the screen, remain anchored above
   Options, and visibly layer over the menu. Inspect whether menu glyphs interfere
   with chooser labels; native graphics layering still requires this live check.
5. Open/close repeatedly and switch focus away/back: no duplicated chooser text,
   accumulating layers, stuck menu opacity or hidden-menu mouse selection.
6. Execute Command is absent; Remove a Binding is immediately before Credits.
   New command creation uses Custom Actions. Recheck any existing legacy raw
   binding; its type/execution remains untouched. No live bindings are migrated.
7. Continue retained release checks: ordinary Enter/text commit, item icons,
   destination labels, Check, disabled-catalog explanation, fresh setup and
   bindings surviving reload/job changes. Folder cleanup/config guide remain.

41 local Lua regression groups pass. Menu suspension now exercises live-object
opacity dim/restore rather than hiding. Overlay-layer tests verify bounded object
replacement, background-before-text creation, heading dimensions and gold/opaque
colors. Existing screen-clamp, controller ownership, draft persistence and all
other checks pass. Actual legacy raw-command dispatch remains verified after
menu removal. Changed runtime Lua parses in the local Lua 5.4 harness; actual
Windower renderer behavior and user preference still await the live checks.

---

# Public Preview 33 — personal-branch Options handoff

Version: `0.4.0-a.20261012.public-preview33`. Cumulative overlay with Preview 32
rollback. Preserve all user data/settings/images. Runtime checkpoints 0f1c820,
f4dbd6d; local only, not pushed. No AHK/personal companion or global asset moves.

User live feedback: Preview 31 consumes Enter during text editing and restores
normal behavior afterward. Preview 32 still failed to expose Options switching
across menu/binding/review states. Personal branch inspection identified its early
Options ownership and set_chooser_active menu suspension. Port the behavior using
public-branch object visibility snapshots rather than the personal menu geometry.
Preview 32 had navigation priority but did not suspend the obscuring modal menu.

1. Apply and `//lua r xivcrossbar`; //xb status reports Preview 33.
2. At the main menu, Review/Save/Edit, button-combo capture and combo confirmation,
   hold Options. The menu temporarily disappears and the set chooser is visible.
   Up/Down changes the selected set. Release Options: same menu, selector page,
   draft and text buffer return. No accidental confirm/bind/save or page turn.
3. Repeat while editing a field and with L2/R2 held during binding. Circle/Esc
   cancels chooser, restoring the previous set. Setup wizard ignores this handoff.
   A chooser button's release must not become a menu confirm/binding event.
4. Try unfinished Add New Set: another Options press dismisses it; release must
   not reopen it. Choosing/confirming a new set resumes an underlying draft.
5. Review/binding destination title and bind/unbind chat say Basic Crossbar or
   All Jobs Default Crossbar, with existing blue/white title colors. Actual names
   and XML keys remain Basic/default/etc; this is display clarification only.
6. Unlinked custom-command slots without an explicit icon show none.png's blue
   field. Catalog pickers show a full-size gear; valid linked artwork or explicit
   icon wins there. No default icon value is written to XML. Existing explicit
   gear icons remain explicit until the user clears them.
7. Recheck Enter commit/ordinary Enter, focus switching and ordinary slot commands.
   Focus cancellation resumes suspended menu state without saving anything.

40 local Lua regression groups pass. New fixture exercises the actual early
controller router and menu visibility handoff in four states, safe slot releases,
draft/text persistence, precise visibility restoration and consumed held-trigger
page gestures. Catalog tests cover explicit/linked/gear precedence without XML
mutation. Existing naming, disabled-choice, Check, icons, file-safety and Enter
checks pass; changed runtime Lua parses. Windows/FFXI checks still pending.

Release focus remains: live polish verification, fresh setup, bindings surviving
reload/job change, configuration guide and distributed-folder cleanup. Do not
restructure assets or personalize the main menu ahead of the playable release.

---

# Public Preview 32 — visible destinations and custom-action polish

Version: `0.4.0-a.20261012.public-preview32`. Cumulative overlay with Preview 31
rollback. Preserve all user data/settings/images. Runtime checkpoints de85a7f,
9b8d64d, 26bb1b6. Local commits, not pushed. No AHK/personal controls or asset moves.

1. Apply and `//lua r xivcrossbar`. Status identifies Preview 32.
2. Open a named custom-action draft. While on Review/Save, hold Options and use
   Up/Down to choose another set. Draft Name/Alias/Command/icon/link remain intact.
   Header changes to the destination's display name, blue for default/shared
   layers and white for ordinary sets. Save & Bind into that destination.
3. Review/Edit plus every combo capture/confirmation view share that set label.
   Sample spell, item, warp, custom action, Change Slot Icon, Change Action Icon
   and Remove a Binding. Switch a destination mid-combo; title follows and combo
   remains intact. Most paths reuse display_button_assigner/display_button_confirmer;
   45 action categories are covered by the shared-view fixtures at six sizes.
4. Create/bind a custom action with no chosen icon: full-size opaque gear appears
   with normal visibility fading. XML/catalog icon remains absent/blank. Choosing
   an explicit icon still wins. Valid linked action artwork also retains priority.
   Compare Custom Action and Edit/Delete pickers: default gear no longer has the
   erroneous four-pixel down/right offset. Test at 960x540 and 1280x720.
5. On an empty catalog in a separate fresh test installation, navigate onto
   Custom Action/Edit/Delete. Dark translucent red selection, red text, dim icons,
   no selection lift; Confirm explains how to create an action and stays there.
   Do not delete your live catalog just to test this. Blank-name Save choices
   remain skipped; only the three empty-catalog main-menu choices are focusable.
6. Main menu order: Ranged Attack > Attack > Check > Assist. Bind Check, target an
   NPC/enemy and execute: command is input /check <t>, icon check.png. Circle Back
   and Share Exit retain existing behavior.
7. Continue Preview 31 Enter checks and normal reload/job/focus/binding tests.
   Preview 31 is still awaiting live feedback; local tests are not confirmation.

38 isolated Lua regression groups pass. Tests exercise actual renderer fallback
without field mutation, actual set-switch adapter/title refresh with persistent
draft/combo state, all shared binding categories at six resolutions, unavailable
navigation/colors/no-lift, explanatory submit and saved Check dispatch. Runtime
Lua syntax checks pass. Windows/FFXI live checks remain pending.

Release checklist: fresh setup and binding persistence; controller configuration
screenshots/guide; trim the distributed folder to runtime/assets/licenses/use
instructions. Exclude AGATHOS/DESIGN/WORKFLOW, development history/tests and old
preview instructions from the community release archive; retain them in source
history/development materials. Preserve existing addon assets/third-party notices.
Do not undertake a global asset-path migration or Trust-state feature for release.

---

# Public Preview 31 — native Enter block and set-name geometry

Version: `0.4.0-a.20261012.public-preview31`. Cumulative overlay with Preview 30
rollback. Preserve user data/settings/images. Three local commits, not pushed.

User live result: Preview 30 Enter still leaked in Options/main-menu set creation
and initial/edit custom-action fields. Main-menu set-name box appeared upper-right.
Prior regression tested Lua event ownership but missed native-block lifetime:
set_capturing_text(false)/chooser clear released keyboard_blockinput during the
confirming down event. Keep native blocking through release, then prerender clears
it. No timed delay and no ordinary keyboard bindings changed.

1. Apply and `//lua r xivcrossbar`; status identifies Preview 31.
2. Test Options > Add New Set and main-menu Create New Set: type/press Enter.
   Name commits once, with no background chat/menu action. Main-menu entry panel
   and placeholder/typed caption stay centered at 960x540 and 1280x720.
3. Repeat bare `//xb ca` name entry and Edit Name/Alias/Command fields. Test
   short/held Enter; rejected blank names still permit retry after release.
4. After editing closes, regular Enter still works in game/chat. Recheck focus
   out/back, Circle Back and Share Exit. No stranded native keyboard block.
5. Preview 29 item extraction is now live-confirmed by the user: items work.
   Item/job code and AHK unchanged from Preview 30; ordinary binds remain intact.

37 Lua regression groups pass, including native command sequence around field
closure/held Enter/release/prerender/reset. Changed Lua parses. Live FFXI behavior
still requires the above check; earlier local checks did not establish the native
input timing. Follow-up polish and public-folder cleanup remain pending.

---

# Public Preview 30 — Enter commits only the active text field

Version: `0.4.0-a.20261012.public-preview30`. Cumulative overlay with Preview 29
rollback. Preserve all current data/settings/images. User has now authorized
consuming Enter while a text field is active; the Preview 29 discussion note
below records the earlier decision to defer. Runtime checkpoint is the Enter
ownership commit immediately preceding this packaging commit; local, not pushed.

1. Apply and `//lua r xivcrossbar`; status identifies Preview 30.
2. Open `//xb ca` or edit an existing action. Type a Name/Alias/Command and press
   Enter. It commits once. Neither down nor release should open chat/confirm
   anything behind the addon. Hold Enter briefly: no repeated submissions.
3. Try a rejected/empty name: the field remains active; release then press Enter
   again to retry normally. Circle/Share/controller confirm remain unchanged.
4. Repeat for set creation through the main menu and Options set chooser.
5. Outside text entry, Enter retains its existing game/chat behavior. Check it
   after editing and after switching focus out/back. No ordinary key bindings
   are changed. Focus/unload clears pending confirmation ownership.
6. Continue Preview 29 item/job checks below; those features are unchanged.

37 local Lua regression groups pass. Tests execute the actual keyboard callback's
Enter interception with binder/chooser field closure, rejected input, held repeat,
release and ordinary gameplay edges. Focus cleanup and syntax checks pass. Live
FFXI validation remains pending; the earlier confirming key-down was already
consumed, while release ownership was lost when editing closed.

---

# Public Preview 29 — expanded item records and one job-change notice

Version: `0.4.0-a.20261012.public-preview29`. Cumulative base overlay; rollback
restores Preview 28. Preserve all user data/settings/images. Runtime checkpoints:
034e69d (validated record layouts), fa862ec (quiet creation/job-change summary).
Local commits, not pushed. No AHK/controller mapping or keyboard-entry changes.

1. Apply the overlay and run `//lua r xivcrossbar`; status identifies Preview 29.
   `//xb reload` reloads bindings only, so it does not load updated Lua code.
2. Open Use Item on Franklet. Check identifiable items such as Instant Warp,
   food and crystals against their in-game icons. Bind one and confirm menu/slot
   show the same icon. Existing custom icon overrides remain intentional.
   The resolver uses a fresh `images/extracted_items_v5` cache without deleting
   older caches. No client restart or manual cache deletion is needed.
3. If an item remains wrong or falls back, send its displayed name/ID, a labeled
   screenshot when convenient and any new v5 .record.dat/.record.txt pairs.
   Diagnostics are now at most 5 KB per failed record; game DATs are read-only.
4. Change main/subjob when convenient. Crossbars load immediately, while chat
   waits 0.3 seconds after the latest event to consolidate related messages.
   Expect one XIVCrossbar line, for example:
   `[XIVCrossbar] Crossbar sets ready for DRK/RDM (created DRK-DEFAULT.xml, DRK-RDM.xml, DRK-WAR.xml).`
   Existing combinations get one line without the created list. XML backup
   notices disappear, but backup files are still made before original writes.
   Another addon's `JobChange: Changing...` lines are outside this change.
5. Recheck one binding after job change/reload. Current binds are retained;
   no recovery from older backups is requested or performed.
6. Deferred discussion: Enter committing a new/edited custom-action field leaks
   into gameplay. User requests no change yet and values keyboard freedom.
   Consider consuming only the active field's confirming press/release while
   leaving keyboard behavior outside editing intact; do not implement yet.

Evidence reviewed: upload/extracted_items_v4.zip, Lionstag_2026.10.12.log and
Franklet_2026.10.12(1).log, as supplied locally. Lionstag lines 132-138 announce
DRK-WAR/DRK-DEFAULT/DRK-RDM and backups. Franklet lines 229-230 announce WAR-WHM
and WAR-DEFAULT, then line 234 confirms Preview 28 was loaded. The newer item
messages have no secondary nil-offset error, confirming the raising guards.

Actual captured offsets establish 0x1400 spacing: offset 1,582,080 contains item
309 (515 * 3072 = 309 * 5120); usable offset 261,120 contains 4147 rather than
4181 (85 * 3072 = 51 * 5120). Other complete starts independently agree, while
several old offsets land in pixel data or zeros. No rotation/bitmap-format guess
was needed. Preserve the older Preview 28 notes as the earlier investigation.

Validation: 36 isolated Lua regression groups pass; changed runtime files parse
in the local Lua 5.4 harness. New coverage checks nonzero record offsets for both
sizes, index-zero ambiguity, stride reuse, pixel bytes, short-record rejection,
quiet real-style file creation and merged successful/failed job notifications.
Five complete neighboring records recovered from the user's captures were also
fed through the actual extractor locally. Independent Python decoding agrees on
all 5,120 output pixels. Those raw game records/generated images are not shipped.
This validates recovered neighbors, not the requested items at their correct
new offsets: live rendering of those requested items is still pending.

---

# Public Preview 28 — Windower guard compatibility and item diagnostics

Version: `0.4.0-a.20261012.public-preview28`. Cumulative base overlay; rollback
restores Preview 27 runtime. Preserve all bindings/settings/images. Runtime
commits d5b0191 and 12223e0; local only, not pushed. No AHK/personal controls or
menu layout changes. Item format/offset selection is not changed speculatively.

Live evidence: upload/Franklet_2026.10.12.log, 137 lines, reports Preview 26;
the item code is also unchanged in Preview 27. Seven failed IDs: 4413, 5885,
924, 4400, 8711, 922 and 8973. Each prints ID mismatch, absent bitmap and then
arithmetic on nil 'at'. Official Windower logger.lua source confirms its global
error() only logs and stores Lua's raising function in _raw.error. The public
guards had assumed standard Lua error semantics; tests now reproduce the actual
logger contract. Capture the raising function in player/storage/extractor.

User confirms fallbacks work; some images changed but none are correct. User
likes the quieter load status and explicitly declines binding-backup recovery;
leave current bindings as-is. No binding restoration is part of this build.

1. Apply overlay, then //lua r xivcrossbar; //xb status reports Preview 28.
   Stop/unload all clients first if following the full installation procedure.
2. Open Use Item on Franklet once. Validation failures should now print one
   useful message per failed ID, including requested/found IDs, source DAT and
   byte offset. No secondary nil-'at' error; menus and fallback icons remain usable.
3. Zip/upload images/extracted_items_v4 after this check, especially the numeric
   .record.dat and .record.txt pairs. Each raw record is only about 3 KB.
   Include one screenshot labeling a wrong displayed item if convenient.
   These actual bytes are needed to distinguish wrong record addressing from
   format/bitmap differences before changing the decoder. No client closure or
   full game-DAT upload is needed for these diagnostic captures.
4. Existing successful icons in older caches are not reused by the new resolver;
   old files remain untouched. Explicit custom iconpack overrides remain honored.
5. Recheck one ordinary binding, reload and the quiet loaded-sets status. The new
   raising guards also protect failed XML/save paths; destructive scenarios stay
   in isolated regression fixtures, not live character files.

34 local Lua regression groups pass, including Windower logger semantics, no
write after failed XML guards, and rejected-DAT evidence capture. Changed runtime
Lua parses. Real DAT decoding and Windows/Windower rendering still need the
record captures/live check. The provided log supports the guard-fallthrough
diagnosis, not a claim that all item-format problems are already solved.

---

# Public Preview 27 — missing defaults and job-change selection

Version: `0.4.0-a.20261012.public-preview27`. Cumulative upstream-base overlay
with Preview 26 runtime rollback. Preserve data, config.ini and original images.
Runtime checkpoints: 07e16b9 (missing defaults), 39de9ee (post-load selection);
local commits, not pushed. No AHK, item-extractor or layout changes.

1. Stop/unload, apply the xivcrossbar overlay and load/reload Lua. Status reports
   Preview 27. Verify current sets/bindings before further edits.
2. When convenient, switch main/subjob in-game. A valid current/shared set stays
   selected; otherwise the chooser picks a set that exists in the new job data.
   Switch back and confirm the previous job's saved bindings remain present.
   No nil-set error, empty display from a stale job-only name, or file deletion.
3. Create/save one disposable binding, reload, and recheck the current named set
   and default slots. Missing-layer/import cases are covered in isolated fixtures;
   do not delete live XML files merely to create a test scenario.
4. Repeat Alt+Tab with menus open/closed, ordinary Apps slot execution and native
   keyboard F7/F8. Keep the item-icon comparison from Preview 24 on the live list.
5. If slots remain missing, send the character XML folder including backups,
   settings.xml, current logs and //xb status before more binding changes.

32 Lua regression groups pass locally. New fixtures run the actual loader and
serializer to verify missing default files preserve already imported labels/
slots and repeated initialization retains extra bars. They also execute the
actual reload/job-change callback and default-only chooser selection. Changed
Lua files parse in the Lua 5.4 harness; Windows/Windower live validation remains
pending. This does not establish the cause of the user's earlier missing binds.

README now uses //xb remap for setup, explains one-screen custom actions in its
command table, names Hotbar.Number correctly, and distinguishes the tested
Windows DirectInput path from retained upstream wrappers. Main-menu order wording
matches Create Custom Action first. User-collected setup screenshots still need
to be supplied before incorporation into the final release guide.

---

# Public Preview 26 — preserve stored sets and inactive bars

Version: `0.4.0-a.20261011.public-preview26`. Cumulative base overlay with a
Preview 25 runtime rollback. Core fix a91a18f; local commits, not pushed.

Continuation audit found independent loader risks: display names were used as
set keys/scopes; empty sets were never constructed without a slot; omitted name
fields fell back to a numeric index; stored bars beyond the enabled count were
dropped before later saves. Regression fixtures reproduced these issues. The
loader now uses the XML tag for identity, retains the label, creates empty sets
and preserves inactive bars. Hidden labels no longer defeat legacy alias-only
commands. No display/layout, controller, icon-extractor or personal-control change.

1. Back up your current data, including .bak files. Stop/unload, apply the
   xivcrossbar overlay, and load/reload Lua. Status reports Preview 26.
2. Check the same character/job and active set before changing bindings. All
   existing named sets and slots should remain present. Repeat the Preview 25
   Alt+Tab checks below, with the addon menu open and closed.
3. If you already have extra bars disabled, their stored slots must survive a
   reload and a disposable binding save. Their UI/input stays disabled. Do not
   alter valuable data just to create this scenario; the fixture covers it.
4. If bindings still appear missing, send the character XML folder, .bak files,
   settings.xml, logs and //xb status output before further binding changes.
   Actual deletion/recovery remains unconfirmed without those files.

30 regression groups pass in the local Lua 5.4 harness; changed runtime syntax
checks pass. Added checks cover set-key/display-name separation, all-job scope,
empty sets, missing name, disabled bars and hidden-label fallback. Live Windows
behavior and actual extracted item images remain pending. This patch cannot
recover data absent from both current XMLs and backups.

---

# Public Preview 25 — focus-reset hotfix

Version: `0.4.0-a.20261011.public-preview25`. Cumulative overlay including the
Preview 24 safeguards; rollback restores Preview 23 (before the new focus
cleanup). Preserve data, config.ini and images. Runtime fix: 339663a; local only.
No AHK or item-extractor changes in this hotfix.

Live Preview 24 report: Alt+Tab causes action_binder.lua:455, attempt to call
consume_page_gesture (nil), with menus open or closed. The test incorrectly
mocked that nonexistent method. Corrected reset directly clears page_gesture
and its selector highlight. The revised regression loads the actual binder
reset methods and selector page-highlight method and verifies focus loss/gain
with open, closed and uninitialized menus. All 29 groups pass locally.

1. Back up current data and .bak files. Stop/unload, apply the overlay, then
   `//lua l xivcrossbar` (or `//lua r xivcrossbar` after replacing the files).
   `//xb reload` reloads bindings only and does not install new Lua code.
2. `//xb status` reports Preview 25 and the expected active set. Check your
   existing bindings before making new ones.
3. Alt+Tab out/in with the addon menu closed, then open. No 455 error. Test a
   held gameplay D-pad key, trigger, page gesture and inline text draft; focus
   cancels controller ownership without firing, paging or discarding the draft.
4. If bindings remain missing, retain/send data/hotbar/<server>/<character>
   including XML .bak files, settings.xml and current logs/status. Code review
   finds no binding write/delete in the focus handler; the interrupted display
   alone cannot establish disk deletion. Do not overwrite backups through new
   binding tests until the evidence is captured.
5. Item icons should depict the correct corresponding in-game items. Generic
   icons are fallbacks, not confirmed extracted images. Continue the Preview 24
   icon checks below; extraction's real DAT/image correctness remains unverified.

No new screenshots or character files were supplied with this error report.
The binding-loss report remains an open investigation, not a confirmed deletion
or a claimed recovery. The personal branch is unchanged.

---

# Public Preview 24 — load/save safeguards and item-icon review

Version: `0.4.0-a.20261011.public-preview24`. Cumulative overlay for the
qEagleStrikerp base installation. Rollback restores Preview 23 runtime. Preserve
config.ini, data, controller preferences and the original images folder. No
personal companion/controls, character bindings or compact toggle are included.
AHK scripts are unchanged. Five focused runtime commits: 3d389ef, 14c79ec,
09665eb, 34919be, a1bbf3f; all local, not pushed.

## Install and check in order

1. Back up the installed addon folder. `//xb controller stop`, unload on all
   clients, merge the package's xivcrossbar folder, then load. `//xb status`
   reports Preview 24. Existing sets/bindings should remain available.
2. Open Use Item and Trade Item. Compare a few recognizable icons with their
   in-game icons (Instant Warp, Honey or another item you have). Bind an item in
   a disposable slot and compare the menu/slot image. An older extracted binding
   should resolve through the fresh cache without rebinding. Explicit iconpack
   overrides still take precedence. Missing DAT images leave usable fallback
   icons and one chat diagnostic per failed ID per load.
3. If icons remain wrong, send the corresponding BMP from
   images/extracted_items_v3 (filenames are numeric item IDs), a game screenshot,
   chat/console diagnostics and the installed version. Do not delete old caches
   or close clients solely to refresh these images; Lua reload retries failures.
4. Create a disposable custom action, test an explicit command and a blank
   command with an existing Windower alias. Save/Bind, return with Circle, and
   reload. Existing actions and independent slot bindings remain intact.
5. Make a disposable binding change, inspect the affected `.xml.bak` files, and
   reload: every existing XML layer has its prior-save backup. Malformed XML,
   failed serialization and write failures are tested with isolated fixtures;
   do not corrupt live character files for this check.
6. Hold a gameplay D-pad direction, change focus to the other client, release,
   return and press once. Repeat with L2/L2+direction and R2/Circle: no stuck
   movement/trigger field, extra action or target change. Repeat while editing a
   custom field or set name: drafts survive focus changes. An ordinary held
   Options list closes on focus change.
7. Recheck physical F7/F8, ordinary Ctrl shortcuts, addon-only navigation with a
   native menu underneath, Share exit, Circle Back, and reload persistence.
   Inspect compact/full layout, scaling, dragging and fades at 960x540 and one
   larger resolution; no layout or input mapping change is intended here.

## Verification and limits

29 regression groups pass through the local Lua 5.4 harness, including actual
loader, serializer, binder, extraction and focus paths. Changed runtime files
parse; this is not a Windows AHK or Windower Lua 5.1 execution. Item tests use
synthetic DAT records with relocated bitmaps and known pixel colors, including
wrong IDs, absent headers, truncated data, failed writes and fallback routes.
Actual FFXI icon appearance and the multi-client focus behavior require live
confirmation. The existing corrupt-cursor bars and tiny first-frame caption
centering hop remain open/deferred; chooser fade-frame misalignment remains
deferred at the user's request.

Read-only personal-branch comparison led to targeted safeguard adaptations; its
shared-catalog migration/conflict checks, loaded-slot edit propagation, menu
skin/sounds and companion have not been imported. Catalogs remain per-character.
Compact on/off command remains deferred. Screenshot-guided gamepad installation
material is being collected by the user; no new screenshots were supplied in
this turn. README's old XInput/default and multi-screen review descriptions were
corrected. Public release still needs the live checks and final setup guide.

The FFXIAH bumper request was verified on page 4: Eyeshark requested bidirectional
bumper targeting while retaining D-pad navigation; HunterHog posted an XInput
Shift+Tab/Tab solution, and Moghedian posted a DirectInput example. No bumper
changes in Preview 24.

---

# Public Preview 23 — display names in binding feedback

Version: `0.4.0-a.20261011.public-preview23`. Cumulative overlay; rollback
restores Preview 22 runtime. Preserve config.ini/data; no AHK changes.
Implementation e076dd3; local only, no push.

1. Stop/unload, apply overlay and load. Bind a safe action in Basic: chat suffix
   should say Basic, matching the chooser. Clear the disposable binding and check
   the same display name. Repeat in a named test set if convenient.
2. Reload and verify the binding's stored set/key remains unchanged. The chat
   display is the only runtime change; all Preview 22 checks remain relevant.

Offline: feedback and actual custom-action binding regression checks pass; changed
Lua syntax/whitespace checks pass. Display-name lookup covers Basic, All Jobs
Default, a custom name and missing metadata. Live feedback confirmation pending.

Branch comparison performed against personal experiment/l1-companion-batch19 at
a7c59f9 (0.4.0-a.20261010.19-companion2), without modifying that repository. Both
have Apps transport/silent interception, readable XML slots, inline custom editing
and fallback/linked metadata, scale/fade work and trigger page navigation. Their
ui_fade.lua files are identical. Public has newer golden cursor/review, measured
caption retries, coherent movement, Options anchor/lifecycle, endpoint text
visibility, icon workflow repairs and hotbar read/write safeguards. Personal
retains the removable L1 addon, PS/touchpad/L3/R3/shoulder extras, shared
data/CustomActions.xml migration/write-conflict checks, FFXI panel skin/sounds,
lock/unlock drag tooling and extra menu/alias/grace controls. Public catalogs
remain character-specific. Selected integration is recommended; no port/merge
performed as part of this feedback-only change.

---

# Public Preview 22 — chooser lifecycle and temporary crossbar reveal

Version: `0.4.0-a.20261011.public-preview22`. Cumulative overlay; rollback
restores Preview 21 runtime. Preserve config.ini/data; no AHK/controller changes.
Implementation: 90cb7dd. Two local commits including documentation/package; no push.

Live Preview 21: the user confirms endpoint text visibility removes the fade
flicker and provides responsive trigger-release feedback. New report: blank or
abandoned New Set entry can leave the chooser stuck; ui.lua:1069 indexes nil
while lingering on that entry. Source confirms the non-existent Add New Set row
was used as player.active_environment; MP/TP checks indexed its missing hotbar.

1. Stop/unload, apply overlay and load. Status: Preview 22, Ready=true.
2. In auto visibility with no trigger held, hold Options: crossbar and set list
   appear, and Change crossbar sets caption disappears. Release Options on a
   real set: chooser/tooltip close and visibility returns to auto. Repeat from
   hidden mode; settings remain unchanged. Restore your preferred mode afterward.
3. Select Add New Set while holding Options, then release. Name entry stays open
   and the last real crossbar remains active/visible. Wait through MP/TP updates;
   no 1069 error. Blank entry then D-pad to a real set closes it and clears capture.
4. Repeat after typing a partial name: Escape closes without creating a set;
   Options press also closes, and its release must not reopen name entry. Another
   Options hold should work normally. Navigating while Options remains held keeps
   ordinary choosing open until release.
5. Enter a valid disposable set name and confirm with keyboard Enter. Set creation
   still works and closes entry. Existing sets and bindings are preserved.
6. Open a default set: tooltip follows its anchored list and disappears when the
   list closes. Share menu open/close must not resurrect a closed tooltip.
7. Check the Options image stays present while its caption is suppressed. The
   caption returns when chooser closes only if ordinary crossbar hints are shown.
8. Recheck ordinary bindings, new fade text behavior, custom actions and ijkl:
   `//xb dpad ijkl`; return with `//xb dpad arrows`.

Offline: 24 regression groups pass, including actual Options edge handling,
placeholder selection without changing live hotbar, draft cancellation, absent
/sparse vitals tables, caption visibility and temporary hidden-mode reveal.
Changed runtime syntax/whitespace checks pass. Live lifecycle behavior is pending.

Tooltip opinion: useful fallback information, but the current long block and
advice against playing from default sets need a future copy review. No tooltip
wording changes here. Other controller support remains deferred. Cursor bars
still need a close screenshot; tiny first-frame caption centering hop remains.

---

# Public Preview 21 — text endpoints and Options-anchored chooser

Version: `0.4.0-a.20261011.public-preview21`. Cumulative overlay; rollback
restores Preview 20 runtime files. Preserve config.ini and data; no AHK changes.

Preview 20 live: captions briefly begin off-center then immediately center; whole
crossbar moves together; text still flickers during fades; cursor is stronger but
has reported corrupt-looking bars; name label is white; Execute Command icons
work. The first-frame text-position hop remains, pending further refinement.

Changes: 9d50212 (text endpoints), f4ec134 (Options anchor/tooltip), df07696
(two-line help). Text visibility now switches at fade endpoints, avoiding partly
faded glyphs. It is hidden at close start even while opacity is still 1; recast
show requests cannot reveal it during the transition. Images fade continuously.

1. Stop/unload, apply overlay, load. Status: Preview 21, Ready=true.
2. Test initial fade, then trigger-only fade in/out. All crossbar text should
   disappear when close starts and return only when full fade-in completes.
   Reverse a fade mid-way; text stays hidden until the bar reaches full opacity.
3. Disable fades briefly: ordinary immediate text visibility still works. Reenable.
4. Open set chooser. Its lower-left corner aligns to the Options image's lower-left
   corner, unless constrained by screen edges/list height. It grows upward in
   15-pixel rows. On a default set, the 400x218 tooltip aligns along the chooser's
   bottom, to its right when it fits or left otherwise, clamped to the screen.
5. Drag or use Move Crossbar with D-pad. Reopen chooser and change scale: list and
   tooltip stay anchored. Check 960x540 and a larger resolution.
6. New Custom Action: first help line unchanged. Second line is exactly:
   Or use: //xb ca name <name of action> | //xb ca alias <label for action> | //xb ca command <console command to fire>
   It stays on one centered line, fitting the available panel width as needed.
7. Check normal bindings, custom review navigation, cursor animation and icon
   workflows remain intact. A close screenshot of cursor bars is still needed
   to distinguish baked texture artifacts from rendering artifacts. No further
   cursor artwork changes in this package.

Offline: all 23 regression groups pass; changed runtime Lua syntax and whitespace
checks pass. Coverage includes fade reversal/endpoints and repeated show requests,
Options screen anchor, tooltip side selection/clamping and retained movement.
Four small local commits including documentation/delivery; no push/public posting.

---

# Public Preview 20 — layout, movement, fades and icon workflows

Version: `0.4.0-a.20261011.public-preview20`. Cumulative overlay for the base
qEagleStrikerp installation; rollback restores Preview 19 runtime files. Preserve
config.ini and data. No AHK changes; no bulk images/sounds.

Implementation commits: 08f931f (stable redraws), 8cd08bd (movement/tooltip),
04d8f9c (cursor opacity), 556c9db (deferred captions/review), a6b677b (icon flow).
All local; no GitHub push or public posting.

Live evidence: Lionstag 960x540; image(7).png confirmation starts near screen center;
image(8).png initial prompt similarly displaced; image(9).png Share/Options hints
separated from the crossbar; image(10).png review help displaced, cursor/highlight
absent; image(20261011-220842).png shows native cursor visibility. Width-unavailable
at initial placement remains an inference from these images, not a captured native
measurement. Rechecking on render directly handles that condition. Offline Preview
19 tests assumed immediate measurements and did not catch the live failure.

1. Stop/unload, apply the overlay and load. Status: Preview 20, Ready=true.
2. At 960x540, Use Item: choose an item, check centered combo prompt and captured
   confirmation. Repeat with Trade Item, a custom action, Superwarp and Remove
   a Binding. Check both long/short captions at a larger resolution too.
3. Open New Custom Action from the menu: Custom Action Name label is white while
   other unnamed fields remain pink. Enter a name; review buttons have the golden
   background and animated cursor. Three help lines stay centered within the panel.
4. Check cursor visibility against the native cursor reference; animation timing
   and selected-text yellow are unchanged. Inline typing hides the selector as
   before; confirm/cancel and Save & Bind -> Circle preserve the committed draft.
5. Drag the crossbar: slots, text, Share/Options images/captions stay together.
   Use Move Crossbar with the D-pad too. Open the set chooser on a default set
   with its explanatory tooltip, drag the bar and check list/background/highlight/
   tooltip all follow it. Repeat after closing/reopening and reloading.
6. Check initial fade and trigger-only fade in/out, including compact mode. Text
   should fade steadily. Redraw churn was fixed; whether this resolves the live
   flicker still needs confirmation. Report which labels flicker if it persists.
7. Change Slot Icon: choose icon first, capture a bound combo and confirm. Its
   command/alias remain unchanged. Circle from combo returns to icons. Selecting
   an empty/fallback-only slot warns and permits another selection, without saving.
8. Change Action Icon: select a binding then icon. Check a matching slot without
   its own icon on another set; explicit slot icons stay unchanged.
9. Execute Command is after Remove a Binding, immediately before Credits. Icon
   images should now appear. Existing name-based commands remain compatible.
10. Ordinary actions, trigger priority, bare menu controls, F7/F8 and reload
    persistence remain working. Keep native hat-switch menu input disabled.

Offline: 22 regression groups pass, including delayed native-width simulation,
all shared binding captions at six resolutions, unchanged glyph setter suppression,
whole-bar/tooltip movement, new/saved review paths, icon-first slot confirmation,
legacy Execute Command image paths and fresh selector setup order. Changed runtime
Lua syntax and whitespace checks pass. Live graphics confirmation is pending.

The personal L1 companion remains outside this public preview. Broken extracted
item icons are a separate outstanding issue; this package repairs Execute Command
icon paths, not the item icon extractor.

---

# Public Preview 19 — binding caption centering

Version: `0.4.0-a.20261011.public-preview19`. Cumulative overlay; rollback
restores Preview 18 runtime. Preserve config.ini/data; no AHK changes.

Preview 18 live: selecting an icon for a new custom action returns directly to
review (first test passed). User reports Use Item binding text offset right at
960x540. Review found the confirmation caption still used character-count width;
the initial combo prompt already used measured width. Both now use that method.

1. Stop/unload, apply overlay and load. Status should report Preview 19, Ready=true.
2. Use Item: choose an item, check centered initial prompt, capture a combo and
   check centered confirmation. Circle backs out without changing bindings.
3. Check Trade Item, Superwarp, Custom Action, Remove a Binding, Change Icon and
   Set Icon Across Jobs. Both prompts should share the panel's horizontal center.
4. Controller hints stay in their corners. Ordinary binding/execution behavior
   is unchanged; confirm one safe echo/custom action and verify it executes once.

Offline: actual shared prompt/confirmation methods pass for every action type at
960x540, 1280x720, 1600x900, 1920x1080, 2560x1440 and 3840x2160 using nonuniform
glyph widths. Existing review-layout and custom-review checks also pass; changed
Lua syntax and whitespace checks pass. Live centering remains pending.

Discussion backlog, not included here: white Custom Action Name label before
naming; much more opaque cursor; rename Change Slot Icon/Change Action Icon;
icon-first slot-icon workflow; move Execute Command after Remove a Binding before
Credits; investigate blank Execute Command icons. Selected text stays as in
Preview 18 per the user's latest preference. No push/public posting.

---

# Public Preview 18 — custom review and menu polish

Version: `0.4.0-a.20261011.public-preview18`. Cumulative overlay; rollback
restores Preview 17 runtime files. No AHK changes; preserve config.ini and data.

Live Preview 17 on Lionstag: Ready=true, Setup=false (state nil); face buttons
work. User reports the low-resolution menu, cursor, selection colors and page
turning look good. Requested brighter yellow, increased cursor opacity and review
navigation refinements are included here. The existing icon-selection code already
intended to return to review; the exact reported route to binding was not reproduced.
An explicit return destination now protects the custom picker from category changes.

1. Stop/unload, copy the overlay and load again. Verify Preview 18 and Ready=true.
2. Check the brighter selected text and cursor at 960x540; Create Custom Action
   comes first. Empty-catalog actions stay present but disabled.
3. Create a named draft from the menu. Choose Icon: Clear Icon is first, folders
   still navigate normally; choosing an icon returns directly to review. Reopen
   the picker and clear it, then cancel out of a folder/root and verify the draft.
4. Link Action: Skip (no linked metadata) comes first. Select a real action and
   return to review; reopen and skip to remove metadata. Clear buttons are absent
   from review, which now has seven choices. Check both a new and saved action.
5. Check centered two-line help and button-combo captions for Change Icon and
   Set Icon Across Jobs. Confirm hints still match saved controller assignments.
6. Save & Bind, then Circle: draft remains. Exit: draft is discarded. Canceling
   inline typing discards only unconfirmed text; already committed fields remain.
7. Bind a command linked to a spell/ability and verify command execution, icon,
   MP/TP cost and recast presentation. Recheck ordinary bindings and F7/F8.

Offline: all 17 regression groups and changed-file syntax pass; coverage includes
icon choice/clear/back independent of category, draft return and text bounds at
six resolutions. Live refinements remain pending. Two implementation commits plus
one delivery/documentation commit, local only.

---

# Public Preview 17 — no-subjob initialization

Version: `0.4.0-a.20261011.public-preview17`. Cumulative base overlay; rollback
restores Preview 16 runtime files. Fix commit: `8bdb398`. No AHK changes.
Keep existing data and config.ini; the package excludes those and bulk images.

Lionstag finished the face-button wizard in Preview 16, then reported player.lua
165 concatenating nil sub_job, followed by skillchains.lua 345 indexing a missing
buff table. The new load message aborted initialize before ready=true and before
skillchains.load. Unlike the status message, existing storage already supported
NOSUB. This repairs that regression and guards early buff-removal packets.

1. Stop/unload using `//xb controller stop` then `//lua u xivcrossbar`, copy the
   overlay and `//lua l xivcrossbar`. Preserve the saved setup assignments.
2. Run `//xb status`: Preview 17, Ready=true, Setup=false. Check the console for
   errors; report exact lines if initialization still fails.
3. Bare Triangle opens the native menu, Square selects the active window, Cross
   confirms and Circle cancels. D-pad moves only addon selection with its menu
   open; outside it, D-pad follows arrows/ijkl. Native hat switches stay disabled.
4. Test trigger-held slot actions, ordinary keyboard F7/F8 and reload persistence.
5. When controls pass, turn `//xb inputtrace off`. No need to rerun setup unless
   assignments themselves differ from the intended buttons.

Offline: 17 regression groups pass; root/player/storage syntax passes. The actual
skillchain packet handler is tested separately because untouched upstream syntax
elsewhere in that module is Windower-specific. Live readiness/input confirmation
is pending. No GitHub push or public posting.

---

# Public Preview 16 — setup readiness gate

Version: `0.4.0-a.20261011.public-preview16`. Cumulative overlay; rollback
restores Preview 15. Only xivcrossbar.lua changed at runtime. Stop wrapper,
unload, copy xivcrossbar and load again. Existing settings/bindings are retained.

Lionstag_2026.10.11.log raw lines 739-750 and 757-762 show Apps DIK221, R2
DIK88 and Cross DIK63 arriving in setup state 3. R2/Cross have capture=true,
ready=false, blocked=false. The router's unconditional readiness gate therefore
discarded both before the wizard. This update permits setup input while not
ready; outside setup the original readiness protection remains.

1. At first Confirm assignment, hold R2 and tap Cross. The prompt should now
   advance to Cancel. Assign Circle, Triangle (Main Menu), Square (Active Window).
2. On Save Changes, confirm with R2+Cross, then complete the final confirmation.
   Let the addon reload and run `//xb status`: Ready should be true, Setup false.
   If Ready remains false, send status and the console error output so the
   initialization failure can be investigated separately.
3. Recheck bare menu buttons, ordinary bindings and F7/F8 keyboard behavior.
4. Turn `//xb inputtrace off` once the result has been recorded.

Offline: all 16 regression groups pass, including setup input while ready=false
and refusing gameplay input in that same state; changed-file syntax passes.
Observed cause of dropped setup events is established; why full initialization
remained incomplete still requires evidence. Live completion remains unverified.
Local fix commit `9bdb0bb`; packaging/docs follow. No push or public post.

# Public Preview 15 — raw setup input diagnostics

Version: `0.4.0-a.20261011.public-preview15`. Cumulative overlay; rollback
restores Preview 14. Over Preview 14, only xivcrossbar.lua changed at runtime.
Stop/unload before copying, then load again; retain settings and character data.

Evidence: AHK log records Apps and R2/F12 + Cross/F5 edges with clean releases.
A temporary Windower #f5 echo executed from controller. User restored silent
#f5 binding. Existing inputtrace was silent; it logged after capture/readiness
checks, so absence did not identify which check failed.

1. During button assignment, run `//xb status` and `//xb inputtrace on`.
   Report Ready/Setup/Capture status and the trace enabling message.
2. Close chat/console, release all buttons, focus FFXI, hold R2 and tap Cross;
   release. Send all RAW and BLOCKED lines from this attempt. Raw trace includes
   physical typing too while setup is open, so missing controller lines can be
   compared with keyboard lines.
3. Run `//xb inputtrace off` afterwards. No binding replacement needed.

Offline controller/setup regressions and changed-file syntax pass. Tests verify
raw messages precede capture=false, ready=false and blocked=true filtering.
No AHK or controller-routing behavior changes. Cause remains unconfirmed.
Local diagnostic commit `7a26e74`; packaging/docs follow. No push or public post.

# Public Preview 14 — setup hover feedback

Version: `0.4.0-a.20261011.public-preview14`. Cumulative overlay; rollback
restores Preview 13. Stop wrapper, unload, copy xivcrossbar and reload. Bulk
images/sounds, settings and character data are excluded; keep existing files.

1. Welcome: hover the click prompt. Text lifts 2 px up/left with a faint white
   alpha glow. Leave the text: position restores and glow disappears. Clicking
   anywhere inside the welcome background panel still advances to controller
   choices and starts the wrapper.
2. Controller choices: hover each image; image and name lift 2 px up/left.
   Move away: restore. Hitboxes remain fixed, including at image boundaries.
3. Check normal keyboard typing during setup still works. Controller signaling
   is unchanged: continue Preview 13's inputtrace/log investigation below.

Offline setup regression checks cover repeat hover without accumulating shifts,
restoration, fixed click regions, prompt-only glow and hiding during navigation.
Changed-file syntax and whitespace pass. Live appearance still needs review.
Local hover commit `009b273`; package/docs checkpoint follows. No push or post.

# Public Preview 13 — setup keyboard correction

Version: `0.4.0-a.20261011.public-preview13`. Cumulative overlay; rollback
restores Preview 12. Stop wrapper, unload, copy xivcrossbar and load again.
No character data, settings, bulk images or sounds are shipped.

Preview 12 layout passed live on Lionstag. Button assignment still failed;
inputtrace reported nothing. Physical typing failed during setup (Space was
reported to pass). The early setup dispatcher added in Preview 12 consumed
unrelated physical keys; this update passes them through.

1. With setup open, type `//xb inputtrace on` normally, then close the chat input.
   Ordinary typing/console Insert should work; controller setup still owns its
   face buttons and triggers.
2. Release all controller buttons, return focus to FFXI, then hold R2 and tap
   Cross. Record trace output or its absence. The missed confirmation cause
   remains unknown; do not treat this update as a confirmed controller fix.
3. Inspect `addons/xivcrossbar/data/input-transport.log` immediately after that
   attempt. Send the last startup block and subsequent lines. This establishes
   whether the wrapper emitted Apps capture, R2/F12 and Cross/F5 edges.
4. Turn `//xb inputtrace off` after the check. Existing layout/ordinary binding
   checks remain in the previous preview sections below.

Offline: setup keyboard pass-through and controller transport tests pass;
changed-file syntax and whitespace pass. No AHK changes in this update.
Local commit `e1d7630` corrects keyboard ownership; packaging/docs follow.
No push or public post.

# Public Preview 12 — first-run controller setup

Version: `0.4.0-a.20261011.public-preview12`. Cumulative overlay for the base
qEagleStrikerp installation or any previous public preview. Rollback restores
Preview 11. Stop the wrapper, unload, copy xivcrossbar including assets/menu,
and reload. Existing settings, images, sounds and character bindings are retained.

Reported on Lionstag at 960x540: setup did not accept R2+Cross; controller layout
heading overlapped images and the background looked incorrectly scaled. Code
inspection found setup already independent of crossbar scaling, but old insets
made the inner background height negative. ~~Ordinary trigger activation returned before forwarding R2 to the setup wizard.~~
Correction: that explanation was a misread; the original code did forward R2.
Cioara successfully completed fresh setup. Lionstag still cannot confirm on
Preview 12, and inputtrace showed no events with the wrapper running.

1. First-run setup (or `//xb remap` with existing configuration): welcome text
   and controller choices fit inside a centered panel. Select PlayStation by
   mouse; hitboxes should coincide with images. Heading/subtitle stay separate.
2. Hold R2 and press/release Cross: advance from Confirm to Cancel. Then assign
   Circle for Cancel, Triangle for Main Menu, Square for Active Window. Each
   press advances once; a bare face press without a trigger does not assign.
3. On Save Changes, use R2+Cross to save. Complete the last confirmation and
   verify reload, normal menu navigation, trigger bindings and absence of leaks.
4. After setup, `//xb scale 0.6` still affects the crossbar independently. Reopen
   remap only if desired: its fixed-size layout remains readable.
5. Resume Preview 11 XML/set persistence and Preview 10 UI checks below.

Offline: 16 regression groups and changed-file syntax pass. New tests exercise
actual setup input dispatch with actual wizard methods, positive panel dimensions,
heading/image separation and mouse hitboxes at 960x540, 1280x720, 1920x1080 and
3840x2160. Windows/FFXI first-run completion still requires live verification.
Local commits: `3cc952e` setup routing; `e84937a` panel layout and regression.
No push or public post.

# Public Preview 11 — XML failure protection and chat feedback

Version: `0.4.0-a.20261011.public-preview11`.
Cumulative overlay: includes Preview 10 UI changes; rollback restores Preview 10.
Stop the wrapper and unload before copying the ZIP's xivcrossbar folder. Keep
existing images, sounds, settings and character data; include assets/menu.

Reported Preview 9 results: test 1 passed; test 2 passed with requested picker
refinements; tests 3 and 4 passed. R2+Circle binding feedback showed a strange
glyph before Basic. Creating a new set failed at player.lua:204 (`contents` nil).
Controller disappeared from game utilities; exact surface/cause not yet known.

1. Before retrying, preserve copies of the current hotbar XML files. Send the
   exact entered set name and affected XML/log to identify the parse failure.
   This update reports the file and XML parser error and refuses hotbar writes
   after failed loading. It does not repair an already damaged file.
2. Bind an echo to R2+Circle: one echo, unchanged targeting, readable chat ending
   `R2 + Circle - Basic.` (or the selected set's name).
3. Create a uniquely named set such as `Preview Eleven` through the menu;
   confirm chat feedback, bind an echo, then reload and verify persistence.
   A file-specific XML error means stop this test and retain the XML for review.
4. Invalid names such as `Slash/Name` or `Question?` should be rejected while
   existing sets and bindings remain available. Renaming has the same validation.
5. Continue Preview 10's name-first entry, cursor, selection lift and trigger
   paging checks below. These visual changes have not been confirmed live yet.

Offline: all 15 regression groups pass; changed-file syntax and whitespace pass.
New tests exercise the actual loader's nil/wrong-root cases and both storage
write guards, including automatic default-file creation. Windows controller
availability and the original XML failure's cause remain unverified.
Local commits: `9b61a25` load/write protection and set validation; `302451e`
ASCII chat feedback. Documentation/package checkpoint follows. No push or post.

# Public Preview 10 — name-first creation and menu navigation

Version: `0.4.0-a.20261011.public-preview10`.
Maintenance initially interrupted Preview 9 testing. Follow-up: tests 1-4
passed, subject to the recorded picker design changes. Set creation later failed
at player.lua:204. Preview 10 UI changes remain awaiting live verification.

Install the cumulative overlay after stopping the wrapper and unloading. Copy
all of xivcrossbar, including the small **assets/menu** folder. Bulk images,
sounds, config.ini and character data are excluded. Rollback restores Preview 9.

1. Bare `//xb ca` and menu Create Custom Action immediately open Custom Action
   Name entry; no option buttons above it. Other fields are inactive. Empty name
   and duplicate name confirmation stay in entry. A unique name unlocks the
   review. Enter or controller Confirm commits; Circle cancels to the command's
   exit or the menu page, respectively. Typing must not open native menus/chat.
2. `//xb ca Bow` still opens a named review directly; existing exact names edit.
   Alias/Command defaults remain green in parentheses and blank in XML. Recheck
   Save Only, Save & Bind, Circle return, name-only alias execution and reload.
3. Navigate with D-pad and mouse: selected icon, frame and label lift 2 px up
   and left; the previous option restores. Golden cursor follows selection,
   glints at 12 fps and disappears with the menu. Check its brightness/placement
   and the warm brown/gold selection at 960×540 and a larger resolution.
4. Icon picker: top-level Goring Blade sample is absent; weaponskill icons in
   their own folders remain. Directory/PNG selection and Circle back work.
5. A multi-page list: L2 highlights Previous, R2 highlights Next. No turn until
   release; one turn per gesture. Face/D-pad input while held consumes the turn.
   Both trigger orders select their respective directions and commit once.
   Rounded dark-blue buttons show L2/R2 icons; active buttons become brown/gold.
   Option selection stays in place or moves to the nearest valid last-page entry.
6. Ordinary binding combos still work, including trigger+Circle. Trigger input
   while binding must capture the combo rather than turn a page. Bare Circle,
   Cross, Share, Options and physical F7/F8 retain the tested behavior.
7. Continue unfinished Preview 9 checks below: typing isolation, new set flow,
   Superwarp, dragging/visibility, fade text and persistence across reloads.

Offline: 14 regression groups pass, plus changed-file Lua syntax and whitespace.
Cursor lifecycle is exercised against the actual playback helper; selector
position restoration and name-gated drawing have regression coverage. Windows
FFXI rendering/input still require the checks above. No public posting yet.

# Public Preview 9 — release candidate testing, October 11, 2026

Version: `0.4.0-a.20261011.public-preview9`. Cumulative update overlay for a
qEagleStrikerp base install. Keep your existing images, sounds, settings and
character data. Copy only the ZIP's `xivcrossbar` contents over that installation;
do not copy the rollback folder. Stop the old wrapper and unload before copying.
Restart with controls released. No personal L1 companion is included.

**First checks, in order:**

1. `//xb status`: Preview 9, PS5 DirectInput / apps; input diagnostics off.
   Native movement/camera work; disable native D-pad/face/trigger assignments
   and hat-switch menu input as in the tested setup. Bare Triangle opens the
   game menu, Square focuses selection, Cross confirms, Circle cancels.
2. `//xb ca`: Save options are dim and skipped until Custom Action Name is
   supplied. Explore Choose Icon before naming: folders open without errors;
   Circle returns. Enter a name and repeat Choose Icon, pick an icon, return.
3. Edit Name/Alias/Command inline; type spaces, punctuation, both Shifts and
   `input /echo Preview nine`. No inventory, action menu or native chat opens.
   Enter commits; Circle cancels; Escape exits. Then type normally in the game
   and open/close the console with Insert. Check this before longer testing.
   If typing becomes blocked after leaving an editor, unload the addon; if
   necessary run `//keyboard_blockinput 0` from Windower's console.
4. Save & Bind a real echo; Circle from binding restores the review, Share
   exits. Reopen by exact name. Save blank-command Bow and verify alias/name
   fallback. Reload and confirm both actions and bindings persist.
5. Menu Create New Set: type a disposable name, Enter; one creation message,
   back to main menu, no alias/icon/bind steps. Switch to the set explicitly.
   Repeat the name: reject without losing its existing bindings. Test the
   Options chooser's Add New Set text entry too, including spaces/punctuation.
6. Superwarp main icon is Home Point. Bind a known unlocked destination anew;
   verify its crystal icon and actual warp. Existing old bindings are preserved.
   Also confirm Execute Command's icon and no picker errors in other lists.
7. `//xb scale 0.6`, `hide`, `show`, `auto`, `autohide off`: actions continue
   working in each mode. Check full and compact fades for caption flicker.
   Explicit show should redraw without needing a reload.
8. Drag with a menu open. Open Move Crossbars while hidden: bar becomes visible,
   D-pad and drag both move it; Circle leaves and restores prior visibility.
   Position persists after reload. Menu choices still respond to mouse clicks.
9. First row is Custom Action/Create/Edit/Delete; four columns maximum, more
   spacing, Remove Binding immediately before Credits. Check 960×540,
   1280×720, 1600×900, 1920×1080, 2560×1440 and 3840×2160 as available.
10. Regression: L2/R2 and both trigger orders, face and D-pad actions each fire
    once; no target change/native macro popup; physical F7/F8 and Ctrl binds
    retain their normal functions. Test client switching and wrapper stop/start.
    Binding/clearing messages appear once in chat with the correct combo/set.

**Recorded live baseline:** Preview 8 Insert behavior improved; ordinary
Apps-trigger actions, navigation, Bow fallback, IJKL, dragging, scaling and reload
persistence passed. Preview 8 had typing leakage, icon-picker crashes, unnamed
save failures, menu Create New Set misrouting and text fade flicker. These are
fixed in code here and remain live-test targets, not claimed live passes.

**Offline validation:** 13 Lua regression groups, changed-runtime syntax and
patch whitespace checks. Review anchors checked at six resolutions. Tests use
Lua 5.4 with Windower stubs; no Windows/FFXI/AHK execution here. A whole-repo
parse encounters unchanged Windower string-method syntax in skillchains.lua;
that dependency is not rewritten by this update.

**Deferred:** Help/status wording review together, Display/Controls menu,
caret/paste editing, general item-icon extraction repair, other controller
wrappers/XInput, visual polishing and the personal companion. No new Display
menu or personal-control features are introduced.

**Rollback:** stop wrapper, unload, copy `rollback/xivcrossbar` back over the
addon. It restores the runtime files changed since Preview 8; extra unused new
modules may remain. Your data/assets stay untouched. Keep a separate backup of
your own data before testing set creation/deletion.

# Public Preview 8 — first live-test corrections, October 11, 2026

Version: `0.4.0-a.20261011.public-preview8`. Cumulative BASE update only.
Stop the old AHK process and unload before overlaying; restart with all buttons
released. This version installs AHK's keyboard hook so physical Apps/Ctrl checks
can distinguish injected presses. Quiet modifier edges are logged to
`data/input-transport.log`. Windows behavior remains to be verified.

1. Test Insert before and after one bare Cross press/release, with console open
   and closed. Also check a trigger/slot press, focus away/back, and ordinary
   typing. If Insert fails, preserve the transport log; do not assume fixed.
2. Open the chooser and hover Add New Set: no ui.lua:758 error should recur.
   Create a disposable set normally; retain the duplicate-protection check.
3. Binding screen: bottom-right Confirm is dim before a combo is captured;
   Back dims while triggers are held. Both become normal at confirmation.
   Bare Circle returns, trigger+Circle remains bindable, Share exits.
4. Main options stay at most four per row, centered with uniform spacing.
   Create Custom Action and Remove Binding exchange positions; other order stays.
5. No Allow stpc diagnostic. Default now true; explicit retained false settings
   need manual change to AllowSTPCForSelfTargetedActions=true, then reload.

Live Preview 7 report: all tested L2/R2/combined-trigger face and D-pad slots
execute without native input leakage; echo binding and name-only Bow work;
right/left Shift, punctuation, Save & Bind return and IJKL targeting work.
Unresolved: native gameplay/chat typing leakage in inline fields; Insert after
Cross (hook correction awaits test); welcome text flicker; review-screen clarity;
text editing has only append/backspace, not arrow-key caret navigation.

Offline checks cover chooser placeholders and sparse sets plus the prior nine
regression groups. AHK's hook behavior cannot be verified in this Linux runtime.
Runtime checkpoint before wrapper correction: 7de59f6.

# Public Preview 7 — direct-action Go Back correction, October 11, 2026

Version: `0.4.0-a.20261011.public-preview7`. Same cumulative BASE installation
rules as Preview 6. Native menus and addon D-pad/Confirm/Back/Exit passed live
in Preview 6. Switch Target -> binding -> Circle hit a missing selection-state
error at action_binder.lua:1303; this update restores the original main-menu page
for direct binding entries (Switch Target, View Map, Last Synth, Remove Binding).
Offline regression covers all four entries. Retest those paths with bare Circle.

Insert became usable after stopping AHK. This is recorded as an unresolved
transport interaction, not established as a stuck Apps modifier. Wrapper code
is unchanged. Restart with all controls released, then test Insert before any
controller press and after a simple press/release. Do not hold controller keys
while opening the console. If it recurs, preserve data/input-transport.log.

# Public Preview 6 — optional gameplay D-pad letters, October 10, 2026

Version: `0.4.0-a.20261011.public-preview6` (UTC stamp).
Same cumulative BASE update installation rules as Preview 5 below.

## Short first play-through

Start with diagnostics off (`//xb inputtest off`, `//xb inputtrace off`).
Use Preview 6 already supplied; the extra smoke checks changed no runtime code.

- Open `//xb ca "Bow"`, edit one field using right Shift, cancel that edit with
  Circle, then Save & Bind. Circle back once to verify the review survives.
- Execute one known bound action with a trigger: one action, stable target,
  no native macro pop-up. Confirm bare Cross/Circle still behave normally.
- Try `//xb dpad ijkl` with your native keyboard assignments. Browse the addon
  menu, execute a D-pad slot, then restore `//xb dpad arrows`.
- Drag the crossbar somewhere pleasant, reload, and keep playing. The position,
  action and D-pad choice should survive. Report the first surprise as it happens.

Deeper multi-client and resolution checks below can wait for the next session.
Additional offline checks exercise real review drawing calls at all six sizes,
inline rectangles, long-value truncation, unsaved draft isolation, and actual
D-pad command persistence/release/invalid-input handling. These check geometry
and behavior, not rendered font widths or the game's response.

## Detailed checks

1. Default `//xb dpad arrows`: bare D-pad sends regular arrow keys.
2. `//xb dpad ijkl`: Up=I, Left=J, Down=K, Right=L. Test your chosen native
   keyboard assignments. The addon changes output, not FFXI's configuration.
3. Verify addon menu navigation and trigger-held slot actions remain unchanged
   in letter mode, without native letter-key leakage from those contexts.
4. Switch mode while holding a direction: old gameplay output must release;
   release and press again for the new mode. Check focus loss also releases it.
5. Bare `//xb dpad` toggles; reload preserves the mode. Restore arrows when done.
   Letter mode can type letters into native chat; check that tradeoff explicitly.

Offline checks cover all four letter mappings, ordinary face-button output,
logical menu/slot routing, and release ownership across a mode change. Eight
regression checks and changed runtime syntax pass. Windows live tests pending.
Implementation checkpoint: 53b780b. Help text remains reserved for joint review.

# Public Preview 5 — three focused fixes, October 10, 2026

Version: `0.4.0-a.20261011.public-preview5` (UTC build stamp).
Same cumulative BASE update and installation rules as Preview 4 below.
Help text is deliberately unchanged pending review together.

1. Create a disposable set, bind one action, then try creating the same name
   again using different capitalization. The command must reject it and preserve
   bindings through reload. Also check reserved names and ordinary new creation.
2. In a custom action, set Command to spaces only. Bind and execute: it should
   use Alias, then Catalog Name if Alias is also spaces only. Catalog XML keeps
   the entered values; executable slot fallback agrees with the review.
3. Edit an inline field using right Shift for capitals and punctuation. Hold
   both Shift keys, release either, and verify the other still works. Verify
   ordinary unshifted typing after releasing both.

Eight offline checks pass, including actual set creation preserving existing
bindings, real slot binding whitespace fallback and both Shift press/release
orders. Changed runtime files pass syntax checks. In-game checks remain pending.
Local checkpoints: b0236f1 (sets), a19ea51 (fallback), b1c692f (Shift).

# Public Preview 4 — single-screen custom actions, October 11, 2026

Version: `0.4.0-a.20261011.public-preview4`. Cumulative BASE experiment update;
use the installation and rollback instructions below. This is not a personal
Batch 19 overlay. No settings, profiles, images, sounds or companion included.
Existing base assets are required. Catalogs remain per character.

## Live checks for this preview

1. Open `//xb ca "Bow"`. Check Catalog Name, green `(Bow)` Alias and Command,
   and optional `(none)` fields. Save Only. Verify no command is filled into
   CustomActions.xml. Bind it from Custom Actions and execute a known Bow alias.
2. Open the same exact name: it should edit that record. Test the old
   `//xb ca new <name>` and `//xb ca a/n/c <value>` forms.
3. Edit fields inline: spaces, uppercase letters, punctuation and a semicolon
   command chain. Enter commits; Circle cancels; clearing Alias/Command restores
   green defaults. Check no typing reaches native chat or triggers gameplay.
4. Save & Bind, then Circle back to review. Verify the saved draft survives.
   Bind a slot and check exactly one execution with no native input leakage.
   Trigger+Circle must remain bindable; bare Circle goes back.
5. Choose an optional icon or linked action, cancel or accept, and return to
   review. Clear each. Reject blank catalog names and duplicate renames.
6. Open Create Custom Action from the menu: Circle returns to the main menu;
   command-opened review exits. Confirm unrelated set/icon workflows still work.
7. Inspect at 960x540, 1280x720, 1600x900, 1920x1080, 2560x1440 and 3840x2160.
   All nine review choices, values, inline field and hints should fit. Confirm
   ordinary lists restore their normal layout after leaving review.
8. Reload and verify records and bound slots survive. Repeat on another client
   with its own catalog. Retest targeting, scaling, dragging and visibility.

Offline checks pass: real review transitions, command compatibility, effective
fallbacks, duplicate-name validation, and the actual XML serializer leaving
blank defaults absent. Existing transport, bounds, visibility, presentation and
mouse checks also pass. Lua syntax checked through Lua 5.4; Windows/Windower Lua
5.1, controller input and visual appearance still require the live checks above.

# Public Preview 3 — directly draggable crossbar, October 10, 2026

Version: `0.4.0-a.20261011.public-preview3`. Same BASE-experiment installation
rules as Preview 2 below. This cumulative update needs existing assets and is
not an overlay for personal Batch 19. No settings, profiles, images or sounds.

Left-click and drag the visible crossbar, then release to save. No lock/unlock.
Test at scales 1 and 0.6, in compact and full layouts: all slots, labels, recasts,
trigger backgrounds and indicators move together. Reload must preserve exactly
the new position. Verify normal clicks outside the bar still reach the game.
Hidden bars and bars under the addon menu/chooser must not capture mouse input.
Changing visibility during a drag finishes and saves that gesture.

The existing offset calculation added saved values twice; this preview applies
them once. Old nonzero positions may consequently move once on first install;
drag to your preferred position and reload to verify it stays there.
Local mouse-gesture checks pass; actual Windows dragging remains untested.
Source checkpoint for scaling/fades: d80d453; documentation: e31f12c.

# Public Preview 2 — crossbar scaling and fades, October 10, 2026

Version: `0.4.0-a.20261011.public-preview2` (UTC build stamp).
This UPDATE ZIP is for the upstream-based Apps experiment, **not the personal
Batch 19 install**. Preserve the whole existing folder before applying it.
No images, sounds, data, character profiles, config.ini or personal companion are
included. Existing base assets are required. Stop the wrapper, unload every
client, overlay the included xivcrossbar folder on that BASE installation, then
load again. Do not overlay this on our personal branch: its catalog/editor
behavior differs. Keep the two installations separate.

Commands: `//xb ui scale 0.6` (range 0.25-2), `//xb ui fade [on|off]`
(bare toggles), and the existing visibility commands below. Settings persist.
Defaults: scale 1; fades enabled; FadeIn 0.24 seconds, FadeOut 1 second,
LoadFadeIn 3 seconds. Animation values are editable in data/settings.xml.
Menu scaling, page animation, FFXI skin and sounds are not part of this port.

## Live checks for this preview

1. Confirm version using `//xb inputstatus`. Use `//xb inputtest off` and
   `//xb inputtrace off` if retained experimental settings enable them.
2. At scale 1, compare the base layout; then try 0.6, 0.8 and restore 1.
   Check labels, costs, recasts, controller hints and trigger backgrounds stay
   aligned in both full and compact layouts. Check three/four/six bars as used.
3. Test Lionstag at 960x540 and Franklet at 1280x720; larger screens when handy.
   Scaling the bar must leave the binder unchanged. Reload preserves the scale.
4. `//xb autohide on`: hold/release triggers to reveal/hide the bar. Release and
   quickly press again while fading: opacity should reverse smoothly.
5. `//xb ui hide`: slot actions still execute, but no icons or combat indicators
   appear. `//xb ui show` restores the bar. Test changing sets while hidden.
6. Toggle fades off/on. Off should immediately show/hide; on restores smooth
   transitions. Initial load uses the longer welcome fade.
7. Repeat target-preservation, ordinary menu navigation, physical F7/F8, reload
   and two-client checks from the earlier routing record.

Local checks cover actual geometry surfaces/primitives, time-based reversal,
complete hiding, disabled fades, routing and six menu bounds. Available parser
is Lua 5.4; Windower and Windows AHK execution still require your live checks.
Rollback: stop wrapper/unload, restore the backed-up base folder, and reload.

# Public coherent update — development checkpoint, October 10, 2026

Branch: `public/coherent-update`. This is work in progress, not a delivered ZIP.
Upstream master was checked through GitHub on October 10 and still resolves to
`15d8381dfad0f9efdb84fe2d24655afc150faec4`, matching our existing runtime snapshot.
Starting local checkpoint: `0865014`. No personal companion or personal controls
are imported. No commits have been pushed and no PR has been opened.

The first implementation adds `ControllerModifier` (`apps`, default, or `ctrl`).
Lua capture, silent bindings and wrapper startup use the same selected modifier.
This is **not** an exact reproduction of the upstream wrapper: it retains our
context routing and edge ownership. Ctrl mode intentionally reserves Ctrl+F1-F12
and may bring up native macros; Apps is recommended.

Changing transport requires stopping the shared wrapper, unloading every client,
editing ControllerModifier consistently in their settings, and loading again.
The first client starts the shared wrapper; existing processes do not hot-reload.
There is deliberately no runtime toggle that could split Lua/wrapper state.
Neither mode restores personal bindings overwritten on its reserved combinations.

Local routing checks pass for both markers. Windows/AHK startup arguments, Ctrl
mode, and transitions require live tests before this is presented as supported.
Menu positioning now uses one centered panel independently of crossbar offsets;
logical bounds are checked at 960x540, 1280x720, 1600x900, 1920x1080, 2560x1440,
and 3840x2160. Selectors have positive page capacity and at most four columns.
This is not yet independent menu scaling or proof every detailed screen fits.
Live check: opening the first menu should align backdrop/title/options at each
resolution, including with nonzero crossbar Style offsets. Check deeper dialogs.
Visibility commands now persist: `//xb ui hide`, `show`, `auto`, and
`//xb autohide [on|off]` (bare toggles). Hidden mode does not disable actions.
~~This initial port has immediate transitions, not our personal branch fades.~~
Preview 2 adds the existing elapsed-time fades and coherent crossbar scaling.
Live checks: hiding keeps slot actions working; auto shows only while triggers
are held; show restores the bar; reload/set changes respect the selected mode.
Still pending: independent menu scaling, navigation, editor fixes,
clean user README and packaging. Earlier test records follow unchanged.

## October 9 live checkpoint and shutdown diagnosis
All eight slots and tested trigger combinations passed silent interception; addon menu isolation, bare Cancel, and native keyboard F7/F8 passed. Bare Triangle should become main menu and Square active-window focus in the next test.
Shutdown cause found: v1 label-style OnExit handler ended with return, cancelling normal termination. Changed it to ExitApp after release cleanup; live validation still pending. This correction is not included in the already delivered Test3 ZIP.

# Apps + F1-F12 Test 3 — silent native interception

Overlay the included xivcrossbar.lua onto the Test 2 base experiment. Reload the addon in each client (//lua r xivcrossbar). No AHK or profile changes; preserve current bindings and settings.
Real output: //xb inputtest off. Trace: //xb inputtrace off.
On load this build reserves Apps+F1-F12 using Windower bind commands targeting xivcrossbar inputconsume. Installation announcements may appear once per load; button presses produce no interception echo. Unload unbinds these twelve combinations. Existing personal bindings on these combinations are replaced, not restored automatically; record and restore them manually if desired. Plain F-keys and Ctrl/Alt binds are untouched.

Live evidence: Apps+F7 test echo prevented self-targeting while both the real slot echo and ordinary Cancel/menu Back still worked. Lua's blocked-flag handling is deliberately unchanged; test other keys before altering it.

First test: target someone else; hold R2 and tap Circle in Input Test. Expect one slot echo, unchanged target, no interception message. Then bare Circle cancels. Next repeat all eight slot buttons and trigger states while checking native targeting/menu leakage. With both menus open, only addon selection should move. Plain keyboard F-keys without Apps retain native behavior.

Wrapper shutdown, held-focus cleanup and 540p layout remain deferred. Rollback: restore Test 2 xivcrossbar.lua and reload; restore any desired personal Apps binds afterward.

---
# Apps + F1-F12 Test 2 — 2026-10-09

Build: 0.4.0-a.20261009.base-apps-fkeys-test2. Real output ON; trace OFF.
Transport commit: 3dde617. Shutdown and held-focus cleanup remain unresolved and deferred.

## Install into the existing BASE experiment
Exit the old ffxi_directinput.ahk through Task Manager if necessary before replacing files. Unload xivcrossbar in both clients. This ZIP contains only the changed runtime files and the two snapshot profiles; overlay its xivcrossbar folder onto the existing BASE-APPS-UNCOMMON-TEST1 installation. It is not a patch for the personal Apps-L1 build.
Back up the current data/hotbar/Fenrir/Franklet and Lionstag folders first: supplied XMLs replace those profiles with the October 8 17:55 snapshot. No settings.xml is supplied.
Load/reload xivcrossbar, then run //xb inputtest off and //xb inputtrace off IN EACH CLIENT: existing settings override defaults.
Keep native HAT Switches DISABLED, native sticks enabled, DirectInput enabled.

## Binding provenance
Franklet BST-WHM and BST-DEFAULT, Lionstag RDM mappings, and all other supplied character XMLs come from xivcrossbar_10-8-2026-1755-return-testing.zip. These are the latest available copies here, not a claim about changes made afterward.
Original actions and bars are preserved. A separate Input Test set was added to Franklet BST-WHM and Lionstag RDM-NOSUB. All 32 slots execute real input /echo commands identifying character, bar, and slot. Use the existing set chooser (hold Options, D-pad Up/Down, release Options) to select Input Test. Lionstag must be RDM/NOSUB for that set; other jobs use their original snapshot bars.

## Live tests, one at a time
1. With no addon menu or trigger, D-pad moves the game menu; Cross confirms and Circle cancels.
2. Select Input Test. Hold L2 and press each direction/face: exactly one labeled echo per press. Repeat with R2, L2 then R2, and R2 then L2. Check target and native menu cursor for leakage.
3. Use the original Basic set for real BST/pet commands as desired; watch target preservation, especially Circle/F7.
4. With both addon and game menus open, D-pad moves only the addon selection; Cross confirms, Circle backs out.
5. Keyboard F1-F12 WITHOUT Apps retains native behavior. Do not retain the manual #f7 test bind during the Lua-only leakage check; restore your personal bind afterward if desired.
6. Toggle //xb inputtrace on only if diagnosing failures. //xb inputtest on restores dummy mode.

Prior live results: HAT disabled blocks native D-pad but keeps sticks/camera. Uncommon transport routed all trigger states and menu directions; held repeats did not duplicate actions. Held focus switch needed one clearing press. Mail/MediaSelect launched Windows applications; Kanji and MyComputer lacked useful DIKs; BrowserSearch opened Start. These candidates are replaced entirely by F1-F12 in this test.

Rollback: exit the wrapper, unload addon, restore Test1 runtime files and backed-up profiles, reload. Restore native HAT only if returning to native D-pad routing.

---
## Previous test record

# Base Apps + uncommon signals — Test 1, October 9, 2026

## What this package is

An isolated PS5 DirectInput experiment based on qEagleStrikerp/xivcrossbar master
commit `15d8381dfad0f9efdb84fe2d24655afc150faec4` (August 1, 2026).
Runtime source and assets were verified against upstream blob hashes. The local
baseline is a runtime snapshot, not a clone of upstream Git ancestry; editable
PSD source artwork and README screenshots are omitted from the installation.
Branch: `experiment/apps-uncommon-signals`. See CHECKPOINTS.txt for local commits.
No commits have been pushed. Existing personal development remains separate.

Version: `0.4.0-a.20261009.base-apps-test1`.
This includes the base UI and features, not the personal Batch 17/18 visual,
custom-action editor, shared-catalog, L1 bar, PS, or touchpad modifications.

## Changes and defaults

- Apps replaces Ctrl capture. No global unbind of F1–F12 or Ctrl shortcuts.
- Every digital input below sends the same signal in every context.
- Lua chooses ordinary gameplay, crossbar, setup, binder, text, or set chooser.
- Press ownership persists until release; repeated downs are suppressed.
- Entering a trigger/menu context releases generated held gameplay keys.
- Dummy gameplay and slot commands ON; trace ON. Existing XML is not needed.
- PS5 mapping: Cross confirms, Circle cancels, Square opens native main menu,
  Triangle changes active window. DirectInput wrapper only; XInput and other
  supplied upstream scripts are not remapped and must not be launched here.
- One persistent AHK v1 script; loading another client does not replace it.
- Stop: `//xb controller stop` or Ctrl+Alt+F12. Start: `//xb controller start`.
  The stop command affects this new script, not an already-running old wrapper.
- No timed automatic shutdown. Explicit stop is provided.

## Candidate signal table

None of these twelve has been confirmed by this new live test. The DIK column
is the expected DirectInput code, not an observed result. AHK explicitly requests
both a virtual key and scan code. UNMAPPED results must be investigated.

| Controller | Candidate | AHK output | Expected DIK |
|---|---|---|---|
| D-pad Up | Kana | vk15sc070 | 112 |
| D-pad Right | Convert | vk1Csc079 | 121 |
| D-pad Down | Nonconvert | vk1Dsc07B | 123 |
| D-pad Left | Kanji | vk19sc094 | 148 |
| Cross | Yen | vkDCsc07D | 125 |
| Square | Mail | vkB4sc16C | 236 |
| Circle | Media Select | vkB5sc16D | 237 |
| Triangle | My Computer | vkB6sc16B | 235 |
| Share/Create | Browser Favorites | vkABsc166 | 230 |
| Options | Browser Search | vkAAsc165 | 229 |
| L2 | Browser Back | vkA6sc16A | 234 |
| R2 | Browser Forward | vkA7sc169 | 233 |

Apps (DIK 221) is held while any of these inputs is held. No F-key slot or trigger
markers are emitted. Japanese input mode or Windows application/browser effects
are possible; the user explicitly chose these candidates for testing.

## Install without mixing builds

1. On Franklet and Lionstag, unload XIVCrossbar. Their reported older
   `0.4.0-a.20261008.17-Apps-L1` build does not have controller stop. Exit its AHK
   wrapper through its tray icon or the identified process. Also exit the old
   HIGH-FKEY-PROBE script and unload fkeyprobe if still loaded. Keep clients open.
2. Move the current `addons/xivcrossbar` folder into a backup location outside
   `addons`. Preserve the whole folder, especially data and controller settings.
3. Put this package's new `xivcrossbar` folder into `addons`. This is a fresh
   install, NOT an overlay. Do not copy personal data/settings into this test.
   It supplies config.ini; resources and blank profiles generate on first load.
4. Clear native gamepad assignments for D-pad and the twelve buttons above.
   Keep analog movement/camera. This test does not translate L1/R1/L3/R3/PS/Mute
   or touchpad. Retain any native personal assignment you wish for those buttons.
5. Load only the test client first: `//lua l xivcrossbar`.
   Run `//xb inputstatus`; confirm the test version and InputTest=true.
6. FFXI must be focused. Release all twelve buttons before testing; focus changes
   require neutral input before the script rearms. Run plugin and AHK v1 required.

## Live tests — first signal identity, then routing

1. Tap each of the twelve buttons individually. Expect one named DOWN and UP
   with the DIK above. Face/D-pad presses outside menus also print a gameplay
   dummy message. Share opens the original binder; close it with Share before
   continuing single-button checks. Options shows the chooser while held.
2. Any UNMAPPED/DIK=0 or unexpected Windows effect: note the physical button and
   stop that part of the test. Send chat log plus data/input-transport.log.
   Do not assume a missing signal is successful because AHK logged it.
3. Hold L2 and tap each direction/face: expect eight dummy slot messages on bar 1.
   Hold R2: bar 2. Hold both: bar 3 with the default three-bar configuration.
   Four/six-bar trigger order and double-taps remain the upstream implementation.
4. Open the binder with Share; RELEASE Share and both triggers. Directions should
   navigate it without a trigger. Cross confirms and Circle cancels according to
   the base UI. No gameplay or crossbar action messages should occur alongside
   menu input. This is real menu navigation; avoid saving bindings during routing
   checks unless deliberately testing the binder. No new menu design is included.
5. Hold Options and test Up/Down to change sets. Other slot buttons are consumed
   without firing actions, including while a trigger is also held.
6. Hold a face button while opening/closing a menu or changing triggers. No new
   action should fire merely because the context changed. Release and press again
   to act in the new context. Check focus switches require release before rearming.
7. Press physical keyboard F1–F12, including F7 while holding R2: they should keep
   their ordinary behavior and not execute dummy slots. Ctrl macro behavior should
   remain available on the physical keyboard; Apps controller input should not
   open native Ctrl macro palettes.
8. Stop with `//xb controller stop`, verify digital translation ceases; start with
   `//xb controller start`. Check Ctrl+Alt+F12 as the script-only emergency stop.
9. After signal identity and dummy routing pass, `//xb inputtest off` enables real
   gameplay key translation and existing bound slot execution. Re-enable with
   `//xb inputtest on`. A bare command toggles. `//xb inputtrace off|on` controls
   logging. This package has blank crossbars unless you deliberately bind actions.

The dummy mode reports held edges but does not exercise real native arrow repeat.
Real key holds, release on focus loss, multi-client behavior, Windows effects,
and AHK execution require live testing. Do not label those passed from local tests.

## Rollback

Stop this script (Ctrl+Alt+F12 works outside FFXI), unload the test addon, move
its folder aside, restore the complete previous `xivcrossbar` backup, and load it.
Restore native D-pad assignments if returning to the old routing design. No old
bindings/settings were overwritten because installations were kept separate.

## Local validation

Changed Lua files parse in the available Lua 5.4 runtime; no Lua 5.1/Windower
runtime or Windows AHK interpreter is present here. Tests cover twelve unique
logical candidates, held ownership, repeats, dummy key and actual slot execution,
menu routing, chooser exclusion, transitions, capture-loss release, physical F7,
and unmapped logging. Unchanged upstream uses Windower Lua syntax extensions
(e.g. string-literal :format); a blanket standard-Lua parse cannot validate those.

## Prior evidence and materials

- First higher-F probe: F13/F14/F15 received as 100/101/102. F19/F20 received as 0.
- October 9 supplied HIGH-FKEY-PROBE.log records all twelve F13–F24 outputs with
  376 downs and 376 ups. Franklet's supplied chat log includes distinct 100–102,
  repeated zeros, and an annotated L2/R2 test yielding zero. Do not map zeros.
- Franklet/laptop baseline is Batch 17 Apps-L1, not Cioara's complete Batch 18.
- ~~The long log proved automatic shutdown failed.~~ Correction: the user may
  have reset the probe; a timer failure is unconfirmed. This version uses explicit
  stop controls rather than assuming a timed diagnostic session.
- Deferred: configurable mappings, personal addon/L1 palette extraction, keybind
  combinations beyond this fixed layout, //xb move / always-draggable experiment.

Sources: https://github.com/qEagleStrikerp/xivcrossbar/tree/15d8381dfad0f9efdb84fe2d24655afc150faec4
and https://docs.windower.net/commands/keymapping/.
