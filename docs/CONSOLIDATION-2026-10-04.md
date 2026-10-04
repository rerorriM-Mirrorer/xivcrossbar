# XIVCrossbar consolidation: 2026-10-04

The ideal next test is one full crossbar installation with the controls already
enjoyed, two remaining Lua changes to verify, and an exact return to the captured
installation. The problem was that the private NPCmirror repository, a partly
published branch, later downloadable batches and the running installation
contained different generations of the work.

## Captured working installation

Source: uploaded `xivcrossbar.zip`, captured as the current working installation
on **2026-10-04 (America/Chicago)**. This records the user's report of what was
running; a folder copy cannot prove which external AHK process or PC-side native
controller settings were active. ZIP timestamps are retained, not interpreted
as evidence that a feature was tested.

- Archive: 10,825,563 bytes; 2,348 files plus directory entries.
- SHA-256: `d55bc5922c9ae82fd6c865dacf528bd8c04cfb408c2c33e00269dee9ef32b94d`.
- Exact dated rollback: `XIVCrossbar-working-installation-2026-10-04.zip`.
- Full per-file hashes accompany the complete test package.
- Public source checkpoint: `snapshot/working-source-2026-10-04`. It captures
  source only; the rollback ZIP also restores personal data/caches/AHK files.

The test package retains every captured file except the eight consolidated Lua
modules and README. The binder, selector, defaults, player, drag and visibility
modules receive attribution comments only; their behavior matches the capture.
Only `ui.lua` and `xivcrossbar.lua` receive the later Lua behavior changes; the
entry point also gets build ID `0.4.0-a.20261004.1`. Repository docs, tests and
optional experiments are added. No captured XML, INI, AHK, backup, cache or image
bytes are replaced.

## Effective captured settings

| Setting | Global | Cioara's override |
| --- | --- | --- |
| Hotbar.Number | 4 | 3 |
| UseAltLayout | false | inherits false |
| iscompact | true | false |
| VisibilityMode | Always | OnInput |
| VisibilityGrace | 0.25 s | 5 s |
| Controller | DirectInput on; XInput off | DirectInput off; XInput on |
| FrameSkip | 1 | 0 |
| UI offsets | X=0, Y=0 | X=13, Y=-44 |
| Text size | 8 | 7 |
| Stop AHK on unload | true | false |

These actual files take precedence over earlier suggested all-DirectInput or
all-four-bar settings. Asura and Fenrir profiles, backup folders, all custom
action catalogs and current Shared/job bindings are retained. The previous
repair's own notes say it preserved non-All-Jobs bindings and reversed aggressive
catalog pruning. The newer October 4 profile bytes in this capture prevail.

## Sources compared

| Source | Exact revision/evidence | Finding |
| --- | --- | --- |
| qEagleStrikerp-derived fork master | `15d8381dfad0f9efdb84fe2d24655afc150faec4` | Upstream assets/modules preserved; local work had not yet been transplanted here |
| NPCmirror main | `bc991ec77d6740efb929c6186500b40dd92eccb1` | PR #1 merged; binder and selector match the captured source |
| NPCmirror cumulative branch | `0a0b2c7667bb6a108ec58584befb4d573e95e3ba` | Only four changes beyond its merge base: AddonToggle, defaults, drag helper and visibility helper; main/ui/player integration was absent |
| Latest cumulative Lua archive | `xivcrossbar-current-code.zip`, October 2 | defaults/player/drag/visibility byte-match the capture; ui/main contain the two remaining changes |
| Review archive | `xivcrossbar-review-batches.zip` | Recovered full later source, tests, reports, optional AHK and utility generator |
| Conversation evidence | September 30–October 4 feedback and uploaded plans/logs | Separates reported live use from later offline-only checks |

The older archive's checkpoint `bfb38eb5394bdefdfb8612ebe9c74d9466d98491`
and intermediate batch IDs are documented as local/unpublished. They are
provenance labels, not asserted reachable GitHub commits. The new fork receives
new coherent commits, rather than pretending those local commits were pushed.

## Tested versus still needing testing

| Behavior | Evidence/status |
| --- | --- |
| Quick custom-action creation, remapped controls | User reported in-game use/approval on October 2; captured binder/main contain the fixes |
| Draggable UI and autohide | User explicitly reported liking both after in-game use on October 2; present in this capture |
| Back/Cioara/Next switching and existing combat/Shared controls | Earlier September 30 live report; preserved latest profile bytes |
| Full icon navigation/edit/save/reload matrix | Offline regression coverage; broad approval does not prove every edge case was tested live |
| NPCmirror | User did test it live; partial target/menu failures were reported. That is separate from proving all NPC paths reliable |
| Sparse four-bar rendering guard | Later archive fixes missing bar/page lookups in show and MP/TP checks; absent from capture; requires this next live test |
| `ui hide/show/auto` | Later archive only; session overrides preserve cutscene priority; requires this next live test |
| Quick Switch stale-return cancellation | `player.lua` and corresponding main code already in capture; functional prototype still deserves live regression if used |
| New shoulder target injection | Uploaded logs show detected L1/R1 presses; user reported no target cycling. Failed/unfinished, not accepted |
| New release-only L3 switching | Latest prototype uses measured Joy11; no multi-client acceptance. Older Joy12/WinActivate success is a different experiment |
| Travel/Utility page XML and AddonToggle 2.0 | Prototypes; not installed over the user's current files |
| CPU/FPS/memory improvements | Not measured in-game; hidden-render suppression is code behavior, not a demonstrated performance result |

The controller measurements were L1=Joy5, R1=Joy6, L3=Joy11, R3=Joy12,
PS=Joy13 and Mic=Joy15. Both uploaded `(1)` logs recorded FFXI focus and
matched press/release records. Physical Tab/Shift+Tab worked; synthetic shoulder
input did not. R3/PS/Mic receive no new default assignment here.

## Existing issues and later work

- One older catalog, `data/hotbar/Asura/Franklet/CustomActions.xml`, has a
  mismatched XML tag at line 5. It is unchanged in the complete package and
  rollback. The 42 current Fenrir XML files parse successfully. Do not treat the
  entire captured folder as verified for every historical character/server.
- Visibility grace remains limited to 0–5 seconds; the October 4 request for
  longer grace, autohide command aliases/default changes and an outlined edit
  area is future work. Those notes are requests, not completed patches.
- The reported reveal hitch and mouse-camera feel need live observation.
- An extra Shift action bank, new default action placements, slot swapping and
  broader NPC/menu adapters remain later work.
- Custom-action edits refresh currently loaded bindings; other job files may
  retain saved command snapshots until rebound. A remaining unspecified
  historical selector error needs its exact error if it recurs.

Use [the short next test](TESTING-2026-10-04.md),
[the dependency map](DEPENDENCIES.md) and
[the GitHub inventory/access report](GITHUB-ACCESS.md). This conversation can be
the development interface; these files and branch commits keep its decisions
reviewable independently of chat history.
