-- Exercise the real private library's registry with lightweight I/O/collection
-- stand-ins. XML parsing/serialization are replaced, not claimed as tested here.
local function read(path)
    local f=assert(io.open(path,'rb')); local s=f:read('*a'); f:close(); return s
end
local shared, shared_settings = {}, {}
local shared_writes, private_writes = 0, 0
function shared.save(t)
    assert(t==shared_settings, 'Foreign table reached shared config')
    shared_writes=shared_writes+1
end
package.preload.config=function() _libs.config=shared; return shared end
local methods={}
function methods:update(t) for k,v in pairs(t) do self[k]=v end; return self end
_meta={T={__index=methods}}
function T(t) return setmetatable(t or {},_meta.T) end
function S() return {} end
local helpers={}
function helpers.copy(t) local r=T{}; for k,v in pairs(t) do r[k]=v end; return r end
_libs={tables=helpers,sets={},lists={},strings={}}
for _,name in ipairs({'tables','sets','lists','strings'}) do package.preload[name]=function() return {} end end
package.preload.xml=function() return {} end
package.preload.json=function() return {} end
package.preload.files=function() return {new=function() return {exists=function() return true end,
    write=function(_,contents) assert(contents=='serialized'); private_writes=private_writes+1 end} end} end
windower={ffxi={get_info=function() return {logged_in=true} end},register_event=function() end}
local runtime_root=assert(package.path:match('^([^;]*)%?%.lua;'))
warning=function() end; notice=function() end; log=function() end
local source=read(runtime_root..'libs/settings_config.lua')
-- Bypass parsing only: config.load still creates and owns its real registry.
source=source:gsub('return parse%(settings%)','return settings',1)
local private=assert(load(source,'@libs/settings_config.lua'))()
assert(private~=shared and _libs.config==shared, 'Private config replaced shared singleton')
local settings=private.load({AutoHold=1.5})
-- Replace serialization only; save must find its own metadata and update it.
for i=1,30 do
    local name=debug.getupvalue(private.save,i)
    if not name then break end
    if name=='settings_xml' then debug.setupvalue(private.save,i,function() return 'serialized' end) end
end
-- Simulate a shared-library load assigning the global module name later.
config=shared
private.save(settings,'all')
_libs.config.save(shared_settings)
assert(private_writes==1 and shared_writes==1, 'Both registries must save independently')
for _,path in ipairs({'xivcrossbar.lua','ui.lua','player.lua','action_binder.lua','environment_chooser.lua'}) do
    assert(read(path):find("local config = require('libs/settings_config')",1,true),
        path..' must retain its own module reference after a shared require')
end
assert(source:find('table.copy(meta.original.global)',1,true), 'Global inheritance fix must remain')
print('Private/shared config ownership, independent saves and explicit consumer imports passed.')
