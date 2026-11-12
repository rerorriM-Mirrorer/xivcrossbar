-- Exercise real UI geometry and drawing proxies with mocked Windower APIs.
dofile('tests/compact.lua')
local presets=require('libs/settings_presets')
local theme=require('theme')
local ui=require('ui')
for _,preset in ipairs({'legacy','default','me'}) do
    local options=theme.apply(presets.values(preset));options.button_layout='playstation'
    ui:setup(options,{})
    ui.public_visible=true
    ui:set_set_name('Travel / Tools')
    assert(ui.set_name_label:text()=='TRAVEL / TOOLS')
    local m=ui.geometry.surfaces[ui.set_name_label]
    assert(m.font_size==11*.94,'one font size smaller')
    assert(m.alpha==60 and m.stroke_alpha==60,'matches trigger label opacity')
    assert(m.center_x==(ui:get_slot_x(1,7)+40+ui:get_slot_x(2,1))/2)
    assert(m.center_y==ui.geometry.surfaces[ui.bank_labels[1]].center_y)
    for _,h in ipairs({0,1,2}) do
        ui:update_context_labels(h,true,false)
        assert(ui.set_name_label:visible(),preset..' idle/single trigger')
    end
    for _,h in ipairs({3,4,5,6,7,8,9}) do
        ui.geometry.deferring_hide=true
        ui:update_context_labels(h,true,false)
        assert(not ui.set_name_label:visible(),preset..' special bank hidden')
        assert(not m.defer_visible,'special bank must hide immediately')
        if not ui.is_compact then
            assert(not ui.button_hints.binder_icon:visible() and
                not ui.button_hints.chooser_text:visible(),'full hints hidden')
        end
        ui.geometry.deferring_hide=false
    end
    ui:update_context_labels(1,true,false)
    assert(ui.set_name_label:visible(),'single trigger returns')
    if not ui.is_compact then assert(ui.button_hints.chooser_icon:visible(),'full hint returns') end
    ui:update_context_labels(1,true,true)
    assert(not ui.set_name_label:visible(),'menu hides set name')
    ui:update_context_labels(0,true,false)
    ui:set_set_name_visible(false);assert(not ui.set_name_label:visible())
    ui:set_set_name_visible(true);assert(ui.set_name_label:visible())
    ui:set_bank_label_opacity(80)
    assert(m.alpha==80 and m.stroke_alpha==80,'opacity follows bank labels')
    ui:set_bank_label_offset(0,5)
    assert(m.center_y==ui.geometry.surfaces[ui.bank_labels[1]].center_y)
    ui:set_bank_label_offset(0,0)
    ui:set_compact(not ui.is_compact)
    assert(ui.geometry.surfaces[ui.set_name_label]==m,'mode toggle preserves label')
    assert(m.center_y==ui.geometry.surfaces[ui.bank_labels[1]].center_y)
end
print('Set-name HUD: shared anchors, label style, context visibility and toggles passed.')
