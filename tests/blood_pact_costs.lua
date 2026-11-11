local costs=require('libs/action_costs')
local abilities={
 [512]={type='BloodPactWard',mp_cost=6},
 [513]={type='BloodPactRage',mp_cost=11},
 [518]={type='BloodPactRage',mp_cost=0},
 [685]={type='Monster',mp_cost=3}}
local function mp(id)return costs.mp({id=id,res_key='job_abilities',mp_cost=0},abilities)end
assert(mp(512)==6 and mp(513)==11,'Old cached zero MP must resolve Rage and Ward costs')
assert(mp(518)==0,'Zero-cost pacts must not invent a fixed cost')
assert(mp(685)==0,'Ready charges are not MP')
assert(costs.mp({res_key='spells',id=512,mp_cost=88},abilities)==88,'Spell ID collisions must not resolve as pacts')
assert(costs.mp({mp_cost=20},{})==20)
local f=assert(io.open('ui.lua'));local source=f:read('*a');f:close()
local _,count=source:gsub('action_costs%.mp%(crossbar_action, res and res%.job_abilities%)','')
assert(count==2,'Both initial display and MP refresh must resolve pact costs')
print('Rage/Ward MP costs, old caches, zero-cost pacts, Ready charges and spell-ID isolation passed.')
