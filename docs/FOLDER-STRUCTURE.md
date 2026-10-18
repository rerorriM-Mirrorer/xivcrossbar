# Folder structure audit and cleanup plan

Author A. October 17, 2026, America/Chicago. Reviewed development/directlink
bfdf7d693c387dac9782144b0139d466e9c0ccf5 against upstream
qEagleStrikerp/xivcrossbar 15d8381dfad0f9efdb84fe2d24655afc150faec4.
This checkpoint adds documentation/example presets only. No runtime module,
image, theme, cache, installed profile or controller path is moved.

## What currently depends on image paths

No PNG has an inherently immutable location. Current code, generated resources,
saved icon values and build scripts make the following paths compatibility
boundaries. Preserve them until their readers/writers are migrated together.

| Current path | Role and consumers |
| --- | --- |
| images/icons/iconpacks/<pack>/ui/ | Crossbar backgrounds, blank tile, feedback/overlays, recast masks, frame steps and controller hints. ui.lua and l1_view.lua construct these paths. |
| images/icons/iconpacks/<pack>/ui/binding_icons/ | Per-button/direction/trigger art used by bar hints, binder and L1 companion. PS artwork suffixes b/x mean Square/Circle in this pack; do not rename based on Xbox assumptions. |
| images/assets/menu/ | L2/R2 page art, page-button and cursor/frames animation assets; selectablelist and animated_cursor load them. Retain credits/provenance alongside artwork. |
| themes/<theme>/slot.png, frame.png, notice.png | Three image-only skins: classic, ffxi, ffxiv. ui.lua, l1_view.lua and packaging refer to this root. |
| images/icons/spells/, abilities/, weapons/, elements/ | Default spell/ability/weapon artwork and elements. resource_generator writes some of these locations into generated resource records. |
| images/icons/iconpacks/<pack>/... | Job/action/item/Trust and other selectable art. Presentation content rather than panel structure, but aliases and saved custom icon values still depend on this tree. |
| images/setup/ | Setup/wizard illustrations. They are feature assets even if ordinary crossbar play does not currently display them. |
| images/credit_avatars/ | Credits screen portraits and its menu icon. Optional to gameplay, required for a complete working Credits screen. |
| images/extracted_items_v5/ | Runtime-generated item BMP cache. ui/item_icons.lua writes it and can return its relative path for saved slots. This cache is absent from the tracked source tree. |

The fork currently has 2,098 tracked files below images, including asset
documentation/provenance, and nine PNGs below themes. This is not a claim that
every image is always visible or that every file is unused unless seen in a
literal path search: many paths are assembled from action/job/theme names.

Changing only hard-coded Lua strings is insufficient. Account for generated
resources/crossbar_spells.lua and crossbar_abilities.lua, saved full images paths,
icon-pack-relative names, item extraction/cache paths, wizard/credits paths,
README/examples and packaging manifests. Test nondefault packs/themes too.

## Proposed module destinations

### Later preference: images/icons/default

The chosen target is now images/icons/default/<category>, removing only the
iconpacks level. This is feasible after centralizing the pack-path resolver
and migrating/preserving old saved and generated references. It is not a move
performed by the audit or real-IJKL checkpoint. Inventory the icon chooser too:
putting a file in the pack does not automatically make every category selectable.

Keep the numeric native fallback collection distinct from named pack artwork,
even if both ultimately live beneath default (for example default/native/abilities
versus default/abilities). Alternate packs can override a subset and fall back
to the shared default/native assets; they need not duplicate every fallback.
Pack identity stays configurable, so a later third-party system can be adapted
through the resolver without rewriting bank/action code. Avoid flattening same-
purpose-looking folders until generated recast IDs and named art are reconciled.

The classifications below describe the 50-file audit baseline; later runtime
helpers such as controller_realkeys.lua belong with controllers/ when moved.

There are 50 Lua files at the root. The table classifies every one; these are
proposed destinations, not completed moves. Retain the addon entry filename and
folder identity xivcrossbar. Keep defaults discoverable at the root initially.

| Destination | Current root Lua files |
| --- | --- |
| Root | xivcrossbar.lua, defaults.lua |
| ui/ | ui.lua (rename to crossbar.lua), ui_geometry.lua, ui_fade.lua, ui_drag.lua, menu_layout.lua, action_binder.lua, environment_chooser.lua, gamepad_mapper.lua, binding_feedback.lua, chat_help.lua, l1_view.lua, visibility.lua, theme.lua, set_labels.lua |
| controllers/ | buttonmapping.lua, gamepad.lua, gamepad_converter.lua, keyboard_mapper.lua, controller_transport.lua, controller_messages.lua, controller_profiles.lua, controller_clients.lua, controller_switch.lua, controller_target.lua, personal_controls.lua, personal_profile.lua, l1_transport.lua, text_input_guard.lua |
| core/ | action_manager.lua, player.lua, storage.lua, variables.lua, custom_catalog.lua, custom_action_review.lua, catalog_bindings.lua, crossbar_destinations.lua, target_choices.lua, l1_bank.lua, autoattack.lua, consumables.lua, enchanted_items.lua, profile_gate.lua, character_identity.lua, resource_generator.lua |
| resources/ | spells_that_require_ja.lua, sw_zones.lua, function_key_bindings.lua (static/default mapping data; review whether a later config/ name serves this last file better) |
| libs/ | windows_file.lua, if kept as reusable Windows/file-operation support |

libs already holds reusable/vendored dependencies. Keep project-specific
controller, profile and menu behavior in named modules rather than moving the
entire root into libs. resources is for tables/generated metadata, not active
controller state or event handlers. Windower's require('resources') is its own
shared library; use explicit resources/<module> names for addon-local tables.

For example ui/geometry.lua is a sensible final name for ui_geometry.lua, with
callers updated to require('ui/geometry'). Moving ui.lua to ui/crossbar.lua avoids
an ambiguous ui.lua-versus-ui/ entry. Final rename choices should be made once
per small migration batch, rather than introducing many temporary names.

AHK is a separate migration: ffxi_directinput.ahk includes sibling scripts and
anchors data/mailboxes to A_ScriptDir. Lua launchers and TrustMovement paths also
depend on that location. Keep the wrapper/includes together at the root until
an explicit addon-root anchor and corresponding launch/include changes exist.

## Can themes move into images?

Yes. All nine tracked theme files are PNGs; images/themes/<theme>/ would be a
coherent destination. It is optional organization, not a rendering fix. Add a
single theme-path resolver, update its consumers and package manifests, and
retain compatibility with old installations during the migration. Keep saved
theme names stable. Do not move existing custom action icons or caches simply
because themes move.

## Origin and installation role of development folders

The named upstream baseline contains no docs/, tests/, packaging/ or examples/.
They are additions from this development line, with these qualifications:

- docs/: five documents before this audit, including controller reference,
  roadmap, branch map and preserved snapshot/handoff history. These are useful
  documentation, not disposable runtime logs. Preserve historical records.
- tests/: 49 files before this audit. Regression/simulated checks and test
  support, not diagnostics that run inside FFXI. fixtures/windower_lists.lua is
  a credited test-only snapshot from Windower, not original code authored here.
- packaging/: six build/helper scripts created for our deliveries. Not required
  for the addon at runtime. Some encode older Personal branches/batch names;
  adapt and verify them before using them to publish a new DirectLink package.
- examples/: existing 34-action template plus its guide; this checkpoint adds
  an index and the recovered Fenrir preset pack. Examples are opt-in and are
  never copied over installed data automatically.

Current builders generally omit tests/ and packaging/ from installable payloads;
they differ in what docs/examples they include. A cleanup should define one
current packaging manifest, keeping README, WORKFLOW and cumulative TESTING
inside the installable addon folder, per the shared workflow.

## Preserve the native-menu guard

Current root code checks info.menu_open separately for companion rendering and
for the L1 execution mailbox. A native menu suppresses the display and resets
the mailbox session, cancelling the held bank and invalidating old queued
events. This is useful ownership behavior, not merely decoration.

Ordinary DirectLink button messages deliberately remain available for native
menu navigation. Fixed personal AHK shortcut output is another path; this guard
does not mean every controller/key output is globally disabled in native menus.

Preserve the default guard on arbitrary saved bank actions. Future menu scrolling
can have an explicit native-menu route, with owned modifier releases and a fresh
press after a context change. NPC navigation/confirm/back can be intentionally
classified as menu-capable later, without globally unlocking inventory, job,
quickswitch or arbitrary user commands. menu_open is only a broad boolean; it
does not identify a specific NPC/item menu or certify that an emote is appropriate.
No menu policy or companion mapping changes are made by this cleanup checkpoint.

## Migration sequence

1. Preserve the current checkpoint; keep source/development material separate
   from the installable manifest. Index examples and label snapshot provenance.
2. Centralize asset paths, including compatibility for saved image references;
   verify existing default and nondefault artwork before moving it.
3. Move one module family at a time. Update require calls, package.loaded test
   fixtures, source-reading tests, dynamic file reads and packaging together.
   Avoid a global package.path change that can affect other loaded addons.
4. Move themes only after the resolver/builders can load both layouts. Validate
   complete fresh installation and overlay onto an existing user installation.
5. Check Lua loading/generated resources, XML catalogs and linked slot icons,
   all menu/companion assets, wrapper startup, lifecycle and multibox ownership.
   Native Windows/FFXI testing remains necessary; path inspection alone cannot
   prove runtime compatibility after a refactor.
