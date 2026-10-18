-- Factory inheritance, v1 adoption and actual root alias dispatch.
local M=require('companion_banks')
local s={CompanionBanks={Version=1}}
for layer,name in pairs({l1='L1',l1l2='L1L2',r1='R1',r1r2='R1R2'}) do
    s.CompanionBanks[name]={Closed={},Menu={}}
    for _,ctx in ipairs({'Closed','Menu'}) do for i=1,8 do
        s.CompanionBanks[name][ctx]['Slot'..i]=layer=='r1r2' and {Alias='',Kind='command',Command='',Key='',Hold=false}
            or M.factory(layer,i,ctx=='Menu')
    end end
end
s.CompanionBanks.L1.Closed.Slot7={Alias='',Kind='command',Command='',Key='',Hold=false} -- deliberately cleared
s.CompanionBanks.R1R2.Closed.Slot1={Alias='Personal',Kind='command',Command='input /echo custom',Key='',Hold=false}
s.CompanionBanks.L1L2.Closed.Slot4={Alias='Imported',Kind='command',Command='input /echo legacy',Key='',Hold=false}
s.CompanionBanks.LeftPanel={X=53,Y=74,Scale=.7,Locked=false,FollowCrossbar=false,Initialized=true}
local saves,executed=0,{}
local bank=M.new({settings=s,clock=function()return 10 end,context=function()return true,false end,
    ordinary=function()end,execute=function(c)executed[#executed+1]=c end,save=function()saves=saves+1 end,say=function()end,help=function()end})
assert(bank.migrated and s.CompanionBanks.Version==2)
assert(bank:stored_entry('l1',4,false).Kind=='default' and bank:entry('l1',4,false).Key=='ctrl+i')
assert(bank:stored_entry('l1',7,false).Kind=='command' and bank:entry('l1',7,false).Command=='')
assert(bank:entry('r1r2',1,false).Command=='input /echo custom')
assert(bank:stored_entry('r1r2',2,false).Kind=='default' and bank:entry('r1r2',2,false).Command=='slowenter all once esc')
assert(bank:entry('l1l2',4,false).Command=='input /echo legacy')
assert(not select(2,M.ensure(s)),'v2 migrated repeatedly')
assert(bank:command({'l1','default','circle'}));assert(bank:entry('l1',7,false).Command=='input /satchel')
assert(bank:stored_entry('l1',7,false).Kind=='default')
assert(bank:command({'r1r2','clear','down'}));M.ensure(s)
assert(bank:stored_entry('r1r2',2,false).Kind=='command' and bank:entry('r1r2',2,false).Command=='')
assert(bank:command({'r1r2','default','down'}));assert(bank:entry('r1r2',2,false).Command=='slowenter all once esc')
assert(bank:command({'r1r2','append','right','input /echo extra'}))
assert(bank:entry('r1r2',3,false).Command=='npcmirror status; input /echo extra')
assert(M.factory('r1r2',3,false).Command=='npcmirror status','append modified hardcoded default')
assert(bank:command({'r1r2','menu','triangle','Other','input /echo menu'}))
assert(bank:command({'r1r2','defaults'}))
assert(bank:entry('r1r2',8,true).Command=='input /echo menu','closed defaults reset menu overrides')
assert(bank:command({'r1r2','menu','defaults'}))
assert(bank:entry('r1r2',8,true).Command=='npcmirror interact')
assert(s.CompanionBanks.LeftPanel.X==53 and s.CompanionBanks.LeftPanel.Scale==.7 and not s.CompanionBanks.LeftPanel.Locked)
local count=saves
assert(not bank:command({'r1r2','default','down','extra'}))
assert(not bank:command({'r1r2','defaults','all'}))
assert(saves==count)
-- Exact eight-slot routing in both contexts; no generated key shortcuts.
local expected={[1]='slowenter all once',[2]='npcmirror status',[3]='slowenter all once esc',[4]='npcmirror call',
    [5]='npcmirror enter',[6]='npcmirror stop',[7]='npcmirror esc',[8]='npcmirror interact'}
bank:edge(14,true);bank:edge(12,true)
for b=1,8 do bank:edge(b,true);bank:edge(b,false);assert(executed[#executed]==expected[b]) end
assert(#bank.output.pending==0)
bank:cancel()
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local a=assert(source:find("    elseif command == 'bank' or command == 'l1' or",1,true))
local b=assert(source:find("    elseif command == 'textsettle'",a,true))
local env=setmetatable({xivcrossbar={ready=true},companion_banks=bank,l1_epoch=0,
    l1_drag={finish=function()end},r1_drag={finish=function()end},windower={add_to_chat=function()end}}, {__index=_G})
local dispatch=assert(load('return function(command,...) if false then\n'..source:sub(a,b-1)..'end end','actual bank alias branch','t',env))()
dispatch('r1r2','triangle','Alias test','input /echo alias')
assert(bank:entry('r1r2',8,false).Command=='input /echo alias')
dispatch('r1r2','default','triangle');assert(bank:entry('r1r2',8,false).Command=='npcmirror interact')
dispatch('r1','menu','key','up','Scroll','ctrl+left');assert(bank:entry('r1',4,true).Key=='ctrl+left')
dispatch('l1l2','left','Short','input /echo utility');assert(bank:entry('l1l2',1,false).Command=='input /echo utility')
dispatch('l1','right','Legacy','input /echo compatibility');assert(bank:entry('l1l2',3,false).Command=='input /echo compatibility')
count=saves;dispatch('r1r2');assert(saves==count and bank.active==nil,'bare alias saved settings or claimed hardware receipt')
env.xivcrossbar.ready=false;dispatch('r1r2','status');assert(saves==count)
dispatch('r1r2','triangle','Blocked','input /echo blocked');assert(saves==count)
-- Explicit trigger names also work inside the original, unchanged set API.
local converter=require('gamepad_converter');converter:setup('playstation')
local bound,saved,reloaded
local set_env=setmetatable({gamepad_converter=converter,theme_options={hotbar_number=6},action_manager=require('action_manager'),
    player={add_action=function(_,action,set,bar,slot)bound={action=action,set=set,bar=bar,slot=slot}end,
        save_hotbar=function()saved=true end},reload_hotbar=function()reloaded=true end},{__index=_G})
a=assert(source:find('function set_action_command(args)',1,true));b=assert(source:find('-- command to delete an action',a,true))
assert(load(source:sub(a,b-1),'actual original set binding','t',set_env))()
for name,bar in pairs({l2=1,r2=2,r2l2=3,l2r2=4,l2l2=5,r2r2=6,rr=6,rl=3,lr=4,ll=5}) do
    saved=false;reloaded=false
    set_env.set_action_command({'basic',name,'triangle','ex','input /jump'})
    assert(bound.set=='basic' and bound.bar==bar and bound.slot==8 and bound.action.action=='input /jump')
    assert(bound.action.type=='ex' and saved and reloaded)
end
print('Bank defaults/aliases: v1 adoption, custom/clear preservation, per-context restoration, factory immutability, panel preservation, exact NPC/raw mappings and actual root short-editor dispatch passed.')
