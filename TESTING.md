# Current Development Status — October 20, 2026 (America/Chicago)

- Repository/branch: rerorriM-Mirrorer/xivcrossbar, development/directlink. Tested starting source d383d2d8d369f49a9acf3da1b6a61f5facd6297a (Controller Timing 1).
- Runtime: directlink1-status1. Shared Controls 9.11-timing1 is unchanged. User reports Timing 1 installed; paired live logs identify housekeeping as the dominant slow stage (details below). No input fix claimed.
- Status Cleanup 1 + menu wrap: shared editor selector wraps within its current row/column, skipping missing/disabled cells without changing pages. Help-palette formatting, compact status summaries, explicit details for protocols/counters/storage/full bank bindings, single-line feedback for bank changes and swaps. No input-route, timer, bank mapping, visibility default or saved-data changes. Wrapping affects editor selection only.
- Live checks pending: //xb status and //xb controller status with and without details; //xb inputstatus; change a bank visibility/menuactions setting and expect one confirmation; //xb bank l1 status details lists bindings. Verify readable colors/line lengths in actual client windows. Reload Lua only after overlay; no AHK restart needed when Timing 1 is already running.
- Automated validation: see dated entry below. All checks are simulated/static; no Windows/Windower/FFXI runtime available.
- Next: isolate lifecycle registration/stop-request housekeeping costs in the supplied Timing 1 capture. Blood Pact chooser, Share/Options swap, menu hold repeat and other controller behavior requests remain separate pending work.

---

# Menu wrapping addendum — October 20, 2026

User requested row/column wrapping while Status Cleanup 1 was being packaged.
Included as a separate coherent selector change. Left/Right wrap in the same row;
Up/Down wrap in the same column. Missing/disabled cells are skipped. Existing
page-button cells remain selectable; wrapping never changes the page itself.
A lone selectable cell stays selected without extra highlight calls. Empty rows
and columns terminate safely. This does not add held-repeat or modify native
FFXI menus or the separate environment chooser.

Timing 1 live capture received: controller-input-trace(8).log and
controller-lua-trace-Cioara.log (UTC start 20261021003145). Of 124 logged slow
cycles, housekeeping was the largest measured stage in 117. Its maximum was
344 ms; controller hardware was generally 0 ms. Housekeeping encloses the
client-registration lifecycle check and stop-request check; it does not yet
isolate an individual Windows I/O call. This narrows the next investigation to
that path rather than proving a device fault or changing timeouts here.

---


# Status Cleanup 1 — October 20, 2026

Current GitHub AGENTS/WORKFLOW/TESTING read before changes. Ideal: clear first-line
state, stable ordering, the established chat/help palette and one confirmation
per change. Established problem: each bank mutation called full status (including
both binding maps); root status mixed storage, controller compatibility and UI
fields in long ungrouped lines. Baseline d383d2d / Timing 1 retained unchanged
input/AHK behavior. This batch replaces presentation and command feedback only.

Commands:
- //xb status: version/readiness/set, crossbar layout/input, four bank summaries,
  then controller summary. //xb status details adds controller diagnostics and
  storage/lifecycle/editor state.
- //xb controller status: Controls version, readiness, selected device, active
  versus requested route, reset/recovery and tracing. details adds counters,
  protocols, timing maxima, IJKL/F8 settings and launch source. Missing/old wrapper
  warnings are consolidated; absence never displays an active messages route.
- //xb bank <layer> status: short panel report, including copyable position.
  details lists each normal/menu binding on its own row and input/output counters.
- Bank mutations and swaps produce one specific confirmation, no automatic
  binding dump. Existing save/release behavior is preserved.
- //xb inputstatus uses the same headings, labels and neutral white values.

Install: back up, unload/reload XIVCrossbar in each client after merging the
cumulative code-only ZIP. Keep data and artwork. The wrapper bytes match Timing 1;
do not restart a working 9.11-timing1 process solely for this presentation update.
If updating from an older build, follow the Timing 1 matched-wrapper instructions.
Rollback: restore previous Lua files while unloaded; saved data is unchanged.

Validation: all 58 top-level Lua regressions passed with the Lua 5.4 normalization fallback; all 138 Lua files parsed. All seven JS routing suites passed. Focused checks cover one-line bank mutations/swaps, compact versus detailed reports, stopped/neutral/legacy wrapper states, help-palette fragments and pre-login status. git diff --check passed. No Lua 5.1 or Windows/Windower/FFXI execution is claimed. Pending live acceptance
is readability in FFXI, not proof of any controller responsiveness improvement.

# Current Development Status — October 20, 2026 (America/Chicago)

- Branch: development/directlink. Tested starting source: 28304f405e7824e1b7dbc5f9e20378985007ea84.
- Diagnostic-only Controller Timing 1: runtime directlink1-timing1, shared Controls 9.11-timing1.
- `//xb controller trace on|off` now also controls a bounded per-character Lua receiver/native-request log. AHK adds actual start-gap, named-stage and slow context-read/button-write measurements. Input routing, filtering and watchdog policy are unchanged.
- Live evidence: October 20 auction capture has 23 paired direction holds, no resets, 29 cycles >100 ms and max 437 ms; one recorded Up spans 297 ms. This does not prove finger release timing or actual game repeat. Earlier paired menu capture has four session resets; chat contains repeated R2 downs without intervening up, but lacks timestamps.
- Correction: prior descriptions equated slow poll_ms with exact hardware-read gaps. It measures elapsed callback duration. New start_gap_ms records callback start intervals separately; neither is CPU time.
- Validation: all 56 top-level Lua regressions passed using the Lua 5.4 normalization fallback; 135 Lua files parsed; all seven JS routing/trace suites passed (including actual timing helper duration checks). Native Windows/AHK/Windower execution remains pending; this is an evidence-gathering build, not a claimed stickiness fix.
- Next: collect the two logs using docs/CONTROLLER-TIMING-TEST.md; locate the slow stage and distinguish delayed native release from session cancellation before changing behavior.

---

# Controller Timing 1 — October 20, 2026

Current AGENTS.md, WORKFLOW.md and TESTING.md read from GitHub before edits.
User requested collection tooling for sticky direction taps and ghost menu movement.
Paired captures use the existing command, with a 30-second shared wrapper capture
and a 31-second character Lua capture. Lua flushes outside the active measurement
window, appends, caps memory at 256 KiB and reports write failure. Unload saves;
crash recovery of the in-memory diagnostic is not promised. No settings or images
are included in the cumulative code-only update. Restart the matched wrapper.

Validation: all 56 top-level Lua tests passed with tests/run_lua.py (Lua 5.4 temporary Windower syntax normalization); all 135 Lua files parsed; all seven JS suites passed. No Windows AHK or FFXI runtime was available. git diff --check passed.

The new recorder tests bounded buffering, automatic and repeated stop, update-gap
timing and failed saves. Existing routing/trace fixtures include the diagnostic
object; they still execute the actual routing handlers. Published head is given
in delivery/Git history, not self-referentially inside this file.

# Current Development Status — October 19, 2026 (America/Chicago)

- **Branch / tested baseline:** development/directlink; published starting source fbb535db09deeb0467c2ebb6339c2e350e264b0a. Runtime directlink1-cleanup1; unchanged Controls 9.10-holdfix.
- **Request / change:** Authorized bank-settings separation, module/folder simplification and image reorganization with working legacy paths. Bank state now saves separately in data/companion_banks.xml. All existing global/character bank sections import before main settings cleanup; original main bytes are backed up and unrelated bytes retained. User bank commands and controller mappings are unchanged.
- **Layout:** 55 Lua modules relocated into libs/ and ui/ (54 retired tracked root files plus the new bank-storage module). Default pack -> images/icons/default; numeric fallbacks -> default/fallback; themes -> images/themes. 2084 asset relocations; all 2101 shipped images match their baseline bytes. Root shared AHK wrapper/includes retain their paths. Internal requires use canonical names; bootstrap supports legacy require names.
- **Verification:** All 55 top-level Lua regressions / 133 Lua sources passed the documented Lua 5.4 normalization fallback; seven JS routing suites, AHK structural checks and layout/dependency/asset-byte audits passed. Actual shipped XML parser exercised with adapted Windower collection/string APIs. Attached settings migration preview retained all seven sections and Cioara positions and independently parsed as valid XML. Focused final checks repeated after recovery guards. Native Windows/Windower/FFXI and PowerShell helper execution remain pending.
- **Delivery:** Cumulative code-only ZIP works with existing DirectLink artwork through the resolver. Optional finish-cleanup.bat consolidates installed images in place, preserves differing custom art as overrides, and backs up modified retired root Lua modules. Complete-package builder uses the same source checkpoint. No personal data/settings are distributed.
- **Live acceptance:** Unload all clients; back up and merge update; optionally run folder helper; load one client and verify storage path/version, saved banks, position commands, menus and icon chooser; edit a bank, reload and verify persistence; then load other clients. Verify custom legacy/override art and rapid bar switching. Latest confirmed behavior remains prior working banks/menu scroll and repaired text settling; no new live confirmation inferred.
- **Pending:** Held-input recovery and hint cleanup live acceptance, native helper execution, compact Options flash, tracker-disable and R3 release-R cleanup, menu-type detection, one-command in-game runner, Ctrl-drag, NPC cutscene/SlowEnter issues. No such behavior changes are bundled into cleanup.

---

# Folder and bank-settings cleanup test 1 — October 19, 2026

Author A. Current AGENTS/WORKFLOW/TESTING reviewed. User explicitly authorized the
previously proposed staged migration and path-compatible directory cleanup.
Starting published checkpoint fbb535db09deeb0467c2ebb6339c2e350e264b0a.

Bank storage imports every saved global/character section with typed field names,
including legacy L1 commands, then stores character differences over global
settings. Main config loads only after prepare; bank defaults are no longer in
the main config shape and bank commands/drags save through the separate owner.
Root config refresh selects the character's bank state without replacing the
shared state container used by render/input owners. Main typography/scaling and
ordinary bar XML/catalogs stay in their existing settings/storage locations.

Migration/save coordination uses the existing Windows atomic replacement backend
and cross-client locks. Main bytes outside the two retired bank sections remain
verbatim, with settings.xml.before-bank-cleanup.bak retained. Bank saves keep a
previous-file .bak, validate XML/readback and detect same-character stale writers
while preserving other characters' edits. Interrupted .pending input is read as
recovery. Invalid/newer files are never overwritten; saves are blocked and a
specific message is shown. A partial bank file without an import-complete marker
does not authorize removal of unimported legacy sections. Old snapshots do not
continually reimport over later edits. No automatic Cioara preset or binding swap.

Runtime Lua moves into libs/banks, libs/controller, supporting libs and ui. One
bootstrap alias map preserves external legacy require names. Canonical internal
requires are dependency-audited. Shared AHK and includes stay at the root so their
startup paths remain stable. Generated resources/ metadata remains compatible.

The resolver handles canonical, old pack, old numeric fallback and old theme
paths; explicit external and extracted cache images stay valid. Existing legacy
art wins over stock and images/overrides wins over both. Alternate packs can fall
back to the default pack. All saved custom action icon stems remain valid. The
selector scans override/legacy/canonical roots, deduplicates stems and includes
fallback icons. Structural setup/menu/credit art remains at existing paths.
All 2101 shipped image bytes were compared with the starting local tree matching
the published baseline; 2084 paths relocate without pixel/recompression changes.

The optional Windows helper consolidates legacy image trees after a merge update:
move missing destinations, remove byte-identical duplicates, preserve differing
art as overrides, keep/report conflicting custom overrides. Retired root Lua
files matching baseline hashes are removed; differing files move to timestamped
data/cleanup-backup for review. It does not alter settings. -Preview is non-writing.
No recursive delete is used. The helper has structural checks only in this Linux
environment; actual Windows PowerShell execution is a pending acceptance check.
Skipping it leaves old paths usable. Code-only packaging is therefore viable
without downloading images again. Complete-package builds include canonical art.

Verification: all 55 tests/*.lua regressions passed; 133 Lua sources parsed via
Lua 5.4 temporary normalization (not native Lua 5.1/Windower). Seven JS routing
suites and tests/check_ahk.py passed. tests/check_layout.py audited canonical
requires, old-module retirement, manifest targets, helper structure and all image
blob hashes. New asset tests exercise the actual resource wrapper. New bank tests
cover import, inherited fields, cleared slots, repeat migration, conflict/failure,
partial/newer/bad files, pending recovery and prelogin writes. The entire bank
regression also ran with the actual shipped libs/xml2 parser and adapted
Windower APIs. The supplied settings(20261019-212625).xml was tested read-only:
a private preview retained global plus six character sections and Cioara anchors;
Python's independent XML parser accepted the emitted document. Original upload
unchanged and not bundled. Native FFXI acceptance is not claimed.

Installation and recovery details: docs/UPDATING.md. Existing position commands
and exact Cioara values are documented there. Earlier history follows unchanged.

---

# Historical status — Hint Cleanup 1, October 19, 2026

- **Branch / tested baseline:** development/directlink; source e4fbe7b32e68f0198c191104b186805e54286b92. Runtime directlink1-hintfix1; unchanged Controls 9.10-holdfix.
- **Request / fix:** Stale skillchain slot hints during rapid set changes. Slot replacement now clears recast/hint surfaces and resets frame artwork/alpha. All non-hint action paths restore their normal frame, including commands, missing metadata and item warmup; burst frames cannot inherit an old SC property image. Tracker timing and tracking remain unchanged.
- **Verification:** Actual renderer regression covers replacement types, empty slots, expiry, SC-to-burst, frame alpha, item warmup/cooldown and immediate slot clear. All 52 top-level Lua regressions and 127 Lua sources passed the documented Lua 5.4 normalization fallback; all seven JS routing suites, AHK structural checks and diff checks passed. Windows/Windower/FFXI live acceptance remains pending.
- **Delivery:** Cumulative code-only update contains all current installable non-image files, not merely changed files. Requires an existing complete DirectLink installation; preserves images/themes and excludes personal settings/bindings. Runtime and PACKAGE-INFO identify the checkpoint. No AHK changes in this batch.
- **Settings supplied:** settings(20261019-212625).xml examined read-only. Cioara panels: left 1657,1669; right 1957,1675; main offsets 35,-146. No whole-file settings replacement. Settings migration and directory moves are proposed next, not implemented here.
- **Latest user feedback:** Text-settling issue resolved; all four banks and menu scrolling work. Held-input recovery/layout changes still need native acceptance. Compact Options flash remains unresolved.
- **Next:** Live-test rapid bar changes during/after a skillchain window; then migrate bank settings into a dedicated data file with explicit versioned import and fallback, before moving runtime modules/assets. Tracker-disable, R3 release-R cleanup, menu-type detection, one-command diagnostic runner and Ctrl-drag remain separate pending work.

---

# Skillchain hint cleanup test 1 — October 19, 2026

Author A. Reviewed current AGENTS.md, WORKFLOW.md and TESTING.md; starting
published checkpoint e4fbe7b32e68f0198c191104b186805e54286b92.
The slot image/frame objects survive set changes. clear_slot hid the frame but
left its animated texture/alpha and recast surfaces intact. Non-recast actions
never visited the frame restoration branch. The burst path reused the warmup
surface without changing a previous skillchain image. These are rendering leaks;
they do not prove a stale tracker window. The patch clears surfaces at replacement,
starts each recast pass with the shared warmup overlay hidden, and restores normal
frame artwork/alpha whenever there is no valid hint. Actual warmup/cooldown code
still draws its current output. Valid hints retain their animated frame path
without an unnecessary base-texture round trip each frame.

New tests/skillchain_hint_cleanup.lua exercises the real renderer rather than a
copy of the algorithm. Caption fixtures now include actual recast cleanup while
still proving replacement labels never pass through a transient blank.

Cumulative packaging includes all installable current code and docs and omits
image bytes only with --no-images. It never includes data/settings.xml, ordinary
bar XML, local configuration or logs. Assets remain at current paths. Package
integrity and published-tree equality are checked by the builder; a code-only
package is not advertised as a fresh installation. Copy commands for the supplied
Cioara positions and a staged settings/directory cleanup plan are in UPDATING.md.
The attachment itself is unchanged and is not distributed with the update.

Verification: all 52 top-level tests/*.lua regressions passed; 127 Lua sources
parsed with the Lua 5.4 temporary Windower-syntax normalization fallback. Seven
JS/controller routing suites, tests/check_ahk.py and git diff --check passed. The
new renderer and caption tests also passed separately. Builder Python parsed.
No native Windows/Windower/FFXI acceptance is claimed. Published-tree and ZIP
byte/entry audits run before delivery. Earlier history follows unchanged.

---

# Historical status — Bank Layout 1, October 19, 2026

- **Branch / tested baseline:** development/directlink, source d6a12c8d8356d6abd3e4f747f2130d24dea1ee27. Runtime directlink1-banklayout1 / unchanged Controls 9.10-holdfix.
- **User request:** Exchange current L1/R1 controls, replace L1L2 Cross Jump with input /quest, match main font/size, and simplify movement/copying Cioara positions. No new live acceptance of held-input recovery was supplied in this request.
- **Change:** Explicit swap preserves custom and materialized inherited bindings, Closed/Menu entries, titles and policies; positions stay on their original side. Updated explicit Cioara preset includes swap and Quests. Existing installs use explicit swap plus two slot assignments, avoiding wholesale preset replacement. Typography follows main font/size/rendered scale. Pinned edit previews allow mouse-only dragging. Main pos and panel status expose copyable position commands; no Ctrl grid snapping.
- **Verification:** All 51 top-level Lua regressions passed, 126 Lua sources parsed using the documented Lua 5.4 normalization fallback; seven JS/controller routing scripts, AHK structural checks and diff checks passed. Native Windows/Windower/FFXI acceptance remains pending.
- **Delivery / install:** Complete update with all Hold Recovery 1 and Banks 3 work. Preserve data/settings.xml, config.ini and art. From Hold Recovery 1 only Lua reload is needed. If still on an older wrapper, install/restart Controls 9.10-holdfix as described in HOLD-RECOVERY.md. No automatic saved-bank rewrite or preset reapply.
- **Live tests:** Run swap once on each desired character, set Quests in both contexts, verify labels/commands, compare bank typography with main bar, drag via edit preview without held controls, and copy Cioara coordinates into clients of matching UI resolution/scale. Continue held-input acceptance and retain its trace protocol.
- **Pending:** Held-input live confirmation/performance investigation, compact Options flash, menu-type detection, one-command in-game diagnostic runner, Ctrl+drag snapping, NPC cutscene access and SlowEnter all-client delivery.

---

# Bank layout and positioning test 1 — October 19, 2026

Author A. Reviewed AGENTS/WORKFLOW/TESTING and source baseline d6a12c8d.
User requested current L1/R1 exchange rather than changing hardware shoulder
semantics. Generic bank swap materializes factory entries before moving them;
otherwise Kind=default would resolve different commands at the destination.
Both contexts and bank-specific display/menu policies follow the definitions;
left/right shared panel geometry does not move. Titles get the correct physical
prefix, including compound-bank swaps. Applying swap again reverses the change.
The explicit Cioara preset now ships party L1 / NPC R1 and Quest on inventory
Cross in Closed and Menu. Existing users should not reapply it to preserve other
customizations: use the swap and slot commands documented in README.

Bank text uses Texts.Font/Size with main CrossbarScale, matching actual main
pixel size even when a bank has an independent geometry scale. Title and font
changes participate in the render cache. Slot icon size/geometry is preserved.
Edit on pins a preview indefinitely and unlocks its side panel; off locks and
unpins. Edit previews do not arm physical input or permanently override a hidden
bank's visibility. Main pos uses existing move/anchor logic and saves offsets;
panel status prints existing pos syntax. data/settings.xml stores Style.OffsetX/Y
and CompanionBanks.LeftPanel/RightPanel.X/Y; copy individual fields/commands, not
all character settings. Different resolutions/scales may clamp/place differently.

Verification: all 51 tests/*.lua regressions and all 126 Lua sources parsed via
the Lua 5.4 temporary Windower-syntax normalization fallback. All seven JS routing
scripts and tests/check_ahk.py passed. Focused final-source bank-layout and view
regressions passed after removing the obsolete unused text-size parameter.
git diff --check passed. Actual bank owner tests cover custom/factory semantics,
both contexts, invalid swap, policy/title transfer, preserved panel positions,
pinned edit without input arming and main position validation. Actual view tests
check configured font and matching main scaled size independent of bank geometry.
No native Windows/Windower/FFXI acceptance is claimed. Source-tree and package
entry/byte integrity are audited after publication.

Source/test records from previous checkpoints remain below. The hold-recovery
implementation and AHK are unchanged; native acceptance is still outstanding.
Ctrl+drag snapping and the one-command runner are not included in this batch.

---

# Historical status — Hold Recovery 1, October 19, 2026

- **Repository / branch:** rerorriM-Mirrorer/xivcrossbar / development/directlink; tested source baseline bdc6706d40b4424bd5bc9eef086c084c750f38d2.
- **Runtime / wrapper:** directlink1-holdfix1 / Controls 9.10-holdfix. This is a matched Lua/AHK update; restart the wrapper after replacing files, reload Lua in each client. Existing settings and Banks 3 preset assignments are retained without reapplying the preset.
- **User live evidence:** Disappearing R1/R2 holds are now frequent. Supplied controller-input-trace(2).log shows native Down/up acknowledgements, then cancellation near a 375 ms poll and eight later physical Down presses suppressed while R1/R2 stay held. Neutral rearming resumes after releasing controls. Clairvaux log reports messages active, zero rejected and lifetime max poll/gap 656/672 ms; those maxima are not proof of this capture's precise reset cause.
- **Change:** Brief same-client stalls renew the session and restore only original still-held controls, after action buttons are released. Queued actions are discarded. Hard context/client/focus/disconnect changes and interruptions beyond two seconds retain neutral rearming. Added reset reason/status protocol. No blanket timeout increase.
- **Verification:** All 50 top-level Lua regressions passed, all 125 Lua sources parsed via the documented Lua 5.4 temporary normalization fallback; all seven JS routing scripts, AHK structural checks and diff checks passed. All checks are static/simulated, not native Windows/Windower/FFXI execution. See dated entry and docs/HOLD-RECOVERY.md.
- **Live acceptance:** Repeat the supplied Trust-menu scenario without releasing bank controls; verify new Down presses work after brief stalls with no old actions replayed. Also check both shoulder/trigger orders, bare R1, ordinary R2, focus/client isolation, long gaps and disconnect. Ordinary double-tap timing restarts rather than replaying a tap.
- **Open work:** Determine any remaining cause of sustained slow polling, compact Options flash, native menu-type recognition, NPC cutscene input access, SlowEnter all-client delivery, and the one-command in-game diagnostic/screenshot runner. Previous bank functionality/text settling was live-confirmed; hold recovery remains pending live acceptance.
- **Delivery:** Complete source-identifiable installation, preserving installed data/settings.xml, config.ini and personal art. Both Lua and AHK updates are required. Public/main and frozen snapshot remain untouched.

---

# Held-input recovery test 1 — October 19, 2026

Author A. Reviewed AGENTS/WORKFLOW/TESTING and baseline bdc6706d. User authorized
repair after the trace-backed diagnosis and reports constant interruptions.
Read local supplied controller-input-trace(2).log and Clairvaux_2026.10.19.log.
Capture spans 337 lines starting UTC 20261019165031, Controls 9.9-banks. Wrapper
identifies R1+R2 (l1=0,r1=1), despite the user's L1>L2 description. Last native
Down/up key acknowledgements are 85/86; cancellation at tick 2995289812 and
replacement route at 2995289843 precede eight Down mask transitions with no
message/native output. Focus stays on the same HWND through that failure.
The old trace cannot identify which Lua reset path fired. Poll 375 ms is observed
around it; attributing the precise guard remains an inference.

Receiver heartbeat, render-gap and native-output stalls now create a fresh token
with a recoverable same-context marker. Wrapper can restore only original held
controls 11..14, ordered by prior physical downs, after all action buttons and
new controls are released. AHK lease uncertainty/backlog can request receiver
renewal using a stall event, which invalidates earlier queued actions atomically.
Restoration uses separate resume events, not ordinary fresh action edges. Lua
suppresses pair Tab and unused-R release during restoration. Native key outputs
are cancelled; no old face/D-pad/command output can be replayed. Context identity,
current eligibility and a two-second healthy-poll bound gate recovery; external
transport cancellations clear its permission. Updated lease avoids an interim
keyboard route on soft reset. Status/trace expose protocol and reset reason.

Verification: python3 tests/run_lua.py tests/*.lua (50 top-level regressions,
125 parsed sources) passed. All seven tests/*.js scripts, tests/check_ahk.py and
git diff --check passed. The AHK harness executes translated actual functions;
Lua uses temporary Windower syntax normalization under Lua 5.4. These do not
establish Windows scheduling, SendEvent or in-game acceptance. Final package
source-tree match, entry/byte integrity and archive audit are checked after
publication and reported with the delivery.

Initial runs found old test assumptions about a cancelled session having a nil
token and exact lease END placement. Updated them to check fresh-token recovery,
empty output, explicit recovery fields and intact complete lease publication.
New tests exercise original/reversed control order, repeated reset, 400 ms stall,
action/new-control quarantine, old token and slot-resume rejection, no Tab/R side
effects, stale queued action cancellation, client/focus and eligibility isolation,
refusal of recovery beyond two seconds, expiry while waiting for action release,
and another lease gap arriving during recovery. Native live acceptance remains open.
No installed state or NPC/Trust addon code is modified. Banks 3 preset and menu
policy remain as delivered. All prior records follow unchanged.

---

# Historical status — Banks 3, October 19, 2026

- **Branch / tested source:** development/directlink, starting at a572fcac584b351d1db6af921766f2da50f8df67. Runtime directlink1-banks3, unchanged AHK Controls 9.9-banks.
- **Last user-confirmed live behavior:** All four banks, commands and item scrolling work; text settling flicker is gone. Selecting DirectLink appears to work on Cioara and crew. Compact Options hint can still flash after the last fix; unresolved.
- **New report:** Native menu context during battle replaces inventory controls. The router only has broad menu_open, not a menu identity. We cannot distinguish item menus from the battle command menu on this evidence.
- **Current change:** Saved per-layer show/hide, native-menu drawing allowance and menu-action override. Explicit Cioara preset: L1 NPC/tests, preserved current L1 inventory on L1L2, R1 party, hidden R1R2 Trust navigation. No automatic preset migration or ordinary-set replacement.
- **Verification:** All 49 top-level Lua regressions passed; 124 Lua sources parsed with the documented Lua 5.4 Windower-syntax normalization fallback. All seven JS/controller routing scripts, AHK structural checks and diff checks passed. No Windows/Windower/FFXI run claimed for Banks 3.
- **Live acceptance:** Apply on a backed-up character; verify inventory routing during battle, optional scrolling, R1 native-menu drawing, hidden R1R2 Trust navigation, persistence/reload, and panel layout retention. Native menu-type detection, compact hint identification, NPC cutscene access and SlowEnter batch delivery remain open.
- **Next:** Get live feedback on this coherent bank update; implement the separately authorized one-command diagnostic/screenshot runner and instrument the remaining compact hint. No runner command is included here.
- **Delivery:** Complete banks3 installation from the published tree, preserving installed data/settings, config.ini and personal art. From Banks 2 only Lua reload is needed; older wrappers require their update. Per-character preset explicitly replaces all four companion definitions, including old L1L2 entries; back up data/settings.xml before applying.

---

# Bank visibility, Cioara preset and menu override — October 19, 2026

Author A. Reviewed AGENTS, WORKFLOW, TESTING and published source a572fcac.
User supplied Cioara-L1s.zip (16 character-set XML/backup files, no settings.xml).
Read current Cioara/ALL-JOBS-DEFAULT.xml, Shared and SMN-DEFAULT. Copied command
strings and their physical positions from current ALL-JOBS-DEFAULT, not backup
or Copy files. Original archive and installed ordinary/job sets are untouched.
User explicitly selected moving inventory to L1L2. Native_menu in combat is user
observation; broad flag routing is source-confirmed, exact menu identity remains
unobserved. No packet or engagement heuristic was introduced.

New defaults declare booleans/title/preset marker for Windower config casing and
type restoration. Display filtering moved into each panel; retired fallback still
has its native-menu guard. Commands and displayed labels use the same selected
Closed/Menu entries. Hide does not disable the physical-input owner. Setting
changes retain cancellation/held-button blocking and saved panel positions.
Explicit preset preserves current L1 bindings as materialized L1L2 entries, not
factory inheritance to the wrong bank. Repeated apply keeps L1L2 as its source.
It sets menu actions OFF for inventory-opening access during broad menu states;
user may opt back into existing menu scrolling. R1 draws over native menus;
R1R2 navigation starts hidden. No IPC claims for Trust menu detection.

Exact copied raw chains retain Cioara's personal dependencies: Send, Switch,
SAT, the all alias, NPCMirror and SlowEnter. Commands were not executed here;
no repair of the existing SlowEnter batch-delivery/cutscene issue is implied.

Verification completed: python3 tests/run_lua.py tests/*.lua, 49 top-level
regressions, all 124 Lua sources parsed; seven tests/*.js scripts and
python3 tests/check_ahk.py; git diff --check. Initial suite run exposed the two
old lower-level menu-visibility assumptions below; both were updated and the
complete suite then passed. Static/simulated checks use the existing Lua 5.4
normalization fallback. No native Lua 5.1/Windows/AHK/Windower/FFXI execution.
Package audit is performed after publication and reported in the handoff.

Two prior lower-level tests assumed their caller filtered native menus. Updated
them to verify the new panel-owned default guard and explicit allow policy.
New tests cover all four visibility policies, hidden execution, broad-menu
Closed binding output, opt-in scrolling, invalid commands, preset exact strings,
repeated apply and saved config reload. Pending acceptance is listed above.
Historical status and checks follow unchanged.

---

# Historical status — compact hints, October 19, 2026

- **Branch / source:** development/directlink, starting at 87fd89e7e47cc67f9e828de01bd928d91d472381. Runtime directlink1-banks2 / Controls 9.9-banks unchanged.
- **Live feedback:** User confirms all four companion banks, assigned commands and native item-menu scrolling work well. The text settling flicker is gone. Rapid R1/R2 transitions can briefly expose the Options hint despite compact mode.
- **Current change:** Compact hints never show during text setup; both hint-show entry points enforce compact visibility; layout-excluded hints hide immediately rather than lingering in a fade. Ordinary full-layout fades retain their existing behavior. This addresses visibility paths; the exact live rapid-switch sequence has not been reproduced here.
- **Verification:** See the dated entry below for completed checks. Native Windows/Windower/FFXI acceptance of this hint fix is pending.
- **Next:** Reload the two runtime files ui.lua and ui_geometry.lua and repeat rapid R1/R2 changes in compact mode; verify ordinary-layout hints and fades. The broader one-command live test/screenshot runner is authorized but not implemented by this focused fix. NPC cutscene access and SlowEnter all-client delivery remain unresolved integration work.
- **Delivery:** Focused two-file Lua update over Banks 2 plus the previous resources.lua hotfix; no AHK restart. Existing complete Banks 2 ZIP predates both fixes.

---

# Compact hint visibility — October 19, 2026

Author A. Reviewed current AGENTS/WORKFLOW/TESTING and remote source baseline.
Recorded the user's live bank/menu/command success and absence of text flicker.
Hardened compact hint ownership at setup, show and hide boundaries. Geometry
surface hide accepts an optional immediate flag, matching primitive hide behavior;
only compact hints opt in. The crossbar text setup helper is now local so another
UI module cannot replace its compact visibility policy. The existing fade remains for ordinary-layout hints.
Regression exercises 20 attempted reveals/chooser changes during deferred hides
at each of 108 layout configurations across six resolutions and three scales.
This is simulated coverage, not reproduction of the user's physical sequence.

Verification: all seven JS/controller routing scripts, AHK structural checks and
git diff --check passed. The amended compact regression passed independently on
the final source (108 configurations); the text API/settling regression passed.
All 48 top-level Lua regressions passed and all 122 Lua sources parsed. Lua uses the documented Lua
5.4 temporary Windower-syntax normalization fallback, not native Lua 5.1 or
Windows/Windower execution. The final refinement limits immediate hint hides to
compact mode, preserving ordinary-layout fade semantics.

The earlier targeted invocation also named nonexistent tests/geometry.lua after
compact/text tests passed; the full wildcard suite is the authoritative run.
The in-game automated pending-test runner remains planned; no such command is
shipped here. No installed settings, bindings, assets or companion code changed.

---

# Historical status — bank text API hotfix, October 19, 2026

- **Branch / baseline:** development/directlink, starting at d6131b127b611708b662850167f2910309dbd60e. Runtime remains directlink1-banks2 / Controls 9.9-banks.
- **User report:** L1/bank reveal raises resources.lua:73, attempt to call a nil field. Title/background and only the leftmost D-pad slot render.
- **Cause / fix:** Measurement queried right(), absent from Windower texts.lua. Corrected the style getter/setter/invalidation key to right_justified(). The first label measurement previously aborted the slot draw loop.
- **Verification:** Inspected current Windower/Lua live addons/libs/texts.lua and statically matched every measured field to an exported getter. Added API-name/invalidation regression and made its fixture reject right(). The execution environment is unavailable: no Lua suite, parse check or Windows/FFXI test ran for this hotfix. Earlier passing checks below do not validate this revision.
- **Delivery / next:** One runtime-file hotfix: replace ui/resources.lua over Banks 2 and reload XIVCrossbar in every client. AHK unchanged. Verify eight slots/texts on all four banks, scale/reveal/menu transitions and absence of repeat console errors. Re-run the full suite when an environment becomes available.

---

# Bank text API hotfix — October 19, 2026

Author A. Reviewed AGENTS/WORKFLOW/TESTING via GitHub. Traced the exact Banks 2
line 73 to the first slot alias measure_width() in l1_view.tick(). Native text
objects have right_justified(), not right(); the permissive test mock previously
invented either name and missed this API mismatch. Corrected measured_fields,
measured_setters and trace observation consistently. Amended text_settle.lua to
reject right() and cover the real right_justified getter/setter and subsequent
width invalidation. Other measured getters were checked against Windower's
published texts API. No blanket nil fallback or removal of text settling.

Source inspection and API-name validation only. Execution blocked because no
usable execution environment is available. New/amended tests have NOT run.
Live report and preceding test history are retained below. No full ZIP rebuilt;
the published runtime file is the focused hotfix over the existing complete ZIP.

---

# Historical development status — Banks 2, October 18, 2026

- **Repository / branch:** rerorriM-Mirrorer/xivcrossbar / development/directlink. Tested source baseline 549e5d86df4919eb82e4c5085aed892b6db9f775.
- **Runtime / companions:** directlink1-banks2; unchanged Controls 9.9-banks. From banks1 only Lua reload is required. NPCMirror/Trust/SlowEnter remain separate; raw all-client taps need SlowEnter v1.4.0+ on participating same-PC clients.
- **Current change:** NPCMirror/SlowEnter R1R2 factory mappings, v2 factory inheritance, default/defaults restoration, short r1/r1r2/l1l2 editors, and explicit trigger names in the original set API. Nonempty personal overrides, legacy L1 recovery and panel layout are preserved. Empty v1 R1R2 entries adopt the requested defaults once; v1 could not distinguish a deliberate clear from unused space.
- **Last confirmed live behavior:** Initial DirectLink ordinary routing on Franklet remains the last confirmed live baseline. Banks1 and this followup remain simulated checkpoints.
- **Verification:** All 48 top-level Lua regressions passed; all 122 Lua sources parsed via the documented Lua 5.4 Windower normalization fallback. All seven JS/AHK-routing scripts and AHK structural checks passed. New tests exercise actual root alias/set dispatch, all eight NPC defaults, v1 adoption, per-context reset, explicit clears, append immutability and settings reload. No native Windows/AHK/Windower/FFXI test is claimed.
- **Known live limitations:** The existing status-4 cutscene controller-feed guard is unchanged, so these mappings do not enable the bank in every NPC event. The user's earlier SlowEnter all-client delivery issue is not repaired by binding those commands. Native responsiveness, menu/Trust interception, NPC session behavior and raw batch delivery still need acceptance.
- **Next:** Live-test aliases/restores, preserved custom assignments and NPC bank outside cutscenes; then design scoped event access and investigate SlowEnter's raw delivery with controlled traces. No companion addon source or public/frozen branch is changed here.
- **Delivery:** Complete banks2 ZIP built from the confirmed published tree, excluding installed state. Commit and archive integrity are reported in the handoff. Preserve data/settings.xml and custom art when updating.

---

# Companion banks checkpoint 2 — October 18, 2026

Author A. Starting at published 549e5d86df4919eb82e4c5085aed892b6db9f775,
tree 9097aece111fd752042654d33010ac324f1780e3. Reviewed current AGENTS,
WORKFLOW/TESTING and NPCMirror's current shared workflow. Source verification:
NPCMirror main aab69c26d068d409754cc9c9f2e0ffc5a9bc3163 (npcmirror.lua/README);
SlowEnter dev/se-toggle dc8341dd8b932c87e33b04c92d358f71f2d17f04
(slowenter.lua/README), runtime 1.4.0. Used canonical npcmirror/slowenter names;
no assumption that the requested npc short alias already exists.

R1R2 Closed and Menu factory maps: Triangle npcmirror interact; Square npcmirror
stop; Cross npcmirror enter; Circle npcmirror esc; Left npcmirror call; Right
npcmirror status; Up slowenter all once; Down slowenter all once esc. Raw taps
are separate from guarded session steps, bypass SlowEnter guards, and can select
native choices. No Send-all wrapper, new key signal or companion code is added.
The existing feed/cutscene policy is retained and explicitly documented.

CompanionBanks v2 records Kind=default for inherited factory actions. Runtime
labels and execution resolve the same hardcoded definition. Setting a command/
key creates a saved override; clear creates an explicit empty override. Default
removes one override; defaults resets eight entries in the selected context.
Neither operation changes panel coordinates/scale/lock, another bank or the
other context. Append materializes an inherited command before changing it.
Old default-valued L1/R1 snapshots adopt inheritance; custom entries and clear
L1/R1 slots remain. Empty v1 R1R2 entries adopt new NPC defaults once, including
old explicit empty clears that v1 did not distinguish; re-clear to reserve them.
Legacy imported L1L2 commands remain overrides until explicitly reset.

Short editors r1/r1r2/l1l2 route through the actual bank branch with identical
arguments. Bare reports status; l1 retains its published legacy L1L2 meaning.
Original //xb set remains set/bar/slot/type/action/target/alias/icon. Its bar
converter gains l2/r2/r2l2/l2r2/l2l2/r2r2 aliases, preserving old numeric and
l/r/rl/lr/ll/rr names. No top-level r2r2 editor or r2 target-command replacement.

Verification: python3 tests/run_lua.py tests/*.lua (48 top-level tests, 122
parsed sources); all seven JS routing scripts and tests/check_ahk.py; git diff
--check. Meaningful new cases cover actual root alias/ready guards, exact factory
dispatch, per-context resets, invalid syntax, custom preservation, durable clear,
same-default adoption, append immutability, panel preservation and actual original
set dispatch with old/new bar names. Prior ownership/native-key/render/shared
regressions pass. These checks are simulated/static; no OS/client/game success
is inferred from command dispatch. Docs and installation guide are updated.

Live acceptance: Back up settings; install/reload Lua (AHK unchanged from banks1).
Check //xb r1r2 status and preview. Use a safe area to verify the mappings, with
raw taps only on intended clients/choices. Test default one slot, defaults Closed,
menu defaults, clear then reload, custom override then reload and panel retention.
NPCMirror and SlowEnter behavior remain their own integration tests. Preserve
the previous banks1 package for rollback; do not delete installed data.

---

# Historical development status — companion banks 1, October 18, 2026

- **Repository / branch:** `rerorriM-Mirrorer/xivcrossbar` / `development/directlink`. Tested starting/source checkpoint: `f13829a7a5ca9f6715ee1337a77722bc078dae38` (integrated shared fixes/R1/text settling).
- **Runtime / wrapper:** `0.4.0-a.20261018.directlink1-banks1`; Controls `9.9-banks`. Both Lua reload and shared AHK restart are required. Trust remains separate: compatible Menu options Test 4 plus explicit Open addendum `17d0f9cc1e8dd400c70ae8411e4ff805d9868129`, or a compatible later development.
- **Implemented:** Saved/versioned L1/L1L2/R1/R1R2 definitions, legacy L1L2 migration, contextual L1 inventory/scroll/emote defaults, R1 Trust layer, ordered R1R2 empty NPC bank, named-button editor, shared compact panels and acknowledged native-key service. Public RC3 and the frozen Unbound snapshot are untouched.
- **Last user-confirmed live behavior:** Initial ordinary DirectLink operation on Franklet, preserved by `snapshot/directlink-unbound-20261016`. This new bank/native-output checkpoint has not run in Windows/FFXI here. Prior real IJKL/text settling/shared fixes continue to await their documented live acceptance.
- **Automated verification:** All 47 top-level Lua regression files passed; all 121 Lua sources parsed via the documented Lua 5.4 Windower-syntax normalization fallback. All seven JavaScript/AHK-routing scripts and AHK lexical/include/function checks passed. Tests exercise actual source modules/functions, with native OS/game/UI services mocked. Windower's actual config merge verifies lowercase XML reload and cleared-slot persistence. No native Lua 5.1, Windows AHK, Windower or FFXI execution is claimed.
- **Remaining live checks:** Native-key receipt/latency/held-repeat, native menu context transitions, Trust consume/open/close, all trigger orders/tails, quick taps, focus/multibox/disconnect/restart, panel drag/scale and text settling at small resolutions. Use `docs/LIVE-TEST-DIRECTLINK.md` and the current map in `docs/SHOULDER-BANKS.md`.
- **Next:** Live-accept this bank checkpoint before assigning NPCMirror commands or extending controller profiles. Graphical/catalog bank assignment, success-confirmed switches and icon/folder migration remain future work.
- **Delivery:** Complete source-audited test ZIP built only after commit/push and remote-head confirmation. Final publication SHA and archive checksum are reported in the handoff; the tracked status identifies its source baseline rather than claiming its own hash.

---

# Companion banks checkpoint 1 — October 18, 2026 (America/Chicago)

Author A. Authorized full L1/R1 bank implementation on development/directlink,
starting at f13829a7a5ca9f6715ee1337a77722bc078dae38. Reviewed current AGENTS,
project WORKFLOW/TESTING and the shared NPCMirror WORKFLOW including its final
review/verify/status/publish/confirm sequence. The materialized starting tree
was verified byte-for-byte against GitHub tree fdf051a78798fa8fd80e76b4bc179a626bdb7404.

## Installation and first live checks — pending

Back up the personal addon folder and data/settings.xml. Stop the shared wrapper
and unload XIVCrossbar in all clients. Update the complete xivcrossbar folder
while preserving data/, config.ini and custom art. Reload Lua, restart AHK and
return every control to neutral. Confirm profile x, messages ON, inputtest OFF,
runtime directlink1-banks1, Controls=9.9-banks, banks protocol=1/enabled=1 and
receiver=true after handshake. Status capability/acks are not game success.
Trust/TrustMovement are separate and are not installed by this ZIP.

1. Verify L1 closed-menu defaults: Up Items/Ctrl+I, Right Equipment/Ctrl+E,
   Left Wardrobe, Down Wardrobe 2; Triangle Case, Square Sack, Circle Satchel,
   Cross Jump. Console actions use input / commands, independent of Shortcuts.
2. With a native game menu open, both panels hide. L1 Up/Down becomes Ctrl+
   Left/Right, Left/Right becomes Alt+Left/Right. Shapes become Triangle Wave,
   Square Bow, Circle Nod (input /yes), Cross Jump. Hold a slot across the
   context change: release/new press is required before its new action.
3. L1 first then L2 reveals saved L1L2 in the same left position. Existing
   commands migrate once; Menu entries start empty. L2 first then L1 stays
   ordinary. Test both release orders and same-sample priority. Repeat on the
   right: R1 first then R2 selects the empty NPC bank; R2 first stays ordinary.
   Empty bank slots cannot leak ordinary face actions. Opposite ordinary
   triggers take priority. L1+R1 Tab remains; any used R1 hold consumes release R.
4. R1 holds native arrows; Cross pulses Enter, Circle Escape; Triangle sends
   trust menu open and Square trust menu close in either native-menu context.
   Trust's own key consumption/save validation still applies. Open should
   preserve an existing submenu/draft; Close can refuse an invalid draft.
5. Test short presses/releases, native repeats, simultaneous directions,
   physical keyboard modifiers/keys, chat, addon editors/choosers, cutscenes,
   focus handoff, multibox, disconnect and wrapper/Lua restart. Native keys
   must release from their original client. Cancellation never produces R.
   A quick native pulse has a nonblocking 40ms minimum hold; judge the feel.
6. Assign a harmless echo with //xb bank l1l2 left Test input /echo bank-test,
   reload, then clear it and reload again. Confirm both changes persist and
   the old L1 section remains intact. //xb l1 is the L1L2 compatibility editor.
   Preview/unlock/drag/lock/scale each side; both layers share that side's panel.
   Repeat text settling and six-bar checks from the integrated live guide.

## Implementation / verification record

CompanionBanks v1 declares its full shape in defaults so Windower's lowercase
XML parser/merge restores field casing and string/boolean types on a fresh
process. Migration copies legacy L1 Alias/Command only once and preserves the
old section. Menu entries are independent; arbitrary migrated commands are
closed-menu-only. R1R2 stays empty until exact NPC verbs are chosen.

The existing acknowledged input stream negotiates two shoulder edges, bank
readiness and native acknowledgments. Lua owns layer/context/action selection;
the ordinary six-bar router is unchanged. Releases finish original owners;
held slots cannot change meaning after a bank or native-menu transition.
Trigger-first/same-sample orders preserve ordinary bars. Bank shoulder-first
release reserves the remaining trigger tail. Readiness is reannounced after
neutral/uncertain/backpressure recovery, so execution and rendering stay aligned.

Native requests use the existing per-client context lease. AHK validates the
entire whitelisted snapshot, preserves keyboard ownership, reconciles shared
modifiers and acknowledges output IDs in the ordered input stream. Quick taps
retain both edges; cancellation advances the output generation and IDs never
rewind, preventing a late acknowledgment from retiring a newer request. Native
output waits for preceding input/cancel acks. Missing/stale leases, context or
client changes release owned keys; a >350ms unacknowledged output or >64 queued
edges resets the session rather than delivering stale work.

Available checks passed: python3 tests/run_lua.py tests/*.lua (47 files, 121
parsed sources); node tests/personal_gestures.js, personal_input.js,
personal_realkeys.js, companion_native.js, controller_messages.js,
controller_clients.js and input_trace.js; python3 tests/check_ahk.py;
git diff --check. The new key-service harness executes actual AHK functions
under narrow translation, not native Windows AHK. New Lua tests execute the
actual schema/output/owner and root router/publisher, including all six bars,
both shoulder orders/releases, menu changes, command dedup/cancel, key queue
acks, stale cancellation, saved-setting reload and two compact panel lifecycles.
Existing text-settle, Save Only, shared-fix and resource cleanup regressions pass.
Vendored Windower merge fixture retains its source attribution/license.

No icon, theme or module path restructuring, Trust source change, movement
protocol change or public/snapshot promotion is included. Historical records
follow intact. Final pushed SHA/ZIP integrity are confirmed at delivery.

---

# Historical development status — integrated package, October 18, 2026

- **Repository / branch:** `rerorriM-Mirrorer/xivcrossbar` / `development/directlink`. Integration baseline: published `92a1710d872b246d15792f6c472ea39e424df8e6`, including the new R1 Trust-menu checkpoint; earlier shared-fix work began at `a30638d`.
- **Runtime:** `0.4.0-a.20261018.directlink1-r1menus1`; AHK `Controls=9.8-r1-menus`. This shared-maintenance pass does not modify controller protocols, wrapper or personal mappings.
- **Current change:** The integrated R1/shared-fixes source is unchanged. Prepared a complete DirectLink live-test package, a short in-game checklist, and a packaging audit that verifies the local source tree against the published GitHub commit. Corrected the README's obsolete wrapper-version/install wording.
- **Last user-confirmed live behavior:** Initial DirectLink Unbound ordinary-message routing worked on Franklet; `snapshot/directlink-unbound-20261016` preserves that evidence. R1 Trust menu, optional real IJKL and text settling are newer simulated checkpoints awaiting live acceptance.
- **Verification:** All 45 top-level Lua regression files passed on this integrated tree with `python3 tests/run_lua.py tests/*.lua`, including the independent R1 Trust-menu and shared-fix tests; all 115 Lua sources parsed using the documented Lua 5.4 normalization fallback. All current JavaScript AHK-routing regressions and `tests/check_ahk.py` passed. These are source/simulated checks, not native Lua 5.1/Windows/Windower/FFXI execution.
- **Still to test in FFXI:** Shared CLI switching and JA spell refresh; new R1+Triangle/Square Trust open/close; optional real IJKL; text settling; chooser, six-bar routing, client focus handoffs and multiresolution/multiclient lifecycle. Detailed checklists below remain authoritative.
- **Next development:** Install the complete DirectLink package and live-accept the R1/Trust, L1/trigger, menu/text and client-focus smoke tests. Then continue L1/R1/L1→L2/R1→R2 bank/input-ownership unification without altering the frozen snapshot or public defaults.
- **Delivery:** Complete DirectLink testing ZIP is prepared from the final verified/published source tree after this documentation-only batch. No native FFXI run has occurred. Final pushed commit and ZIP checksum are reported in the handoff, not self-referenced in this tracked file.

---

# Integrated DirectLink complete test package 1 — October 18, 2026 (America/Chicago)

Author A. `development/directlink`, starting at published source checkpoint
`55571f7a782a3509d15e1722b7da29f1129f3cad`. Runtime stays
`0.4.0-a.20261018.directlink1-r1menus1`, AHK `Controls=9.8-r1-menus`.
No Lua, AHK, controller mapping, stored data, transport or Trust source changes.
The packaging script verifies its local committed tree is the exact tree of the
GitHub checkpoint supplied at delivery; it rejects dirty/unpublished variants,
omits test/example/config/data/XML files, includes complete assets and runtime,
and tests every ZIP entry against its audited bytes. The ZIP has a single
installable `xivcrossbar/` directory with README, WORKFLOW, cumulative TESTING,
the short `docs/LIVE-TEST-DIRECTLINK.md` and a source-commit manifest inside.

**Installation:** Back up the personal addon folder and preserve installed
`data/`, `config.ini` and custom art. Stop wrapper, unload XIVCrossbar in all
clients, update `xivcrossbar/`, reload Lua, restart AHK, return controls to
neutral. Trust and TrustMovement remain separately installed and unchanged; R1
Trust-open testing requires compatible Trust Menu options Test 4 plus its
explicit-Open addendum (`17d0f9cc1e8dd400c70ae8411e4ff805d9868129`).
The package is not a public RC3 or a backup of personal settings. The focused
short checklist precedes the cumulative tests below; it does not replace them.

**Verification:** Re-run all actual-source Lua regressions, all AHK-routing JS
checks and AHK lexical/include checks before publishing. These are simulated/
static checks. Windows, native Lua 5.1, Windower, Trust and FFXI live acceptance
remain pending. The full archive SHA-256 is delivered separately with the file.

---

# R1 Trust menu checkpoint 1 — October 18, 2026 (America/Chicago)

Author A. development/directlink, based on a30638dd1475fab9a7b8f094578c596eba3eb38e.
Runtime 0.4.0-a.20261018.directlink1-r1menus1; Controls=9.8-r1-menus.
Adds the two requested R1 shortcuts and the shoulder-bank implementation proposal.
Exact publication is identified by Git/delivery. Public RC3 and snapshot preserved.

## Install and live acceptance — pending

1. Preserve installed settings/data/artwork. Stop the shared wrapper and unload
   Lua in all clients; update DirectLink, then reload Lua and restart AHK. Confirm
   inputstatus runtime and controller status Controls=9.8-r1-menus, R1 protocol=1.
   Use profile x and //xb messages on. Return controls to neutral.
2. Update Trust's commands/MenuCommands.lua from the explicit-Open addendum over
   the compatible Menu options Test 4 install and reload Trust. Its menu status
   reports explicit open: true. The previous handler had no registered open verb;
   a request fell through to the default menu handler. Do not infer idempotence
   from that older path. Existing close is available in the earlier menu tests.
   Published Trust addendum: 17d0f9cc1e8dd400c70ae8411e4ff805d9868129.
3. Press R1+Triangle: Trust opens. Repeat while deep in an editor: the current
   submenu/cursor/draft should stay. Press R1+Square: all Trust levels close,
   saving eligible edits. Invalid drafts can keep the menu open with feedback;
   discard is not implicit. No NPC dialogue/other-addon close is intended.
4. Hold each face, release in both orders, press the face before R1, and try both
   faces together. Expect at most one command from a fresh eligible face, no
   ordinary Square/Triangle game action, no Ctrl+Numpad pulse, and no extra R
   on R1 release. Bare unused R1 still sends R; arrows/Enter/Escape still work.
5. Check native-menu-open, chat/text, XIVCrossbar editor/chooser, L1, L2/R2 both
   orders, focus/client handoff, restart/disconnect and brief/stale leases. Native
   menus permit Trust commands; other contexts have priority. Try messages off
   at neutral: these new personal command slots stay reserved without injecting
   a native shortcut. Restore messages on for direct menu commands.
6. Trace if needed: R1 Trust menu button=6/8, message rmenu button=6/8 and current
   Controls version. Protocol/permission show route support, not a live receipt
   or successful Trust save. The new bank API in docs remains proposed.

## Implementation and local verification

Reviewed project/shared workflow, testing history and exact starting tree: all
2,268 local blobs matched GitHub. Inspected current Trust main and menu test
branch (31245d39fce64847db755e7c900d6bf111624c07); close exists only in the latter,
and open was not an explicit verb. A coordinated one-runtime-file Trust addendum
uses its existing HUD open method and preserves close validation. No Trust data,
preferences, menus/rendering or profile save algorithm changes are needed here.

Two whitelisted rmenu events use the same ordered/acknowledged DirectLink stream.
The receiver validates the entire packet before dispatch and advances the ack
before execution. Cancel preempts queued menu requests. A separate lease field
advertises the capability independently of the L1 native-menu visibility token.
Old senders remain on their previous controls; new AHK cannot send extended
events to older Lua without the advertised permission. Both sender and receiver
check context; sender also checks transport freshness/backlog and consumes the
face hold. Uncertain/neutral transitions suppress new menu-face output. Existing
R1 consumed-hold state prevents later release-R.

Actual-source tests cover the full AHK poll/menu sender/R1 release machine,
once-only messages, held/face-first/ambiguous chords, raw masking, native-key
absence, guards and capability handoff. Lua tests run the actual root guard and
real receiver for ordering/dedup/atomic rejection/cancel/context rules. Existing
six-bar/menu/chooser/lease, IJKL, R1/F8 and trace regressions pass; AHK lexical/
include/function checks pass. All 114 Lua sources parse with the documented
Lua 5.4 normalization fallback. Trust checks use its actual menu command and HUD
open method plus actual base dispatcher; OS/rendering are mocked. Native Windows/
Windower/FFXI/Trust acceptance remains pending. Historical records follow unchanged.

---

# Text settling checkpoint 1 — October 17, 2026 (America/Chicago)

Author A. development/directlink, based on 6a0052fe23e83157f62f9abfefd2731dbf1d559c.
Runtime 0.4.0-a.20261017.directlink1-text1; unchanged Controls=9.7-realkeys.
Continues the unfinished rendering work from the supplied Franklet capture.
Default ON with //xb textsettle off comparison. Exact checkpoint is identified
by its Git commit/delivery. Public RC3 and frozen Unbound snapshot are preserved.

## Install and native acceptance — pending

1. Preserve installed data/settings/artwork. Update Lua sources, including the
   new ui/text_measure.lua, and reload XIVCrossbar. This batch changes no AHK.
   Updating from before realkeys1 still requires that checkpoint's AHK restart
   to test real IJKL. Confirm directlink1-text1 via //xb inputstatus.
2. //xb textsettle status should report ON. Reveal L1 and L1->L2 repeatedly,
   change aliases and scale, switch sets/pages quickly and visit binder headings.
   A new label may appear a few rendered frames after the surrounding art;
   repeated known labels should be immediately positioned. Commands respond on
   their existing input route and do not wait for caption settling.
3. Confirm native extents update with glyph/outline/background alpha zero. If
   labels consistently appear only after the eight-frame fallback or the delay
   feels wrong, compare //xb textsettle off. Neither local mocks nor the trace
   alone proves which final pixels Windower draws. Matching widths across frames
   are a heuristic, not an explicit native caption-revision acknowledgment.
4. Check long titles/font fitting, fade reversal, chooser title/overlay dimming,
   hidden/reused menus, drag/scale and unload/reload at 960x540, 1280x720 and the
   desktop resolution. No leaked outlines/background, permanently invisible
   caption, delayed resurfacing or recentering after reveal is intended.
5. //xb rendertrace on; reproduce; mark and save promptly. New text-settle events
   report pending/ready/fallback/bypass; native alpha/pos/extents retain the same
   observation semantics. Capture OFF/ON comparisons and note first-use versus
   repeated captions. //xb textsettle on/off is saved per character and follows
   configuration refresh. Off restores immediate measurement; return On to retry.

## Implementation and verification

Read AGENTS, current project/shared NPCMirror WORKFLOW and TESTING. All 2,266
local blobs matched the published starting tree. Reviewed current Windower texts
API source: extents forwards get_extents, while alpha setters maintain native
text settings; no guarantee about transparent native measurement is inferred.
Capture evidence: Ctrl+Space at frame 334 width 0/x238/alpha255, then frame 335
width73/x201.5; a changed binder heading also returned 211 then 416 for the same
caption revision. The latter defeats a zero-width-only retry policy.

New ui/text_measure provides distinct-frame sampling and a 512-entry FIFO cache
keyed by caption, actual pixel font size/font arguments, padding and relevant
style. Unknown widths stay pending until two matching positive samples on later
frames. An eight-frame failure uses width zero at a fixed anchor and is never
cached; it stays fixed rather than hopping when a late width finally appears.
No clocks, timers, extra drawing objects or per-frame disk writes are added.
ui/resources owns temporary transparency and preserves requested alpha/stroke/
background through fade/chooser changes. Owners commit only after position/fit.
Hide releases measurement ownership; disposal retains existing resource cleanup.
The helper is shared by L1, geometry centers and binder caption layout. L1 caches
only after settling; known styles reuse widths. Root advances measurement frames
before UI updates and refreshes the comparison preference with character config.

Actual-source tests replay the zero/stale-positive sequences, reject repeated
same-frame calls as progress, reuse/evict cache entries, fit fonts, scale/drag,
preserve changed opacity, cancel hidden/disposed/superseded text, release ordinary
reuse, bound missing widths and exercise the real companion/static cache and
comparison commands. Existing render-trace tests now advance render frames and
start both observer comparisons with equal cache state; the benchmark also uses
fresh equivalent objects/caches. Trace OFF/ON preserves native call sequences.
All 43 Lua test files pass; 113 sources parse using the documented Lua 5.4
normalization fallback. Controller message/ownership regressions and AHK static
checks pass. This is source/simulated verification; Windows/Windower/FFXI visual
acceptance remains pending. No new bank mappings, Trust changes or directory/
asset migrations are included. Historical records follow unchanged.

---

# Real IJKL comparison checkpoint 1 — October 17, 2026 (America/Chicago)

Author A. development/directlink, based on a9b2486937ec3bbeacd545ec505d9920e0381f75.
Runtime 0.4.0-a.20261017.directlink1-realkeys1; Controls=9.7-realkeys.
Opt-in comparison only; default OFF. Exact checkpoint is identified by its Git
commit/delivery. Public RC3 and frozen Unbound snapshot are unchanged. No Trust
code, renderer, mapping/bank, asset path, installed data or module moves.

## Install and native acceptance — pending

1. Preserve data/, config.ini, personal icons and Trust settings. Stop the shared
   wrapper, unload Lua in every client, update DirectLink, then restart Lua AND
   AHK. Lua reload alone cannot update the sender. Confirm runtime with inputstatus
   and Controls=9.7-realkeys / realkeys protocol=1 with controller status.
2. Profile x; //xb messages on; //xb dpad ijkl; //xb inputtest off;
   //xb realkeys on. Return all controls to neutral. Status reports configured
   state and AHK output permission, not proof of a down event or Trust consumption.
   Old wrappers keep normal Lua output and warn to restart rather than losing
   all D-pad input. //xb realkeys off rolls back after neutral; bare toggles.
3. Trust closed: D-pad Up/Right/Down/Left should behave like keyboard I/L/K/J,
   including native game menus. Trust open with its separately updated build:
   verify navigation, repeat/hold, Enter/Escape and no underlying game movement.
   Trust must recognize AND block key events; this thread changes no Trust code.
4. Test fresh direction, release, held direction then L1/R1, L2/R2 (both orders),
   face/click/touch/Options/Share, modifiers and chat/XIV editor entry. Owned
   keyboard output must release and stay masked until the direction is released;
   no surprise crossbar slot or resumed hold. Fresh trigger+direction remains
   normal DirectLink. Native menu opening alone intentionally does not revoke
   ordinary-key permission; companion hide/executable guards remain unchanged.
5. Test wrapper/Lua stop/reload, disconnect, stale leases and focus/client handoff
   while a direction is held. No stuck key, delayed press or other-client down.
   Exercise physical IJKL/modifiers too. Toggle on/off, messages, dpad mapping and
   inputtest at neutral. All six bars, R1 arrows/Trust shortcut/unused R and R3
   F8/R should retain their current behavior. Trace on if needed; markers include
   real IJKL own <key>, personal <key> down/up, and the 9.7 Controls version.

## Implementation and local verification

Lua publishes effective real-IJKL permission in the current character lease.
Permission requires profile x, messages, ijkl, inputtest off and a current message
session; its parser is independent of L1's native-menu token. AHK owns only fresh
ordinary eligible D-pad holds, emits SendEvent through existing PersonalKey and
masks both edges from the ordinary stream. No global Lua gameplay suppression:
an old wrapper still works. Existing physical-key ownership/old-window release
and brief uncertain-read behavior are retained. Permission changes release keys
and require neutral; a consumed hold never changes owner mid-press. No sleeps,
polling changes, Apps/F-key experiment or general Lua->AHK output service.

New actual-source AHK checks execute the sender, filter, lease parser, key owner,
release cleanup and full PersonalPoll under the narrow JS translation. Cover four
directions, one down/up per hold, no corresponding message direction, physical
keys/modifiers, every ordinary-control exclusion, held combo transitions, route
phases/staleness, context/client cleanup, old Lua compatibility and no R1-arrow
duplication. Lua checks cover default OFF, idempotent/toggle/status/invalid command,
permission prerequisites, immediate lease publication and actual root menu/focus/
cutscene gating. Existing message/six-bar/native-menu/lifecycle/chooser/Save Only/
render-trace and personal-control regressions pass. Lua parsing uses the documented
Lua 5.4 normalization fallback, not native Lua 5.1. Windows/AHK/FFXI/Trust live
execution is unavailable; no live result is inferred from simulated success.
The broad sweep also found an older profile-persistence fixture missing the
render-trace startup register_event stub and target-migration isolation (same
runtime code at the base commit). Updated that fixture only; no profile/runtime
policy change. All 42 Lua test files
and six JS test files pass, plus AHK lexical/include/function checks; all 111 Lua
sources parse under the documented fallback.

Reviewed current AGENTS/WORKFLOW/TESTING and shared NPCMirror WORKFLOW. Baseline
comparison found all 2,263 local blobs identical to current GitHub head before
editing. Historical records follow unchanged. Roadmap now records latest L1/R1
intent, trace-backed settling and path-resolver-first cleanup priorities.

---

# Folder audit and example presets — October 17, 2026 (America/Chicago)

Author A. development/directlink, based on bfdf7d693c387dac9782144b0139d466e9c0ccf5.
Documentation/data-example checkpoint only. Runtime remains directlink1-r1test1;
Controls=9.6-r1-r. No Lua/AHK, theme/image, runtime profile, cache, saved settings,
module path, loader or native-menu policy is changed. Public RC3 and preserved
Unbound snapshot remain untouched.

Reviewed current AGENTS/WORKFLOW/TESTING and the current shared NPCMirror WORKFLOW
(same substantive instructions). Compared the current tree to upstream master,
still 15d8381dfad0f9efdb84fe2d24655afc150faec4 on October 17. Upstream has no
docs/tests/packaging/examples directories; its theme tree contains the same nine
image paths. The fork's test fixture explicitly credits Windower source.

Added docs/FOLDER-STRUCTURE.md: structural and content asset dependencies,
generated/cache and persisted-icon constraints, a complete classification of all
50 root Lua files, AHK-root anchoring, developer-folder origins, an optional
images/themes migration and a staged loader/path/packaging validation plan.
These are proposed moves; source paths are preserved by this checkpoint.

Added examples index and presets/fenrir-20261016, recovering seven files
byte-for-byte from the previously prepared bindings Test1 ZIP. Includes Cioara's
unchanged supplied October 15 bar, Franklet/Lionstag copies clearing only its
four L2 D-pad nodes, the matched 34-record global catalog, original October 14
catalog reference, reconciliation report and optional suggestions. This is not
a fresh PC export. The existing generic template remains unchanged. Guides
explain shared IDs, deliberate catalog merging, dependencies and exact install
destinations; nothing is auto-installed over data/.

Verification: all example XMLs parse; original member bytes/source SHA256 match;
adjusted bars are semantically identical except for the four specified nodes;
Franklet/Lionstag copies are identical; 34 linked current slot values resolve to
34 unique catalog IDs. The All Confirm last-icon marker is historically blank
while the current icon/catalog use custom_actions; all three occurrences are
preserved as original override metadata, not falsely described as identical
last-icon snapshots. Current values match. Existing template/catalog binding
regressions are checked; no native FFXI command execution is claimed.

User paused the proposed relaxation of the native-menu guard. Audit confirms
it hides the companion AND revokes/cancels the L1 bank's executable session,
while ordinary DirectLink remains available for menus. Keep that default guard;
future scrolling/NPC navigation must use explicitly scoped behavior. Inventory/
emote and R1/NPC/Trust layouts remain proposals, not part of folder cleanup.

No runtime testing is needed to infer that unmodified runtime paths remain
unchanged; complete-tree comparison enforces that scope. A future actual move
requires loader/resource/packaging and native overlay/fresh-install acceptance.
Historical testing records follow verbatim.

---

# DirectLink R1 checkpoint 1 — October 17, 2026 (America/Chicago)

Author A. Branch development/directlink; base f04f790d4836df0cee4c9761c7be871222abcdcd.
Runtime 0.4.0-a.20261017.directlink1-r1test1; Controls=9.6-r1-r.
User returned to the thread asking for R1 to become R. Implement an unused-release
gesture, preserving existing R1 chords and R3 F8/R. Public RC3 and the frozen
Unbound snapshot are unchanged. This checkpoint is committed/pushed for testing;
its exact commit is recorded in Git history and delivery feedback.

## First live checks — pending

1. Stop the shared wrapper and unload Lua in all clients. Preserve installed
   data/, config.ini, icons and Trust settings. Update the existing DirectLink
   folder, reload Lua and restart the wrapper. Verify directlink1-r1test1 and
   Controls=9.6-r1-r via //xb inputstatus and //xb controller status. Lua reload
   alone cannot update AHK. No settings migration or companion replacement.
2. Tap bare R1: no R on press; exactly one R on release. Holding R1 produces no
   repeat. Check the native action corresponding to R with the current keymap.
3. Hold R1 and use each D-pad/face combination, L1+R1, R1+L2/R2, touch/click/PS.
   Existing commands should work; releasing R1 must not also emit R. Test both
   release orders, especially releasing the chord's other button first.
4. Hold R1 through focus/client handoff, disconnect, addon text/menu context or
   wrapper stop/restart. Release must not produce delayed R; return neutral and
   make a fresh tap. Test physical Ctrl/Alt/Shift/Win/Apps/R ownership too.
5. R3 still sends eligible F8 on press and R on unused release. Both ordered
   click zooms, L1 order/companions, DirectLink bars and ordinary keyboard keys
   retain existing behavior. If diagnosing, controller trace includes the new
   Controls version and the explicit r1 unused release -> r marker.

## Implementation and local checks

Pure R1 state machine: idle -> armed on a fresh unused down; R on armed release;
another controller action consumes the hold until release. This prevents R from
firing when a chord ends. The sender preserves physical modifier/R ownership and
suppresses overlap with outstanding generated keys. Context cleanup and even a
brief uncertain lease cancel the deferred tap. No polling/key-delay change,
held-R behavior, automatic repeats, L1 remap or message protocol change.

36 actual-AHK gesture scenarios run under the existing narrow JS translation.
Actual R1 sender/filter/F8 checks cover single release, consumed holds, physical
modifiers/R, pending generated keys and cancellation wiring. Message transport,
client lifecycle, input trace and AHK lexical/include/function-link regressions
also pass. Lua static checking uses the documented Lua 5.4 normalization fallback;
native Lua 5.1/Windower and Windows/AHK execution are unavailable. Live acceptance
is pending; these are source/simulated results, not in-game success claims.

Reviewed current project AGENTS/WORKFLOW/TESTING and the unchanged shared
NPCMirror WORKFLOW reference before editing. Cumulative records follow verbatim.

---

# DirectLink diagnostic checkpoint 1 — October 17, 2026 (America/Chicago)

Author A. Branch development/directlink; base c8f198ab2de20bad07678ce23c5f5c134e467ca7.
Runtime 0.4.0-a.20261017.directlink1-trace1; unchanged Controls=9.5-messages.
Chooser repair commit: 0873707898fd50d3f19503f9cdb30b90eef70a9c.
The diagnostic commit follows it; its exact ID is in Git history/delivery feedback. Snapshot
1 and public/rc3-maintenance remain unchanged. No installed settings/data ship.

## First live checks — pending

1. Preserve data/, config.ini and personal assets. Install this source over the
   existing DirectLink folder and reload Lua. This batch changes no AHK bytes;
   the already-running Controls=9.5-messages wrapper can remain. Verify runtime
   with //xb inputstatus. Older wrappers still need stop/start per Test 6 below.
2. Open Options chooser, move to another set, then press the configured Cancel
   face while Options is held. Expect original set restored and chooser closed;
   releasing Options must not reopen or commit the cancelled selection. Repeat
   with the binder open, physical Escape and ordinary release-to-select. Other
   face buttons must not execute actions or leak native keys. Compare messages
   on/off only at neutral. Check nondefault Cancel mapping if used.
3. //xb rendertrace on; reproduce text/set/page flicker at the usual resolution.
   After a hop use //xb rendertrace mark, then //xb rendertrace save promptly.
   Send data/render-trace-<character>.log with a description of the affected
   screen/label. Off saves and stops. Save before unloading: history is memory
   only. Repeated saves overwrite this character's file; preserve a useful copy.
4. Compare the same navigation with rendertrace off/on and note any change in
   feel. No visible overlay, per-event chat or altered fade is intended. Capture
   is OFF after reload, and does not persist. //xb rendertrace status reports
   retained/overwritten counts. No minimum retention duration is guaranteed.
5. Controller status should distinguish requested route, actual active route and
   key fallback=apps. R3 remains F8 on eligible press/R on unused release; R2 F8
   remains off by existing default/choice, bare R1 unassigned. Existing L1/menu
   hiding and shortcuts, six trigger bars, Save Only and multibox checks remain.

## Changes and verification

Chooser: supplied console/source showed a missing is_cancel_button method.
Actual routing regression then exposed a second obstacle: the shared router
discarded every chooser face before the handler could recognize Cancel. Added
the real layout-aware helper and removed that early filter; the chooser's own
handler consumes all face/D-pad input. Tests use actual binder helper/router
source (not a fake helper), all four layouts/all saved cancel choices, and
message-driven chooser cancellation including a remapped Cross. Native acceptance
of complete chooser restoration remains pending.

Render tracing: a default-off 6,000-event chronological ring records changed
native text calls, every caption write, caption revision/owner/stable ID,
existing measurements and requested layout/visibility, creates/destroys/retirement,
frame gaps and root context (bar/set/menu/page/viewport/scale/L1/input ack).
Counters summarize unchanged calls. IDs use weak keys and no objects enter the
event buffer. No extra native extent/getter calls; no opacity or layout policy
change. Captures are saved explicitly/per character, with write failures reported.
This is a Lua observation stream, not a GPU screenshot or action-success receipt.

109 Lua sources parse with the available Lua 5.4 temporary Windower-syntax
normalization fallback. Lua 5.1/Windower and Windows/AHK execution are unavailable.
New trace tests check exact native-call parity on/off, zero/stale/updated widths,
proxy return values, object aliases/revisions, unchanged-context deduplication,
bounded chronological eviction, mark/save/off/status routing, failed writes,
per-character filenames, disabled clock silence and weak lifetimes.

Simulated 600-frame/48-centered-label workload measured 0.032 seconds OFF versus
0.154 seconds ON (about 0.20 ms extra per simulated frame), with identical 34,560
native calls. This single local Lua 5.4 run is not a Windows performance claim;
enabled tracing has measurable cost and needs live comparison. Retention is
activity-bounded, not a guaranteed number of seconds.

Regression checks pass for menu resource ownership/repeated redraws, compact
geometry, rebuilds/deferred destruction, caption replacement, text fades/reversal,
slot cleanup/visibility/costs/indicators, all six bars and message protocol,
L1 context/bank/mailbox/view, personal defaults/F8 choices, Save Only/catalogs,
help and actual controller status. Updated the older status test's missing L1/
message-service fixtures to match the current runtime; no new runtime status
failure was found. AHK message/gesture/filter/client/trace simulations and seven
AHK lexical/include/function-link checks pass. AHK runtime files are unchanged.

## User decisions and deferred work

User approved chooser repair and render trace. Transparency until layout settles
is a candidate fix, not implemented before evidence. R3 F8 stays; /focusnpc is
not adopted. Public DirectLink port belongs in the user's separate conversation.
L1 menu-context scrolling, direct /sack, Lua-owned shoulder gestures, other
readers, Mute-held bank and success-confirmed quickswitch remain proposals.
Broad menu_open is not specific menu identity. Transport acknowledgment means
Lua accepted input, not that the game/server completed Sic or another action.
No packet observation/injection or automatic action retry is introduced.

Reviewed current shared NPCMirror WORKFLOW and project AGENTS/WORKFLOW before
editing. Author A; tests/source records are preserved below. This delivery is a
development checkpoint, not a replacement for the frozen live-tested snapshot.

---

# DirectLink chooser cancellation repair — October 17, 2026 (America/Chicago)

Author A. development/directlink, based on c8f198ab. Repair the missing
layout-aware is_cancel_button helper and remove the earlier router filter that
prevented chooser faces reaching Cancel. The chooser still consumes every other
face/D-pad input. All four layouts/saved cancel choices and actual message/router
cancellation, including a remapped Cross, pass simulated regression checks.
Native chooser restoration/release acceptance remains pending. No AHK or mapping
changes; runtime version remains personal9-l1test6 in this isolated fix commit.
The following diagnostic checkpoint will identify its new version separately.
Reviewed current NPCMirror WORKFLOW and project AGENTS/WORKFLOW/TESTING.
Frozen Unbound snapshot and public RC3 remain unchanged. Historical records follow.

---

# DirectLink history and render-diagnostic review — October 17, 2026 (America/Chicago)

Author A. Documentation-only review on development/directlink, based on
86b50f103425d1ed871d7612735d2d4fa6e3126c. Snapshot 1 is unchanged.

Reviewed the current shared NPCMirror WORKFLOW (bc17a173) and root WORKFLOW/
AGENTS; substantive instructions match. Reviewed current render geometry,
caption layout, resource ownership, action binder/router, chronological testing/
personal notes and retrieved older conversation summaries. Current source and
latest user choices supersede stale TODOs. Historical summaries remain leads,
not proof a feature is still missing.

Added docs/ROADMAP-DIRECTLINK.md with:
- A proposed bounded, quiet render trace covering frame/context, caption revisions,
  measured extents, placement/font/visibility changes and object lifecycle.
  No rendertrace command is implemented by this review.
- The source-supported hypothesis of deferred extent/centering corrections,
  distinguished from the unproven cause of the visible jump.
- A confirmed chooser-cancel call to a missing binder method, matching an older
  uploaded console error; it is queued for repair, not fixed here.
- Active, optional, completed and superseded controller/UI work, and separate
  adjacent projects. Four earlier public ports are present in dc5e02e despite
  older retained NOT PUBLISHED wording in that branch's TESTING.
- Continued first-live-confirmed DirectLink status, with broader acceptance and
  visual/desktop/native crash questions still open.

Documentation verification compares complete repository trees and permits only
the new roadmap plus README/TESTING updates. No runtime test is claimed rerun
and no code, bindings, settings, runtime version or preserved snapshot changes.
The uploaded trace/chat/console files are not copied into source control.
Historical testing entries follow unchanged.

---

# DirectLink — Unbound, Development Snapshot 1 — October 16, 2026 (America/Chicago)

Author A. Snapshot branch: `snapshot/directlink-unbound-20261016`. Future work: `development/directlink`.
Exact tested executable baseline: `7e0e25253aa7cb64451e1b3f18ef861b0a90726f`.
Runtime remains personal9-l1test6; Controls=9.5-messages. Naming/documentation
only: the snapshot preserves every executable/runtime file from that baseline.

## New live result

User reports the controls work "exactly the same if not better" and requests a
named development snapshot. The new 30-second capture beginning 2026-10-17
04:48:22 UTC (October 16, 11:48:22 p.m. Chicago), appended to
controller-input-trace(1).log, identifies Controls=9.5-messages. It contains
81 message downs, 80 message ups, two cancels, and zero ordinary Apps/F-key
transport emissions. Earlier capture data in that same file remains historical.

Franklet_2026.10.16.log reports active route messages, 706 cumulative events
received, zero rejected and no write error. The received count includes protocol
events; it is not a gameplay success count. R2's trace message is followed by
Lua context changing to crossbar. console(20261017-044954).log records Test 6
loading successfully at 23:39:43. The old wrapper lacks the new message record
generation function. These independently observed records confirm that the
message route ran in-game. The user's subjective response is positive; no
controlled latency improvement is claimed.

## Preservation and remaining checks

The snapshot is named **XIVCrossbar DirectLink — Unbound**: keyboard-free ordinary
controller transport. Personal shortcuts/native key outputs and the optional
legacy route still exist. The status modifier field still says apps for the
fallback; active mode is Button route=messages. No status/runtime cleanup is
folded into this checkpoint. See [the snapshot record](docs/SNAPSHOT-DIRECTLINK-UNBOUND-1.md).

The snapshot branch is for recovery/reference. Continue on development/directlink.
Original Personal and RC3-based New Personal are retained as historical lines;
the last keyboard-first comparison checkpoint is f92c0b86f3d79de5542062ee9ad9d4027bbb3c46.
The public RC3 branch is untouched.

Verification for this documentation-only checkpoint compares the complete Git
trees: all files except the named Markdown records must retain identical blob
SHAs/modes. No runtime tests are represented as newly rerun. Earlier source/
simulated verification belongs to Test 6 below. Initial live operation is now
confirmed; exhaustive six-bar/menu/multibox/lifecycle/disconnect/low-frame-rate
acceptance remains pending. Earlier pending statements below describe their
original delivery state and are preserved rather than silently removed.

Supplied trace/chat/console files are evidence references, not runtime files to
ship or private material to commit. No new installer is required to keep using
this exact tested runtime. Snapshot documentation is committed on the new line.

---

# Personal 9 L1 Test 6 — October 16, 2026 (America/Chicago)

Author A. Branch personal/ps5extended. Baseline published Test 5:
f92c0b86f3d79de5542062ee9ad9d4027bbb3c46. Exact new local/published commits are
in the generated package header. Runtime personal9-l1test6; Controls=9.5-messages.

## First live checks — native Windows/FFXI pending

1. Stop the AHK wrapper and unload all clients before replacing the complete
   xivcrossbar folder. Preserve data/, config.ini, personal icons and existing
   Trust settings/quiet overlays. Unchanged TrustMovement 0.1.1 is alongside it.
   Restart BOTH Lua and AHK. Lua alone cannot update the running script.
2. Use //xb x if needed; return all buttons to neutral. //xb controller status
   should show personal9-l1test6 via addon status, Controls=9.5-messages, button
   route=messages and no write error. Sent/ack advances with button gestures.
   A fresh setting defaults to messages ON; any later explicit choice persists.
3. Try L2, R2, L2→R2, R2→L2, double-L2 hold and double-R2 hold. Test every face/
   D-pad slot, quick taps between frames and trigger+face sampled together. Each
   gesture should select the same one of six bars and execute once per fresh
   press. Circle in a crossbar must not leak Escape; confirm/cancel outside it
   should retain their previous behavior. Real F-keys must remain keyboard keys.
4. Test L1, L1→L2, L2→L1, release orders and R2 priority; personal shortcuts,
   R1 arrows/confirm/cancel/Trust shortcut, touch peek, PS focus, H/R and zoom.
   Both L1 companions should still hide in native menus. Ordinary message input
   stays available there; this does not change the native setkey IJKL behavior.
5. In the addon editor/chooser, test navigation, L2/R2 page releases, Options
   press/release and Escape/Enter ownership. Keep draft text during focus changes.
   Recheck Save Only, action-switch destinations and empty/changed caption redraw.
6. Hold a trigger/face while changing clients, disconnecting, stopping/restarting
   the wrapper, logging out, entering a cutscene or restarting Lua. Held state
   should cancel, and another client must require neutral before a new gesture.
   A missing advancing heartbeat clears Lua-held input after 350 ms. Source
   writer backlog cancellation uses 350 ms too; native Windows timing needs
   checking. A lease that disappears completely can return the old login route
   only at neutral after 2.5 s since the last valid read. No hot fallback mid-hold.
7. Compare //xb messages off versus on, returning neutral after each command.
   Bare toggles; status reports the saved choice, controller status the active
   wrapper route. Off restores Apps/F-key transport. Other profiles retain their
   old route. Compare focused one-client and multibox feel at the same settings.
8. If input differs, //xb controller trace on captures 30 seconds. Include addon
   status and controller status. Trace distinguishes message down/up/cancel from
   emitted F-key events. InputTest remains available for dummy-action checking.

## Implemented scope

The experiment moves the twelve ordinary logical buttons into one ordered
physical-event stream, so the trigger and its face/D-pad slot cannot overtake
each other through different input channels. AHK emits no Apps/F1–F12 events for
that stream. A shared Lua router feeds the original bar/menu/slot logic; direct
native gameplay translation still uses Lua setkey. Personal shortcuts and the
Trust movement receiver are retained; no general Lua→AHK keyboard service or
inventory/wardrobe/Trust remap is installed. R3-only targeting and bare R1 free
remain from Test 5. Target acquisition guards now also recognize message holds.

Each client leases an independent token and saved transport mode. Complete
snapshots carry ordered edges, acknowledgments and an advancing heartbeat.
Malformed/partial/gapped/old-token input is rejected before dispatch; duplicates
are acknowledged without replay. A cancel supersedes earlier queued actions in
its snapshot. Focus, lifecycle, prolonged render stalls and heartbeat expiry
invalidate held state. Route/client/writer changes require neutral. A restarted
writer resumes above Lua's ack and sends cancellation before new downs. Write
failures stay owned by the message path; they never inject keyboard duplicates.
Native file operations and scheduling remain unverified here.

## Verification performed here

86 Lua sources parse using the documented Lua 5.4 Windower-syntax normalization
fallback; no native Lua 5.1/Windower execution is claimed. Actual message receiver
checks cover atomic validation, ordered batches, duplicates, sequence gaps,
partial writes, stale timestamps/tokens, cancellation preemption, unchanged-file
heartbeat expiry, client isolation and command persistence/validation.

Actual root router and original bar-selection function receive real decoded
messages in a simulated environment: all six bars, both orders, batched double
taps, once-only slots, native confirm/cancel, held-face ownership, addon menu
routing, keyboard F-key isolation and legacy fallback pass. Actual publication
checks preserve a separate message session while native menus revoke L1's bank
session; focus/render-stall/toggle cleanup passes.

Actual AHK lease/poll/queue/cancel functions run through a narrow JS translation:
neutral handoffs, trigger-before-slot order, release order, held dedup, uncertain
lease suppression, overdue backlog cancellation, writer-ack resumption, client
handoff, logout fallback and no-key-injection branch ownership pass. Native AHK
parsing, Windows FileMove/keyboard delivery and live FFXI acceptance are pending.
Seven AHK lexical/include/function-link checks pass. Existing 30 personal gesture
checks, prefire/filter/lifecycle/trace helpers, bank/view/lease guards, Save Only,
catalog/XML/default/profile, caption replacement and menu-resource checks pass.

## Delivery and user record

User explicitly requested the message-based L2/R2 experiment after understanding
that show/physical-button messages can replace transport keys. Kept it switchable
and personal, with all twelve ordinary buttons ordered to prevent cross-channel
races. The latest live feedback remains that the preceding controls feel good;
Test 6 itself has not been tested in FFXI. Complete package includes README,
WORKFLOW and this cumulative TESTING inside xivcrossbar/, plus the unchanged
TrustMovement receiver beside it. No saved settings/catalogs/bindings are shipped.
Source is committed/pushed to the personal branch before delivery; public is
untouched. Shared NPCMirror WORKFLOW reviewed at unchanged bc17a173 blob.
Historical releases below remain the record of their own verification.

---

# Personal 9 L1 Test 5 — October 17, 2026 (UTC)

Author A. Branch personal/ps5extended. Baseline published Test 4:
0d8888fdc5ae74ff4e9626cd8365445b1fa45cfa. Exact new local/published commits are
in the generated package header. Runtime personal9-l1test5; Controls=9.4-input.

## Current checks — native Windows/FFXI pending

1. Stop the wrapper/unload clients. Install complete xivcrossbar/, retaining
   data/config.ini/custom icons. Restart Lua AND AHK; verify both version strings.
   Unchanged TrustMovement 0.1.1 remains alongside the addon; preserve its data.
2. On first load, existing settings adopt R3 F8 on / R2 F8 off once. Bare R3
   gives F8 on press, R on unused release. Bare R2 gives only its ordinary bar.
   Bare R1 gives no F8 or R; R1 arrows/Enter/Escape/Trust shortcut and L1+R1 Tab
   remain. Check both ordered zoom gestures and all existing L1/L2 orders.
3. //xb x selects PS5 Extended; //xb r2, r3, both toggle their acquisition flags.
   Both enables both unless both are on, then disables both. Explicit on/off
   is idempotent; status only reports. Long target commands keep status behavior.
   Use //xb r2 off and //xb r3 on to restore requested selection. Restart/relog:
   later explicit settings must persist without the one-time adoption repeating.
4. Fresh settings have Shared disabled; explicit saved preferences survive.
   Both companions hide in native menus and chat, using existing guards. Verify
   menu shortcuts remain usable. No broad inventory/wardrobe/Trust remap is added.
5. Repeatedly switch sets, including shared aliases, changed captions and empty
   destinations. Populated captions now replace directly; unchanged native text
   is not rewritten. Empty/explicit clears still clear. Watch for the reported
   flicker/recentering, especially at small resolutions. This removes one source
   of redraws, not a claim that all native rendering causes have been identified.

## User feedback and scope

User reports controllers now feel really good, L1 looks good, and native-menu
companion hiding is welcome. This is live feedback on the preceding installed
build; it is not acceptance of Test 5. Desktop/controller comparison remains
unreported. Preserve timing, menu guards and established gestures. Future L1
inventory/R1 wardrobe/Trust changes remain brainstorming. Actual user shortcuts:
Ctrl+I/M/E/J = Item/Magic/Equipment/Job Ability; Ctrl+Space/Q/S/1/2/3 = jump/quest/
sack/wardrobe/wardrobe2/wardrobe3. Do not silently install those custom bindings.

## Verification performed here

Actual target handlers/default/profile normalization pass R3-only adoption-once,
persistent later choices, aliases/toggles/status and invalid-input checks. Source
routing and pure AHK gesture checks confirm bare R1 sender removal while keeping
combinations. Actual ui load/clear methods with real geometry text caching verify
100 unchanged caption reloads emit no native writes, changed captions replace
without blank, and empty/explicit clears remove old labels. Existing bank/lease,
menu ownership, profile, Save Only and catalog checks are included in validation.
Lua parsing uses the documented Lua 5.4 normalization fallback; AHK checks are
lexical/simulated. Native AHK/FFXI loading, feel and visual acceptance are pending.

## Delivery register

Complete Test 5 includes source, README, WORKFLOW and this cumulative TESTING
inside xivcrossbar/, plus the unchanged TrustMovement receiver alongside it.
No saved data/catalog/bindings are included. Source is committed and pushed on
the personal development branch; public branch is untouched. Historical entries
below remain the record of their own releases.

---

# Personal 9 L1 Test 4 — October 16, 2026 (America/Chicago)

Author A. Branch personal/ps5extended. Baseline published Test 3:
dd50529e9a68cd47609d2d102e3c08e656ba1adb. Package header identifies exact new
commits. Runtime personal9-l1test4; wrapper Controls=9.3-input.

## Current live checks — pending

1. Stop the wrapper and unload all clients. Install the complete xivcrossbar
   folder, retaining data/config.ini/custom icons. TrustMovement receiver is
   unchanged and remains alongside it. Restart Lua AND the wrapper; verify
   personal9-l1test4 and Controls=9.3-input. Old leases lack the new END trailer.
2. Begin with //xb controller target both off. Recheck L1 shortcut/bank press and
   release orders, rolling D-pad directions, held buttons during reveals, native
   menu toggles and all six ordinary trigger bars. Repeat the captured sequence.
3. //xb controller trace on; capture one focused client for 30 seconds. Expect
   any brief lease miss to resume without forcing L1 neutral. A genuinely stale
   lease, changed token/menu/text/focus/disconnect must still cancel and rearm.
   Status now reports short context pauses; trace includes controls version.
4. Compare laptop Franklet and desktop Cioara with this same controller, same
   profile/client load/sequence and trials off first. User reports far less
   stickiness on laptop Franklet; desktop comparison is not yet reported.
5. //xb controller target r2 on, return neutral, then fresh bare R2: native F8
   down/up must precede Apps+F12; no repeat while held. Release and press again.
   Existing targets can change. Same-poll R2+face, L2/R1/L1 overlaps, native menus,
   chat, cutscenes, held keyboard modifiers/F8 or active Apps must skip acquisition
   and retain the existing combo. No target-completion acknowledgment is assumed.
6. Turn R2 off, then //xb controller target r3 on: fresh bare R3 gives F8 on press,
   R on unused release. R3-first zoom also gets the first F8; L3-first zoom does
   not. Enable both only after comparing each; //xb controller target both off
   restores prior targeting behavior. Settings save per character.
7. Recheck bare R1 F8, R1 arrows/Enter/Escape/Ctrl+NumpadPlus, PS focus, touch peek,
   H/R releases, both ordered zoom gestures and movement takeover. Recheck Save
   Only, catalogs, Main/basic switch round trips and companion geometry/drag.
8. No direct-AHK bare-face rewrite is installed. Lua still owns ordinary native
   face routing and addon/crossbar actions. See docs/CONTROLLER-REFERENCE.md for
   complete readers/mappings and the native-menu versus addon-menu distinction.

## Observed trace and responsibility

User supplied controller-input-trace.log, 67,670 bytes / 735 lines: one 30-second
ps5-extended capture beginning 2026-10-17 00:23:21 UTC (October 16 19:23:21 Chicago).
Its header lacks a control-version marker; do not claim the exact installed build.
Six no-matching-lease misses occur. At ticks 40731281→40731296 the context goes
unknown then returns gameplay after 15 ms, but personal_ready stays 0 until
40735687 while L1 is held: approximately 4.4 s of lost personal readiness.
The source deletes a lease before rename, producing the observed possible gap.

Separate source defect: PersonalFilter deletes PC.blocked entries during its
for-enumeration. AHK documents possible skipped entries. At tick 40732171,
Right is routed even though L1 is held/disarmed; the next poll masks it and
emits its up edge. Additional Triangle/Square one-poll leaks appear. The new
filter finishes masking before deleting released entries.

The log has 141 slow-poll records (>30 ms), maximum 125 ms; native sends often
sit 15–16 ms apart. The existing default SendEvent key delay plausibly contributes
to those multiples; workload, scheduler, file I/O and Lua/game delivery are not
separated by this capture. No global key-delay/poll-rate/device-threshold tuning
or complete desktop-stickiness resolution is claimed.

## Implemented behavior

Retry a missing lease scan once without Sleep. Require a complete END trailer.
An armed session seeing unknown pauses NEW downs for up to 100 ms from its last
valid observation. Existing physical transport releases pass; no cached lease
authorizes a new action. Valid current context resumes the previous gesture.
Actual stale/menu/focus/token changes still cancel and require neutral. Lease
files still use the existing Windows remove/rename swap; the reader now handles
its short uncertain interval without treating it as a lost session.

Independent R2/R3 targeting experiments default off. Their guards use the valid
current gameplay token, hardware edge and absence of other inputs/owned native
keys/physical keyboard modifiers. Plain F8 is released before continuing R2 or
click handling, using the existing native sender delay with no extra Sleep.
Two added sends may add roughly 30 ms on this traced system; live feel and target
processing order remain tests. R2/R3 hard/light trigger distinctions are not added.

Status parsing now accepts digit-bearing keys (l1_ready, target_r2/target_r3).
Trace headers identify the wrapper version; pause/prefire transitions are logged.
All Test 3 momentary layers, Main display alias and compact geometry remain.

## Verification performed here

82 local Lua sources parse under the documented Lua 5.4 normalization fallback.
Actual command/default/lease/root bridge, bank/mailbox/view, Save Only, catalog/
XML/lock, profile/default and switch-destination/menu-resource tests pass.
33 pure-AHK gesture/source-routing scenarios pass via narrow JS translation.
Actual PersonalFilter and PersonalTargetTrial functions also run under a narrow
translation with an AHK-style mutation-sensitive enumerator: adjacent held-key
masking, R2/R3 ordered F8 edges, fresh-press/default-off and context/combo/physical
modifier guards pass. Source integration verifies pause emits no new downs and
does not reset the gesture; 100 ms expiry and actual invalid-context guards pass.
Six AHK lexical/include/function-link checks, lifecycle and trace-helper checks
pass. Native AHK parsing/Windows key delivery and real FFXI acceptance are pending.

## Bindings companion and delivery register

Separate XIVCrossbar-Franklet-Lionstag-Bindings-Test1.zip uses the latest supplied
ALL-JOBS-DEFAULT(3).xml (October 15) and CustomActions.xml (October 14). Cioara's
original bar and the uploaded catalog are retained unchanged as references.
Franklet/Lionstag copies remove exactly the four L2 D-pad nodes and nothing else.
A matched 34-record catalog reconciles 16 linked field differences visible in
the newer bar, preventing the older catalog from rolling those actions back.
All original IDs remain. Suggested actions/layouts remain optional, separate
from the copied bar. XML/semantic/link checks pass; native dependency execution
remains pending. Existing newer global catalogs should be merged, not overwritten.

The complete Test4 installer contains no user binding/catalog/settings data.
Shared WORKFLOW was re-read at the unchanged bc17a173 blob; documents stay inside
the addon folder. Personal source is committed/pushed on its development branch;
public and TrustMovement runtime remain unchanged. Exact commits are generated
into package headers. Historical records below are preserved.

---

# Personal 9 L1 Test 3 — October 16, 2026 (America/Chicago)

Author A. Branch personal/ps5extended. Baseline published Test 2:
c5aa53c8d9b72adf5b14bdec76ce47d3cff477d5. The package header identifies exact
delivery commits. Runtime personal9-l1test3; wrapper Controls=9.2-layers.

## Install and first live checks — pending

1. Stop the wrapper and unload all clients; back up the personal installation.
   Install complete xivcrossbar/ and restore its data/, config.ini and custom
   icons. Unchanged TrustMovement 0.1.1 is included alongside it; retain existing
   settings/quiet overlays and AddonManager loading. No user state is shipped.
2. Start with neutral controls. Check personal9-l1test3 / Controls=9.2-layers.
   Restarting Lua alone cannot update the running AHK script.
3. Tap/release L1 several times: exactly one shortcut companion appears only
   while held; no mode changes, client switching or release action.
4. Hold L1, add L2: one action companion replaces it at the same location.
   Existing bank entries persist. Test //xb l1 1 Test input /echo L1-bank,
   then L1, L2, Left: exactly one echo per fresh Left press; empty slots no-op.
5. Release L2 while holding L1: shortcut companion returns. Hold a face/direction
   through this transition: no new action until released and pressed again.
   Release L1 first instead: hide and consume remaining L2 until released.
6. L2 first, then L1: ordinary L2 crossbar remains. Release L2 while holding
   L1: shortcut companion appears. Same-poll L1/L2 favors ordinary L2. Recheck all
   six ordinary L2/R2 bars, including the normal dual-trigger and double presses.
7. L1+L2 and R1+R2 no longer hold native Ctrl/Alt. R1+R2 keeps ordinary R2.
   Individual L1 Ctrl shortcuts still work. Recheck R1 arrows/Cross Enter/Circle
   Escape/Triangle Ctrl+NumpadPlus; bare R1 F8; L1+R1 Tab; PS/touch/L3/R3/zoom.
   R3 F8 on press + R on release is NOT installed; it conflicts with zoom onset.
8. Confirm main compact and companion slots/icons have equal size and spacing at
   main scales .5/1/1.5. //xb l1 scale crossbar follows it; numeric .8 opts out.
   Drag unlocked preview, lock, reload, resetpos; verify both layers share position.
9. Basic displays as Main in chooser, binder title and switch destinations.
   Switch Main -> Default/All Jobs Default -> Main through existing bound slots.
   Saved key remains basic, with unchanged fallback/XML/SMN return semantics.
10. Switch clients, enter menus/chat/cutscenes, disconnect/reconnect and restart
    mid-chord. New personal action requires neutral; no held-slot replay. Preserve
    TrustMovement's existing one-signal-per-newly-piloted-client behavior.
11. Recheck Save Only return, scoped catalog edits and ordinary confirm/cancel.
    Holding L1 consumes Circle by design (reserved shortcut or bank slot);
    bare Circle routes through Lua, whereas R1+Circle sends AHK Escape directly.

## Available verification

80 Lua sources parsed via temporary Windower syntax normalization under Lua 5.4.
No Lua 5.1/luajit/luacheck executable is available here; this is not native Lua
5.1-aware verification. Actual bank/mailbox/root bridge tests cover ordered
layers, same-session ordinary-trigger transitions, once-only actions, retired
toggle rejection, preserved assignments and menu/chat/focus/cutscene/stall guards.
Actual main coordinate methods verify matching compact coordinates/40px icons;
42 fixed companion surfaces, scale following, 24 resolution/scale clamps, 300
hide/reveal cycles, render cache invalidation and teardown pass. Actual binder
tests verify Main display with basic key round trips and Save Only behavior.
Existing catalogs/XML/locks/defaults/profile/menu-resource regressions pass.

32 actual pure-AHK gesture/source-routing scenarios pass through narrow JS
translation, including both press/release orders, simultaneous samples, L2 tail,
R2 priority and unchanged touch/zoom/focus behavior. Six AHK files pass lexical,
include and function-link checks; shared lifecycle and trace-helper simulations
pass. These do NOT establish Windows timer/file/key delivery or in-game rendering.
No debounce, native key-delay, controller threshold or poll interval was changed.

## Evidence, choices and delivery register

The user requested momentary layers, same-location L1+L2 reveal, main compact
dimensions, Main naming without functional changes, input-route clarification,
and review of the current NPCMirror WORKFLOW. The shared workflow was read at
Git blob bc17a173c779a7b921aed1d4bf8c539368aa3730; it and the AGENTS entry point
were adopted, with TESTING/WORKFLOW now inside xivcrossbar/ in test ZIPs.

Existing L1 shortcut mappings form the first layer; existing saved bank entries
form the second. This is the stated interpretation, not a newly specified
inventory/R1 schema. Bare R1 and R3 retain their prior roles. R2 targeting pulses,
R1 replacement bank, Sack/Wardrobe remapping and other addons remain proposals.

The reported severe stickiness on Frank's PC remains unresolved. No current
controller-input-trace.log was attached or resolved by exact filename search in
this request. Do not describe an older transport log as this new capture. Compare
ps5 and x with the same sequence; use //xb controller trace on/off, then share
data/controller-input-trace.log plus the failed physical gesture. New captures
include layer transitions. This patch removes old modifier latches and toggle
rearming intentionally; it is not a proven fix for general sticky input.

Complete delivery: XIVCrossbar-Personal9-L1-Test3-Complete.zip. Source is committed
and published on the personal development branch; exact commits appear in the
generated package header. Public branch and TrustMovement receiver unchanged.
Earlier records below are preserved; their current/pending language is historical.

---

# Personal 9 L1 Test 2 — October 16, 2026

Author A. Branch personal/ps5extended. Baseline published L1 commit
69b9fe12c42b5d026dec83553f37a6117f87fdba. Exact new delivery commits are in the
package header. Runtime personal9-l1test2; wrapper Controls=9.1-diag.

## Scope and live evidence

User confirms L1+Left/echo and switching work well; likes the layout. Frank's PC
still has controller stickiness severe enough to hurt play. Cause unresolved.
Save Only was already in Personal9 Test 1, committed separately at b923133.
This update adds x -> ps5-extended (old aliases retained), tighter companion
geometry and actual theme slot backgrounds/frames around PS symbols, plus
opt-in wrapper diagnosis. Static companion rendering is cached while retaining
fade/drag/label invalidation. Existing mode switching, actions, modifier-pair orders,
key emissions, thresholds and native behavior are retained. Public unchanged.

## Install and compare

1. Stop wrapper and unload all clients; back up the personal folder. Install
   complete xivcrossbar/, restore data/config.ini/icons. TrustMovement 0.1.1 is
   included unchanged alongside it and stays managed by AddonManager. No user
   settings, bindings, catalogs or diagnostic files are distributed.
2. Restart with neutral controls. Check personal9-l1test2 and Controls=9.1-diag.
   A Lua-only reload does not replace the running wrapper.
3. Use the same focused client: //xb controller profile ps5. Wait until
   //xb controller status shows the running base PS5 profile. Test bare D-pad
   taps/holds, each face button and normal L2/R2 actions under the usual client load.
4. //xb controller trace on; reproduce for 15-30 seconds, then off or let the
   wrapper auto-stop after 30 seconds. Records are buffered until stop/expiry/size
   limit in xivcrossbar/data/controller-input-trace.log. Trace overhead can affect
   timing. No chat text is captured. Keep traces short and repeatable.
5. //xb controller profile x. Confirm selected/running PS5 Extended, then repeat
   the same test/trace. The log appends labeled captures, including their profile.
   ps5 is our common reader WITHOUT personal controls; x adds the personal layer.
   This does not compare our entire wrapper to the untouched upstream AHK script.
6. Share which profile sticks, whether bare D-pad vs R1 arrows differ, and the
   trace/status. If x alone sticks, inspect personal handling/context leases first.
   If both stick, inspect common transport/Lua/native duplicate input/driver/client
   timing next. Neither result proves a root cause by itself.

## Diagnostic meaning

raw/routed masks order: Up Right Down Left Cross Square Circle Triangle Share
Options L2 R2. Trace records POV, personal context/rearm, base output edges and
owned personal key transitions, plus slow polls (>30ms) and lease failures.
Status records lifetime max poll gap, poll/read/personal-handler duration, lease
miss count and trace write-error flag. Maxima can include startup/focus stalls;
use correlated capture events, not one number alone. A lease miss counter counts
read attempts, not distinct hardware failures. Diagnostics do not debounce input,
change SendEvent delays, request higher timer resolution or claim an input fix.

## Verification

Lua 5.4 temporary-normalization fallback: deterministic new/old profile aliases,
actual trace-command guards/write failure, L1 bank/bridge/lease/root integration,
42 fixed UI surfaces, 24 scale/resolution clamps, 300 reveal/hide cycles, Save
Only plus catalog/XML/Windows-file/menu/default-destination regressions passed.
AHK lexical/include checks, 37 translated personal gesture/routing scenarios,
shared-client lifecycle and actual pure trace-helper simulations pass. Source
review confirms native SendEvent/ControlSend statements and ordering unchanged.
Font/asset geometry inspected in a local preview; not native Windower rendering.
Native AHK timer/file scheduling and Windows/FFXI live acceptance remain pending.

## Queued, not installed in this delivery

See PERSONAL for the newly agreed L2-then-L1 ordinary crossbar priority and
return-to-L1 reveal after releasing L2; possible one-layer L1/R1 references,
Ctrl/Alt schema choices, inventory cluster, R2 F8/combat submenus, and Basic's
possible Main display name. Shared's invisible fallback execution was reproduced
in review and is retained pending its intended role. It supplies no fallback to
other sets. No changes to Pathfinder/Sparks/NPCMirror belong to this controller ZIP.

Older cumulative records follow unchanged; their "current"/"pending" wording
applies to their dates. Test 1's live-pending statement is superseded only for
the user's confirmed L1 echo and switching observations, not all listed checks.

---

# Personal 9 L1 Test 1 — October 16, 2026

Author: A. Branch: personal/ps5extended. Baseline published checkpoint:
9375a66d75778744a865077e2f676458688fc65a. Save Only was committed separately at
b923133046eaf8b2e3a73ffc57f8a4ebe2dfb19b. Package-generated header identifies the
exact subsequent L1 source commit. Runtime: personal9-l1test1; Controls=9.0-l1.

## Install — complete personal build, not a public update

1. Stop //xb controller stop. Unload XIVCrossbar on every client. Back up the
   personal addon directory, including data/, config.ini and custom icons.
2. Install this complete xivcrossbar/ folder; restore your personal state.
   There are no shipped settings, catalogs, binds, leases or controller choices.
   Do not mix with public RC3 or run two wrapper processes/variants on one PC.
3. The ZIP also contains trustmovement/ (unchanged v0.1.1 receiver). Install it
   alongside xivcrossbar if needed, preserving its data. Keep AddonManager in
   charge of loading it. No old wrapper or Trust quiet-patch overlays ship.
4. Load XIVCrossbar with all buttons/sticks neutral. Select ps5extended if needed.
   Check //xb status -> personal9-l1test1; //xb controller status -> Controls=9.0-l1.
   An older wrapper requires stop/start; Lua restart alone is insufficient.

## First live checks — all pending

- Start with //xb l1 status and //xb l1 preview. Default mode is keyboard. Hold
  L1: a reference appears. Release an unused L1: bank mode appears persistently;
  release another unused tap: keyboard mode, then reference fade. No client switch.
- Assign harmless test slots: //xb l1 1 Left input /echo L1-left and
  //xb l1 6 Cross input /echo L1-cross. In bank mode L1+Left and L1+Cross each
  dispatch once, never repeat while held. Empty slots do nothing. Bare Cross/
  D-pad still perform normal gameplay. Test every slot against its printed number.
- Release button then L1, and L1 then button. Neither combination toggles mode.
  Held buttons from before L1 must not execute. A tap immediately followed by a
  chord must wait for mode acknowledgment and neutral, never use the old mode.
- Recheck Ctrl+I/E/J/M, Ctrl+Q/Space/S and reserved Circle in keyboard mode;
  L1+R1 Tab; L1+L2 Ctrl and R1+R2 Alt including either release order; R1 arrows,
  face shortcuts/F8; PS/touchpad/L3/R3; all six L2/R2 crossbar activations.
- Hold a chord while switching clients, opening/closing menus, typing, zoning,
  reconnecting and restarting the wrapper. Require neutral before fresh personal
  gestures. No action may occur merely when a context becomes eligible.
- //xb l1 append 6 input /echo second; test the chain. Clear a slot; reload;
  assignments/mode persist separately on two characters. No job/set change should
  overwrite the bank. //xb l1 unlock permits visible-panel dragging; lock stops it.
  Test scale 0.4/0.8/1/2 and resetpos at 960x540, 1280x720, 1600x900 and 4K.
- //xb status reports L1 receive/reject/ack counters; wrapper status file reports
  l1_mode/l1_ready/l1_sent/l1_ack. Match sender vs receiver before changing timing.
- Save/edit/rename a custom action on a later page, including matching Global/
  Character names. Save Only returns to that record; a failed save retains the
  draft. Save & Bind and mid-draft set changes retain their previous behavior.
- Verify TrustMovement follow/assist takeover unchanged; //tm test first if needed.

## Verification performed here

Simulated using the available Lua 5.4 library with temporary normalization of
inherited Windower string syntax (NOT native Lua 5.1/FFXI): bank commands/modes,
empty/held-only execution, quote preservation, persisted state, sequenced mailbox
duplicate/partial/CRLF/stale rejection, actual root bridge mode/focus/menu/trigger/
cutscene/stall invalidation, complete context leases and failure cleanup; 26
fixed companion surfaces, 24 scale/resolution layouts and 300 hide/reveal cycles;
actual binder Save Only selection/rename/scopes/pages/failure/Save & Bind.

Regression fixtures: personal defaults, merged catalog editing and XML snapshots,
Windows file rollback/lock ownership, menu resource/pagination cleanup and Default
destination round trips. AHK lexical/include checks and 37 translated pure
gesture/source-routing scenarios pass; shared-wrapper lifecycle simulation passes.
Native AHK SendEvent/file scheduling and in-game visuals remain live tests.

## Implemented vs deferred

Implemented: two modes, one eight-slot command bank, saved independent companion
position/scale/lock, keyboard reference fade, bank persistence, help/status and
token/ack/neutral guards; Save Only return. New settings merge via Windower config.
Deferred: multiple banks, graphical/catalog bank binding, arbitrary button banks,
extra bank autohide overrides and new art/sounds. Current keyboard/native-pair
behavior is deliberately preserved. L1 no longer switches clients by itself.
Unresolved: general sticky/doubling input, cutscene reveal and process-wide crash
cause. Complete lease publication does not establish a fix for those reports.

The historical cumulative records below remain unchanged except explicit dated
superseding notes. Older "pending" statements refer to their own checkpoints.

---

# Personal RC3 — Save Only catalog return (October 16, 2026)

Implemented on personal/ps5extended by A: successful Save Only / Save Changes
returns to the editable catalog picker with the committed record selected,
including renamed records and Global/Character records sharing a name or ID.
Selection is located on the correct page. Failed saves keep the draft; Save &
Bind retains its button-assignment flow. New actions saved without binding also
return to the picker. No controller or main-bar behavior belongs to this change.

Simulated: tests/save_only.lua exercises the actual binder/selector with later
pages, rename, two catalog scopes, a failed save and Save & Bind. Existing menu
resource tests also pass. Native FFXI acceptance remains pending. Cumulative
records and original installation provenance follow unchanged.

---

Complete installation; branch: personal/ps5extended
Local source commit: 7967e84a209b9f2a596a04357743c6a85ccc3ddc
Published source commit: 9375a66d75778744a865077e2f676458688fc65a
Git tree: c1fb5a71dd9ff9932c7711d87519cccc3b028908

# Complete installation + conversation handoff — October 15, 2026

Variant: **NEW RC3-based personal**. This delivery packages all currently implemented
runtime code and required images/themes. Pending ideas are documented, not
implemented. The runtime version remains unchanged.

Start with `xivcrossbar/docs/HANDOFF-PERSONAL-RC3.md` and the shared
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

User confirms reciprocal Default-bar switching works. TrustMovement remains
in AddonManager; no auto-loader requested. The input report includes delayed/
missed presses, nonresponsiveness and D-pad doubling sensation; no root cause
is established. Cutscene reveal still fails in some scenes. Bare L1 is still
client switching in this runtime; its two-bank mode toggle is pending. Prioritize
input/context communication, cutscene access and Save Only catalog return before
new L1/visibility/icon/palette work. Preserve the movement hook.

Additional conversation retrieval did not recover the other threads. This
handoff uses visible discussion, current source, recovered archives and cumulative
records; gaps and historical-only claims are identified. Documentation checks
verify current roles/defaults/commands and preserved branch separation. No new
Windows/FFXI acceptance is implied.

---

# Personal 8 sets checkpoint 1 — cumulative controls, stable login and Default destinations

Runtime: `0.4.0-a.20261014.personal8-sets1`. Shared wrapper Controls=8.1;
UI cleanup helper remains cleanup6. Includes Controls1 (local 0b57621), supplied
movement baseline dc4cbae, and Login1 (local 90dd1d7). ZIP header records the final
source and published commit. No L1 bank/companion/double-tap modes in this batch.

Install: stop the shared wrapper with `//xb controller stop`, unload XIVCrossbar
on participating clients, copy the ZIP's xivcrossbar contents over the install,
then load it on each client. Wrapper starts normally; if needed use
`//xb controller start`. Stop/start is necessary for new AHK code. Existing data,
XML/INI, bindings, catalogs, images and local preferences are not distributed.
Cumulative update includes Cleanup6 and the supplied movement_signal.ahk bridge.
Rollback restores dc4cbae (Cleanup6 plus the user's movement-enabled wrapper).

## Switch destination changes

Switch Crossbars and Quick XB Switch now include Default, Job Default and All
Jobs Default. These three are grouped first, followed by other destinations in
label order. Labels remain presentation; commands/store use actual internal keys.
Renaming All Jobs Default to Universal still binds `xb bar all-jobs-default`;
renaming an all-warps set to Warps still binds `xb bar all-warps`. Quick switches
store the same stable key and preserve their one-action return behavior.
The destination icon path now includes images/. Selecting another action after
Back clears previous optional alias/command/icon metadata, so a destination's
label or command cannot follow the user into a newly selected spell.

A simulated test exercises the real binder, root set_hotkey, root switch command
and player execute/dispatch methods, with only I/O and construction mocked:
Default entries present; renamed labels preserved; Basic -> All Jobs Default ->
Basic using the same physical slot; Quick Switch returns after one action; all
Default/custom destinations use keys; changing choices clears obsolete metadata.
No user XML was read or written in these tests.

## Acceptance order

1. Controls/version: `//xb status` reports personal8-sets1;
   `//xb controller status` reports Controls=8.1. L1+Up/Down/Left/Right sends
   Ctrl+I/E/J/M; Cross/Triangle/Square Ctrl+Space/S/Q. Empty L1 combinations
   stay reserved. R1 arrows are plain; existing direct face shortcuts remain.
2. L1+R1 sends one Tab. Bare L1 release switches next client without a delay;
   combinations never switch. Double taps have no separate action. Bare R1 is
   still F8. PS press toggles recent non-FFXI app/last FFXI client; holding adds
   nothing. Touchpad peek and ordered click zoom retain prior behavior.
3. L1+L2 holds Ctrl immediately; R1+R2 holds Alt immediately. Release either
   first: modifier stays until both release. Native arrows work without firing
   crossbar slots. Focus loss, disconnect, text/setup/menu or wrapper shutdown
   clears owned keys; new input requires release before rearming. A deliberate
   Ctrl pair may show native macro UI; ordinary Apps crossbars remain unchanged.
4. D-pad: roll corners slowly. Each diagonal retains one adjacent direction,
   with no neutral gap and never two crossbar slots. If sticky input persists,
   distinguish bare D-pad from R1/native-pair arrows and collect inputtrace;
   the original session's whole symptom has not been diagnosed.
5. Movement takeover remains once per newly piloted FFXI client, not per stick
   recenter or desktop trip. Check another client after unloading/reloading one.
6. Stable login: load before entering world; controller confirm/cancel remains
   available. Fenrir bindings load without manual reload or new Asura profiles.
   Logout/login another character; verify its proper folder. Existing Asura
   directories are left untouched. A late corrected identity reloads cleanly.
7. Switch Crossbars: bind All Jobs Default in Basic, then Basic in All Jobs
   Default at the same button combination. Toggle both directions. Repeat with
   Default/Job Default if useful. Quick XB Switch should return after one action.
8. Cleanup6 checks still apply: later-page Shellra II target choices appear;
   Back preserves spell/page; editing then opening Options has no disposed-object
   errors; reload has no cursor hide error; live UI counts settle after cycles.

Available verification passed: 88 Lua sources parse with the Lua5.4 compatibility
fallback; actual-menu/paging/lifecycle, 108 compact layouts, catalog/XML identity,
profile migration, status/logout, stable profile observer, destinations, targets,
pre-login routing and client registrations. 33 actual pure-AHK gesture/routing
scenarios pass via the narrow JS translation; lifecycle policy tests and six AHK
lexical/include/link checks pass. Native AHK parsing, Windows key delivery and
FFXI gameplay/renderer acceptance remain live checks.

## Public candidate review

No public files/branch were changed. The archived public rollback source lacks
instant compact switching, the stable gate and current resource ownership helper,
and still uses stroke_transparency in UI/binder. Those are targeted port candidates,
as are corrected later-page selection and Default destinations after live testing.
The named public/rc3-snapshot remote ref was not available through the connector,
so this is an archived-source review, not verification of a current remote branch.
Personal controls/movement/companion experiments stay separate. Saving edits back
to the catalog list, icon organization and the future L1 bank remain on the backlog.
No native crash cause/resolution has been established by this batch.

---

# Personal 8 login checkpoint 1 — recovered stable world/server gate

Runtime personal8-login1, including Controls1 and Cleanup6. Restores the earlier
Batch19 profile_gate.lua behavior, with character ID also rechecked immediately
before initialization. Gate requires a known server, logged-in valid zone, and
matching player/entity name/ID stable for 0.75 seconds. Observe every 250ms even
after ready; a later stable correction performs one normal Lua reload into the
correct server profile. The wrapper/process registration starts before this gate,
so lobby controller input remains available. No hardcoded Fenrir/Asura exception.

Do not delete or copy old Asura directories automatically. The fix chooses the
current profile and leaves historical user files untouched. If the identity shifts
between observation and setup, no character storage is initialized and observation
retries. A malformed hotbar load does not start a repeated UI initialization loop;
a user reload can retry after fixing the file.

Simulated real-observer checks passed: logged-out lobby, missing zone, mismatched
entity, changing tuples, settling, real Asura, late server correction, changed
character ID and transient setup invalidation. Profile migration/appearance,
pre-login keyboard routing, root status/logout and client registration checks
passed. 86 Lua sources parse with the documented Lua5.4 fallback; native timing
and server values remain live checks.

Live: load at character selection, use controller confirm/cancel normally, log
into Fenrir and check `//xb status` selects Fenrir/<character> without a manual
reload. A fresh character must not gain an Asura folder from lobby state. Existing
bindings should load. Logout/relogin another character and check again. Late
correction deliberately restarts Lua for clean drawing-resource reconstruction.

Default switch destinations are next; no personal-control changes in this commit.

---

# Personal 8 controls checkpoint 1 — keyboard shortcuts, focus toggle and native pairs

Runtime personal8-controls1; wrapper personal_version=8.1. Baseline dc4cbae
preserves the uploaded movement-aware wrapper. No data/settings/INI/catalog/binding
files are shipped. Rollback code targets dc4cbae (Cleanup6 plus the supplied movement wrapper).
Stop the shared wrapper, unload participating XIVCrossbar
clients, copy the update, then load on each client. A running AHK script does not
reload when Lua alone reloads. Check `//xb controller status` reports Controls=8.1.

User's updated order: controls and PS first; stable server gate and Default switch
destinations next; L1 companion/double-tap modes deferred. Down was listed twice
in the proposal; as discussed, Right maps Ctrl+M, Down Ctrl+E. Fresh L1 key combos
send the requested Ctrl+letter; L1 release switches next client immediately.
PS toggles focus on a press, with no hold/minimize or client cycle. R1 retains bare
F8 and direct Triangle/Circle/Cross shortcuts, now plain D-pad arrows. L1+R1 is
Tab; L1+touchpad Tab/F15 is removed. Full current table is in PERSONAL.md.

L1+L2 begins Ctrl immediately; R1+R2 begins Alt immediately. Each remains until
BOTH members release, except focus/disconnect/menu/text/setup cancellation. Native
pairs preempt transport: release Apps/F-keys, mask trigger/face signals, send native
arrows, and never fire ordinary crossbar slots. Existing crossbars outside these
pairs retain priority. Empty L1 combinations are consumed. No companion is loaded.

D-pad observation: AHK polls at 10ms; it does not wait for stick movement. The
old DirectInput reader recognized cardinal POV values only. Diagonal rolls
looked neutral. Retain ONE adjacent cardinal through diagonal readings, preventing
both gaps and two slots firing at once. This source defect is confirmed; the
reported overall stickiness is not reproduced in a native client. File/context
reads and game input may also affect timing; no speculative broad tuning is made.

Available verification: 33 decision/routing scenarios exercise actual pure AHK
functions through the existing narrow JS translation, including pair release
orders, focus cancellation, touch/click behavior, repeated singles, requested key
mapping, Apps-release ordering and diagonal decoding. Six AHK files pass lexical,
include and function-link checks. Lua checks below cover unchanged crossbar/menu
behavior. These are not native AHK parsing, SendEvent or FFXI acceptance tests.

Live checks, first with a single client:
1. L1 + Up/Down/Left/Right opens intended Ctrl+I/E/J/M menus. Cross/triangle/square
   send Ctrl+Space/S/Q once. Reserved Circle/touchpad/clicks/PS/Mute send nothing.
2. R1 D-pad moves menus with plain arrows. R1 Circle/Cross operate Trust menus;
   Triangle sends Ctrl+Numpad Plus. L1+R1 sends one Tab in either press order.
3. L1+L2 shows native Ctrl behavior immediately. Release either first: Ctrl stays;
   release both: it stops. Repeat R1+R2/Alt. D-pad performs modified navigation
   without crossbar actions. With both pairs held, both modifiers are intentional.
4. Enter an addon menu, change focus, unplug/replug or stop the wrapper during a
   native pair: no stuck modifier/arrows or fresh action on regain. Return neutral.
5. Hold ordinary L2/R2 without shoulder pairs and use all bar types: unchanged
   execution with no F-key targeting leak. Slowly roll D-pad corners: no dropped
   neutral beat and never two slots from one diagonal.
6. Two clients: L1 tap advances once on release; combos never switch. PS press
   goes to recent non-FFXI app; next press restores last client. Holding PS adds
   nothing. No double-tap special action. Existing movement takeover still fires
   once per client takeover, not every stick recenter or trip to another app.
7. Touchpad peek and ordered stick clicks remain functional. Catalog/menu/page
   Cleanup6 fixes remain installed and `//xb resources` remains bounded.

Stable server gate and Default switch destinations are not yet changed in this
checkpoint. Public candidate is untouched. Current packages will not include
controller settings or command catalogs to avoid overwriting live choices.

---

# Personal 8 baseline — preserve supplied movement takeover integration

The Oct 15 uploaded snapshot's ffxi_directinput.ahk and movement_signal.ahk are
now tracked verbatim (line endings normalized), before changing personal inputs.
This preserves the user-tested TrustMovement bridge, axis observations, per-client
focus latch, release handling and status fields. It does not change TrustMovement
or its commands. Runtime remains Personal7 Cleanup6. AHK include/link checks pass;
no native Windows execution is claimed. This baseline records the user's actual
wrapper for rollback, not the older wrapper without the movement integration.

Next, per the user's revised order: personal keyboard controls and PS focus toggle,
then the recovered stable server gate and Default switch destinations. L1 companion
and double-tap modes are deferred; the public release snapshot remains unchanged.

---

# Personal 7 cleanup checkpoint 6 — paged spell targets and remaining cleanup calls

Runtime: `0.4.0-a.20261014.personal7-cleanup6`; `//xb resources` helper cleanup6.
The ZIP header identifies the final local/GitHub source commits. Includes
checkpoint 5 (local 94b07ab, GitHub 0af3680e6f22cfc976ba2b61674f41ab6f4e2ff3).

This patch targets the user's uploaded Oct 15 Cleanup4 snapshot. All its runtime
Lua files match the baseline; its movement-enabled AHK wrapper is preserved.
Only Lua plus README/WORKFLOW/TESTING documentation and Lua rollback files are
packaged. No images, data, XML, INI, bindings, catalogs or controller scripts.

Shellra II report: selecting the spell on page two produced only Previous Page;
pressing it revealed the target choices, then binding succeeded. Reproduced in
real binder methods with a multi-page spell fixture: display_options reused page
two/three for a shorter target list that had only one page. Clamp the displayed
page to the new list's page count. Valid page turns and explicitly restored Back
pages remain intact. No target rules or saved action commands changed.

The simulation failed with "spell page leaked into target selection" before the
fix. Afterward, all 12 page-two/page-three -> target -> binding -> Back -> save
scenarios pass across 960x540, 1280x720, 1600x900, 1920x1080, 2560x1440 and
3840x2160. The save callback receives ma / Shellra II / me at the requested slot.
These are fixture-based Lua tests, not real FFXI resource, rendering or gameplay
tests. 200 prior menu cycles, 150 typed updates, 100 footer redraws, Options with
live/replaced/deleted inline fields, cursor unload, repeated crossbar/chooser
setup, status, fade, compact, catalog and target ordering checks also passed.
84 Lua sources parse with the documented Lua 5.4 compatibility fallback.

Live checklist:
1. `//lua u xivcrossbar`, overlay the ZIP's xivcrossbar contents onto the installed
   addon, then `//lua l xivcrossbar`. Leave installed data and AHK files intact.
   No wrapper restart needed. `//xb status` ends personal7-cleanup6 and
   `//xb resources` reports helper cleanup6.
2. White Magic -> page two -> Shellra II: target choices should show immediately,
   without a blank intermediate page. Bind and execute normally.
3. Repeat, using Circle to go Back from binding to targets to the spell list.
   The previous spell/page remains selected. Try another later-page action.
4. Edit a custom-action field, confirm, open/close Options and change crossbars;
   repeat while the inline field is active. No text.alpha errors; draft retained.
5. Reload one client while another remains loaded. No image.hide unload error;
   other client's controls and movement integration continue normally.
6. Compare `//xb resources` from the same closed-menu state before/after several
   cycles. Live counts should settle at the same baseline; totals increase.

The log's TrustMovement XML, Repeater type comparison, Logger and Battle Stations
errors belong to other addons and remain separate observations, not fixes here.
This patch fixes reproduced Lua calls; it does not prove a cause or resolution
for the earlier native d3d8.dll crashes.

---

# Personal 7 cleanup checkpoint 5 — stale review references and cursor unload

Runtime: `0.4.0-a.20261014.personal7-cleanup5`; `//xb resources` helper cleanup5.
Source checkpoint is recorded in the delivered ZIP header.

User materials: xivcrossbar-snapshot-10-15-2026.zip and console(20261015-133537).log.
Every tracked runtime Lua file in the snapshot matches Cleanup4 (ignoring line
endings). The DirectInput wrapper differs and includes the separately developed
movement_signal.ahk integration. Neither file is changed or packaged here.
The snapshot's installed data/settings/catalogs remain evidence, never runtime
patch payload.

The console confirms Cleanup4 loaded and records two additional lifecycle errors:
- resources.lua:28, UI object used after disposal: text.alpha (including 07:55:37
  and 08:27:23/27): Options suspends the old inline-entry caption after returning
  to a freshly drawn review. It was destroyed with the previous hints, but its
  secondary reference remained. Clear that reference when rebuilding/resetting;
  skip disposed objects when dimming/restoring an Options overlay.
- resources.lua:28, UI object used after disposal: image.hide (including 07:16:22
  unloads): root cleanup may delete cursor images before the selector's unload
  callback. Cursor destruction now deletes idempotently without hiding already
  deleted frames first.

Both failures were reproduced in the strengthened real-menu regression before
fixing their callers. The registry's use-after-disposal assertion remains active;
these changes do not silence errors in unrelated paths. Options restoration also
handles a screen rebuilt while the overlay owns input.

Simulated checks passed: 200 review/edit/bind/back cycles, 150 typed updates,
100 footer redraws, Options following inline editing and replacement during the
overlay, both cursor cleanup orders, repeated crossbar/chooser rebuilds, status,
text fades and catalog integration. 84 Lua sources parsed under the Lua 5.4
fallback after temporary Windower syntax normalization. No native FFXI testing.

Other console messages are separate: TrustMovement reports malformed XML at
line 12 before later successful loads; Repeater reports a string/number comparison
at repeater.lua:210; Logger and Battle Stations also report unload-time errors.
None establishes a cause for XIVCrossbar's observed stale-object calls, and no
other addon is modified by this package.

Live checks:
1. Unload XIVCrossbar, overlay the matching xivcrossbar folder, then load it.
   Retain data, images, configuration and the movement-enabled controller wrapper.
2. Edit a custom-action field, confirm, open Options and select another crossbar;
   close Options. The review remains usable without text.alpha errors.
3. Repeat while still typing, cancel back to review and open Options again.
4. Reload on one client while another remains loaded. No image.hide unload error.
5. `//xb resources` live counts return to the same baseline after repeated cycles.

The separate page-two spell-to-target transition is still under investigation in
this checkpoint. No bindings, catalogs, settings, images or AHK files are included.

---

# Personal 7 cleanup checkpoint 4 — guarded object cleanup and build marker

Runtime: `0.4.0-a.20261014.personal7-cleanup4`. User reports the same numeric
destroy error and partial menu/background after checkpoint 3. Its delivered ZIP
was rechecked: it contains the ipairs correction; the new repeat is not yet
reproduced with that source. Active runtime/helper version remains unconfirmed.

Cleanup now reads raw indexed entries through the declared List length (or plain
array length), dispatching destroy only for registered owned objects. Numeric
metadata, stray numeric entries, foreign objects and already-disposed objects
cannot receive cleanup dispatch. It does not depend on the generic ipairs
iterator. `//xb resources` identifies the helper as cleanup4.

Checks passed: 200 review/edit/bind/back cycles using upstream Windower Lists,
150 typed updates, 100 footer redraws, repeated UI rebuilds, status, text fades,
slot cleanup, compact switching and catalog integration. All 84 Lua sources
parsed after temporary Windower syntax normalization under Lua 5.4. An additional
case includes an owned object, a numeric entry and a foreign object, with global
ipairs intentionally unavailable: only the owned object is deleted, once.
This is a simulated compatibility safeguard, not a reproduction of the user's
new failure in FFXI. All controller outputs remain unchanged.

Install while unloaded: `lua u xivcrossbar`, copy the contents of the ZIP's
xivcrossbar folder into the installed xivcrossbar folder, then
`lua l xivcrossbar`. Keep existing data. The cumulative patch includes no images,
settings, catalogs or bindings. No controller wrapper restart is needed.

First checks: `//xb status` ends in personal7-cleanup4; `//xb resources` reports
UI cleanup helper: cleanup4. Open/close the main menu, browse a list, then open
and close a custom-action review. If an exception remains, retain its full file/
line/message and these two version reports before changing more files.

---

# Personal 7 cleanup checkpoint 3 — Windower List compatibility

Runtime: `0.4.0-a.20261014.personal7-cleanup3`. Cumulative update includes
previous cleanup fixes. User reported partial menu rendering and
ui/resources.lua:40: destroy is not defined for numbers.

Confirmed cause: Windower List (`L{}`) stores a numeric `n` field alongside
indexed entries. Resource cleanup used pairs(), so it visited n and attempted
to destroy it, including for an empty List. Use ipairs() to clean actual
sequence entries only. Footer pruning now uses List.remove() so its explicit
count remains correct; table.remove() alone did not maintain List metadata.

Regression: tests now load a test-only snapshot of upstream Windower lists.lua
with real metadata, append/remove operations and range checks. The strengthened
menu test failed at resources.lua:40 before the fix. Afterward, 200 review/edit/
bind/back cycles, 150 typed updates and 100 repeated footer redraws pass without
retained native-style objects. Repeated setup, fade/disposal, status, compact
and catalog checks also pass. These remain simulated Lua checks, not live FFXI.
The earlier plain-array test double omitted this metadata and missed the bug.

Installation: unload XIVCrossbar, overlay the matching xivcrossbar runtime folder,
then `lua l xivcrossbar` (or `lua r xivcrossbar` if still loaded). AHK is unchanged
from the prior cleanup package; no wrapper restart is required for this fix.
No XML, INI, bindings, catalogs or images are included. Retain installed data.

Live checks:
1. `//xb status` reports personal7-cleanup3. Open/close main menu repeatedly.
   Options, background, cursor and selection should remain coherent; no
   resources.lua numeric destroy errors.
2. Browse custom actions/icons, edit a draft, bind/back/cancel and exit.
3. Check Delete Custom Action remains free of the unnecessary input band.
4. `//xb resources` in the same closed-menu state before/after should show
   stable live counts; created/deleted totals naturally increase.

Controller changes remain pending. Notes: L1 as Ctrl for inventory/other menu
shortcuts; PS tap minimize/restore rather than client cycling; remove the
L1+touchpad 500ms/F15 experiment. Shoulder double taps were reconsidered as
possible game-macro/crossbar modes, with behavior not yet settled. No companion
bar or controller-output changes in this correction. Icon/menu organization and
asset consolidation remain later work.

---

# Personal 7 cleanup checkpoint 2

Runtime: `0.4.0-a.20261014.personal7-cleanup2`. Includes checkpoint 1.
Crossbar and set-chooser reinitialization no longer discard their previous
text/image layers. Deferred geometry objects can be retired only once;
layer replacement flushes old deferred objects, and unload releases remaining
owned resources without touching any other addon's objects.

Additional simulated checks: 30 complete crossbar rebuilds and 20 chooser
rebuilds retain constant counts. Double destruction during a fade queues/deletes
once. Layer replacement, repeated shutdown and the subsequent fade tick do not
repeat deletion. Existing layout/fade tests remain applicable.

Live acceptance: compare `//xb resources` with menus closed before/after repeated
editing, browsing and Options; test job change and relogging in the same process;
check the fade, cursor, binding hints, draft overlay, compact toggle, and a normal
`lua r xivcrossbar`. A newly started client gives a clean baseline after an
existing shared-text failure. These patches cannot promise to restore an already
failing graphics/text renderer. Do not make several addon changes at once while
trying to establish which operation triggers another failure.

Other pending requests are unchanged: login identity/Asura folder selection,
default switch destinations, Save Changes returning to catalog, icon sorting,
personal menu ordering and asset consolidation. The current PS5 extended
controller mapping and cross-addon source review are at the top of PERSONAL.md.
The documentation checkpoint changes no controller outputs or addon defaults.
Optional evidence: `//xp debug refcount` and `//cbg diagnose` before/after the
same NPC interaction, alongside `//xb resources`. No other addon is patched.

---

# Personal 7 cleanup checkpoint 1

Runtime: `0.4.0-a.20261014.personal7-cleanup1`. Temporary native text/image
objects are explicitly released on screen replacement and actual close, including
selector rows, binding footer icons, repeated text-entry captions and mapper
screen objects. Hiding a draft under Options preserves it. Delete Custom Action
no longer shows the text-input background band. Add `//xb resources` for quiet,
manual same-state object-count comparisons. No user XML, INI or images in updates.

Evidence: Windower Lua master texts.lua and images.lua retain objects in strong
registries; hide only changes visibility, destroy removes the registration and
native primitive. Prior picker resets dropped fields without destroying them
and retained old image lists. This is a demonstrable leak independent of whether
it caused Cioara's native crash.

Simulated: 200 actual review/edit/bind/back cycles, 150 legacy typing updates and
10 menu setup rebuilds return to baseline using strong native-style registries.
108 layouts, slot/cost cleanup, text fades and root status/logout regressions
pass. These are Lua 5.4 fallback/mocked checks, not Windows/FFXI execution.

Live: stop editing if shared text disappears again. After a clean process start:
1. `//xb resources` with menu closed; record counts.
2. Open `//xb ca Bow`, edit command, review, Save & Bind, Circle back, Share exit;
   repeat several times, then compare closed-menu counts.
3. Browse several catalog/icon pages; close and compare again.
4. Open Options over a draft, switch sets, close Options: fields remain intact.
5. Delete confirmation has no blue input band; cancel without deleting.
6. Repeat normal NPCMirror/home-point interaction with Balloon/XIVParty loaded;
   note whether text survives. A normal native crash report remains useful.

The new cross-addon text loss occurred while NPCMirror interacted with a home
crystal. Balloon, XIVParty and console text were absent together. No new native
fault record yet. Preserve current binds; do not infer another d3d8 exception
without a new record. Asura identity, default switch destinations and Save Only
return navigation remain separate pending changes.

---

# Personal 6 Fix3 — preserve catalog tracking through XML reload

Runtime: `0.4.0-a.20261014.personal6-fix3`. While reviewing the supplied
catalog_* fields, the slot loader was found to parse these fields but discard
them in action_manager.build. Carry them into the rebuilt action so stable
identities and inherited-value snapshots survive reload. Native execution
fields and catalog editing behavior are unchanged.

A new regression executes the actual XML slot loader and action constructor:
load, catalog update/rename, preserve an overridden label, serialize the field
snapshot, load again, and retain the retired identity after same-name recreation.
It also exercises a plain sixth-bar SlowEnter action. These checks passed.

New user evidence (read-only): console(20261014-085359).log,
Cioara_2026.10.14(1).log and WHM-RDM - Copy.xml. User confirmed xb restart
preceded the game crash. Console reports Fix1, records the storage error and
successful unload/load pairs at 03:41 and 03:48, plus an addon startup sequence
at 03:45. The chatlog has Restarting followed by loaded sets and NPC dialogue.
Shared-client console entries cannot determine the exact crashed client; no
native faulting module/exception appears. Native crash cause remains unknown.
The valid XML retains 12 actions in Switch; no deleted-bind evidence in this copy.

A portable Fenrir four-character bundle moves those commands into All Jobs
Default for Cioara, Myrr, Clairvaux and Killala, plus the later R2-double-tap
Cross=se binding in the chatlog. These XMLs are a separate, explicitly requested
data bundle, never included in the runtime update. Existing ALL-JOBS-DEFAULT
files require backup/merge before replacement. The source upload is untouched.

The chatlog also shows the stop/follow-stop chain saved into Party - Trust
Toggle. This is a catalog edit, not a crash diagnosis. Preserve the uploaded
slot commands in the copies and flag that entry for user review.

Live checks: apply Fix3, verify status; bind a catalog action, reload hotbars and
Lua, then edit/rename the catalog action and confirm the same bound identity
updates while slot-specific overrides stay. Delete and reload: bound copy
remains usable. Use the Fenrir files only after preserving the previous defaults.

---

# Personal 6 Fix2 — six-bar fresh defaults

New settings now default to `Hotbar.Number=6`, with `AutoHideExtraBars=true`.
Existing saved bar-count choices stay intact. To enable six on an existing
character, set its `Hotbar/Number` to 6 in settings.xml, then load the addon.
The package does not contain settings, hotbars, catalogs or controller INIs.

Apply the cumulative Fix2 update over Personal 6/Fix1. Stop the wrapper and
unload the addon before copying its matching runtime files. A game restart is
not an installation requirement. Status now works and displays pending-login
storage clearly. The code rollback is Personal 5, not the known-broken initial
Personal 6 helpers. Images are unchanged and omitted from the update.

Available checks: actual root status/login/logout paths, fresh six-bar defaults,
preserved saved bar count, identity/catalog regressions and the existing 108
layout scenarios covering 2/4/6 bars, six resolutions and three scales passed.
These are simulated/static checks; FFXI native crash behavior is unverified.

1. After login, `//xb status`: Fix2, Fenrir/Cioara, registration true.
2. Confirm the new bindings made before the crash still exist in their XMLs.
   Do not restore backups automatically or replace a nonempty catalog.
3. With six configured and extra-bar autohide on, test ordinary L/R, ordered
   L+R/R+L, and double-tap L/R actions. Icons/menu placement stay coherent.
4. Record the exact reload command and current console.log if the FFXI process
   crashes again. Check Windows' crash record for faulting module/exception.
   The report in the next section describes a distinct, proven Lua scope bug;
   no causal link to the native crash has been established.

---

# Personal 6 Fix2 — status/storage scope

Runtime: `0.4.0-a.20261014.personal6-fix2`. User reported `//xb status`
raising `xivcrossbar.lua:1203: attempt to index global storage`, followed by
an FFXI process crash during addon reload after binding. The main file lacked
its own `storage` import; player.lua's local import did not export a global.
Fix the root import, including its pre-login/logout guards. Status now names
pending character login instead of an empty storage directory.

The new test executes the actual status branch, invalid-identity initializer
and logout callback using the root's import, with global storage absent.
These checks passed. Earlier injected-local fixtures did not detect the missing
root import; this test covers that integration boundary.

The native crash is not reproduced or attributed. A Lua scope error does not
by itself establish a cause for a native FFXI process crash. Keep the current
character XMLs/backups; no user data is shipped or automatically restored.
A fresh console.log after the crash, the exact reload command used, and the
Windows crash entry's faulting module/exception code would help distinguish
addon/runtime/graphics failures. Current attachments precede this incident.

Live checks: run `//xb status` after login; check storage Fenrir/Cioara and
registration true. Verify newly saved bindings remain present after one reload.
Confirm logout/pre-login input cleanup still completes. Native crash acceptance
remains pending; the patch must not be described as a confirmed crash fix.

---

# Personal 6 compatibility fix — checkpoint 2 (complete correction)

Runtime: `0.4.0-a.20261014.personal6-fix1`. Both reported startup errors are
addressed. Apply the update over Personal 6, preserving installed `data/` and
configuration. Stop the old wrapper, unload the addon on participating clients,
copy the matching Lua/AHK files, then load again. The update contains no user
XML/INI or images. A corrected complete install is also available.

1. Confirm the wrapper starts without the `Return` error, and the chatlog has
   no missing-`ffi` error. `//xb status` should report client registration true.
2. Create a disposable action, save, bind, edit and reload. Confirm global and
   private catalogs remain available and original bindings/settings survive.
3. From two clients, add different actions to the global catalog; both survive.
   Saving an outdated edit of the same entry should retain its draft.
4. Unload one client while another is minimized: controls remain working.
   Unload the last with `on_unload_killahk=true`: wrapper exits after its grace.
   Repeat with false and with `lua r xivcrossbar`/`//xb restart`.

The new helper uses stock Lua and LuaSocket, already used by the addon. A short
local port reservation serializes catalog writes without sending network data.
Windows replacement uses a complete temporary file, a retained `.pending`
revision, and rollback on publication failure. Readers can read that retained
revision during the brief rename gap. This is recoverable replacement, not a
claim of a single atomic filesystem operation. Owner file handles distinguish
live/minimized/pre-login sessions from stale registrations; AHK makes the native
Windows handle probe, not Lua.

Verification: 77 Lua sources parsed in the available Lua 5.4 fallback; 18 Lua
test groups passed, including stock-Lua dependency checks, lock contention,
Windows-style rename failures/recovery and owner lifetime with simulated I/O.
AHK lexical/integration checks, lifecycle decisions and 40 personal gesture
decisions passed. Native AHK/Windows handle probing and live FFXI acceptance
remain pending. The original FFI implementation below is historical and has
been replaced; Cioara's log proved it incompatible with Windower.

# Personal 6 compatibility fix — checkpoint 1

Cioara's native startup screenshot exposed an AHK v1 Files-loop brace error
that lexical delimiter checks missed. Put the opening brace on its own line
and add a regression guard. This checkpoint addresses the parser error only;
the separate missing-FFI error in the chatlog is the next checkpoint.
Native AHK execution remains a live check; this container cannot run it.

# Personal 6 — complete testing package and checkpoint 7

Runtime: `0.4.0-a.20261014.personal6`. Branch: `personal/ps5extended`. Package headers identify the exact source and published GitHub commit. Public RC3 is not modified.

## Install

1. Back up your installed `xivcrossbar` folder, including `data/` and `config.ini`.
2. Stop the old shared wrapper once with `//xb controller stop`, then unload XIVCrossbar on every participating client. Game clients can remain open.
3. Copy the package's `xivcrossbar/` contents over the addon folder, preserving your existing `data/` and `config.ini`. The complete package includes images/dependencies; it needs none of the interim patches. There is no binding XML, catalog XML, settings XML, or controller INI in any package.
4. Load with `lua l xivcrossbar`; confirm `//xb status` reports `personal6` and the expected server/character storage after login. Existing saved settings remain in force. A genuinely fresh installation uses personal defaults and controller setup.
5. The rollback folder restores Personal 5 code only; user catalogs/settings are retained. Read its instructions before restoring.

## Live checks, in order

1. Before character login, verify controller arrows/confirm/cancel work while no character/server folders are created. Log in and verify the reported storage directory and original crossbar sets. Transient missing identity retries; invalid XML stops writes.
2. OnInput: hold/release triggers during NPC dialogue/cutscenes. Explicit Hide still hides. Bind friendly/enemy actions and check `<t>` first where valid.
3. Put the same spell on multiple slots/bars; check MP dim/recovery, recast/warmup and normal feedback completion.
4. Confirm existing private actions plus global actions. `//xb catalog global` (default for new saves), `//xb catalog character`, `//xb catalog status`. Both sources remain listed; edits remain source-owned.
5. Bind a global action on Franklet and Lionstag; edit/rename it and execute both copies. Preserve a slot-specific alias/icon override. Delete, reload another job/client, then recreate the same name: existing copies retain their prior identity/last command.
6. On two clients, add different global actions from stale catalog views; both survive. Edit the same action in two drafts: the conflicting save keeps its draft. Confirm blank commands stay blank in XML, fallback execution works, and backups are made.
7. Unload one of two clients: the other's wrapper keeps working. Unload the last with `on_unload_killahk=true`: exit after about two seconds. False keeps the wrapper running. Repeat with a minimized/pre-login peer and `lua r xivcrossbar`/`//xb restart`.
8. Check current personal controls, bare Cross/Circle, normal F-key behavior, no native macro popup, Options chooser/draft preservation, item icons, compact/scale/drag/textfade. `//xb unload` is graceful; `//xb reload` only re-reads hotbars.

## Verification performed here

All 76 Lua sources parse after temporary normalization of inherited Windower string syntax, using the available Lua 5.4 fallback. Sixteen selected Lua regression groups passed, including the actual player catalog methods with mocked I/O. Rendering coverage remains 108 unique layouts across 960×540, 1280×720, 1600×900, 1920×1080, 2560×1440 and 3840×2160, three scales and 2/4/6 bars; 18 narrow indicator cases passed. Forty personal AHK gesture decisions and the actual AHK last-client decision policy passed through narrow test translations; five AHK files passed lexical/include checks.

These are simulated/static checks. Native AHK execution, Windows FFI locks/replacement/process queries and live FFXI behavior are not tested here. Treat Personal 6 as a testing build until those checks pass.

## Checkpoints

1. Storage identity guard — local `f6e538e`, GitHub `0c8c736`.
2. Per-slot dimming/feedback — local `a8d93b3`, GitHub `e1827d8`.
3. Cutscene/target choices — local `11d3c09`, GitHub `d190c48`.
4. Combined catalogs/coordinated saves — local `21a9310`, GitHub `5a82631`.
5. Binding identity/deletion snapshots — local `58f2937`, GitHub `fea0cbb`.
6. Last-client shutdown/shared help — local `1d4dde2`, GitHub `7441f61`.
7. Final review: login input, source-revision/ID safeguards, centered scope and complete packaging; exact commits are in this package's header.

## Retained backlog

L1 companion next round; icon catalog cleanup and personal main-menu ordering; mute probe; further target refinement and trust-state artwork; alternative gesture/menu ideas. The independent trigger-field fade remains dormant. The reported bind loss has not been reproduced or conclusively attributed; the previous ZIP audit found no shipped user XML/INIs. Preserve any affected XML/backups/logs for comparison.

---

# Personal 6 — checkpoint 6: last-client wrapper shutdown

Runtime: `0.4.0-a.20261014.personal6-6`. Apply after checkpoint 5. Update every participating client/install; stop the old wrapper once with `//xb controller stop`, then start the updated wrapper with `//xb controller start`. Lua reload alone leaves an already-running old wrapper unchanged.

1. Load before character login: wrapper and login controls should remain available; character XML must not be created early.
2. Load on Franklet and Lionstag. Unload Lionstag (`//xb unload` or `lua u xivcrossbar`): Franklet's controller must keep working.
3. Unload the last client with `on_unload_killahk=true`: wrapper should exit after about two seconds, releasing held input. With the last client's flag false, it should stay running.
4. Reload (`lua r xivcrossbar`) and `//xb restart` on one of two clients: controls should remain available on the other. Repeat a sole-client reload: fresh registration should cancel shutdown; setup/defaults/bindings must remain intact.
5. Keep another client minimized or at character selection; unloading the visible client must not stop its wrapper.
6. Launch a manual duplicate wrapper: the existing mutex should reject it. Explicit `//xb controller stop` still stops the shared wrapper irrespective of registered clients.
7. `//xb`, invalid commands and `//xb help` should show chat-only color-fragment help. `reload` re-reads bars; `restart` reloads the addon; `unload` fades/cleans up once.

Available verification: real Lua registration with simulated file APIs; actual AHK lifecycle decision function with simulated observations; lexical AHK/include checks. Native process enumeration, mutex concurrency, Windows replacements and live multi-client shutdown still require Windows/FFXI testing.

---

# Personal 6 — checkpoint 5: catalog edits update associated bindings

Runtime: `0.4.0-a.20261014.personal6-5`. Apply after checkpoint 4.

1. Bind a global custom action on two characters, edit its command/name on one, then execute it on both. Both should use the updated command; rename retains identity.
2. Give one bound slot its own alias/icon. Later catalog edits should preserve these slot overrides while updating catalog-owned values.
3. Delete the catalog entry. It disappears from selection, while existing bindings (including another character/job loaded later) retain the last command through a retired snapshot.
4. Re-create the same name with another command. Existing bindings should retain the deleted action's identity; new bindings use the new entry.
5. Existing bindings with an exact, unique catalog match are adopted on load; ambiguous/modified old copies remain independent until rebound.
6. Check duplicate-scope entries, command fallback, reload and saved XML. Blank catalog command fields remain blank. No unrelated hotbar files are rewritten automatically.

Catalog refresh reads both sources about once per second while menus are closed and before execution; unchanged XML reuses parsed records. Associated values resolve in memory and provenance/snapshots persist on ordinary hotbar saves. Deleted snapshots are retained as hidden `deleted` entries in the originating catalog.

Simulated catalog identity/rename propagation, overrides, ambiguous legacy adoption, blank fallback, hidden deletion snapshots and coordinated saves passed. Live multi-character updates remain pending.

---

# Personal 6 — checkpoint 4: combined catalogs and coordinated saves

Runtime: `0.4.0-a.20261014.personal6-4`. Apply after checkpoint 3. Catalog/slot XML is never supplied in packages. Existing per-character catalogs are retained in place.

- Global catalog: `data/CustomActions.xml`; character catalog: `data/hotbar/<server>/<character>/CustomActions.xml`.
- Both appear in Custom Actions/Edit/Delete regardless of the save option. Duplicate names show [Global]/[Character]; the command shortcut prefers the chosen save scope when names collide.
- `//xb catalog global` (new default), `//xb catalog character` (`personal` also accepted), `//xb catalog status`.
- This setting affects new actions; editing an existing entry saves to its original source. Review title shows the scope. Blank commands remain blank in XML.

1. Confirm existing private actions remain listed. Create a new global action on Franklet; open Custom Actions on Lionstag and verify it appears there.
2. Select character saves; create a private action and verify it is listed along with global actions, but is private to that character. Return to global saves.
3. Create equal names in both scopes; check both labeled entries and their distinct outputs. Editing either must affect only its own catalog.
4. On two clients, add different global actions without reloading the older client. Both must survive. Edit the same action on both: the second stale save should retain its draft and report a conflict.
5. Check blank-name/blank-command creation, rename, delete, Save & Bind, and existing bindings. Confirm malformed catalogs are not replaced.

Available verification: combined views/source choice, stale snapshots with independent additions, same-entry conflict, rename, blank commands, simulated lock contention, and failed-write preservation passed. Profile/default compatibility passed. Native Windows exclusive locking/replacement and live multiclient saves remain pending.

---

# Personal 6 — checkpoint 3: cutscene access and target order

Runtime: `0.4.0-a.20261014.personal6-3`. Apply after checkpoint 2.

1. In Auto/OnInput visibility, open NPC dialogue or a cutscene. Hold a trigger: the crossbar should appear and a slowenter binding remain accessible. Release: normal autohide resumes.
2. Explicit Hide remains hidden. Always-visible mode retains its existing cutscene hiding.
3. Bind an enemy action and a friendly spell: Current Target (<t>) should be the first valid choice. Self-only actions retain Self; no unsupported targets are added.
4. Check paging, binding and target execution normally. Independent trigger-field fade remains dormant.

Simulated visibility/target combinations passed. Live dialogue/cutscene execution is pending.

---

# Personal 6 — checkpoint 2: slot dimming and feedback

Runtime: `0.4.0-a.20261014.personal6-2`. Apply after checkpoint 1; final complete package will include both. No user data/configuration is supplied.

1. Put the same MP spell on two slots, including another bar. With insufficient MP, both should dim; MP recovery should restore both when recast allows it.
2. Repeat with linked custom-action spell metadata and a TP action. Affordability, warmup and cooldown remain per slot.
3. Execute slots repeatedly; feedback should restart at the latest slot and always finish.
4. Check normal text fading and compact/scale behavior.

Simulated verification: duplicate dim/recovery, slot-independent cooldown, feedback overshoot/retrigger, MP colors, text fade, identity guards, and 108 rendering layouts passed. Native gameplay remains pending.

---

# Personal 6 — checkpoint 1: confirmed character storage

Runtime: `0.4.0-a.20261014.personal6-1`. Apply this overlay to Personal 5 (or the complete package later in this batch). No data, catalog, binding XML, settings XML, or controller INIs are supplied. Preserve your installed data. Rollback files restore the preceding committed code.

1. Load before logging in. Verify the wrapper still provides login controls; no Asura/UnknownServer character folders should be created.
2. Log into your Fenrir character, reload and bind an ordinary action. Confirm status and existing sets remain correct.
3. Log out with the addon remaining loaded. Reload must not create or write character files until login.
4. Repeat on another character. Compare existing XML/backups if bindings appear missing; report character/server/job and active set.

Available verification: identity resolver and actual storage write guard exercised with simulated APIs; all Lua sources parsed using the documented Lua 5.4 fallback. Native wrapper/login testing remains pending.

Agreed remainder: duplicate-action dimming and feedback completion; OnInput triggers during cutscenes; valid `<t>` first; merged global/private catalog listing with global default saves and source-preserving edits; coordinated saves; catalog-bound updates with deletion snapshots; last-client shutdown. Independent trigger-field fade remains dormant; L1 companion, icon organization and personal menu ordering are deferred.

---

## Personal/public polish review — October 13, 2026

Review only: no runtime files or public snapshot changed. User confirms text
no longer flickers during continuous fade-in/out, strengthening the evidence
for the stroke-alpha units repair. This does not certify every Personal 5
command/estimator or native concurrent-wrapper test.

Sources compared: recovered public RC3+Icons/Credits/Escape, current Personal 5
at 718fd3a, the October 10 return snapshot (18-apps-personal1), and the delivered
Batch 19 Test 2 complete companion build (19-companion2). The old companion was
on experiment/l1-companion-batch19; its documentation records local/unpushed
commits. Earlier conversation decisions and current runtime take precedence
over old TODOs, including compact switching and shoulder taps now completed.

Public port candidates, in priority order:

1. Stroke-alpha repair, with the optional textfade comparison. Correct the six
   inappropriate transparency calls; retain the chosen endpoint default until
   intentionally changing it. Smooth text fading now has user evidence.
2. Approved instantaneous compact command and relayout. Its implementation
   keeps bindings/drafts/scale intact and has a user command pass plus the
   recorded mock layout matrix. It is still absent from the public snapshot.
3. Installation mutex without importing personal control mappings. Duplicate
   native startup remains a live check; explicit profile switching already
   stops/exits/restarts the shared reader.
4. Zero-opacity skillchain backing fix; independent AA Enabled gate and pause
   cleanup after the Personal 5 combat check. Keep the tracker needed for other
   skillchain cues active and preserve public defaults/profile choices.
5. Refresh cached theme from character settings after login. Adapt the generic
   configuration behavior without the personal PS5Extended migration/defaults.
6. Configurable MP-shortage coloring and rounded timing-bar caps after live
   visual checks. Preserve saved palettes and validate repeated-action slots.

Public RC3 already contains Apps transport/input consumption, standard face
controls, gameplay D-pad choice, scale/drag/visibility, the custom-action review,
inline typing, destination chooser overlay, labels, item/icon fixes, XML read
guards, credits patch and global Escape. Those are not new missing ports.

Old personal work genuinely absent from this RC-based branch:
- Shared data/CustomActions.xml catalog and legacy import/stale-save checks.
  Public/current Personal 5 catalogs remain per-character. Restore sharing as
  a deliberate option with current XML guards and stronger concurrent-save
  coordination; the old check-before-write alone is not a lock.
- Removable sibling l1 addon: eight compact diamond slots, original numbering,
  append commands and independent settings. Adapt routing to current shoulder
  gestures; do not copy the old Tab/Shift/minimize controls over newer choices.
- Independent .12s trigger-field fade retaining its last position on release.
- OnInput trigger visibility during cutscenes; current visibility module hides
  all bars during cutscenes. Useful for seeing SlowEnter/NPC bindings again.
- Optional FFXI menu panel/open-close sounds. Current golden cursor/page/menu
  improvements do not imply the entire old menu_skin implementation is present.

Further personal requests: catalog edits update owned bindings while deletion
leaves snapshots usable; valid Current Target (<t>) first in target selectors;
explicit new-set scope without All- naming prefixes; separate R1/L1 macro bars,
personal menu/icon organization and supplied controller glyphs; Mute Joy15
probe bank; final-client shutdown using the existing on_unload_killahk flag.
That shutdown must account for minimized/background clients, since an old
heartbeat alone does not establish that an addon unloaded.

Additional issues reproduced with actual UI code and mock Windower objects:
- Two Cure bindings at low MP yielded icon alpha 100 and 255. Action-keyed
  disabled state prevents the second slot receiving the same transition.
  The public source has the same path. Test cooldown/warmup duplicates too.
- Feedback alpha 15 with speed 30 became -15, then -45, remaining active.
  The public source also tests nonzero instead of terminating/clamping at zero.
- Texts.Color.Alpha reaches theme.font_alpha but constructors do not consume it.
  Decide its exact label/cost meaning before wiring it consistently.

Suggested next batch: duplicate-slot and feedback cleanup, valid <t> choice
order, restored OnInput cutscene access/trigger fade; port stroke/compact/mutex
on an isolated public update branch. Finish client lifecycle separately, then
reintroduce shared catalogs and the companion. Icon/path overhaul remains later.

Publication checkpoint: the connected GitHub repository master still reports
0.4.0; listed work branches are the October 4/5 branches. Latest RC3/Personal
snapshots and recovered commit history are not published there. Establish an
up-to-date release branch/tag before the proposed FFXIAH announcement. This
review performs no remote mutation or release publishing.

## Personal 5 — text fade and autoattack processing, October 13, 2026

Runtime **0.4.0-a.20261013.personal5**. Cumulative Personal 5 overlay over
Personal 2 Complete, Defaults 1, Personal 3 or Personal 4. Rollback restores
Personal 4 pulse-test files. No data, settings/config INIs or images are supplied.
The new autoattack.lua module is included. The public snapshot stays frozen.
`//xb textfade on` fades crossbar text, strokes and text backgrounds together
with the bar. `//xb textfade off` restores the current endpoint behavior: hide
as closing begins, reveal once fully open. Bare `textfade` toggles; `status`
reports without saving. The default remains off. Startup uses the chosen text
mode too. This command does not restart the current fade or recreate surfaces.

Focused checks passed against actual geometry with mock Windower objects:
opening/closing, startup with ordinary fades disabled, reversal, switching
during a fade, and keeping logically hidden slot labels hidden. The existing
compact-command preservation check also passed. Native FFXI visual comparison
remains a live test.

`//xb autoattack off` clears and stops the optional estimate's swing history,
clock reads and pause bookkeeping, and immediately hides its primitives even
during a closing fade. `on` starts fresh; bare toggles and `status` only reports.
This controls the UI estimate, not the character's actual attacks. Opacity,
colors, lockout bars, bindings and the Attack/Disengage slot remain separate.
Enabled defaults to true to preserve the previous behavior until explicitly
disabled; the existing Opacity=0 still hides drawing only. Timed AA pauses now
use stored expiry times rather than scheduled callbacks. Learning starts at the
second swing and resets between engagements instead of sampling the first-hit
approach delay or carrying an old fight's average into the next.

Focused actual-module tests passed for complete disabled-work bypass, fresh
reenabling, overlapping WS/JA pauses, extended pauses, persistent disabling
buffs, ten-sample history and learning from real inter-swing intervals. Actual
UI tests passed for immediate off during a closing fade while preserving action
lockout state. Real command helpers passed status/validation/idempotence and
existing preference/fade preservation. Those checks use controlled clocks and
mock Windower APIs; native combat behavior and CPU cost remain unmeasured.

### Installation and live checks

1. Release controls, use //xb controller stop, unload XIVCrossbar on every client
   sharing the folder, copy xivcrossbar/ over the installed addon, then load each
   client. Do not copy rollback/ unless reverting. //xb version should say
   personal5; selected/running profile, scale, compact mode, colors and bindings
   should retain your values. The repaired settings.xml from the previous XML
   incident is a separate user-data file and is not overwritten by this ZIP.
2. With on-input visibility, compare //xb textfade on and off while holding and
   releasing a trigger. On: labels/costs/recast text/strokes fade with the bar.
   Off: text appears only fully open and disappears as closing begins. Try a
   quick fade reversal too; empty/hidden labels should not appear in either mode.
3. Compare //xb restart in both modes. Startup honors the same text selection.
   Regular //xb fade off remains immediate after the startup reveal; triggers
   can interrupt that reveal. Textfade changes must not change layout/draft/set.
4. //xb autoattack off reports OFF and saves. Continue attacking and using
   spell/WS/JA slots: execution, Attack/Disengage and independent lockout bars
   should behave normally. On starts fresh; on again preserves current learning.
   Current opacity is preserved and defaults to 0, so enabled does not imply a
   visible bar. If using a nonzero AA opacity, verify off hides it immediately,
   including during a closing fade. The estimate begins after the second swing.
5. //xb textfade status and //xb autoattack status only report; bare toggles.
   Reload with lua r xivcrossbar and verify both saved choices persist. Invalid
   arguments should print usage without changing state.
6. Briefly check personal L1/R1 taps/combos, touchpad, PS focus, ordinary slot
   bindings, menu confirm/back and immediate compact switching. All retained
   Personal 4 mapping details remain below; the optional F15 probe is unchanged.
7. With two clients, unloading/reloading one should leave the other's controls
   available. The mutex already rejects a duplicate wrapper in this installation.
   Last-client automatic shutdown is not in this patch; ordinary unload still
   leaves the wrapper until //xb controller stop or its Ctrl+Alt+F12 hotkey.

### Verification and checkpoints

Passed all nine focused/prior Lua test groups, including profile persistence,
compact command/layout, MP coloring, rounded bars, text fade, optional F15 and
the new estimator/command checks. Actual UI layout covers 108 configurations
over six resolutions and three scales; narrow-bar checks cover 18 widths.
All 60 Lua sources parse after temporary Windower syntax normalization; this
uses Lua 5.4, not a native Windower Lua 5.1 runtime. All 40 existing AHK gesture
decisions and four AHK lexical/include checks pass. Native Windows/AHK/Windower
delivery, combat and renderer behavior remain live tests.

Conceptual commits: 397afd4 text comparison; 047f418 independent estimator.
The personal5-test-20261013 tag identifies the final package/docs snapshot.
Commits remain local/unpushed; the recovered workspace has no configured remote.

User materials/observations: settings(8).xml contained a valid closing root at
line 187 followed by 38 bytes of partial/duplicate closing markup. The separate
repair removed only that tail and validated, preserving all earlier bytes.
User confirmed finding it too. The producing writer has not been established.
Latest requested text comparison, true AA stop, hidden-work review and lock/
shutdown explanation are addressed above and in PERSONAL.md. Actual last-client
shutdown, the Mute probe and standalone-addon processing audit remain pending.

## Personal 4 — profile persistence, target clearing and MP color, October 13, 2026

Runtime: **0.4.0-a.20261013.personal4**. Cumulative overlay over Personal 2
Complete, Defaults 1 or Personal 3. No data, config.ini, personal-controller.ini
or images are supplied. Rollback restores matching Personal 3 files. The public
snapshot remains frozen. The optional F15 probe has no new changes and remains
a pending live test.

### Changes and immediate checks

1. Release buttons, //xb controller stop, unload XIVCrossbar on all sharing
   clients, copy the supplied xivcrossbar/ files, then load on each client.
   //xb version should report personal4. //xb controller status should show
   selected/running ps5-extended. Its backend is still DirectInput.
2. An older ps5-directinput selection migrates once to the extended default.
   PersonalProfileMigrated records that migration, including load/login config
   refresh. //xb controller profile ps5 explicitly restores base behavior and
   persists afterward; return to ps5extended for the personal tests. Other reader
   selections/device IDs remain. Check your scale, compact state, visibility,
   colors and bindings survived. Login now rebuilds its cached theme from the
   refreshed character settings before layout too.
3. Bare L1/R1 completed taps immediately send F10/F8 on release, with no 250ms
   single-tap delay. A second completed tap within DoubleTapMs sends Escape to
   the original client for 40ms, releases its keys there, then switches previous/
   next. Test with two clients in ordinary gameplay and a visible target: it
   should clear before focus changes. PS switching retains its prior behavior.
   Combos consume the held shoulder; a new input, menu/trigger state or external
   focus change cancels a queued switch. With one client there is no Escape.
4. Bare touchpad tap sends backtick on release. Its 500ms hold still opens the
   map peek once and sends Escape once on release in the same focused client.
   L1+touchpad retains immediate Tab plus F15 on hold. L3/R3 and ordered held
   comma/period combos retain Personal 3 behavior.
5. R1 Up/Down initially sends bare arrows. Press Left/Right and release the
   direction while keeping R1 held: Alt remains latched. Further Up/Down also
   carries Alt until R1 releases. R1+Cross/Circle/Triangle temporarily suspends
   physical Alt through its direct Enter/Escape/Ctrl+Plus pulse and restores
   the latch afterward. Confirm those shortcuts still work in Trust and do
   not produce Alt+Enter/Alt+Escape. Menus/triggers/focus/disconnect take priority.
6. Bind an ordinary spell and a custom command linked to a spell. When MP is
   below recorded cost, cost text turns soft pink (255,149,151); the icon remains
   dimmed under the existing resource checks. MP recovery restores normal cost
   color even during recast. Recast-only dimming must not turn cost pink. TP
   stays unchanged. Saved Color.MpCost values are retained; the normal default
   is green (194,253,195). New Color.MpCostInsufficient settings are configurable.
7. To hide the duplicate skillchain bar, set SkillchainIndicator.Opacity=0 in
   settings.xml and reload. Neither fill nor backing should appear; slot chain/
   burst cues retain internal tracking. Other rounded bars continue working.
8. Regression: ordinary trigger slots preserve targets; addon and native menus
   remain separate; keyboard text entry, Options drafts, compact switching,
   scaling/dragging, two-client reload and PS tap/hold still work. Check for
   stuck Alt or Escape after focus changes during held/pending inputs.

### Color/performance and shutdown notes

Spell lockout defaults: 3 seconds, primary RGB200,200,255, ending RGB15,205,5 in
its final 15% (0.45 seconds at this duration). WS: 2 seconds, RGB255,150,0. JA:
2 seconds, RGB220,30,30 for the first second then RGB15,205,5 for the second.
All three opacities default to 220/255. They share a drawing surface, selecting
the appropriate palette for the latest action. The two JA phase labels do not
come from independent game-lock measurements.

Opacity=0 hides the auto-attack display but its swing history and pause callbacks
continue; there is no separate Enabled switch or measured CPU percentage yet.
The corrected stroke API removes invalid negative alpha calculations. It could
have contributed to fade flicker, but that cause has not been isolated in FFXI;
the prior endpoint text visibility remains in place.

The installation-specific Windows mutex is already active. Last-client shutdown
is still not implemented; on_unload_killahk=true stores the preference, while
ordinary one-client or last-client unload leaves AHK running. Explicit //xb
controller stop remains the shared stop.

### Available verification

Passed: actual root profile migration and refresh callback, preserved unrelated
appearance values, later explicit choices, and refreshed character theme before
layout; MP shortage/recovery, linked metadata, cooldown independence and TP
preservation; 40 AHK gesture decisions through the narrow JS translation;
108 compact layout cases and 18 narrow widths plus rounded shape/fade/drag/join
checks, now including zero-opacity skillchain backing. Compact command, fresh
defaults/setup and optional F15 tests pass. All 56 Lua sources parse after
temporary Windower syntax normalization; four AHK lexical/include checks pass.
Native Windows/AHK/Windower behavior still requires the live tests above.

Local commits: 21684f5 profile persistence; df77fff personal controls;
b413792 MP colors/skillchain hide; 2e16f59 refreshed character theme. Documentation
and package checkpoint follows. Nothing pushed. To roll back, stop the wrapper,
unload all clients and copy rollback/xivcrossbar over the install. The new
personal_profile.lua can remain unused after old root files are restored; your
data is retained. To deliberately return to the base profile after migration,
use //xb controller profile ps5 instead of resetting the migration marker.

---

## Personal 3 — control refinements and rounded indicators, October 13, 2026

Runtime: **0.4.0-a.20261013.personal3**. Cumulative small update over Personal 2
Complete, with or without Defaults 1. No images, saved data, config.ini or local
preferences are supplied. The public snapshot remains unchanged.

### What changed

- MP-cost default is review green, 194/253/195 (#C2FDC3). Existing XML colors are
  preserved; TP is unchanged. Edit Color.MpCost in your settings.xml if you want
  the green immediately in an existing installation, then reload.
- R1 Up/Down use bare arrows. Left/Right latch Alt until another R1 combo or R1
  release. Previously held directions do not gain the new chord's modifier.
- L1+touchpad sends Tab on down. Holding adds F15 at 500ms; release adds no Tab.
- R3 then L3 holds comma until L3 releases. L3 then R3 holds period until R3
  releases. The first click may release while the second still owns the key;
  both must return neutral to rearm, and H/R do not fire after a combo.
- All seven timing-bar fill/background primitives use rounded endcaps, with
  scaling, dragging, compact switching and fades kept together. The two AA
  colors have a flush internal join. Timers themselves are unchanged.
- Stroke.Alpha now uses the 0–255 alpha setter. Its saved value remains intact.
- Mute=Joy15 is recovered from Max's October 2 live JoystickTest, alongside
  PS=Joy13. A gated Mute bank is not added yet. The optional probe supports a
  temporary F15 command through raw DIK 102; nothing starts automatically.

### Install and live checks

1. Release controller buttons. //xb controller stop, then unload XIVCrossbar
   on all clients. Copy xivcrossbar/ over Personal 2 Complete and load again.
   Confirm //xb version reports personal3 and selected/running ps5-extended.
   Use the same installed code and profile on every sharing client.
2. Outside addon menus: R1+Up/Down moves native selection without Alt. R1+Left/
   Right sends Alt+arrow; release the direction while holding R1 and check Alt
   remains. Press Up or Cross/Circle/Triangle to clear it; release R1 to clear.
   Bare D-pad still uses your saved arrows/ijkl choice. L2/R2 retain priority.
3. In Trust: direct R1+Cross/Circle/Triangle still act as Enter/Escape/Ctrl+Plus.
   L1+Cross remains Ctrl+Space. A held old direction must not repeat into a new
   shortcut. Test a focus switch during a held inventory arrow as well.
4. L1+touchpad: one Tab immediately; hold 500ms adds F15; release adds nothing.
   Bare touchpad retains F8 tap or map-peek hold/Escape release. PS tap/hold and
   bare L3=H / R3=R still work. Shoulder singles/doubles retain the 250ms choice;
   the on-down/immediate-release/short-window alternatives remain a decision.
5. Hold R3 then press L3: comma zoom continues until L3 releases, no H/R. Reverse
   order: period until R3 releases. Try releasing the first click first; focus
   loss or opening an addon menu must release the held key. Simultaneous clicks
   do not guess an order. Sticks' native movement/camera remain unchanged.
6. Optional F15 command test: copy tools/keyprobe/xbkeyprobe into addons, load
   //lua l xbkeyprobe, then //xbkeyprobe f15 input /echo F15 received. Hold L1+
   touchpad: initial Tab, then one echo. Repeat with another command or alias.
   //xbkeyprobe f15 off removes it; //lua u xbkeyprobe removes the probe. This
   transient raw-DIK handler does not edit saved bindings or load automatically.
7. At Lionstag's 960x540/.6 and Franklet's 1280x720, check spell/JA/WS and skillchain
   timing-bar ends, backgrounds, fades, dragging and //xb compact. Other sizes
   are welcome. AA remains disabled at Opacity=0; to inspect its rounded split,
   temporarily enable it in XML and engage after reload. Its estimate is not a
   server countdown. Check no seam/notch between its red and green segments.
8. For a bound spell with insufficient MP, icon/cost/element should dim; with
   enough MP and recast ready, they restore. Test linked spell metadata on a
   custom command too. Confirm labels remain legible with Stroke.Alpha=200.
9. Regression: addon menu D-pad/Confirm/Back/Exit, text entry, ordinary trigger
   bindings, Options draft preservation, compact switching, two-client reload
   and focus return. No native F-key/menu bleed-through should return.

### Available verification and rollback

Passed: 34 actual AHK gesture decision scenarios through the narrow JS
translation; 108 compact UI cases over six resolutions/three scales; 18 narrow
width cases plus actual UI fade/drag/rounded AA-join checks with mock drawing;
fresh defaults/setup, compact command, optional F15 repeat/blocked/removal
checks. All 53 Lua sources parse after temporary Windower syntax normalization.
AHK lexical/include/gating checks pass. Native Windows/AHK/Windower delivery
and the appearance in FFXI still require the live checks above.

Commits are local, not pushed: 8c5ab0e MP green; e2e5b6e personal routing;
a9d889b rounded indicators; b581b99 stroke alpha; a1d1994 Mute/F15 probe;
7ee70b1 test harness correction. Documentation/package checkpoint follows.

Rollback restores the matching Defaults 1 runtime files. Stop the wrapper and
unload all clients before copying rollback/xivcrossbar, then load again. The
new ui/rounded_bar.lua can remain unused after rollback; no settings/bindings
are replaced in either direction. Last-client shutdown, Texts.Color.Alpha,
feedback overshoot, personal crossbars and public compact port remain pending.

---

## Personal 2 Defaults 1 — October 13, 2026

Runtime: **0.4.0-a.20261013.personal2-defaults1**. Small update over the complete
Personal 2 package. Fresh settings now default to ps5-extended, GameplayDPad=ijkl,
VisibilityMode=oninput, iscompact=true, enable_superwarp_all=true and
on_unload_killahk=true. Saved XML values are retained. Personal first-run setup
now selects the extended profile from its PS5 card. Public defaults are unchanged.

The previous forced on_unload_killahk=false assignment is removed. The flag is
retained as preparation; the unload callback still leaves the shared wrapper
running. Last-client shutdown has not been implemented and is not being tested
as a working feature. No palette values, text-alpha wiring or new probe key
mapping was changed. Public compact port is approved and recorded for the next
public candidate; the frozen public snapshot remains unchanged.

### Install and test

1. Unload XIVCrossbar, copy the supplied xivcrossbar/ files over the installed
   Personal 2 Complete, then load/reload. This patch supplies no images, data or
   config.ini. The controller wrapper code is unchanged; no AHK restart is needed
   just for these defaults. Close/reopen the optional probe to load its watcher.
2. With your existing data, confirm saved profile/layout/visibility/D-pad/warp
   choices remain as they were. //xb compact still toggles instantly.
3. To check fresh defaults, temporarily back up/move only data/settings.xml while
   the addon is unloaded; keep all bindings/config.ini. Load, check the newly
   created settings.xml and //xb status. Restore the backup afterward if desired.
   Do not discard your data/hotbar folders to test defaults.
4. A completely fresh setup's PS5 card should say PS5 Extended and complete with
   selected/running ps5-extended. Other controller readers remain available.
5. Unload one client while another is using the controller: it should still work
   despite the stored true shutdown preference, because last-client logic is
   pending. //xb controller stop remains the explicit shared stop.
6. Optional Mute discovery: stop the normal wrapper, launch keyboard_probe.ahk
   manually, enable Watch controller button numbers (read only), normally device
   1. Focus FFXI, press/release Mute alone, record the Joy number and release to
   none. Check a face button if Mute gives no result. No keys are reassigned by
   this watcher; the proposed Mute-held candidate bank is still a next step.

Color explanations: xivcrossbar/COLOR-SETTINGS.md. Texts.Color.Alpha is unused;
Texts.Stroke.Alpha is passed to the wrong transparency API. Feedback.Speed has
a legacy negative-overshoot edge case. These are recorded for a future wiring
pass, not silently changed alongside defaults.

Validation: fresh-default/profile validation and actual setup-selector checks
pass, including preserved public choices and reused selector IDs; 108 compact
layout scenarios and command checks pass; 22 gesture decisions pass; all 50 Lua
sources parse with temporary Windower syntax normalization. AHK lexical/include
checks pass. No native Windows/Windower execution is available here.
Commits are local, not pushed. Previous test history remains below.
Commits: 243e7ec personal defaults/setup; ad15aad read-only button discovery;
12b23cd color/defaults documentation. User reported the instant compact command
works well and requested its inclusion in the public candidate; broader compact
resolution/draft/cooldown checks remain the recorded test plan.

Rollback files restore the corresponding Personal 2 Complete files. Newly added
COLOR-SETTINGS.md may be kept or removed; it has no runtime effect. This does not
restore older user settings because the patch never overwrites them.

---

## Personal 2 Complete — Cioara test, October 13, 2026

Runtime: **0.4.0-a.20261013.personal2-compact**. Complete personal installation
based on RC3 + Icons/Credits/Escape + Personal 1. No base ZIP or patch chain is
needed. All original images/themes/runtime modules are included; installed
data, bindings, config.ini and local controller preferences are not supplied.
The public snapshot remains separate. Work is local, not pushed to GitHub.

Commits: bdf8582 source recovery/current workflow; 089e29e personal gestures;
7b5f0e5 instant compact switching; 6e0eed3 optional probe; ff6cf52 direct shortcut
modifier cleanup. Subsequent documentation/packaging commit(s) are local as well.
Existing historical records below are preserved.

### Install first

1. Stop the old shared wrapper with **//xb controller stop**. Verify it stopped;
   then **//lua u xivcrossbar** on all clients. Back up the existing addon folder.
2. Put the supplied complete **xivcrossbar/** folder into Windower's addons.
   Restore your own **data/** and **config.ini** from the backup, plus any icons
   you personally added/replaced. Keep all new Lua/AHK files together. The ZIP's
   WORKFLOW.md, TESTING.md and rollback/ stay outside the installed addon.
3. **//lua l xivcrossbar**. With no data/config.ini, finish setup using PS5 and
   PlayStation artwork, then enable the hidden profile. For existing settings,
   **//xb controller profile ps5extended** on each participating client saves it
   and switches the shared wrapper. Release buttons before resuming.
   Ability/spell resource caches are generated on first load from your installed
   Windower resources, just as in the baseline; they are not user bindings.
4. **//xb status** identifies Personal 2; **//xb controller status** should show
   selected/running ps5-extended, connected, ready, Personal gameplay and a
   double-tap interval of 250ms. All participating clients use the same profile.
5. Keep native movement/camera sticks. Clear duplicate native button/hat/menu
   assignments already replaced by the wrapper. //xb dpad ijkl retains your
   existing IJKL game configuration; R1 arrows are always Alt+arrows independently.

### Live tests, one at a time

Record current Cioara/PC resolution; it is not assumed from older screenshots.

1. **Baseline:** first check ordinary ps5 profile: bare D-pad, Triangle main
   menu, Square focus, Cross confirm, Circle back, Share exit, Options chooser,
   L2/R2/combined slot execution once with no native target/menu leakage. Then
   enable ps5extended and repeat. Old mappings are untouched by compact.
2. **Shoulder singles:** tap/release R1 and wait briefly: F8/native target NPC.
   L1 similarly sends F10. No held Ctrl/Alt from shoulders alone. Hold either
   shoulder without another button and release: one delayed target action.
3. **Shoulder doubles:** two quick R1 taps switch forward; L1 switches backward.
   No F8/F10 accompanies switching. The second press starts within 250ms of the
   first release and itself releases within 250ms. Existing PS tap uses the same
   forward list. With only one client it restores that same window.
4. **Direct shortcuts:** R1+Triangle -> Ctrl+Numpad Plus; R1+Circle -> keyboard
   Escape; R1+Cross -> keyboard Enter; L1+Cross -> Ctrl+Space. Check your Trust
   menu separately, then native confirm/cancel. No additional bare Cross/Circle
   action or shoulder-release targeting should occur.
5. **Inventory:** R1+D-pad holds Alt+the corresponding arrow. Check all four,
   release R1 while holding a direction, then release/repress it normally. No
   stuck Alt/arrow and no duplicate base D-pad action. The target tap is consumed.
6. **Touchpad tap/peek:** short bare tap sends F8 on release. Keep backtick bound
   to input /map. Bare touchpad held 500ms emits backtick once; keep it held until
   the map appears, release -> one Escape closes it. No extra F8. Hold again,
   switch to another app or FFXI client, then release: no Escape in that window.
7. **L1 touchpad:** short tap -> Tab. A 500ms hold -> F15 once, with no release
   Tab or F10. Use your test binding or optional DIK observer; F15 previously
   reported DIK 102. Record whether the desired Windower binding is accepted.
8. **Stick clicks:** bare L3/R3 -> H/R on release. Hold R3, then press L3 -> one
   period; reverse order -> one comma. No heal/autorun from the first click. Keep
   the first held while pressing the second, then release both. Simultaneous
   samples deliberately produce neither ordered chord. L1+analog stick does
   nothing extra; the ordinary camera still works.
9. **Priority/cleanup:** hold a shoulder with L2/R2 and use a real bound slot;
   trigger action wins. Repeat with addon menu/text/chooser open: ordinary addon
   navigation wins. Switch focus with shoulders/directions/touch/clicks held,
   release everything, retry: no stuck keys, queued targets or unexpected action.
10. **PS regression:** tap cycles/restores clients. A 500ms hold returns to the
    recent non-FFXI app and does not cycle on release. Restoring focus works.
11. **Compact:** //xb compact toggles immediately; on/off are idempotent. Also
    try //xb ui compact. Test at scale 1 and .6, after dragging, with Options
    chooser/tooltip open, during an unsaved custom-action draft and while a slot
    is primed for binding. Set, draft, position, scale and key state survive;
    slot backgrounds, icons, labels, feedback and recast overlays stay aligned.
    Compact hides the Share/Options artwork, retaining their button functions.
12. **Visibility/persistence:** toggle compact while autohide/fade is active and
    while hidden. No new startup fade or forced show. Test a real cooldown and
    active trigger feedback during switching. //lua r xivcrossbar retains the
    compact preference, current data and profile; another client keeps working.
13. **Public follow-ups:** confirm Credits displays at this resolution and
    physical Escape closes main/review/binding/chooser menus, then behaves
    normally in native gameplay. These public patches were included in Personal
    1, but their live results were not yet recorded. Report any console error.

### Probe and validation

Optional instructions: **xivcrossbar/tools/keyprobe/README.md**. The observer and
manual AHK sender never start with the addon. F13–F15 are established candidates;
higher F-keys and Kana/Convert/Nonconvert/Browser Back/Forward/Favorites need live
verification. No power/mail/media-launch keys are part of this optional probe.

Current offline checks: 22 actual-source gesture decision scenarios (AHK helper
syntax translated to JS), 108 actual UI/geometry layout scenarios at six
resolutions and three scales, compact command/state checks, whole-source Lua
parsing, AHK lexical/include/gating/release checks, image/dependency/ZIP audits.
Gesture decisions are tested; native AHK parsing, hardware timing, Windows focus
and Windower/FFXI delivery remain live checks. Available Lua is 5.4, with only
inherited literal-string method syntax normalized in temporary copies. Native
Lua 5.1/Windower and the lost older 50-group test suite were not rerun.

### Rollback

Select **//xb controller profile ps5** on every client to disable the private
controls. For full code rollback, stop/unload on all clients and restore the
backed-up folder. The supplied **rollback/xivcrossbar/** restores the recovered
Personal 1 code/doc files changed by Personal 2; it needs the complete installed
images/modules. New personal_gestures.ahk and tools/keyprobe may be removed after
rollback because Personal 1 does not reference them. User data is preserved.

Scope: no new shoulder crossbars, mode switch, companion, catalog propagation,
personal menu reorganization, target-choice change or last-client shutdown.
Those remain future work, listed in PERSONAL.md. Local Windows mutex from
Personal 1 remains included. No public release files were modified.

---

## Personal 2 development record — October 13, 2026

Current work: release-only L1/F10 and R1/F8, consumed taps, 250ms shoulder
double taps for previous/next clients, R1 direct Enter/Escape/Ctrl+Numpad Plus,
Alt+D-pad, bare touchpad map peek, L1+touchpad Tab/F15, and ordered stick clicks.
L1+stick zoom is removed. Bare L3/H and R3/R now fire on release so an ordered
pair does not first trigger heal/autorun. No held bare shoulder modifier.

Recovery: the previous scratch checkout and Git objects were unavailable.
Recovered bytes from the delivered RC3 Complete and Personal 1 ZIPs; the latter
includes all public Icons/Credits/Escape patches. New local recovery commit
bdf8582 and tag recovered-personal1-20261013 record this starting point. Original
commit IDs below are historical references; their Git objects and the prior 50
regression groups were not recovered and are not claimed as rerun here.
Reviewed current NPCMirror WORKFLOW.md, blob
1348b25aafcf5d18f438cd6699bd6a1048592233; README belongs inside the addon, with
WORKFLOW.md and cumulative TESTING.md at ZIP root. All changes stay personal.

22 gesture decision scenarios pass using the actual pure AHK helper source
translated to JavaScript's equivalent expressions. They cover singles/doubles,
holds, consumption, context cancellation and stick-click order. This checks
gesture decisions, not the native AHK interpreter or Windows keyboard delivery.
Windows/FFXI live checks are still required.

Compact switching is now implemented: //xb compact [on|off] (also ui compact).
The existing surfaces move without a setup/reload or new object allocations.
108 real UI/geometry scenarios pass across six resolutions, three scales,
two/four/six bars, and both legacy layouts. Tests preserve slot/recast texture
and crop offsets, opacity/fade identity, chooser anchors, feedback and saved
position. Command checks cover toggle/explicit/invalid/pre-setup states and keep
the menu draft, selected set and input state untouched. 48 Lua files parse with
temporary Windower string-method normalization in available Lua 5.4; this is not
a native Windower/Lua 5.1 runtime check. The previous 50-group suite is historical.

---

## Personal 1 — hidden PS5 extended controls (October 13, 2026)

Runtime: 0.4.0-a.20261013.personal1-ps5extended. New branch personal/ps5extended,
based on public/rc3-snapshot at 0259ad1; tag public-rc3-snapshot-20261013 preserves
RC3 plus Icons/Credits/Escape patches. The old personal branch is untouched.
All commits are local; no remote is configured or GitHub push performed.

Reviewed NPCMirror's consolidated WORKFLOW.md, blob
61ff6e1ba6d0583cd24f58f665c16e258ef2bbcf. Commit 0259ad1 adopts it here; the prior
testing patches omitted WORKFLOW.md beside TESTING.md. Both are included at the
root of this testing package. Historical testing entries below are preserved.

Commits: af215d0 hidden profile/context leases; c88bc72 Windows mutex; b37ec5d
personal tap/hold/modifier/window routing; e67100f context failure revocation and
native-key/transport transition cleanup. Personal controls are isolated in
personal_controls.lua/.ahk; root Lua supplies context, AHK sends physical-style
keys. No L1 companion, personal-menu change, catalog propagation, compact toggle
or target-choice modification is implemented in this batch. PERSONAL.md retains
those priorities and explains current targeting/credit differences.

### Install

This is a cumulative overlay over RC3 Complete, including the later icon,
Credits and Escape fixes. It is not a complete fresh installation: images and
all unchanged runtime files must already be present. Bindings/data/configuration
are not included or overwritten. Do not overlay it on the older personal build.

1. On the existing RC3 setup, //xb controller stop; verify the old AHK process
   stops. Unload XIVCrossbar on all clients, then back up the installed folder.
2. Copy only the supplied xivcrossbar/ contents into that folder. Keep package
   docs and rollback/ outside the addon. Load the addon on each client.
3. On each participating client: //xb controller profile ps5extended.
   This saves the hidden profile and uses the existing automatic wrapper switch.
   //xb controller status should report selected/running ps5-extended, ready and
   connected, with Personal context=gameplay while the active client is in game.
4. Keep native stick movement/camera assignments. Clear native assignments for
   buttons now supplied by AHK (shoulders, L3/R3, PS, touchpad), and keep hat/menu
   D-pad assignments disabled as before. This avoids duplicate native actions.
5. //xb controller profile ps5 restores ordinary controls without file rollback.

### Mapping and live checks

| Input | Output / check |
| --- | --- |
| PS tap | Cycle clients in stable order; restore last client when none is focused |
| PS 500ms hold | While FFXI is focused, return to most recent non-FFXI app; no release tap |
| Bare touchpad | F8 / native target-NPC behavior |
| L1 + touchpad tap | Backtick on release; bind it to input /map |
| L1 + touchpad 500ms hold | Shift + backtick once; bind it to toggle ffxidb; no tap on release |
| Bare L3 / R3 | H / R; heal-lock/autorun as configured in FFXI |
| L1 / R1 | Ctrl / Alt, released cleanly |
| L1 + right-stick up/down | Period/comma, with held repeat |
| R1 + D-pad | Alt + matching arrow; no ordinary D-pad duplicate |
| L1 + Cross | Ctrl + Space; no ordinary Cross/Enter duplicate |

Start with ordinary profile controls, then enable the hidden profile and test
one row at a time. Bind your desired keyboard commands yourself. Opening an
addon menu/text field should suppress gameplay combos and shoulder modifiers;
ordinary D-pad/Cross/Circle still navigate it. L2/R2 bars keep priority. After
L1+Cross, bare Cross must still confirm normally. Switch clients while holding
a shoulder/direction, release, then retry: no stuck modifier or unsolicited action.

PS hold uses the user's newer return-to-other-app proposal for this first test.
data/personal-controller.ini is created locally with PSHoldAction=focus and
RightStickAxis=R. PSHoldAction=minimize restores the older minimize-all loop.
The observed stair-step came from individually minimizing each client.

Right-stick axis R needs live confirmation; controller status shows its value.
Observe a centered axis before zoom arms; unsupported/uncentered axes do not
block other personal controls. If R is not the right vertical axis, U/V/Z are
supported preferences; stop/restart the wrapper after editing the local file.
Native camera input may also tilt the camera during this first zoom experiment.
L1 intentionally emits native Ctrl when used alone, so native Ctrl behavior is
expected; Apps trigger transport remains unchanged.

Mutex test: manually launch the installed root script again while it is running,
then compare the status PID. It should stay the same with no duplicate outputs.
Test simultaneous addon loads only after that check. The lock is per installation;
it does not block unrelated scripts or another installation folder. Optional
last-client AHK shutdown is deferred. Stopping the wrapper remains a shared action.

### Validation and rollback

50 Lua regression groups pass, including hidden profile/context transitions,
heartbeat throttling, logout/profile/name cleanup, unsafe names and write-failure
permission revocation. Public input/menu/startup/storage tests remain passing.
Changed Lua parses after temporary standard-Lua normalization of Windower string
methods. Existing reader-map checks pass. AHK checks verify delimiter/string
balance, include/function links, hidden gating and mutex-before-status structure.
No Windows/AHK runtime is available here; these checks do not establish that
native gestures/focus/key delivery or mutex concurrency work on the user's PC.

To return to the frozen public snapshot: select ps5 on each client, stop the
wrapper, unload, copy rollback/xivcrossbar/ into the installed folder, and reload.
New personal_controls.lua/.ahk files may be removed afterward; public code no
longer references them. No settings/bindings/image restoration is required.
Credits/Escape and explicit cross-client restart results still need recording.

---

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

## Personal 6 compatibility delivery and command template

The correction is split into an AHK parser checkpoint and a stock-Lua catalog/
client-registration checkpoint. Both are included in `personal6-fix1`.
Packages use Personal 5 as the code rollback rather than restoring the known
broken original Personal 6 startup helpers. No installed XML/INI is included.
The separate `examples/CustomActions-template.xml` has 34 commands, including
six implemented NPCMirror verbs. It is not copied into runtime `data/` by the
package builder. Decoder/binding-value, uniqueness, escaping and icon-path
checks passed. Merge it into an existing catalog instead of replacing one;
see `examples/CUSTOM-COMMANDS.md` for dependencies and installation.
