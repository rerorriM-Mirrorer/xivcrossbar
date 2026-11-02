-- Exercise the existing renderer and resource transitions, including stale MP
-- and spell-recast state, rather than only testing the policy helper.
dofile('tests/pet_toggle.lua')
local ui=require('ui/crossbar')
local spells=package.loaded['resources/crossbar_spells']
local abilities=package.loaded['resources/crossbar_abilities']
spells.Carbuncle={id=1,recast_id=1,category='summoning magic',mp_cost=5,tp_cost=0,custom_icon='',default_icon='/images/carbuncle.png'}
abilities.Release={id=100,recast_id=0,type='pet',category='pet-commands',mp_cost=0,tp_cost=0,custom_icon='',default_icon='/images/release.png'}
local pet=nil
windower.ffxi.get_mob_by_target=function(target)if target=='pet' then return pet end end
windower.ffxi.get_spell_recasts=function()return {[1]=60}end
windower.ffxi.get_ability_recasts=function()return {}end
local binding={type='ma',action='Carbuncle',alias='My Carby',target='me',icon='images/custom-carby.png'}
local bar={test={hotbar_1={slot_1=binding}}}
local vitals={mp=0,tp=0}
local tracker={get_skillchain_window=function()return 0,0 end,get_skillchain_result=function()end}
local function draw()
 ui:check_vitals(bar,vitals,'test')
 ui:check_recasts(bar,vitals,'test',{}, {active_bar=1},tracker,{},false,false)
end
local caption=ui.hotbars[1].slot_text[1]
local icon=ui.hotbars[1].slot_icon[1]
ui:load_player_hotbar(bar,vitals,'test',{active_bar=1})
draw();assert(caption:text()=='My Carby' and icon:alpha()==ui.theme.disabled_slot_opacity)
pet={name='Carbuncle',hpp=100,status=1};draw()
assert(caption:text()=='Release' and icon:path():find('release.png',1,true),'summon did not show Release artwork')
assert(icon:alpha()==255 and not ui.disabled_slots.no_vitals['1:1'] and not ui.disabled_slots.on_cooldown['1:1'],'spell MP/recast disabled Release')
ui:check_vitals(bar,vitals,'test');draw();assert(icon:alpha()==255,'vitals refresh disabled Release')
local cached=ui.pet_toggle_views['1:1'];draw();assert(ui.pet_toggle_views['1:1']==cached)
pet={name='Ifrit',hpp=100};draw()
assert(caption:text()=='My Carby' and icon:path():find('custom-carby.png',1,true),'different summon did not restore saved presentation')
assert(icon:alpha()==ui.theme.disabled_slot_opacity and ui.disabled_slots.on_cooldown['1:1'],'restored spell lost recast/MP state')
pet={name='Carbuncle',hpp=100};draw();pet=nil;draw()
assert(caption:text()=='My Carby' and icon:alpha()==ui.theme.disabled_slot_opacity)
assert(binding.type=='ma' and binding.action=='Carbuncle' and binding.alias=='My Carby' and binding.icon=='images/custom-carby.png','saved summon changed')
pet={name='Carbuncle',hpp=0};draw();assert(caption:text()=='My Carby')
pet={name='Carbuncle',hpp=100};draw()
ui:load_player_hotbar(bar,vitals,'test',{active_bar=1});draw()
assert(caption:text()=='Release' and icon:alpha()==255,'bar reload retained stale spell presentation')
bar.test.hotbar_1.slot_1={type='ex',action='input /echo custom',alias='Custom'};draw()
assert(caption:text()=='Custom' and not ui.pet_toggle_views['1:1'],'slot replacement retained Release')
print('Summon renderer: matching identity, Release artwork/caption, zero MP/spell recast independence, different/dead/missing pet restoration, custom presentation, stable cache, full bar reload and replacement passed.')
