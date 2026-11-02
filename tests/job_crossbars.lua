local J=require('libs/job_crossbars')
local spells={[1]={type='WhiteMagic',levels={[3]=1,[5]=3}},[2]={type='BlackMagic',levels={[4]=1,[5]=1}},[3]={type='SummonerPact',levels={[15]=1}},[4]={type='Trust',levels={[3]=1,[15]=1}}}
local slots={hotbar_1={slot_1={action='Existing'}}}
local bars={['all-jobs-default']=slots,['summoning']={name='My Summons',hotbar_1={slot_1={action='Custom'}}}}
J.ensure(bars,{main_job_id=15,main_job_level=20,sub_job_id=3,sub_job_level=10},spells,{[4]=true},6)
assert(bars['white-magic'] and bars['blood-pact-rage'] and bars['blood-pact-ward'] and bars['pet-commands'] and bars.trusts)
assert(not bars['black-magic'] and bars.summoning.name=='My Summons' and bars.summoning.hotbar_1.slot_1.action=='Custom')
assert(bars['all-jobs-default']==slots and slots.hotbar_1.slot_1.action=='Existing','existing layout changed')
bars['white-magic'].hotbar_1.slot_1={type='ex',action='Anything'}
J.ensure(bars,{main_job_id=15,main_job_level=20,sub_job_id=3,sub_job_level=10},spells,{[4]=true},6)
assert(bars['white-magic'].hotbar_1.slot_1.action=='Anything' and bars['white-magic'].hotbar_6.slot_9,'editable arbitrary actions/phantom bars lost')
local whm={};J.ensure(whm,{main_job_id=3,main_job_level=1},spells,{},6)
assert(whm['white-magic'] and not whm.summoning and not whm.trusts)
local bst={};J.ensure(bst,{main_job_id=9,main_job_level=30},spells,{},6);assert(bst.ready and bst['pet-commands'] and not bst.summoning)
local paths={};local function exists(p)local f=io.open(p,'rb');if f then f:close();return true end end
assert(J.icon('white-magic','icons/default',exists)=='images/icons/default/jobs/WHM.png')
assert(J.icon('blood-pact-rage','icons/default',exists)=='images/icons/default/fallback/abilities/00173.png')
assert(not J.icon('my-custom-set','icons/default',exists))
print('Job crossbars: main/sub capability sets, learned Trusts, arbitrary bindings, repeated loads, existing labels/slots/global inventory, BST/SMN/WHM and existing artwork passed.')
-- Exercise the production load hook and its failure rollback, not just ensure().
local f=assert(io.open('libs/player.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('function player:load_hotbar()',1,true));local b=assert(source:find('-- Main/subjob can arrive',a,true))
local yes={exists=function()return true end};local no={exists=function()return false end}
local storage={identity_valid=true,file=yes,job_default_file=yes,all_jobs_file=yes,shared_file=yes,shared_icons_file=no}
local p={identity_confirmed=true,auto_create_xml=false,hotbar={},hotbar_settings={max=6},main_job='WHM',sub_job='SMN',
 update_current_spells=function()end,reset_hotbar=function(self)self.hotbar={default={name='Default'}}end,
 refresh_custom_catalogs=function()return true end,load_from_file=function()return true end,sync_catalog_bindings=function()end}
local env=setmetatable({player=p,storage=storage,res={spells=spells},windower={ffxi={get_player=function()return {main_job_id=3,main_job_level=30,sub_job_id=15,sub_job_level=15}end,get_spells=function()return{}end},add_to_chat=function()end}},{__index=_G})
assert(load(source:sub(a,b-1),'actual job capability load','t',env))()
assert(p:load_hotbar() and p.hotbar_load_ok and p.hotbar['white-magic'] and p.hotbar.summoning)
local previous=p.hotbar;p.load_from_file=function()return false end;storage.hotbar_read_error='malformed test XML'
assert(not p:load_hotbar() and p.hotbar==previous and not p.hotbar_load_ok,'capability hook bypassed XML rollback')
print('Actual hotbar load: capability pages added after layer reads, parse failure preserves complete previous view and blocks saving passed.')
-- Production destination selector supplies category artwork to the saved switch.
local f=assert(io.open('ui/action_binder.lua'));local src=f:read('*a');f:close()
local a=assert(src:find('function action_binder:display_crossbar_sets_selector()',1,true));local b=assert(src:find('-- Explicit artwork wins',a,true))
local shown
local binder={title={text=function()end,show=function()end},action_type=1,button_layout='playstation',selector={display_options=function(_,v)shown=v end},show_control_hints=function()end,get_crossbar_sets_binding=function()return{{key='white-magic',name='White Magic'}}end}
local env=setmetatable({action_binder=binder,action_types={QUICK_SWITCH_CROSSBARS=1},get_icon_pathbase=function()return'icons/default'end,L=function()return{append=function(self,v)self[#self+1]=v end}end,require=function(n)if n=='ui/assets'then return{exists=exists}end;return require(n)end},{__index=_G})
assert(load(src:sub(a,b-1),'actual category destination selector','t',env))()
binder:display_crossbar_sets_selector()
assert(shown[1].icon=='images/icons/default/jobs/WHM.png' and shown[1].data.icon_path==shown[1].icon and shown[1].data.action_name=='white-magic')
print('Actual destination selector: category portrait persists on freely bindable switch actions passed.')
