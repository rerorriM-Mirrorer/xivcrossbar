-- Run the actual picker against Windows dir output. cmd.exe directory paths
-- must use backslashes even though the artwork resolver uses forward slashes.
local f=assert(io.open('ui/action_binder.lua'));local source=f:read('*a');f:close()
local chunk=assert(source:match('(function action_binder:display_icon_selector_sylvebits.-)\nfunction action_binder:display_text_entry'))
local function list(t)
    return setmetatable(t,{__index={append=function(self,v) self[#self+1]=v end,
        sort=function(self,fn) table.sort(self,fn) end}})
end
local output
local binder={title={text=function()end,show=function()end},
    selector={display_options=function(_,v) output=v end},show_control_hints=function()end}
local roots={'C:/Game Addons/images/overrides/icons/default','C:/Game Addons/images/icons/iconpacks/default','C:/Game Addons/images/icons/default'}
local scans=0
local env=setmetatable({action_binder=binder,icon_pack='default',L=list,
    get_icon_pathbase=function()return 'icons/default' end,
    require=function(name) assert(name=='ui/assets');return {pack_roots=function()return roots end} end,
    io={popen=function(command)
        scans=scans+1
        local paths={}
        if not command:find('/',command:find('"')+1,true) then
            paths={'C:\\Game Addons\\images\\icons\\default\\spells\\cure.png',
                'C:\\Game Addons\\images\\icons\\default\\feedback.png'}
        end
        return {lines=function() local i=0;return function()i=i+1;return paths[i] end end,close=function()end}
    end}}, {__index=_G})
assert(load(chunk,'actual icon picker','t',env))();binder:display_icon_selector_sylvebits()
assert(scans==3 and #output==1,'picker did not discover/deduplicate usable artwork')
assert(output[1].data.icon_path=='/spells/cure','saved icon stem changed')
print('Actual icon picker: Windows paths with spaces, three roots, deduplication and UI exclusion passed.')
