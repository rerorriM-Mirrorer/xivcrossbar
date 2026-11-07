local banks = require('shoulder_banks')
local settings = require('defaults').ShoulderBanks
local profile = 'ps5-directinput'
assert(not banks.requested(settings, profile))
assert(not banks.select(settings, profile, {[89]=true}, true))
assert(not banks.targeting(settings, profile, true))
local saves = 0
local function save() saves = saves + 1 end
local function say() end
banks.command(settings, profile, 'targeting', 'on', nil, save, say)
assert(saves == 1 and banks.requested(settings, profile) and banks.targeting(settings, profile, true))
assert(not banks.targeting(settings, profile, false))
assert(not banks.requested(settings, 'xinput-r1-chooser'))
assert(banks.target_action(90, true, false, {}, false) == 'targetnpc')
assert(banks.target_action(90, true, false, {}, true) == 'tab')
assert(not banks.target_action(90, false, false, {}, true))
assert(not banks.target_action(90, true, true, {}, true), 'same-sample chord')
for _, held in ipairs({67,68,87,88,89}) do
    assert(not banks.target_action(90, true, false, {[held]=true}, true))
end
banks.command(settings, profile, 'l1', 'on', nil, save, say)
banks.command(settings, profile, 'l1', 'hide', nil, save, say)
banks.command(settings, profile, 'both', 'on', nil, save, say)
assert(saves == 4)
local selected, visible = banks.select(settings, profile, {[89]=true}, true)
assert(selected == 'L1' and visible == false)
assert(banks.select(settings, profile, {[89]=true,[90]=true}, true) == 'Both')
assert(not banks.select(settings, profile, {[89]=true,[90]=true,[88]=true}, true))
assert(not banks.select(settings, profile, {[89]=true}, false))
assert(not banks.select(settings, 'xinput-r1-chooser', {[89]=true,[90]=true}, true))
print('Shoulder banks: settings, targeting press and chord policy, chooser conflict and trigger priority passed.')
