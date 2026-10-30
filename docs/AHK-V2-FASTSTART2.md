# AHK v2 Fast Start 2 — October 30, 2026

Personal development/ahk-v2-migration. Cumulative startup overlay for AHK v2
Test 1 with or without Startup Fix 1/Fast Start 1. Version ends in
`directlink1-ahkv2-faststart2`.

## Evidence and correction

The supplied cache identifies AHK 2.0.31 at the expected Program Files path,
with native Windows backslashes, complete END and size 1284608. The status
identifies that same v2 runtime, PS5 Extended/device 1, and a stopped process
with clients_reason=exit-requested and zero loaded clients. This is an earlier
clean last-client exit, not evidence of a startup crash. The actual current
Run-parser failure still needs live confirmation.

Fast Start 1 preserved the cached native path verbatim when emitting its Run
command. Its static fixture used forward-slash paths, and native Windows tests
launched the returned executable/arguments directly, bypassing Windower's parser.
A new fixture with the supplied native-cache/spaced-addon-path structure fails
the desired command-boundary assertion before this correction.

Native paths remain intact for filesystem checks, cache identity and explicit
runtime overrides. Only paths emitted into Windower's command string now use
forward slashes. The script path is normalized as well. This retains the fast,
explicit v2 launch. No cache deletion or interpreter reinstall is needed.

Upstream context: Windower/Issues #676 records a historical backslash-path
failure and forward-slash workaround, and was closed in 2024 as working. That
report supports avoiding this unnecessary parser dependency; it does not prove
that every current Run build fails in the same way:
https://github.com/Windower/Issues/issues/676 . A first-argument-only forwarding
hypothesis was not established and no argument layout change is made here.

## Startup confirmation and recovery

Direct start now schedules one nonblocking confirmation after one second, using
the existing fresh-running-status definition. If no wrapper is reporting running,
it requests the existing verified bootstrap once and reports that retry. This
one-second startup check is separate from input polling/holds/acknowledgments.
It does not delay a successful fast start. Bootstrap recovery can show the old
brief command window when direct launch fails.

A later start supersedes the old check; explicit stop cancels it; a confirmed
running wrapper or an already-used fallback cannot cause a repeated fallback.
The module supplies a validated canonical fallback command, including aliases.
No automatic retry loop is introduced.

The existing unified diagnostic snapshot now includes controller_launch:
requested time, initial command, mode/source, fallback command and confirmation/
cancellation/fallback flags. No new standalone diagnostic file or per-poll log.

## Install and test

1. Stop any running shared wrapper with //xb controller stop. Wait for stopped.
2. Unload XIVCrossbar on every client; preserve your previous addon code backup.
3. Overlay this ZIP's xivcrossbar folder onto Windower/addons/xivcrossbar.
4. Load one client, then the others. Verify version ahkv2-faststart2.
5. Try //xb controller start. Release controls and test triggers/faces/menu/focus.
   A successful direct start stays quick and quiet; a failed direct request
   should show a one-time retry notice and recover through the old bootstrap.
6. If it still fails, use //xb controller status details and send the saved
   diagnostic file from data/diagnostics. It now records the actual launch plan.
   Include any Windower console error; manual launch-controller.cmd still works
   as the independent recovery route.

Three runtime files are supplied: xivcrossbar.lua, libs/controller/runtime.lua,
and the current launch-controller.ps1 (which includes previous startup fixes).
No AHK input code, mailbox protocol, timing thresholds, bank settings, controller
bindings, icons, user INIs or cache files are distributed or overwritten.

Rollback: stop/unload all clients, restore the previous three startup files from
your code backup, reload. No character settings restoration is needed.

## Verification boundary

Stock-Lua tests execute the actual resolver/root launch functions with native
backslash cache and spaced addon paths, including v2.0.31 metadata. They verify
normalization, retained native identity, running success, exactly one recovery,
superseded attempts and actual stop-handler cancellation. Windows CI executes
production Lua against actual cache/status files and runs the selected v2 binary
on both architectures, also checking that no raw backslashes enter the Run text.
Neither native Windows process tests nor the historical issue substitute for
actual current Windower Run-plugin execution. Physical/game acceptance remains
pending; do not describe the emitted-command correction as live-proven yet.

Verified runtime/test checkpoint: ae7541788f4fc138c1216f1de6db78b1f266e500.
Both native architectures passed:
https://github.com/rerorriM-Mirrorer/xivcrossbar/actions/runs/41123505933 .
All 76 local Lua suites / 167 parses and eight translated AHK equivalence suites
passed. Complete historical observations remain in TESTING.md.
