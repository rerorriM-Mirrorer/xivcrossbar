# Optional controller experiments

These are the later October 2 development files, kept outside the automatically
launched runtime paths. They have not passed live multi-client acceptance.
The complete package retains the current root `ffxi_directinput.ahk`,
`ffxi_xinput.ahk`, config.ini and settings. No experiment starts by installing it.

The prototype `ffxi_directinput.ahk` uses the measured L1=Joy5 and L3=Joy11.
It arms L3 on press and switches once on release, with trigger/menu/modifier
and foreground-window guards. `ShouldersEnabled=0` deliberately leaves the
failed synthetic targeting path off. L3 is enabled only if this wrapper is
explicitly installed; `L3Joy=0` disables it. R3/PS/Mic remain unassigned.

For a separate trial, exit the current DirectInput wrapper, retain its files,
then copy this wrapper and controller-extras.ini to the addon root and launch
it with AutoHotkey v1. Keep the working config.ini and all XML. Do not switch a
character's XInput/DirectInput settings as part of the first Lua test. A single
client cannot establish client-switch behavior. With two or more, hold L3:
focus must stay. Release: exactly one switch. A held trigger or manual focus
change during the hold must cancel. Restore/restart the original wrapper to
return.

`windower-scripts/xivcrossbar-tests` holds the direct setkey diagnostic. Copy
that subfolder under Windower/scripts; keep the current wrapper and pause any
other shoulder test. Near multiple targets with menus closed, run separately:

```text
//exec xivcrossbar-tests/target-next.txt
//exec xivcrossbar-tests/target-previous.txt
```

Each waits two seconds for chat to close and pairs key-down/up requests. Keep
FFXI focused. Record no movement, one forward, one backward or multiple steps.
`//exec xivcrossbar-tests/target-release.txt` releases Tab and left Shift.
The uploaded shoulder logs proved detection/focus, not successful game input.

These files are retained from `xivcrossbar-ahk-next-tests.zip` and the final
review archive; their code was not modified during consolidation.
