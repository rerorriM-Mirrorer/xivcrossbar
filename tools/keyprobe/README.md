# AutoHotkey v2 migration note

This branch's keyboard probe requires v2.0.19+ and uses native v2 GUI events.
Launch it with an explicit v2 executable if your .ahk association still selects
v1. It remains an optional manual diagnostic, never an addon startup dependency.
Earlier historical instructions below refer to the original delivery.

# Optional key probe

Nothing here starts automatically. The previous probe was not recovered from
the saved packages; this is a new small observer and manual signal sender.

## Verified Mute number

Max's October 2 JoystickTest result recorded **Mic/Mute=Joy15**, with PS=Joy13.
That live result was recovered from the earlier conversation; it is not inferred
from the adjacent touchpad number. Use Joy15 for the proposed gated probe bank.
The bank is still pending; no Mute output is assigned by this update.

The read-only watcher below remains useful for checking a different device or
reader. It is no longer necessary to rediscover the known DualSense mapping.

Stop the normal controller wrapper with //xb controller stop. Open the AHK
probe and enable **Watch controller button numbers (read only)**, normally on
device 1. Focus FFXI and press/release Mute alone. The GUI and tooltip show
held Joy numbers and return to `none (released)`. Record the number that appears.
Use a face button as a control check if Mute produces no number. A reader that
sees the face button but not Mute does not currently expose Mute through this
interface; do not guess Joy15. The watcher sends no keyboard events.

The proposed next mode is a temporary Mute-held bank: visible HELD/RELEASED
feedback, candidate keys only while the gate is held, no probe key output when
released, and cleanup on focus loss. It is not implemented yet. Normal controller
translation must be stopped for isolated tests so both scripts do not act on
the same face buttons. An Apps-marked bank would let us compare the same keys
bare versus with Apps after their independent DIKs are established.

## Test signals

For the new **L1+touchpad hold**, first copy `xbkeyprobe/` into Windower's
`addons/` folder. Load `//lua l xbkeyprobe`, then `//xbkeyprobe on`. Hold
L1+touchpad for 500ms: Tab now fires on down; record F15's DIK once after 500ms.
Release should add no Tab. Turn
reports off with `//xbkeyprobe off`, or unload `//lua u xbkeyprobe`.
The observer alone registers no bindings and never consumes input.

To try a real command without depending on an undocumented F15 binding name:

```text
//xbkeyprobe f15 input /echo F15 received
```

Hold L1+touchpad: the initial Tab still happens, then one echo at 500ms. To
change the test, repeat `//xbkeyprobe f15 <Windower command>`; for chains, make
a Windower alias first and supply its name. `//xbkeyprobe f15 off` removes the
temporary handler, or unload the probe. This explicit test consumes DIK 102
while enabled, sends at most one command per down/up pair and respects an
already-blocked event. It never edits your saved bindings. Windower's documented
key-name list omits F15; raw DIK support and a named console bind are separate.

To test other signals independently, stop the controller with
`//xb controller stop`; keep FFXI running and the observer on. Open
`keyboard_probe.ahk` manually with AutoHotkey v1.1.33+. Choose a key and click
**Send to FFXI**. The probe restores the most recently active FFXI window and
sends one down/up pulse. It cancels the pulse if that window loses focus before
delivery, and sends cleanup key-up only to the original window. Record both
the tooltip's VK/scan code and the observer's DIK, plus any native action.
Repeat with Apps selected. Close the probe, unload the observer, then
`//xb controller start` before continuing normal gameplay.

| Candidate | Evidence / purpose |
| --- | --- |
| F13, F14, F15 | Earlier distinct DIK 100, 101, 102; best established spare markers |
| F16–F24 | Windows/AHK candidates; sampled higher keys previously returned DIK 0. Retest before using |
| Kana, Convert, Nonconvert | Windower names exist; our previous international-key results were mixed. Probe emits explicit VK/scan-code pairs |
| Browser Back, Forward, Favorites | Windower names exist; may also perform native Windows/browser actions. Compare bare and Apps output |

Fallbacks already discussed include Delete, End and Numpad Decimal. They are
ordinary keyboard keys, so they are not this probe's nonstandard candidates.
Avoid treating a nonzero DIK as proof that the Windower binding name is accepted:
verify a real binding and repeat key-up/focus tests before allocating a marker.

References: [Windower key names](https://docs.windower.net/commands/keymapping/)
and [AutoHotkey v1 key list](https://www.autohotkey.com/docs/v1/KeyList.htm).
