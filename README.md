# XIVCrossbar — Beta 1 PS5 DirectLink testing candidate

Current verification and pending in-game checks: [TESTING.md](TESTING.md).
Focused PS5 acceptance checklist: [Beta 1 scope](docs/BETA1-PS5-DIRECTLINK-SCOPE.md).

This is a **complete testing installation**, including required images/themes.
It is not a released stable version. Beta 1 adds ordinary PS5 DirectLink
messages to the public RC3 Maintenance 2 foundation. Community publication
and final hardware verification are pending. Read [the branch handoff](docs/HANDOFF-PUBLIC-RC3.md) and
[the branch map](docs/BRANCH-MAP.md) before testing or opening a new development
conversation. Package-root TESTING.md gives installation and first tests.

No saved settings, config.ini, catalogs, bindings or controller preferences
are supplied. Preserve the appropriate installation's data separately. Both
variants use the xivcrossbar name and keyboard transport: test one at a time per
PC, stopping the wrapper and unloading all clients before changing variants.

Current runtime is **0.4.0-beta1.20261025.ps5-directlink-test1**, with RC3 Icons/Credits/Escape,
compact/stroke/resource maintenance, target pagination, stable character identity,
Default-set switch destinations and custom-action save return. It does not include the personal
controller profile, personal catalogs, movement signaling or any L1/R1 banks.
A dedicated //xb unload alias is pending; use //lua u xivcrossbar.

---

# XIVCrossbar — Apps-key public release candidate

Based on qEagleStrikerp's consolidated XIVCrossbar repository, with updates by A.

## What this update addresses

- Native macro palettes no longer appear when using crossbars in Apps mode.
- D-pad and face buttons navigate the addon menu or execute a bound action without
  also moving the in-game menu (when duplicate native assignments are disabled).
- Ordinary keyboard F-keys and Ctrl+F-key shortcuts remain available.
- Crossbars can be scaled, dragged and hidden without disabling bindings. Menus
  fit the screen independently, including smaller resolutions.
- Custom actions use one review screen, with inline editing and name/alias fallbacks.
- Item icons, Superwarp bindings, draft navigation, chat messages and XML
  read/write safeguards received fixes developed during testing.

### Beta 1 controller transport

The ordinary **PS5 DirectInput** profile sends the twelve face/D-pad/menu/trigger
signals over a token/acknowledged message stream when the FFXI client is focused,
logged in and ready. The same public Lua input router interprets them, without
synthetic Apps/F-key events in that mode. During login and the controller wizard
the PS5 reader uses the Apps+F1–F12 keyboard path. Other profiles always keep
their existing Apps route, selected through the one unified AutoHotkey v1 script.
Switch profiles only with controls released.

This is a **PS5 live-test candidate**. Original public RC3 Apps mapping was tested
in game; the newly ported DirectLink route has NOT been accepted in FFXI yet.
See the safety/rollback instructions and the single focused checklist in TESTING.md.

## Important: gamepad configuration

In **FINAL FANTASY XI GAMEPAD Config**, disable **hat switches** and duplicate D-pad, face-button and trigger assignments
as shown below. The addon supplies those buttons through AutoHotkey. Retain stick movement and camera controls.

![DirectInput gamepad configuration; pink marks duplicate native input and yellow marks macro assignments to avoid on L2/R2](images/setup/gamepad-directinput.jpg)

The screenshot shows the tested PS5 DirectInput setup, with native XInput disabled.
All gamepad functions (like Ctrl and Alt macro keys) can stay assigned to other buttons; but avoid assigning them
to L2/R2 and the face buttons used for XIVCrossbar. The yellow markings identify that distinction.

## Controls

Apps+F1–F12 are reserved for legacy-profile and PS5 login/setup input; PS5 gameplay uses DirectLink messages. Follow the setup
wizard to assign functions to face buttons.
On PlayStation 5 controllers:

- Share exits addon menus
- Keyboard Escape exits the full addon menu, including text fields and overlays
- Options opens the crossbar chooser, including over a custom-action draft.
- Triggers select crossbar slots or turn pages where the addon menu permits it.

For in-game D-pad targeting, use the command **`//xb dpad ijkl`**. This sends I/J/K/L for bare
Up/Left/Down/Right. In FFXI, go to **Config > Misc. 2 > Key Assignment > Movement**
and move I/J/K/L from **Menu Cursor & Camera** to **Menu/Target Cursor**, as shown:

![Four-step navigation and final IJKL targeting assignments](images/setup/ffxi-ijkl-targeting.png)

`//xb dpad arrows` restores arrow output; bare `//xb dpad` toggles between the two modes.

## Appearance and visibility

Drag a visible crossbar with the left mouse button; release saves its position.
Dragging also works while addon menus are open.

`AutoHideExtraBars` defaults to true: extra double-tap crossbars stay hidden until activated.

- `//xb autohide [on|off]`: show crossbars with trigger input; bare command toggles.
- `//xb fade [on|off]`: enable or disable regular crossbar fading; bare command toggles.
- `//xb compact [on|off]`: switch layout immediately; bare command toggles.
- `//xb scale <number>`: change crossbar scale, from 0.25 to 2. Menus keep their own layout.
- `//xb hide`, `//xb show`, `//xb auto`: manually hide, show continuously, or use autohide.
  Bindings remain active in each mode.

Defaults for fading in and out are **FadeIn 0.1s, FadeOut 0.5s, LoadFadeIn 2s**, adjustable in the `data/settings.xml`; existing saved values are preserved. Compact layout, themes, fonts and animation durations can also be changed in
`data/settings.xml`. Reload the addon after manual edits.

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

Requires **Windower 4** and **AutoHotkey v1.1.33 or newer in the v1 series**,
associated with `.ahk` files.

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
| `ps5` | PS5 DirectInput, DirectLink in gameplay and Apps during setup | Beta 1 live acceptance pending |
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
