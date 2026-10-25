# Windower Patch Installer 1 — A — October 24, 2026

Runtime directlink1-installer1 / Controls 9.19-lifecycle1. User explicitly chooses
manual client reload; no background downloading, watcher, remote control or reload
is added. Current scope: XIVcrossbar code/docs, existing Cleanup 1+ installation.

Kit layout: WindowerPatch.cmd, WindowerPatch.ps1, INSTALLER-README.md and
WindowerPatchSupport/bootstrap containing a manifest and cumulative addon files.
No nested ZIP. Extract once to Windower root beside Windower.exe/addons; payload
stays outside the live addon until the launcher applies it. First use requires
manual unload because old clients lack the request receiver. It installs this
receiver with all preceding cumulative fixes. Later double-click chooses a ZIP
from Downloads, or drag a ZIP onto CMD. Reload clients yourself after success.

The PS helper validates/stages paths, versions and manifest hashes (or recognised
legacy PATCH-INFO layout), rejects userdata/artwork/unsupported files, waits for
all owner handles, uses the existing explicit wrapper-stop request and waits for
PID exit. It neither kills other AHK processes nor depends on auto-shutdown being
fixed. Open XB menus defer unload; nonresponding/minimized clients may require
manual unload. Timeout/malformed package aborts before code replacement.

Timestamped runs retain affected original files, journal and install-report.json,
including requested/installed source, hashes/count, initial owners and received
session/character/version acknowledgements. Code writes use temporary replacement
and verification; caught failures restore changed files/remove new ones. Settings
and artwork stay in place. Identical files skip writes. Download deletion is
offered only after success, default Keep (explicit -DeletePackage opts in).
Power loss/forced termination may need manual backup restoration; no recovery UI
or backup expiry is claimed. Installer files themselves are updated by extracting
a future kit, not by copying arbitrary scripts from an addon ZIP.

Automated checks: real PowerShell 7.4.6 on Linux tests actual extraction/validation,
manifest/legacy compatibility, traversal/duplicate/unsupported/tampered rejection,
backup/idempotence, injected failure rollback for existing/new files, real owner
file lifetime, stopped/invalid wrapper status, request/ack protocol, real child
CLI install/bootstrap/report/receipt and success-only ZIP deletion. Initial
tests exposed PowerShell null-string binding in File.Replace (use NullString),
then a Linux fixture's missing process executable path (use PSHOME); corrected,
reran successfully. Lua receiver validation/controller routing tests are separate.
All 71 Lua suites / 160 parses and 8 JS suites pass; AHK/dependency checks pass.

Live Windows acceptance still required: CMD drag/drop/path quoting, file picker,
Windows PowerShell 5.1/BCL, native file ownership, actual two-client unload/menu
deferral and wrapper stop. Test first with clients idle and menus closed. Confirm
installed version and manual reload; next update test with an open XB editor
should wait rather than discard it. Reapply an identical patch, then check report
and kept backup. Send install-report.json for any failure. Native tests are not
implied by Linux PowerShell or simulated AHK passes.

Source helper usage and Microsoft API reference: tools/windower_patch/README.md.
Package builder: tools/build_windower_installer.py takes committed revision,
published commit and output path; verifies members against source and manifests.
