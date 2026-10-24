# Dialogue Controls 1 — A — October 24, 2026

Franklet's supplied Lua trace (bankfeedback1, 20:46:24Z) changes to status 4 at
1792874796.418463. Afterwards, six downs/ups of each face and 24 D-pad presses
arrive at the receiver without ordinary-router calls. The latest appended AHK
segment uses Controls 9.18-bankheld1 and Messages; old Apps segments are historical.
This establishes the Lua bank guard as the block in that capture, not lost input.

New behavior: with no modifier/bank held, dialogue status 4 passes directions and
the configured confirm/cancel roles to native arrows/Enter/Escape. Gameplay IJKL
does not replace event-choice arrows. Other face roles, triggers, Share/Options,
bare R1-release R and paired-shoulder Tab do not become dialogue shortcuts.
Explicit companion banks retain their mappings. Trust/XB menus retain ownership;
native chat keeps its existing typing guard. No NPCmirror forwarding is added.

Every navigation press retains its release owner; a status/context/focus change
releases old directions and quarantines preheld inputs until a fresh press.
No timing/polling, packet, AHK or saved-binding changes.

Live: revisit Fhelm Jobeizat, enter the special dialogue, use D-pad choices and
Cross/Circle to confirm/cancel, then leave. Test a direction held across entering
or leaving dialogue and a focus switch: release once, then press again; no stuck
direction or duplicate Enter. Check shoulder banks still work and ordinary
trigger actions do not fire. Repeat Trust/XB menu and native-chat ownership.

Automated: actual bank/router/receiver confirm, cancel, arrows despite IJKL,
suppressed gameplay faces/trigger actions, paired releases and scene-transition
cleanup, alongside bank chat/native-key and existing six-bar/focus checks.
Native Windows/Windower/FFXI acceptance remains pending.
