# Recovered Fenrir bindings and catalog — October 16, 2026

Author A. Copied byte-for-byte from the previously prepared
XIVCrossbar-Franklet-Lionstag-Bindings-Test1.zip. Controller source at that
delivery was 0d8888fdc5ae74ff4e9626cd8365445b1fa45cfa (Personal9 Test4).
The XMLs are data presets; they do not replace DirectLink runtime/controllers.

Source bar: user-supplied ALL-JOBS-DEFAULT(3).xml, October 15.
Source catalog: user-supplied CustomActions.xml, October 14.
This is the latest supplied pair recovered for that delivery, not a fresh
export from the user's currently running PC.

## Contents and deliberate installation

| File | Destination under xivcrossbar/ |
| --- | --- |
| Cioara/ALL-JOBS-DEFAULT.xml | data/hotbar/Fenrir/Cioara/ALL-JOBS-DEFAULT.xml |
| Franklet/ALL-JOBS-DEFAULT.xml | data/hotbar/Fenrir/Franklet/ALL-JOBS-DEFAULT.xml |
| Lionstag/ALL-JOBS-DEFAULT.xml | data/hotbar/Fenrir/Lionstag/ALL-JOBS-DEFAULT.xml |
| global/CustomActions.xml | data/CustomActions.xml, only if adopting this matched global catalog |
| reference/CustomActions-uploaded.xml | Reference only; original unreconciled catalog |
| optional/SUGGESTED-ACTIONS.xml | Optional ideas only; no automatic import |

Unload XIVCrossbar on affected clients before replacing a profile, and keep
current data as rollback. Copy only the selected character's preset. Preserve
settings, job/subjob sets, character catalogs and companion assignments. Keep a
newer installed global catalog; merge desired actions through the editor rather
than replacing it. The global catalog affects all clients using that installation.

Do not combine this catalog with ../../CustomActions-template.xml wholesale:
they share the same 34 IDs, with some different values. Prefer this matched
catalog when adopting these bars; see CATALOG-RECONCILIATION.md for differences.

## Exact preset differences

Cioara's bar is the supplied original unchanged. Franklet and Lionstag copies
are identical and remove only hotbar_l/slot_ll, slot_ld, slot_lr and slot_lu:
the four L2 D-pad nodes in All Jobs Default. All other bar content is preserved.
Clearing this fallback layer does not clear bindings supplied by other sets.

The matched global catalog retains all 34 uploaded records/IDs and adopts the
newer linked values from the bar. This prevents synchronization from reverting
the supplied bar to the older catalog values. Reference bytes remain unchanged.
The retained Return label says Basic in this historical snapshot; internal basic
still works and the current interface displays Main.

Dependencies include the corresponding Switch_focus, Send, Trust, SlowEnter,
NPCMirror, SendAllTarget and Superwarp features used by the selected actions.
Commands and optional suggestions are preserved from that delivery, not newly
certified against every currently installed adjacent addon. No new L1 or NPC/
Trust layer proposal is applied to these presets.

## Provenance and validation

Original bar SHA256:
8cba819dac91893b522b9e46dc2791c8bbd78e0362f9817de5fa1a9e65f1c7c6

Original uploaded catalog SHA256:
6327780f6946e6ef2cf82d83366f5948e7965a9ade2f2d2dfdb2f57f456426aa

This copy is verified against the earlier ZIP member bytes; XML parses, paired
catalog IDs are unique, linked current action/alias/icon values match the catalog, and the
adjusted bars differ by only the four requested nodes. Live execution remains
dependent on the installed addons, character and current game state.

The original last-icon marker on the linked All Confirm action is blank while
its current icon is custom_actions. That historical override marker is preserved
in all three original/derived bars; it is not a missing current icon or a reason
to rewrite the supplied snapshots.
