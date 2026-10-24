# Shutdown Trace 1 — A — October 24, 2026

Runtime directlink1-shutdowntrace1 / Controls 9.19-lifecycle1. Diagnostic addition
for the wrapper remaining up after the last XB unload. This batch does not claim
to fix shutdown; the last-client policy, owner checks, grace and input remain unchanged.
Includes preceding cumulative Scene Transition fixes.

Evidence: Franklet/Killala diagnostics both report stop_after_last_client=true,
registered=true, scene1 and the same wrapper PID 2168 / Controls 9.18. Uploaded
controller-clients.zip contains 36 INIs, all kill=true, 34 closing and two older
loaded records. Latest closes at 21:08:38.565453Z and 21:08:39.040634Z. Old loaded
records are not proof of live handles. Actual scan replay with all owner handles
simulated released exits after grace; real Windows PowerShell probe subsequently
reports All owner handles released while the user still sees the wrapper running.
Root cause is unresolved: internal state, native probe, path/runtime mismatch or
scan progress needs direct observation. Do not delete old registrations as a fix.

The wrapper's existing data/controller-status.ini now includes:

- clients_reason: waiting-for-scan, clients-loaded, no-client-observed,
  last-client-keeps-running, shutdown-grace or exit-requested.
- clients_seen / clients_loaded / clients_records / clients_scan_count / clients_scan_tick.
- clients_locked (Windows errors 32/33), clients_owner_errors (other non-missing
  errors), clients_invalid_records, and up to three blocking filenames/error codes.
- clients_last_close / clients_last_kill / clients_directory.

Counts reuse existing 250 ms scans; fields reuse existing one-second status
publication. Reading status performs no extra owner or file probes. No chat spam,
new timers, decision overrides or file cleanup. Existing //xb diagnostics captures
these fields too, but do not reload XB after the failed unload merely to collect it.

Install and reproduce once:

1. Explicitly stop the OLD wrapper with //xb controller stop while XB is loaded;
   then unload XB on all clients. Merge cumulative patch preserving data/artwork.
2. Reload participating clients and start the wrapper once neutral. Verify
   //xb controller status shows Controls 9.19-lifecycle1. Lua reload alone does
   not replace a running AHK process.
3. Unload XB on every client in this installation. Wait about three seconds.
4. If wrapper remains, send data/controller-status.ini immediately, before
   restarting/reloading/stopping it. This one file reports its own current view.
   Include whether the wrapper icon/process remains. No PowerShell repeat needed.

Available checks: actual AHK scan/decision/parser/status methods exercised through
narrow JS translation with mocked native I/O, including loaded/grace/exit/unseen,
invalid-live records, lock versus access-error counts, and no extra status probes.
Other controller simulation suites, AHK structure and Lua diagnostics/status checks
remain required. Actual Windows AHK execution and the shutdown cause remain pending.
