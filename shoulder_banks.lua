local M = {}
local banks = {'L1', 'R1', 'Both'}
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

function M.select(settings, profile, down, eligible)
    if not eligible or down[87] or down[88] or down[67] or down[68] then return end
    local bank = down[89] and (down[90] and 'Both' or 'L1') or down[90] and 'R1'
    if bank and supported(profile, bank) and settings[bank].Enabled then
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

function M.command(settings, profile, section, option, value, save, say)
    section = section and section:lower() or 'status'
    option, value = option and option:lower(), value and value:lower()
    local bank = names[section]
    if section == 'targeting' and not value and (not option or option == 'status' or option == 'on' or option == 'off') then
        if option == 'on' or option == 'off' then
            settings.Targeting = option == 'on'
            save()
        end
        say('R1 targeting '..(settings.Targeting and 'ON' or 'OFF')..
            (supported(profile, 'R1') and '' or ' | RB is reserved for the chooser on this profile.'))
    elseif bank and not value and (option == 'on' or option == 'off' or option == 'show' or option == 'hide') then
        if option == 'on' or option == 'off' then settings[bank].Enabled = option == 'on'
        else settings[bank].Visible = option == 'show' end
        save()
        say(bank..' bank preference saved for the bank UI.')
    elseif section == 'status' and not option and not value then
        M.command(settings, profile, 'targeting', nil, nil, save, say)
        for _, name in ipairs(banks) do
            local state = settings[name]
            say(name..' bank '..(state.Enabled and 'ON' or 'OFF')..' | '..(state.Visible and 'visible' or 'hidden')..
                (supported(profile, name) and '' or ' | unavailable with the RB chooser'))
        end
        say('Bank settings preview. Binding and rendering are pending.')
    else
        say('//xb bank status | targeting [on|off] | <l1|r1|both> <on|off|show|hide>')
    end
end

return M
