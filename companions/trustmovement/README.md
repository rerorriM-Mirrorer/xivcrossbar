# TrustMovement 0.1.1 — movement takeover test

First movement after selecting an FFXI client produces one diagnostic message.
Further movement and returning the stick to center do not rearm the signal.
Selecting another FFXI window rearms it; a trip to another application does not.

The shared XIVCrossbar controller wrapper reads the physical movement stick.
The receiver defaults to **test** and sends no Trust commands. In **live**, it
runs `trust follow me`, then `trust assist me`, using Trust's existing handlers.
It does not start or stop Trust, change profiles, or implement outside-party
following. The quiet update overlays the included Trust source patch. Trust must already be loaded for live mode.

## Commands

- `//tm test` — diagnostic messages only; initial default.
- `//tm live` — enable the two Trust commands on this client.
- `//tm off` — disable this client's receiver.
- `//tm quiet [on|off]` — movement success chatter; default on, bare toggles.
- `//tm status` — version, mode, received/executed/skipped counts, and readiness.
- `//tm help` — command list; also shown for bare or invalid commands.
- `//tm restart` / `//tm unload` — receiver lifecycle.

The selected mode is saved through Windower config. Use `//tm test` when
returning to diagnostics. Changing mode or reloading the receiver does not
rearm an already-fired wrapper latch: switch to another FFXI client and back.

## Quiet movement feedback

Quiet is enabled by default, including when updating existing settings. In live
mode the receiver omits its own success message and appends `--quiet` to both
Trust commands. Patched Trust propagates that flag to receivers and suppresses
only successful follow/assist acknowledgments, their character chatter and
path-clear notices caused by the handoff. Validation/IPC errors and meaningful
pulling-state notices remain visible. Typed commands without --quiet retain
normal feedback; no text-matching filter or global chat toggle is used.

`//tm quiet off` restores the earlier movement messages for troubleshooting.
`//tm test` still produces diagnostics. Status/help and explicit mode changes
always give feedback. Quiet state is saved independently of live/test/off mode.

Install the Trust patch and reload Trust on every participating client to quiet
their acknowledgments too. An older unpatched Trust may still execute the
commands while ignoring the extra flag and continuing to print its messages.

## Signal and readiness

The wrapper emits the NOCONVERT scan code (DIK 123) for 30 ms. The receiver
consumes both edges without changing held Ctrl/Apps/Shift keys. F1-F12 routing
and personal controls retain their existing behavior.

The receiver publishes a short-lived readiness lease in its own data folder.
The wrapper matches the character's name in the active window title. Default
Windower character titles are supported; custom titles must still contain the
character name. Native menus, chat input, cutscenes, logged-out/background
clients and disabled receivers do not advertise readiness. Existing extended
PS5 context also blocks XIVCrossbar's own editing/setup menus. Held crossbar
triggers alone do not block movement.

Initial detection uses a radial threshold of 0.24 of full stick deflection,
editable as `threshold` in `MovementInit()` in movement_signal.ahk. No deliberate
hold delay is added. Polling, readiness publication and OS scheduling mean this
is not a measured latency guarantee. A stick already held when switching can
trigger the new client; switching with the stick centered does nothing.

The latch belongs to the wrapper process and resets when that process restarts.
Closing a menu with the stick held can trigger once gameplay becomes eligible.
If the menu opens in the narrow interval after a signal is sent, the receiver
rejects the signal; switch clients and back to retry. No automatic retries or
command flooding are introduced.

Wrapper diagnostics: `addons/xivcrossbar/data/trust-movement.log` records only
sent signals; `controller-status.ini` adds movement version/count/reason.
Receiver counts record signal reception and command dispatch, not confirmation
that every remote Trust client completed the requested follow/assist action.

## Changelog

### 0.1.1 — 2026-10-15

- Quiet live movement acknowledgments by default, with //tm quiet on/off.
- Add opt-in --quiet to Trust follow/assist and propagate it through IPC.
- Preserve manual command feedback, errors, control behavior and the AHK wrapper.

### 0.1.0 — 2026-10-15

- Observe left-stick movement in the existing DirectInput/XInput wrapper.
- Send once per FFXI focus session, independently of button-neutral handling.
- Add diagnostic-first receiver, menu readiness and optional follow/assist mode.
- Preserve the supplied wrapper and its existing personal-control includes.
