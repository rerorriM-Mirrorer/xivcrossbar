-- Two independent Lua states share the file; only neutral clients adopt it.
local function client()
    return assert(loadfile('libs/controller/menu_buttons.lua'))()
end
local now,raw,locked,failure=0,nil,false,false
local function options()
    return {path='shared',clock=function()return now end,read=function()return raw end,
        lock=function()assert(not locked);locked=true;return function()locked=false end end,
        replace=function(_,text)assert(locked);if failure then return false,'write failed' end;raw=text;return true end}
end
local a,b=client(),client();local sa,sb=a.new(options()),b.new(options())
assert(not sa:poll(true,true) and not a.swapped)
assert(sa:command('on',true));assert(a.swapped and raw=='menu_swap=on\n' and not locked)
assert(not sb:poll(false,true) and not b.swapped and sb.wanted)
assert(sb:poll(true) and b.swapped)
assert(a.hint('binder','playstation')=='ui/binding_icons/plus_playstation.png')
assert(a.hint('chooser','xbox')=='ui/binding_icons/minus_xbox.png')
local ok,msg=sa:command('off',false);assert(ok and msg:find('Pending',1,true) and a.swapped)
assert(sa:poll(true) and not a.swapped)
now=1;assert(sb:poll(true) and not b.swapped)
raw='partial';assert(not sb:poll(true,true) and not b.swapped)
raw=nil;assert(not sb:poll(true,true) and not b.swapped)
failure=true;assert(not sa:command('on',true) and not a.swapped and not locked)
assert(not sa:command('bogus',true))
-- Real predicates change roles, never physical button identity.
local buttons=require('libs/controller/menu_buttons');local pad=require('libs/controller/gamepad')
buttons.swapped=false;assert(pad.is_minus(67) and pad.is_plus(68))
buttons.swapped=true;assert(pad.is_minus(68) and pad.is_plus(67) and not pad.is_minus(67))
-- Actual Exit hint chooses the same physical artwork as the input predicates.
local f=assert(io.open('ui/action_binder.lua'));local source=f:read('*a');f:close()
local hint=assert(source:match('(function action_binder:show_exit_hint%(%)%s.-)\nfunction action_binder:show_control_hints'))
local shown
local binder={base_x=0,base_y=0,height=300,button_layout='playstation',confirm_button='cross',
    show_hint=function(_,label,icon)shown=icon end}
assert(load(hint,'actual Exit hint','t',setmetatable({action_binder=binder},{__index=_G})))()
binder:show_exit_hint();assert(shown==buttons.hint('binder','playstation'))
buttons.swapped=false
local f=assert(io.open('xivcrossbar.lua'));local root=f:read('*a');f:close()
local guard=assert(root:match('(menu_swap_allowed=function%(%).-\nend)\n'))
local state={};local binder={is_hidden=true};local chooser={}
function chooser:is_showing()return self.shown end
local env=setmetatable({gamepad_state=state,action_binder=binder,env_chooser=chooser,gamepad_mapper={}}, {__index=_G})
assert(load(guard,'actual neutral adoption guard','t',env))()
assert(env.menu_swap_allowed())
for _,key in ipairs({'capturing','minus_button','plus_button'}) do
    state[key]=true;assert(not env.menu_swap_allowed());state[key]=false
end
binder.is_hidden=false;assert(not env.menu_swap_allowed());binder.is_hidden=true
chooser.capturing=true;assert(not env.menu_swap_allowed());chooser.capturing=false
chooser.shown=true;assert(not env.menu_swap_allowed());chooser.shown=false
env.gamepad_mapper.is_showing=true;assert(not env.menu_swap_allowed())
print('Shared menu swap: independent clients, deferred adoption, invalid/absent reads, write failure, lock release, physical predicates and actual Exit artwork passed.')
