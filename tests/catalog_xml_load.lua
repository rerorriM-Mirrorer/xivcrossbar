-- Execute the actual XML loader and action constructor, not just the sync helper.
local f=assert(io.open('libs/player.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('function kebab_casify',1,true))
local z=assert(source:find('-- A: a missing layer file',a,true))
local setup=source:match('(function player:setup_environment_hotbars.-)\n%-%- set bar environment')
local add=source:match('(function player:add_action.-)\nfunction create_send_command_coroutine')
assert(setup and add)
local storage=require('libs/storage')
local action_manager=require('libs/action_manager')
local bindings=require('libs/catalog_bindings')
local function dom(fields,bar,slot)
    local tags={}
    for key,value in pairs(fields) do
        tags[#tags+1]={name=key,children=value=='' and {} or {{value=value}}}
    end
    return{name='hotbar',children={{name='all-jobs-default',children={
        {name='name',children={{value='All Jobs Default'}}},
        {name='hotbar_'..(bar or 'l'),children={{name='slot_'..(slot or 'ru'),children=tags}}},
    }}}}
end
local fields={type='ex',action='input /echo old',alias='Slot override',icon='assist',
    catalog_id='stable-id',catalog_scope='global',catalog_name='Old name',
    catalog_last_action='input /echo old',catalog_last_alias='Old alias',catalog_last_icon='assist',
    catalog_last_linked_action='',catalog_last_linked_type=''}
local tree=dom(fields)
local player={hotbar={},hotbar_settings={max=6},shared_icons={}}
local env=setmetatable({player=player,storage=storage,action_manager=action_manager,
    settings={Hotbar={HideActionName=false}},
    xml={read=function()return tree end},unescape=function(s)return s end,
    windower={add_to_chat=function()end,console={write=function()error('bad bar')end}},
}, {__index=_G})
assert(load(source:sub(a,z-1)..setup..add,'actual XML loader','t',env))()
assert(player:load_from_file({path='fixture'}))
local slot=player.hotbar['all-jobs-default'].hotbar_1.slot_8
assert(slot.catalog_id=='stable-id' and slot.catalog_scope=='global')
assert(slot.catalog_name=='Old name' and slot.catalog_last_alias=='Old alias')
assert(bindings.apply(slot,{id='stable-id',name='New name',command='input /echo new',alias='New alias',icon='assist'}))
assert(slot.action=='input /echo new' and slot.alias=='Slot override','slot override was lost')
local roundtrip={}
for key,value in pairs(slot) do if type(value)=='string' then roundtrip[key]=value end end
tree=dom(roundtrip);player.hotbar={};assert(player:load_from_file({path='fixture'}))
local loaded=player.hotbar['all-jobs-default'].hotbar_1.slot_8
assert(loaded.catalog_id=='stable-id' and loaded.catalog_name=='New name' and loaded.action=='input /echo new')
local records={['@retired:stable-id']={id='stable-id',name='New name',command='input /echo new',deleted='true'},
    ['New name']={id='replacement-id',name='New name',command='input /echo replacement'}}
assert(bindings.find(records,loaded.catalog_id).deleted=='true','recreated name stole identity after XML load')
tree=dom({type='ex',action='se',alias='Enter'},'rr','rd');player.hotbar={}
assert(player:load_from_file({path='fixture'}))
assert(player.hotbar['all-jobs-default'].hotbar_6.slot_6.action=='se')
assert(not player.hotbar['all-jobs-default'].hotbar_6.slot_6.catalog_id)
print('Real XML loader + constructor: catalog identity/snapshot roundtrip, rename/update, slot overrides, retired identities and portable sixth-bar binding passed.')
