# XIVCrossbar DirectLink — Unbound, Snapshot 1

Keyboard-free controller transport. Preserved October 16, 2026, America/Chicago.
Collaborative author: A.

## Identity and preservation

- Snapshot branch: `snapshot/directlink-unbound-20261016`. Preserve this checkpoint; do not use it for ongoing changes.
- Ongoing development: `development/directlink`.
- Exact live-tested runtime source: `7e0e25253aa7cb64451e1b3f18ef861b0a90726f`.
- Runtime remains `0.4.0-a.20261017.personal9-l1test6`; AHK remains `Controls=9.5-messages`.
- Snapshot documentation changes no executable code, defaults, artwork, saved data or controller behavior.
- Addon installation remains `xivcrossbar`; commands remain `//xb`, `//xcb` and `//xivcrossbar`.
- The public RC3 branch is unchanged. This snapshot is not a public release.

DirectLink is the continuing development name for the message-based line. The
Personal Test 6 identifiers remain in this first snapshot to preserve the exact
binary/text sources that were actually tested, rather than silently relabeling
an executable build.

## What Unbound means

AHK sends the twelve ordinary logical controller buttons as ordered messages.
Lua feeds them into the established native/menu/crossbar router. The active
message transport emits no Apps/F1–F12 keyboard signals and needs no gameplay
keyboard binding to carry those controller events.

Native gameplay outputs can still use Lua `setkey`. Personal L1/R1 shortcuts,
R3 targeting, touch/stick-click controls and Trust movement signaling keep their
existing paths. Legacy keyboard fallback and its reserved bindings remain
available through `//xb messages off`. Unbound describes the ordinary controller
transport; it does not claim all keyboard injection or every registered binding
has been removed.

## Live evidence preserved

Max reports that the controls work "exactly the same if not better."

The appended trace `controller-input-trace(1).log` contains an older recording
and a distinct new 30-second capture beginning 2026-10-17 04:48:22 UTC
(October 16, 11:48:22 p.m. Chicago), identifying `controls=9.5-messages`.
Only that new capture is evidence for DirectLink:

- 81 ordinary button-down messages, 80 button-up messages and two cancel messages.
- Zero `emit AppsKey` / `emit F1–F12` transport records.
- R2 `message down button=12` is followed by the reported Lua context changing
  from gameplay to crossbar.
- Franklet's latest status reports message mode configured true, active wrapper
  route messages, 706 events received, zero rejected and write error zero.
  Received is cumulative and includes protocol events; it is not a count of
  successful gameplay actions.
- The console records Personal Test 6 loading successfully at 23:39:43.
- The older wrapper source has neither the message queue function nor its trace
  record generation, so this evidence cannot be explained by running that
  unchanged old wrapper alone.

The `apps` field in Selected/Running status remains the configured keyboard
fallback modifier. `Button route=messages` identifies the active transport.
This wording is confusing and is a follow-up improvement, not a snapshot patch.

## Acceptance limits

This is a first live-confirmed development snapshot. It confirms that the new
transport operated during the user's test. It does not establish a measured
latency improvement or exhaustive acceptance of every bar, addon menu,
multi-client transition, disconnect, timeout, cutscene or low-frame-rate case.
The prior source/simulated checks and outstanding scenarios remain in
[TESTING.md](../TESTING.md). Preserve the supplied observations without turning
them into a blanket claim that every input issue is fixed.

## Historical development lines

| Line | How to identify it |
| --- | --- |
| Original Personal | Legacy Batch-era development before the public RC3 rebuild; historical packages/source, no newly invented Git ref |
| New Personal | RC3-based personal development; keyboard-first comparison checkpoint `f92c0b86f3d79de5542062ee9ad9d4027bbb3c46` (Personal 9 Test 5) |
| DirectLink — Unbound | Message-based continuation; this snapshot preserves the live-tested Personal Test 6 runtime |

`personal/ps5extended` remains at the Test 6 fork point as historical provenance.
Use `development/directlink` for future DirectLink work. See [BRANCH-MAP.md](BRANCH-MAP.md)
before editing any of these lines.

## Controls

`//xb messages on` selects DirectLink messages.
`//xb messages off` selects the retained keyboard transport.
`//xb messages status` reports the saved selection.
Bare `//xb messages` toggles. Return controls to neutral after a change.

This naming/preservation task needs no reinstall of the working runtime.
