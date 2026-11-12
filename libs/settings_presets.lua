-- Complete behavior/appearance presets, independent of saved bindings/hardware.
local M={}
local function copy(v)
    if type(v)~='table' then return v end
    local out={};for k,x in pairs(v)do out[k]=copy(x) end;return out
end
local function merge(to,from)
    for k,v in pairs(from)do
        if type(v)=='table' and type(to[k])=='table' then merge(to[k],v)
        else to[k]=copy(v) end
    end
end
local preserved={ControllerProfile=true,ControllerDevice=true,InputTest=true,InputTrace=true}
function M.values(name)
    if name~='legacy' and name~='default' and name~='me' then return end
    local out=copy(require('libs/preset_base'))
    out.SettingsPreset=name
    out.StartupEnvironment='legacy'
    out.Texts.BankLabelOpacity=60
    out.Animation.RecastFlash=true
    out.Hotbar.Number=5
    out.ShoulderBanks.PersonalControls={Enabled=false,R2TargetNPC=false,PSButton=false,SetCycling=false,CameraZoom=false,TouchpadMap=false,MovementArm='client'}
    if name=='legacy' then
        out.DisplayPreset='legacy';out.VisibilityMode='always'
        out.AutoHideExtraBars=false;out.EventBars=false
        out.AllowSTPCForSelfTargetedActions=false
        out.Animation.Enabled=false;out.Animation.TextFade=false
        -- Full-layout height; the renderer adapts its spread and compact spacing.
        out.HotbarOffsets.DoublePress={X=0,Y=-180}
        out.LegacyExtraBars=true
    else
        out.DisplayPreset='xi';out.iscompact=true;out.EventBars=true
        out.Animation.TriggerScale=true;out.Animation.SlotGlow=true
        out.Texts.SlotLabelAlign='center';out.Texts.SlotLabelOffsetY=-6
        out.Texts.BankLabelOffsetY=-63
        out.Texts.CostOffsetX=-6;out.Texts.CostOffsetY=-28
        if name=='me' then
            merge(out,require('libs/personal_preset'))
            out.ShoulderBanks.PersonalControls={Enabled=true,R2TargetNPC=false,PSButton=true,SetCycling=true,CameraZoom=true,TouchpadMap=true,MovementArm='neutral'}
            out.ControllerBridge.ps='on'
        end
    end
    out.LegacyExtraBars=out.LegacyExtraBars==true
    return out
end
function M.apply(settings,name)
    local values=M.values(name);if not values then return false end
    for k,v in pairs(values)do if not preserved[k] then settings[k]=copy(v) end end
    return true
end
function M.defaults()
    local values=M.values('default')
    return values
end
return M
