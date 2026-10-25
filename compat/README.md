# Legacy upstream auxiliary scripts

These files are preserved unmodified from qEagleStrikerp/xivcrossbar's
2026-08-01 master (upstream baseline 15d8381dfad0f9efdb84fe2d24655afc150faec4).
They are **references / optional independent tools**, not alternate profiles
automatically launched by the public Beta 1 addon.

For Windows, use only the root `ffxi_directinput.ahk` with AutoHotkey **v1**.
Select PS5/F710/FightPadPro/XInput/XInput-alt within XIVCrossbar using
`//xb controller profile <name>`. Running a legacy file alongside the active
wrapper can double-send button events or seize keyboard modifiers.

`ffxi_directinput.v2.ahk` requires AutoHotkey v2 and is not interoperable with
the new v1 wrapper. The diagnostic and old hardware-specific AHK files retain
their upstream behavior, including older Ctrl-related mappings; they have
**not** been converted to the Beta 1 transport. Their corresponding hardware
functions are provided by unified selectable Apps profiles instead.

`FFXI_Input.py` and `FFXI_Input.sh` remain together at addon root, as in
upstream, for Steam Deck/Linux users. They do not speak DirectLink or Apps.
They have not been runtime-verified for this beta. Install required Linux
dependencies and consult upstream instructions before using them.

The repository's LICENSE and NOTICE preserve upstream attribution.
