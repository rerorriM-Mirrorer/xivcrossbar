-- Real binder and slot-save/execute paths; only Windower I/O is mocked.
dofile('tests/menu_resources.lua')
local choices=require('crossbar_destinations')
local bars={basic={name='Basic'},default={name='Default'},['job-default']={name='Job Default'},
    ['all-jobs-default']={name='Universal'},['all-warps']={name='Warps'},shared={name='Shared'}}
local entries=choices.build(bars)
assert(entries[1].key=='default' and entries[2].key=='job-default' and entries[3].key=='all-jobs-default')
assert(entries[3].name=='Universal' and bars['all-jobs-default'].name=='Universal')
assert(#entries==6 and choices.build({})[1]==nil)
local binder=require('action_binder')
local player=package.loaded.player
player.hotbar=bars;player.hotbar_settings={active_environment='basic',active_hotbar=2}
local builds,saves=0,0
local env=setmetatable({player=player,theme_options={},action_manager={build=function(_,kind,action,target,alias,icon)
    builds=builds+1;return{type=kind,action=action,target=target,alias=alias,icon=icon}
end},windower={add_to_chat=function()end},reload_hotbar=function()return true end,
    set_active_environment=function(key)assert(bars[key]);player.hotbar_settings.active_environment=key end,
    is_valid_environment=function(key)return bars[key]~=nil end}, {__index=_G})
function player:add_action(action,key,bar,slot)
    bars[key]['hotbar_'..bar]=bars[key]['hotbar_'..bar] or {}
    bars[key]['hotbar_'..bar]['slot_'..slot]=action
end
function player:save_hotbar()saves=saves+1 end
local f=assert(io.open('xivcrossbar.lua'));local root=f:read('*a');f:close()
local a=assert(root:find('function set_hotkey(',1,true));local b=assert(root:find('function delete_hotkey(',a,true))
assert(load(root:sub(a,b-1),'actual slot save','t',env))()
a=assert(root:find('function switch_crossbars_command(',1,true));b=assert(root:find('-- command to set an action',a,true))
assert(load(root:sub(a,b-1),'actual switch command','t',env))()
env.windower.send_command=function(command)
    local key=command:match('^xb bar ([%w%-]+)$')
    if key then env.switch_crossbars_command({key}) else assert(command=='input /echo one') end
end
f=assert(io.open('player.lua'));local source=f:read('*a');f:close()
a=assert(source:find('function player:execute_action(',1,true))
-- dispatch_action is followed by next code; the ex branch returns early.
b=source:find('\nfunction player:',source:find('function player:dispatch_action(',a,true)+10,true) or (#source+1)
env.kebab_casify=function(value)return value:lower():gsub('%s+','-')end
assert(load(source:sub(a,b-1),'actual action execution','t',env))()
player.is_valid_environment=function(_,key)return bars[key]~=nil end
local options=require('theme').apply(require('defaults'));options.button_layout='playstation'
binder:setup({button_layout='playstation',confirm_button='cross',cancel_button='circle'},env.set_hotkey,function()end,
    options,function()return choices.build(bars)end)
local function pick(key,quick)
    binder.action_type=quick and 40 or 31 -- QUICK_SWITCH_CROSSBARS / SWITCH_CROSSBARS
    binder.state=2 -- SELECT_ACTION
    binder:display_crossbar_sets_selector()
    local found=false
    for col,rows in pairs(binder.selector.field_coords) do
        for row,entry in pairs(rows) do
            if entry.id==key then binder.selector.selected_row,binder.selector.selected_col=row,col;found=true end
        end
    end
    assert(found,'destination omitted: '..key)
    local selected=binder.selector:get_selected_option()
    assert(selected.text==bars[key].name and selected.data.action_name==key)
    assert(io.open('images/icons/iconpacks/default/ui/facebuttons_playstation.png','rb')):close()
    binder:submit_selected_option()
    binder.active_crossbar,binder.hotkey=2,7
    binder:assign_action()
end
pick('all-jobs-default',false)
local first=bars.basic.hotbar_2.slot_7
assert(first.type=='ex' and first.action=='xb bar all-jobs-default' and first.alias=='Universal')
player:execute_action(7);assert(player.hotbar_settings.active_environment=='all-jobs-default')
pick('basic',false)
player:execute_action(7);assert(player.hotbar_settings.active_environment=='basic')
player:execute_action(7);assert(player.hotbar_settings.active_environment=='all-jobs-default')
-- Quick-switch stores the key too, and still returns after the next action.
player.hotbar_settings.active_environment='basic';pick('all-jobs-default',true)
assert(bars.basic.hotbar_2.slot_7.type=='switch' and bars.basic.hotbar_2.slot_7.action=='all-jobs-default')
player:execute_action(7);assert(player.pending_env_switch=='all-jobs-default' and player.temp_switch_previous_env=='basic')
player.hotbar_settings.active_environment=player.pending_env_switch;player.pending_env_switch=nil
bars['all-jobs-default'].hotbar_2.slot_1={type='ex',action='input /echo one'}
player:execute_action(1);assert(player.pending_env_switch=='basic' and player.temp_switch_previous_env==nil)
player.hotbar_settings.active_environment='basic'
for _,key in ipairs({'default','job-default','all-warps'}) do
    pick(key,false)
    assert(bars.basic.hotbar_2.slot_7.action=='xb bar '..key)
end
assert(builds==6 and saves==6)
-- Selecting another action after Back replaces previous destination metadata.
binder.state,binder.action_type=2,4
binder.action_alias,binder.action_command,binder.action_icon='Old label','xb bar default','old-icon'
binder.selector:display_options(L{{id='spell',name='Cure',icon='spell.png',data={target_type={Self=true,Party=true}}}})
binder:submit_selected_option()
assert(binder.action_alias==nil and binder.action_command==nil and binder.action_icon==nil)
binder:hide();binder:reset_state()
require('ui/resources').destroy_all()
print('Default destinations, renamed labels, actual binder/slot save, same-slot round trips and quick-switch return passed.')
