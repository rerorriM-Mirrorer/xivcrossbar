-- Optional experimental controls are owned by the Me preset.
local M={}
function M.options(settings)
    local p=settings.ShoulderBanks and settings.ShoulderBanks.PersonalControls
    return p and p.Enabled and p or {}
end
function M.cycle(entries,current,step,hotbar)
    local available={}
    for _,entry in ipairs(entries)do
        if hotbar[entry.key] then available[#available+1]=entry.key end
    end
    if #available==0 then return end
    local index=step>0 and 0 or 1
    for i,key in ipairs(available)do if key==current then index=i;break end end
    return available[(index-1+step)%#available+1]
end
function M.command(settings,feature,value,save,say)
    feature=feature and feature:lower();value=value and value:lower()
    local p=settings.ShoulderBanks.PersonalControls
    if feature=='status' and not value then
        say('Personal controls: '..(p.Enabled and 'ON' or 'OFF')..'; R2 TargetNPC '..tostring(p.R2TargetNPC)..
            '; PS '..tostring(p.PSButton)..'; set cycling '..tostring(p.SetCycling)..'; movement '..p.MovementArm)
        return
    end
    if settings.SettingsPreset~='me' then say('Apply //xb me before changing personal controls.');return end
    local fields={controls='Enabled',r2target='R2TargetNPC',ps='PSButton',sets='SetCycling'}
    if fields[feature] and (value=='on' or value=='off') then p[fields[feature]]=value=='on'
    elseif feature=='movement' and (value=='client' or value=='neutral') then p.MovementArm=value
    else say('//xb me status | controls/r2target/ps/sets <on|off> | movement <client|neutral>');return end
    if feature=='ps' and value=='on' then settings.ControllerBridge.ps='on' end
    save();say('Personal '..feature..': '..value)
end
return M
