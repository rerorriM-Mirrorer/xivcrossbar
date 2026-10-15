# Trust movement — Test 1 (0.1.0)

This patch is based on the exact ffxi_directinput.ahk you supplied, matching
XIVCrossbar's personal/ps5extended baseline 0d4f09a. It adds a diagnostic-first
movement receiver. Read TESTING.md first for checks and remaining live tests.

## Install

1. In one game client, run `//xb controller stop`. Wait until
   `//xb controller status` reports stopped. This stops the shared wrapper for
   all clients; the game clients can remain open.
2. Copy the package's **addons** and **scripts** folders into your **Windower**
   folder, merging folders. Only ffxi_directinput.ahk is replaced. Your existing
   personal_controls.ahk, personal_gestures.ahk, controller_clients.ahk, controller
   selection and character settings stay in place. Do not run this AHK copy
   directly from the ZIP: it expects your existing companion includes.
3. In each client you want to test, run `//exec trust-movement-test.txt`.
4. In one client, run `//xb controller start` to restart the shared wrapper.

No Trust files or global keyboard bindings are changed. Keep your current
controller profile and device selection. Your window title must contain its
character's name, as default Windower titles do.

## First test

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

Trust must be loaded and its normal IPC modes configured, just as for your
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

1. Run `//tm unload` in every client that loaded it.
2. Run `//xb controller stop` and wait for stopped status.
3. Restore **rollback/ffxi_directinput.ahk** over
   **Windower/addons/xivcrossbar/ffxi_directinput.ahk**.
4. Run `//xb controller start`.

The extra movement_signal.ahk file is unused by the restored wrapper and may
be removed. The trustmovement folder and setup script may also be removed.

## Verification and changelog

0.1.0: one signal per client focus; physical-stick observation; diagnostic-first
receiver; native-menu/chat/event guards; optional follow/assist commands.
Mocked receiver checks and Lua syntax checks are recorded in TESTING.md.
Windows AutoHotkey loading and actual FFXI input delivery remain untested.
