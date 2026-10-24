# Bank Defaults 2 — A — October 24, 2026

Runtime directlink1-banks2 / Controls 9.17-trustmerge1. Cumulative from Cleanup 1
or newer, including Trust Forward Merge 1, MessagePolish and icon folder repair.
Keep Trust-MenuToggle-Full-20261023. NPC commands checked against NPCmirror t8.

Stop the shared wrapper and unload XIVcrossbar on all clients. Merge the code
patch preserving data/artwork, reload clients, then start the wrapper once with
controls released. Check the runtime and Controls versions in status.

The code changes factory bindings but keeps saved overrides. To synchronize
the current character, back up data/companion_banks.xml, then run:

```
//xb bank preset cioara apply
```

Repeat on each character, including laptop characters. This preserves that
installation's per-character positions, scales, locks and other settings. It
replaces all bank commands/policies and clears/disables second levels. Existing
cutscene permissions are preserved. L1 is Cioara's supplied Party layout; R1:
directions `npc raw <direction>`, Cross `npc enter`, Circle `npc cancel`,
Triangle `npc interact`, Square `npc raw enter`. Both contexts use that same map.
Cancel is raw Escape; Cross retains coordinated-session checks. Raw commands
default to all discovered NPCmirror clients; they do not require an NPC session.

The separate settings ZIP revises only the supplied snapshot. Its original file
is included under backup/. Do not install it over a laptop file containing newer
settings or Franklet: Franklet was absent from the supplied upload. The command
above is the appropriate route there. All Jobs Default/job bars remain untouched.

Live checks:

1. Check both panels at rest, chat open/closed, native menus and NPC dialogue.
   Chat must pause actions. Editors/pickers still hide the panels; show/hide and
   menus settings remain meaningful. Drawing in cutscenes does not enable input.
2. Hold L1 then L2, or R1 then R2: the first-level bank stays selected. Reverse
   the order: ordinary trigger crossbars still work. Release shoulder first:
   remaining trigger cannot open a second unintended bar. Pair Tab unchanged.
3. Inspect `//xb bank r1 status details`; test its eight commands with NPCmirror
   running on the intended clients. No old SlowEnter or inventory chains remain
   after applying the preset. Commands dispatch once per press, not per hold.
4. Open Trust and test direct navigation, Confirm/Back and R1+Square close.
   Close Trust and recheck bank commands. Do not infer game success from dispatch.
5. Change Icon on Quest: inspect folders and PNG choices, choose one, save,
   return and reload. No icon-list generation or asset relocation is required.
6. Compare panel coordinates before/after applying the preset. They must match.
   The preexisting screen clamp remains; this patch does not reposition panels.

`//xb bank l2 enable` / `disable` (and r2) enables future assignments without
deleting them. `hide` affects drawing only. Status now reports Enabled separately.

Automated checks cover actual bank routing, old explicit saved-map compatibility,
new defaults, root chat drawing gate, disabled-layer/held-input transitions,
snapshot field preservation, icon folder discovery and Trust lease ownership.
Native Windows/AHK/Windower/FFXI testing remains pending.
