-- Exercises the actual Beta 1 message parser; no Windower or AHK runtime.
local messages=require('controller_messages')
local now,wall=10,1780000000
local edges,captures,cancels={},{},0
local m=messages.new({session='beta1-test',clock=function()return now end,wallclock=function()return wall end,
    event=function(dik,pressed) edges[#edges+1]={dik,pressed} end,
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
assert(messages.diks[63]==nil,'message parser must handle only 12 ordinary signals')
print('Beta1 ordered trigger/face edges, capture, ack, no duplicate, cancellation, stale/gap/watchdog passed.')

-- Source integration guards: no companion bank or personal profile is required.
local function read(path) local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local root=read('xivcrossbar.lua')
local ahk=read('ffxi_directinput.ahk')
local receiver=read('controller_messages.ahk')
local profiles=read('controller_profiles.lua')
assert(root:find("settings.ControllerProfile~='ps5-directinput'",1,true))
assert(root:find("source=='message'",1,true))
assert(root:find("windower.register_event('keyboard', controller_keyboard)",1,true))
assert(root:find("local captured=gamepad_state.capturing",1,true))
assert(ahk:find('SetBatchLines, -1',1,true))
assert(ahk:find('ControllerMessagePoll(states, active)',1,true))
assert(receiver:find('if (profile != "ps5-directinput")',1,true))
assert(not receiver:find('bank_protocol',1,true))
assert(not root:find("require('libs/banks",1,true))
assert(not profiles:find('ps5-extended',1,true))
for _,p in ipairs({'f710-directinput','fightpadpro-directinput','xinput-r1-chooser'}) do
    assert(profiles:find(p,1,true),'legacy profile missing: '..p)
end
assert(ahk:find('captureKey := (modifierArgument = "ctrl") ? "LControl" : "AppsKey"',1,true))
print('Beta1 profile isolation, physical F-key passthrough and legacy Apps transport source checks passed.')
