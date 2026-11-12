local schema=require('libs/settings_schema')
local function merge(a,b)
    for k,v in pairs(b)do
        if type(v)=='table' and type(a[k])=='table' then merge(a[k],v)else a[k]=v end
    end
    return a
end
-- Real XML parser uses lower-case keys. Each scope must be translated first.
local global=schema.decode({visibility='Show',texts={labelopacity=60,crossbarlabels=true},crossbar={labels=true,costs=false,hideemptyslots=true},layout='Full',controller='XboxRB'})
assert(global.VisibilityMode=='always' and global.iscompact==false)
assert(global.ControllerProfile=='xinput-r1-chooser')
assert(global.Hotbar.HideActionName==false and global.Hotbar.HideActionCost==true and global.Hotbar.hideemptyslots==true)
-- Windower merge is case-insensitive. Mirror it for mixed old/new scope keys.
local function ci(t)
    local out={};for k,v in pairs(t)do out[k:lower()]=type(v)=='table' and ci(v)or v end;return out
end
local char=schema.decode({visibilitymode='oninput',texts={banklabelopacity=80},hotbar={hideactionname=true}})
local inherited=merge(ci(global),ci(char))
assert(inherited.visibilitymode=='oninput' and inherited.texts.banklabelopacity==80)
assert(inherited.hotbar.hideactionname==true and inherited.hotbar.hideactioncost==true)
local both=schema.decode({Visibility='Auto',VisibilityMode='hidden',Texts={LabelOpacity=70,BankLabelOpacity=20},Crossbar={Labels=false},Hotbar={HideActionName=false}})
assert(both.VisibilityMode=='oninput' and both.Texts.BankLabelOpacity==70 and both.Hotbar.HideActionName)
for _,mode in ipairs({'Show','Hide','Auto'})do
    local out=schema.encode(schema.decode({Visibility=mode,Layout='Compact',Preset='Me',Controller='PS',Device=2,SharedSet=false,Crossbar={Number=6,HideEmptySlots=false,Elements=false,Labels=true,Costs=true,RecastText=true,RecastAnimation=true}}))
    assert(out.Visibility==mode and out.Layout=='Compact' and out.Preset=='Me' and out.Controller=='PS' and out.Device==2)
    assert(out.SharedSet==false and out.Crossbar.HideEmptySlots==false and out.Crossbar.Elements==false)
    assert(out.Crossbar.Labels and out.Crossbar.Costs and out.Crossbar.RecastText and out.Crossbar.RecastAnimation)
    assert(out.DisplayPreset==nil and out.Hotbar==nil and out.VisibilityMode==nil)
end
assert(schema.decode({EventBars=false}).Cutscene==true)
assert(schema.decode({EventBars=true,Cutscene=true}).Cutscene==true)
local settings=require('libs/settings_presets').values('me')
settings.ShoulderBanks.PersonalControls.CameraZoom=true
settings.ShoulderBanks.PersonalControls.TouchpadMap=true
settings.Style.SlotAlpha=100
local saved=schema.encode(settings)
assert(saved.Texts.LabelOpacity==60 and saved.Texts.CrossbarLabels)
assert(saved.buttonbackgroundalpha==nil and saved.TextSettling==nil and saved.Animation.TextFade==nil)
assert(saved.Fading and saved.SlotGlow and saved.RecastFlash and saved.TriggerScale)
local reloaded=schema.finalize(schema.decode(saved))
assert(reloaded.buttonbackgroundalpha==210 and reloaded.Texts.BankLabelOpacity==60 and reloaded.Style.SlotAlpha==100)
assert(reloaded.ShoulderBanks.PersonalControls.CameraZoom and reloaded.ShoulderBanks.PersonalControls.TouchpadMap)
assert(reloaded.ControllerProfile==settings.ControllerProfile and reloaded.SettingsPreset=='me')
assert(reloaded.UseSharedSet==false and reloaded.StartupEnvironment=='job-sub')
assert(reloaded.Animation.TextFade and reloaded.AllowSTPCForSelfTargetedActions)
local legacy=schema.encode(require('libs/settings_presets').values('legacy'))
assert(not legacy.Fading and not legacy.RecastFlash and not legacy.SlotGlow and not legacy.TriggerScale)
assert(not legacy.Texts.CrossbarLabels and not legacy.Texts.SetName and legacy.Cutscene)
-- Encoding must never mutate the live runtime table or unknown advanced values.
settings.Unrecognized={Keep='custom'};schema.encode(settings)
assert(settings.Unrecognized.Keep=='custom' and settings.Texts.BankLabelOpacity==60)
assert(schema.encode(settings).Unrecognized.Keep=='custom')
print('Settings schema: old/new mixed scopes, false values, precedence, preset/visibility/controller round trips and personal zoom/map preservation passed.')

assert(schema.encode({NativeControllerGuard=true},'global').NativeControllerGuard==nil)
assert(schema.encode({NativeControllerGuard=false},'global').NativeControllerGuard==false)
assert(schema.encode({NativeControllerGuard=true},'cioara').NativeControllerGuard==true)
local custom={Color={MpCost={Red=1}},Unrecognized={Keep='yes'}}
assert(schema.encode(custom).Color.MpCost.Red==1 and schema.encode(custom).Unrecognized.Keep=='yes')

local exceptional=schema.encode({SettingsPreset='me',DisplayPreset='legacy',ShoulderBanks={PersonalControls={Enabled=true,CameraZoom=true}}})
assert(exceptional.Preset=='Me' and exceptional.DisplayPreset=='legacy')
assert(schema.decode(exceptional).SettingsPreset=='me' and schema.decode(exceptional).ShoulderBanks.PersonalControls.CameraZoom)

assert(schema.finalize({Hotbar={Number=9}}).Hotbar.Number==5)
for n=3,6 do assert(schema.finalize({Hotbar={Number=n}}).Hotbar.Number==n) end
