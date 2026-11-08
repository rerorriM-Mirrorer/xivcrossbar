local log, handler, saves = {}, nil, 0
windower = {
    register_event = function(name, callback)
        assert(name == 'addon command')
        handler = callback
    end,
    add_to_chat = function(channel, line)
        assert(channel == 0)
        log[#log+1] = line
    end,
}
local settings = {ControllerProfile = 'ps5-directinput', InputTest = false, InputTrace = true}
local theme_options = {button_layout = 'playstation'}
local file = assert(io.open('xivcrossbar.lua'))
local source = file:read('*a')
file:close()
local first = assert(source:find("windower.register_event('addon command', function(command, ...)", 1, true))
local last = assert(source:find('local shifted_keys', first, true))
local env = setmetatable({
    settings = settings,
    theme_options = theme_options,
    chat_format = require('libs/chat_status'),
    command_help = require('libs/command_help'),
    config = {save = function() saves = saves + 1 end},
}, {__index = _G})
assert(load(source:sub(first, last-1), 'addon command', 't', env))()

local function run(...)
    log = {}
    handler(...)
    return table.concat(log, '\n')
end

local function contains(output, expected)
    assert(output:find(expected, 1, true), 'Missing '..expected..' in '..output)
end

local intro = run()
assert(#log == 6)
contains(intro, 'Getting Started')
contains(intro, 'Share')
contains(intro, 'Options')
contains(intro, 'help <topic>')
assert(run('help') == intro and run('?') == intro)
contains(run('typo'), 'Unknown command "typo".\n'..intro)
contains(run('help', 'typo'), 'Unknown help topic "typo".\n'..intro)
contains(run('help', 'sets', 'extra'), 'Unknown help topic "sets extra".\n'..intro)
local all = run('help', 'ALL')
for topic, title in pairs({
    sets = 'Crossbar Sets', bindings = 'Slot Bindings', display = 'Display',
    controller = 'Controller', diagnostics = 'Diagnostics',
}) do
    local page = run('help', topic)
    assert(#log > 1 and log[1]:find(title, 1, true))
    contains(all, page)
end
contains(run('help', 'display'), 'lockout [on|off|status|0-255]')
theme_options.button_layout = 'xbox'
settings.ControllerProfile = 'xinput'
intro = run()
contains(intro, 'LT/RT')
contains(intro, 'View (Back)')
contains(intro, 'Menu (Start)')
settings.ControllerProfile = 'xinput-r1-chooser'
contains(run(), 'Hold RB')
theme_options.button_layout = nil
contains(run(), 'Getting Started')

contains(run('inputtest', 'typo'), 'Use //xb inputtest [on|off|status].')
contains(run('inputtrace', 'off', 'extra'), 'Use //xb inputtrace [on|off|status].')
contains(run('inputtest', 'status'), 'OFF')
contains(run('inputtrace', 'status'), 'ON')
assert(settings.InputTest == false and settings.InputTrace == true and saves == 0)
contains(run('inputtest', 'ON'), 'ON')
contains(run('inputtrace', 'off'), 'OFF')
contains(run('inputtest'), 'OFF')
assert(settings.InputTest == false and settings.InputTrace == false and saves == 3)
print('Command help: short guide, errors, topic pages, controller labels and input option validation passed.')
