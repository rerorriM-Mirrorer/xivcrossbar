-- Execute the actual shared CLI handlers and action callback under narrow mocks.
-- This guards both the public three-bar and personal six-bar configurations.
local f = assert(io.open('xivcrossbar.lua'))
local source = f:read('*a')
f:close()

local function between(first, following)
    local a = assert(source:find(first, 1, true), 'missing source start: ' .. first)
    local b = assert(source:find(following, a + #first, true), 'missing source end: ' .. following)
    return source:sub(a, b - 1)
end

local messages, operations, reloads, saves, selected = {}, {}, 0, 0, nil
local player = {id = 42, hotbar_settings = {active_environment = 'default'}}
function player:get_id() return self.id end
function player:add_action(...) operations[#operations + 1] = {'set', ...} end
function player:copy_action(...) operations[#operations + 1] = {'copy', ...} end
function player:set_action_alias(...) operations[#operations + 1] = {'alias', ...} end
function player:set_action_icon(...) operations[#operations + 1] = {'icon', ...} end
function player:save_hotbar() saves = saves + 1 end

local theme_options = {hotbar_number = 6, spell_lockout_duration = 3}
local env = setmetatable({
    player = player,
    theme_options = theme_options,
    print = function(message) messages[#messages + 1] = message end,
    kebab_casify = function(value) return value:lower():gsub(' ', '-'):gsub("'", '') end,
    is_valid_environment = function(key) return key == 'default' or key == 'boss-setup' end,
    set_active_environment = function(key) selected = key end,
    gamepad_converter = {
        convert_to_crossbar = function(_, value) return tonumber(value) end,
        convert_to_slot = function(_, value) return tonumber(value) end,
    },
    action_manager = {build = function(_, kind, value) return {type = kind, action = value} end},
    reload_hotbar = function() reloads = reloads + 1 end,
}, {__index = _G})

assert(load(between('function switch_environment_command(args)', '-- Custom Action field-set chat command.'),
    'actual command handlers', 't', env))()
assert(source:find("elseif command == 'sw' or command == 'switch' then\n        switch_environment_command(args)", 1, true),
    'both switch aliases must use the validated handler')

env.switch_environment_command({})
assert(selected == nil and messages[#messages]:find('switch <crossbar_set>', 1, true))
env.switch_environment_command({'Boss', 'Setup'})
assert(selected == 'boss-setup', 'multiword set must use its normalized storage key')
env.switch_environment_command({'unknown'})
assert(selected == 'boss-setup' and messages[#messages]:find('not a valid crossbar set', 1, true))
env.switch_environment_command({'DEFAULT'})
assert(selected == 'default')

env.set_action_command({'default', '6', '1', 'ma', 'Cure'})
assert(operations[#operations][1] == 'set' and operations[#operations][3] == 'default')
env.copy_action_command({'default', '6', '1', 'default', '5', '2'}, false)
assert(operations[#operations][1] == 'copy' and operations[#operations][3] == 6
    and operations[#operations][6] == 5)
env.update_alias_command({'default', '6', '2', 'Healing'})
assert(operations[#operations][1] == 'alias' and operations[#operations][3] == 6)
env.update_icon_command({'default', '6', '2', 'Cure.png'})
assert(operations[#operations][1] == 'icon' and operations[#operations][3] == 6)

local function reject(callback)
    local before = #operations
    callback()
    assert(#operations == before, 'out-of-range command altered a hotbar')
    assert(messages[#messages]:find('Invalid hotbar', 1, true))
end
reject(function() env.copy_action_command({'default', '7', '1', 'default', '6', '1'}, false) end)
reject(function() env.copy_action_command({'default', '6', '1', 'default', '7', '1'}, true) end)
reject(function() env.update_alias_command({'default', '7', '1', 'bad'}) end)
reject(function() env.update_icon_command({'default', '7', '1', 'bad'}) end)
theme_options.hotbar_number = 3
reject(function() env.copy_action_command({'default', '4', '1', 'default', '3', '1'}, false) end)
reject(function() env.update_alias_command({'default', '4', '1', 'bad'}) end)
reject(function() env.update_icon_command({'default', '4', '1', 'bad'}) end)
env.copy_action_command({'default', '3', '1', 'default', '2', '1'}, true)
assert(operations[#operations][1] == 'copy')
assert(reloads == saves and saves == 5, 'only successful edits should save and reload')

local count = 0
source:gsub("windower%.register_event%('action'", function() count = count + 1 end)
assert(count == 1, 'action must have exactly one registered handler')
local on_action, refreshes = nil, 0
player.update_current_spells = function() refreshes = refreshes + 1 end
env.xivcrossbar = {ready = true}
env.resources = {spells = {}}
env.ui = {autoattack = {enabled = false}}
env.aa_record_swing = function() end
env.aa_add_pause_source = function() end
env.aa_clear_pause_after = function() end
env.windower = {
    register_event = function(name, fn)
        assert(name == 'action' and not on_action)
        on_action = fn
    end,
    ffxi = {get_player = function() return {id = 42} end},
}
assert(load(between('local CATEGORY_MELEE = 1', "windower.register_event('incoming chunk'"),
    'actual Windower action handler', 't', env))()
assert(type(on_action) == 'function')
on_action({actor_id = 42, category = 6, param = 999})
assert(refreshes == 1, 'own job ability must refresh spell availability exactly once')
on_action({actor_id = 123, category = 6, param = 999})
on_action({actor_id = 42, category = 1, param = 999})
env.xivcrossbar.ready = false
on_action({actor_id = 42, category = 6, param = 999})
assert(refreshes == 1, 'foreign actors, other categories and pre-login must not refresh')

print('Shared switch/set/copy/alias/icon bounds and action-table regressions passed.')
