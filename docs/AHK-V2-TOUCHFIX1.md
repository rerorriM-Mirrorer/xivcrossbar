# AHK v2 Touch Fix 1 — October 30, 2026

Requires the existing native v2 migration; retains Fast Start 3 startup.
Runtime overlay contains personal_controls.ahk only.

User confirms Fast Start 3 loads faster than the old wrapper after setup. This
is live acceptance of startup on the user's setup, not the complete controller
matrix. Next physical touchpad use reports GetKeyState invalid parameter
vkC0sc029 at PersonalKey's physical-ownership guard.

Combined VK/SC strings are supported for sending but are not valid GetKeyState
names. This inherited call was retained during migration; v2 raises an exception.
Earlier native tests only evaluated the touch gesture result, and translated
keyboard tests accepted any query string. They missed this runtime API boundary.

PersonalPhysicalKey now queries sc029/sc033/sc034 for the touchpad and
comma/period stick-click identities. PersonalKey uses it for acquisition AND
release. Ownership-map identities and foreground/background SendEvent/ControlSend
strings retain their original combined VK/SC names. Ordinary key queries,
ownership, tap/hold thresholds and delayed release remain unchanged. No
catch-and-ignore or removal of physical-key protection. The user also reports
leftward camera spinning; a connection is plausible but not established.

Reference: official v2 key list, Special Keys, combined VK/SC restriction:
https://github.com/AutoHotkey/AutoHotkeyDocs/blob/v2/docs/KeyList.htm#specialkeys

Native tests call the production helper with all three combined identities and an ordinary
key under real v2. Translated ownership tests reject combined GetKeyState names,
verify exact down/up SendEvent strings for all three, and preserve physically held
scan codes. Remaining physical controller/live FFXI tap, hold, focus-loss and shutdown
acceptance must occur on the user's system.

## Install

1. Exit the errored wrapper using the error dialog's ExitApp or its tray Exit.
2. Overlay this ZIP's xivcrossbar folder onto Windower/addons/xivcrossbar.
3. Use //xb controller start. The Fast Start 3 shortcut needs no new setup.
4. If the camera is still rotating after exiting the old wrapper, press/release comma and period once. Then test stick-click comma/period actions and touchpad tap, hold past 500ms, release, and focus change; check no invalid
   GetKeyState error, ordinary console/escape behavior, and no stuck input.

No Lua/bootstrap/cache/data/config/binding/icon files are changed. Addon reload
is not required for this AHK include update; the wrapper must restart.
Rollback: exit wrapper, restore previous personal_controls.ahk, start again.
That restores the prior code including its reported touch exception; use the
separate v1 rollback package if a fully known-working fallback is needed.

Verified source: 59eb8d642756d7e75c59f797baec13129441a0df. Native key query
checks pass under both x86/x64 AHK 2.0.19. The full CI jobs later timed out at
the unchanged startup bootstrap stage; this is recorded as unresolved, not a
full-matrix pass. Run 41130232675; see TESTING.md. Eight translated baseline/v2
suites and static/dependency/layout checks pass. Lua code is unchanged.
