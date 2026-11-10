# Native blocking bridge

The messages build loads `native/xb_gamepad_messages.dll`. The x86 bridge operates in each FFXI process. It starts monitoring when the
matching reader is ready, and filters after the focused client's DirectLink
lease receives a heartbeat. Filters expire when the reader or Lua stops.
`//xb nativepad off` returns controls to FFXI. Use `//xb nativepad auto`
to restore the guard. Wrapper stop suspends filtering. Addon unload releases
that client's lease and detaches its hooks by default, even when another
client keeps the reader running. The hook DLL and trampolines remain pinned for in-flight callbacks.
Restart FFXI to install a different hook DLL or change input backends.

The resident hook loads `native/xb_controller_logic_1.dll` at first attach.
This trial also ships revision 2 with identical filtering rules. With the
guard active and the pad released, run `//xb nativepad logic 2` and confirm
the revision with `//xb nativepad status`. Use `//xb nativepad logic 1` to
switch back. This switches the focused client's hook only. A new process
starts on revision 1. For another test revision, place its versioned DLL
in the same folder before selecting it. Keep revision 1 installed.

The hook checks the versioned export before swapping policies under its
callback mutex, then releases the previous DLL. Missing and incompatible
revisions leave the active policy in place. A successful swap waits for
neutral input before capturing again. Both the heartbeat and the
foreground-process check remain enforced by the resident hook.

Revision 3 captures both shoulders when targeting is enabled and the game
context permits it. Lua resolves targeting on the press edge. A two-shoulder chord acquires
an NPC only when there is no current target. Single shoulders cycle only
when there is a target. It uses the resident hook's guarded
Shift+Tab support for reverse cycling. Install the matching resident hook
with FFXI closed before selecting revision 3. Revisions 1 and 2 still use
the original R1 targeting behavior.

- XInput auto hooks the loaded system variants of GetState, including ordinal
  100 where exported. It preserves sticks and unowned buttons. The standard
  profile reserves View/Menu for addon functions. The alternate reserves
  View/RB and leaves Menu available to FFXI.
- DirectInput uses the Windows joystick ID to choose the instance GUID,
  with a fallback when the selected Windows joystick slot is the only
  responsive slot and exactly one DirectInput controller is attached.
  It filters polled joystick state and supported buffered records.
  PS5 and F710 share one mapping.
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
