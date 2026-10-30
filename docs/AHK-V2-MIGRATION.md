# Personal DirectLink AHK v2 migration

This is a testing branch, not a declaration of live controller equivalence.
Repository: rerorriM-Mirrorer/xivcrossbar. Branch: development/ahk-v2-migration.
Source checkpoint: ed86e5f36c435273b62332278ed08fcb82c2f27f, Controls
9.20-diagnostics1 / Lua directlink1-messagecleanup2. The most recent recorded
live acceptance is Survival Guide controls; last-client automatic shutdown
remains unresolved. Newer diagnostic/message work is not independently promoted
to a live-known-good state. Preserve the complete currently working installation.

## What changed

| File | Required conversion |
| --- | --- |
| ffxi_directinput.ahk | v2 directive, argument Array, function timer/exit callback, explicit globals for the former label body, Buffer/Ptr for XInput, epoch DateDiff, v2 file APIs, explicit SendEvent settings and runtime identity. InputState creates native sparse Maps; PublishControllerFile contains v2 file exceptions within existing retry policy. |
| controller_messages.ahk | Native Array queues, Map hold/sequence state, regex match objects, epoch conversion and exception-aware snapshot writes. Message vocabulary/order/limits unchanged. |
| personal_controls.ahk | Native Maps for key ownership/dictionaries, explicit record defaults, Clone preserving named hardware fields, dynamic property writes, guarded missing-item access/Delete, WinGetList and v2 window/key APIs. |
| personal_gestures.ahk | Audited; byte-identical. Already uses v2-compatible function/expression syntax. |
| controller_clients.ahk | Native Maps, v2 Files loops, exception-aware FileRead, explicit deadAt initialization, regex captures and DateDiff. Same owner-lock and last-client policy. |
| movement_signal.ahk | v2 SendEvent/ControlSend/window/file functions; HasOwnProp for axes, Map policies, match objects, same Send/Ready latch and threshold. |
| tools/keyprobe/keyboard_probe.ahk | Entire optional GUI uses v2 Gui controls/events, function timers/exit, native Map and paired-key cleanup. Default F15 choice retained. Not a runtime dependency. |
| launch-controller.cmd / launch-controller.ps1 | Independent bootstrap resolves a real v2 executable, checks product/version, quotes script path, passes validated arguments. No .ahk association dependency; missing Run arguments retain the existing Lua launch-file handoff. |
| xivcrossbar.lua | One launch target changed from ffxi_directinput.ahk to launch-controller.cmd. Routing/protocol/gesture code unchanged. |
| tests/ahk_source.js and eight JS suites | Test-only v2 source normalization for the existing narrow JS execution harnesses. Native v2 object/I/O semantics are checked separately on Windows, not inferred from these simulations. |
| tests/check_ahk.py | Update lexical/integration assertions to v2 syntax. This is not an AHK parser. |
| tests/ahk_v2.ahk / tests/ahk_v2.ps1 / tests/ahk_v2_launch.lua / tests/compare_ahk.js / .github/workflows/ahk-v2.yml | Actual AHK v2 policy/object tests and isolated Windows startup/mutex/stop/bootstrap/restart. Pinned official 2.0.19 ZIP with published SHA256. |
| README.md / TESTING.md / these docs / package builder | Requirements, cumulative verification status, native acceptance instructions, reproducible v2 overlay and separate source-checkpoint v1 rollback. |

## Preserved behavior and necessary interpreter differences

- Same 10 ms requested timer; no timer-resolution change. v2 has no SetBatchLines;
  v1 already selected -1, so neither version introduces batch sleeps.
- Explicit SetKeyDelay(10,-1) and SetWinDelay(100) retain v1 defaults. SendEvent
  remains SendEvent; no conversion to SendInput. Background ControlSend releases
  retain their former target and modifier vocabulary.
- UTF-8 is v2's default file encoding. CP0 is selected explicitly to retain v1
  mailbox/log bytes (the wire protocol itself is ASCII). No BOM is introduced.
- v1 missing sparse entries returned empty/released. Native v2 Maps use a false
  Default for button state; guarded Get/Delete handles absent ownership items.
  Fixed state records now explicitly initialize fields formerly read as blank.
  Arrays remain ordered queues. OrderedInputMap explicitly preserves v1 integer/ordinal-string acquisition and release order rather than Map insertion order. No v1 emulation class, transpiler, or interpreter
  is shipped in the active runtime.
- Regex captures are explicit match objects passed by reference. Buffer replaces
  a v1 raw string buffer; the XInput layout is still 16 bytes, with the same
  offsets and signed/unsigned types. Handles/function pointers remain Ptr.
- v2 file/window failures throw. File reads/writes and background releases catch
  the corresponding failures so existing uncertainty/retry/release bookkeeping
  continues. A failed DirectLink write still never falls through to keyboard.
- OnExit returns zero after cleanup, rather than recursively calling ExitApp as
  the v1 label needed. The handler registers after module initialization so a
  partial startup cannot read uninitialized v2 globals.
- Status adds ahk_major, ahk_version, ahk_path. Existing Controls marker remains
  9.20-diagnostics1; use the added runtime fields to identify this migration.
- The launcher requires Windows PowerShell (included with supported Windows),
  rather than an .ahk association. An unavailable/invalid v2 installation fails
  explicitly; it never falls back to v1. The #Requires directive also rejects v1.

All physical mappings, trigger >4 threshold, touch 500ms, key pulse 40ms,
movement .24 threshold/30ms release, 100ms lease uncertainty, 350ms backlog,
2s hold recovery, 2.5s legacy fallback, queue limits and event order remain.
Double-tap-and-hold stays in the unchanged Lua 500ms window. Ordinary profiles
retain their existing legacy Apps/Ctrl + F-key path; DirectLink profiles retain
messages without reintroducing those key signals.

## Install the testing overlay

1. In a loaded client, use //xb controller stop. Wait for the process to exit;
   Ctrl+Alt+F12 is the emergency script exit. Unload XIVCrossbar in EVERY client.
   If the old automatic shutdown fails, use the explicit stop before proceeding.
2. Copy the complete currently working addons/xivcrossbar folder outside addons.
   This is your live-known-good v1 rollback, including local modifications.
3. Install AutoHotkey v2.0.19 or newer stable v2. Keeping v1 installed is fine.
4. Overlay the testing ZIP's xivcrossbar directory on the personal installation.
   It supplies code/docs only; keep data, config.ini, icons, themes and bindings.
   Do not apply it to public beta/RC/master installations.
5. Standard discovery tries Program Files/AutoHotkey/v2/AutoHotkey64.exe then
   AutoHotkey32.exe, then the same paths under Program Files (x86). For a portable
   or custom install, create data/controller-runtime.ini yourself:

   [Runtime]
   executable=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe

   Use an absolute path to an actual v2 executable, without command arguments.
   A present invalid override fails instead of silently choosing something else.
6. Load one client with //lua l xivcrossbar, release all controls, then load the
   others. Use the same controller profile/device/modifier across these clients.
7. Use //xb controller status and //xb diagnostics. Check data/controller-status.ini
   for ahk_major=2, the expected ahk_path/version, profile, device, running PID
   and current phase. Failure details go to data/controller-launch-error.log.
8. Follow AHK-V2-NATIVE-TEST.md before considering promotion. Restart/stop remain
   the existing //xb controller start and //xb controller stop commands; profile
   commands coordinate stop/start. Only one shared wrapper should stay running.

Manual startup, if needed (PowerShell):

    & 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' '/ErrorStdOut' '.\ffxi_directinput.ahk' apps ps5-extended 1

## Rollback

Stop the v2 wrapper explicitly, unload every client, move the testing folder
aside, and restore the COMPLETE pre-install v1 backup. Load once, then load the
other clients. Its original Lua launch uses the original v1 association; select
v1 for that restored installation if an association changed. Preserve newer
bindings/data separately before restoring an older backup.

The delivery also contains a separate rollback ZIP of the exact six v1 runtime
files, original Lua entry point and docs from ed86e5f. Overlay it only on this
same checkpoint family, and remove launch-controller.cmd/ps1 afterward. That
source checkpoint preserves v1 code; it does not claim newer untested behavior
is live-known-good. A whole-install backup is preferred. The v1 files are never
mixed into the active v2 runtime directory or included as active .ahk siblings.

## Reusable launcher boundary

The controller remains a standalone program guarded by its existing installation
mutex. The bootstrap exits after starting it. Future launcher work can reuse
executable discovery, version checks and process identity as small utilities;
no launcher session, UI, IPC server or lifetime is required by XIVCrossbar.

## Verified results for Test 1

Actual Windows x86/x64 AHK 2.0.19 verification passed at runtime checkpoint
2bd4ed32ac4c35e080fce7fd8d694920c220b305 in
https://github.com/rerorriM-Mirrorer/xivcrossbar/actions/runs/41006074961 .
This covers native syntax/objects/policies, isolated startup/mutex/explicit stop,
production CMD/Windows PowerShell bootstrap restart and rejection of a non-v2
override, plus missing-argument launch-file fallback. It does not exercise Windower or attached hardware. Local checks:
75 Lua suites, 165 normalized Lua parses, eight v1/v2 translated equivalent
suites, AHK structural checks and dependency/layout validation. Early native
failures were isolated-harness setup/GUI invocation issues; corrected and rerun.
The complete pending game/hardware acceptance matrix is in AHK-V2-NATIVE-TEST.md.
