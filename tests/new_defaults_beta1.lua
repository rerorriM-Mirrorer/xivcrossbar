-- Fresh-install defaults and saved override behavior for public Beta 1.
local d=require('defaults')
local theme=require('theme')
local visibility=require('visibility')
local controller=require('controller_transport')
assert(d.GameplayDPad=='ijkl','Fresh-install bare D-pad must be IJKL')
assert(d.VisibilityMode=='oninput','Fresh-install bars must be trigger visible')
assert(d.Animation.TextFade==true,'Text must fade with artwork by default')
assert(d.Animation.Enabled==true,'Main fade must remain on')
assert(d.Animation.FadeIn==.1 and d.Animation.FadeOut==.5
    and d.Animation.LoadFadeIn==2,'Fade timings must not change')
assert(d.TextSettling==true,'Measurement stabilization must stay enabled')
assert(d.AutoAttackIndicator.Enabled==false,'Tracking disabled by default')
assert(d.AutoAttackIndicator.Opacity==0,'Swing bar hidden by default')
assert(theme.apply(d).aa_enabled==false and theme.apply(d).text_fade==true)
assert(controller:gameplay_key({arrow='up'}, {},d.GameplayDPad)=='i')
assert(controller:gameplay_key({arrow='left'}, {},d.GameplayDPad)=='j')
assert(controller:gameplay_key({arrow='down'}, {},d.GameplayDPad)=='k')
assert(controller:gameplay_key({arrow='right'}, {},d.GameplayDPad)=='l')
assert(not visibility.should_show(d.VisibilityMode,false,false,false),
    'No visible bar with released trigger and no startup reveal')
assert(visibility.should_show(d.VisibilityMode,true,false,false))
assert(visibility.should_show(d.VisibilityMode,false,false,true),
    'Startup reveal still visible')
assert(not visibility.should_show(d.VisibilityMode,true,true,false),
    'Cutscenes suppress bar')
-- Simulate saved values taking precedence after config has merged settings.
local previous_fade,previous_tracking=d.Animation.TextFade,d.AutoAttackIndicator.Enabled
d.Animation.TextFade,d.AutoAttackIndicator.Enabled=false,true
assert(theme.apply(d).text_fade==false and theme.apply(d).aa_enabled==true,
    'User-chosen opposite values must remain effective')
d.Animation.TextFade,d.AutoAttackIndicator.Enabled=previous_fade,previous_tracking
assert(visibility.should_show('always',false,false,false),
    'User-selected always-visible mode must remain supported')
assert(controller:gameplay_key({arrow='up'}, {},'arrows')=='up',
    'User-selected legacy D-pad mode must remain supported')
-- No timer has yet been added: this regression deliberately documents the
-- current immediate hide after trigger release (plus existing fade-out).
assert(not visibility.should_show('oninput',false,false,false))
print('Beta defaults: IJKL, oninput, text fade ON, swing tracking OFF, override modes and old fade durations passed.')
