local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('function start_controller_wrappers(',1,true))
local b=assert(source:find('local function stop_controller_wrapper()',a,true))
local profiles=require('controller_profiles')
local status,queue,messages
local adapter={matches=profiles.matches,write_launch=function()return true end}
local env=setmetatable({settings={ControllerProfile='ps5-directinput',ControllerDevice=2},controller_modifier='messages',
    controller_profiles=adapter,controller_status=function()return status end,
    controller_runtime={plan=function()return {command='launch',mode='bootstrap'}end},
    io={open=function()return nil end},windower={addon_path='addon/',create_dir=function()end,send_command=function()end},
    coroutine={schedule=function(fn)queue[#queue+1]=fn end},
    chat_format={say=function(tone,text)messages[#messages+1]={tone,text}end}},{__index=_G})
assert(load(source:sub(a,b-1),'startup','t',env))()
local function reset()status=nil;queue={};messages={}end
local function heartbeat(connected)
    return {running=true,profile='ps5-directinput',device='2',modifier='messages',state='ready',connected=connected}
end
reset();assert(env.start_controller_wrappers())
assert(messages[1][2]=='[XIVCrossbar] Starting controller...')
status=heartbeat('1');table.remove(queue,1)()
assert(messages[2][1]==158 and messages[2][2]=='[XIVCrossbar] Controller ready.')
assert(#queue==0)
reset();status=heartbeat('1');assert(env.start_controller_wrappers())
assert(#queue==0 and messages[1][2]=='[XIVCrossbar] Controller already running.')
reset();status=heartbeat('1');status.device=1;assert(not env.start_controller_wrappers())
assert(messages[1][1]==123 and #queue==0)
reset();env.start_controller_wrappers();env.launch_attempt=nil;table.remove(queue,1)()
assert(#messages==1 and #queue==0,'Stopped/unloaded launch cannot announce ready')
reset();env.start_controller_wrappers();status=heartbeat('0')
while #queue>0 do table.remove(queue,1)() end
assert(#messages==2 and messages[2][2]:find('Controller not detected.',1,true))
reset();env.start_controller_wrappers()
while #queue>0 do table.remove(queue,1)() end
assert(#messages==2 and messages[2][1]==123 and messages[2][2]:find('Controller is not ready.',1,true))
print('Controller start, green confirmed readiness, existing reader, mismatch, cancellation and bounded waiting notices passed.')
