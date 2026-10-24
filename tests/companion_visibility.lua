-- Rendering is independent of physical holds and action eligibility.
local Banks=require('libs/banks/banks')
local settings={};local menu,allowed,chat=false,true,false;local sent={};local now=10
local bank=Banks.new({settings=settings,clock=function()return now end,
 context=function()return allowed,menu,false,chat end,save=function()end,
 execute=function(c)sent[#sent+1]=c end,ordinary=function()end,say=function()end,help=function()end})
local left,right=bank:panel('Left'),bank:panel('Right')
bank:refresh();assert(left:opacity(true)==0 and right:opacity(true)==0,'idle panels visible')
assert(bank:command({'l1','display','always'}));assert(left:opacity(true)==1)
assert(bank:command({'l1','display','held'}));assert(left:opacity(true)==0)
chat=true;menu=true;bank:refresh()
assert(left:opacity(true)==0 and right:opacity(true)==0)
assert(left:opacity(false)==0)
bank:edge(13,true);bank:edge(5,true);bank:edge(5,false);bank:edge(13,false)
assert(#sent==1,'chat blocked deliberate bank input');sent={}
allowed=true;bank:refresh();bank:edge(14,true)
for b=1,8 do bank:edge(b,true);bank:edge(b,false)end
assert(table.concat(sent,'|')=='npc raw up|npc raw right|npc raw down|npc raw left|npc enter|npc raw enter|npc cancel|npc interact')
bank:edge(14,false);bank:cancel()
assert(bank:command({'l1','hide'}));assert(left:opacity(true)==0)
assert(bank:command({'l1','show'}));bank:edge(13,true);assert(left:opacity(true)==1)
assert(bank:command({'l1','menus','off'}));assert(left:opacity(true)==0)
assert(bank:command({'l1','menus','on'}));assert(left:opacity(true)==1)
for _,pair in ipairs({{13,11,'l1'},{14,12,'r1'}})do
 bank:cancel();menu=false;chat=false;bank:refresh()
 bank:edge(pair[1],true);bank:edge(pair[2],true);assert(bank.layer==pair[3],'disabled level replaced first')
 bank:edge(pair[1],false);assert(bank.layer=='tail');bank:edge(pair[2],false)
end
assert(bank:command({'l2','triangle','Later','input /echo later'}))
assert(bank:command({'l2','enable'}));bank:cancel();bank:edge(13,true);bank:edge(11,true)
assert(bank.layer=='l1l2');bank:edge(8,true);assert(sent[#sent]=='input /echo later')
assert(bank:command({'l2','disable'}));bank:refresh();assert(bank.layer=='l1')
local before=#sent;bank:edge(8,true);assert(#sent==before,'held slot replayed after disable')
bank:cancel();settings.CompanionBanks.LeftPanel.X=1657;settings.CompanionBanks.RightPanel.Y=1675
assert(bank:command({'preset','cioara','apply'}))
assert(settings.CompanionBanks.LeftPanel.X==1657 and settings.CompanionBanks.RightPanel.Y==1675)
assert(bank:entry('l1',1,false).Command=='switch p' and bank:entry('l1',4,false).Command=='switch p1')
for _,layer in ipairs({'l1l2','r1r2'})do
 assert(not bank:settings()[layer=='l1l2' and 'L1L2' or 'R1R2'].Enabled)
 for _,mode in ipairs({false,true})do for i=1,8 do assert(bank:entry(layer,i,mode).Command=='')end end
end
assert(bank:command({'preset','cioara','apply'}));assert(bank:entry('r1',5,true).Command=='npc raw enter')
bank:cancel();bank:command({'l2','preview'});assert(left:mode()=='l1l2');
-- Expired previews must return to their normal first-level view.
now=17;assert(left:mode()=='l1' and left:opacity(true)==0)
print('Bank held/always display, chat actions, disabled layers, held-slot isolation, Cioara defaults and unchanged positions passed.')
-- Execute the actual root drawing gate with chat/cutscene active; no action
-- policy is consulted to determine whether the panels may be drawn.
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local gate=assert(source:match('(local l1_display=.-)\n    local viewport='))
local env=setmetatable({xivcrossbar={ready=true},settings={ControllerProfile='ps5-extended'},
 action_binder={is_hidden=true},env_chooser={is_showing=function()return false end},
 gamepad_mapper={},l1_character={status=4},l1_info={logged_in=true,chat_open=true}}, {__index=_G})
local draw=assert(load(gate..'\nreturn l1_display','actual bank drawing gate','t',env))
assert(draw(),'chat/cutscene hid the root bank drawing gate')
env.l1_info.logged_in=false;assert(not draw(),'logged-out panel drawn')
