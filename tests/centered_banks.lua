local Banks=require('libs/banks/banks')
local settings={CompanionBanks=Banks.defaults(),CrossbarScale=1,Style={}}
local menu=true
local bank=Banks.new({settings=settings,clock=function()return 10 end,
    context=function()return true,menu end,ordinary=function()end,execute=function()end})
assert(bank:settings().R1.MenuActions)
assert(Banks.factory('l1',5,false).Alias=='Toggle')
assert(Banks.factory('l1',6,false).Alias=='Ready')
assert(Banks.factory('l1',8,false).Alias=='')
for slot,key in ipairs({'alt+left','ctrl+right','alt+right','ctrl+left'}) do
    local e=bank:entry('r1',slot,true)
    assert(e.Kind=='key' and e.Key==key and e.Hold)
end
bank:edge(14,true);bank:edge(4,true)
assert(next(bank.output.held),'menu chord not held')
bank:edge(4,false);assert(not next(bank.output.held),'menu chord stuck after release')
bank:edge(1,true);assert(bank.output.held['ctrl+left'],'Up did not scroll ten items up')
bank:edge(1,false);assert(not next(bank.output.held))
bank:edge(3,true);assert(bank.output.held['ctrl+right'],'Down did not scroll ten items down')
menu=false;bank:refresh()
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
local main_settings={CrossbarScale=1,Style={},CompanionBanks={Centered=false}}
local panel={X=777,Y=888,Scale=1,FollowCrossbar=true}
local view=require('ui/bank_view').new({bank={settings=function()return panel end},settings=main_settings,bank_settings=settings,main_top=function()return 700 end})
for _,scale in ipairs({.6,1,1.5}) do
    main_settings.CrossbarScale=scale
    local x,y=view:position(1920,1080)
    local _,_,_,w,h=view:metrics()
    assert(math.abs(x+w*scale/2-960)<.001 and y+h*scale==700-12*scale)
end
bank:clamp_panel('Left',1920,1080,290,148)
assert(settings.CompanionBanks.Centered,'viewport clamp disabled centering')
assert(panel.X==777 and panel.Y==888,'centering erased coordinates')
bank:move_panel('Left',15,25);assert(not settings.CompanionBanks.Centered)
assert(view:position(1920,1080)==777)
-- Execute the real root constructors and command with separate settings stores.
local source=assert(io.open('xivcrossbar.lua')):read('*a')
local root_main={Style={OffsetX=38,OffsetY=-7},CrossbarScale=1}
local root_env=setmetatable({settings=root_main,bank_settings=settings,l1_bank=bank:panel('Left'),
    companion_right=bank:panel('Right'),companion_banks=bank,ui={is_setup=true,get_screen_top=function()return 700 end},
    windower={addon_path='',add_to_chat=function()end},move_crossbars=function()end,
    config={save=function()end},bank_storage={save=function()return true end},
    require=function(name)if name=='ui/resources' then return {} end;return require(name)end},{__index=_G})
local constructors=source:match("(local l1_view=require%('ui/bank_view'%).-\n)")..source:match("(local r1_view=require%('ui/bank_view'%).-\n)")
local left,right=assert(load(constructors..'return l1_view,r1_view','actual root bank views','t',root_env))()
local helper=assert(source:match('(local function set_centered_position%(args%).-\nend)\n'))
local center=assert(load(helper..'\nreturn set_centered_position','actual center command','t',root_env))()
center({'on'});assert(root_main.CenterCrossbars and settings.CompanionBanks.Centered)
left:tick(false,1920,1080);right:tick(false,1920,1080)
local lb,rb=left:bounds(),right:bounds()
assert(lb.x==815 and rb.x==815 and lb.y==540 and rb.y==540,'root views ignored separate bank centering state')
assert(settings.CompanionBanks.Centered,'idle root render disabled centering')
center({'off'});assert(not root_main.CenterCrossbars and not settings.CompanionBanks.Centered)
center({'bogus'});assert(not settings.CompanionBanks.Centered)
local old_scroll={CompanionBanks={Version=2,R1MenuDefaultsApplied=true,R1={Menu={
    Slot2={Alias='Fast Down',Kind='key',Command='',Key='ctrl+down',Hold=true},
    Slot4={Alias='Fast Up',Kind='key',Command='',Key='ctrl+up',Hold=true}}}}}
Banks.ensure(old_scroll)
assert(old_scroll.CompanionBanks.R1.Menu.Slot2.Kind=='default' and old_scroll.CompanionBanks.R1.Menu.Slot4.Kind=='default')
old_scroll.CompanionBanks.R1.Menu.Slot4={Alias='Custom',Kind='key',Command='',Key='ctrl+up',Hold=true,Icon='mine.png'}
old_scroll.CompanionBanks.R1ScrollDefaultsApplied=false;Banks.ensure(old_scroll)
assert(old_scroll.CompanionBanks.R1.Menu.Slot4.Icon=='mine.png','custom scroll entry replaced')
print('Centered banks: shared geometry, saved-coordinate/custom-policy preservation and native menu chord release passed.')
