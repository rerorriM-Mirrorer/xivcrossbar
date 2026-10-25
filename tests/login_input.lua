local t=require('controller_transport')
assert(t:login_key(t.signals[59],{})=='up')
assert(t:login_key(t.signals[63],{})=='enter')
assert(t:login_key(t.signals[65],{})=='escape')
assert(t:login_key(t.signals[87],{})==nil)
assert(t:login_key(t.signals[88],{})==nil)
assert(t:login_key(t.signals[68],{})==nil)
t:reset()
local _,edge=t:edge(63,true,'login');assert(edge=='down')
local _,repeat_edge=t:edge(63,true,'login');assert(repeat_edge=='repeat')
local _,release,owner=t:edge(63,false,'gameplay');assert(release=='up' and owner=='login')
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
assert(source:find("if context == 'login' then",1,true))
assert(source:find("if not xivcrossbar.ready then return 'login' end",1,true))
print('Pre-login arrow/confirm/cancel transport, ignored trigger/set signals and edge ownership passed.')

-- Execute the real root keyboard callback, not just the transport helper.
local first=assert(source:find("local function controller_keyboard(dik, pressed, flags, blocked, source)",1,true))
local last=assert(source:find("\nend\nwindower.register_event('keyboard', controller_keyboard)",first,true))
local handler,commands
commands={}
local ready=false
local env=setmetatable({keyboard={esc=1,enter=28},text_input_guard={enter_edge=function()return false end},
    gamepad_mapper={is_showing=false},action_binder={is_hidden=true,is_capturing_text=function()return false end},
    env_chooser={is_showing=function()return false end},settings={GameplayDPad='ijkl'},
    gamepad_state={capturing=true},controller_capture_dik=221,transport=t,gameplay_down={},message_down={},
    buttonmapping={},input_context=function()return ready and 'gameplay' or 'login'end,
    windower={register_event=function(_,fn)handler=fn end,
        send_command=function(c)commands[#commands+1]=c end},
    handle_controller_key=function()error('login signal reached gameplay handler')end}, {__index=_G})
handler=assert(load(source:sub(first,last+3)..'\nreturn controller_keyboard','root keyboard','t',env))()
t:reset()
assert(handler(59,true)==true and commands[#commands]=='setkey up down')
assert(handler(59,true)==true and #commands==1,'repeat emitted a second key-down')
ready=true
assert(handler(59,false)==true and commands[#commands]=='setkey up up', 'transition lost owned release')
ready=false
assert(handler(63,true)==true and commands[#commands]=='setkey enter down')
assert(handler(63,false)==true and commands[#commands]=='setkey enter up')
assert(handler(65,true)==true and commands[#commands]=='setkey escape down')
assert(handler(65,false)==true and commands[#commands]=='setkey escape up')
local count=#commands
for _,dik in ipairs({67,68,87,88}) do handler(dik,true);handler(dik,false) end
assert(#commands==count,'login trigger/menu emitted input')
env.gamepad_state.capturing=false
assert(handler(59,true)==false and #commands==count,'plain physical F-key captured')
-- A DirectLink-held logical DIK must not claim the same *physical* F-key.
t.down[59]='crossbar';env.message_down[59]=true
assert(handler(59,true)==false and #commands==count,'DirectLink hold captured physical keyboard F-key')
env.message_down[59]=nil;t:reset()
print('Root keyboard: login arrows/confirm/cancel, repeat suppression, transition key-up, ignored triggers and physical F-key passthrough passed.')
