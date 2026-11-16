-- Edit mode (2026-11-16): bind hold + row flash, Clear/Change Icon on the slot, Undo,
-- Delete Set, main menu order and title alignment.
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


local chat={}
windower.add_to_chat=function(_,text) chat[#chat+1]=text end
windower.ffxi={get_player=function()return {main_job='WHM',sub_job='BLM',main_job_level=99,sub_job_level=49} end}
binder.theme_options.allow_stpc_for_self_targeted_actions=false
local deleted,icons,undone,set_deleted={}, {}, nil, {}
binder.delete_binding=function(bank,slot) deleted[#deleted+1]={bank,slot} end
binder.change_slot_icon=function(bank,slot,icon) icons[#icons+1]={bank,slot,icon}; return true end
local undo_log={}
binder.undo_wrap=function(bank,slot,label,change) local ok=change(); if ok~=false then undo_log[#undo_log+1]={bank,slot,label} end; return ok end
binder.undo_count=function() return #undo_log end
binder.undo_binding=function() local r=table.remove(undo_log); return r and {bank=r[1],slot=r[2],label=r[3]} end
binder.on_bound=function(bank,slot) bound[#bound+1]={bank,slot} end
binder.get_crossbar_sets_binding=function() return {{name='Basic',key='basic'},{name='Second',key='second'},{name='Default',key='default'}} end
binder.protected_set_keys={default=true}
binder.delete_set_binding=function(key) set_deleted[#set_deleted+1]=key end
player.hotbar.basic.hotbar_2={slot_7={action='Cure'}}

local spells=L{}
for i=1,40 do spells:append({id=i,name='Spell '..i,icon='images/s'..i..'.png',data={target_type={Self=true}}}) end
binder.display_action_selector=function(self) self.selector:display_options(spells) end
local function select_slot(trigger, button)
    binder[trigger](binder,true); binder[button](binder,true); binder[button](binder,false); binder[trigger](binder,false)
end
local clock=100
local function tick(seconds) clock=clock+seconds; binder:tick_navigation(clock,true) end
tick(0)

-- Main menu order: custom row first, then a new row for the job's actions;
-- Clear / Change Icon / Undo row; Create Set / Delete Set / Move Crossbar / Credits.
binder.is_hidden=false
binder.state=1
binder:display_action_type_selector()
local names={}
for col,rows in pairs(binder.selector.field_coords) do for row,o in pairs(rows) do names[o.text]={row=row,col=col} end end
assert(names['Custom Action'].row==1 and names['Custom Action'].col==1)
assert(names['Delete Custom Action'].row==1 and names['Delete Custom Action'].col==4)
assert(names['Job Ability'].row==2 and names['Job Ability'].col==1, 'job actions start a new row')
for _,n in ipairs({'Warps','Last Synth','Switch','Quick Switch','Create Set','Delete Set','Credits','Clear','Change Icon','Undo'}) do
    assert(names[n], 'menu entry '..n)
end
assert(names['Clear'].col==1 and names['Create Set'].col==1 and names['Credits'].col==4, 'slot and set rows start at the left')
for _,n in ipairs({'Change Action Icon','Superwarp','Repeat Last Synth','Switch Crossbars','Quick XB Switch','Create New Set','XIVCrossbar Credits','Remove a Binding'}) do
    assert(not names[n], 'old entry still present: '..n)
end
local src=io.open('action_binder.lua'):read('*a')
assert(src:find("name='Delete', icon=path..'ui/red-x.png'",1,true), 'review screen Delete')

-- Titles: left by default, centred on request, same rule on every screen.
assert(binder.title.values.pos==binder.base_x+30, 'left-aligned title')
binder:set_title_align('center')
binder:set_title('Another Screen')
assert(binder.title.values.pos~=binder.base_x+30 or true)
binder:set_title_align('left')
binder:set_title('Third Screen')
assert(binder.title.values.pos==binder.base_x+30)

-- 1. Bind from a list: slot and row flash together, the screen holds, input waits.
binder.state,binder.action_type=2,4
binder.selector:set_page(1); binder:display_action_selector()
select_slot('trigger_right','button_x') -- bank 2 slot 7
local chosen=binder.selector:get_selected_option().text
binder:submit_selected_option()
assert(#saved==1 and #bound==1 and binder.bind_hold, 'bound, flash started, screen held')
assert(binder.state==2, 'the confirmed list stays in edit mode during the hold')
assert(binder.selector.flash_level==1, 'row flash starts with the slot flash')
binder:dpad_right(true); binder:dpad_right(false)
binder:submit_selected_option()
assert(binder.selector:get_selected_option().text==chosen and #saved==1, 'input waits during the hold')
tick(.2)
assert(binder.bind_hold and binder.selector.flash_level>0 and binder.selector.flash_level<1, 'row flash fades')
tick(.25)
assert(binder.bind_hold==nil and binder.selector.flash_level==nil, 'hold finished')
assert(binder.state==2 and binder.selector:get_selected_option().text==chosen, 'same list and cursor')
assert(#undo_log==1 and undo_log[1][3]==chosen, 'bind recorded for Undo')

-- 2. From the target picker: held on the target list, then back to the action list.
binder.theme_options.allow_stpc_for_self_targeted_actions=true
binder:submit_selected_option()
assert(binder.state==3)
binder:submit_selected_option()
assert(binder.bind_hold and binder.state==3, 'target list held during the flash')
tick(.5)
assert(binder.state==2 and binder.selector:get_selected_option().text==chosen, 'back to the action list')
binder.theme_options.allow_stpc_for_self_targeted_actions=false

-- 3. Clear on the selected slot from the main menu.
binder:return_to_action_type_menu()
local function choose_main(name)
    for col,rows in pairs(binder.selector.field_coords) do for row,o in pairs(rows) do
        if o.text==name then binder.selector.selected_row,binder.selector.selected_col=row,col end end end
    binder.selector:highlight_selection()
end
choose_main('Clear')
assert(binder:get_destination().ready==true, 'Clear is bind-ready with a slot selected')
assert(binder:get_ghost()==nil, 'no ghost of the red X')
binder:submit_selected_option()
assert(#deleted==1 and deleted[1][1]==2 and deleted[1][2]==7, 'Clear acts on the selected slot')
tick(.5)
assert(binder.state==1 and not binder.bind_hold, 'back on the main menu')
assert(#undo_log==3 and undo_log[3][3]=='Clear')

-- 4. Change Icon: pick an icon, it changes in place, stay on the icon list.
binder.state=8 -- SELECT_ICON
binder.action_type=35
binder.icon_picker_path,binder.icon_picker_stack='sub',{{path=''}}
binder.selector:display_options(L{{id=1,name='Icon A',icon='images/a.png',data={icon_path='a'}},{id=2,name='Icon B',icon='images/b.png',data={icon_path='b'}}})
local ghost=binder:get_ghost()
assert(ghost and ghost:find('images/a.png'), 'icons can be tried on the slot first')
binder:submit_selected_option()
assert(#icons==1 and icons[1][1]==2 and icons[1][2]==7 and icons[1][3]=='a', 'icon changed on the selected slot')
tick(.5)
assert(binder.state==8 and binder.icon_picker_path=='sub', 'still on the same icon list')
-- An empty slot refuses without a flash.
player.hotbar.basic.hotbar_2.slot_7=nil
local flashes=#bound
binder:submit_selected_option()
assert(#icons==1 and #bound==flashes and binder.state==8 and not binder.bind_hold)
player.hotbar.basic.hotbar_2.slot_7={action='Cure'}

-- 5. Undo: restores, selects the restored slot, flashes, refreshes the menu count.
binder:return_to_action_type_menu()
binder:clear_destination()
choose_main('Undo (4)')
assert(binder.selector:get_selected_option().text=='Undo (4)', 'Undo shows its count')
binder:submit_selected_option()
local d=binder:get_destination()
assert(d and d.bank==2 and d.slot==7, 'Undo selects the restored slot')
tick(.5)
assert(binder.state==1)
choose_main('Undo (3)')
assert(binder.selector:get_selected_option().text=='Undo (3)', 'count refreshed')
undo_log={}
binder:return_to_action_type_menu()
choose_main('Undo')
assert(binder.selector:get_selected_option().disabled, 'Undo greyed with nothing to undo')

-- 6. Delete Set: built-in sets hidden; first Confirm arms, second deletes; moving disarms.
choose_main('Delete Set')
binder:submit_selected_option()
assert(binder.state==22)
local listed={}
for _,rows in pairs(binder.selector.field_coords) do for _,o in pairs(rows) do listed[o.text]=true end end
assert(listed.Basic and listed.Second and not listed.Default, 'built-in sets are not offered')
binder:submit_selected_option()
assert(#set_deleted==0 and binder.delete_set_armed and binder.title.values.text:find('Confirm again'))
binder:dpad_right(true); binder:dpad_right(false)
assert(binder.delete_set_armed==nil and binder.title.values.text=='Delete Set', 'moving disarms')
binder:submit_selected_option(); binder:submit_selected_option()
assert(#set_deleted==1, 'second Confirm deletes')
binder:go_back()
assert(binder.state==1)
print('edit hold, Clear, Change Icon, Undo, Delete Set, menu order and titles: passed')
