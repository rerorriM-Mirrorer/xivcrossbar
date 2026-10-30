# XIVCrossbar Beta 1 — PS5 DirectLink

A Windower 4 preview of PS5 controller input without simulated gameplay F-keys.
**Experimental beta:** Windows/FFXI verification of the latest fixes is pending.

## Extra setup

- Install **AutoHotkey v1.1** (not v2). Back up your old `addons/xivcrossbar/` folder; stop the shared AHK reader, unload XIVCrossbar on every client, and replace the **whole** addon folder. Don't overlay a personal installation.
- In FFXI Gamepad Config, unassign duplicate native face/D-pad/trigger/hat-switch input that would conflict with XIVCrossbar; keep movement/camera sticks. See `images/setup/gamepad-directinput.jpg`.
- Load with `//lua l xivcrossbar`, complete the button setup, then use `//xb controller profile ps5` for the PS5 DirectInput profile. Gameplay uses DirectLink; setup/login use the legacy keyboard route.
- **Default D-pad is IJKL.** Assign I/J/K/L to **Menu/Target Cursor** in FFXI Key Assignment first, or use `//xb dpad arrows` for the previous arrow-key behavior. This applies to bare gameplay targeting, not menus.

## Additional commands

| Command | Effect |
| --- | --- |
| `//xb controller profiles` / `controller status` | Reader choices and current state |
| `//xb controller profile ps5 [device]` | Select PS5 reader/device |
| `//xb compact [on\|off]` | Change compact/full layout immediately |
| `//xb autohide [on\|off]` / `hide\|show\|auto` | Trigger visibility ON by default; `//xb show` keeps bars visible. No hold delay yet; current fade-out is 0.5s |
| `//xb fade [on\|off]` | Enable/disable slot fades |
| `//xb textfade [on\|off\|status]` | Fade labels with slots (default ON) |
| `//xb textsettle [on\|off\|status]` | Settle caption widths to avoid flicker (default ON) |
| `//xb autoattack [on\|off\|status]` | Enable swing-timing estimation independently of opacity (default OFF) |
| `//xb scale <0.25–2>` | Scale crossbar independently of menus |
| `//xb resources` | Report owned drawing-object counts |
| `//xb diagnose` | Capture 30 seconds of input and rendering observations |

**Custom actions:** On Save/Review, use **arrow keys** to move, **Enter** to select, and **Escape** to go back. Choose Edit Name/Alias/Command to type; Enter confirms the text. **Save Only** returns to the catalog; **Save & Bind** selects a slot.

To hide the built-in skillchain timer and its backing, set `SkillchainIndicator.Opacity` to `0` in `data/settings.xml`. `AutoAttackIndicator.Opacity = 0` hides its bar; tracking is OFF by default, and `//xb autoattack on` enables it without changing opacity.

Existing `data/settings.xml` choices are retained where those settings were already saved; newly introduced settings inherit these defaults.

For complete settings and rollback details see [README.md](README.md); for test status see [TESTING.md](TESTING.md).
