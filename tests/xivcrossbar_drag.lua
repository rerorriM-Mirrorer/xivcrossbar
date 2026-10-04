local stub = dofile('tests/helpers/windower_stub.lua')
local drag = require('ui_drag')
local enabled, saved, ox, oy = false, 0, 100, 50
local d = drag.new({
    enabled = function() return enabled end,
    bounds = function() return {x=10, y=20, width=200, height=24} end,
    offsets = function() return ox, oy end,
    move = function(x, y) ox, oy = x, y end,
    save = function() saved = saved + 1 end,
})
assert(not d:mouse(1, 20, 25, false)) -- locked: camera input passes through
enabled = true
assert(not d:mouse(1, 900, 900, false)) -- unlocked but outside strip
assert(not d:mouse(4, 20, 25, false)) -- right button is never captured
assert(not d:mouse(1, 20, 25, true)) -- another addon already owns the event
assert(d:mouse(1, 20, 25, false))
assert(d:mouse(0, 60, 15, false))
assert(ox == 140 and oy == 40 and saved == 0)
assert(d:mouse(2, 70, 30, false)) -- release outside the starting strip
assert(ox == 150 and oy == 55 and saved == 1 and not d.gesture)
assert(not d:mouse(0, 80, 40, false))
assert(d:mouse(1, 20, 25, false))
enabled = false
assert(not d:mouse(0, 30, 35, false) and not d.gesture and saved == 2)

-- Real renderer positioning must apply saved offsets once, including reload.
package.loaded.ui = nil
images = require('images')
local ui = require('ui')
ui.theme = {hotbar_number=1, alternate_press_offset_x=0, alternate_press_offset_y=0,
    double_press_offset_x=0, double_press_offset_y=0}
ui.UseAltLayout, ui.is_compact = true, true
ui.hotbar_spacing, ui.slot_spacing = 56, 6
ui.hotbars = {{}}
for _, field in ipairs({'slot_background','slot_icon','slot_frame','slot_recast',
    'slot_warmup','slot_element','slot_text','slot_cost','slot_recast_text'}) do
    ui.hotbars[1][field] = {}
    for i=1,10 do ui.hotbars[1][field][i] = stub.surface() end
end
settings.Style.OffsetX, settings.Style.OffsetY = 150, 55
ui:update_offsets(150, 55)
assert(ui.pos_x == 720 + 150 and ui.pos_y == 960 + 55)
local x, y = ui.pos_x, ui.pos_y
ui:update_offsets(150, 55)
assert(ui.pos_x == x and ui.pos_y == y)
ui:update_offsets(160, 45) -- same absolute values used by binder arrows
assert(ui.pos_x == x + 10 and ui.pos_y == y - 10)
print('PASS: drag capture boundaries, locked pass-through, release/save, cancellation and non-doubling renderer offsets')
