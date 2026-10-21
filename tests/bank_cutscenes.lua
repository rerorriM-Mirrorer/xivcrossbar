-- Exercise real bank ownership, including the negative routes during a scene.
local M=require('libs/banks/banks')
local scene,menu,eligible=false,false,true
local sent,ordinary,saved={},{},0
local settings={}
local bank=M.new({settings=settings,clock=function()return 10 end,
    context=function()return eligible,menu,scene end,
    execute=function(s)sent[#sent+1]=s end,
    ordinary=function(b,p)ordinary[#ordinary+1]={b,p}end,
    save=function()saved=saved+1 end,say=function()end,help=function()end})
assert(not bank:cutscene_enabled())
assert(bank:command({'r1','triangle','NPC','npcmirror interact'}))
assert(bank:command({'r1','menu','triangle','Menu NPC','npcmirror enter'}))
scene=true;bank:refresh()
for b=1,12 do bank:edge(b,true);bank:edge(b,false)end
bank:edge(13,true);bank:edge(8,true);bank:edge(8,false);bank:edge(13,false)
assert(#sent==0 and #ordinary==0 and #bank.output.pending==0)
assert(bank:command({'r1','cutscenes','on'}) and bank:cutscene_enabled())
bank:edge(14,true);bank:edge(8,true);bank:edge(8,false);bank:edge(14,false)
assert(sent[1]=='npcmirror interact' and #bank.output.pending==0,'unused R1 release leaked R')
bank:cancel();bank:edge(14,true);bank:edge(12,true)
bank:edge(8,true);bank:edge(8,false);bank:edge(12,false);bank:edge(14,false)
assert(#sent==1,'R1R2 inherited R1 cutscene permission')
bank:cancel();bank:edge(13,true);bank:edge(14,true)
bank:edge(13,false);bank:edge(14,false)
assert(#bank.output.pending==0,'cutscene pair emitted Tab')
bank:cancel();menu=true;bank:edge(14,true);bank:edge(8,true);bank:edge(8,false)
assert(sent[2]=='npcmirror enter','cutscene permission changed MenuActions policy')
assert(bank:panel('Right'):opacity(true)==0,'cutscene permission bypassed drawing policy')
assert(bank:command({'r1','menus','on'}));assert(bank:panel('Right'):opacity(true)==1)
bank:edge(14,false);bank:cancel()
assert(bank:command({'r1','cutscenes','off'}) and not bank:cutscene_enabled())
bank:edge(14,true);bank:edge(8,true);bank:edge(8,false);bank:edge(14,false)
assert(#sent==2 and #ordinary==0)
bank:cancel();assert(bank:command({'r1r2','cutscenes','on'}))
bank:edge(14,true);bank:edge(12,true);bank:edge(8,true);bank:edge(8,false)
assert(sent[3]=='npcmirror interact')
-- Losing eligibility or entering a scene retires the old hold without replay.
bank:cancel();scene=false;menu=false
bank:edge(14,true);bank:edge(1,true);assert(bank.output.held.up)
scene=true;bank:refresh();assert(not next(bank.output.held) and #bank.output.pending==0)
bank:edge(1,false);bank:edge(14,false);assert(#sent==3)
bank:cancel();eligible=false;bank:edge(14,true);bank:edge(12,true);bank:edge(8,true)
assert(#sent==3 and #ordinary==0)
assert(not bank:command({'r1r2','cutscenes','bad'}))
print('Actual cutscene banks: default-off, per-bank permission, NPC commands, normal/Menu maps, drawing separation, blocked ordinary/trigger/pair/R routes and transition cleanup passed.')
