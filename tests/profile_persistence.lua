package.loaded.socket={gettime=function()return 1 end}
-- Real root startup policy and config refresh callback, with Windower I/O mocked.
-- Simulate old character overrides being reloaded after addon initialization.
local fixture={ControllerProfile='ps5-directinput',ControllerDevice=1,
    CrossbarScale=.6,iscompact=false,VisibilityMode='hidden',
    Hotbar={Number=4},Color={MpCost={Red=12,Green=34,Blue=56}}}
local saved,refresh=0,nil
config={load=function() return fixture end,save=function(t)
    assert(t==fixture);saved=saved+1
    assert(t.CrossbarScale==.6 and t.iscompact==false and t.VisibilityMode=='hidden')
    assert(t.Hotbar.Number==4,'saved bar count was overwritten by new defaults')
    assert(t.Color.MpCost.Red==12 and t.Color.MpCost.Green==34 and t.Color.MpCost.Blue==56)
end,register=function(t,fn) assert(t==fixture);refresh=fn end}
-- Startup now registers the optional render-trace frame observer too. Register
-- without running its callback; this fixture tests settings, not native frames.
windower={addon_path='addon/',create_dir=function()end,ffxi={get_info=function()return{logged_in=false}end},add_to_chat=function() end,register_event=function() end}
-- Bank persistence has separate migration tests; this fixture isolates profile
-- adoption while still exercising the real root initialization/callback.
package.loaded['libs/windows_file']={new=function()return{}end}
package.loaded['libs/banks/storage']={new=function()return{state={},prepare=function()end,refresh=function()end}end}
xml={parse=function()end}
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local start=assert(source:find("local defaults = require('libs/defaults')",1,true))
local stop=assert(source:find('-- A: immutable',start,true))
local block=assert(load(source:sub(start,stop-1)..'\nreturn settings'))
assert(block()==fixture)
assert(fixture.ControllerProfile=='ps5-extended' and fixture.PersonalProfileMigrated==true)
assert(saved==1 and refresh)
refresh();assert(saved==1,'unchanged refresh must not rewrite settings')
fixture.ControllerProfile='ps5-directinput';fixture.PersonalProfileMigrated=false
refresh();assert(fixture.ControllerProfile=='ps5-extended' and saved==2,'old character section reverted profile')
fixture.ControllerProfile='ps5-directinput';fixture.PersonalProfileMigrated=true
refresh();assert(fixture.ControllerProfile=='ps5-directinput' and saved==2,'explicit later base selection overwritten')
fixture.ControllerProfile='xinput';fixture.ControllerDevice=2;fixture.PersonalProfileMigrated=false
refresh();assert(fixture.ControllerProfile=='xinput' and fixture.ControllerDevice==2,'alternate reader changed')
fixture.TextSettling=false;refresh();assert(not require('ui/text_measure').enabled)
fixture.TextSettling=true;refresh();assert(require('ui/text_measure').enabled)
local profiles=require('libs/controller/profiles')
local policy=require('libs/controller/personal_profile')
-- Isolate profile adoption from the later, independently tested target migration.
local public={ControllerProfile='ps5-directinput',ControllerDevice=1,PersonalTargetR3Migrated=true}
assert(policy.normalize(public,{ControllerProfile='ps5-directinput',ControllerDevice=1},profiles)==false)
assert(public.PersonalProfileMigrated==nil,'public defaults acquired private migration')
local function copy(t)
    local out={};for k,v in pairs(t) do out[k]=type(v)=='table' and copy(v) or v end;return out
end
local current=copy(require('libs/defaults'));current.CrossbarScale=.6;current.Style.OffsetX=37
_G.current_settings=current
windower.ffxi={get_player=function() return {name='Test',main_job='BST',id=123} end,get_info=function() return {logged_in=true,server=1,zone=100} end}
windower.ffxi.get_mob_by_id=function()return{name='Test',id=123}end
windower.get_windower_settings=function() return {ui_x_res=1280,ui_y_res=720} end
resources={servers={[1]={en='Fenrir'}}}
buttonmapping={validate=function() return true end,button_layout='playstation'}
local seen
action_binder={setup=function(_,_,_,_,options) seen=options end}
player={initialize=function() end,load_hotbar=function() return false end}
xivcrossbar={}
local first=assert(source:find('function initialize(',1,true))
local last=assert(source:find('-- A: recover the earlier personal',first,true))
local init=assert(load("local character_identity=require('libs/character_identity');local storage={};local settings=current_settings;local theme=require('ui/theme');local theme_options={crossbar_scale=1};local y_adjust=450;\n"..
    source:sub(first,last-1)..'\nreturn initialize'))()
init(1,'Test',123)
assert(seen.crossbar_scale==.6 and seen.offset_x==37,'pre-login cached theme replaced character appearance')
print('Profile migration, character refresh, explicit choice and unrelated settings preservation passed.')
