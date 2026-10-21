# Startup / Blood Pacts / Registry 1

Cumulative changed-files patch for an installed DirectLink Cleanup 1 (28304f4),
Timing 1 or Status Cleanup 1 build. Not a complete addon installation. No personal
settings/data, images, test fixtures or unrelated runtime files are included.
Patch contents represent one published source checkpoint; see PATCH-INFO.txt.

## Install

1. Back up the installed xivcrossbar folder. Run `//xb controller stop`.
2. Unload XIVCrossbar in every client (`//lua u xivcrossbar`).
3. Merge the patch's xivcrossbar folder into your installed folder, preserving
   data, settings and images. Do not rerun the folder-cleanup helper.
4. Load XIVCrossbar in each client (`//lua l xivcrossbar`).
5. With buttons released, run `//xb controller start` once per computer.
6. Check `//xb inputstatus`: directlink1-startup-pacts1. Controller status should
   report Controls 9.12-registry1. Earlier wrapper processes need the restart.

## Live checks

- The crossbar-load announcement uses the same palette as status, one line.
- On a SMN character, open Rage and Ward action binding menus. Choices should
  match the available ability IDs reported by the client, not all resource pacts.
  Check a known available pact and one that should not be available. Reopen the
  selector after an avatar/job/level change. Empty native data stays empty rather
  than exposing all pacts. This editor change does not alter existing bindings.
- Check pact art in both menus: individual custom art wins. Generic overrides
  may live at `<pack>/blood-pacts/rage/bloodpact.png`,
  `<pack>/blood-pacts/ward/bloodpact.png`, `<pack>/blood-pacts/bloodpact.png`,
  `<pack>/bloodpact.png`, or `<pack>/blood-pacts/rage.png` / `ward.png` under
  images/icons/. Legacy/custom-pack resolution remains in effect. The final
  shipped fallback uses abilities/00173.png (Rage) or 00174.png (Ward).
- Use native auction/inventory menus as usual. Check quick taps, held direction
  and release, Options chooser, and shoulder combinations. The registry tuning
  does not change debounce, page-turn rules, repeats or recovery thresholds.
- Reload one client while others remain open; controls must stay available.
  With last-client shutdown enabled, confirm closing the final addon client
  still stops the wrapper. Do not deliberately crash clients to test this.

If input remains sticky, `//xb controller trace on` collects the same paired
logs as Timing 1. Stop or allow the capture to finish, then send the controller
log plus that character's Lua log and a brief description. New operation timings
identify client-registry-scan, client-record-read and client-owner-check. Do not
infer game cursor movement solely from a native-key request being recorded.

## Rollback

Stop the wrapper and unload all clients. Restore the backed-up Lua/AHK code,
reload clients and start the old wrapper once with controls released. Data and
bindings were not migrated by this patch. Keep old logs for comparison.
