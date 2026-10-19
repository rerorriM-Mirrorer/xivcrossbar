local module=require('libs/controller/messages')
local now,wall=10,100
local events,captures,cancels={}, {},0
local t=module.new({session='test',clock=function()return now end,wallclock=function()return wall end,
    capture=function(value)captures[#captures+1]=value end,
    event=function(dik,down)events[#events+1]={dik,down}end,cancel=function()cancels=cancels+1 end})
t:context('Fenrir:A',true);local token=t.token
local function packet(body,tok,stamp)return 'token='..(tok or token)..'\nstamp='..(stamp or wall)..'\nbeat='..math.floor(now*1000)..'\n'..body..'END\n'end
assert(t:accept(packet('1,down,11\n2,down,12\n3,down,7\n4,up,7\n5,up,12\n6,up,11\n')))
assert(#events==6 and events[1][1]==87 and events[2][1]==88 and events[3][1]==65)
assert(captures[1] and captures[2]==false and not t.captured and t.ack==6)
assert(not t:accept(packet('1,down,11\n2,down,12\n3,down,7\n4,up,7\n5,up,12\n6,up,11\n')) and #events==6)
for _,bad in ipairs({packet('8,down,11\n'),packet('7,down,13\n'),packet('7,nope,0\n'),
    packet('7,down,11\n8,nope,1\n'),packet('7,cancel,1\n'),packet('7,up,1\n','old'),
    packet('7,down,11\n',nil,98),packet('7,down,11\n',nil,103),
    'token='..token..'\nstamp=100\n7,down,11\n'})do
    assert(not t:accept(bad) and t.ack==6 and #events==6,'partial/bad message executed')
end
assert(t:accept(packet('7,down,11\n8,down,7\n9,cancel,0\n')) and #events==6 and cancels==2)
assert(not t.captured and t.ack==9,'queued pre-cancel actions executed')
assert(t:accept(packet('10,down,5\n11,up,5\n'):gsub('\n','\r\n')) and #events==8)
assert(t:accept(packet('12,down,11\n13,down,11\n')) and #events==9,'duplicate physical down repeated')
now=10.3;assert(not t:accept(packet('12,down,11\n13,down,11\n')))
local cached=packet('12,down,11\n13,down,11\n')
now=10.5;assert(not t:accept(cached));assert(not t:watchdog(),'valid duplicate snapshot failed heartbeat')
now=10.66;assert(not t:accept(cached));assert(t:watchdog() and t.token==nil and not t.captured and cancels==3)
t:context('Fenrir:A',true);assert(t.token~=token)
assert(not t:accept(packet('14,down,7\n')),'expired session replayed')
token=t.token;assert(t:accept(packet('1,down,1\n')))
t:context('Fenrir:B',true);assert(cancels==5 and not next(t.held))
local other=t.token;t:context('Fenrir:B',true);assert(t.token==other)
t:context('Fenrir:B',false);assert(t.token==nil and cancels==6)
local settings={ControllerMessages=true};local saves=0
local function command(mode)return module.command(settings,mode,function()saves=saves+1 end,function()end)end
assert(command('off') and not settings.ControllerMessages)
assert(command('off') and not settings.ControllerMessages)
assert(command() and settings.ControllerMessages)
assert(command('ON') and settings.ControllerMessages)
assert(command('status')==false and saves==4 and settings.ControllerMessages)
assert(command('invalid')==false and saves==4)
print('Controller messages: ordered tap batches, atomic validation, duplicate/stale/gap rejection, cancellation preemption, heartbeat watchdog, client isolation and toggle persistence passed.')
