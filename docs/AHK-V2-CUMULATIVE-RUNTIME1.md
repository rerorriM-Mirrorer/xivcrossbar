# AHK v2 Cumulative Runtime 1 — October 31, 2026

This is a cumulative runtime overlay for the personal DirectLink development
installation, not a complete fresh addon with art/dependencies. It includes the
full v2 wrapper and every AHK include, plus all launch changes through Fast
Start 3, Touch Fix 1 and Context Poll 1. No new behavior change is introduced.

The reported Loop, 14 at controller_messages.ahk:97 is v1 syntax. The current
published v2 file says Loop 14. Later small patch ZIPs assumed the original full
v2 migration was already present, so applying them over a v1 copy can leave an
incompatible include behind. Replacing only that comma is not a complete repair.

## Install into the installation that reported the error

1. Exit any running controller wrapper. Unload XIVCrossbar on all clients using
   this Windower installation and back up your existing addon code.
2. Merge this ZIP's xivcrossbar folder into:

       D:\FFXI Setup\FFXI\Windower\addons\xivcrossbar

   Replace supplied code files. Do not place it inside a second nested
   xivcrossbar folder. Earlier logs used a different C: Windower location;
   updating that location alone will not change the file in this D: error.
3. Leave data, config.ini, bindings, icons, themes and other personal files in
   place. No user data or machine-specific cache/shortcut is in this package.
4. Load XIVCrossbar and use //xb controller start if it is not already started.
   Missing or outdated startup metadata can require one bootstrap/setup launch.
5. Verify //xb controller status details identifies ahk_major=2, expected
   profile/device and ready/connected after login. Extended-profile captures also
   contain context_poll_protocol=1. Lua version remains ahkv2-faststart3.
6. Confirm no include parse error, then test triggers, touchpad, menu controls,
   focus switching and other clients. If another error appears, include its
   complete filename/path and the unified diagnostic.

## Payload

- ffxi_directinput.ahk
- controller_messages.ahk
- personal_controls.ahk
- personal_gestures.ahk
- controller_clients.ahk
- movement_signal.ahk
- tools/keyprobe/keyboard_probe.ahk (optional probe, migrated to v2)
- xivcrossbar.lua
- libs/controller/runtime.lua
- launch-controller.cmd and launch-controller.ps1
- README.md, WORKFLOW.md, TESTING.md and the migration/testing/audit guides

The six active controller files are one matched runtime. The probe is not
started automatically. The manifest identifies committed payload bytes.

The existing Windows x86/x64 native pass covers this runtime, including parse,
policy/context tests, startup/stop/duplicate protection, shortcut launch,
bootstrap/restart and discovery. This repackaging does not claim a new native or
physical test. The user's complete D: installation has not been inspected.

Rollback: stop/unload and restore the complete prior code backup. For v1,
restore the separate v1 rollback as a coherent runtime; never mix active v1
includes into the v2 wrapper. See docs/AHK-V2-MIGRATION.md for that procedure.
