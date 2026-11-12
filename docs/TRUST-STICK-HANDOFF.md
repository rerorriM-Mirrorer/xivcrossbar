# Trust stick-message handoff

XIVCrossbar personal-controls test, 2026-11-12. Trust changes are NOT included.

Sender protocol remains a 30 ms synthetic vk1D/sc07B key pulse (Trust DIK 0x7B)
to the currently focused FFXI client, using its matching fresh Trust lease.
Me offers two arming policies: client (one per focus session), neutral (one per
fresh movement after 100 ms below 12% stick magnitude; fires at 24%). Neutral
consumes each attempt, including unavailable/rejected contexts, and requires
another center before retrying. No per-frame messages or delayed neutral-mode
replay. Existing off/test/on bridge controls remain available.

Proposed receiver behavior for the separate Trust conversation:
- Every fresh gesture can request immediate local manual movement takeover,
  including party follow/formation, enemy approach and recorded/stuck paths.
- Preserve remembered follow/enemy/path targets. Gate movement producers before
  cancelling active/queued movement and suspending position/zone/path/recovery
  subscriptions, so callbacks cannot immediately restart movement.
- Cancel native follow. Avoid a blanket run(false); release only Trust-owned
  movement input once during cancellation, without fighting manual stick motion.
- Do not repeatedly rebuild/reset an already-valid follow of the same leader.
  Deduplicate action/IPC/chat work; receipts should reflect acceptance/rejection.
- Proposed explicit Stop/Stopall parks actions and movement. Automatic follow
  requests while parked are rejected/discarded, never saved for later replay.
- Explicit Pause or Act releases park but requires a fresh follow request.
  Pause keeps actions paused; Act permits actions. Stop's current retreat behavior
  has NOT been changed by the XIVCrossbar package.
- Prefer receiver-side acceptance for this experiment. Current Send/Ready lease
  policies still apply; Ready may suppress sending when its lease says not ready.
  Sender does not know or clear Trust park state and does not issue Start/Act.

Please implement and verify these semantics in Trust independently before
claiming the combined behavior. Test busy/engaged approach, paths, parked peers,
repeated gestures and repeated same-leader follow requests without queue churn.
