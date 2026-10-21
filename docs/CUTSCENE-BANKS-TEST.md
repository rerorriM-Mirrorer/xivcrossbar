# Cutscene Banks 1 — October 21, 2026

Runtime directlink1-cutscene1; shared Controls 9.14-cutscene1. Starting checkpoint
7bdede0a8a8f46dc02a5f78101bfd88a4978005e. Requires the matched Lua/AHK update.
The cumulative changed-files patch works over Cleanup 1 (28304f4) or any newer
DirectLink build. It contains no personal data, bindings or artwork.

## Install and configure

1. Back up xivcrossbar. Run `//xb controller stop` and unload XIVCrossbar in all
   clients. Merge the patch into the installed addon, preserving data and images.
2. Load XIVCrossbar in each client. Start the wrapper once with buttons released.
3. Check `//xb inputstatus` for directlink1-cutscene1 and controller status for
   Controls 9.14-cutscene1, profile ps5-extended, active/requested messages.
4. Enable cutscene access on the bank containing your NPC/test functions. For
   example, if that bank is R1: `//xb bank r1 cutscenes on`.
5. `//xb bank r1 status` shows cutscenes ON. `//xb bank r1 cutscenes off` restores
   the guard. The option is saved per character and per bank. All banks default
   OFF. Valid bank names are l1, l1l2, r1 and r1r2.

Permission covers the selected bank's configured actions. During status-4
cutscenes, other bank layers, ordinary crossbar actions, and implicit R1/Tab or
touch/click game shortcuts do not gain permission. Existing focus/chat/editor/
input-test guards remain. An unavailable message session cannot run these banks.

Drawing and menu maps remain separate settings. `menus on` allows that bank to
draw over a reported native menu. `menuactions on` selects its Menu map there;
OFF keeps its normal map. This cutscene option does not flip either setting or
replace any binding. Dialogue not reporting status 4 follows ordinary menu rules.

## Live check

Use a familiar dialogue/cutscene. With the selected bank OFF, verify that its
command does not fire. Enable it outside the scene, return with controls neutral,
and try one appropriate NPC/test command. Check the intended normal/Menu map,
release, then verify ordinary trigger bars and other unapproved banks remain
inactive in that scene. Check entry/exit and a client switch for stale holds.
Return OFF if the scene or another addon does not support the requested command.

If a bank should be visible while a native menu is reported open, enable its
existing `menus` drawing option separately. Hidden drawing does not disable
permitted actions. Settings remain per character; configure each desired client.

## Render trace save change

Myrr's reported 0 KB file contains no recoverable events. The old saver opened
the destination in write mode before assembling the trace, so an interrupted
save could leave an empty file. That ordering is consistent with the observation
but does not establish why FFXI crashed.

The new saver assembles the bounded trace first, then uses the existing staged
Windows replacement helper. Assembly/write/swap failures preserve the previous
capture where recovery succeeds and report errors. Native process crashes can
still interrupt a save. This is not a confirmed client-crash fix.

Cioara's supplied trace is complete: 95,047 bytes, 658 frames, 1,080 retained
events, no overwritten events, one MARK, a stop event, and max recorded frame gap
56.8 ms. It spans about 11.6 seconds. It cannot establish Myrr's crash cause or
whether a texture actually flickered on screen. No new trace is required merely
to replace the empty file. The icon picker/ghost-label reports remain separate.

## Verification and rollback

60 top-level Lua suites passed; 141 Lua sources parsed with the documented Lua
5.4/Windower-syntax normalization fallback. Seven JS suites and AHK structural/
layout checks passed. Actual root receiver/bank routing, cutscene permissions,
XML persistence, restricted AHK arming and click-key release are simulated.
Trace tests verify assembly-before-replacement, error reporting and failed-save
handling. Native Windows/AHK/Windower/FFXI behavior still needs live acceptance.

To roll back, stop the wrapper and unload all clients, restore the backed-up
code, then reload and start the prior wrapper with neutral controls. Preserve
data/settings; the previous bank reader ignores the new cutscene field.
