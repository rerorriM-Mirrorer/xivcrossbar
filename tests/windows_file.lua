-- Stock-Lua dependency, cross-client lock ownership and Windows rename behavior.
local native_require=require
require=function(name)assert(name~='ffi','FFI dependency returned');return native_require(name)end
local M=require('libs/windows_file')
local reserved,sequence={},100
local socket={gettime=function()return 1000 end}
function socket.tcp()
    sequence=sequence+1
    local port=sequence
    return{bind=function()return 1 end,getsockname=function()return '127.0.0.1',port end,close=function()end}
end
function socket.udp()
    local port,closed
    return{
        setoption=function(_,key,value)assert(key=='reuseaddr' and value==false);return 1 end,
        setsockname=function(_,_,candidate)
            if reserved[candidate] then return nil,'busy' end
            port=candidate;reserved[port]=true;return 1
        end,
        close=function()if not closed and port then reserved[port]=nil end;closed=true end,
    }
end
local files={catalog='old'}
local fail_publish,fail_restore=false,false
local handles={}
local function open(path,mode)
    if mode=='rb' and not files[path] then return nil,'missing' end
    if mode=='wb' then files[path]='' end
    handles[path]=(handles[path] or 0)+1
    return{read=function()return files[path]end,
        write=function(self,s)files[path]=s;return self end,
        close=function()handles[path]=handles[path]-1;return true end}
end
local function rename(a,b)
    if fail_publish and a:find('.tmp.',1,true) then return nil,'publish failed' end
    if fail_restore and a=='catalog.pending' then return nil,'restore failed' end
    if files[b]~=nil or files[a]==nil then return nil,'Windows rename refuses overwrite/missing source' end
    files[b],files[a]=files[a],nil;return true
end
local function remove(p)files[p]=nil;return true end
local a=M.new{socket=socket,open=open,rename=rename,remove=remove}
local b=M.new{socket=socket,open=open,rename=rename,remove=remove}
assert(a.session_id~=b.session_id,'sessions collided')
assert(M.lock_port('D:\\ADDON\\data\\CustomActions.xml')==M.lock_port('d:/addon/data/customactions.xml'))
local release=assert(a.lock('catalog'))
assert(not b.lock('CATALOG'),'two clients acquired the same save lock')
release();release()
local release2=assert(b.lock('catalog'));release2()
assert(a.replace('catalog','new'));assert(files.catalog=='new' and files['catalog.pending']==nil)
fail_publish=true
assert(not a.replace('catalog','bad') and files.catalog=='new','failed publication lost original')
fail_restore=true
local ok,err=a.replace('catalog','bad')
assert(not ok and err:find('catalog.pending',1,true) and files['catalog.pending']=='new')
fail_publish,fail_restore=false,false
assert(a.replace('catalog','recovered') and files.catalog=='recovered','interrupted replacement did not recover')
files['catalog.pending']='old pending'
assert(a.replace('catalog','latest') and files.catalog=='latest','published revision with stale pending failed')
local owner=assert(a.hold_owner('session.owner'))
assert(handles['session.owner']==1);owner:close();assert(handles['session.owner']==0)
for path,count in pairs(handles) do assert(count==0,'handle leaked: '..path) end
require=native_require
print('No FFI: distinct sessions, canonical cross-client lock contention/release, Windows replacement rollback/recovery and owner-handle lifetime passed.')
