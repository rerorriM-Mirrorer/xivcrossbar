# Bank Feedback 1 + Shared Menu Buttons 1 — A — October 24, 2026

Runtime `0.4.0-a.20261024.directlink1-bankfeedback1`; Controls
`9.18-bankheld1` unchanged. Cumulative changed-files patch from Cleanup 1 includes
the preceding Held Banks and Review Keys fixes. No userdata/artwork replacement.

Install with the shared wrapper stopped and XIVcrossbar unloaded on all clients.
Merge the ZIP's xivcrossbar folder into the installed addon, keeping data and
artwork. Reload participating clients and restart the wrapper once, controls
neutral. Keep the current compatible Trust package. No binding reset required.

Enable the optional swap once per installation:

```
//xb controller menuswap on
//xb controller menuswap status
//xb controller menuswap off
```

ON: Options opens/exits the binder; holding Share opens the page chooser, release
closes it. Both crossbar hints and the binder Exit artwork change together.
Clients adopt at neutral with XB menus closed. Default OFF; preference survives
reloads and character switches. Physical AHK messages are unchanged. See also
[shared-button checks](MENU-SWAP-TEST.md).

Every accepted companion-bank slot press now lights that slot using the existing
white feedback artwork. The pulse stays bright for at least 60 ms, settles to a
quieter held highlight by 140 ms, then fades over 140 ms after release. Fast taps
retain their minimum pulse before fading. Timing uses elapsed seconds; the main
crossbar's existing feedback animation is unchanged.

This acknowledges received input, including an empty slot. It does not certify
game action success. Layer/context changes, focus cancellation and commands that
cancel bank input clear feedback immediately. Disabled/blocked/ordinary inputs
do not light companion slots. Shoulder release hides the panel normally; feedback
never extends panel visibility. No positions or bindings change. Eight overlays
per allocated side add a fixed 16 images; idle frames do not redraw static labels.

Live checks:

1. Hold L1, tap directions and faces rapidly; confirm correct slot flashes once
   per press. Hold two slots and release independently. Repeat on R1.
2. Release a shoulder before its slot. Reopen the bank: no stale held highlight
   or replayed action. Switch focus while held, return, release and press again.
3. Test with chatlog, native menu and dialogue open. Feedback should follow the
   bank owning input. Trust/XB menu navigation must not light a hidden bank.
4. Temporarily enable empty L2/R2 banks and test their feedback. Old saved maps
   remain unless explicitly reset; use both contexts if clearing to defaults:

   ```
   //xb bank l2 defaults
   //xb bank l2 menu defaults
   //xb bank r2 defaults
   //xb bank r2 menu defaults
   ```

5. Try normal play at 30 and 60 fps, then on the laptop. Judge pulse brightness,
   minimum visibility and fade length; positions and autohide should be familiar.
6. Check Review and Save keyboard trial, ordinary six-bar triggers and Trust
   navigation as regressions. Toggle menu swap OFF and confirm original roles.

Automated coverage includes actual bank ownership and view caches/lifecycle,
fast/held/empty/multiple-slot feedback, neutral shared-setting adoption, actual
root message routing and hints, plus the existing Lua/AHK simulation suites.
Native Windows/Windower/FFXI visual/input acceptance remains pending.
