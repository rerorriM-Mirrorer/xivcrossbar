string.capitalize = function(value) return value end
local pet, member, known, status = nil, nil, false, 0
local sent, queued = {}, {}
package.loaded['resources/crossbar_spells'] = {
    kupipi={id=900,en='Kupipi',type='Trust'},
}
package.loaded['resources/crossbar_abilities'] = {
    ['healing-ruby']={type='pet',category='blood-pacts/ward'},
}
package.loaded.socket = {gettime=function() return 0 end}
local ffxi = {
    get_player=function() return {id=1,status=status,main_job_id=15} end,
    get_info=function() return {zone=100,logged_in=true} end,
    get_mob_by_target=function() return pet end,
    get_party=function() return {p1=member} end,
    get_spells=function() return {[900]=known} end,
}
local p = {hotbar={},hotbar_settings={active_environment='basic'}}
local absent = {contains=function() return false end}
local env = setmetatable({player=p,windower={ffxi=ffxi,send_command=function(cmd) sent[#sent+1]=cmd end},
    chat_format={say=function() end},avatar_names=absent,job_abilities=absent,
    coroutine={schedule=function(fn) queued[#queued+1]=fn end}}, {__index=_G})
local file=assert(io.open('player.lua'))
local source=file:read('*a');file:close()
local a=assert(source:find('function player:cancel_summon_swap(',1,true))
local b=assert(source:find('-- remove action from slot',a,true))
assert(load(source:sub(a,b-1),'actual job dispatch','t',env))()
local trust={type='ma',action='Kupipi',target='me'}
assert(not p:dispatch_action(trust) and #sent==0)
known=true
assert(p:dispatch_action(trust) and sent[#sent]=='input /ma "Kupipi" <me>')
member={mob={name='Kupipi',spawn_type=14}}
local accepted, stay=p:dispatch_action(trust)
assert(accepted and stay and sent[#sent]=='input /refa "Kupipi"' and trust.action=='Kupipi')
assert(not p:dispatch_action({type='pet',action='Healing Ruby',target='me'}))
pet={id=4,name='Carbuncle',hpp=100,status=0}
assert(p:dispatch_action({type='pet',action='Retreat',target='me'}))
assert(sent[#sent]=='input /pet "Assault" <t>')
pet.status=1
assert(p:dispatch_action({type='pet',action='Assault',target='t'}))
assert(sent[#sent]=='input /pet "Retreat" <me>')
assert(p:dispatch_action({type='a',action='a',target='t'}))
assert(sent[#sent-1]=='input /pet "Assault" <t>' and sent[#sent]=='input /attack on <t>')
status=1
assert(p:dispatch_action({type='a',action='a',target='t'}))
assert(sent[#sent-1]=='input /pet "Retreat" <me>' and sent[#sent]=='input /attack off')
local summon={type='ma',action='Carbuncle',target='me'}
accepted, stay=p:dispatch_action(summon)
assert(accepted and stay and sent[#sent]=='input /pet "Release" <me>')
assert(p:dispatch_action({type='ma',action='Fire Spirit',target='me'}))
assert(sent[#sent]=='input /pet "Release" <me>' and #queued==1)
pet=nil;table.remove(queued,1)()
assert(sent[#sent]=='input /ma "Fire Spirit" <me>')
assert(p:dispatch_action({type='ex',action='input /echo kept'}))
assert(sent[#sent]=='input /echo kept')

local jobs=require('libs/job_crossbars')
local existing={name='My White Magic',hotbar_1={slot_1=trust}}
local hotbar={['white-magic']=existing}
local actor={main_job_id=15,main_job_level=99,sub_job_id=3,sub_job_level=49}
local resources={{type='WhiteMagic',levels={[3]=5}},{type='Trust',levels={[15]=1}}}
assert(jobs.ensure(hotbar,actor,resources,{[2]=true},6)>0)
assert(hotbar['white-magic']==existing and hotbar.trusts and hotbar['blood-pact-rage'])
assert(hotbar.trusts.hotbar_6.slot_9 and jobs.ensure(hotbar,actor,resources,{[2]=true},6)==0)
print('Typed Trust, pet dispatch, summon replacement and additive job categories passed.')
