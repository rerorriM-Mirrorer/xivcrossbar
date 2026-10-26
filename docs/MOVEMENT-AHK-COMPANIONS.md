# Movement AHK companion repair

Author A. October 26, 2026. Source runtime c216ac2bb90738347d5b60efa5ef205fe6077d37,
personal test/trust-movement-20261025. Public beta unchanged.

The Cioara screenshot reports nonexistent WrapperClientsStatus() at line 348
of ffxi_directinput.ahk. That helper is defined in the matching included
controller_clients.ahk. The screenshot indicates an older/mismatched companion;
the installed companion's exact contents have not been supplied.

Earlier chat advice to replace only two AHK files omitted a prerequisite:
all other runtime companions must already match the source baseline.
The previous full paired ZIP contains the matching companions. This smaller
repair delivers the complete runtime AHK include closure from that same source:

- ffxi_directinput.ahk
- controller_clients.ahk
- controller_messages.ahk
- personal_controls.ahk
- personal_gestures.ahk
- movement_signal.ahk

No AHK runtime behavior is changed by this repair. Controls stays
9.19-lifecycle1 and movement stays 0.2.0-trust1.

## Install

1. Stop the shared wrapper with //xb controller stop. If startup already failed,
   the failed script is not running; close its error dialog too.
2. Back up the six listed files from the existing addons/xivcrossbar folder.
3. Merge this package's xivcrossbar folder into that existing folder, replacing
   all six AHK files. Avoid creating xivcrossbar/xivcrossbar nesting.
4. Start the shared wrapper once on that PC with //xb controller start.

Repeat on another PC only if it also needs this update. The wrapper is shared
by clients using the same installation; this is not a per-character replacement.
Keep existing Lua files, data, settings and artwork. This is a repair for the
personal DirectLink installation receiving the integrated Trust movement test,
not a public-beta upgrade. Keep the separate trustmovement addon unloaded.

## Verify

Confirm the error no longer appears, normal bank/menu buttons still work and
switching clients then moving triggers Trust following once. The receiver's
Movement > Status should show accepted signals. Controls/movement versions can
be checked in data/controller-status.ini.

Nine JS suites and AHK static checks pass on Linux; the static dependency check
also detects a fixture missing WrapperClientsStatus. No native Windows/AHK run
was available here. Startup on the affected installation remains to test.
Restore all six backed-up files together to roll back this AHK update.
