# Trust Forward Merge 1 — A — October 24, 2026

MessagePolish1 and the separate Trust-menu test branch diverged. Installing the
former replaced the sender while the newer Trust retained its receiver. This
forward merge preserves MessagePolish and Xbox Extended, restores direct menu
ownership, Windows CRLF leases, held-R1 close, repeat and stale-input guards.

Keep Trust-MenuToggle-Full-20261023. Stop the shared wrapper, unload XIVcrossbar
on every client, merge this cumulative code patch, reload clients, then start
the wrapper once with neutral controls. Preserve data and artwork.

Check Controls 9.17-trustmerge1 and Messages in `//xb controller status`.
Open Trust, close chat, release controls, then test ordinary directions,
Confirm/Back, a held direction, submenu changes and R1+Square closing all menus.
Switch clients while holding a direction: no stale press should carry over.
Chat must pause input. With Trust closed, verify ordinary crossbars and banks.
`//trust menu status` reports direct accepted/rejected actions; `//xb diagnostics`
also saves Trust mode/sent count without expanding normal chat status.

Automated: full Lua suite, direct bridge/root routing, AHK simulation and
structural/layout checks. Native Windows/Windower/FFXI acceptance remains pending.
Bank defaults, visibility, disabled second levels and icon browser repairs are
subsequent checkpoints; no positions or saved bindings change in this checkpoint.
