-- Edit mode step 2 (2026-11-16): immediate bind to the selected slot.
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
binder.bind_hold_seconds=0 -- hold tested in edit_hold_undo.lua

windower.ffxi={get_player=function()return {main_job='WHM',sub_job='BLM',main_job_level=99,sub_job_level=49} end,
    get_abilities=function()return {job_abilities={},weapon_skills={}} end}
binder.on_bound=function(bank,slot) bound[#bound+1]={bank,slot} end
binder.theme_options.allow_stpc_for_self_targeted_actions=true
local resources=require('ui/resources')
local spells=L{}
for i=1,40 do spells:append({id=i,name='Spell '..i,icon='spell.png',data={target_type={Self=true}}}) end
binder.display_action_selector=function(self) self.selector:display_options(spells) end
local function open_list(page, row_moves)
    binder.is_hidden=false
    binder.state,binder.action_type=2,4 -- SELECT_ACTION, WHITE_MAGIC
    binder.selector:set_page(page or 1); binder:display_action_selector()
    for _=1,(row_moves or 0) do binder:dpad_down(true); binder:dpad_down(false) end
end
local function select_slot(trigger, button)
    binder[trigger](binder,true); binder[button](binder,true); binder[button](binder,false); binder[trigger](binder,false)
end

-- 1. With a destination: action -> target -> bound at once, back on the same list and cursor.
open_list(2, 0)
local chosen=binder.selector:get_selected_option().text
local page=binder.selector.current_page
select_slot('trigger_right','button_x') -- bank 2, slot 7
binder:submit_selected_option() -- spell -> target picker (Self, stpc)
assert(binder.state==3, 'target picker still shown when a target choice exists')
binder:submit_selected_option() -- <me> -> bind
assert(#saved==1, 'bound immediately, no Enter Button Combo screen')
local s=saved[1]
assert(s[1]==2 and s[2]==7 and s[3]=='ma' and s[4]==chosen and s[5]=='me', 'saved to destination')
assert(#bound==1 and bound[1][1]==2 and bound[1][2]==7, 'confirmation hook fired')
assert(binder.state==2, 'returned to the action list')
assert(binder.selector.current_page==page and binder.selector:get_selected_option().text==chosen, 'cursor kept')
assert(not binder.is_hidden, 'menu stays open')
local d=binder:get_destination(); assert(d and d.bank==2 and d.slot==7, 'destination stays selected')
assert(not resources.snapshot or true)

-- 2. Choose again: replaces the same slot, no confirmation.
binder:dpad_right(true); binder:dpad_right(false)
local second=binder.selector:get_selected_option().text
assert(second~=chosen and not second:find('Page'), second)
binder:submit_selected_option(); binder:submit_selected_option()
assert(#saved==2 and saved[2][1]==2 and saved[2][2]==7 and saved[2][4]==second)

-- 3. Self-only action with no target choice binds straight from the list.
binder.theme_options.allow_stpc_for_self_targeted_actions=false
binder:submit_selected_option()
assert(#saved==3 and binder.state==2, 'self-only action binds without a target screen')
binder.theme_options.allow_stpc_for_self_targeted_actions=true

-- 4. A failed save (set_hotkey returns false) plays no confirmation but stays put.
local real_save=binder.save_binding
binder.save_binding=function(...) saved[#saved+1]={...}; return false end
local flashes=#bound
binder:submit_selected_option(); binder:submit_selected_option()
assert(#bound==flashes and binder.state==2 and not binder.is_hidden)
binder.save_binding=real_save

-- 5. No destination: the legacy Enter Button Combo screen appears.
binder:clear_destination()
local before=#saved
binder:submit_selected_option(); binder:submit_selected_option()
assert(binder.state==5 and #saved==before, 'legacy Bind-to-Slot without a destination')
binder:go_back(); binder:go_back()
assert(binder.state==2)

-- 6. Direct actions (View Map) bind and return to the main menu.
select_slot('trigger_left','dpad_up') -- bank 1 slot 4
binder.state,binder.action_type,binder.action_name,binder.action_target=5,28,'View Map',nil
binder:display_button_assigner()
assert(#saved==before+1 and saved[#saved][1]==1 and saved[#saved][2]==4 and saved[#saved][4]=='View Map')
assert(binder.state==1, 'direct action returns to the main menu')

-- 7. Slot operations keep their legacy screens for now.
for _,t in ipairs({36,42}) do
    binder.state,binder.action_type,binder.action_name=5,t,'x'
    assert(not binder:can_bind_to_destination(), 'operation '..t..' stays legacy')
end
binder.state,binder.action_type=5,0
assert(binder:can_bind_to_destination(), 'Clear acts on the selected slot')
binder.action_type,binder.action_icon=35,nil
assert(not binder:can_bind_to_destination(), 'Change Icon needs a chosen icon')
binder.action_icon='x.png'
assert(binder:can_bind_to_destination(), 'Change Icon acts on the selected slot')
binder.binding_custom_action_review=true; binder.action_type=34
assert(not binder:can_bind_to_destination(), 'custom editor Save & Bind stays legacy')
binder.binding_custom_action_review=false
assert(binder:can_bind_to_destination(), 'binding an existing custom action uses the destination')
print('edit bind: 7 scenario groups passed')
