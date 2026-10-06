# Migrated design notes — 2026-10-06

These unresolved ideas were migrated from `ffxi-NPCmirror/DEVELOPMENT NOTES.txt` while XIVCrossbar development was being removed from that repository. They are preserved here so pruning the old workspace does not lose intent.

They are design prompts, not accepted features or promises.

- Consider convenient bindings/actions for `/check`, `/wave`, and `/bow`. Bow is already used by current custom-action testing; the broader convenience-binding idea remains open.
- Review the historical FFXIAH XIVCrossbar thread for useful community modifications, pain points, and ideas that may not have reached the qEagleStrikerp lineage: https://www.ffxiah.com/forum/topic/55374/xivcrossbar-a-gamepad-macro-addon
- Consider an optional four-box controller layout where D-pad directions select specific client positions (P1/P2/P3/P4) rather than cycling windows.
- PS5 buttons still intentionally left without a default addon assignment could support optional focus behavior later. Earlier notes specifically considered the PS button for switching/main-client focus and the microphone button for returning to a designated main window. Any such mapping should remain opt-in until native passthrough/consumption behavior is understood.

Related ideas already preserved elsewhere in this repository and therefore not duplicated here include the extra Shift action bank, travel/utility quick-switch pages, drag outline, autohide/grace changes, reveal hitch/fades, CPU/FPS measurement concern, measured controller button numbers, R1/L1 target cycling, and release-only L3 switching.
