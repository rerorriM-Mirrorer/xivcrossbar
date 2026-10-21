local Assets=require('ui/assets')
local files={}
windower={addon_path='C:/Windower/addons/xivcrossbar/',file_exists=function(path)return files[path]==true end}
local base=windower.addon_path
local function available(paths)
    files={};for _,p in ipairs(paths)do files[base..p]=true end;Assets.invalidate()
end
local new='images/icons/default/abilities/provoke.png'
local old='images/icons/iconpacks/default/abilities/provoke.png'
available({new})
assert(Assets.resolve(base..old)==base..new)
assert(Assets.resolve('/'..old)==base..new)
assert(Assets.resolve(base..'/images/icons/default/abilities/provoke.png')==base..new)
available({new,old});assert(Assets.resolve(base..new)==base..old,'legacy custom art lost')
local override='images/overrides/icons/default/abilities/provoke.png'
available({new,old,override});assert(Assets.resolve(base..new)==base..override)
available({'images/themes/ffxiv/frame.png'})
assert(Assets.resolve(base..'themes/ffxiv/frame.png')==base..'images/themes/ffxiv/frame.png')
available({'themes/ffxiv/frame.png','images/themes/ffxiv/frame.png'})
assert(Assets.resolve(base..'images/themes/ffxiv/frame.png')==base..'themes/ffxiv/frame.png')
local numeric='images/icons/default/fallback/abilities/00001.png'
available({numeric})
assert(Assets.resolve(base..'images/icons/abilities/00001.png')==base..numeric)
available({'images/icons/abilities/00001.png'})
assert(Assets.resolve(base..numeric)==base..'images/icons/abilities/00001.png')
available({new})
assert(Assets.resolve(base..'images/icons/alternate/abilities/provoke.png')==base..new,'alternate pack fallback missing')
assert(Assets.resolve('D:/personal/icon.png')=='D:/personal/icon.png')
assert(Assets.resolve(base..'images/extracted_items_v5/100.bmp')==base..'images/extracted_items_v5/100.bmp')
-- Real resource wrapper routes legacy paths through the resolver too.
local actual
images={new=function()return {path=function(_,v)actual=v end,destroy=function()end}end}
local image=require('ui/resources').image({})
image:path(base..old);assert(actual==base..new)
image:destroy();assert(not pcall(function()image:path(base..old)end),'disposed image accepted a path')
require('libs/module_paths').install()
assert(require('companion_banks')==require('libs/banks/banks'))
assert(require('ui_drag')==require('ui/drag'))
-- Actual icon chooser combines all three roots and exposes numeric fallbacks.
local f=assert(io.open('ui/action_binder.lua'));local source=f:read('*a');f:close()
local first=assert(source:find('function action_binder:display_icon_selector_sylvebits()',1,true))
local last=assert(source:find('function action_binder:display_text_entry',first,true))
local roots=Assets.pack_roots('default')
local listings={[roots[1]]={roots[1]..'/abilities/provoke.png'},
    [roots[2]]={roots[2]..'/abilities/provoke.png',roots[2]..'/custom.png'},
    [roots[3]]={roots[3]..'/abilities/provoke.png',roots[3]..'/fallback/abilities/00001.png',roots[3]..'/ui/frame_step1.png'}}
local entries
local env=setmetatable({action_binder={},icon_pack='default',
    L=function(t)return setmetatable(t,{__index={append=function(self,v)table.insert(self,v)end,sort=table.sort}})end,
    get_icon_pathbase=function()return 'icons/default'end,
    io={popen=function(command)
        local folder=command:match('"(.-)\\%*%.png"')
        assert(not folder:find('/',1,true),command)
        folder=folder:gsub('\\','/')
        assert(listings[folder],command)
        local i=0
        return{lines=function()return function()i=i+1;return listings[folder][i]end end,close=function()end}
    end}}, {__index=_G})
assert(load(source:sub(first,last-1),'actual canonical/legacy icon chooser','t',env))()
local chooser={title={text=function()end,show=function()end},show_control_hints=function()end,
    selector={display_options=function(_,list)entries=list end}}
env.action_binder.display_icon_selector_sylvebits(chooser)
assert(#entries==3,'chooser lost fallback/custom art or retained duplicates/structural images')
local found={};for _,entry in ipairs(entries)do found[entry.data.icon_path]=true end
assert(found['/abilities/provoke'] and found['/custom'] and found['/fallback/abilities/00001'])
print('Asset paths: clean/legacy/override art, themes, numeric fallback, alternate packs, derived/external paths, actual image wrapper and legacy module aliases passed.')
