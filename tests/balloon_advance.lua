-- The production route tells Balloon only on a confirm-button press during
-- an NPC event; it never touches the native press FFXI receives.
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('local function route_controller_message(',1,true))
local b=assert(source:find('local message_session=',a,true))
local transport=require('controller_transport');transport:reset()

-- Real confirm-button mapping from action_binder.
local af=assert(io.open('action_binder.lua'));local binder_source=af:read('*a');af:close()
local ca=assert(binder_source:find('function action_binder:is_confirm_button(',1,true))
local cb=assert(binder_source:find('\nend\n',ca,true))
local binder={button_layout='playstation',confirm_button='cross',is_hidden=true}
assert(load('local action_binder=...\n'..binder_source:sub(ca,cb+4),'confirm','t',_G))(binder)

local context,outputs='gameplay',{}
local status,focus,chat=4,true,false
local settings={InputTest=false,InputTrace=false}
local env=setmetatable({settings=settings,transport=transport,action_binder=binder,
    native_mode='guard',native_filtering=true,native_gamepad={},
    gamepad_state={},gamepad=require('gamepad'),shoulder_banks=require('shoulder_banks'),
    input_context=function()return context end,
    ui={release_slot_pulse=function()end},
    windower={has_focus=function()return focus end,send_command=function(s)outputs[#outputs+1]=s end,
        ffxi={get_info=function()return {chat_open=chat} end,get_player=function()return {status=status} end}},
    handle_controller_key=function()end},{__index=_G})
local route=assert(load(source:sub(a,b-1)..'\nreturn route_controller_message','balloon route','t',env))()
local function press(dik) route(dik,true);route(dik,false) end
local function count() local n=0 for _,s in ipairs(outputs) do if s=='balloon advance' then n=n+1 end end return n end

press(63) assert(count()==1,'Cross in an event notifies Balloon once')
route(63,true);route(63,true);route(63,true);route(63,false)
assert(count()==2,'held Cross repeats do not notify again')
press(65) press(64) press(66) assert(count()==2,'only the confirm button notifies')
status=0 press(63) assert(count()==2,'no notice outside an event') status=4
chat=true press(63) assert(count()==2,'no notice with chat open') chat=false
focus=false press(63) assert(count()==2,'unfocused client stays quiet') focus=true
context='crossbar' press(63) assert(count()==2,'held crossbar trigger owns Cross') context='gameplay'
context='menu:1' press(63) assert(count()==2,'XIV Crossbar menu owns Cross') context='gameplay'
settings.InputTest=true press(63) assert(count()==2,'Input Test sends nothing') settings.InputTest=false
binder.confirm_button='circle' press(63) assert(count()==2,'remapped confirm: Cross no longer notifies')
press(65) assert(count()==3,'remapped confirm: Circle notifies')
binder.button_layout,binder.confirm_button='xbox','a'
press(63) assert(count()==4,'Xbox A (bottom face) notifies')
for _,s in ipairs(outputs) do assert(s=='balloon advance','no other command was sent: '..s) end
print('Balloon advance: event-only confirm notice, repeats, chat, focus, menu/crossbar/InputTest guards and layouts passed.')
