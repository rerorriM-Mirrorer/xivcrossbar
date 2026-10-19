-- Actual bank/schema/output modules. OS delivery is exercised separately by
-- the actual AHK function harness; no FFXI success is inferred from a dispatch.
local Banks=require('libs/banks/banks')
local now,menu,allowed=10,false,true
local settings={L1={Slot1={Alias='Old Wardrobe',Command='input /wardrobe4'},X=37,Y=81,Scale=.8}}
local saved,commands,ordinary=0,{},{}
local bank=Banks.new({settings=settings,clock=function()return now end,
    context=function()return allowed,menu end,save=function()saved=saved+1 end,
    execute=function(c)commands[#commands+1]=c end,
    ordinary=function(b,p)ordinary[#ordinary+1]={b,p} end,say=function()end,help=function()end})
local function edge(b,p) bank:edge(b,p) end
local function press(b)edge(b,true)end
local function release(b)edge(b,false)end
local function tap(b)press(b);release(b)end
local function reset()
    bank:cancel();menu=false;allowed=true;bank:refresh();commands={};ordinary={}
end
assert(bank.migrated and settings.CompanionBanks.Version==2)
assert(bank:entry('l1l2',1,false).Command=='input /wardrobe4')
assert(settings.L1.Slot1.Command=='input /wardrobe4' and settings.CompanionBanks.LeftPanel.X==37)
assert(bank:entry('l1',4,false).Key=='ctrl+i' and bank:entry('l1',3,false).Key=='ctrl+e')
assert(bank:entry('l1',2,false).Command=='input /wardrobe2')
assert(bank:entry('l1',7,true).Command=='input /yes','Nod uses the native yes emote')
for i=1,8 do assert(bank:entry('r1r2',i,false).Command==Banks.factory('r1r2',i,false).Command and bank:entry('l1l2',i,true).Command=='') end
assert(bank:command({'l1l2','clear','left'}));Banks.ensure(settings)
assert(bank:entry('l1l2',1,false).Command=='' and settings.L1.Slot1.Command=='input /wardrobe4','migration reseeded a cleared slot')
assert(bank:legacy({'1','Legacy alias','input /echo compatible'}))
assert(bank:entry('l1l2',1,false).Command=='input /echo compatible')
assert(bank:command({'r1r2','triangle','Inspect','input /check'}))
assert(bank:command({'l1','menu','key','up','Previous list','ctrl+left'}))
local count=saved
bank:command({'l1','preview'});assert(bank:previewing('Left'))
now=now+6.1;assert(not bank:previewing('Left'),'expired preview replaced legacy rendering forever')
assert(not bank:command({'l1','key','left','Unsafe','{Enter}'}))
assert(not bank:command({'l1','key','left','Unsafe','ctrl+alt+i'}))
assert(not bank:command({'l1','pos','nan','1'}) and saved==count)
-- The same press cannot migrate into a companion or out of it.
reset();press(1);press(13);assert(bank.layer=='l1');release(1);tap(4)
assert(commands[1]=='input /wardrobe' and #ordinary==2 and ordinary[2][2]==false)
release(13)
-- Shoulder first owns its trigger; trigger first stays in the six-bar router.
for _,pair in ipairs({{13,11,'l1','l1l2'},{14,12,'r1','r1r2'}}) do
    local shoulder,trigger,bare,combined=table.unpack(pair)
    reset();press(shoulder);assert(bank.layer==bare);press(trigger);assert(bank.layer==combined and #ordinary==0)
    tap(8);release(trigger);assert(bank.layer==bare);release(shoulder)
    assert(not bank.output.held.r,'used R1 emitted release-R')
    reset();press(trigger);press(shoulder);assert(bank.layer=='' and #ordinary==1 and ordinary[1][1]==trigger)
    release(trigger);assert(bank.layer==bare and #ordinary==2);release(shoulder)
    reset();press(shoulder);press(trigger);release(shoulder);assert(bank.layer=='tail')
    tap(5);assert(#ordinary==0);release(trigger);assert(bank.layer=='')
end
-- Exact closed/menu mappings; context transitions consume held slots.
reset();press(13);tap(6);tap(7);tap(8);tap(5)
assert(table.concat(commands,'|')=='input /sack|input /satchel|input /case|input /jump')
press(1);local token,payload,base=bank.output:payload('test')
assert(payload:find('d,ctrl+i',1,true) and payload:find('u,ctrl+i',1,true))
menu=true;bank:refresh();local epoch=bank.output.epoch
assert(#bank.output.pending==0 and bank.blocked[1])
press(1);assert(#bank.output.pending==0,'held Items changed to native scrolling')
release(1);tap(1);tap(2);tap(3);tap(4)
local _,scroll=bank.output:payload('test')
for _,key in ipairs({'ctrl+left','alt+right','ctrl+right','alt+left'}) do assert(scroll:find('d,'..key,1,true)) end
commands={};tap(8);tap(6);tap(7);tap(5)
assert(table.concat(commands,'|')=='input /wave|input /bow|input /yes|input /jump')
-- Contextual execution is independent of native-menu visibility.
local left,right=bank:panel('Left'),bank:panel('Right')
assert(left:opacity(false)==0 and left:opacity(true)==0,'native menu guard belongs to the panel')
assert(left:settings().Slot8.Alias=='Wave')
left:settings().X=54;assert(settings.CompanionBanks.LeftPanel.X==54)
assert(settings.CompanionBanks.LeftPanel.Slot1==nil,'rendering duplicated entries into panel settings')
reset();press(14);tap(8);tap(6)
assert(commands[1]=='trust menu open' and commands[2]=='trust menu close')
assert(right:opacity(true)==1 and left:opacity(true)==0)
press(1);assert(bank.output.held.up);release(14);assert(not bank.output.held.up)
tap(1);assert(#commands==2)
-- Unused R1 release and pair Tab are native output, not console setkey.
reset();press(14);release(14);local _,r=bank.output:payload('test')
assert(r:find('d,r',1,true) and r:find('u,r',1,true))
reset();press(13);press(14);local _,tab=bank.output:payload('test');assert(tab:find('d,tab',1,true))
release(13);release(14);local _,after=bank.output:payload('test');assert(not after:find('d,r',1,true))
-- Chat/editor/focus/cutscene all use the same cancellation boundary.
reset();press(14);press(1);allowed=false;bank:refresh()
assert(next(bank.output.held)==nil and #bank.output.pending==0)
allowed=true;bank:refresh();assert(bank.blocked[1]);release(1);release(14)
assert(#bank.output.pending==0,'cancelled R1 emitted deferred R')
-- Owner refcounts: two editable holds on the same native chord.
assert(bank:command({'r1','key','right','Up too','up','hold'}))
reset();press(14);press(1);press(2);release(1);assert(bank.output.held.up)
release(2);assert(not bank.output.held.up)
-- Global output IDs survive cancellation; a late ack cannot retire new work.
reset();bank.output:pulse('ctrl+i');local old=bank.output.seq
bank.output:cancel();bank.output:pulse('tab');assert(not bank.output:accept(old-1))
assert(bank.output:accept(old) and #bank.output.pending==2)
assert(not bank.output:accept(bank.output.seq+1))
now=now+.36;assert(bank.output:stale());bank.output:cancel();assert(not bank.output:stale())
-- New protocol negotiates separately; old receivers reject its entire packet.
local received={};local receiver=require('libs/controller/messages').new({session='banks-test',clock=function()return now end,
    wallclock=function()return 100 end,capture=function()end,cancel=function()bank:cancel()end,
    physical=function(b,p)received[#received+1]={b,p};bank:edge(b,p)end,
    ready=function()bank.active=true end,key_ack=function(a)bank.output:accept(a)end})
receiver:context('character',true)
local function packet(body)return 'token='..receiver.token..'\nstamp=100\nbeat=1\n'..body..'END\n' end
assert(receiver:accept(packet('1,banks,0\n2,down,14\n3,down,8\n4,up,8\n5,up,14\n')))
assert(bank.active and commands[#commands]=='trust menu open')
local n=#commands
assert(not receiver:accept(packet('1,banks,0\n2,down,14\n3,down,8\n4,up,8\n5,up,14\n')) and #commands==n)
assert(receiver:accept(packet('6,down,14\n7,down,8\n8,cancel,0\n')) and #commands==n,'cancel executed queued command')
assert(not receiver:accept(packet('9,down,15\n')) and receiver.ack==8)
print('Companion banks: migration/editing, exact context maps, both shoulder orders/release orders, ownership, native output queue, Trust, pair Tab, cancellation and negotiated protocol passed.')
