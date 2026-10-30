# DirectLink improvement audit

Source inspected: ed86e5f (v1 baseline) and the v2 migration. Evidence paths and
line numbers below refer to the initial v2 source checkpoint 6b7105d; functions
are stable anchors if later documentation shifts line numbers. At migration
delivery none of the optional proposals was implemented. P1 is now implemented
in the separate Context Poll 1 batch; other proposals remain unimplemented. This is an audit of source behavior, not a claim
of measured latency or CPU improvements.

## Is DirectLink more complicated than necessary?

Parts of the current complexity are compatibility accumulation. The active
negotiated bank stream coexists with the old L1 mailbox, R1 menu messages,
native IJKL ownership, modifier/F-key fallback and old TrustMovement leases.
Those paths can eventually be separated behind explicit capability selection.
They cannot be removed while preserving every currently supported profile and
receiver. The core ordering, session generation, acknowledgments, complete
snapshots and neutral ownership barriers each prevent a different failure.

“Direct messages” currently means file-backed Lua messages, not Windows
SendMessage/WM_COPYDATA: AHK serializes acknowledged snapshots and Lua reads
its own mailbox. Replacing that mechanism would be a separate transport project.
The safest simplification is one immutable per-poll context and one explicit
route state, retaining distinct hardware, transport and gameplay responsibilities.
Do not collapse sender backpressure, receiver watchdog and physical-key ownership
into one generic timeout; their lifetimes and failure domains differ.

## Required and implemented in this migration

| Name | Discovery/evidence | Proposal and benefit | Risks / effort / priority / disposition |
| --- | --- | --- | --- |
| Explicit v2 startup | xivcrossbar.lua:start_controller_wrappers formerly executes an associated .ahk directly. | Version-check a concrete executable in the independent bootstrap; reject v1. Ensures intended interpreter. | New Windows PowerShell bootstrap needs Windower live acceptance; medium; P0; required and implemented. |
| Native collection semantics | personal_controls.ahk:PersonalPoll, PersonalFilter, PersonalNativeSpec; controller_messages.ahk:ControllerMessageInit/Lease. v1 sparse arrays mix named fields with indices. | Maps for sparse owners/state, Arrays for ordered queues, explicit records/match objects and Buffer. Preserves data semantics under v2. | Enumeration and absent-item differences need native regression tests; medium; P0; required and implemented. |
| Exception boundaries | controller_messages.ahk:ControllerMessageFlush 103–122; personal_controls.ahk:PersonalContext 320–359, PersonalKey; wrapper snapshot/trace writes. | Handle v2 throws at the same failure boundaries previously represented by ErrorLevel; preserve retries and release bookkeeping. | Must avoid treating uncertainty as permission; small; P0; required and implemented. |

## Prioritized independent proposals

### P1 — One context observation per poll

**Discovery:** PersonalContext rescans the directory, reads matching snapshots
and runs several capability parsers; its two-pass retry can repeat work. Ready
movement may call it again. This is demonstrated I/O duplication, not measured
input latency.

**Evidence:** personal_controls.ahk:PersonalPoll 15–80 and PersonalContext
320–359; movement_signal.ahk:MovementPoll 22–44; the observation includes
ControllerMessageLease, PersonalBankLease, RealKey/R1/L1 leases.

**Proposal:** Produce one immutable observation keyed by current HWND/session
inside a poll; pass it to movement and policy consumers. Reuse only within that
poll; never cache stale gameplay permission across polls. Preserve the immediate
second read on incomplete publication until Windows replacement is improved.

**Expected benefit:** Fewer file opens, regex passes and inconsistent views
within a single tick; simpler diagnostics.

**Tradeoffs/risks:** A mid-poll focus/context change still needs the existing
final owner check. An overly broad cache could authorize a stale action.

**Effort:** Medium. **Priority:** 1. **Disposition:** Implemented in the separate
Context Poll 1 batch, independent of AHK v2. See docs/AHK-V2-CONTEXT-POLL1.md.
The duplicate occurs in Ready movement evaluation, not every poll or Send mode.
Per-poll counters expose reuse; no measured CPU/latency benefit is claimed.

### P2 — Explicit negotiated route state

**Discovery:** Route state is distributed across CM.phase/requested/expanded,
PC.banks/ready/contextPaused and legacy layer state. The modern bank path returns
early while old implementations remain in the same large poll function.
Demonstrated structural complexity; no new live failure attributed to it.

**Evidence:** controller_messages.ahk:ControllerMessageLease 9–58,
ControllerMessagePoll 127–239; personal_controls.ahk:PersonalPoll 15–227,
PersonalBankLease and PersonalBanksPoll.

**Proposal:** Describe permitted transitions/ownership in one table and extract
legacy/modern policies behind a capability-selected route. Initially preserve
all transitions and output traces exactly. No protocol rewrite or feature removal.

**Expected benefit:** Easier review and fewer accidental overlaps during future
features; smaller modern hot path.

**Tradeoffs/risks:** Refactoring cancellation/recovery order is high risk. Keep
existing trace fixtures and compare both implementations before switching.

**Effort:** Large. **Priority:** 2 after context snapshot. **Disposition:** Proposed
only; independent of v2.

### P3 — Atomic Lua context replacement

**Discovery:** Lua removes the destination before renaming its temporary file;
AHK compensates with immediate retries and a bounded uncertain-context pause.
The gap is explicit in source; its real duration is not measured here.

**Evidence:** libs/controller/personal_controls.lua:update 40–52;
personal_controls.ahk:PersonalContext 328–359;
personal_gestures.ahk:PersonalLeasePause 5–7. libs/windows_file.lua already
provides Windows-focused file infrastructure elsewhere in the addon.

**Proposal:** Investigate reuse of the existing Windows replacement primitive
for complete context snapshots, retaining old invalidation semantics on failure.
Keep the uncertainty/neutral barriers until fault tests prove they are still safe.

**Expected benefit:** Fewer missing-file observations and less recovery churn.

**Tradeoffs/risks:** Windower FFI availability, sharing modes and replacement
failure behavior; no assumption Windows rename is sufficient.

**Effort:** Medium. **Priority:** 3. **Disposition:** Proposed only; independent
of v2. Do not remove recovery based solely on successful replacement.

### P4 — Bound retained history and mailbox bytes

**Discovery:** Pending stream events are bounded at 96 and time-limited at
350ms, while receiver bytes cap at 8192. Each flush rebuilds pending rows. The
client registry caches retired records but still enumerates every historical
INI at 250ms cadence. No limit violation or measured slowdown demonstrated. The required v2
OrderedInputMap helper also creates sorted snapshots to preserve v1 key order;
its per-poll allocation cost has not been profiled.

**Evidence:** controller_messages.ahk:ControllerMessageFlush 103–122 and Poll
200–218; libs/controller/messages.lua:accept 54–57; controller_clients.ahk:
WrapperClientsShouldExit 21–97 (retired cache at 38–68).

**Proposal:** Add byte-budget invariants/tests for worst-case sequence fields;
measure registry size/cost. Consider archive/compaction of safely retired
sessions outside the input loop, preserving diagnostic history and live owners.
Avoid a queue rewrite unless profiling justifies it. Profile the ordered-map
helper too; an explicit ordered ownership container might preserve the same
order with fewer temporary allocations, if the cost is material.

**Expected benefit:** Predictable resource growth and less historical work.

**Tradeoffs/risks:** Premature cleanup can hide shutdown evidence or remove a
live registration; serialized-row caching needs correct acknowledgment trimming.

**Effort:** Medium. **Priority:** 4. **Disposition:** Proposed only; independent
of v2; theoretical performance opportunity with demonstrated growth pattern.

### P5 — Diagnose last-client shutdown in isolation

**Discovery:** The cumulative testing record reports released owner handles
with the wrapper still running. Static replay passed, so the live cause is not
established. This is a demonstrated user-visible problem, not a diagnosed bug.

**Evidence:** TESTING.md “Shutdown Trace 1”; controller_clients.ahk:
WrapperClientsShouldExit, WrapperOwnerAlive, WrapperClientsDecision;
ffxi_directinput.ahk:TransportPoll/TransportExit.

**Proposal:** Reproduce with one isolated Windows client/registration and capture
the final internal decision/status before any restart. Native owner-handle
integration tests should cover release, access-denied, missing record, process
crash and reload. Change the decision only after its blocker is identified.

**Expected benefit:** Reliable cleanup and fewer stale processes.

**Tradeoffs/risks:** A speculative timeout could kill a minimized or uncertain
live client. Preserve fail-live ownership behavior.

**Effort:** Medium investigation. **Priority:** 1 for a focused bug investigation,
parallel in scheduling with performance work but a separate code batch.
**Disposition:** Proposed only; independent of v2. October 30 update: user
reports last-client shutdown now seems reliable. No new cause/fix is established;
retain historical evidence and investigate only if the symptom recurs.

### P6 — Observable snapshot-write failures

**Discovery:** Controller stream sets CM.error and retries; native-bank return
values and routine status/trace writes have different feedback surfaces. v2
exception handling prevents interpreter exceptions but does not unify diagnosis.

**Evidence:** controller_messages.ahk:ControllerMessageFlush 103–122;
personal_controls.ahk:PersonalL1Event; ffxi_directinput.ahk:
WriteTransportStatus, InputTraceFlush, PublishControllerFile.

**Proposal:** Add bounded error-kind/count/last-code fields to the existing unified
capture, plus recovery time. Keep routine chat quiet and do not add per-poll logs.

**Expected benefit:** Distinguishes sharing violations, path failures and output
backlog without another diagnostic subsystem.

**Tradeoffs/risks:** Diagnostics must not generate recursive writes or change
retry cadence. File error capture should occur immediately after failure.

**Effort:** Small. **Priority:** 2 for observability, separate from route refactor.
**Disposition:** Proposed only; independent of v2.

### P7 — Consolidate timeout ownership, retain distinct guards

**Discovery:** 100ms sender uncertainty, 350ms sender backlog and Lua watchdog,
2s recovery and 2.5s legacy fallback look redundant but protect different stages.
Native key acks add another independent owner lifecycle.

**Evidence:** controller_messages.ahk:Poll 134–218; libs/controller/messages.lua:
watchdog 47–51 and reset 24–32; personal_controls.ahk:PersonalNativePoll.

**Proposal:** Name these constants and document one state/ownership matrix with
boundary tests. Only combine guards if traces demonstrate equivalent ownership
and failure handling. Do not increase or decrease timeout values in that batch.

**Expected benefit:** Simplifies reasoning without weakening fail-safe behavior.

**Tradeoffs/risks:** Mistaking heartbeat freshness for event acknowledgment can
replay actions or sustain stale holds.

**Effort:** Small/medium. **Priority:** 2 documentation/tests, later behavioral
changes only with evidence. **Disposition:** Proposed only; independent of v2.

### P8 — Capability-isolated legacy modules

**Discovery:** Legacy .l1 mailbox/keyboard shortcuts, R1-menu shortcut and modern
bank/native service coexist; TrustMovement leases remain a fallback. These are
still supported and cannot be deleted in a faithful migration.

**Evidence:** personal_controls.ahk:PersonalPoll 110–225, PersonalL1Lease
384–417, PersonalL1Event 427–451; movement_signal.ahk:MovementReceiverReady
58–108; libs/controller/personal_controls.lua:update payload.

**Proposal:** Move legacy policies to explicit optional modules selected at
startup/negotiation; retain protocol compatibility and regression coverage.
Retire paths only after inventorying actual supported installation combinations.

**Expected benefit:** Smaller modern controller surface and clearer dependencies.

**Tradeoffs/risks:** Incorrect capability detection could strand older receivers
or ordinary controller profiles; does not inherently reduce latency.

**Effort:** Medium/large. **Priority:** After P2. **Disposition:** Proposed only;
independent of v2.

### P9 — Share hardware-neutral launcher utilities

**Discovery:** XInput DLL discovery, process identity/version checks and stable
client enumeration are useful outside XIVCrossbar; gameplay policies are not.

**Evidence:** ffxi_directinput.ahk:InitXInput 328–347, AcquireWrapperMutex;
personal_controls.ahk:PersonalClientTarget; launch-controller.ps1 discovery.

**Proposal:** Extract only small tested hardware/process utilities into independent
v2 modules when the Vana’diel Launcher exists. Each app owns its own process and
lifetime; no controller dependency on launcher startup or health.

**Expected benefit:** Reuse and maintainability; consistent interpreter discovery.

**Tradeoffs/risks:** Shared-version coupling and premature abstraction. Windows
focus policy and FFXI context remain app-specific.

**Effort:** Small/medium. **Priority:** Last, driven by concrete reuse.
**Disposition:** Proposed only; independent of this migration.

## Smallest next batch

P1 is implemented separately as Context Poll 1 and awaits live acceptance.
After that validation, P6 (bounded write-failure details in unified capture) is
the smallest observability batch worth considering. Last-client shutdown is now
reported reliable; retain P5 for recurrence, not an assumed active bug. Do not
bundle route refactoring, transport replacement, legacy removal or launcher
integration into either batch.
