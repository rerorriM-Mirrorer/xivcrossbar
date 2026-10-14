# Custom action template

The template contains 34 commands from our party/controller testing, plus the
six implemented NPCMirror actions within that total. It has no hotbar slots,
placeholder actions, job spell lists or personal AHK mappings. Names have a
category prefix; aliases remain short. The raw commands have no leading `//`.

For a new/empty shared catalog, copy this file as `data/CustomActions.xml`.
If you already have a catalog, merge the template's `<action>` elements inside
its existing `<custom_actions>` root instead of replacing it. Back up the
catalog first. Do not import the template twice: names/IDs must remain unique.
Run `//xb reload`, then use Custom Action in the menu to select and bind entries.
The addon reads the global and per-character catalogs together. For Cioara-only
use, the destination is `data/hotbar/Fenrir/Cioara/CustomActions.xml` instead.

Dependencies: Switch_focus provides `switch`; Trust provides `trust`; Send
provides broadcasts; SlowEnter provides `slowenter`; SendAllTarget's tested
reporting build provides `sat alltargetreport`; Superwarp provides `sw`.
`trust stopall` stops Trust on all participating clients. The separate Stop
Following action pauses following. Edit character destinations if necessary;
`Kil` is the prefix experiment and may be ambiguous with multiple Kil names.
Windurst Walls uses the current menu's `sw hp all Windurst Walls` command.
Instant Warp requires that item. Ranged Attack requires an appropriate weapon.

NPCMirror commands included:

| Action | Purpose |
| --- | --- |
| `npcmirror interact` | Start a session at the selected NPC and coordinate interaction. |
| `npcmirror enter` | Advance eligible ordinary dialogue within the session. |
| `npcmirror esc` | Send a guarded session cancellation/recovery step. |
| `npcmirror status` | Report the active session and participant state. |
| `npcmirror stop` | Cancel the session and queued actions. |
| `npcmirror call` | Ask other clients to follow the current character. |

Menu choices remain under native control; no proposed choice mirroring is
included. Party Target and Raw Cancel are broad broadcasts, whereas NPCMirror
Enter/Escape are guarded by its session checks.

Bow has an explicit `input /bow`, so it works without a per-client Windower
alias. No empty fallback actions are supplied. An omitted icon uses the addon’s
current custom-action default; explicit icons reference shipped default assets.
The custom Attack entry sends `/attack` but does not gain the native bindable
Attack option's automatic engaged/disengaged artwork. For that artwork, bind
Attack from the main menu. Item/Trade Item and job actions still use their menu
binders; no unspecified trade item is invented here.

Checked against the actual Personal 6 catalog decoder and binding snapshot
helper. The six NPCMirror commands were verified in its current Lua handler.
Commands need their dependencies loaded and still require live gameplay checks.
