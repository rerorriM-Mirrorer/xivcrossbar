# XIVCrossbar — Personal 6 testing build

This personal build starts from RC3 plus its Icons, Credits and Escape patches.
Personal 6 adds confirmed-character storage guards with controller login input,
per-slot dimming fixes, cutscene trigger access, current-target-first selection,
combined global/private custom-action catalogs, linked binding updates, and
optional last-client wrapper shutdown. Complete and update packages omit all
installed data/settings/controller INIs; preserve yours when copying over an install.
New settings default to PS5 Extended, IJKL, on-input visibility, compact layout
and Superwarp all. Existing saved values are retained. Select the extended
profile with `//xb controller profile ps5extended`; `//xb controller profile ps5`
restores regular controller behavior. Personal setup offers the extended default;
the public profile list is unchanged. See [PERSONAL.md](PERSONAL.md) for
the mapping and preferences, and the package's `TESTING.md` for installation and
live checks. `//xb compact [on|off]` switches immediately; bare toggles and saves.
See [COLOR-SETTINGS.md](COLOR-SETTINGS.md) for what each color/opacity setting
affects. `on_unload_killahk=true` now stops the shared wrapper only when the last registered client unloads, after a two-second reload grace period. Other clients and pre-login/minimized clients keep it running.
Personal 5 adds `//xb textfade [on|off|status]` for comparing continuous text
fading with the current endpoint behavior, and `//xb autoattack [on|off|status]`
to independently stop or enable the optional swing estimator. Neither command
changes the controller mapping, slot bindings or other indicators.
Personal 4 also adopts PS5 Extended for older base-PS5 settings once, rechecks it
after character settings reload and preserves later explicit profile choices.
Shoulder taps target immediately on release; doubles clear the old client with
Escape before switching. Bare touchpad sends backtick. Horizontal R1 input
latches Alt until R1 release. Insufficient-MP cost numbers use soft pink.
Personal 3 rounds the timing-bar ends, uses pale green for new MP-cost settings,
repairs stroke-alpha units, and refines inventory arrows, held click combinations
and touchpad timing. Saved MP colors remain yours; see the color guide to update
an existing XML. The public snapshot is unchanged.

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

## Important: gamepad configuration

In **FINAL FANTASY XI GAMEPAD Config**, disable **hat switches** and duplicate D-pad, face-button and trigger assignments
as shown below. The addon supplies those buttons through AutoHotkey. Retain stick movement and camera controls.

![DirectInput gamepad configuration; pink marks duplicate native input and yellow marks macro assignments to avoid on L2/R2](images/setup/gamepad-directinput.jpg)

The screenshot shows the tested PS5 DirectInput setup, with native XInput disabled.
All gamepad functions (like Ctrl and Alt macro keys) can stay assigned to other buttons; but avoid assigning them
to L2/R2 and the face buttons used for XIVCrossbar. The yellow markings identify that distinction.

## Controls

Apps+F1–F12 are reserved for controller input. Follow the setup
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
- `//xb scale <number>`: change crossbar scale, from 0.25 to 2. Menus keep their own layout.
- `//xb hide`, `//xb show`, `//xb auto`: manually hide, show continuously, or use autohide.
  Bindings remain active in each mode.

Defaults for fading in and out are **FadeIn 0.1s, FadeOut 0.5s, LoadFadeIn 2s**, adjustable in the `data/settings.xml`; existing saved values are preserved. Compact layout, themes, fonts and animation durations can also be changed in
`data/settings.xml`. Reload the addon after manual edits.

Startup uses LoadFadeIn even when regular fades are off. A trigger interrupts the
intro with the quick FadeIn when fades are on, or immediate full visibility when
fades are off. After startup, normal visibility settings resume.

`//xb textfade on` fades slot labels, costs, recast text and controller hint text
with the crossbar. `off` hides text until fully revealed and hides it as closing
starts; off is the default. Startup follows the chosen text mode.
`//xb autoattack off` stops the estimate and clears its history; `on` starts
fresh. It has no effect on the game's autoattacks or your Attack slot.
Both commands save, bare toggles, and `status` reports without changing anything.
AA Opacity=0 still hides only the bar; Enabled=false stops its processing too.

## Custom actions

Use `//xb ca` to create a new custom action. `//xb ca <name>` also works; for example,  `//xb ca "Bow"` opens a creation screen with the Name already set to Bow, OR edits the existing action with that name.

Select Edit Name, Edit Alias or Edit Command to type directly into the review; then choose Save Only or Save & Bind.
Enter commits the active text field; Circle cancels it.

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
| `ps5` | PS5 DirectInput | Base profile; tested in game |
| `f710` | Logitech F710 DirectInput | Experimental |
| `fightpadpro` | FightPadPro DirectInput | Experimental |
| `xinput` | Xbox-style XInput; Start opens the chooser | Experimental |
| `xinputalt` | XInput; R1 opens the chooser instead of Start | Experimental |

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
## Changelog

### Personal 5 — October 13, 2026

- Add saved text-fade comparison without restarting fades, replacing surfaces,
  or changing the default endpoint timing. Use `//xb textfade on/off/status`.
- Add an independent autoattack Enabled setting and command. Off clears swing
  history and pauses, bypasses timing/sampling work, and hides the indicator
  immediately even during a fade. Existing opacity/colors remain unchanged.
- Replace AA scheduled pause callbacks with expiry timestamps. Learn from two
  actual swings and start fresh each engagement. Other lockout/skillchain work
  and the game's Attack/Disengage behavior remain separate.
- Document actual hidden work, the existing instance lock and proposed
  last-client shutdown. That shutdown is not implemented in this patch.

### Personal 4 — October 13, 2026

- Correct profile precedence on old character settings and load/login refresh;
  PS5 Extended adopts once, while other preferences and later choices persist.
  Remap uses the extended default too. No settings/data files are supplied.
- Remove the single targeting-tap delay. A second completed tap sends Escape
  to the old window, waits for its key-up, then moves to the previous/next client.
- Bare touchpad tap now sends backtick. R1 horizontal input latches Alt through
  vertical input/other combos until R1 releases; direct shortcuts keep their
  unmodified/Ctrl output by briefly suspending the physical Alt key.
- Add configurable insufficient-MP pink without changing TP or cooldown-only
  coloring. Skillchain Opacity=0 hides the background as well as the fill.
- Instance mutex remains active. Last-client shutdown and a complete AA
  collection-disable option remain separate pending work.

### Personal 3 — October 13, 2026

- R1 Up/Down are bare arrows; Left/Right latch Alt until another R1 combo or
  shoulder release. Held previous directions do not acquire the new modifier.
- L1+touchpad sends Tab on down; holding adds F15 at 500ms. R3 then L3 holds
  comma until L3 releases; L3 then R3 holds period until R3 releases.
- All timing bars use inset rounded ends and share crossbar movement, scaling
  and fades. The auto-attack colors meet without an inset at their inner join.
- MP-cost default matches review green (194,253,195); TP is unchanged. Stroke
  alpha now uses Windower's 0–255 setter. Saved settings/bindings are retained.
- Recovered the verified October 2 Mute=Joy15 result. Optional probe accepts a
  removable F15 test command; no Mute bank or production F15 binding is added.
- Shoulder singles/doubles and bare touchpad output are unchanged pending their
  timing choice. Last-client wrapper shutdown remains pending; the instance
  mutex is already in place.

- RC3: complete Apps-based controller update with selectable readers, silent
  input consumption, scaled/draggable crossbars, menu/custom-action refinements,
  item extraction repairs, startup fades and graceful restart.
- RC3 follow-ups: slot icon alignment, Credits paths/layout, and physical Escape
  exiting all addon menus. The public snapshot remains separate.
- Personal 1: optional PS5 extended controls, context leases, PS client switching,
  personal keyboard shortcuts and an installation-scoped wrapper lock.
- Personal 2: consumed release taps/double taps, touchpad map peek, Tab/F15 holds,
  direct menu shortcuts, Alt inventory arrows, ordered stick clicks, instant
  compact switching and an optional manual key probe. Removed shoulder-stick zoom.
- Personal 2 Defaults 1: requested fresh-install defaults and matching setup
  choice, retained shutdown preference, color-setting reference, and read-only
  controller button discovery for planning a Mute-held probe layer.

### Personal 6 checkpoint 1

Controller transport may start before login. Character hotbar storage now requires a confirmed logged-in character and known server; logout disables character writes until a valid login. Packages omit all user data and configuration.

### Personal 6 checkpoint 2

Affordability/recast dimming is tracked per slot so duplicate and linked actions update independently. Feedback animation clamps its opacity and completes even when its decrement does not divide the starting opacity.

### Personal 6 checkpoint 3

OnInput trigger visibility works during dialogue/cutscenes; explicit Hide remains authoritative. Target selection prefers `<t>` when the action supports another target, including friendly spells.

### Personal 6 checkpoint 4

Custom Actions lists both global (`data/CustomActions.xml`) and character catalogs. `//xb catalog global|character|status` selects where new actions save; global is the default. Edits stay in the original catalog. Same-name entries remain individually selectable with their scope shown. Catalog writes re-read and merge one edit under a short Windows file lock, retain a previous-file `.bak`, and publish a complete replacement. A conflicting same-entry edit keeps the draft. Missing catalogs stay absent until an action is saved.

### Personal 6 checkpoint 5

Catalog-linked bindings follow edits and renames by stable identity. Explicit slot alias/icon overrides remain independent. Deleting an entry hides it from the catalog while retaining a command snapshot for existing bindings; re-creating its name creates a separate identity. Unique exact legacy copies can be adopted automatically; ambiguous copies require rebinding. Catalog updates resolve without bulk rewriting another character's crossbar XML.

### Personal 6 checkpoint 6

The installation-scoped mutex still prevents duplicate wrappers. A session registry supports optional last-client shutdown: `on_unload_killahk=true` on the last departing client stops the shared wrapper after a two-second reload grace; false keeps it running. Registration begins before character login. A held owner file identifies live Lua sessions, including minimized clients; stale metadata alone cannot keep a client registered. `//xb unload` performs graceful teardown; `//xb restart` reloads the addon and `//xb reload` only re-reads hotbars. Help now uses the shared chat-only formatting, and unknown commands display help. Apply matching Lua and wrapper files to every participating client, then restart the shared wrapper once for the new policy.

### Personal 6 final review

Allow controller menu input before character initialization while keeping crossbar execution/storage guarded. Retry transient identity readiness after login. Add a per-process counter to action IDs and retain the exact committed entry as a draft revision, so an intervening edit cannot be silently accepted. Keep the review's catalog scope centered with its changing set title. Full simulated regression checks and package checks passed; live Windows/FFXI checks are pending.

### Personal 6 compatibility correction

Cioara’s native startup report exposed an AHK v1 Files-loop syntax error and an unsupported Lua FFI dependency. The corrected build uses stock Lua/LuaSocket for catalog coordination and AHK for native owner-handle detection. Catalog replacement retains the old revision during the Windows rename gap and rolls back failed publication. Update matching Lua/AHK files and restart the wrapper once; existing user XML and configuration are not distributed or replaced. Native acceptance is still a live check.

### Personal 6 Fix2: storage scope

Import storage in the main addon so status, pending-login and logout guards access the same module as player. Status describes uninitialized storage clearly. The reported native reload crash remains under investigation; this fixes the proven Lua error.

### Personal 6 Fix2: six bars by default

Fresh personal settings default to six hotbars and hide inactive extra bars. Existing saved bar counts remain in force; set Hotbar.Number to 6 in the character settings to opt an existing installation in. No user XML or controller INI is shipped.

### Personal 6 Fix3: catalog XML tracking

Preserve catalog identities and inherited-value snapshots when rebuilding slots from XML, so catalog-linked bindings retain their provenance across reloads. Native crash cause remains unconfirmed by the supplied logs. The separately requested four-character Fenrir defaults are not part of the runtime update.


### Personal 7 cleanup checkpoint 1

Temporary review, picker, binding and text-entry objects are explicitly destroyed
when replaced or closed. Setup rebuilds replace their titles and cursor assets.
Options overlays still hide and restore the active draft without disposing it.
The unnecessary text-entry band is hidden on Delete Custom Action.

`//xb resources` reports this addon's live text/image counts and cumulative
creation/deletion totals, without touching other addons. Compare the same closed
menu state before and after repeated editing. Counts differ between screens;
cumulative creation totals naturally increase. This fixes demonstrated object
retention, not a proven native d3d8 crash cause.


### Personal 7 cleanup checkpoint 2

Crossbar and set-chooser rebuilds dispose the previous drawing layer before
replacing it. Geometry destruction is idempotent, including objects queued for
a closing fade. Unload stops geometry animation, releases its surfaces and
rounded primitives, then releases any remaining tracked text/image objects.
Personal controller outputs are unchanged.


### Personal 7 review notes

PERSONAL.md now starts with the current source-verified extended controller map
and the shared-text failure investigation. It distinguishes explicit XIVCrossbar
resource retention from unproven native crash causes and documents existing
XIVParty/ConsoleBGPlus diagnostics. Historical mappings remain below, clearly
superseded by the current table. No controller remapping is part of cleanup.


### Personal 7 cleanup checkpoint 3

Fix partial menus caused by iterating Windower List metadata as drawing objects.
Cleanup visits indexed objects only; repeated footer replacement uses the List
removal method to preserve its explicit count. Regression tests now execute the
upstream List implementation. Controller outputs and saved data are unchanged.


### Personal 7 cleanup checkpoint 4

Cleanup dispatch is limited to owned drawing objects, using raw indexed entries
independently of generic list iterators. `//xb resources` now identifies its helper
build, so the loaded module can be checked separately from the addon version.
This guards the reported repeated numeric-destroy failure; its recurrence after
checkpoint 3 is not yet reproduced in FFXI. No controller changes.


### Personal 7 cleanup checkpoint 5

Options no longer tries to dim a deleted inline-entry caption after returning to
the custom-action review. Overlay restoration skips objects replaced while it
was open. Cursor cleanup works when root unload has already destroyed its images.
Regression checks reproduce both previous calls before their respective fixes;
controller scripts and installed data are unchanged.


### Personal 7 cleanup checkpoint 6

Selecting a spell or action on a later page now clamps the following list to
its available pages, so a one-page target list appears immediately. Back still
restores the original spell/page. Includes checkpoint 5's stale-caption and
cursor-unload fixes; all controller scripts, catalogs and bindings are preserved.
