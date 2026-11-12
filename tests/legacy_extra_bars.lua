dofile('tests/compact.lua')
local options=require('theme').apply(require('libs/settings_presets').values('legacy'))
options.button_layout='playstation'
local ui=require('ui');ui:setup(options,{})
for slot=1,8 do
    assert(ui:get_slot_x(5,slot)==ui:get_slot_x(1,slot)-90,'left extra must spread outwards')
    assert(ui:get_slot_x(6,slot)==ui:get_slot_x(2,slot)+90,'right extra must spread outwards')
    assert(ui:get_slot_y(5,slot)==ui:get_slot_y(1,slot)-180)
    assert(ui:get_slot_y(6,slot)==ui:get_slot_y(2,slot)-180)
end
assert(not ui.display_palette and not ui.is_compact)
assert(ui.bar_background:path():find('/ui/bar_bg.png',1,true),'legacy retains original trigger artwork')
local full_y=ui.geometry.surfaces[ui.bank_labels[1]].center_y
assert(full_y==ui:get_slot_y(1,2)+13,'full label placement must stay unchanged')
for cycle=1,3 do
    ui:set_compact(true)
    for slot=1,8 do
        assert(ui:get_slot_x(5,slot)==ui:get_slot_x(1,slot)-90)
        assert(ui:get_slot_x(6,slot)==ui:get_slot_x(2,slot)+90)
        assert(ui:get_slot_y(5,slot)==ui:get_slot_y(1,slot)-108)
        assert(ui:get_slot_y(6,slot)==ui:get_slot_y(2,slot)-108)
    end
    for _,bank in ipairs({1,2,3,5,6})do
        local label=ui.geometry.surfaces[ui.bank_labels[bank]]
        local top=math.min(ui:get_slot_y(bank,2),ui:get_slot_y(bank,4))
        assert(label.center_y==top-6,'compact header must use the XI gap above the bar')
    end
    ui:set_compact(false)
    assert(ui.geometry.surfaces[ui.bank_labels[1]].center_y==full_y)
end
for _,name in ipairs({'default','me'})do
    options=require('theme').apply(require('libs/settings_presets').values(name))
    options.button_layout='playstation';ui:setup(options,{})
    local label=ui.geometry.surfaces[ui.bank_labels[1]]
    assert(label.center_y==math.min(ui:get_slot_y(1,2),ui:get_slot_y(1,4))-6)
    ui:set_compact(false)
    assert(ui.geometry.surfaces[ui.bank_labels[1]].center_y==ui:get_slot_y(1,2)+13,
        name..' full label shares the zero-offset Legacy baseline')
end
print('Legacy extras: outward spread, adaptive compact height, matching XI header gap, reversible toggles and original full artwork/labels passed.')
