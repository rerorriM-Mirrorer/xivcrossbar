# AHK v2 Fast Start 3 — October 30, 2026

Personal development/ahk-v2-migration cumulative startup overlay. Lua version
ends in directlink1-ahkv2-faststart3. Requires the existing AHK v2 Test 1 install.

## Confirmed observation

User reports approximately four seconds and a command window on startup.
Supplied status-Cioara.log identifies Fast Start 2, cache-selected direct launch,
fallback=true and a ready AHK 2.0.31 wrapper. Thus a direct attempt was not
confirmed within the one-second window and the CMD/PowerShell fallback ran.
It does not establish exactly which Run-parser step failed, or exclude a slow
first process subsequently losing the singleton race. Normalizing separators
in Fast Start 2 did not establish the desired live fast path.

## Change

During verified discovery, launch-controller.ps1 creates a Windows Shell shortcut
at data/controller-start.lnk. TargetPath is the explicit verified v2 executable;
Arguments contains /ErrorStdOut and the quoted wrapper path; WorkingDirectory
is the addon directory. No .ahk association is consulted. Windows scripting host
is not used to launch the shortcut; PowerShell uses its WScript.Shell COM object
only during setup to create it. No VBScript, native helper binary, FFI or launcher
application dependency is added.

Run now receives only:

    run addons/xivcrossbar/data/controller-start.lnk

No spaced executable name, embedded quotes or script arguments cross Run's
parameter parsing. The wrapper reads the existing controller-launch.ini handoff,
which Lua updates before each launch, so profile/device/modifier remain dynamic.
The shared installation mutex, client lifecycle, explicit stop and fallback
policies are retained. No AHK input source/protocol/timing or personal data changes.

Cache protocol ahk-v2-link1 records interpreter version/size, addon directory and
shortcut size. Old caches, missing/changed shortcut, moved install, changed
interpreter or override require discovery again. Stopped v2 status cannot create
a Shell shortcut, so it no longer seeds a direct launch on upgrade. Shortcut
creation failure is recorded in controller-launch-error.log and does not prevent
the existing verified bootstrap from launching AHK. Filesystem size checks are
cache invalidation, not a cryptographic integrity guarantee.

Existing one-shot startup confirmation/recovery remains. Diagnostics include the
shortcut path. Actual Windower acceptance is still required: opening .lnk through
Windows Shell tests that boundary, not the user's Run-plugin build.

## Install and live acceptance

1. Stop the wrapper; unload XIVCrossbar on all clients. Back up previous code.
2. Overlay this ZIP's xivcrossbar folder onto Windower/addons/xivcrossbar.
3. Load the addon and verify ahkv2-faststart3. The first start must use discovery
   once to create the new shortcut/cache; expect the command window this once.
4. After ready, //xb controller stop. Wait for stopped, then //xb controller start.
   This second start should open the shortcut without CMD/PowerShell or fallback.
5. Repeat stop/start, reload clients and test input, focus changes and multibox
   ownership. The selection should still match PS5 Extended/device 1/apps or your
   selected profile. Never test holds across a deliberate stop.
6. If the second start still shows a window or fails, save //xb controller status
   details and include Windower console errors plus controller-launch-error.log.
   Double-clicking data/controller-start.lnk is a separate Shell-boundary check;
   stop the wrapper before using that check.

Runtime overlay: xivcrossbar.lua, libs/controller/runtime.lua,
launch-controller.ps1. README/WORKFLOW/TESTING and this guide are included. No
user INIs/cache/shortcut or character assets are distributed. The installer
creates its own machine-specific shortcut; it is never packaged from CI.

Rollback: stop/unload all clients, restore the previous three runtime files,
reload. The older bootstrap will replace startup cache as needed. To revert the
entire migration, use the separate original v1 rollback instructions/package.

## Verification

See TESTING.md for the final results and tested source checkpoint. Stock Lua
simulates filesystem/cache conditions and executes root launch/recovery functions.
Native Windows tests create and inspect the shortcut, open it through Shell,
observe the real AHK process reading launch-file selection, then stop it. Native
AHK policy/lifecycle/bootstrap tests run on x86 and x64. No physical controller,
FFXI session or current Windower Run invocation is claimed by those checks.

Verified runtime/test source: 9bb25ccfdaba4abbb06d3f627904be9a9b36dca8.
Both architectures passed the full native matrix in run 41128814781, after an
unchanged rerun of one x86 cold-discovery timeout. Shortcut execution itself
passed on both original jobs. See TESTING.md for the retained failure detail.
All 76 Lua suites / 167 parses and eight translated AHK suites also passed.
