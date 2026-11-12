-- Exercise real UI geometry and drawing proxies with mocked Windower APIs.
dofile('tests/compact.lua')
local presets=require('libs/settings_presets')
local theme=require('theme')
local ui=require('ui')
for _,preset in ipairs({'legacy','default','me'}) do
    local options=theme.apply(presets.values(preset));options.button_layout='playstation'
    -- This fixture tests opt-in label geometry; preset defaults are checked separately.
    options.bank_labels_visible=true;options.set_name_visible=true
    ui:setup(options,{})
    -- The preceding compact fixture leaves this singleton chooser flag true;
    -- a live render pass would synchronize it to the actually closed chooser.
    ui.chooser_open=false
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
    for _,h in ipairs({3,4,7,8,9}) do
        ui.geometry.deferring_hide=true
        ui:update_context_labels(h,true,false)
        assert(not ui.set_name_label:visible(),preset..' combined/shoulder bank hidden')
        assert(not m.defer_visible,'special bank must hide immediately')
        if not ui.is_compact then
            assert(not ui.button_hints.binder_icon:visible() and
                not ui.button_hints.chooser_text:visible(),'full hints hidden')
        end
        ui.geometry.deferring_hide=false
    end
    for _,h in ipairs({5,6}) do
        ui.geometry.deferring_hide=true
        ui:update_context_labels(h,true,false)
        local expected = not options.AutoHideExtraBars
        assert(ui.set_name_label:visible()==expected,preset..' double-tap respects extra bar setting')
        assert(not m.defer_visible,'double-tap context switch must be immediate')
        if not ui.is_compact then
            assert(ui.button_hints.binder_icon:visible()==expected,'full double-tap hint rule')
            assert(ui.button_hints.chooser_text:visible()==expected,'full double-tap hint text rule')
        end
        ui.geometry.deferring_hide=false
    end
    -- The display rule follows the live option, not the preset name.
    ui.AutoHideExtraBars = not ui.AutoHideExtraBars
    ui:update_context_labels(5,true,false)
    assert(ui.set_name_label:visible()==(not ui.AutoHideExtraBars),
        'changing persistent-extra setting changes double-tap caption policy')
    ui.AutoHideExtraBars = options.AutoHideExtraBars
    ui:update_context_labels(1,true,false)
    ui:update_context_labels(1,true,false)
    assert(ui.set_name_label:visible(),'single trigger returns')
    if not ui.is_compact then assert(ui.button_hints.chooser_icon:visible(),'full hint returns') end
    ui:update_context_labels(1,true,true)
    assert(ui.set_name_label:visible(),'binder menu keeps set name')
    if not ui.is_compact then
        assert(not ui.button_hints.binder_text:visible(),'menu still hides hint text')
        assert(not ui.button_hints.chooser_icon:visible(),'menu still hides hint icons')
    end
    ui:set_chooser_open(true)
    ui:update_context_labels(3,true,true)
    assert(ui.set_name_label:visible(),'set chooser keeps name even over combined preview')
    ui:set_set_name('New set from chooser')
    assert(ui.set_name_label:text()=='NEW SET FROM CHOOSER'
        and ui.set_name_label:visible(),'chooser selection refreshes visible caption')
    ui:set_chooser_open(false)
    ui:update_context_labels(0,true,false)
    assert(ui.set_name_label:visible(),'set name returns to idle after menus')
    ui:set_set_name('Travel / Tools')
    ui:set_set_name_visible(false);assert(not ui.set_name_label:visible())
    ui:set_set_name_visible(true);assert(ui.set_name_label:visible())
    ui:set_bank_label_opacity(80)
    assert(m.alpha==80 and m.stroke_alpha==80,'opacity follows bank labels')
    ui:set_bank_label_offset(0,5)
    assert(m.center_y==ui.geometry.surfaces[ui.bank_labels[1]].center_y)
    ui:set_bank_label_offset(0,0)
    local prior_x,prior_y=m.center_x,m.center_y
    local other=ui.geometry.surfaces[ui.bank_labels[1]]
    local bank_x,bank_y=other.center_x,other.center_y
    ui:set_set_name_offset(7,-11)
    assert(m.center_x==prior_x+7 and m.center_y==prior_y-11,'independent set name offset')
    assert(other.center_x==bank_x and other.center_y==bank_y,'bank label unaffected')
    ui:set_set_name_offset(0,0)
    assert(m.center_x==prior_x and m.center_y==prior_y,'reset offset')
    ui:set_compact(not ui.is_compact)
    assert(ui.geometry.surfaces[ui.set_name_label]==m,'mode toggle preserves label')
    assert(m.center_y==ui.geometry.surfaces[ui.bank_labels[1]].center_y)
end
print('Set-name HUD: shared anchors, label style, context visibility and toggles passed.')
