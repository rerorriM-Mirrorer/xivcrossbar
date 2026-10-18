# DirectLink integrated live test — October 18, 2026

This is the short in-game guide for the **complete personal DirectLink** test
package. It incorporates the shared command fixes, R1 Trust-menu shortcuts,
optional real IJKL comparison and text settling. It is **not** the public RC3.
The cumulative record and detailed edge cases remain in `TESTING.md`.

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

   Expect runtime `0.4.0-a.20261018.directlink1-r1menus1` and wrapper
   `Controls=9.8-r1-menus`, with R1 protocol support. If the wrapper version
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
   orders. Existing saved L1L2 commands should still work.
2. **R1 + Trust:** Hold R1 then press Triangle to open Trust. Press Triangle
   again from inside a submenu; its cursor and unsaved draft should remain.
   R1+Square closes Trust, subject to its usual save/validation rules. Try
   face-first and R1-first order, and release in both orders. No extra R,
   ordinary Square/Triangle, or Ctrl+Numpad action should escape. R1 arrows,
   Cross/Enter, Circle/Escape and unused-R behavior should remain intact.
3. **Menus and chat:** While the game menu, Trust editor, XIVCrossbar chooser
   and chat entry are open, try short shoulder/face combinations. Inputs owned
   by those interfaces should stay there; no surprise gameplay or Trust command.
4. **Text settling:** Try `//xb textsettle status` (default ON). Reveal L1,
   change pages/sets, and open the binder. Notice any label that jumps,
   appears late, is incorrectly centered, or remains invisible. Compare with
   `//xb textsettle off`, then restore `//xb textsettle on`.
5. **Another client:** With both clients running, switch focus and try a few
   inputs. Nothing should repeat or remain held in the previous client. Then
   stop/restart the wrapper once while both controls are neutral.

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
