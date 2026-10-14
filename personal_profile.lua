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
    return changed,notice
end
return M
