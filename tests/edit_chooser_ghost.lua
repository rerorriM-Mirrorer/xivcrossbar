-- Edit mode (2026-11-16): set chooser carry-over and ghost preview.
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
local resources=require('ui/resources')
binder.theme_options.allow_stpc_for_self_targeted_actions=false
local spells=L{}
for i=1,40 do spells:append({id=i,name='Spell '..i,icon='images/spell'..i..'.png',data={target_type={Self=true}}}) end
binder.display_action_selector=function(self) self.selector:display_options(spells) end
binder.is_hidden=false
binder.state,binder.action_type=2,4
binder:display_action_selector()
local function select_slot(trigger, button)
    binder[trigger](binder,true); binder[button](binder,true); binder[button](binder,false); binder[trigger](binder,false)
end
local function footer_text()
    binder:update_destination_footer()
    local f=binder.destination_footer_objects
    return f and f.label:visible() and f.label.values.text
end
-- The footer uses the crossbar label's display name, not the internal key.
binder.set_name_provider=function() return 'SHOWN '..player.hotbar_settings.active_environment:upper() end
player.hotbar.second={name='Second'}

-- Ghost 1: nothing without a destination.
assert(binder:get_ghost()==nil)
select_slot('trigger_right','button_x') -- bank 2 slot 7
-- Ghost 2: the highlighted action's icon in the destination slot.
local path,bank,slot=binder:get_ghost()
local selected=binder.selector:get_selected_option()
assert(path=='addon/'..selected.asset_path and bank==2 and slot==7, tostring(path))
-- Ghost 3: follows the cursor.
binder:dpad_right(true); binder:dpad_right(false)
local moved=binder:get_ghost()
assert(moved and moved~=path, 'ghost follows the highlighted action')
-- Ghost 4: after binding, no ghost of the just-bound action until the cursor moves.
local asset=binder.selector:get_selected_option().asset_path
binder:submit_selected_option() -- self-only: binds at once
assert(binder.state==2 and #saved==1)
assert(binder:get_ghost()==nil, 'no ghost duplicating the action just bound')
binder:dpad_right(true); binder:dpad_right(false)
assert(binder:get_ghost(), 'ghost returns once the cursor moves')
-- Ghost 5: page buttons, disabled entries and other states show none.
local real_get=binder.selector.get_selected_option
for _,fake in ipairs({{id='NEXT',text='Next Page'},{id=3,asset_path='images/x.png',disabled=true},
        {id=4,asset_path='images/f.png',data={is_dir=true}}}) do
    binder.selector.get_selected_option=function() return fake end
    assert(binder:get_ghost()==nil, 'no ghost for '..tostring(fake.id))
end
binder.selector.get_selected_option=real_get
binder.state=1
assert(binder:get_ghost()==nil, 'no ghost on the main menu')
binder.state=2
binder.capturing_text=true; assert(binder:get_ghost()==nil); binder.capturing_text=false

-- Chooser 1: opening the set chooser keeps the destination and footer.
assert(footer_text()=='SHOWN BASIC:')
binder:set_chooser_active(true)
local d=binder:get_destination(); assert(d and d.bank==2 and d.slot==7, 'destination survives the chooser')
assert(footer_text()=='SHOWN BASIC:', 'footer stays up while choosing a set')
assert(binder:get_ghost()==nil, 'no ghost while the chooser has the controller')
-- Chooser 2: slot presses are ignored while the chooser is open.
assert(binder:edit_slot_press(1,true)==false)
-- Chooser 3: browsing sets updates the footer name; same slot stays selected.
player.hotbar_settings.active_environment='second'
assert(footer_text()=='SHOWN SECOND:', 'footer follows the browsed set')
-- A renamed label is shown again once measured (first visit to a set was invisible).
local text_measure=require('ui/text_measure')
for _=1,12 do text_measure.begin_frame(); binder:update_destination_footer() end
local label=binder.destination_footer_objects.label
assert(label.values.alpha==255 and label.values.stroke_alpha==255,
    'set name visible after measuring: '..tostring(label.values.alpha))
binder:set_chooser_active(false)
d=binder:get_destination(); assert(d.bank==2 and d.slot==7)
assert(footer_text()=='SHOWN SECOND:')
-- Chooser 4: cancelling back to the first set restores the name.
binder:set_chooser_active(true)
player.hotbar_settings.active_environment='basic'
assert(footer_text()=='SHOWN BASIC:')
binder:set_chooser_active(false)
-- Chooser 5: binding after a set change saves to the same slot position.
binder:submit_selected_option()
assert(#saved==2 and saved[2][1]==2 and saved[2][2]==7)
-- Chooser 6: the legacy button-combo screen shows no footer even with the chooser.
binder.state=5; binder.chooser_active=true
assert(not binder:is_choosing_set_in_edit_mode())
binder.chooser_active=false; binder.state=2
print('edit chooser and ghost: 11 checks groups passed')
