local presets=require('libs/settings_presets')
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a)do if not equal(v,b[k]) then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
for _,from in ipairs({'legacy','default','me'})do
    for _,to in ipairs({'legacy','default','me'})do
        local settings={ControllerProfile='xbox-xinput',ControllerDevice=4,InputTest=true,InputTrace=false}
        presets.apply(settings,from);presets.apply(settings,to)
        local expected=presets.values(to)
        expected.ControllerProfile,expected.ControllerDevice,expected.InputTest='xbox-xinput',4,true
        assert(equal(settings,expected),from..' -> '..to..' must be repeatable')
        settings.Animation.SlotGlow=false
        assert(presets.values(to).Animation.RecastFlash==(to~='legacy'),'no mutation of preset templates')
    end
end
local legacy,public,me=presets.values('legacy'),presets.values('default'),presets.values('me')
assert(not legacy.EventBars and legacy.VisibilityMode=='always' and not legacy.AutoHideExtraBars)
assert(legacy.LegacyExtraBars and legacy.HotbarOffsets.DoublePress.Y==-180)
assert(public.EventBars and public.AutoHold==0 and public.DisplayPreset=='xi')
assert(not public.ShoulderBanks.L1.Enabled and not public.ShoulderBanks.Targeting)
assert(me.StartupEnvironment=='job-sub' and not me.UseSharedSet and me.AutoHold==3)
assert(me.LockoutOpacity==0 and me.ShoulderBanks.L1.Enabled)
for _,p in ipairs({legacy,public,me})do
    assert(p.Animation.RecastFlash==(p.SettingsPreset~='legacy') and p.Texts.BankLabelOpacity==60)
end
assert(not presets.apply({},'new'))
assert(require('defaults').SettingsPreset=='default')
-- Exercise the real chooser selection without its image dependencies.
local f=assert(io.open('environment_chooser.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('function env_chooser:get_default_active_environment',1,true))
local b=assert(source:find('function env_chooser:get_player_environments',a,true))
local chooser={}
local e=setmetatable({env_chooser=chooser,default_hotbars={default=true,['job-default']=true,['all-jobs-default']=true,shared=true},
    kebab_casify=function(s)return s end,L=function()
        return setmetatable({},{__index={append=table.insert,sort=table.sort}})
    end},{__index=_G})
assert(load(source:sub(a,b-1),'startup chooser','t',e))()
local bars={basic={},default={},travel={}}
assert(chooser:get_default_active_environment(bars,'legacy')=='basic')
assert(chooser:get_default_active_environment(bars,'job-sub')=='default')
bars.default=nil;assert(chooser:get_default_active_environment(bars,'job-sub')=='basic')
print('Settings presets: all nine transitions, hardware preservation, defaults, personal overrides and real startup selection passed.')
