# Color and opacity settings

This describes the current code, not the contents of an individual character's
settings.xml. Values below are defaults; your saved values may differ.
RGB components use 0–255. Alpha/Opacity normally use 0–255: 0 transparent,
255 opaque. Global crossbar fades multiply these base opacities.

Animation.TextFade=false preserves endpoint text visibility. Set it true, or
use //xb textfade on, to fade glyphs, text backgrounds and strokes with the bar.
Colors and base alpha values are unchanged. //xb textfade off restores endpoint
behavior; bare toggles and status reports.

| Setting | Default | What it controls |
| --- | --- | --- |
| Color.MpCost.Red/Green/Blue | 194,253,195 (#C2FDC3) | Spell MP-cost numbers on bound slots; the review screen's pale green |
| Color.MpCostInsufficient.Red/Green/Blue | 255,149,151 (#FF9597) | MP-cost numbers when current MP is below recorded cost; the review screen's soft pink |
| Color.TpCost.Red/Green/Blue | 254,222,0 (#FEDE00) | TP-cost numbers on bound slots; yellow |
| Color.Feedback.Opacity | 150 | Starting intensity of the feedback image drawn over a fired slot |
| Color.Feedback.Speed | 30 | Alpha removed per rendered update from that feedback image; higher fades faster. It is not an RGB color or a duration in seconds |
| Color.Disabled.Opacity | 100 | Dimming applied to the slot icon, cost and element when an action is disabled by recast or resources |
| Texts.Color.Red/Green/Blue | 255,255,255 | Ordinary crossbar labels and general menu text; specialized selected/default/error fields override these colors |
| Texts.Color.Alpha | 255 | Intended ordinary-text opacity; currently passed into theme options but never used by the text constructors |
| Texts.Stroke.Red/Green/Blue | 20,20,20 (#141414) | Dark outline around text |
| Texts.Stroke.Alpha | 200 | Outline opacity in 0–255; about 78% at the default |
| Texts.Stroke.Width | 2 | Thickness of the outline, in original layout units; scales with crossbar geometry. Not a color |
| Style.SlotAlpha | 100 | Opacity of the underlying slot background image; its color comes from the theme artwork |
| buttonbackgroundalpha | 150 | Opacity of the large trigger-held background field behind a crossbar section |

The feedback speed is frame/update based, unlike Animation.FadeIn/FadeOut,
which are in seconds. Its current code has an overshoot edge case if a speed
step passes below zero; keep that on the cleanup list before freely retuning it.

## Timing bars

These settings affect XIVCrossbar's internal timing bars.
All now use small rounded endcaps, including their backgrounds. The two-color
auto-attack bar rounds only its outer ends so its internal color join stays flush.
They follow the crossbar's scale, dragging, compact layout and fade together.

| Group / field | Default | Meaning |
| --- | --- | --- |
| SkillchainIndicator.WindowWaitingColor | 237,28,36 (#ED1C24) | Waiting portion before the skillchain opportunity opens; red |
| SkillchainIndicator.WindowOpenColor | 15,205,5 (#0FCD05) | Open skillchain opportunity; green |
| SkillchainIndicator.Opacity | 220 | Strength of the skillchain timing bar |
| SpellLockoutIndicator.PrimaryColor | 200,200,255 (#C8C8FF) | Main post-spell lockout bar; pale blue |
| SpellLockoutIndicator.EndingFlashColor | 15,205,5 | Final 15% of that display; changes to green rather than a repeated blink |
| SpellLockoutIndicator.Opacity / Duration | 220 / 3 seconds | Bar strength and spell-lockout duration |
| WeaponskillLockoutIndicator.PrimaryColor | 255,150,0 (#FF9600) | Post-weaponskill lockout display; orange |
| WeaponskillLockoutIndicator.Opacity | 220 | Strength of that bar |
| JobAbilityLockoutIndicator.FullLockoutColor | 220,30,30 (#DC1E1E) | First part of the post-job-ability display; red |
| JobAbilityLockoutIndicator.PartialLockoutColor | 15,205,5 | Second part of that display; green |
| JobAbilityLockoutIndicator.Opacity | 220 | Strength of the job-ability bar |
| AutoAttackIndicator.BeforeEstimateColor | 220,30,30 | Swing-timer portion before the estimated next swing; red |
| AutoAttackIndicator.Enabled | true | Independent processing gate; //xb autoattack off clears/stops tracking while preserving colors/opacities |
| AutoAttackIndicator.PastEstimateColor | 15,205,5 | Portion extending beyond that estimate; green |
| AutoAttackIndicator.Opacity | 0 | Normal swing-bar strength; zero disables the entire swing display |
| AutoAttackIndicator.PausedOpacity | 110 | Swing-bar strength while its timer is paused, if the bar is enabled |
| AutoAttackIndicator.BackgroundOpacity | 150 | Black background behind the active swing bar |
| AutoAttackIndicator.PausedBackgroundOpacity | 75 | That background's opacity while paused |

Skillchain timing comes from the bundled skillchain tracker and the living
current target. Its thin waiting bar grows until the opportunity opens, then
the thicker open bar contracts. Spell, weaponskill and job-ability settings
share one post-action display: the latest action starts the appropriate timer.
The spell duration is configurable (default 3 seconds); weaponskills and job
abilities use 2 seconds. JA changes from Full to Partial color after 1 second.
These visual hints do not enforce locks or replace individual slot recasts.
Spell/WS/JA Opacity=0 hides that mode's bar and background. Skillchain Opacity=0
now also hides its fill and black backing. Set it under SkillchainIndicator in
settings.xml and reload. The internal tracker stays active because it supplies
on-slot chain/burst cues too. Their shared display uses each action kind's own
palette, not one common color. All three lockout opacities default to 220/255.
The spell's final 15% means its last 0.45 seconds at a three-second Duration;
it is an inherited visual threshold. JA has one timer with a halfway color
change, rather than separate readiness measurements for two game locks.

AutoAttack is a learned swing estimate, not a live server countdown. It averages
up to 10 observed intervals, subtracting the recorded WS/JA/debuff pauses, and
starts learning at the second actual swing, and resets history between
engagements. Without an estimate it displays
a 10-second fallback. Once learned, the display covers 1.5 times the estimate:
red remaining time before the estimate plus a green allowance after it. Green
is already visible alongside red before the expected swing; it does not mean
the next attack is guaranteed. A completed swing restarts the display. If no
swing arrives by the end, it hides. Pause colors/opacity freeze and dim it;
ordinary Opacity=0 disables the whole AA display even if PausedOpacity is nonzero.
It does not stop swing-history updates or pause bookkeeping. Enabled=false,
or //xb autoattack off, now stops those, clears state and immediately hides the
bar. The estimator owns no scheduled callbacks; timed WS/JA pauses use expiry
timestamps. Generic action/status handlers remain for other functions. Live
CPU cost has not been measured. On preserves opacity, so on with Opacity=0
learns without displaying; set a nonzero opacity to see the bar.

Possible improvements, not included: reset estimates for weapon/haste changes
within a fight; show learning
or confidence rather than implying precision. Alternatively the same drawing
could become a brief confirmed-swing pulse, or the AA indicator could be removed.
A recommends keeping it disabled until its estimate is useful in your gameplay.

## Menu palette

Several refinements are currently code constants, not XML color settings:
selected yellow text (255,216,112), defaulted custom-action green
(194,253,195), unavailable pink (255,149,151), gold/brown selection background,
blue/brown page buttons, cursor opacity and menu background gradient.
Changing Color.MpCost or Texts.Color does not retheme all those elements.
Icon/slot/frame colors also come from their image assets.

The personal MP-cost default now uses that same green. Existing settings.xml
values are preserved. To change an installed character's MP text too, set
Color.MpCost to Red=194, Green=253, Blue=195 and reload the addon. TP colors
are unchanged. A spell with insufficient MP dims its icon, cost and element;
this uses its recorded resource cost, not a calculation of every gear/buff
modifier. Linked spell metadata gives custom commands the same visual check.
Its cost number also turns pink specifically for insufficient MP. Once MP
recovers, it returns to the configured normal color even if recast still dims
the icon. TP color is unaffected.

The stroke setter now uses stroke_alpha. It previously passed a 0–255 alpha
to stroke_transparency, which expects a 0–1 transparency fraction: 0 opaque,
1 transparent. Supplying 200 there produces an invalid negative alpha in the
library's conversion. This repair makes the setting use its intended units;
it does not change your saved value. Texts.Color.Alpha remains unused and is a
separate pending wiring change. Defaults 1 itself did not change rendering.

Source trace: defaults.lua -> theme.lua -> ui.lua and the menu text constructors.
Windower's [texts.lua](https://github.com/Windower/Lua/blob/dev/addons/libs/texts.lua)
defines stroke_alpha in 0–255 and stroke_transparency as a 0–1 fraction.
