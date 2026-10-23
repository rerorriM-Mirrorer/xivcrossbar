# Xbox Extended 1 — October 23, 2026

This cumulative changed-files patch applies over Cleanup 1
`0.4.0-a.20261019.directlink1-cleanup1` or a newer DirectLink build. It includes
Slots/Icons 1 and Cutscene Banks 1. Preserve existing data, config.ini and artwork.

Stop the shared wrapper, unload XIVCrossbar in all clients, merge the supplied
xivcrossbar folder into the installed addon, then load the clients. Select the
same hardware profile on each participating client, with all controls neutral:

```
//xb controller profile xbox 1
//xb messages on
//xb controller status
```

Profile selection starts/replaces the shared wrapper. If it is stopped after
selection, use `//xb controller start`. Do not launch an older standalone AHK
script alongside it. Device 1 means XInput user index 0; supported choices are
1–4. The saved Xbox role mapping from remap can be retained. `//xb remap` is only
needed to change layout/roles; in this personal build its Xbox reader choice is
now Xbox Extended.

Expected versions: Lua `0.4.0-a.20261023.directlink1-xbox1`, Controls
`9.15-xbox1`, selected/running `xinput-extended`, active/requested `messages`.
`//xb controller status details` reports bank negotiation and Xbox Guide reader
availability. An unavailable Guide reader does not disable the other controls.

| PS5 control | Xbox control |
| --- | --- |
| Cross / Circle / Square / Triangle | A / B / X / Y |
| Share / Options | Back / Start |
| L1 / R1 | LB / RB |
| L2 / R2 | LT / RT |
| L3 / R3 | Left / right stick click |
| Touchpad click | Guide, when available |

The PS focus-toggle action has no Xbox mapping. Guide deliberately uses the
touchpad tap/hold handler; mute is unused. Windows may also intercept Guide.
The optional GetStateEx entry point follows SDL's established approach; its
availability flag is not proof of native Guide delivery on this machine.

Check one thing at a time:

1. Use each saved face role in a native menu. With ordinary Xbox roles, A is
   confirm, B cancel, Y main menu and X active window. Custom remapped roles win.
2. Back opens the binding menu. Hold Start to choose a crossbar set and release
   to finish. Check a quick press/release without a lingering menu or input.
3. LT/RT reveal ordinary bars; test a harmless slot, both orders and release.
4. LB, LB+LT, RB and RB+RT reuse L1, L1L2, R1 and R1R2 saved bindings. Check
   ordinary/menu maps, native output and release. Trigger-first behavior stays
   ordinary. Per-bank cutscene opt-ins remain explicit and default off.
5. Check quick D-pad taps, alternating Up/Down and a short hold in the same
   harmless native menu used for the PS5 comparison. User's current observation:
   stopping the wrapper stops D-pad menu movement. This does not establish that
   every other button has no direct native assignment.
6. Test stick clicks and Guide separately. Check focus changes, unplug/replug
   and a neutral rearm before resuming. Live Windows release behavior is pending.

If a trigger still sticks, use `//xb controller trace on`, reproduce briefly,
then `//xb controller trace off`. The capture remains 30-second opt-in and paired
with Lua; XInput state lines now include `triggers=LT/RT` values from 0–255.
The existing threshold is >4, unchanged. We need the actual released values
before deciding whether trigger noise, routing or native delivery is responsible.

`//xb controller profile xinput 1` selects the legacy Apps route for comparison;
`//xb controller profile x 1` returns to PS5 Extended, requiring the corresponding
FFXI device configuration. Profile changes do not rewrite bank/action bindings.

Automated checks use Lua 5.4 with temporary Windower syntax normalization and
narrow translations/mocks of the actual AHK functions. They do not establish
native Windows/AHK/FFXI acceptance or prove a cure for the reported stickiness.

Sources reviewed: upstream qEagleStrikerp/XIVCrossbar ffxi_xinput.ahk at
15d8381dfad0f9efdb84fe2d24655afc150faec4; Microsoft's XINPUT_GAMEPAD definition;
SDL src/core/windows/SDL_xinput.c and SDL_xinput.h (ordinal-100 fallback/Guide bit).
