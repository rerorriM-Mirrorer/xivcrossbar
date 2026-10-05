# Batch 2 — Clean globals

Build `0.4.0-a.20261005.10`.

Fresh defaults now use four bars, compact layout, Shared off, OnInput with
five-second release grace, Meiryo size 8 and diagnostics on. The raw PS5
controller baseline selects DirectInput; retain XInput on installations that
use an emulated Xbox controller. Existing saved settings still take precedence.

`//xb debug off` and `//xb debug on` now persist across reloads. Debug includes
custom-action state and icon-folder/texture diagnostics; it does not broadcast
the player's logs to other clients.

Each package includes the same profile-free global settings template, separate
from the runtime overlay so extracting a patch cannot erase local settings.
Apply it deliberately after backing up `data/settings.xml`; existing character
sections can override the clean globals. No character names, IDs or hotbars
are included in this settings template.
