-- Exercise the real bank layout against mocked Windower drawing objects.
dofile('tests/compact.lua')
local now = 0
package.loaded.socket = {gettime=function() return now end}
local defaults = require('defaults')
defaults.Hotbar.Number = 6
local options = require('theme').apply(defaults)
options.fade_enabled = false
options.button_layout = 'playstation'
local ui = require('ui')
ui:setup(options, {})
local g = ui.geometry
local left, right = g.banks[1], g.banks[2]
local icon = g.surfaces[ui.hotbars[1].slot_icon[1]]
local timer = g.surfaces[ui.hotbars[1].slot_recast_text[1]]
local special = g.surfaces[ui.hotbars[5].slot_icon[1]]
local function pose(active, visible, auto, menu)
    ui:update_trigger_scale(true, .90, active, visible, auto, menu)
end
local function step(delta)
    now = now + delta
    g:tick()
end
local function near(a,b)
    assert(math.abs(a-b)<.0001, tostring(a)..' ~= '..tostring(b))
end
pose(0, false, true)
near(left.value,.90); near(right.value,.90)
pose(1, true, true)
near(left.value,.90); near(right.value,.90)
assert(left.active and not right.active)
ui:show_bar_background(1)
local field = g.surfaces[ui.bar_background]
assert(field.bank==left and timer.bank==left and special.bank==nil)
step(.06)
near(left.value,.95); near(icon.draw_width,40*g.scale*.95)
local x,y=g:point(left.x,left.y)
local sx,sy=g:point(left.x,left.y,false,left)
near(x,sx); near(y,sy)
step(.07)
near(left.value,1); near(right.value,.90)
pose(0, false, true)
ui:hide()
near(left.value,.90)
assert(not left.active and not icon.visible and g.opacity==0)
pose(2, true, true)
near(right.value,.90)
step(.13)
near(right.value,1); near(left.value,.90)
for _, bank in ipairs({3,4,5,6}) do
    pose(bank, true, true)
    ui:show_bar_background(bank)
    assert(field.bank==nil and g.surfaces[ui.hotbars[bank].slot_icon[1]].bank==nil)
end
pose(0, true, false)
step(.13)
near(left.value,.90); near(right.value,.90)
pose(1, true, false)
step(.13)
near(left.value,1); near(right.value,.90)
pose(0, true, false)
assert(left.active)
step(.13)
near(left.value,.90)
pose(1, true, false, true)
near(left.value,1); near(right.value,1)
g:configure_fade(true)
pose(1, true, false)
assert(not left.active and not right.active)
near(left.value,1); near(right.value,1)
print('Trigger scaling: centered single-bank pop, immediate hide, alternate banks, idle and fade gating passed.')
