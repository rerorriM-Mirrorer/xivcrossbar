-- Exercise the shared client registry and its saved-state migration in public source.
local records,held={},{}
local backend={session_id='public-test-1',token='public-test-1',clock=function()return 55 end}
function backend.hold_owner(path)
    held[path]=true
    return {close=function()held[path]=nil end}
end
function backend.replace(path,content)records[path]=content;return true end
local created
windower={create_dir=function(path)created=path end}
local owner=require('libs/controller/clients').new({directory='data/controller-clients/',backend=backend})
assert(created=='data/controller-clients/')
assert(owner:register(true))
local record=records['data/controller-clients/public-test-1.ini']
assert(record:find('state=loaded',1,true) and record:find('kill=true',1,true))
assert(held['data/controller-clients/public-test-1.ini.owner'])
assert(owner:register(false))
assert(records[owner.path]:find('kill=false',1,true))
assert(owner:close(false))
assert(records[owner.path]:find('state=closing',1,true) and records[owner.path]:find('kill=false',1,true))
assert(not held['data/controller-clients/public-test-1.ini.owner'])
assert(owner:close(false))
local f=assert(io.open('xivcrossbar.lua','rb'));local root=f:read('*a');f:close()
local d=require('defaults')
assert(d.on_unload_killahk==true and d.WrapperShutdownMigrated==false)
assert(root:find('settings.WrapperShutdownMigrated=true',1,true))
assert(root:find('registry:register(settings.on_unload_killahk)',1,true))
assert(root:find('client_registry:close(settings.on_unload_killahk)',1,true))
assert(root:find("mode == 'autostop'",1,true))
print('Public client registry, owner handles, saved preference migration, close and autostop wiring passed.')
