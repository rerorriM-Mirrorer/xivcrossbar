-- Full production rendering path with controlled native API observations.
dofile('tests/compact.lua')
local ui=require('ui/crossbar')
local abilities=package.loaded['resources/crossbar_abilities']
abilities['healing-ruby']={id=512,recast_id=173,type='pet',category='blood-pacts/ward',mp_cost=0,tp_cost=0}
abilities.release={id=100,recast_id=0,type='pet',category='pet-commands',mp_cost=0,tp_cost=0,custom_icon='',default_icon='/images/release.png'}
abilities['Healing Ruby']=abilities['healing-ruby'];abilities.Release=abilities.release
local pet=nil;local recasts={}
windower.ffxi.get_mob_by_target=function(target)if target=='pet' then return pet end end
windower.ffxi.get_ability_recasts=function()return recasts end
windower.ffxi.get_spell_recasts=function()return {}end
ui.theme.hotbar_number=1;ui.theme.combined_trigger_bank=false
ui.autoattack:set_enabled(false)
ui.disabled_slots={actions={},no_vitals={},on_cooldown={},on_warmup={}}
local spells=package.loaded['resources/crossbar_spells'];spells.carbuncle={id=1,recast_id=1,category='summoning magic',mp_cost=5,tp_cost=0,custom_icon='',default_icon='/images/carbuncle.png'}
local bar={test={hotbar_1={slot_1={type='pet',action='Healing Ruby'},slot_2={type='pet',action='Release'},slot_3={type='ma',action='Carbuncle'}}}}
local vitals={mp=100,tp=0}
local tracker={get_skillchain_window=function()return 0,0 end,get_skillchain_result=function()end}
local function draw()
 ui:check_vitals(bar,vitals,'test')
 ui:check_recasts(bar,vitals,'test',{}, {active_bar=1},tracker,{},false,false)
end
local function alpha(slot)return ui.hotbars[1].slot_icon[slot]:alpha()end
draw();assert(alpha(1)==ui.theme.disabled_slot_opacity and alpha(2)==ui.theme.disabled_slot_opacity)
assert(alpha(3)==255,'no-pet dimmed summon spell')
pet={name='Carbuncle',hpp=100};draw();assert(alpha(1)==255 and alpha(2)==255)
recasts[173]=10;draw();assert(alpha(1)==ui.theme.disabled_slot_opacity,'cooldown alpha='..tostring(alpha(1))..' cd='..tostring(ui.disabled_slots.on_cooldown['1:1']))
pet=nil;draw();pet={name='Carbuncle',hpp=100};draw()
assert(alpha(1)==ui.theme.disabled_slot_opacity,'pet recovery incorrectly ended blood pact recast')
recasts[173]=nil;draw();assert(alpha(1)==255)
pet={name='Fire Spirit',hpp=100};draw()
assert(alpha(1)==ui.theme.disabled_slot_opacity and alpha(2)==255,'spirit incorrectly enabled avatar blood pact')
pet={name='Carbuncle',hpp=0};draw();assert(alpha(1)==ui.theme.disabled_slot_opacity and alpha(2)==ui.theme.disabled_slot_opacity)
pet={name='Carbuncle',hpp=100};draw();assert(alpha(1)==255)
-- No stale dimming survives replacing a pet binding with an ordinary action.
pet=nil;draw();bar.test.hotbar_1.slot_1={type='ex',action='input /echo ordinary'};draw();assert(alpha(1)==255)
print('Actual renderer: absent/dead pet dimming, summon spell usable, avatar/spirit distinction, cooldown recovery composition and slot replacement passed.')
