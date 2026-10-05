-- Contributing author: A. Exercise drawing through the real renderer/binder;
-- only Windower's native surfaces/resources are substituted.
local stub = dofile('tests/helpers/windower_stub.lua')
package.loaded.defaults, package.loaded.theme, package.loaded.ui = nil, nil, nil
local defaults = require('defaults')
local theme = require('theme')
defaults.Hotbar.Number, defaults.iscompact = 4, true
defaults.Style.Scale = .75
defaults.Texts.SlotAlias = {OffsetX=-5, OffsetY=-10}
defaults.Texts.OffsetX, defaults.Texts.OffsetY = 900, 900 -- legacy offsets must not move costs/aliases
local options = theme.apply(defaults)
options.button_layout = 'playstation'
windower.ffxi.get_player = function() return {buffs={}, main_job_id=3} end
texts, images = require('texts'), require('images')
local ui = require('ui')
ui:setup(options, {})
local x, y = ui:get_slot_x(1, 1), ui:get_slot_y(1, 1)
local slot = ui.hotbars[1]
local expected_x, expected_y = ui.geometry:point(x + 15 - select(1, slot.slot_text[1]:extents()) / 2, y + 30)
assert(slot.slot_text[1]._pos == expected_x and slot.slot_text[1]._pos_y == expected_y)
assert(slot.slot_frame[1]._size == 30 and slot.slot_frame[1]._size_y == 30)
assert(slot.slot_element[1]._size == 12)
assert(slot.slot_text[1]._size == 5) -- 7pt at .75, rounded for the native font API
assert(slot.slot_cost[1]._size == 6 and slot.slot_recast_text[1]._size == 7)
local cost_x, cost_y = slot.slot_cost[1]:pos()
ui:set_alias_offsets(10, -5)
assert(slot.slot_cost[1]:pos() == cost_x) -- dedicated offsets do not disturb costs
expected_x, expected_y = ui.geometry:point(x + 30 - select(1, slot.slot_text[1]:extents()) / 2, y + 35)
assert(slot.slot_text[1]._pos == expected_x and slot.slot_text[1]._pos_y == expected_y)

local action = {type='ex', action='input /check', alias='Check', icon='weaponskills/sword/Goring_Blade'}
local bars = {basic={hotbar_1={slot_1=action}}}
ui:load_player_hotbar(bars,{mp=100,tp=0},'basic',{active_bar=1})
assert(slot.slot_icon[1]._size == 30 and slot.slot_icon[1]._fit == false)
local texture_calls = slot.slot_icon[1]._path_calls
ui:hide(); ui:load_player_hotbar(bars,{mp=100,tp=0},'basic',{active_bar=1}); ui:show(bars,'basic')
assert(slot.slot_icon[1]._path_calls == texture_calls) -- unchanged reveal keeps its texture
action.icon='check'
ui:load_player_hotbar(bars,{mp=100,tp=0},'basic',{active_bar=1})
assert(slot.slot_icon[1]._path:find('/check.png',1,true) and slot.slot_icon[1]._path_calls == texture_calls + 1)
bars.basic.hotbar_1.slot_1=nil
ui:load_player_hotbar(bars,{mp=100,tp=0},'basic',{active_bar=1})
assert(slot.slot_icon[1]._path:find('/blank.png',1,true)) -- removed bindings cannot show stale textures

-- Recast crops and controller hints use the same transform, including inset.
slot.slot_recast[1]:size(40, 20); slot.slot_recast[1]:pos(x, y + 20)
assert(slot.slot_recast[1]._size == 30 and slot.slot_recast[1]._size_y == 15)
assert(slot.slot_recast[1]._pos_y == select(2, ui.geometry:point(x, y + 20)))
ui:show_controller_icons(1)
assert(slot.slot_recast[9]._size == 30)
ui:set_scale(.5)
assert(slot.slot_frame[1]._size == 20 and slot.slot_recast[1]._size_y == 10)
ui:update_offsets(100,50)
local moved_x, moved_y = slot.slot_frame[1]._pos, slot.slot_frame[1]._pos_y
ui:update_offsets(110,40)
assert(slot.slot_frame[1]._pos == moved_x + 10 and slot.slot_frame[1]._pos_y == moved_y - 10)

-- Edit feedback tracks the scaled tile. Hidden UI cannot leave an edit overlay.
ui:show_drag_handle(true)
local b = ui:get_drag_bounds()
assert(b.width == 20 and b.height == 20)
assert(ui.drag_tile._pos == b.x and ui.drag_tile._pos_y == b.y)
ui:update_drag_feedback(b.x+1,b.y+1,false,true)
assert(ui.drag_glow:visible())
ui:update_drag_feedback(b.x+1,b.y+1,true,true)
assert(not ui.drag_glow:visible() and ui.drag_handle._color_y == 190)
assert(stub.primitives.xivcrossbar_edit_top.set_color[3] == 190)
ui:hide()
assert(not ui.drag_handle:visible() and not ui.drag_tile:visible())
assert(stub.primitives.xivcrossbar_edit_top.set_visibility[1] == false)
ui.suspended=true; ui:show_drag_handle(true); assert(not ui.drag_tile:visible())
print('PASS: uniform crossbar/font/crop scaling, dedicated alias offsets, icon bounds, texture reuse, pixel dragging and edit feedback')

-- A centered binder fits small/large resolutions, including its paging row.
-- Changing crossbar offsets cannot shift its background away from its content.
for _, resolution in ipairs({{640,480},{1280,720},{1366,768},{1600,900},{3840,2160}}) do
    windower.get_windower_settings=function() return {ui_x_res=resolution[1],ui_y_res=resolution[2]} end
    defaults.Style.OffsetX, defaults.Style.OffsetY = 500, -200
    package.loaded.action_binder, package.loaded['ui/selectablelist'] = nil, nil
    local binder=stub.binder()
    local rect=stub.primitives.dialog_bg
    local px,py=unpack(rect.set_position)
    local pw,ph=unpack(rect.set_size)
    assert(math.abs(px*2+pw-resolution[1]) < .001 and math.abs(py*2+ph-resolution[2]) < .001)
    assert(px>=16-.001 and py>=16-.001)
    local options=L{}
    for i=1,100 do options:append({id=i,name='Action '..i,icon='images/test76.png'}) end
    binder.selector:display_options(options)
    for _, image in ipairs(binder.selector.images) do
        assert(image._fit==false)
        assert(image._pos>=px and image._pos_y>=py and image._pos+image._size<=px+pw and image._pos_y+image._size_y<=py+ph)
    end
    local bx,by=unpack(stub.primitives.next_page_button.set_position)
    local bw,bh=unpack(stub.primitives.next_page_button.set_size)
    assert(bx>=px and by>=py and bx+bw<=px+pw and by+bh<=py+ph)
    local row,col=binder.selector:get_row_col_from_pos(bx+1,by+1)
    assert(binder.selector.field_coords[col][row].id=='NEXT')
    binder:hide()
end
print('PASS: centered binder and bounded icons/paging/mouse regions at 640x480, 720p, 768p, 900p and 4K')
