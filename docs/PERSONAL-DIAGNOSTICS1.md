# Personal Unified Diagnostics 1

Run `//xb diagnostics` (or `//xb diagnostics on`), reproduce the issue, then
wait for the saved message. Input recording lasts about 30 seconds; assembly
waits until 32 seconds so the AHK buffer can flush. Upload the single new log
under `xivcrossbar/data/diagnostics/`.

`//xb diagnostics mark` records a mark. `//xb diagnostics off` finishes early
after a short wrapper-flush allowance. `status` reports whether a capture is
running. `controller trace on|off`, `inputtrace`, and `rendertrace` use the same
capture; `rendertrace save` finishes it. Diagnostics are opt-in and bounded.

Each uniquely named report contains status at start and finish (addon/wrapper
versions, profile, bank settings, receiver state), Lua input, AHK input, and the
bounded rendering history. AHK tick times and Lua epoch times remain separately
labeled; their capture ID and button sequence numbers correlate the streams.
Missing AHK data is explicitly marked, never presented as successful delivery.
Without a running wrapper, Lua/render/status diagnostics still work. An old
running wrapper must be restarted with this batch before unified capture works.

Only one shared-wrapper recording should run at a time. A known active capture
rejects another start. Controller request files remain runtime IPC under data;
they are not historical logs. Failed final saves retain component logs. An
unload saves available data immediately and labels possibly unflushed AHK data.

Static status details now save to `data/diagnostics/status-<character>.log`.
Movement's existing log moves to `data/diagnostics/trust-movement.log`.
Existing historical logs/backups are not moved/deleted. `personal-controls`,
`controller-clients`, hotbar, settings, catalogs and their runtime files retain
their existing locations and semantics.

## Primary bank display and aliases

L1/R1 remain hold-to-display by default. Native chat, menus and dialogue do not
hide them. Holding a primary shoulder can also show its panel when another
controller menu owns actions. This does not permit bank actions in that menu.
XIVcrossbar's own editor/chooser/setup retains its existing display gate.
Focus/readiness, Trust input ownership, editor/setup and explicit disable
restrictions are unchanged. Second-level banks and panel positions are unchanged.

`//xb bank l` means `//xb bank l1`; `r` means `r1`. Existing `l2`/`r2` aliases
remain unchanged. Existing explicit hide/menu/display settings are preserved.
For a character with an older explicit menu-hide setting, use:

```
//xb bank l menus on
//xb bank r menus on
//xb bank l display held
//xb bank r display held
```

## Bare Cancel in native chat

The supplied October 28 UTC capture records seven Circle down/up pairs received
by Lua while chat remained open, with no router/native Escape calls. Earlier
gameplay Circle produced paired Escape requests. A narrow exception now forwards
the configured bare Cancel button to Escape in native chat. Confirm and other
bare chat buttons remain blocked. An up releases its original Escape even if
chat closes between edges. Shoulder/trigger combinations retain bank ownership.

## Installation and verification

Personal cumulative code patch, requiring the existing personal DirectLink
installation/artwork. Do not install over the separate public beta. Unload XB
across clients, stop the shared wrapper, extract into addons, then reload.
No user data or artwork is included. Integrated Trust Send/Ready movement code
from the October 26 companion package is preserved; its log path alone changes.

Native Windows/AHK/Windower tests are pending: Cancel in chat, display during
Trust navigation, one complete report after automatic/manual stop, and fallback
without a running wrapper. The test record lists actual automated checks.
