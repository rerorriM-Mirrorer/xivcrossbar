# Trust movement — Quiet update (0.1.1)

This patch is based on the exact ffxi_directinput.ahk you supplied, matching
XIVCrossbar's personal/ps5extended baseline 0d4f09a. It adds a diagnostic-first
movement receiver. Read TESTING.md first for checks and remaining live tests.

## Update an already working Test 1 installation

1. Merge the ZIP's **addons/trust** and **addons/trustmovement** folders into
   the corresponding folders under **Windower/addons**.
2. In each participating client run `//lua reload trust`, followed by
   `//lua reload trustmovement`. Use the Lua reload command: //trust reload only
   reloads job settings and does not load this code update.
3. Existing live/test/off settings are retained; quiet defaults on. If needed,
   `//tm live` enables the actual follow/assist handoff.

Your working AHK files are unchanged. No shared-wrapper restart or setup script
is needed for this update. Switch to another FFXI client and move to try the
next handoff. Normal handoffs should produce no success acknowledgments;
actual failures remain visible. `//tm quiet off` restores success messages.

Both Trust senders and recipients need the included patch for full quieting.
This is an overlay for the existing Trust installation, not a full Trust ZIP.
Trust patch baseline: test/compact-trust-title-20261008 at 89939a7.

## Fresh movement install (requires existing Trust and XIVCrossbar)

1. In one game client, run `//xb controller stop`. Wait until
   `//xb controller status` reports stopped. This stops the shared wrapper for
   all clients; the game clients can remain open.
2. Copy the package's **addons** and **scripts** folders into your **Windower**
   folder, merging folders. The package also overlays the targeted Trust quiet-command files. Your existing
   personal_controls.ahk, personal_gestures.ahk, controller_clients.ahk, controller
   selection and character settings stay in place. Do not run this AHK copy
   directly from the ZIP: it expects your existing companion includes.
3. In each client you want to test, run `//exec trust-movement-test.txt`.
4. In one client, run `//xb controller start` to restart the shared wrapper.

No global keyboard bindings or user configuration files are replaced. Keep your current
controller profile and device selection. Your window title must contain its
character's name, as default Windower titles do.

## Diagnostic test

Move the left stick on the focused client. Expect:

`[TrustMovement] Movement received on Myrr (#1). TEST: no Trust commands sent.`

The character name will match your client. Stop, recenter and move repeatedly:
expect no more messages on that focus session. Switch to another FFXI client
without moving: expect no message. Start moving there: expect one message.
Return to the first client and move: expect one new message. A trip to another
application and back to the same client must not rearm it.

Also test with L2/R2 held, camera-only movement, menu navigation, and your
existing personal controls. See TESTING.md for the complete short checklist.

## Enable the actual Trust commands

After the diagnostic behaves as expected, run `//tm live` on each participating
client. Switch clients and back if that focus already sent its diagnostic.
The next eligible movement runs exactly:

```
trust follow me
trust assist me
```

Patched Trust must be loaded and its normal IPC modes configured, just as for your
existing working commands. Start/stop management and outside-party following
are not included. Use `//tm test` for diagnostics or `//tm off` to disable a
client. Modes are saved per Windower config. Nothing is added to init.txt;
load the receiver again after a new launch when you want to use it.

## If nothing appears

Run `//tm status`, then `//xb controller status`. Check:

- Both receiver files are under addons/trustmovement, and movement_signal.ahk
  is beside the replaced ffxi_directinput.ahk.
- The shared wrapper was actually stopped and started after copying.
- The selected controller/device is the one you normally use.
- Your window title includes the character name, and you are outside menus.

Useful files to send back: addons/xivcrossbar/data/controller-status.ini and
addons/xivcrossbar/data/trust-movement.log, plus the receiver's chat output.
If the wrapper log records a signal but chat does not, that specifically
isolates Windows scan-code delivery as the next thing to investigate.

## Roll back

For quiet-only rollback, restore **rollback/quiet-update/addons/** over your
Windower/addons folder, then reload Trust and TrustMovement in each client.
This restores the previously working Test 1 receiver and original Trust files.
The new command_feedback.lua is unused by restored Trust and may remain.

For complete movement rollback:

1. Run `//tm unload` in every client that loaded it.
2. Run `//xb controller stop` and wait for stopped status.
3. Restore **rollback/ffxi_directinput.ahk** over
   **Windower/addons/xivcrossbar/ffxi_directinput.ahk**.
4. Run `//xb controller start`.

The extra movement_signal.ahk file is unused by the restored wrapper and may
be removed. The trustmovement folder and setup script may also be removed.

## Verification and changelog

0.1.1: quiet movement success messages and a scoped --quiet Trust patch.

0.1.0: one signal per client focus; physical-stick observation; diagnostic-first
receiver; native-menu/chat/event guards; optional follow/assist commands.
Mocked receiver checks and Lua syntax checks are recorded in TESTING.md.
The user reported Test 1 working live. This quiet update has 81 simulated
assertions and Lua 5.1 syntax checks; its new quiet behavior awaits live testing.
