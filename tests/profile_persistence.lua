-- Real root startup policy and config refresh callback, with Windower I/O mocked.
-- Simulate old character overrides being reloaded after addon initialization.
local fixture={ControllerProfile='ps5-directinput',ControllerDevice=1,
    CrossbarScale=.6,iscompact=false,VisibilityMode='hidden',
    Color={MpCost={Red=12,Green=34,Blue=56}}}
local saved,refresh=0,nil
config={load=function() return fixture end,save=function(t)
    assert(t==fixture);saved=saved+1
    assert(t.CrossbarScale==.6 and t.iscompact==false and t.VisibilityMode=='hidden')
    assert(t.Color.MpCost.Red==12 and t.Color.MpCost.Green==34 and t.Color.MpCost.Blue==56)
end,register=function(t,fn) assert(t==fixture);refresh=fn end}
windower={add_to_chat=function() end}
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local start=assert(source:find("local defaults = require('defaults')",1,true))
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
local profiles=require('controller_profiles')
local policy=require('personal_profile')
local public={ControllerProfile='ps5-directinput',ControllerDevice=1}
assert(policy.normalize(public,{ControllerProfile='ps5-directinput',ControllerDevice=1},profiles)==false)
assert(public.PersonalProfileMigrated==nil,'public defaults acquired private migration')
local function copy(t)
    local out={};for k,v in pairs(t) do out[k]=type(v)=='table' and copy(v) or v end;return out
end
local current=copy(require('defaults'));current.CrossbarScale=.6;current.Style.OffsetX=37
_G.current_settings=current
windower.ffxi={get_player=function() return {name='Test'} end,get_info=function() return {server=1} end}
windower.get_windower_settings=function() return {ui_x_res=1280,ui_y_res=720} end
resources={servers={[1]={en='Fenrir'}}}
buttonmapping={validate=function() return true end,button_layout='playstation'}
local seen
action_binder={setup=function(_,_,_,_,options) seen=options end}
player={initialize=function() end,load_hotbar=function() return false end}
xivcrossbar={}
local first=assert(source:find('function initialize()',1,true))
local last=assert(source:find('-- trigger hotbar action',first,true))
local init=assert(load("local settings=current_settings;local theme=require('theme');local theme_options={crossbar_scale=1};local y_adjust=450;\n"..
    source:sub(first,last-1)..'\nreturn initialize'))()
init()
assert(seen.crossbar_scale==.6 and seen.offset_x==37,'pre-login cached theme replaced character appearance')
print('Profile migration, character refresh, explicit choice and unrelated settings preservation passed.')
