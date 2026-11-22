-- A (2026-11-21): a Trust toggle slot plays the success flash once when it
-- changes face, never on first draw or while the face stays the same.
dofile('tests/compact.lua')
local now = 0
package.loaded.socket = {gettime=function() return now end}
local options = require('theme').apply(require('defaults'))
options.button_layout = 'playstation'
options.fade_enabled = false
local ui = require('ui')
ui:setup(options, {})
ui.geometry:set_opacity(1)
ui.display_skillchain_indicator=function() end
ui.display_aa_indicator=function() end
local tc = require('libs/trust_control')
local snap, engaged = {state='pause', intent='none'}, false
tc.shared = function() return {snapshot=function() return snap end} end
tc.engaged = function() return engaged end
local flashes = {}
local real = ui.flash_action_success
ui.flash_action_success = function(self, h, i) flashes[#flashes+1] = h*10+i; return real(self, h, i) end
local skills = {get_skillchain_window=function() return 0,0 end, get_skillchain_result=function() end}
local consumables = {get_item_count_by_name=function() return 0 end}
local hotbar = {basic={hotbar_1={
    slot_1={type='ex',action='trust actall',source_environment='basic'},
    slot_2={type='ex',action='trust startall',source_environment='basic'}}}}
local function draw()
    ui:check_recasts(hotbar, {mp=50,tp=0}, 'basic', {}, {active_bar=1}, skills, consumables,
        false, false, false, nil, nil, 0, nil)
end
draw(); draw()
assert(#flashes == 0, 'no flash on first draw or a repeat')
assert(ui.resolved_slots[9].trust_face == 'ready' and ui.resolved_slots[10].trust_face == 'start')
assert(ui.resolved_slots[10].icon == 'assist', 'Start uses the assist icon')
snap = {state='act', intent='act'}
draw()
assert(#flashes == 2 and flashes[1] == 11 and flashes[2] == 12, 'both faces changed: one flash each')
draw()
assert(#flashes == 2, 'steady face: no repeat')
snap = {state='pause', intent='pause'}
draw()
assert(#flashes == 4, 'Stand Down -> Ready and Stop -> Start flash')
print('Trust toggles: success flash once per face change; Start uses the assist icon.')
