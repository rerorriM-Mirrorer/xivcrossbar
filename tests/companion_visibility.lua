-- Use the actual bank owner, native output queue and panel facade. Drawing
-- policy must never turn a hidden bank into ordinary game button input.
local Banks=require('companion_banks')
local settings={};local menu,allowed=false,true;local sent,saves={},0
local bank=Banks.new({settings=settings,clock=function()return 10 end,
    context=function()return allowed,menu end,save=function()saves=saves+1 end,
    execute=function(c)sent[#sent+1]=c end,ordinary=function()error('bank input leaked')end,
    say=function()end,help=function()end})
local function edge(b,p)bank:edge(b,p)end
local function tap(b)edge(b,true);edge(b,false)end
local left,right=bank:panel('Left'),bank:panel('Right')
for _,layer in ipairs({'l1','l1l2','r1','r1r2'}) do
    bank:cancel();menu=false;bank:refresh()
    edge(layer:sub(1,1)=='l' and 13 or 14,true)
    if layer=='l1l2' then edge(11,true) elseif layer=='r1r2' then edge(12,true) end
    local panel=layer:sub(1,1)=='l' and left or right
    assert(panel:opacity(true)==1)
    assert(bank:command({layer,'hide'}));assert(panel:opacity(true)==0)
    assert(bank:command({layer,'triangle','Marker','input /echo '..layer}))
    tap(8);assert(sent[#sent]=='input /echo '..layer,'hidden bank stopped executing')
    assert(bank:command({layer,'show'}));assert(panel:opacity(true)==1)
    menu=true;bank:refresh();assert(panel:opacity(true)==0)
    assert(bank:command({layer,'menus','on'}));assert(panel:opacity(true)==1)
    assert(panel:opacity(false)==0,'visibility bypassed eligibility')
    assert(bank:command({layer,'menus','off'}));assert(panel:opacity(true)==0)
end
bank:cancel();menu=true;bank:refresh();edge(13,true)
assert(left:settings().Slot4.Key=='ctrl+left')
assert(bank:command({'l1','menuactions','off'}))
assert(left:settings().Slot4.Key=='ctrl+i','drawn label disagrees with closed binding')
tap(1);local _,payload=bank.output:payload('test')
assert(payload:find('d,ctrl+i',1,true),'broad battle-menu flag stole Items')
assert(bank:command({'l1','menuactions','on'}))
tap(1);_,payload=bank.output:payload('test')
assert(payload:find('d,ctrl+left',1,true),'explicit menu scrolling lost')
local count=saves
assert(not bank:command({'l1','menus','maybe'}))
assert(not bank:command({'l1','menu','hide'}))
assert(not bank:command({'l1','hide','extra'}))
assert(saves==count)
-- Explicit preset only; old custom settings never adopt a character template.
assert(not bank:command({'preset','cioara'}))
bank:cancel();menu=false;bank:refresh()
assert(bank:command({'l1','left','Custom wardrobe','input /wardrobe4'}))
local panelX=settings.CompanionBanks.LeftPanel.X
assert(bank:command({'preset','cioara','apply'}))
assert(settings.CompanionBanks.LeftPanel.X==panelX)
assert(bank:entry('l1l2',1,false).Command=='input /wardrobe4')
assert(bank:entry('l1l2',4,false).Key=='ctrl+i')
assert(bank:entry('r1',6,false).Command=='send @others trust start; input /echo Asked party to stand ready!')
assert(bank:entry('r1',7,false).Command=='send @all trust stop; input /echo Asked party to stand down!')
assert(bank:entry('r1',8,false).Command=='trust toggle')
assert(bank:entry('l1',8,false).Command=='npcmirror interact')
assert(bank:entry('l1',6,false).Command=='se all once; wait 2; slowenter on')
assert(bank:entry('l1',7,false).Command=='all slowenter off; wait 0.1; slowenter all once esc')
assert(bank:entry('r1r2',5,false).Command=='trust menu close')
assert(bank:entry('r1r2',8,false).Command=='trust menu open')
assert(bank:entry('r1r2',6,false).Key=='enter' and bank:entry('r1r2',7,false).Key=='escape')
assert(settings.CompanionBanks.R1.ShowOnMenu and not settings.CompanionBanks.R1R2.Visible)
assert(not settings.CompanionBanks.L1L2.MenuActions)
assert(bank:command({'preset','cioara','apply'}))
assert(bank:entry('l1l2',1,false).Command=='input /wardrobe4','second apply copied NPC over inventory')
bank:cancel();menu=true;bank:refresh();edge(14,true)
assert(right:opacity(true)==1);tap(8);assert(sent[#sent]=='trust toggle')
edge(12,true);assert(bank.layer=='r1r2' and right:opacity(true)==0)
tap(8);assert(sent[#sent]=='trust menu open','hidden Trust navigation lost commands')
print('Actual bank visibility/menu routing: four independent layers, hidden execution, broad battle-menu override, native scrolling, explicit Cioara preset, repeated apply and preserved inventory passed.')
