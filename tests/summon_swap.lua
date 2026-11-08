local Swap=require('libs/summon_swap')
local now,context,state=0,'player:job:zone',{pet=true,pet_name='carbuncle',pet_id=10,player={status=0}}
local queue,sent,casts,notices={},{},{},{}
local swap=Swap.new({clock=function()return now end,context=function()return context end,
 snapshot=function()return state end,schedule=function(fn)queue[#queue+1]=fn end,
 send=function(c)sent[#sent+1]=c end,cast=function(a)casts[#casts+1]=a end,notice=function(n)notices[#notices+1]=n end})
local action={type='ma',action='Ifrit',target='me',alias='Fire'}
local function step()local f=table.remove(queue,1);assert(f);f()end
swap:request(action,state);swap:request(action,state);assert(#sent==1)
step();assert(#casts==0 and #queue==1,'cast before Release completion')
state.pet=false;step();assert(#casts==1 and casts[1]~=action and casts[1].alias=='Fire')
state.pet=true;swap:request(action,state);now=6;step();assert(not swap.pending and #casts==1 and #notices==1)
now=0;swap:request(action,state);context='new zone';step();assert(not swap.pending and #casts==1)
context='player:job:zone';swap:request(action,state);state.pet_id=11;step();assert(not swap.pending and #casts==1)
state.pet_id=10;swap:request(action,state);state.player.status=2;step();assert(not swap.pending and #casts==1)
state.player.status=0;swap:request(action,state);swap:cancel();state.pet=false;step();assert(#casts==1)
state.pet=true;swap:request(action,state);swap:request({type='ma',action='Shiva'},state)
state.pet=false;step();assert(#casts==1,'stale request revived');step();assert(casts[2].action=='Shiva')
assert(action.action=='Ifrit' and action.type=='ma')
print('Summon replacement: observed completion, held pet/timeout, context/death/replacement cancellation, duplicate/replaced requests and immutable binding passed.')
