local D=require('libs/controller/diagnostics')
local sample={controller={route='messages',sent=8,ack=8},selected={dpad='ijkl',ahk_ijkl=false}}
sample.loop=sample
local body=D.render(sample)
assert(body:find('controller.ack = 8',1,true) and body:find('controller.route = messages',1,true))
assert(body:find('selected.ahk_ijkl = false',1,true) and body:find('[reference]',1,true))
local writes=0
assert(D.save('snapshot.log',sample,function(path,text)
    writes=writes+1;assert(path=='snapshot.log' and text==body);return true
end))
local ok,err=D.save('snapshot.log',sample,function()return false,'replacement failed'end)
assert(not ok and err=='replacement failed')
ok,err=D.save('snapshot.log',sample,function()error('backend unavailable')end)
assert(not ok and err:find('backend unavailable',1,true))
local render=D.render;D.render=function()error('assembly failed')end
ok,err=D.save('snapshot.log',sample,function()writes=writes+1 end)
assert(not ok and writes==1,'assembly failure reached the replacement boundary')
D.render=render
-- Execute the real root snapshot command with native replacement mocked only.
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('local function diagnostic_snapshot()',1,true))
local b=assert(source:find('local function report_controller_status',a,true))
local lines,snapshots={},{}
local saved=D.save;local success=true
D.save=function(path,snapshot)
    assert(path=='addon/data/diagnostics/status-Test.log');snapshots[#snapshots+1]=snapshot
    return success,success and nil or 'Disk full'
end
local env=setmetatable({_addon={version='test'},player={name='Test',hotbar_settings={active_environment='basic'}},
    settings={ControllerProfile='xinput-extended',ControllerDevice=1,ControllerMessages=true,GameplayDPad='ijkl',ControllerRealKeys=false},
    controller_status=function()return {button_route='messages',button_ack='8',guide_touchpad='available'}end,
    xivcrossbar={ready=true},controller_modifier='apps',input_timing={active=false},
    controller_message_bridge={ack=8,received=8,rejected=0,last_reason='context-change',recovering=false},
    companion_banks={settings=function()return {}end,active=true,layer='',menu=false,output={ack=0,seq=0}},
    storage={identity_valid=true,directory='Fenrir/Test'},bank_storage={source='banks.xml',character='Test'},
    client_registry={loaded=true},action_binder={state=1},gamepad_mapper={},text_input_guard={},l1_bridge={},
    windower={addon_path='addon/',create_dir=function(path)assert(path=='addon/data/diagnostics/')end,
        add_to_chat=function(color,line)assert(color==0);lines[#lines+1]=line end}}, {__index=_G})
local command=assert(load(source:sub(a,b-1)..'\nreturn save_diagnostics','actual diagnostic command','t',env))()
assert(command() and #lines==1 and lines[1]:find('Diagnostics saved:',1,true))
assert(snapshots[1].receiver.received==8 and snapshots[1].selected.legacy_modifier=='apps')
assert(snapshots[1].selected.dpad=='ijkl' and snapshots[1].selected.ahk_ijkl==false)
assert(snapshots[1].controller.guide_touchpad=='available')
assert(not lines[1]:find('context-change',1,true),'diagnostics leaked into chat')
success=false;lines={};assert(not command())
assert(#lines==1 and lines[1]:find('Disk full',1,true),'save failure was silent')
D.save=saved
print('Actual diagnostic command: full snapshots, quiet confirmations, preserved delivery distinctions, assembly/replacement failures and cycle bounds passed.')
