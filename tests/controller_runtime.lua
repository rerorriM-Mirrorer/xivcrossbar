-- Production resolver under stock Lua, with bounded file I/O simulated.
local runtime=require('libs/controller/runtime')
local root='C:/Windower/addons/xivcrossbar/'
local exe='C:/Program Files/AutoHotkey/v2/AutoHotkey64.exe'
local other='D:/Portable AHK/AutoHotkey64.exe'
local files,writes={},0
local function open(path,mode)
    if mode=='wb' then
        writes=writes+1
        return {write=function(_,s)files[path]=s;return true end,close=function()return true end}
    end
    if not files[path] then return nil,'not found',2 end
    return {read=function(_,n)return files[path]:sub(1,n) end,
        seek=function()return #files[path] end,close=function()return true end}
end
local function status(version,path)
    return {ahk_major='2',ahk_version=version or '2.0.19',ahk_path=path or exe,state='stopped',pid='0'}
end
local function fresh()
    files={[exe]=string.rep('a',20),[other]=string.rep('b',30)};writes=0
    return runtime.new({open=open})
end
local function plan(r,s,profile,device,modifier)
    return r:plan(root,profile or 'ps5-extended',device or 1,modifier or 'apps',s)
end
local r=fresh();local p=assert(plan(r,status()))
assert(p.mode=='direct' and p.source=='status' and p.executable==exe)
assert(p.command=='run "'..exe..'" /ErrorStdOut "'..root..'ffxi_directinput.ahk" apps ps5-extended 1')
assert(not p.command:lower():find('powershell',1,true) and not p.command:find('launch-controller.cmd',1,true))
assert(writes==1 and files[root..'data/controller-runtime-cache.ini']:sub(-4)=='END\n')
r=runtime.new({open=open});p=assert(plan(r,nil,'xinput-extended',4,'ctrl'))
assert(p.source=='cache' and p.arguments:find('ctrl xinput%-extended 4$') and writes==1)
p=assert(plan(r,status('1.1.37')));assert(p.source=='cache','stale status overrode a good cache')
-- A changed size must not be blessed by old status from that same path.
files[exe]=files[exe]..'x';p=assert(plan(r,status()));assert(p.mode=='bootstrap')
r=fresh();p=assert(plan(r));assert(p.mode=='bootstrap' and writes==0)
assert(p.command=='run addons/xivcrossbar/launch-controller.cmd apps ps5-extended 1')
for _,version in ipairs({'1.1.37','2.0.18','2.0.19-bad','bad','2.0.19..'}) do
    r=fresh();p=assert(plan(r,status(version)));assert(p.mode=='bootstrap',version)
end
for _,version in ipairs({'2.0.19','2.0.20','2.1.0','2.0.19.0'}) do
    r=fresh();assert(plan(r,status(version)).mode=='direct',version)
end
r=fresh();files[exe]=nil;assert(plan(r,status()).mode=='bootstrap')
r=fresh();files[root..'data/controller-runtime-cache.ini']='[Runtime]\nprotocol=ahk-v2-cache1\nexecutable='..exe..'\nversion=2.0.19\nsize=20\n'
assert(plan(r,status()).mode=='bootstrap','partial cache authorized fast path')
r=fresh();files[root..'data/controller-runtime.ini']='[Runtime]\nexecutable='..other..'\n'
p=assert(plan(r,status()));assert(p.mode=='bootstrap','changed explicit path reused previous interpreter')
r=fresh();files[root..'data/controller-runtime.ini']='\239\187\191[Runtime]\nexecutable="'..exe..'"\n'
p=assert(plan(r,status()));assert(p.mode=='direct')
for _,path in ipairs({'AutoHotkey64.exe','C:/bad;reload.exe','C:/bad"quote.exe','C:/bad\npath.exe','C:/wrong.dll'}) do
    r=fresh();files[root..'data/controller-runtime.ini']='[Runtime]\nexecutable='..path..'\n'
    local value=plan(r,status());assert(not value,path)
end
r=fresh();files[root..'data/controller-runtime.ini']='[Other]\nexecutable='..exe..'\n'
assert(not plan(r,status()))
r=fresh();files[root..'data/controller-runtime-cache.ini']=string.rep('x',4097)
assert(plan(r,nil).mode=='bootstrap')
r=fresh();assert(not plan(r,status(),'bogus'));assert(not plan(r,status(),'xinput',5));assert(not plan(r,status(),nil,nil,'shift'))
assert(not r:plan('C:/unsafe;command/','ps5-extended',1,'apps',status()))
-- Cache is an optimization; failed persistence must not block the verified
-- prior-runtime path on an installation being upgraded.
r=fresh();r=runtime.new({open=open,replace=function()return false,'read-only' end})
assert(plan(r,status()).mode=='direct')
print('Actual runtime planner: status migration, persisted direct start, quoting, override changes, missing/replaced executable, partial/version-invalid cache, profile validation and recovery discovery passed.')
