-- Full slot renderer, following the existing pet guard/recast regression.
dofile('tests/pet_render.lua')
local ui=require('ui/crossbar')
local abilities=package.loaded['resources/crossbar_abilities']
abilities.Assault={id=101,recast_id=0,type='pet',category='pet-commands',mp_cost=0,tp_cost=0,custom_icon='',default_icon='/images/icons/default/fallback/abilities/assault.png'}
abilities.Retreat={id=102,recast_id=0,type='pet',category='pet-commands',mp_cost=0,tp_cost=0,custom_icon='',default_icon='/images/icons/default/fallback/abilities/retreat.png'}
local pet={name='Carbuncle',hpp=100,status=0}
windower.ffxi.get_mob_by_target=function(target)if target=='pet' then return pet end end
local player_status=1
windower.ffxi.get_player=function()return {status=player_status}end
local original={type='pet',action='Retreat',alias='Retreat',target='me'}
local bar={test={hotbar_1={slot_1=original}}}
local vitals={mp=100,tp=0}
local tracker={get_skillchain_window=function()return 0,0 end,get_skillchain_result=function()end}
local function draw()ui:check_recasts(bar,vitals,'test',{}, {active_bar=1},tracker,{},false,false)end
local caption=ui.hotbars[1].slot_text[1]
local icon=ui.hotbars[1].slot_icon[1]
draw();assert(caption:text()=='Assault' and icon:path():find('assault.png',1,true))
local cached=ui.pet_toggle_views['1:1'];draw();assert(ui.pet_toggle_views['1:1']==cached,'unchanged pet state rebuilt slot')
pet.status=1;player_status=0;draw();assert(caption:text()=='Retreat' and icon:path():find('retreat.png',1,true))
assert(original.action=='Retreat' and original.alias=='Retreat' and original.target=='me','render mutated saved action')
pet.status=0;draw();assert(caption:text()=='Assault')
original.alias='My Pet';draw();assert(caption:text()=='My Pet','custom alias lost')
pet.status=1;draw();assert(caption:text()=='My Pet')
pet=nil;draw();assert(icon:alpha()==ui.theme.disabled_slot_opacity)
bar.test.hotbar_1.slot_1={type='ex',action='input /echo replacement',alias='Replacement'}
draw();assert(not ui.pet_toggle_views['1:1'] and caption:text()=='Replacement' and icon:alpha()==255,'replacement retained toggle or dimming')
local P=require('libs/pet_actions')
local a={type='pet',action='Assault',alias='Assault',target='stnpc',icon='assist'}
local b=P.pet_toggle(a,{pet_engaged=false})
assert(b.target=='stnpc' and b.icon=='assist' and a.action=='Assault')
assert(P.pet_toggle(a,{pet_engaged=true}).target=='me')
print('Pet toggle rendering: pet/player status independence, Assault/Retreat artwork and captions, stable cache, saved-binding preservation, custom alias/icon/selector and replacement cleanup passed.')
