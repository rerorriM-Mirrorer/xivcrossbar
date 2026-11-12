local M = {}
local banks = {'L1', 'R1', 'Both'}
M.ids = {L1=7, R1=8, Both=9}
M.labels = {[7]='L1', [8]='R1', [9]='L1 + R1'}
local keys = {[7]='hotbar_shoulder-l1', [8]='hotbar_shoulder-r1', [9]='hotbar_shoulder-both'}
function M.destination(environment, bar)
    if keys[bar] then return 'shared', keys[bar] end
    return environment, 'hotbar_'..bar
end
function M.bar(hotbar, environment, bar)
    local key
    environment, key = M.destination(environment, bar)
    return hotbar[environment] and hotbar[environment][key]
end

local names = {l1='L1', r1='R1', both='Both'}
local function supported(profile, bank)
    return profile ~= 'xinput-r1-chooser' or bank == 'L1'
end

function M.requested(settings, profile)
    if settings.Targeting and supported(profile, 'R1') then return true end
    for _, bank in ipairs(banks) do
        if supported(profile, bank) and settings[bank].Enabled then return true end
    end
    return false
end

function M.slot_context(info, actor)
    -- Explicit L1/R1 holds own their eight slots in all in-world states:
    -- chat, FFXI menus, cutscenes, Event status 4, and the death/Raise prompt.
    -- Only actual addon menus and input ownership/focus limit capture.
    return info ~= nil and actor ~= nil
end

function M.capture_mask(settings, profile)
    local mask = 0
    for index, bank in ipairs(banks) do
        if settings[bank].Enabled and supported(profile, bank) then mask = mask + 2^(index-1) end
    end
    return mask
end

function M.select(settings, profile, down, eligible, binding)
    if not eligible or down[67] or down[68] or (not binding and (down[87] or down[88])) then return end
    local bank = down[89] and (down[90] and 'Both' or 'L1') or down[90] and 'R1'
    if bank and supported(profile, bank) and (binding or settings[bank].Enabled) then
        return bank, settings[bank].Visible
    end
end

function M.targeting(settings, profile, eligible)
    return settings.Targeting and eligible and supported(profile, 'R1')
end

function M.target_action(dik, pressed, chord, down, has_target)
    if dik ~= 90 or not pressed or chord or down[89] or down[87] or down[88]
        or down[67] or down[68] then return end
    return has_target and 'tab' or 'targetnpc'
end

function M.target_press(dik, chord, down, has_target)
    if down[67] or down[68] or down[87] or down[88] then return end
    for slot = 59, 66 do
        if down[slot] then return end
    end
    if down[89] and down[90] then return
    elseif not chord and has_target then
        return dik == 89 and 'shift-tab' or 'tab'
    end
end

function M.command(settings, profile, section, option, value, save, say)
    section = section and section:lower() or 'status'
    option, value = option and option:lower(), value and value:lower()
    local bank = names[section]
    if section == 'targeting' and not value and (not option or option == 'status' or option == 'on' or option == 'off') then
        if option == 'on' or option == 'off' then
            settings.Targeting = option == 'on'
            save()
        end
        say('Shoulder targeting '..(settings.Targeting and 'ON' or 'OFF')..
            (supported(profile, 'R1') and '' or ' | RB is reserved for the chooser on this profile.'))
    elseif bank and not value and (option == 'on' or option == 'off' or option == 'show' or option == 'hide') then
        if option == 'on' or option == 'off' then settings[bank].Enabled = option == 'on'
        else settings[bank].Visible = option == 'show' end
        save()
        say(bank..' bank '..option..'.')
    elseif section == 'status' and not option and not value then
        M.command(settings, profile, 'targeting', nil, nil, save, say)
        for _, name in ipairs(banks) do
            local state = settings[name]
            say(name..' bank '..(state.Enabled and 'ON' or 'OFF')..' | '..(state.Visible and 'visible' or 'hidden')..
                (supported(profile, name) and '' or ' | unavailable with the RB chooser'))
        end
    else
        say('//xb bank status | targeting [on|off] | <l1|r1|both> <on|off|show|hide>')
    end
end

return M
