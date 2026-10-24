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
local env=setmetatable({input_timing={record=function()end},gamepad=require('libs/controller/gamepad'),keyboard=require('libs/controller/keyboard_mapper'),gamepad_state=state,
    controller_capture_dik=221,transport=require('libs/controller/transport'),settings={GameplayDPad='ijkl'},
    buttonmapping={confirm_button='cross',cancel_button='circle',mainmenu_button='triangle',activewindow_button='square'},
    action_binder=binder,env_chooser=chooser,gamepad_mapper={is_showing=false},xivcrossbar={ready=true},
    theme_options={hotbar_number=6},shift_keys_down={},keys={},shifted_keys={},
    windower={ffxi={get_info=function()return {} end},send_command=function(s)commands[#commands+1]=s end},
    coroutine={schedule=function(fn,delay)tasks[#tasks+1]={fn=fn,at=now+delay}end},
    change_active_hotbar=function()end,
    trigger_action=function(slot)actions[#actions+1]={bar=state.active_bar,slot=slot}end,
    finish_set_chooser=function()chooser.shown=false end}, {__index=_G})
function env.close_left_doublepress_window()env.is_left_doublepress_window_open=false;env.left_trigger_lifted_during_doublepress_window=false end
function env.close_right_doublepress_window()env.is_right_doublepress_window_open=false;env.right_trigger_lifted_during_doublepress_window=false end
env.l1_epoch=0;env.message_epoch=0
env.l1_bridge={reset=function()end};env.l1_bank={cancel=function()end}
env.l1_drag={finish=function()end};env.r1_drag={finish=function()end}
env.text_input_guard={reset_confirmation=function()end}
env.focus_events={};env.windower.register_event=function(name,fn)env.focus_events[name]=fn end
local focus_start=assert(source:find('local focus_release_keys = {}',1,true))
local focus_end=assert(source:find('local catalog_clock=',focus_start,true))
assert(load(source:sub(start,finish-1)..source:sub(focus_start,focus_end-1)..'\ntrace_snapshot=trace_controller_state','actual controller routing and focus','t',env))()
local receiver=require('libs/controller/messages').new({session='routing',clock=function()return now end,wallclock=function()return 100 end,
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
local f=assert(io.open('ui/action_binder.lua'));local binder_source=f:read('*a');f:close()
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
-- Repeat ordinary six-bar scenarios through the actual new bank owner, using
-- the root's real context guard and router rather than a copied bar selector.
local info={logged_in=true,menu_open=false};local character={status=0}
env.windower.ffxi={get_info=function()return info end,get_player=function()return character end}
env.windower.has_focus=function()return true end
env.settings.ControllerProfile='ps5-extended';env.settings.ControllerMessages=true
binder.cancel_button='circle';chooser.shown=false
local banks=require('libs/banks/banks').new({settings=env.settings,clock=function()return now end,
    context=env.companion_context,execute=env.windower.send_command,save=function()end,say=function()end,help=function()end,
    ordinary=function(button,pressed)env.message_button(require('libs/controller/messages').diks[button],pressed,0,false)end})
require('tests/fixtures/bank_legacy')(banks)
env.companion_banks=banks
receiver=require('libs/controller/messages').new({session='full-bank-routing',clock=function()return now end,wallclock=function()return 100 end,
    capture=env.message_capture,physical=function(b,p)banks:edge(b,p)end,cancel=env.message_cancel,
    ready=function()banks.active=true end,key_ack=function(a)banks.output:accept(a)end})
for _,case in ipairs({{1,{'down,11','down,7','up,7','up,11'}},{2,{'down,12','down,5','up,5','up,12'}},
    {3,{'down,12','down,11','down,1','up,1','up,11','up,12'}},
    {4,{'down,11','down,12','down,6','up,6','up,12','up,11'}},
    {5,{'down,11','up,11','down,11','down,7','up,7','up,11'}},
    {6,{'down,12','up,12','down,12','down,7','up,7','up,12'}}}) do
    new_session();send(table.unpack(case[2]));assert(#actions==1 and actions[1].bar==case[1]);empty()
end
new_session();send('down,13','down,11','down,7','up,7','up,11','up,13')
assert(#actions==0 and #commands==0,'empty L1L2 slot leaked to ordinary crossbar');empty()
new_session();send('down,11','down,13','down,7','up,7','up,11','up,13')
assert(#actions==1 and actions[1].bar==1,'L2-first stopped being ordinary');empty()
new_session();send('down,14','down,8','up,8','down,6','up,6','up,14')
assert(#actions==0 and commands[1]=='trust menu open' and commands[2]=='trust menu close');empty()
new_session();info.menu_open=true
send('down,13','down,1','up,1','down,8','up,8','up,13')
assert(#actions==0 and #commands==1 and commands[1]=='input /wave')
local _,native=banks.output:payload('route');assert(native:find('ctrl+left',1,true))
info.menu_open=false;empty()
new_session();send('down,13','down,7');assert(commands[1]=='input /satchel')
send('up,13','up,7');assert(#commands==1,'companion Circle leaked Escape');empty()
print('Actual bank owner + root router: six bars, both L1/L2 orders, empty-bank isolation, Trust dispatch, native-menu actions and Circle release isolation passed.')

-- Both transports must retain only their own injected keys across cancellation.
env.controller_message_bridge=receiver
for button,key in ipairs({'i','l','k','j','enter'}) do
    new_session();send('down,'..button);assert(commands[#commands]=='setkey '..key..' down')
    env.focus_events['lose focus']();assert(commands[#commands]=='setkey '..key..' up')
    env.focus_events['lose focus']() -- repeated loss must not discard the retry
    commands={};env.focus_events['gain focus']()
    assert(#commands==1 and commands[1]=='setkey '..key..' up','DirectLink lost focus retry for '..key)
    commands={};env.focus_events['gain focus']();assert(#commands==0,'retry was not retired')
end
new_session();receiver:reset()
events.keyboard(221,true,0,false);events.keyboard(59,true,0,false)
assert(commands[#commands]=='setkey i down')
env.focus_events['lose focus']();commands={};env.focus_events['gain focus']()
assert(#commands==1 and commands[1]=='setkey i up','keyboard fallback lost focus retry')
commands={};env.focus_events['gain focus']();assert(#commands==0)
print('Actual focus callbacks: DirectLink and keyboard fallback preserve owned key-ups before cancellation, retry on regain, retain across repeated loss and retire retries once.')

-- A capture begun during a hold needs its initial ownership and route snapshot.
local snapshots={}
env.input_timing.state=function(_,s)snapshots[#snapshots+1]=s end
env.input_timing.active=true
new_session();send('down,1');env.controller_message_bridge=receiver
env.trace_snapshot('gameplay')
assert(snapshots[#snapshots]:find('messages_setting=true',1,true))
assert(snapshots[#snapshots]:find('lua_route=messages',1,true))
assert(snapshots[#snapshots]:find('gameplay_owned=i',1,true))
receiver:reset();env.trace_snapshot('gameplay')
assert(snapshots[#snapshots]:find('lua_route=keys',1,true))
assert(snapshots[#snapshots]:find('gameplay_owned=none',1,true))
env.input_timing.active=false;local count=#snapshots;env.trace_snapshot('gameplay');assert(#snapshots==count)
print('Actual trace snapshot: initial owned key, route permission/selection, cleanup state and inactive silence passed.')

-- Real root context plus real bank/router: only the opted-in scene bank works.
new_session();character.status=4
local allowed,_,cutscene=env.companion_context();assert(allowed and cutscene)
assert(banks:command({'r1','cutscenes','on'}));assert(env.companion_context())
assert(banks:command({'r1','triangle','Scene NPC','npcmirror interact'}))
commands={};actions={}
send('down,14','down,8','up,8','up,14')
assert(#commands==1 and commands[1]=='npcmirror interact' and #actions==0)
send('down,12','down,7','up,7','up,12')
assert(#commands==1 and #actions==0,'ordinary bar leaked during cutscene bank permission')
info.chat_open=true;assert(env.companion_context())
local before_chat=#commands
send('down,14','down,8','up,8','up,14')
assert(#commands==before_chat+1 and commands[#commands]=='npcmirror interact','root chat bank blocked')
assert(#actions==0,'chat bank leaked an ordinary crossbar action')
info.chat_open=false
assert(banks:command({'r1','cutscenes','off'}));assert(env.companion_context())
character.status=0
print('Actual root bank permission: dialogue/chat dispatch, ordinary-bar suppression and legacy setting compatibility passed.')
env.settings.ControllerProfile='xinput-extended'
env.buttonmapping={button_layout='xbox',confirm_button='a',cancel_button='b',mainmenu_button='y',activewindow_button='x'}
for button,key in pairs({[5]='enter',[6]='numpad+',[7]='escape',[8]='numpad-'}) do
    new_session();send('down,'..button,'up,'..button)
    assert(commands[1]=='setkey '..key..' down' and commands[2]=='setkey '..key..' up','Xbox role failed through root receiver')
end
new_session();send('down,11','down,5','up,5','up,11')
assert(#actions==1 and actions[1].bar==1 and #commands==0,'Xbox trigger slot failed')
assert(env.companion_context(),'Xbox companion context disabled')
print('Actual Xbox root receiver: remapped native face roles, release pairs, trigger slot and companion eligibility passed.')
