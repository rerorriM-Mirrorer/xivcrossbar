# DirectLink development roadmap and render-diagnostic proposal

Reviewed October 17, 2026, America/Chicago. Author A.
Current source: 86b50f103425d1ed871d7612735d2d4fa6e3126c on development/directlink.
This is a planning/source-review record. No runtime, settings or controller mapping
is changed by it. Snapshot 1 remains preserved on snapshot/directlink-unbound-20261016.

Sources: current README/PERSONAL/TESTING, current rendering/router/binder source,
the visible controller-design conversation, retrieved earlier project notes,
and the already-reviewed uploaded trace/chat/console evidence. Historical assistant
summaries are leads, not proof that a feature remains absent. Current source and
the user's latest decisions take precedence.

Reviewed shared NPCMirror WORKFLOW (bc17a173c779a7b921aed1d4bf8c539368aa3730)
and current project WORKFLOW/AGENTS. Their workflow instructions match; only
trailing blank lines differ. Preserve existing history, distinguish source/
simulated/live results, and use small development changes.

## Immediate work

| Item | State and intended result |
| --- | --- |
| Quiet render trace | Proposed; not implemented. Correlate caption/layout changes with the visual hop without adding an overlay or chat spam. |
| Text flicker/recentering | Still reported. Test 5 stopped clearing populated labels before replacing them, but that is not proof the visible hop is fixed. |
| Options chooser cancel error | Confirmed source defect to repair: xivcrossbar.lua calls action_binder:is_cancel_button(button), but the current action_binder module defines no such method. The supplied console has matching earlier Test 4 errors. Do not confuse this with evidence of a new DirectLink transport failure. |
| Active-route status wording | Pending polish: Selected/Running still shows apps as fallback modifier even while Button route=messages. Show active route and fallback distinctly. |
| DirectLink acceptance | First live operation is confirmed; all six bars, modifier orders, fast rolling inputs, addon/native menus, focus/client handoffs, disconnect/restart, cutscenes and low-frame-rate behavior still need systematic acceptance. |
| Public RC3 message-mode port | Desired next public experiment after isolation/acceptance. Port a generic optional transport with its dependencies/tests; preserve public defaults and exclude personal mappings. No port is claimed yet. |

## Proposed invisible render diagnostics

Existing tools are //xb controller trace on|off (buffered, bounded input capture)
and //xb resources (one-shot resource counts). They do not yet record the history
of caption positions, measurements or native draw requests.

Proposed new commands, NOT currently implemented:
- //xb rendertrace on: bounded detailed capture.
- //xb rendertrace mark: timestamp a noticed jump while preserving earlier events.
- //xb rendertrace save: dump the retained capture.
- //xb rendertrace off: stop detail capture.

A small bounded event buffer can retain recent history, with sampled counters
for long sessions. File output should be batched/on save, not per setter or every
render frame. Capture related events across a frame, not just a final screenshot.
Only annotate measurements and setter calls the runtime already makes; avoid
extra extent queries that could alter the timing being investigated. Measure
diagnostic cost with it off/on before calling it lightweight.

| Record | What it helps distinguish |
| --- | --- |
| Frame ID, monotonic time, frame gap, set/layer/page/context and transition reason | Normal set/page/fade transitions versus a hitch or unintended rebuild |
| Stable object ID, owner/layer/role, caption revision and actual caption setter writes | Reusing a caption versus repeated rewrites or replacing it with a new object |
| Font/style/size, existing returned extents, desired center, requested final x/y, screen size and scale | A stale/zero width becoming current, font fitting, viewport/scale changes or competing layout writers |
| Visibility, alpha/stroke changes and hide/show requests | Recentring versus opacity flicker or repeated reveals |
| Object create/destroy/retire counts and disposal attempts | Resource churn, leaks, stale objects or duplicate layers |
| Input/transport transitions and a shared timestamp/marker | A trigger/set switch preceding the visual change |

Source-supported lead, not a confirmed cause: ui/text_layout.lua revisits extents
and visibly corrects centered captions on prerender; fitting can change font size
and defer another update. ui_geometry.lua also recalculates centered surfaces
from native extents. Logging these paths can show whether a caption was first
drawn with one width/position and corrected later. Main action labels are normally
left-aligned, so a hop there may instead involve text rewrites, object/geometry
changes or native rendering. Trace the relevant surface rather than assuming all
text uses the same centering helper.

A change of extents/position for the same caption revision differs from two
layout owners moving it in one frame, which differs from repeated object creation.
The trace should make those distinctions visible. It records requested operations
and returned measurements; it cannot by itself certify which pixels the game
finally displayed. A short matching video can help correlate that last step if
needed. No packet injection or Windower-core replacement is proposed.

## Controller and menu design still open

| Idea | Latest constraint / status |
| --- | --- |
| L1 inventory/item cluster | Shapes could open the most-used inventory/menu actions, including Sack. Final map not chosen; do not auto-install custom Windower bindings. |
| R1 equipment/wardrobe cluster | Shapes could open equipment/wardrobes. Bare R1 is currently free; R was suggested, not assigned. |
| L1 directional scrolling | Proposed Left/Right = Alt+Left/Right; Up/Down = Ctrl+Left/Right. Preserve navigation in native item menus. Not implemented. |
| R1 and R1→R2 companions | An R1 reference and an upper-right R1→R2 action bar remain ideas. Existing R1 direct arrows/Enter/Escape/Trust shortcut remain. |
| R2 directional quick menus | Temporary magic/ability/item/combat choices were brainstormed; no agreed state machine or bindings yet. |
| Trust menu integration | Investigate direct logical navigation/IJKL/Enter support and command-driven menu opening; retain the working raw-input route until compatibility is verified. The Trust thread is also developing AUTO/MANUAL behavior. |
| Personal routing in Lua | Ordinary buttons are messages now; personal gestures still decide some meanings in AHK. A general Lua→AHK request path for Windows key delivery is proposed, not implemented. One owner must retain each press through its release. |
| More specific native menu context | menu_open already supplies the broad open/closed guard. Main/item/other menu identity and appropriate output routing need investigation; do not assume the boolean identifies the exact menu. |

The user's existing external shortcuts are Ctrl+I/M/E/J for Item/Magic/Equipment/
Job Ability and Ctrl+Space/Q/S/1/2/3 for jump/quest/sack/wardrobe/wardrobe2/
wardrobe3. These are user bindings, not defaults installed by this review.

## Older optional ideas to retain, not silently reactivate

- Graphical/catalog assignment for companion slots, rather than only command editing.
- Additional banks/arbitrary button banks only if useful; the user explicitly found
  bank switching onerous. Do not make multiple banks the next default.
- Icon catalog/folder organization and remaining personal menu ordering/artwork.
  Some order changes already exist, including Ranged Attack → Attack → Check → Assist.
- A Mute-held experimental bank. Joy15 is already identified; do not rediscover
  it as if unknown or assign a production key without a chosen behavior.
- Independent trigger-field fade retaining its last position; explicitly dormant.
- Optional FFXI-style menu open/close sounds and remaining old menu-skin ideas.
- Texts.Color.Alpha semantics/wiring: setup_text still does not consume a font_alpha
  setting. Define whether this controls labels/costs/etc. before wiring it.
- Standalone-addon work-while-hidden audit. The internal autoattack Enabled gate
  exists; hiding an addon does not automatically stop all its processing.
- Older conversation wishes for true slot swapping, a fuller multiline editor,
  richer charge presentation and binding unloaded-job actions. These need fresh
  source/design review before becoming committed tasks. Copy/move commands and
  SCH charge handling already exist; this is not a claim those are absent.
- Explicit new-set scope without naming prefixes was an older design wish.
  Recheck the current storage model before specifying a new UI.
- A screenshot-guided setup guide and broader XInput/F710/FightPadPro validation;
  their readers exist, but PS5 Extended is the confirmed route discussed here.
- Shared's historical display-versus-execution fallback discrepancy remains a
  low-priority design question. Shared is disabled by default; no new Shared
  fallback provider is authorized or implemented.

## Completed or substantially implemented — remove from active missing-feature lists

- Ordered messages for the twelve ordinary buttons; first live transport confirmation.
- Preserved DirectLink Unbound Snapshot 1 and separate ongoing development branch.
- One momentary L1 reference; L1→L2 bank in the same location; L2-first priority;
  reveal L1 after releasing L2; held-slot guards; compact PS icon geometry/scale following.
- Basic's display name Main without changing internal keys; Shared off by default.
- R3 F8 acquisition with R on unused release; R2 F8 off by default; no bare R1 F8.
- x/r2/r3/both private shortcuts, profile selection, PS application focus and
  the retained touch/click/zoom personal gestures.
- Save Only catalog return and selection; single-screen custom-action review.
- Global/character catalogs, source-owned edits, linked-binding updates and
  deletion snapshots, with concurrency/failed-write guards. Broader native
  multiclient acceptance still matters.
- Stable server/character storage gating, pre-login input, last-client wrapper
  shutdown, mutex and graceful lifecycle commands in the personal line.
- Compact switching, scale/drag/position persistence, text-fade option, slot dim/
  feedback repairs and autoattack processing gate.
- Default/Job Default/All Jobs Default switch destinations and shorter-list pagination.
- Existing summon/release and arts-based environment switching; do not relist
  automatic SMN switching wholesale as a missing feature.
- Trust movement takeover, once per newly piloted client, with quiet receiver.
- Public RC3's four recent candidates (pagination, identity gate, default-set
  destinations, Save Only return) are present in published dc5e02e. Older public
  TESTING wording that says NOT PUBLISHED is historical/stale, not an undone port.

Implemented does not mean every historical acceptance test passed. Current
reports do not prove that every desktop stickiness/native crash/shared text-loss
cause has been eliminated.

## Superseded control plans

Keep out of the active queue unless the user revives them: L1 bare-release client
switching or bank toggling; held Ctrl/Alt shoulder-pair latches; bare R1 F8;
automatically enabling R2 F8; changing Basic's internal storage key. The PS focus
toggle supersedes earlier generic single-client minimize/restore discussions.
L2→L1 ordinary-bar priority, momentary L1 behavior, native-menu companion hiding
and the usable Trust/navigation routes remain explicit constraints.

## Related projects, tracked separately

Pathfinder/path recording, Sparks buying and NPCMirror development remain desired
adjacent work. Trust's AUTO/MANUAL transition and optional party/connected-client
follow/assist/start/stop behavior live in its own project. Keep useful crossbar
commands/bindings in view without describing these other addons as unfinished
XIVCrossbar runtime features.

## Suggested next sequence

1. Repair the confirmed chooser-cancel method mismatch in an isolated change.
2. Add the bounded render diagnostic; reproduce the hop and examine measurement/
   placement/visibility/resource events before choosing a rendering fix.
3. Clarify active-route status and keep testing DirectLink under real client load.
4. Settle the inventory/wardrobe/Trust mapping through small trials.
5. Port generic message transport into public RC3 as a separate optional experiment.

This sequence is a recommendation from the review, not a claim that these changes
have been implemented or that old optional controls were reapproved.
