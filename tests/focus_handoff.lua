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
-- Execute the production callback and verify fresh destination modifier presses.
local f=assert(io.open('xivcrossbar.lua'));local s=f:read('*a');f:close()
local a=assert(s:find('    adopt=function(mask,bank)',1,true))
local b=assert(s:find('    event=route_controller_message,',a,true))
local pressed,closed={},0
local transport={reset=function()end}
local env=setmetatable({windower={has_focus=function()return true end,ffxi={get_info=function()return {}end}},
    xivcrossbar={ready=true},crossbar_menu_open=function()return false end,
    gamepad_state={},transport=transport,
    close_left_doublepress_window=function()closed=closed+1 end,
    close_right_doublepress_window=function()closed=closed+1 end,
    route_controller_message=function(dik,down,chord,seq,handoff)
        assert(down and handoff and not chord);pressed[#pressed+1]=dik
    end},{__index=_G})
local callback=assert(load('return {'..s:sub(a,b-1)..'}','fresh handoff','t',env))().adopt
assert(callback(1,5) and pressed[1]==87,'held L2 gets a fresh trigger press, not a restored double bank')
pressed={};assert(callback(2,6) and pressed[1]==88)
pressed={};assert(callback(3,4) and pressed[1]==88 and pressed[2]==87,'combined trigger order retained')
pressed={};assert(callback(12,0) and pressed[1]==89 and pressed[2]==90)
assert(closed==8)
print('Focus handoff: consume held actions, fresh destination modifier presses, combo order and duplicate rejection passed.')
