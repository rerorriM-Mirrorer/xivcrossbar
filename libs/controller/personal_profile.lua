-- A: personal-build migration. Old base-PS5 selections adopt the extended
-- default once; explicit choices made afterward remain authoritative.
local M = {}
function M.normalize(settings, defaults, profiles)
    local profile,device = profiles.validate(settings.ControllerProfile,settings.ControllerDevice)
    local notice
    if not profile then
        profile,device = profiles.validate(defaults.ControllerProfile,defaults.ControllerDevice)
        notice = 'Invalid controller selection; using '..profile..' device '..device..'.'
    end
    local changed = settings.ControllerProfile~=profile or settings.ControllerDevice~=device
    if defaults.ControllerProfile=='ps5-extended' and settings.PersonalProfileMigrated~=true then
        if profile=='ps5-directinput' then profile='ps5-extended' end
        settings.PersonalProfileMigrated=true
        changed=true
    end
    settings.ControllerProfile,settings.ControllerDevice=profile,device
    -- A: adopt the requested R3-only experiment once, including saved Test 4
    -- configurations. Later explicit r2/r3/both choices remain authoritative.
    if settings.PersonalTargetR3Migrated~=true then
        settings.ControllerTargetR2=false
        settings.ControllerTargetR3=true
        settings.PersonalTargetR3Migrated=true
        changed=true
    end
    return changed,notice
end
return M
