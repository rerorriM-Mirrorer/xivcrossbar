# L1 Party 1

Requires latest Trust Party Commands / Focus Stick / Widgets 1, which implements
trust ready and trust standdown. Verified against the delivered command source.
Cross: Stand Ready / trust ready / assist.png.
Circle: Stand Down / trust standdown / follow.png.
Square: Trust Toggle / trust toggle / return-trust.png.
Triangle: Trust Menu / trust menu / abilities/book_white.png.

The Cioara preset reads these same factory values. Existing saved entries are
preserved. The uploaded data contains explicit overrides and custom menu entries;
none are replaced by installing this update. To deliberately adopt just four
Closed face buttons on the current client, use:

```
//xb bank l default cross
//xb bank l default circle
//xb bank l default square
//xb bank l default triangle
```

Do not apply the full Cioara preset merely to update those four slots: its
existing explicit behavior also resets other bank definitions/policies.
Menu-context overrides remain unchanged. Icon overrides take priority, and the
normal asset resolver preserves custom artwork. Other bank entries and panel
positions are unchanged. No AHK/transport/stick changes are included.

Install after Delete Set 1: unload xivcrossbar on all clients, overlay the
supplied code folder, reload. No data or artwork files are supplied. Back up the
three runtime files first; restoring them and reloading rolls code back.
Verify the four inherited/restored buttons, acknowledgments from Trust, personal
Square/Menu behavior, custom menu entries and unchanged stick behavior in game.
Local bank regressions pass; native/controller/FFXI acceptance remains pending.
