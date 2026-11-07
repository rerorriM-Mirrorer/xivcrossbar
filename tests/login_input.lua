-- Exercise both real callbacks with a synthetic guard and menu state.
local t=require('controller_transport')
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local function extract(first,last,name,env)
    local a=assert(source:find(first,1,true));local b=assert(source:find(last,a,true))
    return assert(load(source:sub(a,b-1)..'\nreturn '..name,name,'t',env))()
end
local routed, released = {}, {}
local context,chat='login',false
local env=setmetatable({keyboard={esc=1,enter=28},review_keyboard={edge=function()return false end},
    env_chooser={is_showing=function()return false end},
    text_input_guard={enter_edge=function()return false end},settings={},gamepad_state={},
    ui={release_slot_pulse=function(_,slot) released[#released+1]=slot end},
    transport=t,gamepad=require('gamepad'),native_mode='guard',native_filtering=true,input_context=function()return context end,
    windower={has_focus=function()return true end,ffxi={get_info=function()return {chat_open=chat}end}},
    handle_controller_key=function(dik,pressed) routed[#routed+1]={dik,pressed} end}, {__index=_G})
local keys=extract('local function controller_keyboard(', "windower.register_event('keyboard', controller_keyboard)", 'controller_keyboard',env)
local message=extract('local function route_controller_message(', 'local message_session=', 'route_controller_message',env)
message(59,true);message(59,false)
context='gameplay'
message(59,true);message(59,false);message(63,true);message(63,false)
assert(#routed==0,'bare gameplay/login must pass natively')
env.native_filtering=false
message(87,true);message(63,true);message(63,false);message(87,false)
assert(#routed==0,'guard must be live before dispatch')
env.native_filtering=true
message(87,true);context='crossbar';message(63,true);message(63,true)
assert(#routed==2 and routed[1][1]==87 and routed[2][1]==63)
assert(keys(63,true)==false,'physical F-key remains independent')
chat=true
message(63,false);message(87,false);message(88,true);message(88,false)
assert(released[#released]==6, 'Cross pulse must release even after entering chat')
assert(#routed==3 and routed[3][1]==87 and routed[3][2]==false,'chat must permit cleanup only')
chat=false;context='setup'
message(65,true);message(65,false)
assert(#routed==5 and routed[4][1]==65 and routed[5][2]==false,'setup still uses messages')
message(64,true);message(65,true)
message(64,false);message(65,false)
assert(released[#released-1]==5 and released[#released]==7,'Circle and Square must clear the slots they trigger')
local outputs, target, menu, status, focus = {}, nil, false, 0, true
env.shoulder_banks = require('shoulder_banks')
env.settings.ShoulderBanks = require('defaults').ShoulderBanks
env.settings.ControllerProfile = 'ps5-directinput'
env.diagnostic = {record=function() end}
env.gamepad_state.shoulder_targeting=true
env.native_gamepad = {tap_tab=function() outputs[#outputs+1]='tab'; return 1 end}
env.windower.send_command = function(command) outputs[#outputs+1]=command end
env.windower.has_focus = function() return focus end
env.windower.ffxi.get_info = function() return {chat_open=chat,menu_open=menu} end
env.windower.ffxi.get_player = function() return {status=status} end
env.windower.ffxi.get_mob_by_target = function() return target end
t:reset()
context='gameplay'
message(90,true);message(90,false)
assert(#outputs==0,'targeting is off by default')
env.settings.ShoulderBanks.Targeting=true
message(90,true);message(90,true);message(90,false)
assert(#outputs==1 and outputs[1]=='input /targetnpc','fresh targetless R1 only')
target={}
message(90,true);message(89,true);message(90,false);message(89,false)
assert(#outputs==2 and outputs[2]=='tab','R1 first sends Tab, L1 later adds no shortcut')
message(90,true,true);message(90,false)
message(89,true);message(90,true);message(90,false);message(89,false)
menu=true
message(90,true);message(90,false)
menu=false; status=4
message(90,true);message(90,false)
status=0; focus=false
message(90,true);message(90,false)
focus=true; context='menu:1'
message(90,true);message(90,false)
context='gameplay';env.settings.ControllerProfile='xinput-r1-chooser'
message(90,true);message(90,false)
env.settings.ControllerProfile='ps5-directinput'
message(87,true);message(90,true);message(90,false);message(87,false)
assert(#outputs==2,'chords, menus, focus loss, RB chooser and triggers suppress targeting')
print('Actual routing callback: R1 acquire/cycle, repeats, release, focus, menus and chord priority passed.')
print('Native login and bare gameplay, guard gate, chord routing, chat release and setup passed.')
