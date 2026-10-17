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
local defaults=require('defaults');assert(defaults.ControllerTargetR2==false and defaults.ControllerTargetR3==false)
local profiles=require('controller_profiles');local original=io.open
io.open=function()return {read=function()return '[Controller]\nprofile=ps5-extended\nstate=ready\npid=1\ntimestamp=100\nl1_ready=1\ntarget_r2=1\ntarget_r3=0\n' end,close=function()end}end
local status=profiles.read_status('mock',100);io.open=original
assert(status.running and status.target_r2=='1' and status.target_r3=='0' and status.l1_ready=='1')
print('F8 commands: independent/default-off settings, persistence, invalid input and digit-bearing status keys passed.')
