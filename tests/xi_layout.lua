dofile('tests/compact.lua')
local defaults=require('defaults')
local theme=require('theme')
local options=theme.apply(defaults)
options.button_layout='playstation'
options.fade_enabled=false
options.is_compact=true
options.slot_spacing=6
options.hotbar_spacing=56
options.hotbar_number=6
options.UseAltLayout=false
local ui=require('ui')
ui:setup(options,{})
local legacy_x,legacy_y=ui:get_slot_x(1,1),ui:get_slot_y(1,4)
local icon=ui.hotbars[1].slot_icon[1]
local xi=theme.display_palette('xi')
ui:set_display_layout(xi,true)
assert(ui:get_slot_x(1,2)-ui:get_slot_x(1,1)==40)
assert(ui:get_slot_x(2,1)-ui:get_slot_x(1,7)-40==16)
assert(ui:get_slot_y(1,2)-ui:get_slot_y(1,4)-40==4)
assert(ui.hotbars[1].slot_icon[1]==icon)
assert(ui.geometry.surfaces[icon].x==ui:get_slot_x(1,1))
ui:show_bar_background(1)
local field=ui.geometry.surfaces[ui.bar_background]
assert(field.path:find('xi-bar_bg_compact.png',1,true) and field.width==296)
ui.display_skillchain_indicator=function() end
ui.display_aa_indicator=function() end
local actions={basic={hotbar_1={slot_1={type='ct',action='echo bound',source_environment='basic'}}}}
local function draw()
    ui:check_recasts(actions,{},'basic',{}, {active_bar=1},
        {get_skillchain_window=function()return 0,0 end},{})
end
draw()
assert(ui.hotbars[1].slot_frame[1]:path()==ui.frame_image_path)
assert(ui.hotbars[1].slot_frame[2]:path()==ui.empty_frame_image_path)
ui.theme.hide_empty_slots=true
draw()
assert(not ui.hotbars[1].slot_frame[2]:visible())
ui:set_display_layout(nil,true)
draw()
assert(ui:get_slot_x(1,1)==legacy_x and ui:get_slot_y(1,4)==legacy_y)
assert(ui.geometry.surfaces[icon].x==legacy_x)
assert(ui.hotbars[1].slot_frame[2]:path()==ui.frame_image_path)
assert(not field.path:find('xi-',1,true) and field.width==330)
options.UseAltLayout=true
options.display_palette=xi
ui:setup(options,{})
ui:show_bar_background(1)
assert(not ui.bar_background:visible())
assert(ui.bar_background_left:visible() and ui.bar_background_right:visible())
assert(ui.bar_background_right:path():find('xi-bar_bg_compact_alt.png',1,true))
ui:show_bar_background(3)
assert(ui.bar_background:visible() and not ui.bar_background_right:visible())
print('XI compact spacing, Legacy reversibility, empty frames and fitted trigger fields passed.')
