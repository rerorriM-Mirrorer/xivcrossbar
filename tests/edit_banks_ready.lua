-- Edit mode (2026-11-16): all banks, bind-ready amber, renames.
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
local saved,bound={},{}
binder:setup({button_layout='playstation',confirm_button='cross',cancel_button='circle'},function(...)saved[#saved+1]={...}end,function()end,
    options,function()return {'Basic'}end,0,0,1000,600)



windower.ffxi={get_player=function()return {main_job='WHM',sub_job='BLM',main_job_level=99,sub_job_level=49} end}
local spells=L{}
for i=1,60 do spells:append({id=i,name='Spell '..i,icon='images/s'..i..'.png',data={target_type={Self=true,Enemy=true}}}) end
binder.display_action_selector=function(self) self.selector:display_options(spells) end
binder.is_hidden=false
binder.state,binder.action_type=2,4
binder.selector:set_page(2); binder:display_action_selector()
local left_double,right_double=false,false
binder.doublepress_provider=function() return left_double,right_double end
binder.theme_options.hotbar_number=6
binder.bind_hold_seconds=0 -- hold tested in edit_hold_undo.lua

-- Double-tap banks: tap turns a page, the double press puts it back and picks bank 5.
local page=binder.selector.current_page
binder:trigger_left(true); binder:trigger_left(false)
assert(binder.selector.current_page==page-1, 'a single tap still turns the page')
left_double=true
binder:trigger_left(true)
assert(binder.selector.current_page==page, 'double tap restores the page')
assert(binder:edit_bank()==5)
binder:button_a(true); binder:button_a(false)
local d=binder:get_destination(); assert(d.bank==5 and d.slot==6, 'L2 double-tap + Cross = bank 5')
binder:trigger_left(false); left_double=false
assert(binder.selector.current_page==page, 'releasing after a slot press turns no page')
right_double=true
binder:trigger_right(true); binder:dpad_left(true); binder:dpad_left(false); binder:trigger_right(false); right_double=false
d=binder:get_destination(); assert(d.bank==6 and d.slot==1, 'R2 double-tap bank 6')
-- Only with five or more banks.
binder.theme_options.hotbar_number=4; left_double=true
binder.trigger_left_pressed=true; assert(binder:edit_bank()==1); binder.trigger_left_pressed=false
left_double=false; binder.theme_options.hotbar_number=6

-- Shoulder banks: L1 / R1 / L1+R1 held, no trigger.
binder:set_shoulder_combo(8)
binder:button_y(true); binder:button_y(false)
d=binder:get_destination(); assert(d.bank==8 and d.slot==8, 'R1 + Triangle = bank 8')
binder:set_shoulder_combo(nil)
binder:button_y(true); binder:button_y(false)
d=binder:get_destination(); assert(d.bank==8, 'bare button after release navigates, keeps the slot')
-- Triggers take priority over a held shoulder.
binder:set_shoulder_combo(7); binder.trigger_right_pressed=true
assert(binder:edit_bank()==2); binder.trigger_right_pressed=false; binder:set_shoulder_combo(nil)
local icons=binder:destination_icons(5,6)
assert(icons[1]:find('_left') and icons[2]:find('x2'), 'double-tap pictures')

-- Set cycling chord: the trigger turns no page afterwards.
page=binder.selector.current_page
binder:trigger_right(true); binder:consume_trigger_gesture(); binder:trigger_right(false)
assert(binder.selector.current_page==page)

-- Bind-ready amber: on a list where Confirm opens a target picker, not ready.
assert(binder:get_destination().ready==false)
binder.state=3; assert(binder:get_destination().ready==true, 'target picker: Confirm binds')
binder.state=2
spells[binder.selector:get_selected_option().id].data.target_type={None=true}
binder:display_action_selector()
assert(binder:get_destination().ready==true, 'no-target action: Confirm binds')
binder.is_linking_for_custom_action=true; assert(binder:get_destination().ready==false); binder.is_linking_for_custom_action=false
binder:clear_destination(); assert(binder:get_destination()==nil and not binder:is_bind_ready())

-- Main menu renames.
local src=io.open('action_binder.lua'):read('*a')
assert(src:find("name = 'Clear'",1,true) and src:find("name = 'Change Icon'",1,true))
assert(not src:find("'Remove a Binding'",1,true) and not src:find("'Change Slot Icon'",1,true))
print('edit banks, ready and renames: passed')
