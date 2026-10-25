# Beta 1 scope — PS5 DirectLink, upstream-compatible Apps profiles

Status: **implemented test candidate**, 2026-10-25 (America/Chicago). Code is published on this branch. Source/simulated CI verification is available; native AutoHotkey/Windower/FFXI acceptance has not been performed.
Repository: `rerorriM-Mirrorer/xivcrossbar`. Working branch: `release/beta1-ps5-directlink` created from published public baseline `a73a6c6754a1edccd6515a7b641733e044a1f7f9`.
The public baseline is derived from qEagleStrikerp/xivcrossbar master `15d8381dfad0f9efdb84fe2d24655afc150faec4`.

Read root AGENTS.md, WORKFLOW.md and TESTING.md before edits and before testing deliveries. Do not merge the current personal DirectLink branch into public wholesale. Keep its known-good profiles, catalog formats, layouts and defaults.

## Intent

Provide one normal Windower 4 XIVCrossbar community beta that is compatible with the existing L2/R2/double-trigger crossbars, custom-action UI, setup wizard and native gamepad input. PS5 DirectInput gets DirectLink for the **ordinary twelve controls** (D-pad, four face buttons, Share, Options, L2, R2); no extra L1/R1 personal controller actions, companion panels, Trust/NPCMirror integration or personal character bindings.

The PS5 ordinary profile is `ps5-directinput` (`//xb controller profile ps5`), **not** the hidden personal `ps5-extended` profile. Use the existing ordered token/acknowledgement message design as the source of truth. AHK observes physical edges; the Lua controller router owns meaning and releases. One input owner per gesture: never send the same press simultaneously over DirectLink and Apps.

Preserve other unified reader profiles and their upstream physical mappings:
- `f710-directinput` / `f710`: Logitech F710, Apps+F1-F12.
- `fightpadpro-directinput` / `fightpadpro`: FightPadPro, Apps+F1-F12.
- `xinput`: Xbox-style XInput, Apps+F1-F12.
- `xinput-r1-chooser` / `xinputalt`: legacy RB chooser mapping, Apps+F1-F12.
- `ps5-directinput` / `ps5`: DirectLink messages during eligible in-world gameplay and UI; safe pre-login/setup transition. Preserve a documented Apps comparison/fallback only if needed, with no double delivery.

Keep one *active* AutoHotkey v1 wrapper per installation, selected and restarted via `//xb controller profile <name> [device]`. Device IDs and physical button/artwork selection remain separate. Reject duplicate readers, wait for neutral on profile/focus handoff, preserve all held releases, and restore ordinary keyboard F1-F12 and Ctrl+F1-F12 passthrough.

The current public branch already consolidates PS5/F710/FightPadPro/XInput/XInput-alt in `ffxi_directinput.ahk`. Port a **small, generic subset** of the newer `development/directlink` message route into the public branch rather than replacing its entire AHK, root Lua, menu or settings stack. Required companion modules can be added deliberately with actual-source tests. Do not port any personal shortcut handler.

### Input responsiveness to carry forward

Retain the known source-level response improvements from the DirectLink wrapper: `SetBatchLines, -1`; no arbitrary `Sleep` inside the controller poll callback; edge-order-preserving delivery; owned key-up on focus loss/disconnect/profile change; clean neutral rearm; and suppression of duplicate input while message ownership is uncertain. Preserve SendEvent behavior where it remains relevant to Apps profiles instead of blindly substituting another keyboard injection mode. Validate responsiveness in FFXI rather than claiming source changes alone prove a latency win.

Do not transplant the personal wrapper's unresolved last-client-auto-exit design as part of the release. A deliberate `//xb controller stop` and existing public multi-client lifecycle remain the safe foundation until native verification.

### Upstream auxiliary compatibility

Restore or carry forward the upstream auxiliary files as needed for installation, documentation, Steam Deck, diagnosis and older controller setups, without changing their meaning or pretending they all become Windows AHK profiles. `FFXI_Input.py` and `FFXI_Input.sh` are separate Steam Deck/non-Windows launch paths, **not** AHK profiles. Historical diagnostic/AHK-v2/reference scripts may be shipped as clearly labeled optional compatibility resources; they must not auto-launch next to the unified v1 reader. Verify file provenance and license/NOTICE preservation, and do not distribute user-generated data/settings. Keep the complete package with images/themes and setup documentation.

## Explicit exclusions

No L1/R1 or ordered shoulder-first companion banks. No PS/touchpad/L3/R3/mute personal shortcuts. No new Trust/NPCMirror/SlowEnter bindings, shared personal presets, movement signaling, installer bridge, hidden personal profiles or private catalog migration. No changes to traditional three/four/six bar semantics, hotbar actions, upstream job sets, or L2/R2 order. No Steam Deck DirectLink claim without its own implementation and tests.

## Single focused acceptance pass — after a matching test package exists

Test from one exact published code checkpoint; keep a separate backup of the existing working Personal build. Record profile, wrapper version, client count, resolution, fresh/upgrade state and pass/fail for every item. No tests below are claimed completed.

1. **Fresh setup and login:** Windower + AHK v1, fresh PS5 profile, physical face/D-pad setup, login/lobby and no-subjob character. Confirm ordinary confirm/cancel/directions work before and after login. `//xb controller status` reports matched PS5 reader and messages readiness when eligible.
2. **PS5 ordinary crossbars:** L2 and R2 alone; L2→R2 and R2→L2 (four bars), optional double-taps (six bars); trigger+each D-pad/face action fires once. Hold/release, fast rolling presses and two simultaneous buttons; no stray native macro palette, physical F7/F8 and Ctrl+F-key remain ordinary.
3. **PS5 native and addon menus:** Bare D-pad/face controls, in-game menu/selection, event dialogue at status 4, XIVCrossbar binder, custom-action text entry/review, Options chooser, Share exit and Escape. Verify one press means one intended action; no swallowed confirmation, input bleed or stuck keys.
4. **Other reader profiles (Apps path):** Switch sequentially at neutral through F710, FightPadPro, XInput and XInput-alt, where hardware is available. Test each profile's original face/shoulder/chooser mapping without introducing DirectLink; label unavailable hardware **untested**, not passed. Verify wrapper ownership and no duplicate process.
5. **Multi-client lifecycle:** With two clients (e.g. 1280×720 and 960×540), change focus repeatedly while holding/releasing triggers; unload/reload one without breaking the other; stop/restart the shared wrapper deliberately. Repeat a PS5 native menu after switching client. Record any stuck hold, dropped release or lingering AHK process.
6. **Persistence/UI and rollback:** Save a bind/custom action, rename, change set, drag/scale/compact, reload and switch job; observe no lost data or unexpected personal folders. Check small-screen menu clipping, fades and drawing-object recovery; verify full rollback restores previous working installation.
7. **Final package inspection:** Archive has one installable `xivcrossbar/` folder, complete assets, `LICENSE`/`NOTICE`, `README.md`, `WORKFLOW.md`, `TESTING.md`; no user state or second automatically running AHK. Compare package files with a committed source and mark each profile as verified, experimental or unsupported.

Run source/regression checks before the live pass; specifically add assertions that only ordinary PS5 selects message mode, no bank handlers or personal profiles are reachable, other profiles still emit Apps signals, and cancellation/key-up never falls through between routes. Include tests for login fallback and mode-transition mid-hold. Static/AHK-translation checks do not substitute for native Windows/Windower/FFXI tests.

## Optional future Companion Banks separation (NOT part of Beta 1)

A separately installable *personal* Companion Banks addon does **not** need a second simultaneously running AHK reader. First try independent read-only Lua receivers for the same event stream, as NPCMirror currently does, with distinct per-consumer sequence tracking and context decisions. Only introduce a shared event broker or exclusive action arbiter if simultaneous interpretation actually causes duplicate actions or missed acknowledgement windows. Keep this experiment exclusively on the personal development track, not Beta 1.

## Release gate

This branch now contains the Beta 1 test implementation and its CI packaging workflow. Keep `public/rc3-maintenance`, `development/directlink` and `master` unchanged until the user has live-tested the candidate. No GitHub Release, upstream PR, forum post or community availability is implied by this document.
