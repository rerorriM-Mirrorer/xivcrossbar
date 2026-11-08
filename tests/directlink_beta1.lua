-- Exercises the actual Beta 1 message parser; no Windower or AHK runtime.
local messages=require('controller_messages')
local now,wall=10,1780000000
local edges,captures,cancels,routed={},{},0,{}
local m=messages.new({session='beta1-test',clock=function()return now end,wallclock=function()return wall end,
    event=function(dik,pressed,_,seq) edges[#edges+1]={dik,pressed,seq};return 'fixture-claim','crossbar',1,4 end,
    routed=function(...) routed[#routed+1]={...} end,
    capture=function(pressed) captures[#captures+1]=pressed end,
    cancel=function() cancels=cancels+1 end})
m:context('focused-client',true)
assert(m.token and m.token:find('beta1-test',1,true))
local function snap(token,beat,events,stamp)
    return 'token='..token..'\nstamp='..(stamp or wall)..'\nbeat='..beat..'\n'..events..'END\n'
end
local token=m.token
assert(m:accept(snap(token,10,'1,cancel,0\n2,down,11\n3,down,5\n4,up,5\n5,up,11\n')))
assert(m.ack==5 and #edges==4)
assert(edges[1][3]==2 and routed[1][1]==2 and routed[1][4]=='fixture-claim' and routed[1][7]==4)
assert(edges[1][1]==87 and edges[1][2]==true)
assert(edges[2][1]==63 and edges[2][2]==true)
assert(edges[3][1]==63 and edges[3][2]==false)
assert(edges[4][1]==87 and edges[4][2]==false)
assert(#captures==2 and captures[1]==true and captures[2]==false)
assert(not m:accept(snap(token,11,'1,cancel,0\n2,down,11\n3,down,5\n4,up,5\n5,up,11\n')))
assert(#edges==4,'acknowledged events must not replay')
assert(not m:accept(snap('wrong',12,'6,down,5\n')))
assert(not m:accept(snap(token,13,'7,down,5\n')))
assert(m.ack==5)
assert(not m:accept(snap(token,14,'6,down,5\n',wall-8)))
assert(m:accept(snap(token,15,'6,down,5\n7,cancel,0\n')))
assert(#edges==4,'a later cancel must suppress earlier actions in the same snapshot')
assert(m.ack==7 and cancels>=2)
assert(m:accept(snap(token,16,'8,down,12\n')))
assert(edges[#edges][1]==88 and edges[#edges][2]==true)
now=11
assert(m:watchdog()==true and m.token==nil,'expired held control must cancel')
m:context('focused-client',true)
assert(m.token and m.token~=token,'watchdog must create a fresh message token')
m:reset('focus')
assert(m.token==nil and m.ack==0)
m:context('base-profile',true)
assert(not m:accept(snap(m.token,17,'1,down,13\n')),'ordinary lease rejects shoulder edges')
local shoulder_edges={}
local extended=messages.new({session='shoulders',clock=function()return now end,wallclock=function()return wall end,
    capture=function()end,cancel=function()end,
    event=function(dik,pressed,chord) shoulder_edges[#shoulder_edges+1]={dik,pressed,chord} end})
extended:context('focused-client',true,true)
assert(not extended:accept(snap(extended.token,18,'1,down,13\n')),
    'extended lease needs a matching reader header')
assert(extended:accept(snap(extended.token,18,'buttons=14\n1,down,13,1\n2,down,14,1\n3,up,13\n4,up,14\n')))
assert(extended.extended and shoulder_edges[1][3] and shoulder_edges[2][3], 'same-sample chord survives the spool')
assert(#shoulder_edges==4 and shoulder_edges[1][1]==89 and shoulder_edges[2][1]==90
    and shoulder_edges[3][2]==false and shoulder_edges[4][2]==false)
assert(not extended:accept(snap(extended.token,19,'buttons=14\n5,down,15\n')),'unknown inputs must be rejected')
print('Beta1 ordered trigger/face edges, capture, ack, no duplicate, cancellation, stale/gap/watchdog passed.')

-- Source integration guards: no companion bank or personal profile is required.
local function read(path) local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local root=read('xivcrossbar.lua')
local ahk=read('ffxi_directinput.ahk')
local receiver=read('controller_messages.ahk')
local profiles=read('controller_profiles.lua')
assert(root:find("event=route_controller_message",1,true))
assert(root:find("windower.register_event('keyboard', controller_keyboard)",1,true))
assert(ahk:find('#Requires AutoHotkey v2.0.19+',1,true))
assert(ahk:find('ControllerMessagePoll(states, active)',1,true))
assert(receiver:find('WinGetPID',1,true))
assert(receiver:find('number[1] + 0 != device',1,true))
assert(not ahk:find('SendEvent',1,true) and not ahk:find('ControlSend',1,true))
assert(not root:find('inputconsume',1,true) and not root:find('setkey',1,true))
assert(not receiver:find('bank_protocol',1,true))
assert(not root:find("require('libs/banks",1,true))
for _,p in ipairs({'ps5-directinput','f710-directinput','fightpadpro-directinput','xinput','xinput-r1-chooser'}) do
    assert(profiles:find(p,1,true),'profile missing: '..p)
end
print('All-profile DirectLink, process-scoped leases and keyboard isolation passed.')
