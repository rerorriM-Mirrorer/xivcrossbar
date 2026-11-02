local Banks=require('libs/banks/banks')
local settings={CompanionBanks=Banks.defaults(),CrossbarScale=1,Style={}}
local menu=true
local bank=Banks.new({settings=settings,clock=function()return 10 end,
    context=function()return true,menu end,ordinary=function()end,execute=function()end})
assert(bank:settings().R1.MenuActions)
assert(Banks.factory('l1',5,false).Alias=='Toggle')
assert(Banks.factory('l1',6,false).Alias=='Ready')
assert(Banks.factory('l1',8,false).Alias=='Menu')
for slot,key in ipairs({'alt+left','ctrl+down','alt+right','ctrl+up'}) do
    local e=bank:entry('r1',slot,true)
    assert(e.Kind=='key' and e.Key==key and e.Hold)
end
bank:edge(14,true);bank:edge(4,true)
assert(next(bank.output.held),'menu chord not held')
bank:edge(4,false);assert(not next(bank.output.held),'menu chord stuck after release')
bank:edge(3,true);menu=false;bank:refresh()
assert(not next(bank.output.held),'menu close retained chord')
bank:cancel()
local old={CompanionBanks={Version=2,R1={MenuActions=false}}}
old.CompanionBanks.R1.Menu={Slot1=Banks.factory('r1',1,false),Slot2={Alias='Personal',Kind='command',Command='npc raw down',Key='',Hold=false}}
Banks.ensure(old)
assert(old.CompanionBanks.R1.Menu.Slot1.Kind=='default')
assert(old.CompanionBanks.R1.Menu.Slot2.Alias=='Personal')
assert(old.CompanionBanks.R1.MenuActions,'existing R1 menu policy not enabled')
old.CompanionBanks.R1.MenuActions=false;Banks.ensure(old)
assert(not old.CompanionBanks.R1.MenuActions,'later explicit off overwritten')
settings.CompanionBanks.R1.MenuActions=false
Banks.ensure(settings);assert(not settings.CompanionBanks.R1.MenuActions,'explicit policy replaced')
settings.CompanionBanks.R1.Menu.Slot1={Alias='Personal',Kind='command',Command='echo preserved',Icon='mine.png'}
assert(bank:entry('r1',1,true).Command=='echo preserved')
local panel={X=777,Y=888,Scale=1,FollowCrossbar=true}
local view=require('ui/bank_view').new({bank={settings=function()return panel end},settings=settings,main_top=function()return 700 end})
for _,scale in ipairs({.6,1,1.5}) do
    settings.CrossbarScale=scale
    local x,y=view:position(1920,1080)
    local _,_,_,w,h=view:metrics()
    assert(math.abs(x+w*scale/2-960)<.001 and y+h*scale==700-12*scale)
end
assert(panel.X==777 and panel.Y==888,'centering erased coordinates')
bank:move_panel('Left',15,25);assert(not settings.CompanionBanks.Centered)
assert(view:position(1920,1080)==777)
print('Centered banks: shared geometry, saved-coordinate/custom-policy preservation and native menu chord release passed.')
