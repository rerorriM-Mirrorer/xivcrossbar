-- Dialogue permits bare navigation; chat/trigger gestures stay masked.
local M=require('libs/banks/banks')
local scene,chat,menu,eligible=false,false,false,true
local sent,ordinary={},{ }
local bank=M.new({settings={},clock=function()return 10 end,
 context=function()return eligible,menu,scene,chat end,
 execute=function(s)sent[#sent+1]=s end,ordinary=function(b,p)ordinary[#ordinary+1]={b,p}end,
 save=function()end,say=function()end,help=function()end})
local function tap(b)bank:edge(b,true);bank:edge(b,false)end
for _,context in ipairs({'scene','chat'})do
 bank:cancel();scene=context=='scene';chat=context=='chat';bank:refresh()
 local before=#sent
 for b=1,12 do tap(b)end
 assert(#sent==before and #ordinary==(scene and 16 or 0) and #bank.output.pending==0,'incorrect dialogue/chat ownership')
 ordinary={}
 bank:edge(14,true);assert(bank:panel('Right'):opacity(true)==1)
 tap(8);assert(sent[#sent]=='npc interact')
 bank:edge(14,false);assert(bank:panel('Right'):opacity(true)==0)
 assert(#bank.output.pending==0,'bare R1 release emitted R')
 bank:cancel();bank:edge(13,true);bank:edge(14,true)
 assert(#bank.output.pending==0,'pair emitted Tab in chat/dialogue')
 bank:cancel();assert(bank:command({'r1','cutscenes','off'}))
 bank:edge(14,true);tap(5);assert(sent[#sent]=='npc enter','legacy flag blocked explicit bank')
 bank:cancel();assert(bank:command({'r1','key','up','Native Enter','enter','hold'}))
 bank:edge(14,true);bank:edge(1,true);assert(bank.output.held.enter)
 eligible=false;bank:refresh();assert(not next(bank.output.held) and #bank.output.pending==0)
 local count=#sent;tap(8);assert(#sent==count,'unfocused input dispatched')
 eligible=true;bank:cancel()
end
scene=false;chat=false;bank:refresh();bank:edge(14,true);bank:edge(1,true)
assert(bank.output.held.enter);chat=true;bank:refresh()
assert(not next(bank.output.held),'chat transition retained native hold')
bank:edge(1,true);assert(not next(bank.output.held),'held press replayed across chat transition')
bank:edge(1,false);bank:edge(1,true);assert(bank.output.held.enter)
print('Held banks: chat/dialogue commands and native keys, no ordinary/Tab/R leakage, legacy-flag compatibility, focus cancellation and no transition replay passed.')
