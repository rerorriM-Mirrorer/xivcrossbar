# AHK v2 Startup Fix 1 — October 30, 2026

Personal migration branch only. Install on the existing AHK v2 Test 1 build.

## Observed failure

User reports the Lua label directlink1-messagecleanup2, wrapper state stopped,
connected off, and no triggers/faces. Manual launch from an open command window
later starts the wrapper, while //xb controller start does not. Supplied
controller-launch-error.log contains three failures to discover AHK v2.0.19+.
Manual start was reported; live input acceptance after that start is not yet
confirmed. The log does not record the failing parent process bitness.

## Correction

Windower/Run is a 32-bit launch path. ProgramFiles can resolve to the x86 root;
ProgramFiles(x86) then searches the same root again, missing an AHK installation
in native 64-bit Program Files. The launcher now checks ProgramW6432 first,
then the prior ProgramFiles and ProgramFiles(x86) locations. Explicit
controller-runtime.ini overrides retain their existing precedence and validation.
No .ahk association fallback or elevation request is added. Discovery failures
now record bootstrap bitness and the exact checked executable paths in the
existing controller-launch-error.log.

Only launch-controller.ps1 changes at runtime. Lua, AHK input functions,
profiles/devices, gesture windows, mailbox protocol and personal data are unchanged.

## Install and try

1. Use //xb controller stop to stop any manually launched shared wrapper.
2. Back up addons/xivcrossbar/launch-controller.ps1, or retain the Test 1 ZIP.
3. Overlay this patch's xivcrossbar folder onto Windower/addons/xivcrossbar.
   Only the PowerShell bootstrap and documentation are supplied. No data or
   controller-runtime.ini is installed or overwritten. The addon can stay loaded.
4. Use //xb controller start from FFXI. Confirm fresh status reports a running
   PID, ahk_major=2 and the intended profile/device. Release buttons before input.
5. Test trigger/face and menu behavior. If startup still fails, send the newest
   controller-launch-error.log and controller-status.ini. New discovery failures
   include launcher bitness and attempted executable paths.

Rollback: stop the wrapper, restore the backed-up launch-controller.ps1 from
AHK v2 Test 1, and start manually or use a valid absolute executable override.
No game or Lua restart is required just to restore this bootstrap file.

## Verification scope

Native regression uses actual SysWOW64 CMD -> 32-bit Windows PowerShell with
ProgramFiles pointing at an empty x86 root and ProgramW6432 pointing at a native
root containing the pinned AHK executable. No explicit runtime INI override is
present. It asserts the launch host really is 32-bit, the discovered executable
comes from native Program Files, and the wrapper starts and stops. This test
reproduces the original failure before the correction. Both x86/x64 AHK runtimes
are checked by the CI matrix, alongside the existing native policy/startup tests.

This isolates the demonstrated discovery mechanism; the user's actual Windower
handoff and controller operation still require their live confirmation.

Native result: old-source regression failed in run 41114765906. Runtime fix
88c3041baec687cad3a6844f4364fa389dcdda88 passed both matrix jobs in
https://github.com/rerorriM-Mirrorer/xivcrossbar/actions/runs/41114905686 .
Local structural/dependency/layout checks and eight translated v1/v2 comparison
suites passed. No Lua or AHK input source changes were made in this patch.
