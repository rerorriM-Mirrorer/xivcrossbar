# XIVCrossbar — Native Blocking and DirectLink

1. Stop the old reader and close all FFXI clients before replacing the addon.
   Back up the existing addon and its data. Use the complete x86 test artifact
   with `native/xb_gamepad_messages.dll`, and keep your existing settings and bindings.
2. Install AutoHotkey v2.0.19+ and keep native FFXI Gamepad Config assignments.
   Restore them if they were cleared for an older XIVCrossbar test.
3. Select a profile with `//xb controller profile <name> [device]`.
   Profiles are `ps5`, `f710`, `fightpadpro`, `xinput`, and `xinputalt`.
   Use F710 DirectInput mode with `f710`; use an XInput profile in its X mode.
4. Release the buttons. Check `//xb controller status` and
   `//xb nativepad status`. The guard needs live game polls and a matching
   reader lease. Use the keyboard or mouse for setup if the hook is unavailable.

## Additional commands

| Command | Effect |
| --- | --- |
| `//xb controller profiles` / `controller status` | Reader choices and current state |
| `//xb controller profile ps5 [device]` | Select the PlayStation 5 reader and device |
| `//xb compact [on\|off]` | Change compact/full layout immediately |
| `//xb autohide [on\|off]` / `hide\|show\|auto` | Auto shows the bars while a trigger or visible shoulder bank is held. `//xb show` keeps the bars visible during regular gameplay. |
| `//xb autohold [seconds]` | Keep the last bank visible in Auto after release. Accepts 0–30 seconds and defaults to 0. |
| `//xb costalign <alignment>` | Align MP, TP, and item counts to `left`, `center`, or `right` |
| `//xb fade [on\|off]` | Enable/disable slot fades |
| `//xb textfade [on\|off\|status]` | Fade labels with slots (default ON) |
| `//xb textsettle [on\|off\|status]` | Settle caption widths to avoid flicker (default ON) |
| `//xb autoattack [on\|off\|status]` | Enable swing-timing estimation independently of opacity (default OFF) |
| `//xb scale <0.25–2>` | Scale crossbar independently of menus |
| `//xb resources` | Report owned drawing-object counts |
| `//xb diagnose` | Capture 30 seconds of input observations |

**Remap and custom actions:** Use **arrow keys** to move, **Enter** to select, and **Escape** to go back. Release each key before pressing it again on the next screen. Choose Edit Name/Alias/Command to type; Enter confirms the text. **Save Only** returns to the catalog; **Save & Bind** selects a slot.

To hide the built-in skillchain timer and its backing, set `SkillchainIndicator.Opacity` to `0` in `data/settings.xml`. `AutoAttackIndicator.Opacity = 0` hides its bar; tracking is OFF by default, and `//xb autoattack on` enables it without changing opacity.

Existing `data/settings.xml` choices are retained where those settings were already saved; newly introduced settings inherit these defaults.

For complete settings and rollback details see [README.md](README.md); for test status see [TESTING.md](TESTING.md).
