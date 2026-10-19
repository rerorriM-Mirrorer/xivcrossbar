# DirectLink held-input recovery test 1 — October 19, 2026

This is the short in-game guide for the **complete personal DirectLink** test
package. It incorporates the shared command fixes, four companion banks,
optional real IJKL comparison and text settling. It is **not** the public RC3.
The cumulative record and detailed edge cases remain in `TESTING.md`.

## Banks 3 layout and menu acceptance

For this hold fix, update both Lua and AHK, reload each client, and restart the
shared wrapper once; expect Controls 9.10-holdfix. See HOLD-RECOVERY.md. Preserve installed data and art. New fields
merge without changing assignments. The Cioara layout is opt-in per character:

```
//xb bank preset cioara apply
//xb r1 status
//xb r1r2 status
//xb l1l2 status
```

Back up data/settings.xml first: the preset replaces all four companion layouts
and old L1L2 assignments. L1 becomes NPC/tests; current L1 inventory moves to
L1L2; R1 gets Cioara client directions / Ready / Stand Down / Toggle / Trust open;
R1R2 gets Trust navigation and starts hidden. Ordinary crossbar sets are untouched.
The existing personal Send/Switch/SAT/all-alias dependencies are not installed.

Hold R1 over a native game menu: its bank should remain visible. Hold R1 then R2:
the panel should disappear but directions/confirm/back/open/close should still
work in Trust. Test safe choices and verify physical releases do not leak.

Open the battle command menu and try L1 then L2 inventory commands; the preset
uses Closed bindings even if native menu_open is true. This tests output routing,
not a guarantee that FFXI accepts each command in every state. For the saved
scrolling/emote layer in actual item menus:

```
//xb l1l2 menuactions on
```

To restore always-available opening bindings: `//xb l1l2 menuactions off`.
Per-bank `show|hide` controls artwork; `menus on|off` controls drawing over native
menus. Trust's addon menu has no detection in this change; hide R1R2 entirely.
Capture any failed command/menu context and the exact chord. The old compact
Options flash still needs identification; the previous patch did not resolve it.

## Install and identify

1. Back up the existing personal `Windower/addons/xivcrossbar/` folder, including
   `data/`, `config.ini` and any added images. Do not delete those files. Keep
   the public variant on a separate installation; both use the same addon name.
2. From every running FFXI client, stop the shared controller wrapper and unload
   XIVCrossbar. Extract the ZIP's `xivcrossbar/` folder into `Windower/addons/`,
   updating addon files but **preserving** installed user data and custom art.
   The ZIP contains no character XML, saved settings, INI or bindings.
3. Reload XIVCrossbar and **restart the AHK wrapper** with controller buttons
   released. A Lua reload alone does not update the wrapper. Check:

   ```
   //xb controller profile x
   //xb messages on
   //xb inputtest off
   //xb inputstatus
   //xb controller status
   ```

   Expect runtime `0.4.0-a.20261019.directlink1-holdfix1` and wrapper
   `Controls=9.10-holdfix`, banks protocol=1/enabled=1 and receiver=true after
   neutral. If the wrapper version
   is older, stop here and restart it before judging controller behavior.
4. **Trust prerequisite:** The R1 Trust-menu tests require the compatible Trust
   *Menu options Test 4* installation plus its
   [explicit Open addendum](https://github.com/rerorriM-Mirrorer/trust/commit/17d0f9cc1e8dd400c70ae8411e4ff805d9868129)
   (`trust/commands/MenuCommands.lua`). Reload Trust and verify its menu status
   reports explicit Open. This XIVCrossbar ZIP does **not** install or overwrite
   Trust or TrustMovement. If that Trust version is not installed, skip the
   R1-menu checks for now; the other checks are still useful.

## First ten minutes

Use an ordinary, safe gameplay area on one character. Release all controller
buttons between different tests. Simple observations are enough.

1. **Ordinary input:** Move with the stick. Try L2, R2, both trigger orders,
   face buttons, D-pad, and R3 targeting. Check for missed, repeated, or stuck
   inputs. Reveal and hide the L1 bank; try L1 then L2 and release in both
   orders. Existing saved L1L2 commands should still work. R1 then R2 reveals
   the NPCMirror/SlowEnter bank at the right; R2 then R1 stays ordinary. Cleared
   slots must not leak native face actions. Releasing a bank trigger first
   returns to its bare shoulder; releasing its shoulder first consumes the tail.
2. **R1 + Trust:** Hold R1 then press Triangle to open Trust. Press Triangle
   again from inside a submenu; its cursor and unsaved draft should remain.
   R1+Square closes Trust, subject to its usual save/validation rules. Try
   face-first and R1-first order, and release in both orders. No extra R,
   ordinary Square/Triangle, or Ctrl+Numpad action should escape. R1 arrows,
   Cross/Enter, Circle/Escape and unused-R behavior should remain intact.
3. **L1 inventory and menus:** With the game menu closed, test Up Items,
   Right Equipment, Left Wardrobe, Down Wardrobe 2; Triangle Case, Square Sack,
   Circle Satchel, Cross Jump. With a native menu open, panels should hide and
   L1 directions become Ctrl+Left, Alt+Right, Ctrl+Right, Alt+Left (Up/Right/
   Down/Left). L1 Triangle/Square/Circle/Cross becomes Wave/Bow/Nod/Jump.
   Keep a slot held while the menu changes: it must wait for release/new press.
   Trust's own menu is not necessarily the native-menu flag. R1 navigation
   should still work. Chat and XIVCrossbar editors/choosers have priority.
4. **Text settling:** Try `//xb textsettle status` (default ON). Reveal L1,
   change pages/sets, and open the binder. Notice any label that jumps,
   appears late, is incorrectly centered, or remains invisible. Compare with
   `//xb textsettle off`, then restore `//xb textsettle on`.
5. **Another client:** With both clients running, switch focus and try a few
   inputs. Nothing should repeat or remain held in the previous client. Then
   stop/restart the wrapper once while both controls are neutral.
6. **Settings and panels:** `//xb bank l1 status` and `//xb bank r1r2 status`
   show both contexts. Assign a harmless `input /echo` in an unused L1L2 slot,
   reload Lua, and confirm it persists. Verify legacy `//xb l1` edits L1L2.
   Preview/unlock/drag/lock each side; both layers on a side share its position
   and scale. Confirm compact spacing and label settling at small resolutions.
   The old L1 settings section remains for recovery, not ongoing bank editing.
7. **NPC defaults/short editors:** `//xb r1r2 status` shows the resolved map and
   default/override source. Triangle Interact, Square NPC stop, Cross guarded
   NPC Enter, Circle guarded NPC Escape; Left Call, Right Status, Up raw Enter
   all, Down raw Escape all. Use compatible NPCMirror and SlowEnter v1.4.0+ on
   the same PC. Raw taps can choose highlighted menu options and bypass guards;
   the earlier reported all-client reliability issue remains unresolved. The
   status-4 cutscene feed guard still applies; event access is not added here.
8. **Restore:** Override one harmless slot, then `//xb r1r2 default triangle`.
   `//xb r1r2 defaults` resets Closed only; `//xb r1r2 menu defaults` resets Menu
   only. Clear a slot and reload: it must remain empty. Defaults must preserve
   both panel layouts and unrelated bank/context overrides. Upgrading v1 fills
   empty R1R2 entries once; re-clear any you intentionally want reserved.

### Optional comparisons

- **Real IJKL:** With profile x, messages ON, D-pad mapping IJKL and inputtest
  OFF, enable `//xb realkeys on`. Try movement keys and Trust menu navigation;
  this route is experimental and defaults OFF. `//xb realkeys off` restores the
  prior route. Try real IJKL only if your Trust installation recognizes *and
  blocks* these keys while its menu is open.
- **Shared CLI fixes:** `//xb sw` and `//xb switch` with no destination should
  show usage rather than error. Switching to an existing multiword set should
  use its complete name. Copy/alias/icon and job-ability refresh are covered by
  automated checks; skip editing valuable live bindings just to exercise them.
- **Larger sweep:** Six bars, 960×540/1280×720/desktop resolutions, repeated
  character changes, alt-tab, disconnect and reload. These can follow once the
  short smoke test feels right.

## If something misbehaves

Tell A the character/client, exact button sequence, what you expected, and
what happened. No full report is necessary. For an input issue, collect a
short bounded trace:

```
//xb controller trace on
```

Reproduce once, then `//xb controller trace off`. The log is
`xivcrossbar/data/controller-input-trace.log`. For a text jump, run:

```
//xb rendertrace on
//xb rendertrace mark
//xb rendertrace save
//xb rendertrace off
```

Mark **after** the visible issue and save promptly. The render log is
`xivcrossbar/data/render-trace-<character>.log` and each save overwrites the
previous copy, so preserve any useful capture before recording again. These
logs are only created locally; they are not sent anywhere automatically.

If startup or input regresses, stop the wrapper, unload XIVCrossbar on all
clients, restore the backed-up personal addon folder and restart with controls
neutral. The source-only rollback reference is
[`snapshot/directlink-unbound-20261016`](https://github.com/rerorriM-Mirrorer/xivcrossbar/tree/snapshot/directlink-unbound-20261016),
but your complete pre-install backup is the safer way to recover personal data.

**Verification at packaging:** Lua, JS/AHK routing and AHK structural tests run
outside FFXI. No native Lua 5.1, Windows AHK, Windower or FFXI result is claimed
until Max reports it.
