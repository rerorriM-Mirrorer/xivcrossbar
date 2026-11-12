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
    action_binder={is_capturing_text=function()return false end},settings={},gamepad_state={},
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
assert(#outputs==1 and outputs[1]=='tab','fresh targetless R1 cycles only')
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
local fired = {}
env.trigger_action=function(slot,bank) fired[#fired+1]={slot,bank} end
env.settings.ShoulderBanks.L1.Enabled=true
env.gamepad_state.shoulder_slots=true
message(89,true)
message(59,true);message(59,true)
message(89,false);message(59,false)
assert(#fired==1 and fired[1][1]==4 and fired[1][2]==7,'L1 + Up dispatches once')
message(59,true);message(89,true);message(59,true)
assert(#fired==1,'holding a native direction before L1 must not dispatch it')
message(59,false);message(89,false)
menu=true; status=1
message(89,true);message(59,true);message(59,false);message(89,false)
assert(#fired==2 and fired[2][2]==7,'battle palette must allow an enabled shoulder slot')
env.gamepad_state.shoulder_slots=false
message(89,true);message(59,true);message(59,false);message(89,false)
assert(#fired==2,'dispatch must respect the native capture gate')
status=4
env.gamepad_state.shoulder_slots=true
env.settings.ShoulderBanks.Both.Enabled=true
message(89,true);message(90,true,true);message(59,true)
message(59,false);message(90,false);message(89,false)
assert(#fired==3 and fired[3][2]==9,'Event capture dispatches the combined shoulder bank')
-- Revision 3 acts on press and reads target presence at that edge.
outputs, target, menu, status = {}, nil, false, 0
env.gamepad_state.shoulder_target_gestures=true
env.native_gamepad.tap_tab=function(reverse)
    outputs[#outputs+1]=reverse==1 and 'shift-tab' or 'tab'
    return 1
end
t:reset()
message(89,true);message(89,false)
message(90,true);message(90,false)
assert(#outputs==2 and outputs[1]=='shift-tab' and outputs[2]=='tab','single shoulders cycle without a target')
outputs={}
for _, pair in ipairs({{89,90},{90,89}}) do
    for _, simultaneous in ipairs({true,false}) do
        message(pair[1],true,simultaneous)
        assert(#outputs==(simultaneous and 0 or 1),'only a staggered first shoulder may cycle')
        message(pair[2],true,simultaneous);message(pair[2],true,simultaneous)
        assert(#outputs==(simultaneous and 0 or 1),'combined shoulders never acquire TargetNPC')
        message(pair[1],false);message(pair[2],false)
        assert(#outputs==(simultaneous and 0 or 1),'release cannot target')
        outputs={}
    end
end
target={}
message(89,true);message(89,true)
assert(#outputs==1 and outputs[1]=='shift-tab','L1 cycles once on press')
message(89,false);message(90,true)
assert(#outputs==2 and outputs[2]=='tab','R1 cycles on press')
message(90,false)
message(89,true,true);message(90,true,true)
message(59,true);message(59,false);message(90,false);message(89,false)
assert(#fired==4 and fired[#fired][2]==9,'combined bank slot still dispatches')
message(87,true);message(90,true);message(90,false);message(87,false)
menu=true;message(90,true);message(90,false);menu=false
focus=false;message(89,true);message(89,false);focus=true
message(59,true);message(89,true);message(89,false);message(59,false)
assert(#outputs==2,'selected-target chord, triggers, menu, focus and held slots suppress targeting')
message(90,true);message(89,true);message(89,false);message(90,false)
assert(#outputs==3 and outputs[3]=='tab','staggered selected-target presses cycle only on the first press')
print('Revision 3 routing: press-only targeting, both chord orders, targetless cycling and context priority passed.')
print('Actual routing callback: R1 cycle, repeats, release, focus, menus and chord priority passed.')
print('Native login and bare gameplay, guard gate, chord routing, chat release and setup passed.')
