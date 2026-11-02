-- Actual Lua router/views: shoulder combinations and linked drag geometry.
local Banks=require('libs/banks/banks')
local s={};local menu,eligible=false,true;local sent,ordinary={},{}
local bank=Banks.new({settings=s,clock=function()return 10 end,
 context=function()return eligible,menu end,save=function()end,say=function()end,help=function()end,
 execute=function(c)sent[#sent+1]=c end,ordinary=function(b,p)ordinary[#ordinary+1]={b,p}end})
local d=s.CompanionBanks
assert(d.LinkedPositions and d.L1R1.Enabled)
for i=1,8 do assert(bank:entry('l1r1',i,false).Command=='') end
local left,right=bank:panel('Left'),bank:panel('Right')
d.LeftPanel.X,d.LeftPanel.Y=100,100;d.RightPanel.X,d.RightPanel.Y=500,110
left:clamp(1000,700,290,150);right:clamp(1000,700,290,150)
left:move(120,125)
assert(d.RightPanel.X==120 and d.RightPanel.Y==125 and d.LeftPanel.Y==125)
right:move(550,160)
assert(d.LeftPanel.X==550 and d.LeftPanel.Y==160)
left:move(900,900)
assert(d.RightPanel.X==710 and d.RightPanel.Y==550 and d.LeftPanel.X==710 and d.LeftPanel.Y==550,'common anchor not clamped')
assert(bank:command({'l','pos','300','530'}))
assert(d.RightPanel.X==300 and d.RightPanel.Y==530,'position command did not update common anchor')
-- Every alias enters the same handler for every supported bank operation.
for alias,full in pairs({l='l1',r='r1',lr='l1r1',rl='l1r1',l2='l1l2',r2='r1r2'}) do
 assert(bank:command({alias,'edit'}));local side=full:sub(1,1)=='l' and 'Left' or 'Right'
 assert(bank.previews[side].layer==full and bank.previews[side].editing)
 assert(bank:command({alias,'edit'}));assert(not next(bank.previews))
 assert(bank:command({alias,'edit','on'}));assert(bank:command({alias,'edit','on'}))
 assert(bank.previews[side].editing,'explicit on toggled off')
 assert(bank:command({alias,'edit','off'}));assert(bank:command({alias,'edit','off'}))
 for _,args in ipairs({{'enable'},{'disable'},{'enable'},{'show'},{'hide'},{'show'},
  {'display','always'},{'display','held'},{'menus','off'},{'menus','on'},
  {'menuactions','on'},{'menuactions','off'},{'cutscenes','on'},{'cutscenes','off'},
  {'pos','100','100'},{'resetpos'},{'scale','0.8'},{'scale','crossbar'},
  {'lock'},{'unlock'},{'lock'}, {'cross','Label','input /echo alias'},
  {'append','cross','input /echo appended'},{'clear','cross'},{'default','cross'},{'defaults'},
  {'menu','cross','Menu','input /echo menu'},{'menu','append','cross','input /echo more'},
  {'menu','key','up','Up','up','hold'},{'menu','clear','up'},
  {'menu','default','up'},{'menu','defaults'}}) do
   local command={alias};for _,v in ipairs(args) do command[#command+1]=v end
   assert(bank:command(command),'alias operation failed: '..table.concat(command,' '))
 end
 bank:command({alias,'status'});bank:command({alias,'status','details'});bank:command({alias,'help'})
 bank:command({alias,'preview'});assert(bank.previews[side].layer==full)
end
assert(bank:command({'swap','l','r'}));assert(bank:command({'swap','r','l'}))
assert(bank:command({'swap','l','lr'}));assert(bank:command({'swap','lr','l'}))
bank.previews={};assert(bank:command({'l','edit'}));assert(bank:command({'r','edit'}))
assert(not bank.previews.Left and bank.previews.Right.layer=='r1')
assert(left:opacity(true)==0 and right:opacity(true)==1,'shared previews overlapped')
assert(bank:command({'r','edit'}))
d.L1.Display='always';d.R1.Display='always';bank:cancel()
assert(left:opacity(true)==1 and right:opacity(true)==0,'idle Always banks overlapped')
bank:edge(14,true);assert(left:opacity(true)==0 and right:opacity(true)==1,'held R1 did not replace Always L1')
bank:edge(13,true);assert(left:opacity(true)==1 and right:opacity(true)==0,'combined bank did not replace Always R1')
bank:cancel();d.L1.Display='held';d.R1.Display='held'
assert(bank:command({'lr','cross','Combined','input /echo combined'}))
assert(bank:command({'l1r1','key','up','Move','up','hold'}))
for _,order in ipairs({{13,14},{14,13}}) do
 for _,release in ipairs({{13,14},{14,13}}) do
  bank:cancel();sent={};ordinary={}
  bank:edge(order[1],true);bank:edge(order[2],true)
  assert(bank.layer=='l1r1' and #bank.output.pending==0,'combined entry emitted Tab/R')
  assert(left:mode()=='l1r1' and left:opacity(true)==1 and right:opacity(true)==0)
  bank:edge(5,true);bank:edge(5,false);assert(sent[1]=='input /echo combined')
  bank:edge(1,true);assert(bank.output.held.up)
  bank:edge(release[1],false);assert(not bank.output.held.up and bank.blocked[1])
  local count=#sent;bank:edge(5,true);bank:edge(5,false)
  bank:edge(release[2],false);bank:edge(1,false)
  local _,payload=bank.output:payload('test')
  assert(not payload:find('d,tab',1,true) and not payload:find('d,r|',1,true),'release emitted old pair shortcut')
 end
end
-- A held face is consumed across entering AND leaving the combined bank.
bank:cancel();sent={};bank:edge(13,true);bank:edge(5,true)
local count=#sent;bank:edge(14,true);assert(#sent==count and bank.blocked[5])
bank:edge(5,true);assert(#sent==count)
bank:edge(5,false);bank:edge(5,true);assert(sent[#sent]=='input /echo combined')
bank:edge(14,false);count=#sent;bank:edge(5,true);assert(#sent==count)
bank:edge(5,false);bank:edge(13,false)
-- A recovered combination restores only controls, never a slot or Tab.
bank:cancel();sent={};bank:resume(13);bank:resume(14)
assert(bank.layer=='l1r1' and #sent==0 and #bank.output.pending==0)
-- Focus loss cancels native holds; Always R1 cannot overlap the combined bank.
d.R1.Display='always';bank:edge(1,true);assert(bank.output.held.up)
assert(right:opacity(true)==0)
eligible=false;bank:refresh();assert(not next(bank.output.held))
bank:cancel();eligible=true;menu=true;bank:refresh();bank:edge(14,true);bank:edge(13,true)
assert(left:mode()=='l1r1' and left:opacity(true)==1)
assert(bank:command({'l1r1','menus','off'}));assert(left:opacity(true)==0)
assert(bank:command({'l1r1','edit','on'}));assert(left:opacity(true)==1)
assert(bank:command({'l1r1','edit','off'}));assert(bank:command({'l1r1','disable'}))
bank:cancel();menu=false;bank:edge(13,true);bank:edge(14,true)
local _,payload=bank.output:payload('test');assert(payload:find('d,tab',1,true),'disabled combined bank lost old Tab route')
-- New fields remain part of the declared XML shape, not transient view state.
local Store=require('libs/banks/storage')
local encoded=Store.encode({global={CompanionBanks=d}})
assert(encoded:find('<L1R1>',1,true) and encoded:find('<LinkedPositions>true</LinkedPositions>',1,true))
-- Real mouse callbacks delegate to the group mover, including after bank switch.
local f=assert(io.open('xivcrossbar.lua'));local root=f:read('*a');f:close()
assert(root:find('companion_right:move(x,y)',1,true) and root:find('if b.move then b:move(x,y)',1,true))
print('Combined bank: both press/release orders, slot/hold ownership, no Tab/R, recovery/focus/menu isolation, shared moves/edges/aliases/toggle/commands and XML shape passed.')
