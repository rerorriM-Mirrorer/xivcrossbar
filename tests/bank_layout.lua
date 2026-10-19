local Banks=require('companion_banks')
local now,settings,saved=5,{},0
local bank=Banks.new({settings=settings,clock=function()return now end,
    context=function()return true,false end,execute=function()error('layout executed a command')end,
    ordinary=function()error('layout emitted input')end,save=function()saved=saved+1 end,say=function()end,help=function()end})
local d=settings.CompanionBanks;d.LeftPanel.X=39;d.RightPanel.X=508
d.L1.Visible=false;d.R1.ShowOnMenu=true
assert(bank:command({'r1','triangle','Personal','input /echo preserved'}))
assert(bank:command({'swap','l1','r1'}))
assert(bank:entry('r1',1,false).Command=='input /wardrobe')
assert(bank:entry('r1',1,true).Key=='alt+left')
assert(bank:entry('l1',1,false).Key=='left' and bank:entry('l1',8,false).Command=='input /echo preserved')
assert(d.L1.ShowOnMenu and not d.R1.Visible)
assert(d.L1.Title=='L1  Trust' and d.R1.Title=='R1  Inventory')
assert(d.LeftPanel.X==39 and d.RightPanel.X==508)
assert(bank:command({'swap','l1','r1'}))
assert(bank:entry('l1',1,false).Command=='input /wardrobe')
local count=saved
assert(not bank:command({'swap','l1','l1'}));assert(not bank:command({'swap','bad','r1'}));assert(saved==count)
assert(bank:command({'r1r2','hide'}))
assert(bank:command({'r1r2','edit','on'}))
assert(bank:previewing('Right') and not d.RightPanel.Locked)
local right=bank:panel('Right');assert(right:opacity(true)==1 and right:opacity(false)==0)
now=now+100;assert(bank:previewing('Right'),'edit preview expired')
assert(not bank.active and bank.layer=='' and not next(bank.down),'edit armed input')
assert(bank:command({'r1r2','edit','off'}))
assert(d.RightPanel.Locked and not bank:previewing('Right') and right:opacity(true)==0)
assert(not bank:command({'r1','edit','maybe'}))
-- Actual main-position helper: coordinates remain offsets, not scaled pixels.
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local helper=assert(source:match('(local function set_crossbar_position%(args%).-\nend)\n'))
local main={Style={OffsetX=3,OffsetY=4}};local moved
local env=setmetatable({settings=main,ui={is_setup=true},theme_options={},
    crossbar_drag={finish=function()end},move_crossbars=function(x,y)moved={x,y}end,
    config={save=function()saved=saved+1 end},windower={add_to_chat=function()end}}, {__index=_G})
local setpos=assert(load(helper..'\nreturn set_crossbar_position','actual main position','t',env))()
setpos({});assert(not moved)
setpos({'12','-31'});assert(moved[1]==12 and moved[2]==-31 and main.Style.OffsetX==12 and env.ui_dirty)
setpos({'nan','2'});assert(main.Style.OffsetX==12)
setpos({'1','2','3'});assert(main.Style.OffsetX==12)
print('Actual bank swap: materialized inherited/custom entries, both contexts, titles/policies, stable positions, mouse-only edit pinning and main-position validation passed.')
