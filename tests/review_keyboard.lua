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
local f=assert(io.open('action_binder.lua'));local source=f:read('*a');f:close()
local predicate=assert(source:match('(function action_binder:is_keyboard_review%(%).-\nend)'))
local env=setmetatable({action_binder=binder,states={EDIT_CUSTOM_ACTION_REVIEW=17,CONFIRM_CUSTOM_ACTION=15}},{__index=_G})
assert(load(predicate,'actual review predicate','t',env))()
binder.is_hidden=false;binder.state=17;assert(binder:is_keyboard_review())
binder.state=15;assert(binder:is_keyboard_review())
binder.capturing_text=true;assert(not binder:is_keyboard_review());binder.capturing_text=false
binder.chooser_active=true;assert(not binder:is_keyboard_review());binder.chooser_active=false
binder.state=1;assert(not binder:is_keyboard_review());binder.state=17

-- Execute the real public keyboard-router prefix with a stub game environment.
f=assert(io.open('xivcrossbar.lua'));source=f:read('*a');f:close()
local start=assert(source:find('local function controller_keyboard(dik, pressed, flags, blocked, source)',1,true))
local stop=assert(source:find('    -- Only mapped controller input is traced;',start,true))
local prefix=source:sub(start,stop-1):gsub('^local function controller_keyboard','return function',1)
local rootenv=setmetatable({
 review_keyboard=require('libs/controller/review_keyboard').new(),
 action_binder=binder,keyboard={enter=28},
 text_input_guard={enter_down=false},restart_pending=false,
 env_chooser={capturing=false,is_showing=function()return false end},
 windower={has_focus=function()return true end}
},{__index=_G})
local dispatch=assert(load(prefix..'    return false\nend','actual review key prefix','t',rootenv))()
binder.is_hidden=false;binder.chooser_active=false;binder.capturing_text=false;binder.state=17
assert(dispatch(200,true,0,false,'keyboard') and calls[#calls]=='dpad_up')
binder.state=1;assert(dispatch(200,false,0,false,'keyboard'))
assert(not dispatch(28,true,0,false,'keyboard'),'Enter outside review consumed')
dispatch(28,false,0,false,'keyboard')
binder.state=17;rootenv.text_input_guard.enter_down=true
assert(not dispatch(28,true,0,false,'keyboard'),'field-owned Enter stolen')
dispatch(28,false,0,false,'keyboard');rootenv.text_input_guard.enter_down=false
assert(dispatch(28,true,0,false,'keyboard') and calls[#calls]=='submit_selected_option')
binder.capturing_text=true
assert(dispatch(28,false,0,false,'keyboard'),'Enter release escaped into text field')
binder.capturing_text=false
assert(not dispatch(200,true,0,false,'message'),'synthetic DirectLink keyboard event misrouted')
print('Review keys: physical arrows/Enter/Escape, single edge, review-only scope, field ownership and real routing passed.')
