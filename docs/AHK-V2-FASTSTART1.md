# AHK v2 Fast Start 1 — October 30, 2026

Personal development/ahk-v2-migration only; overlay on AHK v2 Test 1, with or
without Startup Fix 1. Runtime Lua label: directlink1-ahkv2-faststart1.

## Behavior

Normal controller start now asks Windower Run to launch the saved, verified
AHK v2 executable directly with the wrapper script and selected arguments.
CMD and PowerShell are not part of that path. The existing profile/device/
modifier handoff file is still written before launching; argument-loss recovery,
shared-instance mutex, existing-wrapper reuse and stop coordination remain.

Existing installations can seed the cache from controller-status.ini's actual
v2 runtime identity, including its stopped status. No freshness/permission is
inferred for game input: that old status only identifies the executable. The
executable must still exist, its recorded version must be v2.0.19+ and its path
must agree with an explicit controller-runtime.ini override if present.

Discovery is now exceptional. On a fresh installation without a usable identity,
a changed override, or a missing/size-changed executable, the existing bootstrap
runs and validates v2. It writes data/controller-runtime-cache.ini with a bounded,
complete snapshot before launching. Later starts use that cache. Its native
Program Files/32-bit-parent correction remains included. Cold discovery can
still show the temporary command window; ordinary cached starts do not use it.

Cache contains protocol/path/version/size and END, with bootstrap bitness when
written by PowerShell. Lua checks completeness, version, absolute executable path,
current file size and override agreement. Cache validation uses small file reads
and an executable seek, not another process. AHK's existing #Requires v2.0.19+
remains the final interpreter check if a binary is replaced in place. Discovery
performs product/version verification; cache reads reuse that prior verification
rather than repeating Windows version-resource inspection on every start.

## Files

- xivcrossbar.lua: use runtime launch plan and identify this build in the version.
- libs/controller/runtime.lua: cache/status/override validation and quoted direct
  command construction, with existing discovery fallback. Stock Lua; no FFI.
- launch-controller.ps1: save its verified runtime identity before launch. Cache
  persistence failure does not prevent the current verified bootstrap launch.
- tests/controller_runtime.lua and ahk_v2_launch.lua: actual resolver/root function
  scenarios under stock Lua.
- tests/controller_runtime_windows.py and ahk_v2.ps1: run production Lua against
  real Windows cache/status/executable files, then execute its direct launch plan.
- CI uses pinned Lupa 2.6/Lua 5.4 only as a test dependency. It is not required or
  included in the addon runtime.

No AHK controller input file, mailbox protocol, bank, key mapping, polling/gesture
constant, native input ownership or Trust policy is changed. No user settings,
icons or character files are supplied. This patch includes the prior startup
fix in its PowerShell file.

## Install

1. Stop the shared wrapper once with //xb controller stop. Wait for stopped status.
2. Unload XIVCrossbar in every client with //lua u xivcrossbar. Preserve a backup
   of the current addon code before overlaying.
3. Overlay the supplied xivcrossbar folder onto Windower/addons/xivcrossbar.
   It contains the changed Lua/PowerShell files and documentation, not userdata.
4. Load one client with //lua l xivcrossbar, then load the others. Confirm version
   directlink1-ahkv2-faststart1 and a running AHK v2 PID.
5. Stop/start once with //xb controller stop and //xb controller start. Normal
   startup should have no command window. Check triggers/faces/menu/focus behavior.

Your previously launched v2 wrapper normally supplies enough status to use the
fast path immediately after this upgrade. A fresh install can require one
bootstrap discovery. Keep controller-runtime.ini for custom interpreter paths;
changing it intentionally revalidates that executable once.

## Rollback / live acceptance

Stop the wrapper, unload all clients, restore xivcrossbar.lua and
launch-controller.ps1 from the previous v2 installation, then reload. The new
runtime module/cache can remain unused; no existing settings need restoration.
Do not restore v1 AHK scripts for this v2 startup-only rollback.

Native CI checks both x86 and x64 AHK and real 32-bit discovery. The direct
executable tests use the production Lua plan and actual Windows process startup,
with spaces in paths. They do not execute Windower's Run plugin. Final in-game
Run parsing/quoting, visible-window behavior and perceived delay await live
confirmation. CI timings are observations, not a promised startup deadline.

## Verified checkpoint

Runtime/test source 0317eed249299369b2018da1e18e9de9b87346e4 passed both
native architecture jobs in
https://github.com/rerorriM-Mirrorer/xivcrossbar/actions/runs/41117495125 .
Direct-plan status observations were 59ms and 74ms in that run. Full local
regression: 76 Lua suites, 167 normalized source parses, eight translated
AHK equivalence suites, structural/dependency/layout and whitespace checks.
User-facing Windower/physical-controller acceptance remains pending.
