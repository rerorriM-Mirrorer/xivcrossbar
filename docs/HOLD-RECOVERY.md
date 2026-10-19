# Held-input recovery test 1 — October 19, 2026

Author A. Source baseline bdc6706d40b4424bd5bc9eef086c084c750f38d2.
Runtime 0.4.0-a.20261019.directlink1-holdfix1 / Controls 9.10-holdfix.

## Install

Back up the current addon including data/settings.xml. Stop the shared wrapper
with `//xb controller stop`, update the complete addon files while retaining
installed data/config.ini/custom art, reload XIVCrossbar in each client, then
`//xb controller start` once on the computer. Release all controls for startup.
Check `//xb controller status`: active route messages, Controls 9.10-holdfix,
Hold recovery protocol=1. Preserve current bank settings; do not reapply the
Cioara preset just to install this fix. Public/frozen branches are unchanged.

## Live acceptance

Use the same Trust menu setup as the reported failure. Hold R1 then R2 and tap
Down several times, keeping both controls held. After a brief interruption,
release the action button and try another Down: it should work without releasing
R1/R2. Repeat for L1/L2, bare R1 and ordinary R2. Test trigger-first separately:
it must remain the ordinary trigger bar, not turn into the companion chord.
No stale action or menu choice should execute on recovery. Native delivery to
Trust remains a live check; an AHK acknowledgement is not proof of menu movement.

Capture with `//xb controller trace on`, reproduce within 30 seconds, then
`//xb controller trace off` and `//xb controller status`. Trace now records
receiver reset reasons, lease-gap/ack-backlog stalls and recovery completion.
Check focus/client switch or disconnect still cancels, and that returning with
controls held requires neutral. No automatic startup/cross-client hold transfer.

## Boundaries

Existing 350 ms heartbeat/output checks and 500 ms render-gap detection remain.
They discard old input; a replacement same-client generation can recover only
held controls, ordered by the writer's pre-reset observations. The receiver
accepts resume events only in an authorized recovery generation and only for
buttons 11 through 14. No slot commands or native directions are replayed.
All action buttons and any newly pressed control must be released before
restoring the original held controls. After two seconds without healthy polling,
recovery is refused and neutral is required. Chat/edit/setup/cutscene eligibility
is checked again before restoration. Ordinary double-tap timing is reset; no
synthetic double tap is generated to recover a double-tap bar.

The code does not establish why Windows/controller polling stalled. The original
trace proves the input cancellation/quarantine, not its exact originating guard.
The update targets the resulting prolonged hold loss. Frequent or long stalls
may still need separate performance investigation. No timeout relaxation is used.

The compact Options flash, menu-type recognition, NPC cutscene access, SlowEnter
batch delivery and one-command live test/screenshot runner remain pending.
