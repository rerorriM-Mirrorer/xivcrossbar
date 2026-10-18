# DirectLink development roadmap and render diagnostics

October 18 update: full companion banks are now implemented on
development/directlink, runtime directlink1-banks2 / Controls 9.9-banks. See
[the current bank guide](SHOULDER-BANKS.md) for saved L1/L1L2/R1/R1R2 definitions,
context maps, native key service and editing. The earlier roadmap below is a
historical planning record: unified ownership/key delivery is implemented and
simulated-tested. NPCMirror/SlowEnter factory commands, short bank editors and
default restoration are implemented. Live/event access acceptance is next.
Graphical/catalog assignment, success-confirmed switches, icon/folder restructuring and other
controller profiles remain future work. Existing text/shared fixes carry forward.

Reviewed October 17, 2026, America/Chicago. Author A.
Initial review source: 86b50f103425d1ed871d7612735d2d4fa6e3126c.
Updated after the authorized diagnostic checkpoint based on c8f198a, on
development/directlink. Chooser repair and render trace are now implemented;
their live acceptance is pending. The following R1 checkpoint adds R on unused
R1 release; other controller mappings remain unchanged.
Snapshot 1 remains preserved on snapshot/directlink-unbound-20261016.

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

### Text settling checkpoint 1

Implemented on development/directlink after realkeys1; native acceptance pending.
ui/text_measure counts render frames, ignores same-frame extents after a caption/
style change, and accepts matching positive widths on two later frames. A bounded
512-entry cache holds only caption/font/pixel-size/padding/style keys and widths.
ui/resources preserves requested glyph/stroke/background alpha while pending;
centering/font fitting finish before commit restores it. Hide releases ownership
so a text object reused outside its former centering helper cannot stay invisible.

L1 labels, ui_geometry centers and ui/text_layout binder captions use this path.
L1's render cache remains invalid while measurement is pending, including stale
positive widths. Eight frames bound missing/unstable measurements with a fixed
position fallback that is not cached. No new timers or drawing objects. Matching
widths are a heuristic: Windower does not return the caption revision with extents.
Verify alpha-zero extent updates, first/repeated reveals and low-frame-rate cases
live; //xb textsettle off provides a comparison. TextSettling defaults ON and is
refreshed with per-character config. Trace adds text-settle state transitions.
Actual-source tests replay the captured 0->73 and 211->416 width sequences,
font fit, scale/fade/dimming, rapid replacements, cache bounds and lifecycle.
The sequence below remains the preceding plan; item 2 now awaits live acceptance.

### October 17 update: input ownership before new banks

The opt-in real-IJKL comparison is implemented on development/directlink,
default OFF. //xb realkeys on lets AHK own ordinary D-pad I/L/K/J and mask those
directions from DirectLink; no duplicate Lua setkey is emitted for that gesture.
Requires profile x/messages on/dpad ijkl/inputtest off, updated Lua and AHK,
and neutral handoff. This is a small routing experiment, not the general Lua
gesture owner/native-key output service proposed below. Trust consumption is
separate work in its own conversation; no integration success is claimed here.

Recommended sequence:

1. Validate real IJKL with Trust closed/open, native menus, every trigger order,
   held-direction transitions and client/focus/lifecycle cleanup. Easiest useful
   experiment; establishes which keyboard events Trust actually receives.
2. Fix text settling from the supplied capture, an isolated high-visibility
   repair. Frame 334 object 546 Ctrl+Space is shown at alpha 255 with width 0
   and x=238; frame 335 width 73 moves x to 201.5. Other changed captions can
   report a stale positive width, so testing only for zero is insufficient.
   Caption/font/size/scale-aware measurement reuse and a bounded invisible
   settling pass are candidates; no rendering fix is included here.
3. Establish one context/press-ownership contract before new bank execution.
   Lua decides meaning; AHK handles hardware and required Windows key output.
   Keep visibility separate from action permission and retain each press's
   owner through release. This is the most foundational design work.
4. Add editable per-layer labels/actions and contextual L1, then R1 Trust and
   ordered R1->R2 NPC interaction banks. L1->L2 remains mostly free for tests;
   trigger-first orders keep ordinary bars. Do not fill NPC commands speculatively.
5. Centralize asset paths/legacy references, then migrate the default pack to
   images/icons/default and optionally themes to images/themes. Shared numeric
   fallback art can serve partial alternate packs; no duplication requirement.
6. Move broader module families last, in small loader-tested batches. Folder
   churn should not be coupled to input behavior or text layout repairs.

Latest desired L1 closed-menu map (not implemented): Up Items/Ctrl+I, Right
Equipment/Ctrl+E, Left input /wardrobe, Down input /wardrobe2; Triangle Case,
Square Sack, Circle Satchel, Cross Jump, with direct game commands where
appropriate. Native-menu map: Up Ctrl+Left, Down Ctrl+Right, Left Alt+Left,
Right Alt+Right; Triangle Wave, Square Bow, Circle Nod, Cross Jump. These
supersede older equipment-on-R1 brainstorming below. Keep companion hidden
in native menus; arbitrary saved bank execution remains guarded by default.

Other retained follow-ups: exact per-bank editing commands, multibox/neutral
acceptance, a separate public RC3 port, other-controller message profiles,
optional mute-held bank and success-confirmed temporary-bank return. Movement
receiver remains separate; only the old standalone L1 addon is redundant.

| Item | State and intended result |
| --- | --- |
| Quiet render trace | Implemented, local checks pass; live capture needed. Default OFF, 6,000-event memory ring, explicit save, no overlay or extra native measurements. |
| Text flicker/recentering | Shared settling comparison implemented after the supplied trace; local replay checks pass. Native alpha-zero measurements and visual acceptance remain pending. Earlier blank-caption prevention alone did not resolve it. |
| Options chooser cancel error | Repaired missing layout-aware binder helper and earlier face-button discard in shared router. Actual-source regression checks pass; full live chooser restoration still needs acceptance. |
| Active-route status wording | Implemented: requested/active route and key fallback modifier are labelled separately. Live status check pending. |
| DirectLink acceptance | First live operation is confirmed; all six bars, modifier orders, fast rolling inputs, addon/native menus, focus/client handoffs, disconnect/restart, cutscenes and low-frame-rate behavior still need systematic acceptance. |
| Public RC3 message-mode port | Desired next public experiment after isolation/acceptance. Port a generic optional transport with its dependencies/tests; preserve public defaults and exclude personal mappings. No port is claimed yet. |

## Invisible render diagnostics

Existing tools are //xb controller trace on|off (buffered, bounded input capture)
and //xb resources (one-shot resource counts). The new render trace records
caption positions, measurements and native draw requests.

Implemented commands (default OFF on load):
- //xb rendertrace on: bounded detailed capture.
- //xb rendertrace mark: timestamp a noticed jump while preserving earlier events.
- //xb rendertrace save: dump the retained capture.
- //xb rendertrace off: save and stop detail capture.
- //xb rendertrace status (or bare): report capture state/counts.

A 6,000-event memory ring retains recent events, with counters for unchanged
calls and overwritten records. Every actual caption write is retained, including
unchanged text. Save promptly after marking a hop: busy activity can overwrite
older records. Explicit save/off writes data/render-trace-<character>.log,
overwriting the previous save. Capture does not persist across reload/unload.
Measurements/setters are existing calls only; no native queries are added.
Local native-call parity checks pass. The simulated benchmark shows measurable
overhead; live OFF/ON comparison is still needed (see TESTING).

| Record | What it helps distinguish |
| --- | --- |
| Frame ID, monotonic time, frame gap, set/layer/page/context and transition reason | Normal set/page/fade transitions versus a hitch or unintended rebuild |
| Stable object ID, owner/layer/role, caption revision and actual caption setter writes | Reusing a caption versus repeated rewrites or replacing it with a new object |
| Font/style/size, existing returned extents, desired center, requested final x/y, screen size and scale | A stale/zero width becoming current, font fitting, viewport/scale changes or competing layout writers |
| Visibility, alpha/stroke changes and hide/show requests | Recentring versus opacity flicker or repeated reveals |
| Object create/destroy/retire events and call counts | Resource churn, leaks or duplicate layers |
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
The trace helps distinguish those patterns. It records requested operations
and returned measurements; it cannot by itself certify which pixels the game
finally displayed. A short matching video can help correlate that last step if
needed. No packet injection or Windower-core replacement is proposed.

The user's opacity-until-settled idea remains a candidate: keep a changed label
transparent through its width/fit revisit, then restore its intended alpha,
including stroke/background and current fade state. Validate that transparent
text still updates native extents; prevent zero-width text remaining invisible.
No opacity change is included before a capture identifies the affected path.

## Controller and menu design still open

| Idea | Latest constraint / status |
| --- | --- |
| L1 inventory/item cluster | Shapes could open the most-used inventory/menu actions, including Sack. Final map not chosen; do not auto-install custom Windower bindings. |
| R1 equipment/wardrobe cluster | Shapes could open equipment/wardrobes. Bare R1 now sends R on unused release; existing chords consume the hold. Further remapping remains undecided. |
| L1 directional scrolling | Proposed only while native menu_open is true: Left/Right = Alt+Left/Right; Up/Down = Ctrl+Left/Right. Closed menus retain existing shortcuts. Companion remains hidden in native menus. Not implemented; no remap installed. |
| R1 and R1→R2 companions | An R1 reference and an upper-right R1→R2 action bar remain ideas. Existing R1 direct arrows/Enter/Escape/Trust shortcut remain. |
| R2 directional quick menus | Temporary magic/ability/item/combat choices were brainstormed; no agreed state machine or bindings yet. |
| Trust menu integration | Investigate direct logical navigation/IJKL/Enter support and command-driven menu opening; retain the working raw-input route until compatibility is verified. The Trust thread is also developing AUTO/MANUAL behavior. |
| Personal routing in Lua | Ordinary buttons are messages now; personal gestures still decide some meanings in AHK. A general Lua→AHK request path for Windows key delivery is proposed, not implemented. One owner must retain each press through its release. |
| More specific native menu context | menu_open already supplies the broad open/closed guard. Main/item/other menu identity and appropriate output routing need investigation; do not assume the boolean identifies the exact menu. |
| Success-confirmed quickswitch | A requested action can retain its temporary bar until correlated action evidence arrives. Engagement alone cannot confirm Sic. Design explicit waiting/success/failure/cancel states; retain bar on failure, require another press to retry, and cancel pending tracking on context/target/pet/job/zone/focus changes. Exact Sic evidence needs a controlled observation before implementing a matcher. |

The user's existing external shortcuts are Ctrl+I/M/E/J for Item/Magic/Equipment/
Job Ability and Ctrl+Space/Q/S/1/2/3 for jump/quest/sack/wardrobe/wardrobe2/
wardrobe3. These are user bindings, not defaults installed by this review.

### What DirectLink changes for shoulders

L1 show/release/bank-slot events already use a mailbox, but the personal AHK
filter still consumes L1 shortcut buttons and emits Ctrl keys. R1 combinations
also emit native keys. Simply adding a Lua Triangle handler would not see those
consumed edges. The next routing step would feed ordered shoulder/button state
to Lua, give Lua ownership of gesture meaning, and retain AHK as hardware reader
and optional native key-output service. Native menu scrolling can still need
Ctrl/Alt+arrows; press ownership must keep their key-ups/modifier releases correct
if a menu closes mid-hold. Chat/addon-menu/trigger-order guards take priority.

Lua could independently show a reference and run input /sack from one fresh
L1+Triangle gesture. The existing native-menu visibility guard can still hide the
reference; drawing and command execution need not depend on one another.
This would bypass the user's Ctrl+S binding, not remove the game-command parser.

Remaining keyboard paths: personal L1 shortcuts, R1 menu/Trust combinations,
L1+R1 Tab, native click/touch/PS behaviors, R3 F8 and the TrustMovement takeover
marker (vk1Dsc07B). Bare ordinary native gameplay uses Lua setkey. Optional
legacy Apps/F-key transport still exists for comparison/other profiles, with its
silent bindings installed. None of those are ordinary transport emissions while
the message stream owns the twelve buttons. TrustMovement's hidden marker is a
separate remaining transport candidate, not already converted by DirectLink.

Keep R3 F8 for now: its existing AHK-to-game path avoids a new Lua message hop.
Do not substitute /focusnpc without verifying such a command. Direct commands
are attractive for named actions; keyboard delivery remains useful for native
navigation and keyboard-listener addons. Fewer layers depends on the operation.

Other controller readers already normalize the same twelve logical slots in
the common wrapper. That makes transport reuse feasible for PS5 standard, F710,
FightPadPro and XInput; it is currently enabled only by the PS5 Extended context
lease. Generalize lease/profile eligibility and validate each reader's neutral,
disconnect, trigger threshold and ownership behavior separately. Shoulder/Mute
availability is hardware-specific; do not copy PS5 Joy numbers to other readers.

Input acknowledgment means the Lua receiver accepted a transport batch; it is
not confirmation of game/server action success. For quickswitch success, first
observe a matching actor/pet/action/target result in a bounded attempt window,
including failures and unrelated actions. Action events may suffice; packet
captures are warranted only for unresolved evidence. Do not auto-retry attacks.

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

1. Live-check repaired chooser cancellation, including restoration and Options release.
2. Reproduce the hop with the implemented bounded render diagnostic and examine
   measurements/placement/visibility before choosing a rendering fix.
3. Verify clarified route status and keep testing DirectLink under real client load.
4. Trial native-menu-only L1 scrolling, then settle inventory/wardrobe/Trust mapping
   and move shoulder meanings into Lua in a separate controlled batch.
5. Public DirectLink port belongs in the user's separate conversation.

Other roadmap items remain proposals; this checkpoint does not activate every
historical wish or change controller mappings.
