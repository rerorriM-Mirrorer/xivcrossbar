# XIVCrossbar — Native Blocking and DirectLink test

Start with [BETA-QUICKSTART.md](BETA-QUICKSTART.md) and [TESTING.md](TESTING.md).
This isolated Windower 4 build uses AutoHotkey v2 DirectLink messages for
all supported Windows profiles. An x86 bridge filters only the addon-owned
buttons in the focused client. FFXI handles ordinary gamepad input.

Keep your native Gamepad Config assignments. Switch profiles with buttons
released and use the same reader profile/device across clients. Install the
complete test folder with its matching `native/xb_gamepad_messages.dll`.

## Unified diagnostics in this beta (new)

Run `//xb diagnose` on a character to capture **30 seconds** of
AHK hardware observations, Lua button reception, routing,
context/focus/transport state, and public text/image rendering observations.
All go into a **single new file** per request under
`data/diagnostics/<Character>-<timestamp>-<session>.log`. AHK writes only a
temporary bounded observation feed under `data/diagnostics-staging/`;
Lua combines and removes the feed after a successful save. Previous captures
are never appended to or replaced. Only **one AHK capture** can be active on
the shared reader at a time; other clients are unaffected by the logging.

`//xb diagnose mark` adds an observation marker; `//xb diagnose stop` ends
early and saves after a short handoff; `//xb diagnose status` shows progress;
`//xb diagnose snapshot` records a near-immediate state capture. A normal
capture saves automatically around 30 seconds. Wait for "Diagnostic saved"
before copying the file, especially after manually stopping. Addon unload
also attempts to preserve the partial Lua capture.

Render observation tracks real native text/image calls, measured extents,
positions, center requests, visibility, object lifetimes and long frame gaps
through opt-in instrumentation. **It does not see GPU pixels or confirm how
FFXI interpreted an injected key.** Diagnostic timestamps are clock-based
observations, not proof of game engine timing; high-rate tracing may itself
add overhead. The personal build's text-settling algorithm and banks are
not imported. No normal gameplay logging is active until you request it.

## Gamepad controls

- Keep movement, camera, D-pad, and native face assignments in FFXI Gamepad Config.
- L2/R2 select the addon crossbar. View/Share opens the binder. Menu/Options opens
  the set chooser. The XInput alternate profile uses RB for the chooser.
- Both XInput profiles use physical LT and RT. LB remains available to FFXI.
- Ordinary targeting, NPC dialogue, and login navigation use native controls.
- If the reader or hook is unavailable, native controls remain available.
  Use `//xb controller status` and `//xb nativepad status` to inspect the two sides.

## Appearance and visibility

Use `//xb slotglow on` to show a gold border on slot press and hold.
The border is softer on unavailable actions and faintest on empty slots.
Use `//xb slotglow off` or `//xb slotglow status` to control the saved
option. It can run alongside either display preset and trigger scaling.


Use `//xb fade off` and `//xb triggerscale on` for a centered pop on the
single-trigger bars. `//xb triggerscale 0.90` sets the shared small scale
(relative to HUD scale), from 0.75 to 1.00, with 0.95 by default.
`//xb triggerscale status` reports the saved option and size. Autohide
reveals the selected single-trigger bar from small to full size and hides
immediately. Combined and double-tap banks appear at full size.


Drag a visible crossbar with the left mouse button; release saves its position.
Dragging also works while addon menus are open.

`AutoHideExtraBars` defaults to true: extra double-tap crossbars stay hidden until activated.

- `//xb autohide [on|off]`: show crossbars with trigger input; defaults ON. There is currently no post-trigger hold delay; release starts the normal fade-out immediately. Bare command toggles.
- `//xb fade [on|off]`: enable or disable regular crossbar fading; bare command toggles.
- `//xb textfade [on|off|status]`: fade captions and their strokes/backgrounds with slot artwork. Defaults ON; `off` restores endpoint-only captions, `status` reports without changing settings.
- `//xb textsettle [on|off|status]`: hide newly changed centered text until its native width settles, then reveal at its correct position. Defaults ON; bare toggles.
- `//xb compact [on|off]`: switch layout immediately; bare command toggles.
- `//xb scale <number>`: change crossbar scale, from 0.25 to 2. Menus keep their own layout.
- `//xb hide`, `//xb show`, `//xb auto`: manually hide, show continuously, or use autohide.
  Bindings remain active in each mode.

Defaults for fading in and out are **FadeIn 0.1s, FadeOut 0.5s, LoadFadeIn 2s**, adjustable in the `data/settings.xml`; existing saved values are preserved. Compact layout, themes, fonts and animation durations can also be changed in
`data/settings.xml`. Reload the addon after manual edits.

Text fading is independently saved as `Animation.TextFade` in `data/settings.xml`.
It only interpolates during an actual fade (including startup); it does not
change label positioning or install personal text-settling behavior.

Startup uses LoadFadeIn even when regular fades are off. A trigger interrupts the
intro with the quick FadeIn when fades are on, or immediate full visibility when
fades are off. After startup, normal visibility settings resume.

## Custom actions

Use `//xb ca` to create a new custom action. `//xb ca <name>` also works; for example,  `//xb ca "Bow"` opens a creation screen with the Name already set to Bow, OR edits the existing action with that name.

Select Edit Name, Edit Alias or Edit Command to type directly into the review; then choose Save Only or Save & Bind.
Enter commits the active text field; Circle cancels it.
Save Only (Save Changes for an existing action) returns to the editable catalog
with the saved entry selected, ready to edit another action. Save & Bind opens
slot binding as before. A failed save keeps the draft open.

Switch Crossbars and Quick XB Switch offer Default, Job Default and All Jobs
Default alongside custom sets. Newly bound switches use the actual set key,
independently of its display label. Quick XB Switch returns after one action.

While the review is open, you can also edit fields with these commands:

| Field | Purpose | Command alternative |
| --- | --- | --- |
| Name | Unique name in the custom-action catalog | `//xb ca name <value>` — or `//xb ca n <value>` |
| Alias | Label displayed on the crossbar slot | `//xb ca alias <value>` — or `//xb ca a <value>` |
| Command | Windower console command to execute | `//xb ca command <value>` — or `//xb ca c <value>` |

Blank Alias defaults to Name. Blank Command defaults to Alias, then Name. If Bow
is already a Windower alias, an action named Bow can execute it without an explicit
Command.

For commands containing semicolons, type into the inline Command field to avoid
chat/console command splitting. Options can change the destination crossbar
without discarding your draft.

`//xb ca new <name>` remains available for names that would otherwise
be read as field commands.

## Help

`//xb help` lists commands, including the retained set/copy/move/icon/alias commands.
`//xb status` reports the version and configuration.
`//xb reload` refreshes crossbar data.
`//xb restart` closes menus and fades out before reloading the entire addon.
`//lua r xivcrossbar` performs the same full reload immediately.
Superwarp bindings require the separate Superwarp addon.

## Install or upgrade

Requires **Windower 4** and **AutoHotkey v2.0.19 or later in the v2 series**. The Windows bootstrap selects a verified interpreter independently of the `.ahk` file association.

This isolated Public Beta AHK v2 test build uses the five existing public controller
profiles. Stop the old reader on all clients, unload the addon, and back up the
entire existing `addons/xivcrossbar` folder outside the addons directory. Install
the complete test folder in its place. For the first pass, start with fresh settings.

The launcher checks the standard AutoHotkey v2 install locations. To use a portable
or custom interpreter, create `data/controller-runtime.ini` with:

```ini
[Runtime]
executable=C:\Path\To\AutoHotkey64.exe
```

Use `//xb controller status` for profile and device. The reader also writes its
PID, phase, version and interpreter path to `data/controller-status.ini`.
Discovery failures go to `data/controller-launch-error.log`.
To roll back, stop the v2 reader with `//xb controller stop` or Ctrl+Alt+F12,
unload all clients, restore the complete backed-up v1 folder, and restart it
using its original AutoHotkey v1.1 setup.


1. Stop your current AutoHotkey controller script and unload XIVCrossbar on all clients.
2. Back up the existing `addons/xivcrossbar` folder, then move it out of the addons folder.
3. Extract the complete new `xivcrossbar` folder into Windower's `addons` folder.
4. To keep your settings and bindings, copy `data/` and `config.ini` from your backup
   into the new folder. Restore any custom icons you added or replaced. Keep the
   new Lua and AutoHotkey files.
5. Load with `//lua l xivcrossbar`. A fresh installation opens setup: choose the
   input profile, then button artwork, then confirm the requested combinations.
   Existing mappings are retained; `//xb remap` reopens setup.
6. Test bare menu navigation and a trigger-held binding.

The shared AutoHotkey script starts automatically. Unloading one client leaves it
running for the others.
`//xb controller stop` stops it for all clients; `//xb controller start` restarts it. Ctrl+Alt+F12 also exits this script.
To roll back, stop the script, unload on all clients and restore your backed-up
folder. Keep a separate copy of any newer bindings you want to retain.

## Controller profiles

Choose a profile during setup, or change it with a command such as
**`//xb controller profile ps5`**. The addon stops and restarts the shared script
automatically. Release the buttons before resuming play. Use the same profile
across clients sharing a controller.

| Profile command | Controller mapping | Test status |
| --- | --- | --- |
| `ps5` | PS5 DirectInput, DirectLink | Live retest pending |
| `f710` | Logitech F710 DirectInput | Experimental |
| `fightpadpro` | FightPadPro DirectInput | Experimental |
| `xinput` | Xbox-style XInput; Start opens the chooser | Experimental |
| `xinputalt` | XInput; R1 opens the chooser instead of Start | Experimental |

Legacy upstream controller scripts are preserved under `compat/upstream/` as
**optional reference utilities only**, not as simultaneously running profiles.
The separate `FFXI_Input.py` and `FFXI_Input.sh` support the original Linux
path and do not implement DirectLink; they are untested here.
See `compat/README.md` before running anything from that directory.

The profile selects how the script reads the controller; the button artwork selection in the setup wizard only selects the labels shown by the addon. The first four profiles are offered in setup;
`xinputalt` is available through its command.

`//xb controller profiles` lists choices.
`//xb controller status` reports the selected and running profiles.
If needed, an optional device number selects which controller to read: `//xb controller profile xinput 2`. Omit it to use device 1.

## Credits and license

Thank you to SirEdeonX for the original xivhotbar, Aliekber for XIVCrossbar, and
upstream contributors including Aeliya, BlueSummersC, FionaBrightgrass, grayfox2510,
Icydeath, qEagleStrikerp, Sylvebits and XerevNonori. Public update contributions: A.

See LICENSE and NOTICE. Menu asset attribution, license links and cursor provenance
are retained under `images/assets/menu/`. Original game artwork belongs to its respective owners.

## Maintenance changelog

2026-10-16: Save Only / Save Changes returns to the editable custom-action list
with the saved entry selected (including renamed or later-page entries). This
also applies to `//xb ca` entry. Save & Bind still opens binding; failed saves
keep the draft open. Public catalog storage/ownership is unchanged.

2026-10-16: Switch Crossbars and Quick XB Switch include Default, Job Default
and All Jobs Default. Bindings store stable environment keys while showing
readable labels, including renamed sets. Existing bindings remain unchanged;
rebind an old label-based switch if its destination was unreliable.

2026-10-16: character XML loads wait for a matching in-world entity and a stable
server/name/ID tuple (0.75 seconds, sampled every 0.25 seconds). Login navigation
remains available; a later identity correction requests one normal Lua reload.
Unconfirmed character writes are blocked. `//xb status` reports profile readiness.

2026-10-16: shorter target lists clamp to their available pages; Back restores
the selected spell and its original page. Public port of personal 2f462fa.

2026-10-15: immediate `//xb compact [on|off]` preserves the active set, drafts, drag position and fade state.

Stroke alpha now uses Windower's 0..255 alpha API for text outlines, preventing the invalid transparency values associated with fade flicker.

Menu transitions and crossbar rebuilds now explicitly release replaced drawing objects. `//xb resources` reports live text/image counts for diagnostics; compare the same screen after repeated edits. This fixes demonstrated retained objects and does not establish the cause of earlier native crashes.

2026-10-25: Beta 1 test candidate ports the ordered, acknowledged DirectLink
message transport for ordinary PS5 DirectInput only. Login/setup and other
hardware profiles retain Apps+F1-F12. Includes PS5 diagonal D-pad continuity,
non-blocking AutoHotkey polling, stream cancellation/watchdog tests, untouched
upstream auxiliary references and a reproducible single-folder CI package.
No personal shoulder banks, movement controls or controller shortcuts ship.
**In-game Beta 1 acceptance is still pending.**

2026-10-25: Beta 1 Diagnostic Test 1 adds `//xb diagnose` single-file
30-second per-character captures: focused AHK raw/route events, Lua message
sequences and native key requests, lifecycle snapshots, render object changes,
native text extents and frame gaps. Includes restart-safe bounded buffers,
manual markers and scoped CI tests. Personal rendering algorithms remain
outside the release candidate; native Windows/Windower/FFXI acceptance
is still pending.


2026-10-29: Beta 1 Diagnostic Test 1 local-module loading hotfix.
The complete package already contained `libs/xml2.lua` and the other private
Lua libraries, but Windower's shared `addons/libs/` search root could attempt
`addons/libs/libs/xml2.lua` rather than the addon's own nested copy.
XIVCrossbar now appends its own install-folder Lua module path before importing
bundled `libs/*` modules. This preserves standard Windower library priority;
nothing needs to be copied into `Windower/addons/libs/`, and no XML DLL is required.
Install the full ZIP directly as `Windower/addons/xivcrossbar/` (not nested).
Added a simulated missing-module regression test. Native FFXI/Windower smoke
testing is still required.


2026-10-29: Beta 1 stabilization, no new features. The button-hint show method
now refuses to reveal Options/Share hints while compact, including requests
made during a menu transition or fade. Unified diagnostics now merge Lua,
render and AHK streams directly into an adjacent temporary file, emitting
bounded lines in chronological order before the completed file is renamed.
This avoids allocating the entire sorted/concatenated diagnostic log in memory
at save time. Linux simulated load/regression checks cover a busy capture;
native Windower 4 and PS5 in-game verification remain pending. If a diagnostic
still fails to save, preserve the complete console error and any temporary
file. Do not enable `//xb inputtest` for normal diagnosis; `//xb diagnose`
observes real actions without converting them into dummy actions.

The community Beta 1 retains the public RC3's chat/help formatting and its
endpoint-visible caption fade. The personal branch's structured chat formatting
and `//xb textfade` switch have **not** been ported; no feature additions or
broad renderer changes are included in this stabilization batch.


2026-10-29: Beta 1 text fade comparison option. `//xb textfade on|off|status`
controls whether caption glyphs, background and stroke alpha interpolate with
crossbar artwork instead of appearing only at the fully visible endpoint.
Defaults OFF for compatibility and persists in `Animation.TextFade`. Turning
it on/off updates current labels without recreating bars or changing input,
layouts, or timing. Regression coverage includes startup/regular fade logic,
mid-fade labels, fade-out retention, baseline default and image parity.
No personal text-measurement or settling algorithm has been imported.


2026-10-29: Public Beta 1 text flicker stabilization. Ported the previously
personal centered-caption measurement system (a bounded stable-width cache,
frame-separated width confirmation, transparent pending labels and a capped
fallback) to the existing public UI resource/geometry code. It is enabled by
default and independently toggled by `//xb textsettle [on|off|status]`;
`//xb textfade` stays opt-in and retains requested alpha during settling.
The Save/Review inline keyboard editor was already included and is unchanged.
Added [BETA-QUICKSTART.md](BETA-QUICKSTART.md) as the terse new-user guide.
Automated tests are simulated, not live FFXI acceptance.


2026-10-29: Beta 1 release presentation and review keyboard input. The physical
keyboard arrows now navigate the custom-action Save/Review and confirmation
screens; Enter selects the highlighted option, Escape goes back, and held keys
are owned through release so they do not leak native game input or activate
the next screen. Inline field typing and controller action binding are unchanged.
No other menu or native gameplay keyboard mapping has been expanded.

Public command help, controller status, addon status, notices, bindings, custom
action messages, XML validation and console-only argument errors now use the
existing BattleStations-inspired formatting conventions: purple identity and
headings, blue syntax and labels, white descriptions/values, green ON/Ready,
yellow transitions and red errors. The shared helpers are
`libs/chat_help.lua` and `libs/chat_status.lua`. InputTrace test chatter
and diagnostic file contents retain their own debug representation.
No alterations to personal `development/directlink`, stable/master, PS5
routing, text measurement, compact geometry, or settings are included.
CI exercises real keyboard dispatch in a mocked Windower environment and the
colored message output; actual FFXI/AutoHotkey acceptance remains unverified.


2026-10-29: Focused public Beta 1 combat/Options UI parity with personal.
Setting `SkillchainIndicator.Opacity = 0` now hides both the skillchain
progress indicator and its background. New `//xb autoattack [on|off|status]`
separately disables/enables automatic swing estimation, including incoming
swing/buff/pause tracking; it preserves the prior default of Enabled=true.
The existing `AutoAttackIndicator.Opacity = 0` still hides the entire bar while
allowing estimation when enabled. Re-enabling resets estimation instead of
showing a stale average. Delayed pause callbacks from an older session cannot
mutate a newly enabled session.

Animated skillchain slot frames now restore the base image whenever their
skillchain property is absent, including during warmup. The existing valid
skillchain animation stays unchanged. The Options/set chooser also gained the
previously missing physical cancel-button mapping for PS/GameCube/Xbox/Nintendo
artwork; the root input router had called this method without providing it.

All updates are isolated to the public Beta 1 branch. The extra personal
blood-pact selection filtering, Main chooser label for Basic, personal
companion banks and extended reader-profile choices remain separate.
Simulated Lua source/regression tests are not native FFXI live verification.


2026-10-29: Fresh-install default choices for the public Beta 1, after the
combat overlay and chat presentation fixes. Bare gameplay D-pad now defaults
to `ijkl` (assign I/J/K/L to FFXI Menu/Target Cursor or select `//xb dpad arrows`),
`Animation.TextFade=true` so labels fade with slots,
`AutoAttackIndicator.Enabled=false` so swing estimation and associated tracking
start disabled (the already-zero bar opacity remains unchanged), and
`VisibilityMode='oninput'` so the crossbar appears on trigger input.
These are *defaults*: settings explicitly saved by a user for these fields
remain in effect. Users upgrading from a version that did not yet save these
fields will inherit the new defaults for the missing values. `//xb show`
restores always-visible bars, `//xb textfade off` restores endpoint labels,
`//xb autoattack on` re-enables estimation, and `//xb dpad arrows` uses arrows.
AutoHide currently has no post-release delay (visibility switches on release,
then the existing 0.5s fade-out). A future delay of 3/9/15/30 seconds is only
under discussion, NOT implemented or claimed in this build. Existing
fade-in/fade-out/startup durations and text-settling behavior are unchanged.

2026-11-07: Re-extracted the golden menu cursor using the original atlas DXT3
transparency. See TESTING.md for the in-game appearance check.

2026-11-07: Aligned the golden cursor crops to the transparent divider rows
in the atlas to preserve both arrow tips through all six frames.

2026-11-07: Restored the golden cursor’s downward bounce and moved it above
the menu caption line to avoid overlap from long neighboring labels.

2026-11-07: Restored the menu cursor’s normal height with an overlap fallback.
Added a session-only slot acceptance tap for testing with separate GripRumble.

2026-11-06: Added a centered action preview and green tentative slot tint
to the binder, a padded menu title backing, and space for the bouncing cursor.

2026-11-07: Added PID-scoped DirectLink and selective native blocking for all five Windows profiles. Retired the injected keyboard transport.

2026-11-07: Cleared the binding preview and combo panel when backing out.

2026-11-07: Added saved `//xb display legacy|xi` presets and allowed
trigger-held Auto bars to show during Event status.

2026-11-07: Lockout strips stay visible during Auto while the slots are hidden.

2026-11-07: Temporary wired Xbox 360/XInput test: LB substitutes for
logical L2; noisy physical LT is discarded by the reader and masked by the
active native guard. Other profiles and crossbar bindings stay unchanged.
The DLL's resident/pinned lifecycle remains a separate follow-up request.

2026-11-07: Binder sorting experiment: preserve user-approved White Magic
ascending spell-ID ordering and try descending weaponskill resource-ID ordering.
All other action categories retain alphabetical sorting.

2026-11-07: Binder order experiment: Job Abilities and Songs ascending ID.
Trusts prefer existing portrait images in the selected icon pack, then sort
each portrait/no-portrait group by passive, healer, tank, support, caster,
ranged, attacker/unclassified and ascending ID. White Magic ascending and
weaponskills descending remain unchanged. No icon files or binding data changed.

2026-11-07: Icon picker folder entries and breadcrumb paths now show friendly
names (Blue Magic, Weapon Skills, UI, etc.). Physical folder paths and saved
icon names remain unchanged. Personal curated icon pack not committed.

2026-11-07: Restored physical LT/RT for standard XInput and removed the
Xbox 360 diagnostic substitution. An unavailable DirectInput D-pad sample
now cancels held input and rearms after neutral.

2026-11-07: Centralized native hook cleanup under the addon lifecycle and
added hook residency to native pad status. The DLL remains pinned so
callbacks can safely finish after detachment.

2026-11-07: The Windows reader and native guard now generate their physical
controller mappings from one definition. Existing logical bindings retain
their profile behavior.

2026-11-07: Added opt-in trigger scaling for fade-off mode, with a saved
small scale shared by the two regular banks.

2026-11-07: Added opt-in gold slot borders with separate brightness for
available, unavailable, and empty slots during controller holds.
