-- Execute the actual root menu guard through the real acknowledged receiver.
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('local function input_context()',1,true))
local b=assert(source:find('-- A: both transports',a,true))
local c=assert(source:find('message_menu = function(button)',b,true))
local d=assert(source:find('message_cancel = function()',c,true))
local commands={};local info={logged_in=true,menu_open=false};local character={status=0};local focused=true
local binder={is_hidden=true,is_capturing_text=function()return false end}
local chooser={capturing=false,is_showing=function()return false end}
local env=setmetatable({settings={ControllerProfile='ps5-extended',ControllerMessages=true,InputTest=false},
    restart_pending=false,xivcrossbar={ready=true},gamepad_mapper={is_showing=false},
    action_binder=binder,env_chooser=chooser,gamepad_state={},windower={
        has_focus=function()return focused end,send_command=function(s)commands[#commands+1]=s end,
        ffxi={get_info=function()return info end,get_player=function()return character end}}},{__index=_G})
assert(load(source:sub(a,b-1)..source:sub(c,d-1),'actual direct R1 command guard','t',env))()
local receiver=require('libs/controller/messages').new({session='r1-menus',clock=function()return 10 end,
    wallclock=function()return 100 end,capture=function()error('menu request captured ordinary buttons')end,
    event=function()error('menu request injected a logical key')end,cancel=function()end,menu=env.message_menu})
receiver:context('Fenrir:Test',true);local token=receiver.token
local function packet(body,tok)return'token='..(tok or token)..'\nstamp=100\nbeat=10\n'..body..'END\n'end
assert(receiver:accept(packet('1,rmenu,8\n2,rmenu,6\n')))
assert(commands[1]=='trust menu open' and commands[2]=='trust menu close')
assert(not receiver:accept(packet('1,rmenu,8\n2,rmenu,6\n')) and #commands==2,'command replayed')
assert(receiver:accept(packet('3,rmenu,8\n4,cancel,0\n')) and #commands==2,'cancel failed to preempt queued open')
assert(not receiver:accept(packet('5,rmenu,1\n')) and receiver.ack==4)
assert(not receiver:accept(packet('5,rmenu,6\n','old')) and #commands==2)
local function blocked(set,undo)
    local n=#commands;set();assert(not env.message_menu(8) and not env.message_menu(6));undo();assert(#commands==n)
end
blocked(function()env.restart_pending=true end,function()env.restart_pending=false end)
blocked(function()env.xivcrossbar.ready=false end,function()env.xivcrossbar.ready=true end)
blocked(function()env.settings.ControllerProfile='xinput' end,function()env.settings.ControllerProfile='ps5-extended' end)
blocked(function()env.settings.ControllerMessages=false end,function()env.settings.ControllerMessages=true end)
blocked(function()env.settings.InputTest=true end,function()env.settings.InputTest=false end)
blocked(function()focused=false end,function()focused=true end)
blocked(function()info.logged_in=false end,function()info.logged_in=true end)
blocked(function()info.chat_open=true end,function()info.chat_open=false end)
blocked(function()character.status=4 end,function()character.status=0 end)
blocked(function()env.gamepad_state.left_trigger=true end,function()env.gamepad_state.left_trigger=false end)
blocked(function()env.gamepad_state.right_trigger=true end,function()env.gamepad_state.right_trigger=false end)
blocked(function()env.gamepad_mapper.is_showing=true end,function()env.gamepad_mapper.is_showing=false end)
blocked(function()binder.is_hidden=false end,function()binder.is_hidden=true end)
blocked(function()chooser.capturing=true end,function()chooser.capturing=false end)
info.menu_open=true;assert(env.message_menu(6) and env.message_menu(8),'native menu blocked Trust command')
assert(not env.message_menu(5),'arbitrary command/button accepted')
env.settings.ControllerProfile='xinput-extended'
assert(env.message_menu(8) and env.message_menu(6),'Xbox Extended menu route rejected')
print('Actual R1 Lua/receiver: direct open/close, ack dedup, cancel preemption, atomic validation, native menu allowance and chat/editor/trigger/focus/login/cutscene guards passed.')
