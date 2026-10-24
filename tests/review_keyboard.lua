local helper=require('libs/controller/review_keyboard').new()
local calls={};local binder={active=true}
function binder:is_keyboard_review()return self.active end
for _,method in ipairs({'dpad_up','dpad_down','dpad_left','dpad_right','submit_selected_option','go_back'})do
 binder[method]=function(self)calls[#calls+1]=method end
end
for _,key in ipairs({200,208,203,205,28,1})do
 local before=#calls;assert(helper:edge(key,true,binder,true))
 assert(helper:edge(key,true,binder,true) and #calls==before+1,'held key repeated action')
 binder.active=false;assert(helper:edge(key,false,binder,false),'owned release leaked after screen transition')
 binder.active=true
end
binder.active=false;assert(not helper:edge(28,true,binder,true))
binder.active=true;local before=#calls
assert(helper:edge(28,true,binder,true) and #calls==before,'preexisting Enter hold activated review')
assert(not helper:edge(28,false,binder,true),'original game key release was swallowed')
assert(not helper:edge(16,true,binder,true),'ordinary typing blocked')
assert(not helper:edge(200,true,binder,false));helper:edge(200,false,binder,false)

-- Actual binder predicate, including both review variants and field exclusion.
local f=assert(io.open('ui/action_binder.lua'));local source=f:read('*a');f:close()
local predicate=assert(source:match('(function action_binder:is_keyboard_review%(%).-\nend)'))
local env=setmetatable({action_binder=binder,states={EDIT_CUSTOM_ACTION_REVIEW=17,CONFIRM_CUSTOM_ACTION=12}},{__index=_G})
assert(load(predicate,'actual review predicate','t',env))()
binder.is_hidden=false;binder.state=17;assert(binder:is_keyboard_review())
binder.state=12;assert(binder:is_keyboard_review())
binder.capturing_text=true;assert(not binder:is_keyboard_review());binder.capturing_text=false
binder.chooser_active=true;assert(not binder:is_keyboard_review());binder.chooser_active=false
binder.state=1;assert(not binder:is_keyboard_review());binder.state=17

-- Actual root prefix must consume review Escape before generic close-all.
f=assert(io.open('xivcrossbar.lua'));source=f:read('*a');f:close()
local a=assert(source:find("windower.register_event('keyboard', function(dik, pressed, flags, blocked)",1,true))
a=assert(source:find('\n',a,true))+1
local b=assert(source:find('    if dik == keyboard.esc then',a,true))
local rootenv=setmetatable({review_keyboard=require('libs/controller/review_keyboard').new(),
 action_binder=binder,keyboard={enter=28},text_input_guard={},
 env_chooser={is_showing=function()return false end},windower={has_focus=function()return true end},
 publish_personal_context=function()end},{__index=_G})
local dispatch=assert(load('return function(dik,pressed,flags,blocked)\n'..source:sub(a,b-1)..'return false end','actual review keyboard dispatch','t',rootenv))()
assert(dispatch(1,true,0,false) and calls[#calls]=='go_back')
binder.state=1;assert(dispatch(1,false,0,false))
assert(not dispatch(28,true,0,false),'Enter outside review consumed')
dispatch(28,false,0,false);binder.state=17;rootenv.text_input_guard.enter_down=true
assert(not dispatch(28,true,0,false),'field-owned Enter stolen on review return')
dispatch(28,false,0,false);rootenv.text_input_guard.enter_down=false
assert(dispatch(28,true,0,false));binder.capturing_text=true
assert(dispatch(28,false,0,false),'Enter release escaped into newly opened text field')
print('Review keyboard: six keys, single presses, ownership through transitions, preheld/field Enter, real binder scope, ordinary typing and root Escape precedence passed.')
