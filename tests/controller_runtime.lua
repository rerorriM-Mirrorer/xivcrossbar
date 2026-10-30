-- Production resolver: shortcut identity checks use simulated bounded files.
local runtime=require('libs/controller/runtime')
local root='C:/Windower/addons/xivcrossbar/'
local exe='C:/Program Files/AutoHotkey/v2/AutoHotkey64.exe'
local other='D:/Portable AHK/AutoHotkey64.exe'
local files
local function open(path)
    if not files[path] then return nil,'not found',2 end
    return {read=function(_,n)return files[path]:sub(1,n) end,
        seek=function()return #files[path] end,close=function()return true end}
end
local function cache(version,protocol,directory)
    return '[Runtime]\nprotocol='..(protocol or 'ahk-v2-link1')..'\nexecutable='..exe..
        '\nversion='..(version or '2.0.31')..'\nsize=20\ndirectory='..(directory or root)..'\nlink_size=8\nEND\n'
end
local function fresh(version,protocol)
    files={[exe]=string.rep('a',20),[other]=string.rep('b',30),
        [root..'data/controller-start.lnk']='shortcut',
        [root..'data/controller-runtime-cache.ini']=cache(version,protocol)}
    return runtime.new({open=open})
end
local function plan(r,profile,device,modifier)
    return r:plan(root,profile or 'ps5-extended',device or 1,modifier or 'apps',
        {ahk_major='2',ahk_version='2.0.31',ahk_path=exe})
end
local r=fresh();local p=assert(plan(r))
assert(p.mode=='direct' and p.source=='cache' and p.executable==exe)
assert(p.shortcut==root..'data/controller-start.lnk')
assert(p.command=='run addons/xivcrossbar/data/controller-start.lnk')
assert(not p.arguments,'selection must remain in launch.ini, never frozen in shortcut')
p=assert(plan(r,'xinput-extended',4,'ctrl'));assert(p.mode=='direct')
assert(p.fallback_command=='run addons/xivcrossbar/launch-controller.cmd ctrl xinput-extended 4')
-- Old caches/status cannot manufacture a Windows shortcut. One upgrade bootstrap.
r=fresh(nil,'ahk-v2-cache1');assert(plan(r).mode=='bootstrap')
r=fresh();files[root..'data/controller-runtime-cache.ini']=nil;assert(plan(r).mode=='bootstrap')
r=fresh();files[root..'data/controller-start.lnk']=nil;assert(plan(r).mode=='bootstrap')
r=fresh();files[root..'data/controller-start.lnk']='changed';assert(plan(r).mode=='bootstrap')
r=fresh();files[exe]=files[exe]..'x';assert(plan(r).mode=='bootstrap')
r=fresh();files[exe]=nil;assert(plan(r).mode=='bootstrap')
r=fresh();files[root..'data/controller-runtime-cache.ini']=cache(nil,nil,'D:/Moved/');assert(plan(r).mode=='bootstrap')
r=fresh();files[root..'data/controller-runtime-cache.ini']=cache():gsub('END\n$','');assert(plan(r).mode=='bootstrap')
r=fresh();files[root..'data/controller-runtime-cache.ini']=string.rep('x',4097);assert(plan(r).mode=='bootstrap')
for _,v in ipairs({'1.1.37','2.0.18','2.0.19-bad','bad','2.0.19..'}) do r=fresh(v);assert(plan(r).mode=='bootstrap',v) end
for _,v in ipairs({'2.0.19','2.0.20','2.1.0','2.0.19.0'}) do r=fresh(v);assert(plan(r).mode=='direct',v) end
r=fresh();files[root..'data/controller-runtime.ini']='[Runtime]\nexecutable='..other..'\n';assert(plan(r).mode=='bootstrap')
r=fresh();files[root..'data/controller-runtime.ini']='\239\187\191[Runtime]\nexecutable="'..exe..'"\n';assert(plan(r).mode=='direct')
for _,path in ipairs({'AutoHotkey64.exe','C:/bad;reload.exe','C:/bad"quote.exe','C:/bad\npath.exe','C:/wrong.dll'}) do
    r=fresh();files[root..'data/controller-runtime.ini']='[Runtime]\nexecutable='..path..'\n';assert(not plan(r),path)
end
r=fresh();files[root..'data/controller-runtime.ini']='[Other]\nexecutable='..exe..'\n';assert(not plan(r))
r=fresh();assert(not plan(r,'bogus'));assert(not plan(r,'xinput',5));assert(not plan(r,nil,nil,'shift'))
assert(not r:plan('C:/unsafe;command/','ps5-extended',1,'apps'))
-- Native Windows paths and spaces never enter Run's argument parser.
r=fresh();local native_root='C:\\Users\\Player\\Saved Games\\Windower\\addons\\xivcrossbar\\'
files[native_root..'data/controller-start.lnk']='shortcut'
files[native_root..'data/controller-runtime-cache.ini']=cache(nil,nil,native_root)
p=assert(r:plan(native_root,'ps5-extended',1,'apps'))
assert(p.mode=='direct' and p.command=='run addons/xivcrossbar/data/controller-start.lnk')
print('Shortcut resolver: verified cache, upgrade discovery, changed/missing/moved files, explicit overrides, version/profile validation and argument-free Run command passed.')
