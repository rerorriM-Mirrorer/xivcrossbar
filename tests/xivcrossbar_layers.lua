local stub = dofile('tests/helpers/windower_stub.lua')
images = require('images')
package.loaded.player = nil
package.loaded.ui = nil
local player = require('player')
local ui = require('ui') -- Includes the real UI fallback resolver.
local function slot(command) return {action = command, type = 'ex', alias = command} end
player.hotbar = {
    basic = {hotbar_1 = {}}, default = {hotbar_1 = {slot_1 = {}}},
    ['job-default'] = {hotbar_1 = {slot_1 = {}}},
    ['all-jobs-default'] = {hotbar_1 = {slot_1 = slot('npcmirror enter')}},
    shared = {hotbar_1 = {}},
}
player.hotbar_settings.active_hotbar = 1
player.hotbar_settings.active_environment = 'basic'
player:execute_action(1)
assert(stub.commands[#stub.commands] == 'npcmirror enter')
assert(maybe_get_default_action(player.hotbar, 'basic', 1, 1).action == 'npcmirror enter')
player.hotbar['job-default'].hotbar_1.slot_1 = slot('job command')
player:execute_action(1)
assert(stub.commands[#stub.commands] == 'job command')
player.hotbar.default.hotbar_1.slot_1 = slot('default command')
player:execute_action(1)
assert(stub.commands[#stub.commands] == 'default command')
player.hotbar.basic.hotbar_1.slot_1 = slot('own job action')
player:execute_action(1)
assert(stub.commands[#stub.commands] == 'own job action')
local count = #stub.commands
player.hotbar_settings.active_environment = 'shared'
player:execute_action(1)
assert(#stub.commands == count and maybe_get_default_action(player.hotbar, 'shared', 1, 1) == nil)
player:dispatch_action(slot(''))
assert(#stub.commands == count)
print('PASS: job/default/all-jobs precedence, empty slots, isolated Shared and blank-command no-op')

-- Fallback pages themselves must never pull from a more-specific page.
for _, env in ipairs({'default', 'job-default', 'all-jobs-default'}) do
    local own = player.hotbar[env].hotbar_1.slot_1
    player.hotbar[env].hotbar_1.slot_1 = {}
    player.hotbar_settings.active_environment = env
    local before = #stub.commands
    player:execute_action(1)
    local expected = env == 'default' and 'job command' or
        (env == 'job-default' and 'npcmirror enter' or nil)
    assert((#stub.commands > before and stub.commands[#stub.commands] or nil) == expected)
    local visible = maybe_get_default_action(player.hotbar, env, 1, 1)
    assert((visible and visible.action) == expected)
    player.hotbar[env].hotbar_1.slot_1 = own
end

package.loaded.gamepad_converter = nil
local converter = require('gamepad_converter')
converter:setup('playstation')
local slots = {'ll', 'ld', 'lr', 'lu', 'rl', 'rd', 'rr', 'ru'}
local buttons = {'Left', 'Down', 'Right', 'Up', 'Square', 'Cross', 'Circle', 'Triangle'}
for i, name in ipairs(slots) do
    assert(converter:convert_to_slot(name) == i)
    assert(converter:convert_to_slot(buttons[i]) == i)
end
for i, name in ipairs({'l', 'r', 'rl', 'lr', 'll', 'rr'}) do
    assert(converter:convert_to_crossbar(name) == i)
end
ui.UseAltLayout = true
ui.pos_x, ui.pos_y, ui.slot_spacing, ui.hotbar_spacing = 700, 500, 6, 56
ui.is_compact = true
ui.theme.alternate_press_offset_x, ui.theme.alternate_press_offset_y = 0, 0
ui.theme.double_press_offset_x, ui.theme.double_press_offset_y = 0, 0
-- Four horizontal clusters, not a change of physical slot identity.
assert(ui:get_slot_x(1, 1) < ui:get_slot_x(2, 1))
assert(ui:get_slot_x(2, 3) < ui:get_slot_x(1, 5))
assert(ui:get_slot_x(1, 7) < ui:get_slot_x(2, 5))
assert(ui:get_slot_y(1, 4) < ui:get_slot_y(1, 1))
assert(ui:get_slot_y(1, 1) < ui:get_slot_y(1, 2))
print('PASS: fallback-page isolation, XML/button conversion and actual AltLayout geometry')
