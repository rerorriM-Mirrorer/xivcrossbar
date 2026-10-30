# Native AHK v2 and live acceptance

## Automated Windows execution

From the migration checkout, run:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ahk_v2.ps1 -Interpreter 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'

The runner copies runtime files to an isolated temporary folder with spaces,
executes actual production functions with native v2 Maps/Arrays/match objects,
checks the optional probe's parse, starts the real wrapper without FFXI, verifies
its reported runtime/PID, launches a duplicate, stops it, and checks bootstrap
restart and cleanup. It never writes installed userdata. Results are written
under native-test-results. CI pins 2.0.19 and checks both x86 and x64, the production CMD/Windows PowerShell 5.1 bootstrap, and rejection of a non-v2 override. Repeat locally on your installed build.

A function-only include is generated from AcquireWrapperMutex onward, retaining
all five production includes. It excludes auto-start and the emergency hotkey;
the separate real-wrapper run covers those startup paths. Hardware input,
actual keys into FFXI, foreground handoff and Windower are not simulated as passes.

## Equivalent v1/v2 live sequence

Run the complete sequence on the saved v1 installation first, then repeat on v2.
Use the same profile, device, modifier, bindings, frame cap, client set and game
scene. Stop/unload all clients before each swap. Capture //xb diagnostics start
then //xb diagnostics stop (or use the documented capture command supported by
your source); compare ordered button/slot/native-key events rather than absolute
timestamps, wall-clock values, session tokens or process IDs. Keep each result
with runtime version and exact source/package checkpoint.

| Test | Sequence and expected observation |
| --- | --- |
| Native startup | Load one client, then 2–4. Exactly one wrapper survives. Verify ahk_major=2/path; no v1 process starts, even with .ahk associated to v1. Test custom executable path with spaces and invalid/v1 override. |
| Digital mapping | In Input Test, press/release every D-pad/face/Create/Options/trigger/shoulder/click/PS/touch control once. Each intended edge/action occurs once; no native F-key/Apps leakage from messages. Repeat supported XInput/F710/FightPad profiles when devices are available. |
| D-pad rolls | Up→Up-right→Right→Down-right→Down, then reverse and complete circle. Same one-cardinal retention through diagonals; no extra slot/neutral action. |
| Trigger order | L2, R2, L2→R2, R2→L2, simultaneous; release in both orders. Tap a face in the same sample and while held; compare bank/slot ordering. |
| Double holds | Tap then hold each trigger inside 500ms, around boundary and outside; test release/repress and opposing trigger interruption. Lua double-hold behavior must match v1. |
| Fast taps | Repeated short taps, then holds; no duplicates or dropped release. Test near a frame/poll boundary and with normal multibox load. 10ms is requested scheduling, not a guaranteed physical sampling rate. |
| Companion banks | L1/R1 and their extra layers, context visibility, held display, both trigger orders, bank-first/face-first, empty slots, native key/chord ownership and two slots sharing a key. No release of another owner's key. |
| Trust | Open/close menu; navigate IJKL/arrows, confirm/cancel; close while a direction is held. Send/Ready movement once per observed client focus session, including blocked contexts and old TrustMovement fallback if still supported/used. |
| Native scenes | Main menu, inventory scrolling, chat input, dialogue/NPC/signet/Survival Guide, zoning, cutscene transitions, addon editor and chooser. Confirm/cancel and bare keyboard remain faithful. |
| Focus | Hold a trigger/direction/native key, switch to another client, desktop and back; PS focus toggle and character switching. Old owner releases; new client requires neutral; no deferred slot replays. |
| Recovery | Reproduce known interrupted R1/R2 holds under ordinary multibox load; capture diagnostics. If safe, pause the wrapper briefly while holding only controls then resume. Only eligible same-client held controls may recover, in original order; action presses must not replay. |
| Reconnect | Disconnect with trigger/button held, reconnect neutral and held. No stuck input; release before rearming; device/profile remains correct. |
| Keyboard ownership | Physically hold Ctrl/Alt/Shift or a key also requested by controller, then release controller. Physical key remains owned by keyboard; no extra shortcuts. Repeat legacy Ctrl/apps mode separately on ordinary profiles. |
| Shutdown | Stop during a held input, restart; unload one of several clients; reload another; unload last client with both shutdown settings. Explicit stop/emergency exit must release state. Record pre-existing auto-shutdown failure separately. |
| Diagnostics | One unified capture contains Lua/AHK/runtime identity; normal chat quiet, trace opt-in, manual stop/30s timeout and failed-write reporting behave as before. |

Record character/client, scene, physical sequence, expected/observed result,
source SHA, AHK path/version and diagnostic capture. Do not promote until the
used profiles and the four-client focus/native/recovery paths have passed.
