-- Actual Lua launch function under a focused environment, no Run plugin invoked.
local f=assert(io.open('xivcrossbar.lua','r'));local source=f:read('*a');f:close()
local code=assert(source:match('(function start_controller_wrappers%b().-)\nlocal function stop_controller_wrapper'))
local sent,written={},{}
local planned={}
local status=nil
local format={notice=function(s)return s end,legacy=function(_,s)return s end,
    value=function(s)return s end,profile=function(s)return s end}
local env=setmetatable({
    settings={ControllerProfile='ps5-extended',ControllerDevice=2},controller_modifier='apps',
    controller_status=function()return status end,
    controller_runtime={plan=function(_,directory,profile,device,modifier,current)
        planned={directory,profile,device,modifier,current}
        return {command='run "C:/Program Files/AutoHotkey/v2/AutoHotkey64.exe" /ErrorStdOut "C:/Windower/addons/xivcrossbar/ffxi_directinput.ahk" apps ps5-extended 2'}
    end},
    controller_profiles={write_launch=function(path,profile,device,modifier)
        written={path,profile,device,modifier};return true end,
        matches=function()return true end},
    windower={addon_path='addon/',create_dir=function()end,add_to_chat=function()end,
        send_command=function(s)sent[#sent+1]=s end},
    io={open=function()return nil end},require=function(name)assert(name=='libs/chat_status');return format end,
}, {__index=_G})
assert(load(code,'launch','t',env))()
assert(env.start_controller_wrappers())
assert(sent[1]=='run "C:/Program Files/AutoHotkey/v2/AutoHotkey64.exe" /ErrorStdOut "C:/Windower/addons/xivcrossbar/ffxi_directinput.ahk" apps ps5-extended 2')
assert(planned[1]=='addon/' and planned[2]=='ps5-extended' and planned[3]==2 and planned[4]=='apps')
assert(written[1]=='addon/data/controller-launch.ini' and written[2]=='ps5-extended' and written[3]==2 and written[4]=='apps')
status={running=true}
assert(env.start_controller_wrappers() and #sent==1,'existing shared wrapper spawned again')
print('Actual Lua v2 launch: direct executable plan, unchanged selection handoff and existing-wrapper reuse passed; Run plugin execution remains live.')
