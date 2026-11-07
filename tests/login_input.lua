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
print('Native login and bare gameplay, guard gate, chord routing, chat release and setup passed.')
