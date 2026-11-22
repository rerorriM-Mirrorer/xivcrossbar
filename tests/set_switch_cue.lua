-- 2026-11-21 (A): set-switch cue. On a real set change the set name's stroke
-- brightens and its opacity lifts briefly, then both return exactly to the
-- configured values; the banks start 1 screen pixel up and settle into place
-- through their own channel, so trigger scale and slides are not replaced.
dofile('tests/compact.lua')
local now = 10
package.loaded['socket'] = {gettime=function() return now end}
local presets = require('libs/settings_presets')
local theme = require('theme')
local ui = require('ui')
local options = theme.apply(presets.values('default')); options.button_layout = 'playstation'
options.bank_labels_visible = true; options.set_name_visible = true
ui:setup(options, {})
ui.chooser_open = false
ui.public_visible = true
ui:set_set_name('Melee')
local label = ui.set_name_label
local m = ui.geometry.surfaces[label]
local base = ui.bank_label_opacity
assert(base > 0 and base < 255, 'preset label opacity is partial: ' .. tostring(base))

local function stroke() return {label:stroke_color()} end
local resting = stroke()

-- Flash: rises, peaks, returns exactly.
ui:cue_set_switch()
now = now + .06; ui:tick_set_flash()
local peak = m.alpha
assert(peak > base and peak < 255, 'opacity lifts part way: ' .. peak)
assert(m.stroke_alpha == peak, 'stroke follows text opacity')
local lit = stroke()
assert(lit[3] and resting[3] and lit[3] > resting[3], 'stroke brightens toward pale gold')
now = now + .2; ui:tick_set_flash()
assert(m.alpha < peak and m.alpha > base, 'falling: ' .. m.alpha)
now = now + .2; ui:tick_set_flash()
assert(ui.set_flash == nil, 'flash ends')
assert(m.alpha == base and m.stroke_alpha == base, 'opacity restored exactly')
local after = stroke()
assert(after[1] == resting[1] and after[2] == resting[2] and after[3] == resting[3], 'stroke colour restored exactly')

-- The label size never changes during the flash (no re-measure / shift).
local size = m.font_size
ui:cue_set_switch(); now = now + .03; ui:tick_set_flash()
assert(m.font_size == size, 'size unchanged')
now = now + 1; ui:tick_set_flash(); ui.geometry:tick()

-- Off switch: no flash, no settle.
ui.set_flash_enabled, ui.set_settle_enabled = false, false
ui:cue_set_switch()
assert(ui.set_flash == nil, 'flash off')
for _, h in ipairs(ui.render_banks) do
    assert(not ui.geometry.banks[h].settle.active, 'settle off')
end
ui.set_flash_enabled, ui.set_settle_enabled = true, true

-- Zero opacity hides the label; the flash must not reveal it.
ui:set_bank_label_opacity(0)
ui:cue_set_switch(); now = now + .06; ui:tick_set_flash()
assert(m.alpha == 0, 'turned-off label stays at zero')
now = now + 1; ui:tick_set_flash(); ui.geometry:tick()
ui:set_bank_label_opacity(base)

-- Settle: one screen pixel up, eased back to the layout position.
local g = ui.geometry
local bank = g.banks[1]
local x0, y0 = g:point(100, 100, false, bank)
ui:cue_set_switch()
local x1, y1 = g:point(100, 100, false, bank)
assert(x1 == x0 and math.abs((y0 - y1) - 1) < 1e-9, 'starts 1 px up: ' .. (y0 - y1))
now = now + .06; g:tick()
local _, y2 = g:point(100, 100, false, bank)
assert(y2 < y0 and y2 > y1, 'settling')
now = now + .1; g:tick()
local _, y3 = g:point(100, 100, false, bank)
assert(y3 == y0 and not bank.settle.active, 'settled exactly')

-- Composes with a held-trigger scale: the settle adds to the scaled point.
g:set_bank_scale(1, 50, 50, 1.1, true)
local _, ys = g:point(100, 100, false, bank)
ui:cue_set_switch()
local _, yss = g:point(100, 100, false, bank)
assert(math.abs((ys - yss) - 1) < 1e-9, 'settle adds to trigger scale')
now = now + 1; g:tick()
local _, ye = g:point(100, 100, false, bank)
assert(ye == ys, 'scale kept after settle')
g:set_bank_scale(1, 50, 50, 1, true)

-- Hiding the HUD mid-flash restores the label style.
ui:cue_set_switch(); now = now + .06; ui:tick_set_flash()
ui:hide()
assert(ui.set_flash == nil and m.alpha == base, 'hide clears the flash')

-- Wiring: only a real change in a running addon cues, like the rumble.
local main = io.open('xivcrossbar.lua'):read('*a')
local cue = main:find("grip_rumble:emit('set')", 1, true)
assert(cue and main:find('ui:cue_set_switch()', cue, true), 'cue beside the set rumble')
assert(main:find('ui:tick_set_flash()', 1, true), 'ticked every frame')
assert(main:find("command == 'setflash' or command == 'setsettle'", 1, true), 'commands')
-- A (2026-11-21): flash on by default, settle off by default.
assert(main:find('settings.SetFlash ~= false', 1, true) and main:find('settings.SetSettle == true', 1, true), 'flash on, settle off by default')
print('set switch cue: ok')
