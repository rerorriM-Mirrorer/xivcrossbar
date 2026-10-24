# Shared menu buttons — A — October 24, 2026

`//xb controller menuswap on` swaps Share and Options for all characters in this
XIVcrossbar installation. Options opens/exits the binding menu; holding Share
opens the page chooser and releasing it closes the chooser. `off` restores the
original roles; `status` reports the saved preference and any pending adoption.
The equivalent logical pair also swaps on other controller layouts.

Default OFF. The shared file is `data/controller-menu-buttons.ini`, independent
of character settings and bindings. Each installation needs its own choice.
Clients check at most twice per second and adopt after releasing controls and
closing XIVcrossbar menus/setup/text entry. Background clients adopt quietly.
The binding-menu Exit artwork and both crossbar hints follow the active roles.
AHK's physical button stream and external addon receivers are unchanged.

Live checks: enable on one character, release controls, then focus another.
Check Options opens/closes the editor and its Exit hint shows Options. Hold
Share, navigate pages, release and check the chooser closes once. Repeat with
the binding editor open, using cancel and typed-field entry. Ask another client
to change the setting while the first holds the chooser: its release must keep
the original role; adoption waits until closed/neutral. Try OFF, restart all
clients, and confirm persistence. Try Trust/native menus afterward.

Automated checks use independent preference clients, atomic-save mocks, actual
button predicates, Exit hint and root bank/message routing. Native acceptance
on Windows/Windower/FFXI remains pending. No user data or artwork is packaged.
