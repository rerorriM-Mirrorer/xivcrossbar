local events={};local cancelled=0;local wall=100
local t=require('libs/banks/legacy_transport').new({session='test-1',wallclock=function()return wall end,
    event=function(kind,slot)events[#events+1]={kind,slot}end,cancel=function()cancelled=cancelled+1 end})
t:context('foreground-keyboard',true);local token=t.token
local function packet(body,stamp,tok)return 'token='..(tok or token)..'\nstamp='..(stamp or wall)..'\n'..body..'END\n' end
assert(t:accept(packet('1,show,0\n2,slot,4\n3,release,0\n')) and #events==3 and t.ack==3)
assert(not t:accept(packet('1,show,0\n2,slot,4\n3,release,0\n')) and #events==3,'duplicate snapshot replayed')
for _,raw in ipairs({packet('4,slot,9\n'),packet('5,slot,1\n'),packet('4,nope,0\n'),
    packet('4,show,1\n'),packet('4,slot,1\n',98),packet('4,slot,1\n',103),
    packet('4,slot,1\n',100,'old-token'),'token='..token..'\nstamp=100\n4,slot,1\n'}) do
    assert(not t:accept(raw));assert(#events==3 and t.ack==3)
end
assert(not t:accept(packet('4,tap,0\n')),'retired toggle accepted')
assert(t:accept(packet('4,bank,0\n5,slot,2\n')));assert(t.ack==5 and #events==5)
t:context('foreground-bank',true);assert(t.token~=token and t.ack==0)
assert(not t:accept(packet('1,show,0\n')),'old-mode event accepted')
token=t.token
assert(t:accept(packet('1,show,0\n2,slot,1\n')) and t.ack==2)
assert(t:accept(packet('3,release,0\n'):gsub('\n','\r\n')) and t.ack==3)
t:context('menu',false);assert(t.token==nil and not t:accept(packet('3,slot,1\n')))
t:context('foreground-bank',true);assert(t.token~=token and t.ack==0)
assert(cancelled>=4)
print('L1 mailbox: ordered layer/slot batches, retired toggle, duplicate/partial/stale rejection and context invalidation passed.')
