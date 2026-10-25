# Installer unload receiver 1 — A — October 24, 2026

Runtime directlink1-installer1 / Controls 9.19-lifecycle1 unchanged. Adds only a
local installer unload receiver; ordinary menu/controller permissions unchanged.
User confirmed Survival Guide controller working again; Felm/similar NPC live
acceptance still pending. Wrapper shutdown diagnosis also remains unresolved.

The installer writes data/installer-request.ini containing one bounded unload
request: protocol 1, a 32-character lowercase hexadecimal ID, action unload,
expiry no more than 120 seconds ahead and an END trailer. At most once a second,
the existing prerender callback checks it. Unsupported/malformed/expired requests
are ignored. A client with an XB menu/editor/chooser/setup open acknowledges busy
and waits; otherwise it acknowledges unloading and calls existing graceful unload
once per request. Load-time check also prevents starting a newly requested client.
No arbitrary commands, reload, downloads, file copying or wrapper killing are
implemented inside Lua. Owner-file checks remain the installer's completion test.

Current installs cannot consume this protocol until updated once. Bootstrap must
therefore allow manual unload; subsequent installs can request it automatically.
Each acknowledgement is installation/session/request scoped. The installer removes
only its own request/ack files afterward. No permanent game input block added.

Automated checks exercise actual helper validation, expiry/bounds, busy menus,
failed acknowledgements, CRLF, per-request dedup and graceful callback dispatch.
Live Windows/Windower handoff still needs testing with two clients, an open editor,
a pre-login client and a minimized peer. A busy/nonresponding owner must make the
installer wait/abort without replacing code. Reload remains manual by user choice.
