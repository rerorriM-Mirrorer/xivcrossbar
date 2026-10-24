# Review keyboard trial — A — October 24, 2026

Runtime directlink1-reviewkeys1 / Controls 9.18-bankheld1. Includes Held Banks 1
and earlier cumulative fixes. No saved settings/bindings/positions are replaced.

Arrow keys navigate the custom-action Review and Save / Review and Edit selector;
Enter confirms the selected option; Escape uses that screen's existing Go Back
path rather than the generic close-all shortcut. The legacy final custom-action
confirmation screen is included; other screens retain existing behavior.

Only these six physical keys are intercepted on review, one action per fresh
press. Owned repeats/releases remain consumed after the screen changes. An Enter
already held before review opens cannot activate it. An Enter used to finish a
text field remains owned by the text-field guard after returning to review.
Typing a field keeps existing text entry behavior and its native keyboard block.
Outside review, ordinary typing/chat/Enter handling is unchanged. Windower and
OS-level shortcuts are not replaced. Native event consumption needs live testing.

Install: stop the shared wrapper, unload XIVcrossbar on all clients, merge the
cumulative code patch preserving data/artwork, reload all and start once neutral.
Keep current compatible Trust. Controls 9.18-bankheld1 required for bank chat mode.

Live checks:

1. Open a new action with a name, reach review and navigate every field/footer
   choice using arrows. Enter opens the selected field/choice. Escape returns.
2. Type a name/alias/command, hold Enter while committing, then release. It must
   not activate another review option or open native chat. A new press works.
3. Save Only returns to the action list; Save and Bind opens button assignment.
   Keep Enter held across each transition: no action or native Enter repeats.
4. Escape from review does not also cancel a native menu underneath. Direction
   releases after entering a field/picker cannot move the game or edit new text.
5. Outside review, open native chat and type; physical Enter retains its previous
   function. Test controller navigation, Trust menus and native menus afterward.
6. Switch focus during a held review key. No repeat may submit/cancel on return;
   release then press again. Existing game-held releases are not stolen.

Automated tests exercise the real binder scope and root keyboard prefix, key
ownership/preheld/field-confirmation cases, saved catalog behavior and existing
menu lifecycle checks. Native Windows/Windower/FFXI acceptance remains pending.
