# Controller Timing 1 — October 20, 2026

This diagnostic build starts paired AHK/Lua traces with the existing controller
trace command. It changes observation, not routing, repeat policy, thresholds or
timeouts. Starting baseline: development/directlink 28304f4 (Cleanup 1).
Runtime directlink1-timing1; shared Controls 9.11-timing1.

## Install

1. Back up the existing xivcrossbar folder. Run `//xb controller stop`.
2. Unload XIVCrossbar in every client: `//lua u xivcrossbar`.
3. Merge this cumulative code-only update into the existing xivcrossbar folder.
   Keep data, settings, bindings and artwork. No cleanup helper run is required.
4. Load XIVCrossbar in each client: `//lua l xivcrossbar`.
5. With controls released, run `//xb controller start` once per computer.
6. `//xb inputstatus` should include directlink1-timing1;
   `//xb controller status` should include Controls 9.11-timing1.

## Capture one native-menu occurrence

Use one character for each capture; the shared wrapper has one trace at a time.
Leave the usual clients/addons running. Keep existing input settings unchanged.
Turn chat tracing off (`//xb inputtrace off`) to avoid adding chat output load.
Open an auction/inventory or other native menu where the problem occurs.
Start `//xb controller trace on` shortly before testing; the Lua trace starts in
that character too. The wrapper captures 30 seconds and Lua 31 seconds to cover
the request-poll offset. Both append to their existing logs.

For about 15–20 seconds, make separated short Up/Down taps, then a deliberately
held direction and release, then several quicker taps. Never confirm a sale or
purchase merely to test; use navigation and cancel normally. If a selection
moves again after release, note the direction and approximate seconds since
starting. Stop early with `//xb controller trace off` or wait at least 32 seconds.

## Capture the addon menu separately

Start another `//xb controller trace on` in the same character. Open the Options
chooser, make quick directional taps, and try the trigger page turns in the
ordinary addon editor as usual. Note any chooser closing while Options stays
held or page turn not taking. Stop or wait as above. Do not start another trace
until the preceding one has stopped.

## Send back

- `xivcrossbar/data/controller-input-trace.log`
- `xivcrossbar/data/controller-lua-trace-<character>.log`
- A brief note: character, menu, tap versus hold, direction, approximate point
  in the capture; whether a shoulder/trigger/Options was also held. State USB
  versus Bluetooth. A short screen recording is optional if easy.

No separate inputtrace or character chat log is required for this build. After
capture tracing is off automatically. The logs append; do not delete them.

## What this can establish

AHK records actual poll start gaps, elapsed named stages, context-file reads,
button-file writes over 10 ms, raw/routed masks and existing output/reset events.
Stage times include OS scheduling pauses; they are not CPU-time measurements.
Lua records timestamped received sequence/button edges, writer heartbeat,
router context, native setkey requests, cancellation and update gaps. Sequence
numbers join the logs; Lua uses epoch seconds while AHK uses monotonic ticks.
Writer heartbeat is a batch timestamp, not the physical event timestamp.
A setkey request is not proof of when FFXI applied it or which option was selected.
Use the note or recording for the visible effect. Log buffering reduces I/O
while measuring but diagnostics can still add overhead.

Lua is capped at 256 KiB and flushes on stop/deadline/unload. A process crash can
lose the buffered Lua capture; do not unload or crash clients deliberately.
A failed save is reported in chat. Only the initiating character's Lua is traced.

## Rollback

Stop the wrapper, unload XIVCrossbar in all clients, restore the backed-up code
and load again. Start the previous wrapper once with controls released. This
build does not migrate settings or change saved bindings.
