-- A: hardware selection is separate from button artwork and Lua menu routing.
local M = {}
M.order = {'ps5-directinput', 'f710-directinput', 'fightpadpro-directinput', 'xinput', 'xinput-r1-chooser'}
M.profiles = {
    ['ps5-directinput'] = {backend='directinput', label='PS5 DirectInput', experimental=false},
    ['f710-directinput'] = {backend='directinput', label='F710 DirectInput', experimental=true},
    ['fightpadpro-directinput'] = {backend='directinput', label='FightPadPro DirectInput', experimental=true},
    ['xinput'] = {backend='xinput', label='XInput', experimental=true},
    ['xinput-r1-chooser'] = {backend='xinput', label='XInput R1 chooser', experimental=true},
}
M.aliases = {ps5='ps5-directinput', f710='f710-directinput',
    fightpadpro='fightpadpro-directinput', xinput='xinput', xinputalt='xinput-r1-chooser'}
function M.short_name(name)
    for short, canonical in pairs(M.aliases) do if canonical == name then return short end end
    return name
end
function M.validate(name, device)
    name = type(name) == 'string' and name:lower() or ''
    name = M.aliases[name] or name
    local profile = M.profiles[name]
    if not profile then return nil, 'Unknown controller profile.' end
    device = tonumber(device or 1)
    local maximum = profile.backend == 'xinput' and 4 or 16
    if not device or device % 1 ~= 0 or device < 1 or device > maximum then
        return nil, 'Controller device must be an integer from 1 to ' .. maximum .. '.'
    end
    return name, device
end
-- A: file associations/launchers may omit command-line arguments for .ahk files.
-- Write only validated values before launching; the running reader never rereads it.
function M.write_launch(path, profile, device, modifier)
    local name, number = M.validate(profile, device)
    if not name or (modifier ~= 'apps' and modifier ~= 'ctrl') then
        return false, 'Invalid wrapper startup selection.'
    end
    local f, err = io.open(path, 'w')
    if not f then return false, err end
    local ok, write_err = f:write('[Controller]\nprofile=' .. name .. '\ndevice=' .. number .. '\nmodifier=' .. modifier .. '\n')
    f:close()
    if not ok then return false, write_err end
    return true
end
function M.read_status(path, now)
    local f = io.open(path, 'r')
    if not f then return nil end
    local contents = f:read('*a'); f:close()
    local result = {}
    for key, value in contents:gmatch('([%a_]+)=([^\r\n]*)') do result[key] = value end
    local timestamp = tonumber(result.timestamp)
    if not timestamp or not result.profile or not result.state then return nil end
    local age = (now or os.time()) - timestamp
    result.fresh = age >= -2 and age <= 5
    result.running = result.fresh and result.state ~= 'stopped' and (tonumber(result.pid) or 0) > 0
    return result
end
function M.matches(status, profile, device, modifier)
    return status and status.running and status.profile == profile
        and tonumber(status.device) == tonumber(device) and status.modifier == modifier
end
return M
