local now,adopted,edges=10,{},{}
local m=require('controller_messages').new({session='handoff',clock=function()return now end,
    wallclock=function()return 100 end,capture=function()end,cancel=function()end,
    adopt=function(mask,bank)adopted[#adopted+1]={mask,bank};return true end,
    event=function(dik,down)edges[#edges+1]={dik,down}end})
local function accept(events)
    return m:accept('token='..m.token..'\nstamp=100\nbeat=10\nbuttons=14\n'..events..'END\n')
end
for _,mask in ipairs({1,2,3,4,8,12,15})do
    m:context('client-'..mask,true,true)
    assert(accept('1,cancel,0\n2,resume,'..mask..',5\n3,up,2\n'))
    assert(adopted[#adopted][1]==mask and adopted[#adopted][2]==5)
    assert(#edges==0,'resume and unowned release cannot dispatch an action')
    for bit=0,3 do assert(not not m.held[11+bit]==(math.floor(mask/2^bit)%2==1))end
    assert(not accept('1,cancel,0\n2,resume,'..mask..',5\n3,up,2\n'),'acknowledged resume cannot replay')
    assert(accept('4,down,2\n5,up,2\n'))
    assert(#edges==2 and edges[1][1]==60 and edges[1][2] and not edges[2][2])
    edges={}
end
m:context('invalid',true,true)
assert(not accept('1,resume,16,5\n'))
assert(not accept('1,resume,1,7\n'))
-- Execute the actual adoption callback. It restores state without routing a press.
local f=assert(io.open('xivcrossbar.lua'));local s=f:read('*a');f:close()
local a=assert(s:find('    adopt=function(mask,bank)',1,true))
local b=assert(s:find('    event=route_controller_message,',a,true))
local state,transport={},{down={}}
local closed,selected=0,0
local env=setmetatable({windower={has_focus=function()return true end,ffxi={get_info=function()return {}end}},
    xivcrossbar={ready=true},crossbar_menu_open=function()return false end,
    gamepad_state=state,transport=transport,theme_options={hotbar_number=6},
    close_left_doublepress_window=function()closed=closed+1 end,
    close_right_doublepress_window=function()closed=closed+1 end,
    change_active_hotbar=function(bank)selected=bank end},{__index=_G})
local callback=assert(load('return {'..s:sub(a,b-1)..'}','real adoption','t',env))().adopt
assert(callback(1,5) and selected==5 and state.left_trigger_doublepress)
assert(callback(2,6) and selected==6 and state.right_trigger_doublepress)
assert(callback(3,4) and selected==4 and state.left_trigger and state.right_trigger)
assert(callback(12,0) and state.active_bar==0 and transport.down[89] and transport.down[90])
assert(closed==8,'handoff closes gesture windows without opening a new one')
print('Focus handoff: modifier masks, bank preservation, no action replay, fresh actions, invalid/duplicate packets and real adoption passed.')
