-- Exercise the actual Change Icon folder browser, not the recursive picker.
local f=assert(io.open('ui/action_binder.lua'));local s=f:read('*a');f:close()
local a=assert(s:find('local icon_picker_excluded_files',1,true))
local b=assert(s:find('function action_binder:apply_icon_change',a,true))
local function list(t)return setmetatable(t,{__index={append=function(self,v)self[#self+1]=v end}})end
local output,commands
local binder={title={text=function()end,show=function()end},selector={display_options=function(_,v)output=v end},show_control_hints=function()end}
local env=setmetatable({action_binder=binder,action_types={},icon_pack='default',L=list,
 get_icon_pathbase=function()return 'icons/default'end,
 require=function(name)assert(name=='ui/assets');return {pack_roots=function()return {'C:/Game Addons/images/overrides/icons/default','C:/Game Addons/images/icons/iconpacks/default','C:/Game Addons/images/icons/default'}end}end,
 io={popen=function(command)
  commands[#commands+1]=command
  assert(not command:match('"[^"]*/'),'Windows command contains forward slash')
  local rows={}
  if command:find('icons\\default',1,true) then
   if command:find('/a:d',1,true) then rows={'spells','binding_icons'}
   else rows={'Quest.PNG','feedback.png','not-an-icon.txt'}end
  end
  return {lines=function()local i=0;return function()i=i+1;return rows[i]end end,close=function()end}
 end}}, {__index=_G})
assert(load(s:sub(a,b-1),'actual folder picker','t',env))()
for _,path in ipairs({'','spells'})do
 commands={};binder:display_icon_selector(path)
 assert(#commands==6 and #output==2,'Missing roots, deduplication or exclusions')
 assert(output[1].data.is_dir and output[1].name=='spells >')
 assert(output[2].data.icon_path==(path=='' and 'Quest' or 'spells/Quest'))
end
print('Actual folder icon picker: all asset roots, full Windows normalization, nested folders, case-insensitive PNGs/dedup and exclusions passed.')
