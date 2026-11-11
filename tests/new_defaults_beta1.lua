-- Fresh-install defaults and saved override behavior for public Beta 1.
local d=require('defaults')
local theme=require('theme')
local visibility=require('visibility')
assert(d.GameplayDPad==nil and d.ControllerModifier==nil,'Controller must use native gameplay and messages')
assert(d.VisibilityMode=='oninput','Fresh-install bars must be trigger visible')
assert(d.Animation.TextFade==true,'Text must fade with artwork by default')
assert(d.Animation.Enabled==true,'Main fade must remain on')
assert(d.Animation.FadeIn==.1 and d.Animation.FadeOut==.5
    and d.Animation.LoadFadeIn==2,'Fade timings must not change')
assert(d.TextSettling==true,'Measurement stabilization must stay enabled')
assert(d.AutoAttackIndicator.Enabled==false,'Tracking disabled by default')
assert(d.AutoAttackIndicator.Opacity==0,'Swing bar hidden by default')
assert(theme.apply(d).aa_enabled==false and theme.apply(d).text_fade==true)
assert(not visibility.should_show(d.VisibilityMode,false,false,false),
    'No visible bar with released trigger and no startup reveal')
assert(visibility.should_show(d.VisibilityMode,true,false,false))
assert(visibility.should_show(d.VisibilityMode,false,false,true),
    'Startup reveal still visible')
assert(visibility.should_show('oninput',true,true,false), 'Trigger shows auto bars during an event')
assert(not visibility.should_show('oninput',false,true,true), 'Events suppress startup reveal')
assert(not visibility.should_show('always',true,true,false), 'Legacy visibility hides during events')
assert(not visibility.should_show('hidden',true,true,false), 'Explicit hide wins')
assert(d.EventBars==true,'Public Default allows held bars during events')
for _, mode in ipairs({'always','oninput'}) do
    local during=visibility.event_mode(mode,true,true)
    assert(during=='oninput')
    assert(not visibility.should_show(during,false,true,true),'Event hides idle and startup bars')
    assert(visibility.should_show(during,true,true,false),'held bank reveals during Event')
    assert(visibility.event_mode(mode,false,true)==mode,'leaving Event restores selected mode')
    assert(visibility.event_mode(mode,true,false)==mode,'option off preserves original policy')
end
assert(visibility.event_mode('hidden',true,true)=='hidden')
-- Simulate saved values taking precedence after config has merged settings.
local previous_fade,previous_tracking=d.Animation.TextFade,d.AutoAttackIndicator.Enabled
d.Animation.TextFade,d.AutoAttackIndicator.Enabled=false,true
assert(theme.apply(d).text_fade==false and theme.apply(d).aa_enabled==true,
    'User-chosen opposite values must remain effective')
d.Animation.TextFade,d.AutoAttackIndicator.Enabled=previous_fade,previous_tracking
assert(visibility.should_show('always',false,false,false),
    'User-selected always-visible mode must remain supported')
assert(d.AutoHold==0 and theme.apply(d).cost_align=='right')
local hold={}
local update=visibility.update_hold
assert(not update(hold,true,0,0,true) and not update(hold,false,0,1,true))
assert(not update(hold,false,1.5,2,true),'idle startup must not begin a hold')
assert(not update(hold,true,1.5,3,true))
assert(update(hold,false,1.5,4,true) and update(hold,false,1.5,5.49,true))
assert(not update(hold,false,1.5,5.5,true))
assert(not update(hold,true,30,6,true) and update(hold,false,30,7,true))
assert(not update(hold,true,30,8,true),'repress cancels the previous hold')
assert(update(hold,false,30,9,true) and not update(hold,false,30,10,false))
assert(not update(hold,false,30,11,true),'context exit must not revive an old hold')
print('Beta defaults: native D-pad, oninput, text fade ON, swing tracking OFF, override modes and old fade durations passed.')
