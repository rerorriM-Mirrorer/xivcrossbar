-- A: isolated movement receiver; Trust supports scoped --quiet feedback.
_addon.name = 'TrustMovement'
_addon.author = 'A'
_addon.version = '0.1.1'
_addon.commands = {'trustmovement', 'tm'}

require('chat')
local config = require('config')
local clock = require('socket').gettime
local settings = config.load({mode = 'test', quiet = true})
local signal_dik = 0x7B -- DIK_NOCONVERT, AHK vk1Dsc07B; independent of modifiers.
local received, executed, skipped = 0, 0, 0
local signal_down, lease_path = false, nil
local next_lease, last_ready = 0, nil

local function say(message)
    windower.add_to_chat(0, ('[TrustMovement] '):color(200) .. message)
end

local function mode()
    if settings.mode == 'live' or settings.mode == 'off' then return settings.mode end
    return 'test'
end

local function quiet()
    return settings.quiet ~= false
end

local function block_reason()
    if mode() == 'off' then return 'disabled' end
    if not windower.has_focus() then return 'unfocused' end
    local info = windower.ffxi.get_info()
    if not info or not info.logged_in then return 'logged out' end
    if info.chat_open then return 'chat input' end
    if info.menu_open then return 'game menu' end
    local player = windower.ffxi.get_player()
    if not player then return 'no character' end
    if player.status == 4 then return 'event/cutscene' end
end

local function remove_lease()
    if lease_path then os.remove(lease_path); lease_path = nil end
    last_ready = nil
end

local function publish_lease(force)
    local player = windower.ffxi.get_player()
    if not player or not windower.ffxi.get_info().logged_in then remove_lease(); return end
    local ready = block_reason() == nil
    local now = clock()
    if not force and ready == last_ready and now < next_lease then return end
    next_lease, last_ready = now + 0.25, ready
    local path = windower.addon_path .. 'data/' .. player.name .. '.lease'
    if lease_path and lease_path ~= path then remove_lease() end
    lease_path = path
    local temporary = path .. '.tmp'
    local file = io.open(temporary, 'w')
    if not file then return end
    file:write('name=' .. player.name .. '\ntimestamp=' .. os.time()
        .. '\nready=' .. (ready and '1' or '0') .. '\n')
    file:close()
    -- Windows rename does not replace an existing file. The short gap is
    -- harmless: the reader waits for a complete fresh lease on its next poll.
    os.remove(path)
    os.rename(temporary, path)
end

local function status()
    say('v' .. _addon.version .. ' | mode=' .. mode() .. ' | quiet=' .. (quiet() and 'on' or 'off') .. ' | received=' .. received
        .. ' | executed=' .. executed .. ' | skipped=' .. skipped
        .. ' | ' .. (block_reason() or 'ready'))
end

local function help()
    say(('Commands'):color(167))
    local commands = {
        {'test', 'Diagnostic message only (default).'},
        {'live', 'Movement runs Trust follow me, then assist me.'},
        {'off', 'Disable this receiver.'},
        {'quiet [on|off]', 'Quiet movement acknowledgments locally and on Trust receivers; bare toggles.'},
        {'status', 'Show mode and received signal count.'},
        {'help', 'Show commands.'},
        {'restart', 'Reload this receiver.'},
        {'unload', 'Unload this receiver.'},
    }
    for _, item in ipairs(commands) do
        windower.add_to_chat(0, ('//tm '):color(200) .. item[1]:color(207)
            .. (' -> '):color(200) .. item[2])
    end
end

local function movement()
    received = received + 1
    local reason = block_reason()
    if reason then
        skipped = skipped + 1
        if mode() == 'test' or not quiet() then say('Signal skipped: ' .. reason .. '.') end
        return
    end
    local name = windower.ffxi.get_player().name
    if mode() == 'test' then
        say('Movement received on ' .. name .. ' (#' .. received .. '). TEST: no Trust commands sent.')
        return
    end
    executed = executed + 1
    local flag = quiet() and ' --quiet' or ''
    windower.send_command('lua c trust follow me' .. flag .. '; lua c trust assist me' .. flag)
    if not quiet() then say('Follow/assist requested from ' .. name .. '.') end
end

windower.register_event('keyboard', function(dik, pressed, flags, blocked)
    if dik ~= signal_dik then return end
    -- Consume both edges regardless of Ctrl/Apps/Shift, and debounce repeats.
    -- A fresh foreground check prevents background clients issuing commands.
    if not windower.has_focus() then signal_down = false; return true end
    if pressed then
        if not signal_down then signal_down = true; movement() end
    else
        signal_down = false
    end
    return true
end)

windower.register_event('addon command', function(command, argument)
    command = (command or ''):lower()
    if command == 'test' or command == 'live' or command == 'off' then
        settings.mode = command
        config.save(settings)
        publish_lease(true)
        say('Mode: ' .. command .. '. Switch to another FFXI client and back if this focus already fired.')
    elseif command == 'quiet' then
        argument = argument and argument:lower()
        if argument and argument ~= 'on' and argument ~= 'off' then
            say('Use //tm quiet [on|off].'); help(); return
        end
        if argument == 'on' then settings.quiet = true
        elseif argument == 'off' then settings.quiet = false
        else settings.quiet = not quiet() end
        config.save(settings)
        say('Quiet movement feedback: ' .. (quiet() and 'on' or 'off') .. '.')
    elseif command == 'status' then status()
    elseif command == 'restart' or command == 'unload' then
        remove_lease()
        say(command == 'restart' and 'Restarting.' or 'Unloading.')
        windower.send_command('lua ' .. (command == 'restart' and 'reload' or 'unload') .. ' trustmovement')
    else
        if command ~= '' and command ~= 'help' then say('Unknown command: ' .. command) end
        help()
    end
end)

windower.register_event('load', function()
    windower.create_dir(windower.addon_path .. 'data')
    publish_lease(true)
    say('v' .. _addon.version .. ' | mode=' .. mode() .. '. //tm help')
end)
windower.register_event('prerender', function() publish_lease(false) end)
windower.register_event('gain focus', function() signal_down = false; publish_lease(true) end)
windower.register_event('lose focus', function() signal_down = false; publish_lease(true) end)
windower.register_event('logout', remove_lease)
windower.register_event('unload', remove_lease)
