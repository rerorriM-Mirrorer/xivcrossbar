-- 2026-11-18: an Attack slot pressed with nothing targeted only targets
-- (/targetnpc); the second press attacks. Every Attack slot (<t>, <bt> or no
-- target), with or without an avatar/spirit out. No success flash for the
-- target-only press.
string.capitalize = function(value) return value end
local target, pet, status = nil, nil, 0
local sent = {}
package.loaded['resources/crossbar_spells'] = {}
package.loaded['resources/crossbar_abilities'] = {}
package.loaded.socket = {gettime=function() return 0 end}
local ffxi = {
    get_player=function() return {id=1,status=status,main_job_id=1} end,
    get_info=function() return {zone=100,logged_in=true} end,
    get_mob_by_target=function(kind) if kind=='pet' then return pet end; if kind=='t' then return target end end,
    get_party=function() return {} end,
    get_spells=function() return {} end,
}
local slot = {type='a',action='Attack',target='t'}
local p = {hotbar={basic={hotbar_1={slot_1=slot}}},hotbar_settings={active_environment='basic',active_hotbar=1}}
local absent = {contains=function() return false end}
local env = setmetatable({player=p,windower={ffxi=ffxi,send_command=function(cmd) sent[#sent+1]=cmd end},
    chat_format={say=function() end},avatar_names=absent,job_abilities=absent,kebab_casify=function(s) return s end,
    shoulders={bar=function(h,e,b) return h[e] and h[e]['hotbar_'..b] end,labels={}},
    coroutine={schedule=function() end}}, {__index=_G})
local source=assert(io.open('player.lua')):read('*a')
local a=assert(source:find('function player:execute_action(',1,true))
local b=assert(source:find('-- remove action from slot',a,true))
assert(load(source:sub(a,b-1),'actual player dispatch','t',env))()

-- No target: only target; no action returned (so no success flash request).
local accepted, action = p:execute_action(1)
assert(accepted and action==nil and sent[#sent]=='input /targetnpc' and #sent==1, 'first press targets')
-- Target now exists: the second press attacks.
target={id=9,name='Rabbit'}
accepted, action = p:execute_action(1)
assert(accepted and action==slot and sent[#sent]=='input /a "Attack" <t>', 'second press attacks: '..tostring(sent[#sent]))

-- <bt> and no-target Attack slots behave the same.
for _,t in ipairs({'bt',false}) do
    target=nil; sent={}
    slot.target = t or nil
    assert(p:execute_action(1) and sent[1]=='input /targetnpc', 'Attack <'..tostring(t)..'> targets first')
end
slot.target='t'

-- Selector targets keep the game's own subtarget cursor.
target=nil; sent={}; slot.target='st'
p:execute_action(1); assert(sent[1]=='input /a "Attack" <st>')
slot.target='t'

-- Engaged: Attack disengages as before, never retargets.
status=1; sent={}
p:execute_action(1); assert(sent[1]~='input /targetnpc')
status=0

-- With an avatar out, no target: target only (no Assault yet); then Assault + attack.
pet={id=4,name='Carbuncle',hpp=100,status=0}; target=nil; sent={}
assert(p:execute_action(1) and #sent==1 and sent[1]=='input /targetnpc')
target={id=9}; sent={}
p:execute_action(1); assert(sent[1]=='input /pet "Assault" <t>' and sent[2]=='input /attack on <t>')
pet=nil

-- /attack off slots and other action types are untouched.
local attack_target=require('libs/attack_target')
target=nil
assert(attack_target.redirect({type='a',action='off',target='t'},ffxi)==nil)
assert(attack_target.redirect({type='ma',action='Fire',target='t'},ffxi)==nil)
assert(attack_target.redirect({type='a',action='on',target='t'},ffxi)=='input /targetnpc')
print('Attack with no target: target first, second press attacks, all Attack slots: passed')
