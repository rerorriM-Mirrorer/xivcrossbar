# Dependencies and repository boundaries

## XIVCrossbar

XIVCrossbar itself needs Windower 4, its Lua libraries/resources, the bundled
Lua modules and icon/theme assets, and AutoHotkey for the selected existing
controller wrapper. `socket` supplies the visibility timer. Its resource
generator builds ignored `resources/crossbar_*.lua` caches when needed; the
complete test package retains the caches from the working installation.

NPCmirror, Send, SlowEnter, AddonToggle and Trust are not imported with `require`
by XIVCrossbar. They are command backends used by particular saved actions.
Removing a backend can leave its button ineffective even though XIVCrossbar
loads normally.

| Saved action/backend | Needed for that action | Source or current home |
| --- | --- | --- |
| `npcmirror interact/enter/esc/status/stop` | NPCmirror on participating clients | [ffxi-NPCmirror](https://github.com/rerorriM-Mirrorer/ffxi-NPCmirror) |
| `npcmirror call` | NPCmirror and Send | NPCmirror; Send from [Windower-Addons](https://github.com/rerorriM-Mirrorer/Windower-Addons/tree/dev/addons/send) |
| `send @all slowenter once` and `... once esc` | Send and SlowEnter on clients receiving input | `addons/slowenter` in NPCmirror until separated |
| `sat alltargetreport/fetchall/stop` | The currently installed SendAllTarget implementation | Working source still in NPCmirror; [SendAllTarget-reference](https://github.com/rerorriM-Mirrorer/SendAllTarget-reference) is a reference, not a proven identical replacement |
| `switch back/n/p/to ...` | Existing switch-focus command provider | Installed Windower plugin; reported working in the previous live tests |
| `trust ...` | Trust and its own dependencies | [trust fork](https://github.com/rerorriM-Mirrorer/trust) |
| `sw ...` in optional Travel prototype | SuperWarp plus usable/unlocked destination | [superwarp fork](https://github.com/rerorriM-Mirrorer/superwarp) |
| `at cycle` in optional Utility prototype | Later AddonToggle 2.0 implementation | Separate development; later archive has the invalid-HideAt correction |
| Existing `warp` action | Its existing alias/addon command provider | Provider not established by this XIVCrossbar-only capture |

## NPCmirror

The reviewed revision is `bc991ec77d6740efb929c6186500b40dd92eccb1`.
Its only explicit Lua module requirement is Windower's `packets` library.
Discovery, target agreement, session state and guarded key taps use Windower
APIs and IPC directly. Core interaction does not load XIVCrossbar, SendAllTarget,
NpcInteract, interactbruh, SirPopAlot, Enternity, SuperWarp, or project `libs/`.

NPCmirror still sends `slowenter off` while preparing/stopping sessions to
disable a competing raw input loop. That is coordination with an optional
installed tool, not an imported runtime module. Its `call` command delegates
follow to `send @others`, so Send is needed for that convenience action.

The private repo's `libs/README.md` confirms no shared runtime modules yet.
Keep NPCmirror's code and tests in that repository. Keep Send/SlowEnter/SAT
available where the preserved controller actions rely on them. The unrelated
reference addons can be documented with source links without copying them into
XIVCrossbar's runtime. This consolidation changes no NPCmirror repository files.

## AddonToggle and SlowEnter

They remain independent tools. The cumulative branch has only an earlier
AddonToggle 2.0 draft; `xivcrossbar-current-code.zip` and the review archive hold
the later invalid-HideAt fix. Preserve that version when its own repository is
created. Neither that addon nor NPCmirror's tests are included in this fork's
Lua test runner. SlowEnter's current working source remains in NPCmirror until
its separate move is useful.
