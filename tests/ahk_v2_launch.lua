-- Actual Lua launch function under a focused environment, no Run plugin invoked.
local f=assert(io.open('xivcrossbar.lua','r'));local source=f:read('*a');f:close()
local code=assert(source:match('(function start_controller_wrappers%b().-)\nlocal function stop_controller_wrapper'))
local sent,written={},{}
local planned={}
local scheduled={}
local status=nil
local format={notice=function(s)return s end,legacy=function(_,s)return s end,
    value=function(s)return s end,profile=function(s)return s end}
local env=setmetatable({
    settings={ControllerProfile='ps5-extended',ControllerDevice=2},controller_modifier='apps',
    controller_status=function()return status end,
    controller_runtime={plan=function(_,directory,profile,device,modifier,current)
        planned={directory,profile,device,modifier,current}
        return {mode='direct',source='cache',fallback_command='run addons/xivcrossbar/launch-controller.cmd apps ps5-extended 2',command='run "C:/Program Files/AutoHotkey/v2/AutoHotkey64.exe" /ErrorStdOut "C:/Windower/addons/xivcrossbar/ffxi_directinput.ahk" apps ps5-extended 2'}
    end},
    controller_profiles={write_launch=function(path,profile,device,modifier)
        written={path,profile,device,modifier};return true end,
        matches=function()return true end},
    windower={addon_path='addon/',create_dir=function()end,add_to_chat=function()end,
        send_command=function(s)sent[#sent+1]=s end},
    coroutine={schedule=function(fn,delay)assert(delay==1);scheduled[#scheduled+1]=fn end},
    io={open=function()return nil end},require=function(name)assert(name=='libs/chat_status');return format end,
}, {__index=_G})
assert(load(code,'launch','t',env))()
assert(env.start_controller_wrappers())
assert(sent[1]=='run "C:/Program Files/AutoHotkey/v2/AutoHotkey64.exe" /ErrorStdOut "C:/Windower/addons/xivcrossbar/ffxi_directinput.ahk" apps ps5-extended 2')
assert(planned[1]=='addon/' and planned[2]=='ps5-extended' and planned[3]==2 and planned[4]=='apps')
assert(env.last_controller_launch.command==sent[1] and env.last_controller_launch.requested>0)
assert(written[1]=='addon/data/controller-launch.ini' and written[2]=='ps5-extended' and written[3]==2 and written[4]=='apps')
status={running=true}
assert(env.start_controller_wrappers() and #sent==1,'existing shared wrapper spawned again')
print('Actual Lua v2 launch: direct executable plan, unchanged selection handoff and existing-wrapper reuse passed; Run plugin execution remains live.')

-- Execute the actual root's one-shot confirmation/recovery callback.
assert(#scheduled==1)
scheduled[1]()
assert(#sent==1 and env.last_controller_launch.confirmed,'running wrapper was retried')
status=nil
assert(env.start_controller_wrappers());local first=scheduled[#scheduled]
assert(env.start_controller_wrappers());local second=scheduled[#scheduled]
local before=#sent;first();assert(#sent==before,'superseded startup retried')
second();assert(#sent==before+1 and sent[#sent]=='run addons/xivcrossbar/launch-controller.cmd apps ps5-extended 2')
assert(env.last_controller_launch.fallback)
before=#sent;second();assert(#sent==before,'fallback repeated')
-- Cancellation must prevent a deferred bootstrap from reviving controls.
assert(env.start_controller_wrappers());local cancelled=scheduled[#scheduled]
local stopcode=assert(source:match('(local function stop_controller_wrapper%b().-)\nlocal diagnostic_capture'))
local wrote_stop=false
local stop=assert(load(stopcode..'\nreturn stop_controller_wrapper','stop','t',env))()
env.io.open=function(path,mode)
    if mode=='w' then
        assert(path=='addon/data/input-stop.request');wrote_stop=true
        return {write=function()end,close=function()end}
    end
end
assert(stop());assert(wrote_stop)
before=#sent;cancelled();assert(#sent==before,'cancelled startup retried')
print('Actual Lua direct-start confirmation: live success, one fallback, superseded request and cancellation passed.')
