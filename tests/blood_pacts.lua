local P=require('libs/blood_pacts')
local res={
 [512]={id=512,en='Healing Ruby',type='BloodPactWard',targets={Self=true}},
 [513]={id=513,en='Poison Nails',type='BloodPactRage',targets={Enemy=true}},
 [518]={id=518,en='Searing Light',type='BloodPactRage'},
 [529]={id=529,en='Crescent Fang',type='BloodPactRage'},
 [1151]={id=1151,en='Flame Breath',type='Monster'}}
local player={main_job_id=15,main_job_level=10}
local spells={[1]={en='Carbuncle',type='SummonerPact',levels={[15]=1}},[2]={en='Fenrir',type='SummonerPact',levels={[15]=1}}}
local known={[1]=true}
local function available(kind)return P.available(res,player,spells,known,kind)end
local rage=available('BloodPactRage')
assert(#rage==2 and rage[1].id==518 and rage[2].id==513,'level/unlock/category/sort')
assert(#available('BloodPactWard')==1)
player.main_job_level=4;assert(#available('BloodPactRage')==1,'above-level pact exposed')
player.main_job_level=10;known[2]=true;assert(#available('BloodPactRage')==3,'learned avatar missing')
player={main_job_id=3,main_job_level=99,sub_job_id=15,sub_job_level=4}
assert(#available('BloodPactRage')==1,'subjob level ignored')
player.sub_job_level=10;assert(#available('BloodPactRage')==3)
player.sub_job_id=1;assert(#available('BloodPactRage')==0,'non-SMN saw pacts')
player={main_job_id=15,main_job_level=10};known[2]=false
assert(#P.available(res,player,spells,{},'BloodPactRage')==0,'unlearned summon exposed pacts')
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
local f=assert(io.open('action_binder.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('function action_binder:display_blood_pact_selector(kind)',1,true))
local b=assert(source:find('function action_binder:display_blue_magic_selector()',a,true))
local shown
local binder={title={text=function()end,show=function()end},selector={display_options=function(_,x)shown=x end},show_control_hints=function()end}
local env=setmetatable({action_binder=binder,res={job_abilities=res,spells=spells},windower={ffxi={get_player=function()return player end,get_spells=function()return known end}},
 file={new=function()return {exists=function()return false end}end},crossbar_abilities={},kebab_casify=function(s)return s:lower():gsub(' ','-')end,get_icon_pathbase=function()return 'icons/default'end,
 L=function()return{append=function(self,v)self[#self+1]=v end}end,
 require=function(name)if name=='ui/assets' then return{exists=function()return false end}end;return require(name)end},{__index=_G})
assert(load(source:sub(a,b-1),'actual BP chooser','t',env))()
binder:display_bp_rage_selector();assert(#shown==2 and shown[2].id==513 and shown[2].data.target_type.Enemy and shown[2].icon_offset==4)
binder:display_bp_ward_selector();assert(#shown==1 and shown[1].id==512)
print('Actual BP chooser: level/learned-summon eligibility without native pet availability, main/subjob, Rage/Ward separation, targets and custom/generic/shipped fallback icons passed.')

local sorter=require('libs/binder_sort').summons
local summons={{id=1,name='Fire Spirit'},{id=7,name='Carbuncle'},{id=3,name='Ifrit'},{id=2,name='Ice Spirit'}}
table.sort(summons,sorter)
assert(summons[1].name=='Ifrit' and summons[2].name=='Carbuncle' and summons[3].name=='Fire Spirit')
assert(source:find("or magic_type == 'BlackMagic' then",1,true),'Black Magic must join numeric ID sorting')
assert(source:find("spell_list:sort(require('libs/binder_sort').summons)",1,true))
print('Avatars precede spirits, each group keeps numeric ID order; Black Magic uses ID order.')
-- Exercise the actual magic chooser rather than only checking its source.
local begin=assert(source:find('function action_binder:display_magic_selector_internal(magic_type)',1,true))
local finish=assert(source:find('function action_binder:display_white_magic_selector()',begin,true))
local spell_rows={
 [1]={name='Fire Spirit',targets={},type='SummonerPact'},
 [2]={name='Ice Spirit',targets={},type='SummonerPact'},
 [3]={name='Ifrit',targets={},type='SummonerPact'},
 [7]={name='Carbuncle',targets={},type='SummonerPact'},
 [11]={name='Z first',targets={},type='BlackMagic'},
 [12]={name='A second',targets={},type='BlackMagic'}}
local metadata={}
for _,row in pairs(spell_rows) do metadata[row.name]={category=row.type=='BlackMagic' and 'black magic' or 'summoning magic'} end
local magic_env=setmetatable({action_binder=binder,res={spells=spell_rows},
 windower={ffxi={get_player=function()return {main_job='BLM',main_job_id=4,main_job_level=99,sub_job_id=15,sub_job_level=49}end}},
 get_spells_for_job=function(_,_,kind)local result={}for id,row in pairs(spell_rows)do if row.type==kind then result[id]=true end end;return result end,
 T=function(t)return t end,L=function()return {append=function(self,v)self[#self+1]=v end,sort=function(self,fn)table.sort(self,fn)end}end,
 crossbar_spells=metadata,kebab_casify=function(x)return x end,
 fix_target_types=function(_,_,targets)return targets end,maybe_get_custom_icon=function()return 'icon',false end,
 SPELL_TYPE_LOOKUP={BlackMagic='black magic',SummonerPact='summoning magic'}},{__index=_G})
assert(load(source:sub(begin,finish-1),'actual magic chooser','t',magic_env))()
binder:display_magic_selector_internal('BlackMagic')
assert(#shown==2 and shown[1].id==11 and shown[2].id==12,'Actual Black Magic chooser must sort IDs, not names')
binder:display_magic_selector_internal('SummonerPact')
assert(#shown==4 and shown[1].id==3 and shown[2].id==7 and shown[3].id==1 and shown[4].id==2)
print('Actual Black Magic and summoning choosers sort correctly with missing JP data.')
