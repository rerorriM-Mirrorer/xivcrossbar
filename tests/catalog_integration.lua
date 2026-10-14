-- Exercise the actual player methods with catalog I/O and Windows locking mocked.
dofile('tests/custom_catalog.lua')
local catalog=require('custom_catalog')
local bindings=require('catalog_bindings')
local f=assert(io.open('player.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('local function read_catalog_file',1,true))
local z=assert(source:find('function player:store_new_hotbars()',a,true))
local files={
    ['addon/data/CustomActions.xml']=catalog.encode({Bow={name='Bow',id='g',command='input /bow'}}),
    ['addon/data/hotbar/Fenrir/Test/CustomActions.xml']=catalog.encode({Local={name='Local',id='p',command='input /echo private'}}),
}
local actual_open=io.open
io.open=function(path,mode)
    if path:find('CustomActions.xml',1,true) then
        if files[path]==nil then return nil,'missing' end
        return {read=function()return files[path]end,close=function()end}
    end
    return actual_open(path,mode)
end
windower={addon_path='addon/',create_dir=function()end}
file={new=function(path)return{exists=function()return files['addon/'..path]~=nil end}end}
xml={parse=catalog_test_parse}
package.loaded['windows_file']={new=function()return{pid=123,lock=function()return function()end end,
    replace=function(path,raw)files[path]=raw;return true end}end}
package.loaded.socket={gettime=function()return 111 end}
local storage={identity_valid=true,global_catalog_path='addon/data/CustomActions.xml',character_catalog_path='addon/data/hotbar/Fenrir/Test/CustomActions.xml'}
local player={identity_confirmed=true,name='Test',hotbar={}}
_G.integration_player,_G.integration_storage=player,storage
local block=assert(load("local player,storage=integration_player,integration_storage;local catalog=require('custom_catalog');local catalog_bindings=require('catalog_bindings');\n"..source:sub(a,z-1)))
block()
assert(player:refresh_custom_catalogs())
assert(player.custom_actions.Bow and player.custom_actions.Local)
local new={name='Dance',command='input /dance'}
assert(player:save_catalog_edit(nil,new))
assert(new._scope=='global' and player.custom_actions.Dance)
local private=player:find_custom_action('Local')
local draft={name='Local',command='input /echo edited',_expected=catalog.copy(private)}
assert(player:save_catalog_edit('Local',draft))
assert(draft._scope=='character')
assert(not catalog.decode(files[storage.global_catalog_path],xml.parse).Local)
local rec=player:find_custom_action('Bow')
local slot={type='ex',action='input /bow',alias='Bow'}
bindings.attach(slot,rec,'global')
player.hotbar={basic={hotbar_1={slot_1=slot}}}
local edit={name='Greeting',command='input /wave',_expected=catalog.copy(rec)}
assert(player:save_catalog_edit('Bow',edit))
assert(slot.action=='input /wave' and slot.catalog_name=='Greeting')
assert(player:save_catalog_edit('Greeting',nil))
assert(not player.custom_actions.Greeting and slot.action=='input /wave')
assert(player:save_catalog_edit(nil,{name='Greeting',command='input /echo new'}))
assert(slot.action=='input /wave','recreated name stole retired binding')
io.open=actual_open
print('Actual player catalog methods: combined loads, default saves, source-owned edits, binding updates and delete/recreate passed.')
