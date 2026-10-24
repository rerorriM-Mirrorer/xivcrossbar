# Held banks — A — October 24, 2026

Runtime directlink1-bankheld1 / Controls 9.18-bankheld1. Correction to Bank
Defaults 2: retain hold-to-show/release-to-hide, including when chatlog/chat is
open. Deliberate bank actions now work in chat/dialogue. Existing hide/disable,
menus drawing, bindings, second levels, scales and positions remain unchanged.

Stop the shared wrapper and unload XIVcrossbar on all clients, merge the code
patch preserving data/artwork, reload and start the wrapper once at neutral.
Keep the compatible Trust installation. Update Lua/AHK together.

`//xb bank <layer> display held|always` chooses display behavior (default held).
If hide was used as a workaround, use `//xb bank l1 show` / `//xb bank r1 show`.
No preset or defaults reset is needed. The legacy cutscenes flag is retained
for saved-file compatibility but no longer restricts explicit bank actions.

Check hold/release with chatlog, chat input, native menus and NPC dialogue.
Deliberately pressed slots should run; bare triggers, implicit Tab/R, touchpad,
stick-click and real-IJKL output remain suppressed during chat/dialogue.
Assigned native keys can intentionally affect chat/dialogue. Focus/login,
readiness, input-test, disconnect and XB/Trust editor ownership still apply.
Opening/closing chat or changing focus releases native holds and suppresses
held-slot replay. Repress to act in the new context.

Verify `display always`, `display held`, show/hide and enable/disable; positions
and commands must stay unchanged. Six-second previews expire back to the normal
bank. Ordinary trigger bars continue to work in normal gameplay.

Automated Lua/root routing/publisher, XML/schema, AHK chat polling, release and
native-output tests pass. Native Windows/Windower/FFXI acceptance remains pending.
Review and Save keyboard navigation is the next separate checkpoint.
