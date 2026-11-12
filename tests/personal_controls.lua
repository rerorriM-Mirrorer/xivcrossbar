local controls=require('libs/personal_controls')
local presets=require('libs/settings_presets')
for _,name in ipairs({'legacy','default'})do assert(not controls.options(presets.values(name)).PSButton)end
local settings=presets.values('me')
assert(controls.options(settings).PSButton and controls.options(settings).MovementArm=='neutral')
local saves=0
controls.command(settings,'movement','client',function()saves=saves+1 end,function()end)
assert(saves==1 and controls.options(settings).MovementArm=='client')
local bars={['all-jobs-default']={},['job-default']={},default={},basic={}}
local entries={{key='all-jobs-default'},{key='job-default'},{key='default'},{key='basic'},{key='add-new-set'}}
assert(controls.cycle(entries,'basic',1,bars)=='all-jobs-default')
assert(controls.cycle(entries,'all-jobs-default',-1,bars)=='basic')
assert(controls.cycle(entries,'default',1,bars)=='basic')
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('local function route_controller_message(',1,true))
local b=assert(source:find('local message_session=',a,true))
local transport=require('controller_transport');transport:reset()
local context,outputs,changes='gameplay',{},{}
local player={hotbar=bars,hotbar_settings={active_environment='default'}}
local env=setmetatable({settings=settings,player=player,transport=transport,
    native_mode='guard',native_filtering=true,native_gamepad={personal_revision=1},
    gamepad_state={},gamepad=require('gamepad'),shoulder_banks=require('shoulder_banks'),
    input_context=function()return context end,
    env_chooser={get_player_environments=function()return entries end},
    set_active_environment=function(key)player.hotbar_settings.active_environment=key;changes[#changes+1]=key end,
    ui={release_slot_pulse=function()end},
    windower={has_focus=function()return true end,send_command=function(s)outputs[#outputs+1]=s end,
        ffxi={get_info=function()return {}end}},
    handle_controller_key=function(dik,pressed)
        if dik==87 or dik==88 then context=pressed and 'crossbar' or 'gameplay' end
    end},{__index=_G})
local route=assert(load(source:sub(a,b-1)..'\nreturn route_controller_message','actual personal route','t',env))()
route(88,true);route(88,true)
assert(#outputs==1 and outputs[1]=='input /targetnpc','R2 targets only on its fresh press')
route(90,true);route(90,true);route(90,false)
assert(#changes==1 and changes[1]=='basic','R2 then R1 cycles forward exactly once')
route(88,false);route(87,true);route(89,true);route(89,false);route(87,false)
assert(#changes==2 and changes[2]=='default','L2 then L1 cycles backward')
settings.ShoulderBanks.PersonalControls.Enabled=false
route(88,true);route(90,true);route(90,false);route(88,false)
assert(#outputs==1 and #changes==2,'master switch disables the personal shortcuts')
print('Personal controls: preset isolation, options, filtered cyclic set list, actual R2 target/cycling route and master OFF passed.')
