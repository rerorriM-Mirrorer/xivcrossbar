# Native blocking bridge

The messages build loads `native/xb_gamepad_messages.dll`. The x86 bridge operates in each FFXI process. It starts monitoring when the
matching reader is ready, and filters after the focused client's DirectLink
lease receives a heartbeat. Filters expire when the reader or Lua stops.
`//xb nativepad off` returns controls to FFXI. Use `//xb nativepad auto`
to restore the guard. Wrapper stop suspends filtering. Addon unload releases
that client's lease and detaches its hooks by default, even when another
client keeps the reader running. The DLL and trampolines remain pinned for
in-flight callbacks. Restart FFXI to replace the DLL or change input backends.

- XInput auto hooks the loaded system variants of GetState, including ordinal
  100 where exported. It preserves sticks and unowned buttons. The standard
  profile reserves View/Menu for addon functions. The alternate reserves
  View/RB and leaves Menu available to FFXI.
- DirectInput uses the Windows joystick ID to choose the instance GUID,
  with a single-device fallback for Device 1. It filters polled joystick
  state and supported buffered records. PS5 and F710 share one mapping.
  FightPadPro uses its own face-button order.
- Bare navigation passes through. A new chord or active addon menu owns
  captured buttons through release, with the existing 120 ms held-direction
  handoff after a trigger. FFXI chat passes new controller presses through.
- The AHK reader is the only action publisher. Native hooks do not duplicate
  messages. The login/character select screens use native bindings.

`//xb nativepad status` reports filtering or pass-through, hook state, poll counts and raw/masked bits. No compatible
polls means addon controller actions wait. An unloaded XInput DLL is not
hooked by the current installation. Restart after changing the gamepad mode.
See TESTING.md for the five-profile physical acceptance matrix.

Build on Windows with `cmake -S native -B build -A Win32`, then
`cmake --build build --config Release` and
`ctest --test-dir build -C Release --output-on-failure`.
The native CI workflow packages the DLL and MinHook license.

For physical layout changes, edit `packaging/controller_mappings.json` and run
`python packaging/generate_controller_mappings.py` from the repository root.
Commit both generated tables. CI checks that the AHK and native tables match
the source. DirectInput button numbers in the source use the AHK 1-based form.
