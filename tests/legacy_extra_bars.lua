dofile('tests/compact.lua')
local options=require('theme').apply(require('libs/settings_presets').values('legacy'))
options.button_layout='playstation'
local ui=require('ui');ui:setup(options,{})
for slot=1,8 do
    assert(ui:get_slot_x(5,slot)==ui:get_slot_x(1,slot),'left extra must align horizontally')
    assert(ui:get_slot_x(6,slot)==ui:get_slot_x(2,slot),'right extra must align horizontally')
    assert(ui:get_slot_y(5,slot)==ui:get_slot_y(1,slot)-180)
    assert(ui:get_slot_y(6,slot)==ui:get_slot_y(2,slot)-180)
end
assert(not ui.display_palette and not ui.is_compact)
assert(ui.bar_background:path():find('/ui/bar_bg.png',1,true),'legacy retains original trigger artwork')
print('Legacy extras: both pairs align above regular bars without slot overlap; original full trigger artwork retained.')
