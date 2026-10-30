# AHK v2 Context Poll 1 — October 30, 2026

Optional improvement P1, independent of v2 syntax compatibility. Requires the
existing migrated runtime (including Fast Start 3 and Touch Fix 1).

## Scope and evidence

PersonalPoll reads the personal-controls context and applies lease handlers.
MovementPoll can repeat that read when Trust policy is Ready, the stick exceeds
its existing threshold, and movement has not fired for the focus session.
Under the ordinary Send policy that second context lookup does not run. This
is a narrower saving than two scans on every 10ms tick. No CPU or latency gain
has been measured on hardware, and no perceptible speed change is promised.

TransportPoll now passes a fresh short-lived observation to PersonalPoll and
MovementPoll. PersonalContext resolves lazily on first request, applies the
existing lease handlers once, then publishes a mode/HWND result that consumers
only read. Repeated requests for that HWND in the same poll reuse it. Another
HWND resolves again. No record persists into the next timer call. Standalone
PersonalContext callers without a record still obtain a fresh result each time.

The extracted PersonalReadContext retains directory order, title matching,
complete-record/staleness validation, the two-pass immediate publication retry,
capability parser order and existing trace/miss classification. Both consumers
use the first observation's mode and adopted session; a file/session replacement
mid-poll becomes visible on the next poll. Unknown/stale results are shared too,
so a second consumer cannot independently reauthorize a missing lease mid-poll.
This deliberate within-poll consistency differs from observing two generations
in the old path; no earlier-poll gameplay permission is cached.

PersonalReleaseDue still precedes context observation. Hardware acquisition,
PS focus switching, neutral ownership barriers, final foreground rechecks,
Send/Ready semantics, message ordering, acknowledgments, timeout constants,
10ms timer target and key delays remain in their original order/values.
No startup, shutdown, launcher, transport rewrite or atomic-file replacement
changes are bundled. The extended profiles allocate one short-lived record per
poll; its allocation cost has not been profiled. Disabled profiles use false.

## Existing unified diagnostics

The regular controller status snapshot adds context_poll_protocol=1 and four
process-lifetime counters, collected by //xb controller status details:

| Field | Meaning |
| --- | --- |
| context_observations | Fresh resolver calls, including unfocused/no-file results |
| context_reuses | Same-poll same-HWND calls satisfied from the observation |
| context_scans | Directory passes, including the existing immediate retry |
| context_file_reads | Attempted reads of context INIs, including read failures |

No new diagnostic file, per-poll log or routine chat output. Counters reset on
wrapper restart. Reuse can remain zero in Send mode or after movement has fired;
that is expected. Compare deltas during an equivalent Ready movement sequence,
not raw totals across different focus histories or client counts. This does not
optimize Trust receiver lease scans or historical client registry enumeration.

## Install and verify

1. Stop the shared wrapper; overlay the ZIP's xivcrossbar folder onto the addon.
2. Start the wrapper. No Lua reload or shortcut setup is required.
3. Capture //xb controller status details; check context_poll_protocol=1.
4. Test usual Send movement and controller input. If already using Ready, repeat
   focused-client movement takeover and blocked menu/chat contexts; inspect
   counter deltas. Do not change your movement policy just to install this patch.
5. Check held triggers, companion banks, native menus, focus switches, quick taps
   and 2–4 clients. Repeat stop/start and last-client exit. Preserve logs of any
   regression; actual hardware behavior remains a live acceptance step.

Runtime overlay: ffxi_directinput.ahk, personal_controls.ahk, movement_signal.ahk.
All other input includes and user data/assets remain as installed. README,
WORKFLOW, TESTING, this guide and the updated audit accompany the overlay.
Rollback: stop wrapper, restore all three prior AHK files together, start again.

## Verification boundary

Eight translated v1/v2 policy suites compare observable outputs for their fixed
input traces. They do not execute native Windows I/O or simulate every mid-poll
file replacement. Native tests use hidden titled windows, actual INIs and real
v2 production context/movement functions to cover same-poll reuse, next-poll
mode/session adoption, HWND isolation, missing-file two-pass retry, stale and
malformed rejection, unfocused lookup and standalone fresh-read behavior.
Complete current results and historical failures are retained in TESTING.md.

User feedback accompanying this batch: touchpad works after Touch Fix 1; camera
spinning stopped before that fix and cannot be credited to it. Last-client
shutdown now seems reliable in the user's testing; no new shutdown fix or cause
is inferred. Earlier observations remain historical evidence.

Verified runtime/test checkpoint: b21727733bc345a9dba7f958a93379aec1190a51.
Full x86/x64 native matrix passed in run 41134452769. Initial run 41134321064
exposed a stale-vs-unknown expectation error in the new test; correcting that
assertion retained the existing runtime classification. All eight translated
policy equivalence suites and static/dependency/layout checks passed.
