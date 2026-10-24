-- Actual receiver + companion owner: restore controls only, never old actions.
local now,wall=10,100
local allowed=true
local sent,ordinary={},{}
local bank=require('libs/banks/banks').new({settings={},clock=function()return now end,
    context=function()return true,false end,save=function()end,say=function()end,help=function()end,
    execute=function(c)sent[#sent+1]=c end,ordinary=function(b,p)ordinary[#ordinary+1]={b,p}end})
require('tests/fixtures/bank_legacy')(bank)
local receiver=require('libs/controller/messages').new({session='recovery',clock=function()return now end,
    can_recover=function()return allowed end,
    wallclock=function()return wall end,capture=function()end,
    cancel=function()bank:cancel();bank.active=false end,
    physical=function(b,p)bank:edge(b,p)end,resume=function(b)bank:resume(b)end,
    ready=function()bank.active=true end})
local function packet(body,token)
    return 'token='..(token or receiver.token)..'\nstamp=100\nbeat='..math.floor(now*1000)..'\n'..body..'END\n'
end
receiver:context('A',true)
receiver:accept(packet('1,down,14\n2,down,12\n'))
assert(bank.layer=='r1r2');local old=receiver.token
now=now+.4;assert(receiver:watchdog());assert(bank.layer=='')
receiver:context('A',true);assert(receiver.recovering and receiver.last_reason=='heartbeat')
assert(not receiver:accept(packet('3,down,8\n',old)))
assert(receiver:accept(packet('1,cancel,0\n2,banks,0\n3,resume,14\n4,resume,12\n')))
assert(bank.layer=='r1r2' and bank.active and #sent==0 and #bank.output.pending==0)
receiver:accept(packet('5,down,8\n6,up,8\n'));assert(sent[1]=='npcmirror interact')
-- A pending command in the stalled generation is discarded before execution.
local count=#sent
receiver:accept(packet('7,down,8\n8,stall,0\n'))
assert(#sent==count and not receiver.token and receiver.recover_key=='A')
receiver:context('A',true);assert(receiver.recovering)
assert(not receiver:accept(packet('1,resume,8\n')),'slot resume was accepted')
-- Bare R1 restoration is already consumed; its release must not run R.
receiver:accept(packet('1,cancel,0\n2,banks,0\n3,resume,14\n4,up,14\n'))
assert(#bank.output.pending==0 and #sent==count)
receiver:reset('stall');receiver:context('A',true)
receiver:accept(packet('1,cancel,0\n2,banks,0\n3,resume,13\n4,resume,14\n'))
assert(bank.layer=='pair' and #bank.output.pending==0,'recovery emitted pair Tab')
receiver:reset('stall');receiver:context('A',true)
ordinary={};receiver:accept(packet('1,cancel,0\n2,banks,0\n3,resume,12\n4,resume,14\n'))
assert(bank.layer=='' and ordinary[1][1]==12 and ordinary[1][2],'trigger-first ownership changed')
receiver:reset('stall');receiver:context('B',true)
assert(not receiver.recovering)
assert(not receiver:accept(packet('1,resume,14\n')),'cross-client resume accepted')
receiver:reset('stall');receiver:context('B',false);receiver:context('B',true)
assert(not receiver.recovering,'disabled context retained recovery permission')
allowed=false;receiver:reset('stall');receiver:context('B',true)
assert(not receiver.recovering,'chat/editor policy retained recovery permission')
print('Actual Lua hold recovery: same-client token renewal, old-packet rejection, stale-action discard, four-control whitelist, original chord ownership, no Tab/R side effects and hard-context isolation passed.')
