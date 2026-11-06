# Native gamepad bridge experiment

This isolated Win32 addon build starts with the bridge off. Its DLL is loaded
only by an explicit nativepad command. Keep your FFXI Gamepad Config assignments.
The prototype is session-only and works inside the selected FFXI client process.

## Installation and first test

1. Back up the current xivcrossbar folder outside Windower's addons folder.
   Stop the shared reader and unload the addon on all clients before replacing
   the entire folder. Use a spare client first. Install the artifact's
   xivcrossbar folder, including native/xb_gamepad.dll.
2. Start XIVCrossbar normally and select the matching public controller profile.
   Finish setup, log in, run **//xb controller stop**, and wait for stopped status.
   Keep the shared AHK reader stopped on every client during native tests.
3. Verify native controls work, then run **//xb nativepad probe**. Release all
   relevant buttons, press Up, and check **//xb nativepad status**. The poll count
   should rise and held Up should report raw and masked bit 0x001. Verify that Up
   alone is blocked while Right, movement, camera, and ordinary face buttons
   work. Disable with **//xb nativepad off**, release, and verify fresh native Up.
4. Run **//xb nativepad on** and release all buttons. Test unmodified native input,
   then L2/R2 + Up and the face buttons. Release the trigger first while holding
   Up, then release Up. A subsequent bare Up should go to FFXI. Use
   **//xb nativepad menu** to open or close XIVCrossbar's binder. Check page turns,
   bindings, both trigger orders and double taps. Test a native menu separately,
   then focus switching, disconnect/reconnect, unload/reload, and two clients.
5. Record Xbox/XInput and DualSense/DirectInput separately. For XInput try an
   explicit module if automatic selection reports no polls, for example
   **//xb nativepad probe xinput1_3.dll 1**. Restart the FFXI process before changing
   a successfully installed backend, module, or device target. DirectInput uses
   connected-controller enumeration order, which can differ from AHK numbering.
   Use **//xb nativepad probe auto 2** to try the second device after a restart.

## Status and rollback

Report the selected profile, module and device, poll count, raw and masked
masks, buffered calls, unsupported sizes, and overflow. A rising buffered
count means the bridge is declining takeover on that DirectInput device.
Zero polls means the selected hook has not seen a compatible game call.
The raw status is sampled per poll, so hold a button while requesting status.

Use **//xb nativepad off** and then **//xb controller start** for AHK fallback.
Release held buttons before changing modes. Unload restores pass-through as
well. Detours stay installed but dormant until the process exits, with the
DLL pinned so a Lua reload cannot leave a dangling callback. Exit FFXI before
removing the DLL or restoring the backup. If Lua stops servicing the bridge,
filtering stops after a 500 ms heartbeat timeout. Outside the foreground
client, the callbacks pass input through.

## Scope and references

- XInput hooks the selected loaded module's named XInputGetState export.
  Other entry points, including the ordinal-only extended getter, are outside
  this experiment. Axes and unrelated buttons are left alone.
- DirectInput hooks GetDeviceState on a joystick implementation discovered
  from DirectInput8Create, keyed to the selected device instance GUID. It
  assumes standard DIJOYSTATE/DIJOYSTATE2 offsets for matching sizes. A custom
  format of the same size cannot be distinguished by size alone. The
  GetDeviceData observer latches pass-through if buffered access is seen.
  Neither the exact game vtable nor the data format has been verified in FFXI.
- In takeover mode, native menu/chat detection uses Windower's broad flags.
  Compare the battle palette and ordinary menus in live testing. Share,
  Options and the alternate chooser shoulder stay native in this experiment.
  The binder is reachable by command. Captured events reuse the public Lua
  logical keyboard router. The bridge loads via LuaJIT FFI, which needs a
  first-load check on the target Windower installation.
- [ThornyFFXI/Crossbar](https://github.com/ThornyFFXI/Crossbar) uses Ashita input
  callbacks for state and DirectInput offsets. [tCrossBar](https://github.com/ThornyFFXI/tCrossBar)
  uses Ashita's per-button blocked events. Neither callback is assumed to
  exist in Windower 4.
- [XIPivot](https://github.com/HealsCodes/XIPivot) loads a Windower Lua C module
  through package.cpath and uses Detours for process-local hooks. This
  experiment uses independently written code and MinHook instead.
- [Fenestra](https://github.com/Windower/Fenestra) forwards GetDeviceState in
  its DirectInput wrapper. It is an architecture reference and does not
  identify the implementation in the installed Windower 4 Hook.
- MinHook v1.3.4 is pinned in CMake. The Windows package includes its license.
  No upstream reference implementation source was copied into the bridge.

Build with Visual Studio and CMake using **cmake -S native -B build -A Win32**,
then **cmake --build build --config Release** and
**ctest --test-dir build -C Release --output-on-failure**. Keep the build
directory outside the addon tree when using the packaging script.
