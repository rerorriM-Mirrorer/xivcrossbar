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
local expected={'L2','R2','R2>L2','L2>R2','L2x2','R2x2'}
for bank,caption in ipairs(expected) do
    local label=ui.bank_labels[bank]
    assert(label:text()==caption and not label:visible())
    assert(ui.geometry.surfaces[label].bank==ui.geometry.banks[bank])
end
local label=ui.bank_labels[1]
local function check_label_anchor(bank)
    local m=ui.geometry.surfaces[ui.bank_labels[bank]]
    assert(m.center_x==(ui:get_slot_x(bank,2)+ui:get_slot_x(bank,6))/2+20)
    assert(m.center_y==ui:get_slot_y(bank,2)+13)
end
check_label_anchor(1)
local function check_stroke(view, r, g, b)
    local red,green,blue=view:stroke_color()
    assert(red==r and green==g and blue==b)
end
local slot_caption=ui.hotbars[1].slot_text[1]
local recast_caption=ui.hotbars[1].slot_recast_text[1]
check_stroke(label,255,216,112)
check_stroke(slot_caption,20,20,20)
ui:set_slot_label_stroke('amber')
check_stroke(slot_caption,143,89,30)
check_stroke(label,255,216,112)
check_stroke(recast_caption,20,20,20)
ui:set_slot_label_stroke('black')
check_stroke(slot_caption,20,20,20)
local legacy_x,legacy_y=ui:get_slot_x(1,1),ui:get_slot_y(1,4)
local icon=ui.hotbars[1].slot_icon[1]
local xi=theme.display_palette('xi')
ui:set_display_layout(xi,true)
assert(ui.bank_labels[1]==label)
check_label_anchor(1)
local bank_surface=ui.geometry.surfaces[label]
local slot_surface=ui.geometry.surfaces[slot_caption]
local bank_x,bank_y=bank_surface.center_x,bank_surface.center_y
ui:set_bank_label_offset(3,-9)
assert(bank_surface.center_x==bank_x+3 and bank_surface.center_y==bank_y-9)
ui:set_bank_label_offset(0,0)
ui:set_slot_label_layout('center',4,6)
assert(slot_surface.center_x==ui:get_slot_x(1,1)+24 and slot_surface.center_y==ui:get_slot_y(1,1)+46)
ui:set_slot_label_layout('left',4,6)
assert(not slot_surface.center_x and slot_surface.x==ui:get_slot_x(1,1)+2
    and slot_surface.y==ui:get_slot_y(1,1)+46)
ui:set_slot_label_layout('left',0,0)
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
assert(label:visible() and ui.bank_labels[2]:visible() and not ui.bank_labels[3]:visible())
ui.geometry.deferring_hide=true
ui:set_bank_labels_visible(false)
assert(not ui.geometry.surfaces[label].defer_visible)
draw()
assert(not label:visible() and ui.hotbars[1].slot_icon[1]:visible())
ui.geometry.deferring_hide=false
ui:set_bank_labels_visible(true)
draw()
assert(label:visible())
ui:set_bank_label_opacity(160)
assert(bank_surface.alpha==160 and bank_surface.stroke_alpha==160)
ui.geometry:set_opacity(.5)
assert(bank_surface.draw_alpha==80 and bank_surface.draw_stroke_alpha==80)
ui:set_bank_label_opacity(0)
draw()
assert(not label:visible() and ui.hotbars[1].slot_icon[1]:visible())
ui:set_bank_label_opacity(255)
ui.geometry:set_opacity(1)
draw()
assert(label:visible())
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
options.hotbar_number=5
ui:setup(options,{})
assert(ui.bank_labels[3]:text()=='R2+L2' and not ui.bank_labels[4])
options.hotbar_number=2
options.shoulder_banks=true
ui:setup(options,{})
assert(ui.hotbars[7] and not ui.hotbars[3], 'shoulder setup keeps the original bar count')
assert(ui.bank_labels[7]:text()=='L1' and ui.bank_labels[8]:text()=='R1'
    and ui.bank_labels[9]:text()=='L1+R1')
check_label_anchor(7)
assert(ui:get_slot_x(7,1)==ui:get_slot_x(3,1) and ui:get_slot_y(9,8)==ui:get_slot_y(3,8))
actions.shared={['hotbar_shoulder-l1']={slot_1={type='ct',action='echo bound',source_environment='shared'}}}
local function shoulder_draw(active, shoulder, menu, preview)
    ui:check_recasts(actions,{},'basic',{}, {active_bar=active,shoulder_display=shoulder},
        {get_skillchain_window=function()return 0,0 end},{},false,false,menu,preview,1)
end
shoulder_draw(0,7)
assert(ui.bank_labels[7]:visible() and not ui.bank_labels[1]:visible())
assert(ui.hotbars[7].slot_icon[1]:visible() and not ui.hotbars[1].slot_icon[1]:visible())
shoulder_draw(1,7)
assert(not ui.hotbars[7].slot_icon[1]:visible() and ui.hotbars[1].slot_icon[1]:visible())
shoulder_draw(0,nil,true,9)
assert(ui.hotbars[9].slot_icon[1]:visible() and ui.binding_tint:visible())
ui:set_display_layout(nil,true)
assert(ui.geometry.surfaces[ui.hotbars[9].slot_icon[1]].x==ui:get_slot_x(9,1))
ui:move_to(80,40)
check_label_anchor(9)
assert(ui.bank_labels[9]:visible() and not ui.bank_labels[7]:visible())
print('Centered shoulder banks, trigger priority, disabled binding preview and layout changes passed.')
print('XI compact spacing, Legacy reversibility, empty frames and fitted trigger fields passed.')
