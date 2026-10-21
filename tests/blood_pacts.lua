local P=require('libs/blood_pacts')
local res={
 [512]={id=512,en='Healing Ruby',type='BloodPactWard',targets={Self=true}},
 [513]={id=513,en='Poison Nails',type='BloodPactRage',targets={Enemy=true}},
 [518]={id=518,en='Searing Light',type='BloodPactRage'},
 [529]={id=529,en='Crescent Fang',type='BloodPactRage'},
 [1151]={id=1151,en='Flame Breath',type='Monster'}}
local available={job_abilities={529,513,512,1151},pet_commands={513}}
local rage=P.available(res,available,'BloodPactRage')
assert(#rage==2 and rage[1].id==529 and rage[2].id==513,'availability/category/sort/dedup')
assert(#P.available(res,available,'BloodPactWard')==1)
assert(#P.available(res,nil,'BloodPactRage')==0,'missing state exposed unavailable abilities')
assert(#P.available(res,{job_abilities={999}},'BloodPactRage')==0)
local files={};local function exists(p)return files[p]end
local meta={custom_icon='blood-pacts/rage/poison-nails.png',default_icon='/old/default.png'}
local icon,custom=P.icon(res[513],meta,'icons/test',exists)
assert(icon=='images/icons/default/fallback/abilities/00173.png' and not custom)
files['images/icons/test/bloodpact.png']=true
icon,custom=P.icon(res[513],meta,'icons/test',exists);assert(icon=='images/icons/test/bloodpact.png' and custom)
files['images/icons/test/blood-pacts/rage/poison-nails.png']=true
icon,custom=P.icon(res[513],meta,'icons/test',exists);assert(icon=='images/icons/test/blood-pacts/rage/poison-nails.png' and custom)
files={};icon,custom=P.icon(res[512],nil,'icons/default',exists)
assert(icon=='images/icons/default/fallback/abilities/00174.png' and not custom)
for _,id in ipairs({'00173','00174'}) do local f=assert(io.open('images/icons/default/fallback/abilities/'..id..'.png','rb'));f:close() end
-- Actual chooser integration retains ids, targets and icon sizing.
local f=assert(io.open('ui/action_binder.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('function action_binder:display_blood_pact_selector(kind)',1,true))
local b=assert(source:find('function action_binder:display_blue_magic_selector()',a,true))
local shown
local binder={title={text=function()end,show=function()end},selector={display_options=function(_,x)shown=x end},show_control_hints=function()end}
local env=setmetatable({action_binder=binder,res={job_abilities=res},windower={ffxi={get_abilities=function()return available end}},
 crossbar_abilities={},kebab_casify=function(s)return s:lower():gsub(' ','-')end,get_icon_pathbase=function()return 'icons/default'end,
 L=function()return{append=function(self,v)self[#self+1]=v end}end,
 require=function(name)if name=='ui/assets' then return{exists=function()return false end}end;return require(name)end},{__index=_G})
assert(load(source:sub(a,b-1),'actual BP chooser','t',env))()
binder:display_bp_rage_selector();assert(#shown==2 and shown[2].id==513 and shown[2].data.target_type.Enemy and shown[2].icon_offset==4)
binder:display_bp_ward_selector();assert(#shown==1 and shown[1].id==512)
print('Actual BP chooser: native availability, Rage/Ward separation, duplicate/unknown IDs, targets and custom/generic/shipped fallback icons passed.')
