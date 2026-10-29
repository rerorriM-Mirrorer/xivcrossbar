# XIVCrossbar Beta 1 — PS5 DirectLink

A Windower 4 preview of PS5 controller input without simulated gameplay F-keys.
**Experimental beta:** Windows/FFXI verification of the latest fixes is pending.

## Extra setup

- Install **AutoHotkey v1.1** (not v2). Back up your old `addons/xivcrossbar/` folder; stop the shared AHK reader, unload XIVCrossbar on every client, and replace the **whole** addon folder. Don't overlay a personal installation.
- In FFXI Gamepad Config, unassign duplicate native face/D-pad/trigger/hat-switch input that would conflict with XIVCrossbar; keep movement/camera sticks. See `images/setup/gamepad-directinput.jpg`.
- Load with `//lua l xivcrossbar`, complete the button setup, then use `//xb controller profile ps5` for the PS5 DirectInput profile. Gameplay uses DirectLink; setup/login use the legacy keyboard route.
- Optional: `//xb dpad ijkl` requires mapping I/J/K/L to **Menu/Target Cursor** in FFXI's key assignment menu. `//xb dpad arrows` restores arrows.

## Additional commands

| Command | Effect |
| --- | --- |
| `//xb controller profiles` / `controller status` | Reader choices and current state |
| `//xb controller profile ps5 [device]` | Select PS5 reader/device |
| `//xb compact [on\|off]` | Change compact/full layout immediately |
| `//xb autohide [on\|off]` / `hide\|show\|auto` | Visibility without disabling binds |
| `//xb fade [on\|off]` | Enable/disable slot fades |
| `//xb textfade [on\|off\|status]` | Fade labels with slots (default OFF) |
| `//xb textsettle [on\|off\|status]` | Settle caption widths to avoid flicker (default ON) |
| `//xb scale <0.25–2>` | Scale crossbar independently of menus |
| `//xb resources` | Report owned drawing-object counts |
| `//xb diagnose` | Capture 30 seconds of input and rendering observations |

**Custom actions:** In the Save/Review screen choose Edit Name, Alias or Command to type directly; Enter confirms, Circle cancels. **Save Only** returns to the catalog; **Save & Bind** selects a slot.

For complete settings and rollback details see [README.md](README.md); for test status see [TESTING.md](TESTING.md).
