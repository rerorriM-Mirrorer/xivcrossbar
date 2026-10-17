-- Feed the real root router/bar logic through the real message receiver. Only
-- native game/UI services are doubles; no copy of trigger selection is tested.
local file=assert(io.open('xivcrossbar.lua'));local source=file:read('*a');file:close()
local start=assert(source:find('local function handle_controller_key(',1,true))
local finish=assert(source:find('publish_personal_context = function()',start,true))
local now=10;local tasks={};local commands,actions,menus={},{},{}
local state={left_trigger=false,right_trigger=false,active_bar=0}
local binder={is_hidden=true,chooser_active=false,typing=false}
function binder:is_capturing_text()return self.typing end
function binder:clear_controller_input()end
function binder:trigger_left(down)menus[#menus+1]={'left',down}end
function binder:trigger_right(down)menus[#menus+1]={'right',down}end
function binder:button_x(down)menus[#menus+1]={'circle',down}end
local chooser={capturing=false,shown=false}
function chooser:is_showing()return self.shown end
function chooser:close()self.shown=false end
local env=setmetatable({gamepad=require('gamepad'),keyboard=require('keyboard_mapper'),gamepad_state=state,
    controller_capture_dik=221,transport=require('controller_transport'),settings={GameplayDPad='ijkl'},
    buttonmapping={confirm_button='cross',cancel_button='circle',mainmenu_button='triangle',activewindow_button='square'},
    action_binder=binder,env_chooser=chooser,gamepad_mapper={is_showing=false},xivcrossbar={ready=true},
    theme_options={hotbar_number=6},shift_keys_down={},keys={},shifted_keys={},
    windower={send_command=function(s)commands[#commands+1]=s end},
    coroutine={schedule=function(fn,delay)tasks[#tasks+1]={fn=fn,at=now+delay}end},
    change_active_hotbar=function()end,
    trigger_action=function(slot)actions[#actions+1]={bar=state.active_bar,slot=slot}end,
    finish_set_chooser=function()chooser.shown=false end}, {__index=_G})
function env.close_left_doublepress_window()env.is_left_doublepress_window_open=false;env.left_trigger_lifted_during_doublepress_window=false end
function env.close_right_doublepress_window()env.is_right_doublepress_window_open=false;env.right_trigger_lifted_during_doublepress_window=false end
assert(load(source:sub(start,finish-1),'actual controller routing','t',env))()
local receiver=require('controller_messages').new({session='routing',clock=function()return now end,wallclock=function()return 100 end,
    capture=env.message_capture,event=env.message_button,cancel=env.message_cancel})
local seq=0
local function new_session()
    receiver:reset();receiver:context('new-'..tostring(now),true);seq=0
    env.message_cancel();commands={};actions={};menus={};tasks={}
end
local function send(...)
    local lines={};for _,edge in ipairs({...})do seq=seq+1;lines[#lines+1]=seq..','..edge..'\n'end
    assert(receiver:accept('token='..receiver.token..'\nstamp=100\nbeat='..math.floor(now*1000)..'\n'..table.concat(lines)..'END\n'))
end
local function empty()assert(not state.capturing and not state.left_trigger and not state.right_trigger and state.active_bar==0)end
new_session();send('down,11','down,7','up,7','up,11')
assert(#actions==1 and actions[1].bar==1 and actions[1].slot==7 and #commands==0, 'first bar actions='..#actions..' bar='..tostring(actions[1] and actions[1].bar)..' commands='..table.concat(commands,','));empty()
new_session();send('down,12','down,5','up,5','up,12')
assert(#actions==1 and actions[1].bar==2 and actions[1].slot==6 and #commands==0);empty()
new_session();send('down,12','down,11','down,1','up,1','up,11','up,12')
assert(#actions==1 and actions[1].bar==3 and actions[1].slot==4);empty()
new_session();send('down,11','down,12','down,6','up,6','up,12','up,11')
assert(#actions==1 and actions[1].bar==4 and actions[1].slot==5);empty()
for _,pair in ipairs({{11,5},{12,6}})do
    new_session();send('down,'..pair[1],'up,'..pair[1],'down,'..pair[1],'down,7','up,7','up,'..pair[1])
    assert(#actions==1 and actions[1].bar==pair[2] and actions[1].slot==7);empty()
end
new_session();send('down,7');assert(commands[1]=='setkey escape down' and #actions==0)
send('up,7');assert(commands[2]=='setkey escape up' and #commands==2);empty()
new_session();send('down,7','down,11','up,7','up,11')
assert(#actions==0 and #commands==2 and commands[2]=='setkey escape up','held Circle executed after trigger reveal');empty()
new_session();send('down,11','down,7','up,11','up,7')
assert(#actions==1 and #commands==0,'release leaked Escape');empty()
new_session();binder.is_hidden=false
send('down,11','down,7','up,7','up,11')
assert(#actions==0 and #commands==0 and #menus==4 and menus[1][1]=='left' and menus[2][1]=='circle')
binder.is_hidden=true;empty()
new_session();send('down,11');assert(state.active_bar==1)
local previous=receiver.token;receiver:context('other-client',true);empty()
assert(not receiver:accept('token='..previous..'\nstamp=100\n2,down,7\nEND\n') and #actions==0)
new_session();send('down,5');assert(commands[1]=='setkey enter down')
now=now+.36;assert(receiver:watchdog());assert(commands[2]=='setkey enter up');empty()
-- The installed keyboard listener must not interpret real F-keys as slots
-- while message capture is active.
local events={};env.controller_message_bridge=receiver;receiver:context('keys-test',true);seq=0
env.windower.register_event=function(name,callback)events[name]=callback end
local a=assert(source:find("windower.register_event('keyboard'",finish,true))
local b=assert(source:find('local frame = 0',a,true))
assert(load(source:sub(a,b-1),'actual keyboard listener','t',env))()
send('down,11');local count=#actions
assert(events.keyboard(88,true,0,false)==false and #actions==count and state.left_trigger and not state.right_trigger)
assert(events.keyboard(221,false,0,false)==false and state.left_trigger,'real Apps release cancelled message hold')
receiver:reset();empty()
-- Apps/F-key transport still reaches the exact same router when disabled.
env.publish_personal_context=function()end
commands={};actions={}
events.keyboard(221,true,0,false);events.keyboard(88,true,0,false)
events.keyboard(65,true,0,false);events.keyboard(65,false,0,false)
events.keyboard(88,false,0,false);events.keyboard(221,false,0,false)
assert(#actions==1 and actions[1].bar==2 and actions[1].slot==7 and #commands==0);empty()
-- Exercise the real chooser handler with the real binder helper, not a fake
-- is_cancel_button method that would hide its absence from the installed file.
local f=assert(io.open('action_binder.lua'));local binder_source=f:read('*a');f:close()
local first=assert(binder_source:find('function action_binder:is_cancel_button(',1,true))
local last=assert(binder_source:find('function action_binder:create_text(',first,true))
assert(load(binder_source:sub(first,last-1),'actual cancel helper','t',
    setmetatable({action_binder=binder},{__index=_G})))()
local cancellations=0
env.finish_set_chooser=function(cancel)assert(cancel);cancellations=cancellations+1;chooser.shown=false end
binder.button_layout='playstation';binder.cancel_button='circle'
new_session();chooser.shown=true
send('down,6','up,6');assert(chooser.shown and cancellations==0 and #actions==0 and #commands==0)
send('down,7','up,7');assert(not chooser.shown and cancellations==1 and #actions==0 and #commands==0)
new_session();chooser.shown=true;binder.cancel_button='cross'
send('down,7','up,7');assert(chooser.shown and cancellations==1)
send('down,5','up,5');assert(not chooser.shown and cancellations==2 and #commands==0)
print('Actual Lua routing: all six bars, ordered trigger pairs, batched double taps, once-only slots, native confirm/cancel, held-button ownership, addon menu routing, focus/watchdog cleanup, real keyboard isolation and Options cancellation passed.')
