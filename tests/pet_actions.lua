-- Actual availability and dispatch policies, including quick-switch behavior.
local P=require('libs/pet_actions')
local abilities={['healing-ruby']={type='pet',category='blood-pacts/ward'},
 ['poison-nails']={type='pet',category='blood-pacts/rage'},
 ['sheep-song']={type='ja',category='ready'}}
local current_pet,current_player=nil,{status=0}
local sent,notices,switched={},{},{}
local ffxi={get_player=function()return current_player end,get_mob_by_target=function(name)
 assert(name=='pet');return current_pet end}
local function state()return P.snapshot(ffxi)end
for _,action in ipairs({{type='pet',action='Release'},{type='pet',action='Assault'},
 {type='pet',action='Retreat'},{type='pet',action='Healing Ruby'},
 {type='ja',action='Sheep Song'},{type='pet',action='Fight'}}) do
 assert(P.unavailable(action,state(),abilities))
end
for _,action in ipairs({{type='ma',action='Carbuncle'},{type='ja',action='Call Beast'},
 {type='ja',action='Activate'},{type='ja',action='Call Wyvern'},
 {type='ex',action='input /echo custom',linked_type='pet',linked_action='Healing Ruby'}}) do
 assert(not P.unavailable(action,state(),abilities),'pet gate blocked summon/custom metadata')
end
current_pet={name='Carbuncle',hpp=100}
assert(state().avatar and state().summon)
assert(not P.unavailable({type='pet',action='Healing Ruby'},state(),abilities))
current_pet={name='Fire Spirit',hpp=100}
assert(not state().avatar and state().summon)
assert(P.unavailable({type='pet',action='Healing Ruby'},state(),abilities)=='No avatar summoned.')
assert(not P.unavailable({type='pet',action='Release'},state(),abilities))
current_pet={name='Sheep',hpp=100}
assert(state().pet and not state().summon)
assert(not P.unavailable({type='ja',action='Sheep Song'},state(),abilities))
assert(P.unavailable({type='pet',action='Assault'},state(),abilities))
current_pet={name='Carbuncle',hpp=0};assert(not state().pet)
-- Real player methods are extracted with their runtime dependencies supplied.
local f=assert(io.open('libs/player.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('function player:execute_action(',1,true))
local b=assert(source:find('-- remove action from slot',a,true))
local player={hotbar={avatar={hotbar_1={}}},hotbar_settings={active_environment='avatar',active_hotbar=1}}
local env=setmetatable({player=player,windower={ffxi=ffxi,
 send_command=function(command)sent[#sent+1]=command end,
 add_to_chat=function(_,message)notices[#notices+1]=message end},
 avatar_names={contains=function()return false end},job_abilities={contains=function()return false end},
 set_active_environment=function(name)switched[#switched+1]=name end}, {__index=_G})
local old=package.loaded['resources/crossbar_abilities'];package.loaded['resources/crossbar_abilities']=abilities
assert(load(source:sub(a,b-1),'actual player pet actions','t',env))()
-- Windower string helpers used by the untouched tail.
function string.capitalize(s)return s:sub(1,1):upper()..s:sub(2):lower()end
local function action(binding)
 player.hotbar.avatar.hotbar_1.slot_1=binding;sent={};player.pending_env_switch=nil
 player:execute_action(1)
end
current_pet=nil;player.temp_switch_previous_env='basic'
action({type='pet',action='Release',target='me'})
assert(#sent==0 and #notices==1 and not player.pending_env_switch and player.temp_switch_previous_env=='basic')
action({type='pet',action='Release',target='me'});assert(#notices==1,'blocked pet press spammed chat')
current_pet={name='Carbuncle',hpp=100}
action({type='pet',action='Release',target='me'})
assert(#sent==1 and #switched==0 and not player.pending_env_switch and player.temp_switch_previous_env=='basic','Release returned to Main')
player.temp_switch_previous_env=nil
for _,status in ipairs({0,1,3}) do
 current_player.status=status
 action({type='a',action='a',target='t',alias='Attack'})
 assert(#sent==2)
 assert(sent[1]==(status==0 and 'input /pet "Assault" <t>' or 'input /pet "Retreat" <me>'))
 assert(sent[2]==(status==0 and 'input /attack on <t>' or 'input /attack off'))
end
current_player.status=0
for _,target in ipairs({'bt','12345'})do
 action({type='a',action='Attack',target=target});assert(sent[1]=='input /pet "Assault" <'..target..'>')
end
action({type='a',action='a',target='stnpc'});assert(#sent==1,'selector attack prematurely sent Assault')
for _,pet in ipairs({{name='Sheep',hpp=100},{name='Carbuncle',hpp=0},false})do
 current_pet=pet or nil;action({type='a',action='a',target='t'});assert(#sent==1,'non-summon attack changed')
end
current_pet=nil
action({type='ma',action='Carbuncle',target='me'});assert(#sent==1,'summoning was blocked')
player.temp_switch_previous_env='basic';action({type='ex',action='input /echo ordinary'})
assert(sent[1]=='input /echo ordinary' and player.pending_env_switch=='basic','ordinary quick-switch return changed')
-- Pet-command toggles use pet status, independently of player status.
for _,binding_name in ipairs({'Assault','Retreat'}) do
 local binding={type='pet',action=binding_name,alias=binding_name,target=binding_name=='Retreat' and 'me' or 'bt'}
 current_player.status=1;current_pet={name='Carbuncle',hpp=100,status=0}
 action(binding)
 local target=binding_name=='Retreat' and 't' or 'bt'
 assert(#sent==1 and sent[1]=='input /pet "Assault" <'..target..'>','idle pet did not Assault')
 assert(binding.action==binding_name and binding.alias==binding_name,'toggle rewrote saved binding')
 current_player.status=0;current_pet.status=1;action(binding)
 assert(#sent==1 and sent[1]=='input /pet "Retreat" <me>','engaged pet did not Retreat')
 current_pet=nil;action(binding);assert(#sent==0,'missing summon emitted pet toggle')
end
assert(P.pet_toggle({type='ex',action='assault; input /attack <t>'},state())==nil)
assert(P.pet_toggle({type='pet',action='Fight'},state())==nil)
assert(P.pet_toggle({type='pet',action='Heel'},state())==nil)
-- A matching summon slot releases without the normal temporary-page return.
for _,name in ipairs({'Carbuncle','Cait Sith','Fire Spirit'}) do
 local binding={type='ma',action=name,alias=name,target='me',icon='custom-summon.png'}
 current_pet={name=name,hpp=100,status=0};player.temp_switch_previous_env='basic'
 action(binding)
 assert(#sent==1 and sent[1]=='input /pet "Release" <me>','matching summon did not Release')
 assert(not player.pending_env_switch and player.temp_switch_previous_env=='basic','summon Release returned page')
 assert(binding.type=='ma' and binding.action==name and binding.icon=='custom-summon.png','summon binding mutated')
 current_pet=nil;player.temp_switch_previous_env=nil;action(binding)
 assert(#sent==1 and sent[1]=='input /ma "'..name..'" <me>','summon did not restore after dismissal')
 current_pet={name='Ifrit',hpp=100};action(binding)
 assert(sent[1]=='input /ma "'..name..'" <me>','different summon became Release')
 current_pet={name=name,hpp=0};action(binding)
 assert(sent[1]=='input /ma "'..name..'" <me>','dead summon became Release')
end
current_pet={name='Carbuncle',hpp=100}
assert(not P.summon_toggle({type='ex',action='input /ma "Carbuncle" <me>'},state()))
assert(not P.summon_toggle({type='ma',action='Kupipi'},state()))
player.temp_switch_previous_env='basic';action({type='ma',action='Cure',target='me'})
assert(player.pending_env_switch=='basic','ordinary magic quick-return changed')
print('Summon toggle dispatch: matching avatar/spirit, missing/dead/different pet, saved bindings, custom macros, Trust exceptions and Release page retention passed.')
package.loaded['resources/crossbar_abilities']=old
print('Pet guard and actual player dispatch: absent/dead/avatar/spirit/BST, summons/custom exceptions, throttled notice, Release page retention, attack/retreat pairs, selectors and ordinary quick-return passed.')
