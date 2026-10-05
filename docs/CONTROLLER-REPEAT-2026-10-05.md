# XIVCrossbar controller update — October 5, 2026

Controller extras revision: **2026-10-05.1**.
Source baseline: **9423175d3e21474dda0827fc3abf0a70df9c067c** on
[work/consolidate-2026-10-04](https://github.com/rerorriM-Mirrorer/xivcrossbar/tree/work/consolidate-2026-10-04).
The Lua build remains **0.4.0-a.20261005.8**.

## What changes

| Control | Behavior |
| --- | --- |
| R1 tap | One Tab, as in the working version |
| L1 tap | One Shift+Tab |
| Hold either shoulder | First tap immediately; repeat after **3 seconds** at **2 taps per second** |
| Hold L1 | Shift stays held between Tab pulses; release L1 to release it |
| L3 with one FFXI client | On release, minimize the focused client or activate/restore it from another program |
| L3 with multiple clients | The existing numeric window-order cycle, once on release |

Shoulder holds cancel on focus loss, a trigger/menu, a competing shoulder, or
an L3 press. They require a fresh press to restart. The helper releases its own
Shift before changing focus and during normal wrapper exit/reload. Physically
held keyboard modifiers are preserved. XInput disconnects now cancel a hold.
Tabs retain the working 40 ms pulse; late polling produces no catch-up burst.

With multiple clients, L3 still needs an FFXI client focused. The solo toggle
also works from another program, because restoring the one client is its
requested purpose. Changing focus during the L3 hold cancels the action.

## Install the small patch

1. Extract this archive to a temporary folder. Release all controller buttons.
2. Save your currently installed controller_extras.ahk and ffxi_xinput.ahk.
3. Copy the two files in the archive's xivcrossbar folder into
   Windower/addons/xivcrossbar, replacing those two files.
4. Keep your existing controller-extras.ini. The new settings default to the
   behavior above when absent, so the existing button numbers remain yours.
   A complete example is supplied in reference/controller-extras.ini.
5. Reload the active AutoHotkey wrapper using its tray icon's **Reload Script**.
   Use the same DirectInput or XInput wrapper that is already working. This
   helper is for AutoHotkey v1.1.21 or later.

The XInput file is included solely for its disconnect cleanup. No Lua, profile
XML, icon assets, or face-button/trigger mapping file is included in this patch.

## Optional timing settings

Add these entries under the existing [Controller] section:

    SingleClientToggle=1
    ShoulderRepeatEnabled=1
    ShoulderRepeatDelayMs=3000
    ShoulderRepeatIntervalMs=500

For three taps per second, set the interval to **333**. A delay of **2000** or
**4000** selects two or four seconds. Set ShoulderRepeatEnabled to **0** to
retain tap-only shoulders. Set SingleClientToggle to **0** to retain the
previous one-window behavior. Restart/reload the wrapper after INI changes.

## Short live check

- Tap R1 and L1: one forward/reverse step each.
- Hold each for less than three seconds: no extra step.
- Hold each longer: repeat begins at three seconds, then two steps per second.
  Release L1 and check that subsequent keyboard input is no longer shifted.
- While holding a shoulder, change focus or press a crossbar trigger: repetition
  should stop. Refocus without releasing: it must wait for a fresh press.
- With one client, release L3 twice: minimize, then restore/activate. With two
  or more clients, check the existing cycle. Hold L3 without releasing: no move.
- If using XInput, disconnect during an L1 hold and confirm Shift is released.

## Return to the baseline

Use your own saved copies if your installed files differ from the source
baseline. Otherwise copy the two files from rollback/xivcrossbar into the
installed folder and reload the active wrapper. Unknown new INI settings are
ignored by the previous helper, so they do not prevent rollback.

## Verification

The package is checked for complete files, matching baseline backups, and
balanced AHK source delimiters. Windows AutoHotkey execution and FFXI input
sampling cannot be exercised in this workspace and still need the live check.
The earlier live passes for menu paging, the XML binds, and shoulder taps are
retained as observations; they do not certify the new repeat or solo toggle.

Contributing author: **Awake**. New code comments explain timing, modifier
ownership, focus cancellation, and disconnect cleanup.
