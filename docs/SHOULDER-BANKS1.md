# Shoulder Banks 1 — November 1, 2026

Personal development/ahk-v2-migration, starting checkpoint
d3443848d0204265a280fb75c6230e09129ae99e. Runtime suffix:
`directlink1-ahkv2-shoulderbanks1`. Public beta/master are unchanged.

## What changes

L1/R1 panel positions are linked by default. Moving either translates both by
the same distance, preserving their current horizontal and vertical spacing.
This applies to mouse dragging and `bank <layer> pos`; a linked move stops when
either panel reaches a screen edge. Their scale/lock and visibility policies
remain separate. Resolution or scale changes can clamp each panel to fit.

Both shoulders, in either order, select a new editable eight-slot L1+R1 bank.
It replaces the L1 display at its existing position and hides the R1 display
while held (except explicit R1 edit previews). Releasing a shoulder returns to
the remaining bank. Held face/directional inputs are consumed until released;
they cannot migrate into a different bank. The new slots start empty, and the
old L1+R1 Tab shortcut is replaced. Disable the new bank to restore that shortcut.
Existing L1/R1 and second-level bindings are preserved. Trigger-first rules and
Trust's existing controller-menu ownership remain in force; the new bank does
not bypass Trust's open-menu input handler. New fields use the existing version
2 XML shape. Older code does not know these fields; restore the bank settings
backup together with code for a full rollback.

## Install and use

1. Back up the working addon and `data/companion_banks.xml`.
2. Stop the wrapper and unload XIVCrossbar on every client in this installation.
3. Overlay the package's `xivcrossbar` folder onto the existing personal addon.
4. Reload. The PC's selected controller device 2 is preserved; no settings,
   character bindings, icons, startup cache or machine shortcut are supplied.

This cumulative code overlay includes the complete current AHK v2 runtime and
Lua libraries/UI; it still requires your existing addon assets and user data.

For dragging, enter `//xb bank l1 edit on`, move L1 with the mouse, then enter
`//xb bank l1 edit off`. Both panels move even when R1 is hidden. For temporary
independent placement use `//xb bank link off`, adjust the panels, then
`//xb bank link on`; relinking preserves the new spacing.

Examples:

```text
//xb bank l1r1 preview
//xb bank l1r1 cross Together input /echo Combined bank
//xb bank l1r1 key up Up up hold
//xb bank l1r1 status details
//xb bank l1r1 edit on
//xb bank l1r1 edit off
//xb bank l1r1 disable
//xb bank l1r1 enable
```

The ordinary bank command grammar, normal/menu bindings, display, visibility,
feedback and native key holds also apply. `bank lr` and `bank rl` are aliases.
`//xb l1r1` also opens the new bank's command entry point.

## Verification and live checklist

77 top-level Lua suites and 168 Lua source parses passed using the local Lua
5.4 runner with temporary normalization of Windower string-literal methods.
New tests exercise both shoulder press/release orders, held-slot isolation,
native-key release, recovered combinations, focus/menu cancellation, no Tab/R
side effects, linked movement from both sides, screen-edge limits, unlinking,
position commands and the actual shipped XML parser roundtrip. Dependency and
whitespace checks pass. These are simulated/local checks, not Windower/FFXI
or native Windows acceptance. No AHK source changed or new Windows pass claimed.

Live: check both shoulder orders and release orders; assign one harmless echo;
try holding a face button before entering/leaving the combination; verify no
Tab targeting or stray R. Drag each side, save/reload, and confirm spacing and
new-bank assignments persist. Check menus, focus changes and existing L1/R1
and shoulder-trigger banks. Trust's open menu retains its existing ownership.

Rollback: stop/unload every client, restore the complete backed-up code and
companion_banks.xml together, then reload. Keep v1 and v2 include sets coherent.
