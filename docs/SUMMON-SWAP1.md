# Summon Swap 1

Personal development/ahk-v2-migration patch over Centered Banks 1 (c7f1907). Copy the included xivcrossbar files over the existing addon, then reload xivcrossbar. Keep your data, custom artwork, and newer Trust/AHK files.

An active Trust's typed summon slot now shows **Return**, retaining its portrait and named `/refa` dismissal. The saved label returns when that Trust is absent. No saved slot or catalog entry is rewritten.

Selecting a different typed avatar/spirit spell while an avatar/spirit is out sends Release once, observes the pet, and casts the selected spell after the pet is gone. The spell keeps its normal label and artwork. Selecting the same summon still performs Release; selecting a summon without a pet still casts normally. Custom command macros are unchanged.

The pending request stops on another selected action, player/zone/job changes, defeat, another pet appearing, logout/unload, or a five-second timeout. Repeating the same pending summon does not repeat Release; choosing a different summon replaces the request. Cancellation/timeout messages are shown in chat where useful. A failed Release never forces a cast. This does not automate BST Leave, spell retries, MP/recast recovery, or command macros.

## Live checks

1. Summon Kupipi; her assigned typed Trust slot should read Return, dismiss Kupipi, then restore its saved label.
2. With Carbuncle out, select Ifrit: Release first, Ifrit only after Carbuncle disappears. Repeat with an elemental spirit. Selecting Ifrit again should just Release.
3. Try repeated presses, another action during Release, failed Release, zoning/job change and logout. Check for no late/unwanted cast and useful timeout/cancellation feedback.
4. Confirm ordinary spell use, summon artwork, pet actions and quick-switch Release page retention still behave normally.

Local tests use Lua 5.4 with temporary Windower syntax normalization and mocked game observations. Windows/controller/in-game acceptance remains pending. The separate Ctrl+Left/Right menu-scroll correction remains deferred per the earlier standby instruction.
