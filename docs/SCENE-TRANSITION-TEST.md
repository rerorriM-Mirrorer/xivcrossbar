# Scene Transition 1 — A — October 24, 2026

Runtime `0.4.0-a.20261024.directlink1-scene1`, Controls `9.18-bankheld1`
unchanged. Cumulative patch includes Dialogue Controls 1, Bank Feedback 1,
Shared Menu Buttons 1 and earlier Cleanup 1 forward fixes. No data/artwork reset.

User saw the crossbar briefly appear/disappear with labels and a doubled or
misaligned-looking overlay during Fhelm Jobeizat interaction. Supplied render
trace at 20:46:27Z records 144 text objects (48 captions/costs/recasts each) shown
then hidden near 1792874816.1–4816.4 with active bar 0. It records native calls,
not GPU pixels: actual displacement/image overlap is not proven by this log.

Source contained two competing reveal paths: status exit called ui:show directly,
bypassing visibility policy; ui:show revealed slots/text/images across every bar
before check_recasts selected the intended layers. Both are corrected. Status
changes now invalidate visibility and force a render; that render decides whether
the panel belongs on screen, then selects active/default bars and their surfaces.
The reveal entry point starts the fade/hints without blanket slot visibility.
No geometry, position, binding, artwork, normal bar-selection or fade-setting
changes. This targets the observed transition, not a claim all flicker is solved.

Install: stop the shared wrapper, unload XIVcrossbar on participating clients,
merge the patch's xivcrossbar folder into the installed addon preserving data and
artwork, reload all, then restart the wrapper once neutral. No new toggle needed.
The optional shared Share/Options swap keeps its saved state.

Live checks:

1. Revisit Fhelm Jobeizat. Bare Cross/Circle confirm/cancel; D-pad moves native
   choices even with gameplay IJKL. See DIALOGUE-CONTROLS-TEST.md for ownership.
2. Enter and leave dialogue with no triggers held under autohide: no brief panel,
   all-bar labels or doubled slot layers. Repeat with always/hidden visibility.
3. Hold each trigger before/after a scene transition. Only intended default or
   active bars appear, without stale labels from another layer. Test double and
   ordered trigger bars afterward. Existing scene action restrictions remain.
4. Repeat with native chat, Trust and XB editor/chooser open/closed; no inactive
   bar surfaces should flash. Confirm companion-bank autohide/feedback unchanged.
5. Try at 30/60 fps and laptop resolution. A short render trace with a mark just
   after any visible glitch would distinguish remaining cases; no trace required
   unless the problem recurs. Render tracing does not intentionally alter visibility.

Automated checks exercise real status callback invalidation and full UI/recast
rendering for 14 active/default/extra-bar selections. They record native show
requests across nine slot-surface types and reject any inactive-layer reveal,
including intermediate calls before selection. Native Windows/Windower/FFXI
visual acceptance remains pending.
