local settings={};local saves=0;local messages={}
local function command(source,mode)return require('controller_target').command(settings,source,mode,
    function()saves=saves+1 end,function(s)messages[#messages+1]=s end)end
assert(command()==nil and saves==0 and messages[1]:find('R2=off, R3=off',1,true))
assert(command('r2','on') and settings.ControllerTargetR2 and not settings.ControllerTargetR3)
assert(command('r3','on') and settings.ControllerTargetR3)
assert(command('both','off') and not settings.ControllerTargetR2 and not settings.ControllerTargetR3)
local count=saves
for _,args in ipairs({{'bad','on'},{'r2','toggle'},{'status','on'}})do assert(command(args[1],args[2])==false)end
assert(saves==count)
local defaults=require('defaults');assert(defaults.ControllerTargetR2==false and defaults.ControllerTargetR3==true)
local function short(source,mode)return require('controller_target').shortcut(settings,source,mode,
    function()saves=saves+1 end,function(s)messages[#messages+1]=s end)end
assert(short('r3') and settings.ControllerTargetR3)
assert(short('r3') and not settings.ControllerTargetR3)
assert(short('both') and settings.ControllerTargetR2 and settings.ControllerTargetR3)
assert(short('both') and not settings.ControllerTargetR2 and not settings.ControllerTargetR3)
assert(short('r2','ON') and settings.ControllerTargetR2)
assert(short('both') and settings.ControllerTargetR2 and settings.ControllerTargetR3)
count=saves;assert(short('r2','status')==nil and saves==count)
assert(short('r2','off') and not settings.ControllerTargetR2)
assert(short('r3','on') and settings.ControllerTargetR3)
count=saves;assert(short('r3','garbage')==false and saves==count)
local normalize=require('personal_profile').normalize
local prior={ControllerProfile='ps5-extended',ControllerDevice=1,PersonalProfileMigrated=true,
    ControllerTargetR2=true,ControllerTargetR3=false}
assert(normalize(prior,defaults,require('controller_profiles')))
assert(not prior.ControllerTargetR2 and prior.ControllerTargetR3 and prior.PersonalTargetR3Migrated)
prior.ControllerTargetR2=true;prior.ControllerTargetR3=false
assert(not normalize(prior,defaults,require('controller_profiles')))
assert(prior.ControllerTargetR2 and not prior.ControllerTargetR3,'later explicit choice overwritten')
-- Exercise the installed alias branch, including lease refresh and status no-op.
local file=assert(io.open('xivcrossbar.lua'));local source=file:read('*a');file:close()
local start=assert(source:find("    elseif command == 'x' then",1,true))
local finish=assert(source:find("    elseif command == 'controller' then",start,true))
local refreshes,selected=0
local env=setmetatable({settings=settings,l1_epoch=0,
    config={save=function(value)assert(value==settings);saves=saves+1 end},
    windower={add_to_chat=function()end},publish_personal_context=function()refreshes=refreshes+1 end,
    select_controller_profile=function(name,device)selected={name,device}end},{__index=_G})
local dispatch=assert(load('return function(command, ...) if false then\n'..
    source:sub(start,finish-1)..' end end','actual short command branch','t',env))()
dispatch('x','2');assert(selected[1]=='x' and selected[2]=='2')
dispatch('r2','off');assert(not settings.ControllerTargetR2 and refreshes==1 and env.l1_epoch==1)
dispatch('r2');assert(settings.ControllerTargetR2 and refreshes==2)
dispatch('both','status');assert(refreshes==2,'status invalidated active gesture')
dispatch('both','invalid');assert(refreshes==2)
local profiles=require('controller_profiles');local original=io.open
io.open=function()return {read=function()return '[Controller]\nprofile=ps5-extended\nstate=ready\npid=1\ntimestamp=100\nl1_ready=1\ntarget_r2=1\ntarget_r3=0\n' end,close=function()end}end
local status=profiles.read_status('mock',100);io.open=original
assert(status.running and status.target_r2=='1' and status.target_r3=='0' and status.l1_ready=='1')
print('F8 commands: R3-only adoption once, persistent later choices, short toggles/status, validation and digit-bearing status keys passed.')
