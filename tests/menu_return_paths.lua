-- Menu patch (2026-11-18): Back returns to the entry that opened a screen, delete
-- returns to the Custom Action list, delete header, Create/Edit on the main menu,
-- old flow keeps the menu open with the slot selected, mouse off by default.
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



windower.get_dir=function() return {'custom_actions.png'} end
windower.dir_exists=function() return false end
windower.file_exists=windower.file_exists or function() return true end
local chat={}
windower.add_to_chat=function(_,text) chat[#chat+1]=text end
windower.ffxi={get_player=function()return {main_job='WHM',sub_job='BLM',main_job_id=3,sub_job_id=4,main_job_level=99,sub_job_level=49} end,
  get_abilities=function() return {job_abilities={},weapon_skills={}} end,
  get_spells=function() return {} end, get_items=function() return {} end,
  get_mob_by_target=function() return nil end}
binder.on_bound=function(bank,slot) bound[#bound+1]={bank,slot} end
local undo_log={}
binder.undo_wrap=function(bank,slot,label,change) local ok=change(); if ok~=false then undo_log[#undo_log+1]={bank,slot,label} end; return ok end
binder.get_crossbar_sets_binding=function() return {{name='Basic',key='basic'},{name='Second',key='second'}} end
binder.protected_set_keys={}
local catalog={}
player.custom_actions=catalog
binder.save_custom_action=function(d) catalog[d.name]={command=d.command,icon=d.icon}; return true end
binder.update_custom_action=function(old,d) catalog[old]=nil; catalog[d.name]={command=d.command,icon=d.icon}; return true end
binder.delete_custom_action=function(name) catalog[name]=nil; return true end
local clock=100
local function tick(seconds) clock=clock+seconds; binder:tick_navigation(clock,true) end
tick(0)
local function find(name)
    for col,rows in pairs(binder.selector.field_coords) do for row,o in pairs(rows) do
        if o.text==name or o.id==name then return row,col,o end end end
end
local function choose(name)
    local row,col=find(name); assert(row, 'no entry '..tostring(name))
    binder.selector.selected_row,binder.selector.selected_col=row,col
    binder.selector:highlight_selection()
end
local function selected() local o=binder.selector:get_selected_option(); return o and (o.text or o.id) end
local function open_main() binder.is_hidden=false; binder.state=1; binder.selection_states={}; binder:display_action_type_selector() end

-- Main menu: Custom Action (dummied out with none saved), Create, Edit (dummied out).
open_main()
local _,_,ca=find('Custom Action'); local _,_,create=find('Create Custom Action'); local _,_,edit=find('Edit Custom Action')
assert(ca.disabled and create and not create.disabled and edit.disabled, 'Create/Edit back on the main menu')

-- Back returns the cursor to the entry that opened the screen.
for _,name in ipairs({'Change Icon','Delete Set','Credits','Weaponskills','Attack'}) do
    open_main(); choose(name); binder:submit_selected_option()
    assert(binder.state~=1, name..' opened a screen')
    for _=1,3 do if binder.state~=1 then binder:go_back() end end
    assert(binder.state==1 and selected()==name, 'Back to '..name..', got '..tostring(selected()))
end

-- Create from the main menu; review sub-screens return to the entry that opened them.
open_main(); choose('Create Custom Action'); binder:submit_selected_option()
binder.custom_action_draft.name='Ready All'; binder.custom_action_draft.command='input /pet "Ready" <me>'
binder.custom_action_review_field=nil; binder.custom_action_name_required=false; binder:set_capturing_text(false)
binder:display_edit_custom_action_review()
choose('CHANGE_ICON'); binder:submit_selected_option(); assert(binder.state==8)
binder:go_back(); assert(binder.state==17 and selected()=='Choose Icon', 'Back from icons: '..tostring(selected()))
choose('CHANGE_LINKED'); binder:submit_selected_option(); assert(binder.state==9 or binder.state==16 or binder.state~=17)
binder:go_back(); assert(binder.state==17 and selected()=='Link Action', 'Back from linking: '..tostring(selected()))
choose('CHANGE_ALIAS'); binder:submit_selected_option(); assert(binder.custom_action_review_field=='alias')
binder:go_back(); assert(binder.state==17 and selected()=='Edit Alias', 'after typing: '..tostring(selected()))
-- Save, then delete from the review screen: the Custom Action list, not a closed menu.
catalog.Other={command='input /echo other'}
choose('SAVE_EDIT'); binder:submit_selected_option()
assert(catalog['Ready All'] and binder.state==16, 'saved, on the edit pick list')
choose('Ready All'); binder:submit_selected_option(); assert(binder.state==17)
binder:go_back(); assert(binder.state==16 and selected()=='Ready All', 'Back to the action on the pick list')
choose('Ready All'); binder:submit_selected_option()
choose('DELETE_CUSTOM_ACTION'); binder:submit_selected_option(); assert(binder.state==19)
-- Delete screen: icon and amber name under the title.
local header=binder.delete_header
assert(header and header.name.values.text=='"Ready All"' and header.icon.values.path:find('custom_actions.png',1,true))
binder:go_back(); assert(binder.state==17 and selected()=='Delete Custom Action', 'Back from delete keeps the entry')
choose('DELETE_CUSTOM_ACTION'); binder:submit_selected_option()
binder:submit_selected_option()
assert(not catalog['Ready All'] and not binder.is_hidden and binder.state==2 and binder.action_type==34, 'Custom Action list after deleting')
assert(find('Other') and not find('Ready All'))
-- Deleting the last one: back to the main menu (Custom Action dummied out again).
catalog.Other=nil; catalog.Last={command='x'}
binder.custom_action_delete_target='Last'; binder.custom_action_delete_from_review=false
binder.state=19; binder:submit_selected_option()
assert(binder.state==1 and not binder.is_hidden)
local _,_,ca2=find('Custom Action'); assert(ca2.disabled)

-- Old Bind-to-Slot flow: bound, then the main menu with that slot selected.
open_main(); binder:clear_destination()
binder.state,binder.action_type,binder.action_name,binder.action_target=5,4,'Cure','me'
binder.active_crossbar,binder.hotkey=1,3
binder:assign_action()
assert(saved[#saved][1]==1 and saved[#saved][2]==3 and saved[#saved][4]=='Cure')
assert(binder.state==1 and not binder.is_hidden and binder.destination.bank==1 and binder.destination.slot==3, 'slot selected for more binding')
assert(bound[#bound][1]==1 and bound[#bound][2]==3 and undo_log[#undo_log][3]=='Cure', 'flash and Undo for the old flow')
binder.state,binder.action_type=5,0; binder.active_crossbar,binder.hotkey=2,5
binder:delete_action()
assert(binder.state==1 and binder.destination.bank==2 and binder.destination.slot==5 and undo_log[#undo_log][3]=='Clear')

-- Mouse input is off by default.
assert(binder.mouse_enabled==false)
local main=io.open('xivcrossbar.lua'):read('*a')
assert(main:find('action_binder.mouse_enabled = settings.MenuMouse == true',1,true) and main:find("command == 'menumouse'",1,true))
local src=io.open('action_binder.lua'):read('*a')
assert(src:find('if blocked or not action_binder.mouse_enabled then',1,true))
print('menu return paths, delete flow, old flow and mouse default: passed')
