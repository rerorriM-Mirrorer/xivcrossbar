local helper=require('libs/controller/review_keyboard').new()
local calls={};local binder={active=true}
function binder:is_keyboard_review()return self.active end
for _,method in ipairs({'dpad_up','dpad_down','dpad_left','dpad_right','submit_selected_option','go_back'})do
 binder[method]=function(self, pressed)
  if method:sub(1,5)=='dpad_' then self.repeat_active=pressed end
  if pressed~=false then calls[#calls+1]=method end
 end
end
for _,key in ipairs({200,208,203,205,28,156,1})do
 local before=#calls;assert(helper:edge(key,true,binder,true))
 assert(helper:edge(key,true,binder,true) and #calls==before+1,'held key repeated action')
 assert(not binder.repeat_active,'keyboard tap left controller repeat armed')
 assert(helper:has_owned_key())
 binder.active=false;assert(helper:edge(key,false,binder,false),'owned release leaked after screen transition')
 assert(not helper:has_owned_key())
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
local states=assert(load("return "..assert(source:match("local states = (%b{})"))))()
local env=setmetatable({action_binder=binder,states=states},{__index=_G})
assert(load(predicate,'actual review predicate','t',env))()
-- 2026-11-16: every selector screen and Credits take the keys too.
function binder:is_in_selector_state() return self.selector_showing == true end
function binder:is_main_menu() return not self.is_hidden and self.state==1 end
binder.is_hidden=false;binder.state=17;assert(binder:is_keyboard_review())
binder.state=15;assert(binder:is_keyboard_review())
binder.capturing_text=true;assert(not binder:is_keyboard_review());binder.capturing_text=false
binder.chooser_active=true;assert(not binder:is_keyboard_review());binder.chooser_active=false
binder.state=1;assert(not binder:is_keyboard_review())
binder.selector_showing=true;assert(binder:is_keyboard_review(),'main menu arrows/Enter')
binder.state=7;binder.selector_showing=false;assert(binder:is_keyboard_review(),'credits'); binder.state=1;binder.selector_showing=true
binder.selector_showing=false;binder.state=17

for _, state in ipairs({10,11,12,13,16,18,19}) do
    binder.state=state
    assert(binder:is_keyboard_review(),'custom workflow page does not claim keys')
end
binder.state=8;binder.custom_action_draft={}
assert(binder:is_keyboard_review())
binder.custom_action_draft=nil
assert(not binder:is_keyboard_review())

-- Execute the real router across review, text entry, and closing a modal.
f=assert(io.open('xivcrossbar.lua'));source=f:read('*a');f:close()
local start=assert(source:find('local function controller_keyboard(dik, pressed, flags, blocked)',1,true))
local stop=assert(source:find("windower.register_event('keyboard', controller_keyboard)",start,true))
local prefix=source:sub(start,stop-1)..'return controller_keyboard'
local sent, closed = {}, 0
chat_open=false
function binder:is_capturing_text() return self.capturing_text end
enter_now=0
local rootenv=setmetatable({
    chat_enter=require('libs/chat_enter_grace').new(function() return enter_now end),
    review_keyboard=require('libs/controller/review_keyboard').new(),
    action_binder=binder,keyboard={enter=28,esc=1},transport={signals={}},
    text_input_guard={update=function() end},restart_pending=false,
    env_chooser={capturing=false,is_showing=function()return false end},
    crossbar_menu_open=function()return not binder.is_hidden end,
    close_addon_menus=function() closed=closed+1;binder.is_hidden=true end,
    handle_controller_key=function(dik,pressed)
        if pressed then sent[#sent+1]=dik;binder.capturing_text=false end
        return false
    end,
    windower={has_focus=function()return true end,send_command=function() end,
        ffxi={get_info=function() return {chat_open=chat_open} end}}
},{__index=_G})
local dispatch=assert(load(prefix,'actual review router','t',rootenv))()
binder.is_hidden=false;binder.chooser_active=false;binder.capturing_text=false;binder.state=13
assert(dispatch(200,true,0,false) and calls[#calls]=='dpad_up')
binder.state=1;assert(dispatch(200,false,0,false))
binder.capturing_text=true
assert(dispatch(156,true,0,false) and sent[#sent]==28 and not binder.capturing_text)
binder.state=17
local count=#calls
assert(dispatch(156,true,0,false) and #calls==count)
assert(dispatch(156,false,0,false))
binder.capturing_text=true
assert(dispatch(1,true,0,false) and sent[#sent]==1 and closed==0)
assert(dispatch(1,false,0,false))
binder.state=1;binder.selector_showing=true
assert(dispatch(200,true,0,false) and calls[#calls]=='dpad_up','arrow keys on the main menu')
dispatch(200,false,0,false)
assert(dispatch(1,true,0,false) and closed==1,'Esc on the main menu still closes the menus')
binder.selector_showing=false
assert(dispatch(1,true,0,false) and dispatch(1,false,0,false) and closed==1)
binder.is_hidden=false;binder.state=17
assert(not dispatch(28,true,0,true),'preblocked Enter must not submit')
dispatch(28,false,0,false)
-- 2026-11-18: with FFXI chat open, Enter never reaches an XIV Crossbar menu,
-- not even a text field; the arrows and Esc still do.
chat_open=true
binder.state=17
count=#calls
assert(not dispatch(28,true,0,false) and #calls==count, 'chat Enter goes to FFXI')
assert(not dispatch(156,true,0,false) and #calls==count, 'chat numpad Enter goes to FFXI')
dispatch(28,false,0,false);dispatch(156,false,0,false)
binder.capturing_text=true
local sent_before=#sent
assert(not dispatch(28,true,0,false) and #sent==sent_before and binder.capturing_text, 'not even into a text field')
dispatch(28,false,0,false);binder.capturing_text=false
binder.state=13
-- 2026-11-22: the arrows belong to chat (history) while it is open.
count=#calls
assert(not dispatch(200,true,0,false) and #calls==count, 'chat arrows go to FFXI')
dispatch(200,false,0,false)
-- A key whose release went to chat leaves no stale hold behind.
chat_open=false
binder.state=13
local rk=rootenv.review_keyboard
rk.held[1]=true -- as if a press reached the router before chat took the release
chat_open=true
dispatch(1,false,0,false)
assert(rk.held[1]==nil, 'release handed to chat clears the hold')
-- 2026-11-22: Esc with chat open closes chat, never the menu.
local closed_before=closed
assert(not dispatch(1,true,0,false) and closed==closed_before and not binder.is_hidden, 'chat Esc goes to FFXI')
dispatch(1,false,0,false)
chat_open=false
binder.state=17
count=#calls
-- 2026-11-21: a short grace after the chat Enter swallows further Enter
-- presses (held key or double press), so they reach neither menu nor game.
enter_now=.1
assert(dispatch(28,true,0,false) and #calls==count, 'Enter inside the grace is swallowed')
assert(not dispatch(28,false,0,false), 'its key-up still goes to the game')
enter_now=.35
assert(dispatch(28,true,0,false) and #calls==count, 'a repeat extends the grace')
dispatch(28,false,0,false)
enter_now=1
assert(dispatch(28,true,0,false), 'Enter works again once chat closes')
dispatch(28,false,0,false)
local guard=require('text_input_guard')
local commands={}
local function send(command) commands[#commands+1]=command end
guard:update(false,send,true)
guard:update(true,send)
guard:release(send)
assert(table.concat(commands,',')=='keyboard_blockinput 1')
guard:update(false,send,false)
assert(table.concat(commands,',')=='keyboard_blockinput 1,keyboard_blockinput 0')
print('Review keys: physical arrows/Enter/Escape, single edge, review-only scope, field ownership and real routing passed.')
