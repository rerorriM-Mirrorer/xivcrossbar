-- Edit mode step 1 (2026-11-16): slot selection while the menu is open.
-- Mock preamble copied from menu_resources.lua.
local native = {}
local function object()
    local o = {values={}, shown=false}
    native[o] = true
    return setmetatable(o, {__index=function(_, key)
        return function(self, ...)
            assert(native[self], 'native object used after deletion: '..key)
            local args={...}
            if key=='pos' and #args==2 then self.coords={args[1],args[2]} end
            if key=='destroy' then native[self]=nil
            elseif key=='show' then self.shown=true
            elseif key=='hide' then self.shown=false
            elseif key=='visible' and #args==0 then return self.shown
            elseif key=='extents' then return #(self.values.text or '')*6,14
            elseif #args==0 then return self.values[key] or (key=='alpha' and 255 or nil)
            else self.values[key]=args[1] end
        end
    end})
end
texts={new=object}; images={new=object}
package.loaded.texts=texts;package.loaded.images=images
for _,name in ipairs({'strings','tables','libs/mountroulette/mountroulette',
    'ui/item_icons','sw_zones','resources/crossbar_abilities','resources/crossbar_spells'}) do package.loaded[name]={} end
-- The upstream List has a numeric n member and range-checked assignments.
-- A plain array double hid the original cleanup regression.
_libs={tables=table}
class=function(value)
    local mt=type(value)=='table' and getmetatable(value)
    return mt and mt.__class or type(value)
end
dofile('tests/fixtures/windower_lists.lua')
package.loaded.lists=list
package.loaded['libs/kebab_casify']=function(s) return s:lower():gsub(' ','-') end
local player={hotbar_settings={active_environment='basic'},hotbar={basic={name='Basic'}},
    catalog_save_scope=function() return 'global' end}
package.loaded.player=player
package.loaded['text_input_guard']={update=function()end}
package.loaded.socket={gettime=function()return 1 end}
config={load=function(d)return d end}
package.preload['libs/settings_config']=function() return config end
local prim_values,events={},{}
local screen={ui_x_res=1280,ui_y_res=720}
windower={addon_path='addon/',register_event=function(name,callback)
        events[name]=events[name] or {};table.insert(events[name],callback)
    end,send_command=function()end,
    get_windower_settings=function()return screen end,
    prim=setmetatable({}, {__index=function(_,key)return function(name,...)
        prim_values[name]=prim_values[name] or {};prim_values[name][key]={...}
    end end})}
local binder=require('action_binder')
local options=require('theme').apply(require('defaults'))
options.button_layout='playstation';options.hotbar_number=6
binder:setup({button_layout='playstation',confirm_button='cross',cancel_button='circle'},function()end,function()end,
    options,function()return {'Basic'}end,0,0,1000,600)

local resources=require('ui/resources')
local function menu_list()
    local list=L{}
    for i=1,30 do list:append({id=i,name='Option '..i,icon='x.png'}) end
    return list
end
binder.is_hidden=false
binder.state=1 -- SELECT_ACTION_TYPE
binder.selector:display_options(menu_list())
local start=binder.selector:get_selected_option().id

-- 1. No trigger: buttons navigate as before, nothing is selected.
binder:dpad_right(true); binder:dpad_right(false)
assert(binder:get_destination()==nil, 'bare D-pad must not select a slot')
local after_nav=binder.selector:get_selected_option().id
assert(after_nav~=start, 'bare D-pad should still move the menu cursor')

-- 2. R2 held + Cross (slot 6 on PlayStation layout... button_a is slot 6) selects bank 2 slot 6.
local page=binder.selector.current_page
binder:trigger_right(true)
assert(binder:get_binding_preview_bank()==2, 'held R2 previews bank 2 in edit mode')
binder:button_a(true)
local d=binder:get_destination()
assert(d and d.bank==2 and d.slot==6, 'R2 + Cross selects bank 2 slot 6')
assert(binder.selector:get_selected_option().id==after_nav, 'slot press must not confirm/move the menu')
assert(binder.state==1, 'slot press must not submit the menu')
binder:button_a(false)
binder:trigger_right(false)
assert(binder.selector.current_page==page, 'trigger used for a slot must not turn the page')
assert(binder:get_binding_preview_bank()==nil)

-- 3. D-pad with trigger: selects, and does not start held-navigation repeat.
binder:trigger_left(true); binder:dpad_up(true)
assert(binder.held_navigation==nil, 'slot press must not start repeat navigation')
d=binder:get_destination(); assert(d.bank==1 and d.slot==4)
binder:dpad_up(false); binder:trigger_left(false)

-- 4. Pressing the selected slot again deselects it.
binder:trigger_left(true); binder:dpad_up(true); binder:dpad_up(false); binder:trigger_left(false)
assert(binder:get_destination()==nil, 'same slot again deselects')

-- 5. Release after letting go of the trigger stays consumed (no stray confirm).
binder:trigger_right(true); binder:button_a(true); binder:trigger_right(false)
local before=binder.state
binder:button_a(false)
assert(binder.state==before and binder:get_destination().slot==6)

-- 6. L2+R2 order picks bank 3 or 4 with six banks.
binder.theme_options.hotbar_number=6
binder.bind_hold_seconds=0 -- hold tested in edit_hold_undo.lua
binder:trigger_right(true); binder:trigger_left(true)
binder:button_y(true); binder:button_y(false)
d=binder:get_destination(); assert(d.bank==3 and d.slot==8, 'R2 then L2 = bank 3')
binder:trigger_left(false); binder:trigger_right(false)
binder:trigger_left(true); binder:trigger_right(true)
binder:button_b(true); binder:button_b(false)
d=binder:get_destination(); assert(d.bank==4 and d.slot==5, 'L2 then R2 = bank 4')
binder:trigger_right(false); binder:trigger_left(false)

-- 7. Footer pictures match the old Bind-to-Slot icons.
local icons=binder:destination_icons(2,7)
assert(icons[1]:find('trigger_playstation_right') and icons[2]:find('plus') and icons[3]:find('facebuttons_playstation_x'))
icons=binder:destination_icons(4,1)
assert(icons[1]:find('_left') and icons[2]:find('arrow_right') and icons[3]:find('_right') and icons[5]:find('dpad_playstation_left'))

-- 8. Footer objects are created once and updated in place; hide disposes them.
binder:update_destination_footer()
local f=binder.destination_footer_objects
assert(f and f.label:visible() and f.label.values.text=='BASIC:', 'footer shows the set name')
assert(f.icons[1]:visible() and not f.prompt:visible())
local label,icon1=f.label,f.icons[1]
binder.trigger_left_pressed=true; binder:edit_slot_press(2,true); binder:edit_slot_press(2,false); binder.trigger_left_pressed=false
binder:update_destination_footer()
assert(binder.destination_footer_objects.label==label and binder.destination_footer_objects.icons[1]==icon1,
    'a new slot reuses the footer objects (no flash)')
assert(icon1.values.path:find('trigger_playstation_left'), 'pictures updated in place')
binder:hide()
assert(binder.destination==nil, 'closing the menu clears the selected slot')
assert(resources.is_disposed(label) and binder.destination_footer_objects==nil)
binder.is_hidden=false
binder:update_destination_footer()
assert(binder.destination_footer_objects.prompt:visible(), 'reopened menu: Choose a slot to bind to')
assert(binder.destination_footer_objects.prompt.values.text=='Choose a crossbar slot to bind to:')

-- 9. Legacy Bind-to-Slot screen is untouched: edit mode is off there.
binder.state=5 -- SELECT_BUTTON_ASSIGNMENT
assert(not binder:is_edit_mode())
assert(binder:edit_slot_press(6,true)==false)
binder.state=1
binder.capturing_text=true
assert(not binder:is_edit_mode(), 'typing never selects slots')
binder.capturing_text=false

-- 10. A closed menu reports no destination.
binder.trigger_right_pressed=true; binder:edit_slot_press(7,true); binder.trigger_right_pressed=false
binder.is_hidden=true
assert(binder:get_destination()==nil)
binder.is_hidden=false
binder:clear_destination()
assert(binder.destination==nil)
print('edit destination: 10 scenario groups passed')
