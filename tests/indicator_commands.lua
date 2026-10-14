-- Run the actual root helpers with real UI/geometry and narrow API spies.
-- Preferences, active fades, bindings and gameplay commands remain independent.
dofile('tests/compact.lua')
local ui=require('ui')
local settings=require('defaults')
local file=assert(io.open('xivcrossbar.lua'))
local source=file:read('*a');file:close()
local saves,messages=0,{}
windower.ffxi.get_player=function() return {status=1,buffs={}} end
windower.add_to_chat=function(_,message) messages[#messages+1]=message end
windower.send_command=function() error('indicator setting issued a gameplay command') end
local theme_options=require('theme').apply(settings)
local env=setmetatable({ui=ui,settings=settings,theme_options=theme_options,
    windower=windower,config={save=function(value) assert(value==settings);saves=saves+1 end}},
    {__index=_G})
local function helper(name)
    local block=assert(source:match('(local function '..name..'%(mode%).-\nend)\n'))
    return assert(load(block..'\nreturn '..name,name,'t',env))()
end
local textfade,autoattack=helper('set_text_fade'),helper('set_autoattack')
local fade,opacity=ui.geometry.fade,ui.geometry.opacity
local colors,mp,aaopacity=settings.Color,settings.Color.MpCost,settings.AutoAttackIndicator.Opacity
local duration=settings.Animation.LoadFadeIn
textfade('ON');assert(settings.Animation.TextFade and ui.geometry.text_fade)
textfade('status');assert(saves==1)
textfade('invalid');assert(saves==1 and settings.Animation.TextFade)
textfade();assert(not settings.Animation.TextFade)
textfade('off');assert(not settings.Animation.TextFade)
autoattack('off');assert(not ui.autoattack.enabled and not settings.AutoAttackIndicator.Enabled)
autoattack('status');assert(saves==4)
autoattack('invalid');assert(saves==4)
autoattack('ON');assert(ui.autoattack.enabled and ui.autoattack.engaged)
ui.autoattack.estimate=7
autoattack('on');assert(ui.autoattack.estimate==7,'explicit on restarted learning')
autoattack();assert(not ui.autoattack.enabled and ui.autoattack.estimate==nil)
assert(saves==7)
assert(ui.geometry.fade==fade and ui.geometry.opacity==opacity)
assert(settings.Animation.LoadFadeIn==duration)
assert(settings.Color==colors and settings.Color.MpCost==mp)
assert(settings.AutoAttackIndicator.Opacity==aaopacity)
assert(settings.GameplayDPad=='ijkl' and settings.ControllerProfile=='ps5-extended')
assert(source:find("if command == 'autoattack' then return set_autoattack(args[1]) end",1,true))
print('Indicator commands: toggles, explicit states, status, validation, opacity/colors and active-fade preservation passed.')
