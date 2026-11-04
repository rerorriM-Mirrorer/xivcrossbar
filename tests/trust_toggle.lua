-- Actual player dispatch plus actual renderer with native observations mocked.
dofile('tests/pet_actions.lua')
dofile('tests/summon_toggle.lua')
local T=require('libs/trust_actions')
local spells=package.loaded['resources/crossbar_spells']
spells.Kupipi={id=900,en='Kupipi',type='ma',category='trust',mp_cost=10,tp_cost=0,recast_id=900,custom_icon='',default_icon='/images/kupipi.png'}
local party={p0={zone=1},p1={name='Kupipi',zone=1,mob={name='Kupipi',spawn_type=14}}}
local known={}
windower.ffxi.get_party=function()return party end
windower.ffxi.get_spells=function()return known end
windower.ffxi.get_mob_by_target=function()end
windower.ffxi.get_spell_recasts=function()return {[900]=60}end
local ui=require('ui/crossbar')
local binding={type='ma',action='Kupipi',alias='Kupipi',target='me'}
local bar={test={hotbar_1={slot_1=binding}}};local vitals={mp=0,tp=0}
local tracker={get_skillchain_window=function()return 0,0 end,get_skillchain_result=function()end}
local function draw()ui:check_vitals(bar,vitals,'test');ui:check_recasts(bar,vitals,'test',{}, {active_bar=1},tracker,{},false,false)end
ui:load_player_hotbar(bar,vitals,'test',{active_bar=1});draw()
assert(ui.hotbars[1].slot_text[1]:text()=='Return' and ui.hotbars[1].slot_icon[1]:alpha()==255,'present Trust inherited spell MP/recast')
local a=T.resolve(binding,T.snapshot(windower.ffxi),spells);assert(a.action=='refa "Kupipi"' and a.trust_dismiss and a.type=='ct')
assert(require('libs/pet_actions').is_release(a),'Trust dismissal would quick-return')
assert(binding.action=='Kupipi' and binding.type=='ma','saved Trust binding mutated')
party.p1=nil;draw();assert(ui.hotbars[1].slot_text[1]:text()=='Kupipi' and ui.hotbars[1].slot_icon[1]:alpha()==ui.theme.disabled_slot_opacity)
assert(T.unavailable(binding,T.snapshot(windower.ffxi),spells)=='This Trust has not been learned.')
known[900]=true;assert(not T.unavailable(binding,T.snapshot(windower.ffxi),spells))
party.p1={name='Kupipi',zone=1,mob={name='Kupipi',spawn_type=13}};assert(not T.resolve(binding,T.snapshot(windower.ffxi),spells),'player mistaken for Trust')
party.p1.mob.spawn_type=14;party.p1.zone=2;assert(not T.resolve(binding,T.snapshot(windower.ffxi),spells),'stale zone mistaken for present Trust')
local unity={type='ma',action='Yoran-Oran (UC)',alias='Yoran-Oran'}
local unity_spells={[980]={id=980,en='Yoran-Oran (UC)',type='Trust'}}
local u=T.resolve(unity,{trusts={yoranoran='Yoran-Oran'}},unity_spells)
assert(u and u.action=='refa "Yoran-Oran"' and u.icon=='trust/Yoran-Oran','Unity name/portrait mapping failed')
local source=assert(io.open('libs/player.lua')):read('*a')
local start=assert(source:find('function player:execute_action(',1,true));local finish=assert(source:find('-- remove action from slot',start,true))
local sent={};local p={hotbar={test={hotbar_1={slot_1=binding}}},hotbar_settings={active_environment='test',active_hotbar=1},temp_switch_previous_env='default'}
local env=setmetatable({player=p,windower={ffxi=windower.ffxi,send_command=function(s)sent[#sent+1]=s end,add_to_chat=function()end},avatar_names={contains=function()return false end},job_abilities={contains=function()return false end}},{__index=_G})
assert(load(source:sub(start,finish-1),'actual Trust dispatch','t',env))()
party.p1.zone=1;p:execute_action(1);assert(sent[1]=='input /refa "Kupipi"' and not p.pending_env_switch and p.temp_switch_previous_env=='default')
party.p1=nil;known[900]=false;sent={};p:execute_action(1);assert(#sent==0 and not p.pending_env_switch,'unlearned Trust dispatched/returned page')
known[900]=true;p:execute_action(1);assert(sent[1]=='input /ma "Kupipi" <me>','learned absent Trust did not summon')
print('Trust toggle: actual display/dispatch, named refa, portrait, no quick-return, MP/recast independence, unlearned block, absent restoration, player/zone discrimination and immutable binding passed.')
