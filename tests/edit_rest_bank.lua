-- A (2026-11-20): in the menu, with no trigger held, the bank holding the
-- selected slot stays on screen when it is a normally hidden bank.
dofile('tests/compact.lua')
local now = 0
package.loaded.socket = {gettime=function() return now end}
local defaults = require('defaults')
defaults.Hotbar.Number = 6
local options = require('theme').apply(defaults)
options.button_layout = 'playstation'
options.fade_enabled = false
local ui = require('ui')
ui:setup(options, {})
ui.geometry:set_opacity(1)
ui.display_skillchain_indicator=function() end
ui.display_aa_indicator=function() end
local skills = {get_skillchain_window=function() return 0,0 end}
local consumables = {get_item_count_by_name=function() return 0 end}
local hotbar = {basic={hotbar_1={slot_1={type='ct',action='echo Ready',source_environment='basic'}}}}

local function draw(preview, destination)
    ui:check_recasts(hotbar, {}, 'basic', {}, {active_bar=0}, skills, consumables, false, false, true,
        preview, nil, 0, destination)
    return ui.pulse_visible_bars
end
local function drawn(bars)
    local list = {}
    for bank=1,9 do if bars[bank] then list[#list+1] = bank end end
    return table.concat(list, ',')
end

-- No selection: the two base bars, as before.
assert(drawn(draw(nil, nil)) == '1,2', drawn(draw(nil, nil)))
assert(not ui.destination_tint:visible())

-- Base-bank selection: unchanged (base bars, no bank background).
assert(drawn(draw(nil, {bank=1, slot=3})) == '1,2')
assert(ui.destination_tint:visible())
assert(not ui.bar_background:visible() and not ui.bar_background_left:visible()
    and not ui.bar_background_right:visible(), 'base selection keeps the old look')

-- Combined bank: stays up after release, with its slot highlighted.
local bars = draw(nil, {bank=3, slot=5})
assert(bars[3] and not bars[1] and not bars[2], drawn(bars))
assert(ui.destination_tint:visible())
assert(ui:menu_rest_bank({bank=4, slot=1}) == 4)

-- Holding another trigger still previews that bank; the selection hides.
bars = draw(2, {bank=3, slot=5})
assert(bars[2] and not bars[3], drawn(bars))
assert(not ui.destination_tint:visible())

-- Releasing again brings the selection's bank back.
bars = draw(nil, {bank=3, slot=5})
assert(bars[3] and ui.destination_tint:visible())

-- Double-tap banks: shown with the base bars unless extra bars auto-hide.
ui.AutoHideExtraBars = false
assert(ui:menu_rest_bank({bank=5, slot=1}) == nil)
bars = draw(nil, {bank=5, slot=1})
assert(bars[5] and bars[1], drawn(bars))
ui.AutoHideExtraBars = true
assert(ui:menu_rest_bank({bank=6, slot=1}) == 6)
bars = draw(nil, {bank=6, slot=1})
assert(bars[6] and not bars[1], drawn(bars))

-- Shoulder banks, when they exist; unknown banks are ignored.
for bank=7,9 do
    if ui.hotbars[bank] then assert(ui:menu_rest_bank({bank=bank, slot=1}) == bank) end
end
assert(ui:menu_rest_bank({bank=42, slot=1}) == nil)
assert(ui:menu_rest_bank(nil) == nil)

print('edit_rest_bank: ok')
