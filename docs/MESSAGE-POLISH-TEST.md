# Message Polish 1 — October 23, 2026

Applies cumulatively over Cleanup 1 or a newer DirectLink batch. Stop the shared
wrapper, unload XIVCrossbar on every client, merge supplied addon files while
preserving data/config/artwork, reload clients, and restart the wrapper once.
Keep your current controller profile and mappings. Expected runtime:
`0.4.0-a.20261023.directlink1-messages1`; Controls `9.16-messages1`.

Check `//xb status` and `//xb controller status` for purple `[XIVcrossbar]`/title
identity, `===` headings, light-blue labels/routine wording, white values and
green ON/Ready. Restarting is yellow; profile selection highlights controller
and device in white with Experimental yellow. Loaded DRK/RDM stays routine blue,
without an arrow, job-name emphasis or trailing status command. Normal wrapper
start feedback omits Apps. The underlying compatibility route is not removed.

Normal status shows the current set, layout, D-pad mapping, bank policies and a
single controller summary. Recovery/trace/protocol/counter/timing internals no
longer print in routine chat. An unavailable or mismatched controller still gets
an actionable message. Stopped state must never present an active message route.

```
//xb diagnostics
```

`//xb diagnose`, `//xb status details`, and `//xb controller status details` save
the same snapshot. Expect one confirmation naming
`data/diagnostics-<Character>.log`; the latest snapshot for that character is
replaced only through the existing staged-save helper. The file retains raw
wrapper state, selected settings, receiver counters, bank policies/bindings,
output acknowledgments, lifecycle and editor/storage state. It does not start a
continuous trace. Existing paired controller/render trace commands remain.

The diagnostic file can contain your custom bank commands. Supply it when
investigating a problem. A failed save reports failure without claiming success.

| Bank status label | Meaning |
| --- | --- |
| Draw | Whether this bank's panel is enabled |
| Draw in Menus | Whether its panel may draw over native menus |
| Menu Input | Bank input is available in otherwise eligible native-menu contexts |
| Bindings in Menus: Menu | Automatically use its Menu assignments |
| Bindings in Menus: Normal | Keep using its normal assignments |
| Cutscenes | Explicit per-bank exception to scene input guards |

There is no separate per-bank menu-input disable switch in this batch. Menu Input
ON describes existing eligibility; `menuactions off` does not turn controls off.
Chat, focus, editor and cutscene guards still apply. Drawing and execution remain
independent. This update changes labels without changing existing bank policy.

`//xb bank l2 ...` targets the same saved bank as `//xb bank l1l2 ...`;
`//xb bank r2 ...` targets `//xb bank r1r2 ...`. These aliases work for status,
editing and swaps. They do not change ordinary trigger-first crossbar selection.
`//xb bank l2 status details` still lists bindings in chat deliberately.

Check a bare R3/right-stick press and release on PS5 or Xbox: acquisition follows
your existing F8 setting, but our wrapper no longer injects R on release. L3's H,
both stick-click zoom orders, and the separate R1/RB action remain unchanged.
Native FFXI button assignments and explicit custom actions are not rewritten.

IJKL is the selected D-pad key mapping. The old “IJKL configured OFF” diagnostic
referred to the optional AHK delivery method, not that mapping. The snapshot now
records those as separate `selected.dpad` / `selected.ahk_ijkl` fields. Likewise,
the old requested/active routes, recovery resets, trace flags and protocol values
remain available in the file without cluttering normal status.

Full Apps retirement remains separate transport work: startup/login/setup and
lease-loss compatibility paths still exist. This batch makes the current route
clear and removes misleading routine fallback labels; it does not claim removal.

64 Lua regressions / 147 parsed sources and eight JS suites pass using the
documented Lua 5.4 normalization fallback and actual-function mocks/translations.
Native Windows/Windower/FFXI colors, wrapping and R3 behavior require live checks.
