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

-- No target: only target; the returned marker asks for a "target appeared" flash.
local accepted, action = p:execute_action(1)
assert(accepted and action and action.target_only and sent[#sent]=='input /targetnpc' and #sent==1, 'first press targets')
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

-- Success tracker: target-only press flashes once a target appears, with a chat line.
local clock=10
local flashes,said={},{}
local tracker=require('libs/action_success').new({clock=function() return clock end,
    context=function() return 'basic' end, resolve=function() end, resources={},
    emit=function(bar,slot) flashes[#flashes+1]={bar,slot} end,
    targeted=function(name) said[#said+1]=name end})
local pet_actions=require('libs/pet_actions')
target,pet,status=nil,nil,0
tracker:request({type='a',action='Attack',target_only=true},pet_actions.snapshot(ffxi),2,5,'basic')
assert(tracker.pending and tracker.pending.kind=='target')
tracker:tick(pet_actions.snapshot(ffxi)); assert(#flashes==0, 'no flash before a target appears')
target={id=9,name='Mandragora'}
tracker:tick(pet_actions.snapshot(ffxi))
assert(#flashes==1 and flashes[1][1]==2 and flashes[1][2]==5 and said[1]=='Mandragora' and not tracker.pending)
-- Timed out: no flash.
target=nil
tracker:request({type='a',action='Attack',target_only=true},pet_actions.snapshot(ffxi),1,1,'basic')
clock=clock+4; target={id=3,name='Bee'}; tracker:tick(pet_actions.snapshot(ffxi))
assert(#flashes==1 and #said==1, 'expired after 3 s')
-- Already targeted: nothing to wait for.
tracker:request({type='a',action='Attack',target_only=true},pet_actions.snapshot(ffxi),1,1,'basic')
assert(not tracker.pending)
-- The real trigger path passes the marker to the tracker and names the target in chat.
local main=io.open('xivcrossbar.lua'):read('*a')
assert(main:find("targeted=function(name)",1,true) and main:find("'[XIVCrossbar] Targeting '",1,true))
-- The slot shows what the next press does: Target, Attack, Disengage.
local ui_src=io.open('ui.lua'):read('*a')
local a=ui_src:find("-- A: what the next press does: Target",1,true); assert(a)
local block=ui_src:sub(a,a+900)
assert(block:find("not in_battle and require('libs/attack_target').redirect(action, windower.ffxi)",1,true)
    and block:find("targetnpc.png",1,true) and block:find("text('Target')",1,true)
    and block:find("disengage.png",1,true) and block:find("attack.png",1,true))
print('Attack with no target: target first, flash + chat on target, Target/Attack/Disengage label: passed')
