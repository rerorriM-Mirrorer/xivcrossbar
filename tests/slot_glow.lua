dofile('tests/compact.lua')
local now = 0
package.loaded.socket = {gettime=function() return now end}
local defaults = require('defaults')
defaults.Hotbar.Number = 2
local options = require('theme').apply(defaults)
options.button_layout = 'playstation'
options.fade_enabled = false
options.slot_pulse_enabled = true
local ui = require('ui')
ui:setup(options, {})
local g = ui.geometry
g:set_opacity(1)
assert(not ui.glow_views[1], 'opt-in allocates no glow views while disabled')
ui:set_slot_glow_enabled(true)
local glow = ui.glow_views
ui:set_slot_glow_enabled(true)
assert(glow[1]==ui.glow_views[1])
ui.display_skillchain_indicator=function() end
ui.display_aa_indicator=function() end
local skills = {get_skillchain_window=function() return 0,0 end}
local consumables = {get_item_count_by_name=function() return 0 end}
local hotbar = {basic={hotbar_1={
    slot_1={type='ct',action='echo Ready',source_environment='basic'},
    slot_2={type='item',action='Potion',source_environment='basic'},
}}}
local function draw(active, menu)
    ui:check_recasts(hotbar, {}, 'basic', {}, {active_bar=active}, skills, consumables, false, false, menu)
    ui:show_slot_pulse(menu)
end
for slot=1,3 do ui:press_slot_pulse(1,slot) end
draw(1)
assert(glow[1]:visible() and glow[2]:visible() and glow[3]:visible())
assert(glow[1]:alpha()>glow[2]:alpha() and glow[2]:alpha()>glow[3]:alpha())
local frame = g.surfaces[glow[1]]
assert(frame.bank==g.banks[1] and ui.pulse_views[1]:visible())
assert(frame.path:find('images/assets/slot-glow.png',1,true))
assert(frame.width==48 and frame.height==48)
assert(frame.x==ui:get_slot_x(1,1)-4 and frame.y==ui:get_slot_y(1,1)-4)
assert(ui.pulse_views[1]:alpha()==180)
local bright=glow[1]:alpha()
now=.2;draw(1)
assert(ui.pulse_views[1]:alpha()==96)
assert(glow[1]:visible() and glow[1]:alpha()==bright and bright==250)
ui:release_slot_pulse(1);draw(1)
assert(not glow[1]:visible() and ui.pulse_views[1]:visible() and glow[2]:visible())
draw(1,true)
assert(not glow[2]:visible())
draw(1)
ui:set_slot_pulse_enabled(false);draw(1)
assert(not ui.pulse_views[2]:visible() and glow[2]:visible())
ui:set_compact(not ui.is_compact)
local moved = g.surfaces[glow[2]]
assert(moved.x==ui:get_slot_x(1,2)-4 and moved.y==ui:get_slot_y(1,2)-4)
ui:clear_slot_pulses()
assert(not glow[2]:visible() and not glow[3]:visible())
print('Gold slot border: eligibility levels, independent holds, release, layer controls and cleanup passed.')
