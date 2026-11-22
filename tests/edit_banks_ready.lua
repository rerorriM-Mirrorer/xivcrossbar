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
assert(src:find("name = 'Clear Slot'",1,true) and src:find("name = 'Change Icon'",1,true))
assert(not src:find("'Remove a Binding'",1,true) and not src:find("'Change Slot Icon'",1,true))
-- Shoulder bank footer pictures (Xbox trigger placeholders).
icons=binder:destination_icons(7,1); assert(icons[1]:find('trigger_xbox_left') and icons[2]:find('plus'))
icons=binder:destination_icons(8,1); assert(icons[1]:find('trigger_xbox_right'))
icons=binder:destination_icons(9,1); assert(icons[1]:find('trigger_xbox_left') and icons[2]:find('trigger_xbox_right'))

-- Option glow: on while Confirm would bind, off when the slot already holds it.
binder.state,binder.action_type=2,4
spells=L{}
for i=1,10 do spells:append({id=i,name='Spell '..i,icon='images/s'..i..'.png',data={target_type={None=true}}}) end
binder.selector:set_page(1); binder:display_action_selector()
select_slot=select_slot or nil
binder.trigger_right_pressed=true; binder:edit_slot_press(7,true); binder:edit_slot_press(7,false); binder.trigger_right_pressed=false
binder:update_destination_footer()
local glow=binder.selector.option_glow
assert(glow and glow:visible(), 'highlighted entry glows when Confirm would bind')
local x=binder.selector:get_pos(binder.selector.selected_row,binder.selector.selected_col)
assert(glow.values.pos==x+5-2-4, 'glow sits on the lifted entry')
player.hotbar.basic.hotbar_2={slot_7={action=binder.selector:get_selected_option().text}}
binder:update_destination_footer()
assert(not glow:visible(), 'no glow when the slot already holds that action')
assert(binder:get_destination().ready==false and binder:get_ghost()==nil, 'full amber and no ghost for the same action')
player.hotbar.basic.hotbar_2=nil
binder:update_destination_footer()
assert(glow:visible())
binder.selector:hide(); assert(not glow:visible(), 'glow hides with the list')

-- Custom Action list: only the custom actions (Create/Edit are on the main menu, 2026-11-18).
binder.action_type=nil
binder.action_type=34
binder.state=2
local real_display=binder.display_action_selector
binder.display_action_selector=nil
player.custom_actions={Ready={command='input /ja Ready <me>'}}
binder:display_custom_actions_selector()
local first=binder.selector.current_options
assert(#first==1 and first[1].name=='Ready', 'no Create/Edit entries in the list')
binder.display_action_selector=real_display

-- Footer: amber label with a black outline, two points larger; centred on the menu.
binder.state=1; binder.is_hidden=false
binder:update_destination_footer()
local f=binder.destination_footer_objects
assert(f.label.values.color==255 and f.label.values.stroke_color==0, 'amber text, black outline')
local text_measure=require('ui/text_measure')
for _=1,12 do text_measure.begin_frame(); binder:update_destination_footer() end
local width=f.label:measure_width()
if width then
    local total=width+6+f.count*32
    assert(math.abs(f.label.values.pos-(binder.base_x+binder.width/2-total/2))<0.01, 'group centred on the menu')
end
-- Menu list icons fill their 40x40 frame like crossbar slots (smaller packs line up).
binder.selector:display_options(L{{id=1,name='Small',icon='images/small.png',icon_offset=4,data={target_type={None=true}}},
    {id=2,name='Portrait',icon='images/p.png',icon_size=32,data={target_type={None=true}}}})
local entry1,entry2=binder.selector.option_objects[1],binder.selector.option_objects[2]
assert(entry1.objects[2].ref.values.size==40 and entry1.objects[2].x==entry1.objects[3].x, '32px pack icon scaled to the frame')
assert(entry2.objects[2].ref.values.size==32 and entry2.objects[2].x==entry2.objects[3].x+4, 'credit portraits keep their size')

-- Set chooser and diagnostics (source checks).
local chooser=io.open('environment_chooser.lua'):read('*a')
assert(chooser:find("or '\\\\cs(255,216,112)'",1,true) and chooser:find("HAIRLINE .. color .. HIDDEN_SPACE .. name",1,true)
    and chooser:find("environment.key == 'all-jobs-default' and require('crossbar_destinations').all_cs()",1,true) and not chooser:find("\\\\cs(0,128,255)' .. HIDDEN_SPACE .. name",1,true), 'default sets amber')
assert(chooser:find("if self.heading then self.heading:hide() end",1,true) and chooser:find('get_name_y(count) - 5',1,true), 'no heading; background fits the list')
assert(not chooser:find('self:maybe_show_default_sets_tooltip(',1,true), 'no default-sets tooltip')
local main=io.open('xivcrossbar.lua'):read('*a')
assert(main:find("diagnostic:command('start', 'full')",1,true) and not main:find("command == 'menutitle'",1,true))
print('edit banks, ready and renames: passed')
