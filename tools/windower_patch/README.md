# Windower Patch — A — first XIVcrossbar installer trial

Keep `WindowerPatch.cmd`, `WindowerPatch.ps1` and `WindowerPatchSupport` together
in the Windower root, beside Windower.exe and the existing addons folder.
Windows PowerShell 5.1 runs the launcher; no Python or compiled EXE is required.
This first version installs XIVcrossbar cumulative **code/docs** updates only.
It does not install Trust/other addons or edit/copy character XML, bindings or art.

## First use

1. Extract this kit into the Windower root. It places the bundled update under
   WindowerPatchSupport/bootstrap, not directly over the live addon.
2. Close XB editing menus and manually unload XB on all clients once. Older
   versions do not yet understand installer unload requests.
3. Double-click WindowerPatch.cmd. First run installs the included cumulative
   addon update and its future unload receiver. If the wrapper is still up,
   the installer sends the existing stop request and checks for process exit.
4. Read the installed version/result, then reload clients yourself when ready.
   Controls 9.19-lifecycle1 remains the companion version.

You need an existing XIVcrossbar Cleanup 1 or newer DirectLink installation;
this kit omits the addon's artwork and personal data. No administrator session
is requested by the launcher. If the existing folder is not writable, it reports
the error instead of changing permissions.

## Later downloaded patches

Double-click the launcher to choose a downloaded ZIP (the picker starts at
Downloads), or drag the ZIP onto WindowerPatch.cmd. It stages the selected ZIP,
checks its layout/version, requests graceful unload, waits for owner release,
stops the shared wrapper, backs up affected files and installs/verifies the update.
Open XB menus/editors defer unloading; close them to continue. A minimized or
nonresponding client may require manual unload. Timeout aborts before code writes.
Reload clients manually afterward. There is no background Downloads watcher.

The launcher recognises our xivcrossbar/ cumulative code ZIPs with PATCH-INFO.txt,
and schema-1 windower-patch.json manifests. New manifests verify SHA-256 for each
payload file. Legacy ZIPs are layout checked and hashed for backup/install parity;
these checks do not establish the publisher's identity or replace choosing the
intended package. Individual settings/artwork/full-addon ZIPs are rejected.

Only after successful installation does it offer to delete the selected downloaded
ZIP; default is Keep. `WindowerPatch.cmd -Package "C:\path\patch.zip" -DeletePackage`
opts into deletion after success. Failed installs keep the download. Original
files, file journal and JSON install report live in timestamped
WindowerPatchSupport/runs folders. Identical files are skipped. Caught write/hash
failures restore already changed files and remove newly added ones. A power loss
or forced termination may require restoring from that backup; this version has
no interactive recovery wizard. It never reloads clients or cleans old backups.

## Live acceptance and reports

Windows file picker, CMD drag/drop, actual Windows PowerShell 5.1, Windower menu
deferral/unload and AHK process stop still need native testing. Core PowerShell
tests run under PowerShell 7.4.6 on Linux using real temporary ZIP/filesystem
operations; Lua and controller checks are separate. Treat this as an installer
trial, not a live-proven installer. Do not apply a package during an open edit.

If anything fails, send the install-report.json path printed by the launcher.
The report includes requested version/source, changed-file count and backup path;
it does not claim clients reloaded or verified live until you do so yourself.

The unload receiver accepts only a fresh local unload request, not arbitrary
commands. Its first installation is the only manual-bootstrap step. No extra
gameplay/controller blocking is introduced. Ordinary wrapper auto-shutdown remains
an independent investigation; the installer uses explicit stop rather than
depending on that unresolved behaviour.

Implementation references: [Microsoft ZIP extraction](https://learn.microsoft.com/en-us/dotnet/api/system.io.compression.zipfileextensions.extracttofile?view=netframework-4.8.1).
