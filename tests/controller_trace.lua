local f=assert(io.open('xivcrossbar.lua'));local text=f:read('*a');f:close()
local start=assert(text:find('local function request_controller_trace(mode)',1,true))
local stop=assert(text:find('\ncontroller_switcher =',start,true))
local running,writes,mode=true,0,nil
local write_ok=true
local env=setmetatable({controller_status=function()return {running=running}end,
    windower={addon_path='addon/',add_to_chat=function()end,ffxi={get_player=function()return {name='Test'}end}},
    input_timing={start=function(_,path)assert(path=='addon/data/controller-lua-trace-Test.log')end,stop=function()end},
    _addon={version='test'},
    io={open=function(path,access)
        assert(path=='addon/data/controller-trace.request' and access=='w')
        return {write=function(_,s)writes=writes+1;mode=s;return write_ok end,close=function()return true end}
    end}}, {__index=_G})
local request=assert(load(text:sub(start,stop-1)..'\nreturn request_controller_trace','actual trace command','t',env))()
assert(not request(nil) and not request('bad') and writes==0)
running=false;assert(not request('on') and writes==0)
running=true;assert(request('on') and mode=='on')
assert(request('off') and mode=='off')
write_ok=false;assert(not request('on'))
print('Actual controller trace command: explicit modes, running-wrapper guard and failed-write reporting passed.')
local first=assert(text:find('local function report_controller_status(details,embedded)',1,true))
local last=assert(text:find('function start_controller_wrappers(',first,true))
local lines={}
local status={running=true,profile='ps5-extended',device='1',modifier='apps',state='ready',connected='1',
    button_protocol='1',bank_protocol='1',hold_recovery_protocol='1',r1_menu_protocol='1',button_route='messages',personal_version='9.11-timing1'}
local status_env=setmetatable({settings={ControllerProfile='ps5-extended',ControllerDevice=1,ControllerMessages=true},
    input_timing={active=true},controller_modifier='apps',controller_message_bridge={received=12,rejected=0},companion_banks={active=false},
    controller_status=function()return status end,controller_profiles={matches=function()return true end},
    windower={add_to_chat=function(color,s)assert(color==0);lines[#lines+1]=s end}},{__index=_G})
local report=assert(load(text:sub(first,last-1)..'\nreturn report_controller_status','actual route status','t',status_env))()
report();local concise=table.concat(lines,'\n')
assert(concise:find('active messages | requested messages',1,true) and concise:find('Lua ON',1,true))
assert(not concise:find('received 12',1,true) and #lines<=10)
lines={};report(true);local detail=table.concat(lines,'\n')
assert(detail:find('received 12',1,true) and detail:find('fallback apps',1,true))
status_env.settings.ControllerMessages=false;status.button_route='keys';lines={};report()
assert(table.concat(lines,'\n'):find('active keys | requested keys',1,true))
status_env.settings.ControllerRealKeys=true;lines={};report()
assert(table.concat(lines,'\n'):find('Restart the updated AHK wrapper for real IJKL',1,true))
status.realkeys_protocol='1';status.dpad_output='ahk';lines={};report(true)
assert(table.concat(lines,'\n'):find('output ahk',1,true))
assert(not table.concat(lines,'\n'):find('Restart the updated AHK wrapper for real IJKL',1,true))
print('Actual controller status: compact/detail separation, route truth, Lua trace and compatibility notices passed.')
