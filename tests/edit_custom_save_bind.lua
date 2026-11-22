-- Edit mode (2026-11-16): custom action Save & Bind to the selected slot, review grid,
-- target title, set icons.
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

local chat={}
windower.add_to_chat=function(_,text) chat[#chat+1]=text end
windower.ffxi={get_player=function()return {main_job='SMN',sub_job='WHM',main_job_level=99,sub_job_level=49} end}
binder.on_bound=function(bank,slot) bound[#bound+1]={bank,slot} end
local catalog={}
player.custom_actions=catalog
binder.save_custom_action=function(d) catalog[d.name]={command=d.command,icon=d.icon,alias=d.alias,linked_action=d.linked_action,linked_type=d.linked_type}; return true end
binder.update_custom_action=function(old,d) catalog[old]=nil; catalog[d.name]={command=d.command,icon=d.icon}; return true end
local clock=100
local function tick(seconds) clock=clock+seconds; binder:tick_navigation(clock,true) end
tick(0)
local function choose(id)
    for col,rows in pairs(binder.selector.field_coords) do for row,o in pairs(rows) do
        if o.id==id then binder.selector.selected_row,binder.selector.selected_col=row,col end end end
    binder.selector:highlight_selection()
end

-- Review grid: four across in Sunshine's order, Save & Bind first.
assert(binder:new_custom_action('Ready All','menu'))
binder.custom_action_draft.command='input /pet "Ready" <me>'
binder:display_edit_custom_action_review()
assert(binder.selector.max_col==4 and binder.selector.max_row==2, 'four across')
local ids={};for _,o in ipairs(binder.selector.current_options) do ids[#ids+1]=o.id end
assert(table.concat(ids,',')=='SAVE_BIND,SAVE_EDIT,CHANGE_LINKED,CHANGE_ICON,CHANGE_NAME,CHANGE_ALIAS,CHANGE_COMMAND', table.concat(ids,','))
assert(binder.selector.current_options[1].icon:find('custom_actions.png',1,true), 'gear until an icon is set')

-- With a slot selected: ghost + glow on Save & Bind (gear icon).
binder.trigger_right_pressed=true; binder:edit_slot_press(7,true); binder:edit_slot_press(7,false); binder.trigger_right_pressed=false
choose('SAVE_BIND')
assert(binder:is_bind_ready() and binder:get_destination().ready, 'Save & Bind is bind-ready')
local ghost=binder:get_ghost()
assert(ghost and ghost:find('custom_actions.png',1,true), 'gear ghost on the slot')
binder:update_destination_footer()
assert(binder.selector.option_glow and binder.selector.option_glow:visible(), 'Save & Bind glows')
choose('CHANGE_NAME')
assert(not binder:is_bind_ready() and binder:get_ghost()==nil, 'other review entries do not bind')

-- An assigned icon replaces the Save & Bind picture and the ghost.
binder.custom_action_draft.icon='abilities/ready'
binder:display_edit_custom_action_review()
assert(binder.selector.current_options[1].icon:find('abilities/ready.png',1,true), 'Save & Bind shows the assigned icon')
choose('SAVE_BIND')
assert(binder:get_ghost():find('abilities/ready.png',1,true))

-- Save & Bind: saved, bound to the slot, flash + hold, back on Review and Edit at Save & Bind.
binder:submit_selected_option()
assert(catalog['Ready All'], 'saved to the catalog')
assert(#saved==1 and saved[1][1]==2 and saved[1][2]==7 and saved[1][4]=='Ready All', 'bound to the selected slot')
assert(#bound==1 and binder.bind_hold and binder.state==17, 'flash and hold on the review screen')
tick(.5)
assert(binder.state==17 and binder.editing_custom_action and binder.selector:get_selected_option().id=='SAVE_BIND',
    'stays on the review screen, now editing')
local ids2={};for _,o in ipairs(binder.selector.current_options) do ids2[#ids2+1]=o.id end
assert(ids2[#ids2]=='DELETE_CUSTOM_ACTION' and binder.selector.current_options[#ids2].name=='Delete Custom Action')

-- Without a slot: the old Enter Button Combo screen.
binder:clear_destination()
binder:submit_selected_option()
assert(binder.state==5 and binder.binding_custom_action_review, 'legacy Save & Bind flow without a slot')
binder:go_back()
assert(binder.state==17)

-- Review fields: Linked above Icon; Icon notes a linked action's icon.
binder.custom_action_draft.icon=nil
binder.custom_action_draft.linked_action='Ready'
binder:display_edit_custom_action_review()
local texts={}
for _,h in ipairs(binder.hints) do texts[#texts+1]=h.values.text end
local all=table.concat(texts,'|')
assert(all:find('Linked:|Ready|Icon:|(from Ready)',1,true), all)

-- Target title: the action name in amber after the title.
binder.custom_action_draft=nil; binder.editing_custom_action=false
binder.state,binder.action_type,binder.action_name=3,4,'Cure'
binder.target_type={Self=true,Party=true}
binder:display_target_selector()
assert(binder.title.values.text=='Select Action Target - \\cs(255,216,112)Cure\\cr', binder.title.values.text)

-- Set icons in Switch / Quick Switch.
assert(binder:set_icon('job-default','SMN'):find('jobs/SMN.png',1,true), 'JOB default uses the main job icon')
assert(binder:set_icon('default','SMN/WHM'):find('jobs/WHM.png',1,true), 'JOB/SUB default uses the subjob icon')
assert(binder:set_icon('all-jobs-default','ALL')==nil, 'ALL uses the face-button picture (A, 2026-11-21)')
assert(binder:set_icon('black','Black Magic')==nil, 'WHM/SMN has no Black Magic entry')
assert(binder:set_icon('songs','Song')==nil)
assert(binder:set_icon('rage','Rage'):find('jobs/SMN.png',1,true), 'a set named like a menu entry uses its icon')
assert(binder:set_icon('whm','White Magic'):find('jobs/WHM.png',1,true))
assert(binder:set_icon('misc','Travel')==nil)
print('custom action Save & Bind, review grid, target title and set icons: passed')
