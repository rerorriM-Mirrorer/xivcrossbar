local policy=require('libs/synced_actions')
package.loaded['libs/kebab_casify']=function(s) return s:lower():gsub(' ','-') end
local resources={provoke={id=5,res_key='job_abilities'},berserk={id=6,res_key='job_abilities'},
    ['fast-blade']={id=10,res_key='weapon_skills'},['savage-blade']={id=11,res_key='weapon_skills'},
    assault={id=20,res_key='pet_commands'},pact={id=21,res_key='job_abilities'}}
local buffs={269}
local available={job_abilities={5},weapon_skills={10}}
local api={get_player=function() return {buffs=buffs} end,get_abilities=function() return available end}
local function blocked(kind,name,extra)
    local a=extra or {};a.type=kind;a.action=name
    return policy.unavailable(a,policy.snapshot(api),resources)
end
assert(not blocked('ja','Provoke') and blocked('ja','Berserk'))
assert(not blocked('ws','Fast Blade') and blocked('ws','Savage Blade'))
assert(blocked('pet','Pact') and not blocked('pet','Assault'))
assert(blocked('ex','/console macro',{linked_type='ws',linked_action='Savage Blade'}))
assert(not blocked('ct','Berserk') and not blocked('ja','Unknown'))
available.job_abilities={5,6};available.weapon_skills={10,11}
assert(not blocked('ja','Berserk') and not blocked('ws','Savage Blade'))
available={job_abilities={},weapon_skills={}}
assert(blocked('ja','Provoke') and blocked('ws','Fast Blade'))
for _,b in ipairs({{}, {143}, {269}}) do
    buffs=b
    assert(blocked('ja','Berserk'))
end
available=nil;assert(not blocked('ja','Berserk'))
available={};assert(not blocked('ws','Fast Blade'))
buffs={};api.get_abilities=nil
assert(not blocked('ja','Berserk'))
-- Execute the actual final UI tint block to verify restoration and precedence.
local f=assert(io.open('ui.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('                -- Submit only the final colour.',1,true))
local b=assert(source:find('\n                if glow then',a,true))
local function object()return {calls=0,color=function(self,...) self.calls=self.calls+1;self.rgb={...} end} end
local icon,label=object(),object()
local env=setmetatable({self={hotbars={{slot_text={label},slot_icon={icon}}},slot_label_color={230,240,250}},
    h=1,i=1,shade=255,availability_unavailable=true,unavailable_reason=true,unpack=table.unpack},{__index=_G})
local draw=assert(load(source:sub(a,b-1),'tint','t',env))
draw();assert(icon.calls==1 and label.calls==1,'Only the final colour may be submitted');assert(icon.rgb[1]==130 and icon.rgb[2]==130 and label.rgb[1]==130)
env.availability_unavailable=false;draw();assert(icon.rgb[1]==130 and label.rgb[1]==230)
-- Restoration also occurs in this single final-colour block.
env.unavailable_reason=false;draw()
assert(icon.rgb[1]==255 and label.rgb[2]==240)
print('JA/WS/pact availability lists, linked actions, restriction removal, missing data and tint restoration passed.')

-- Exercise the UI sampling block: one shared snapshot, at most four per second.
local start=assert(source:find('    local availability_now =',1,true))
local finish=assert(source:find('    local pet_state',start,true))
local samples,time=0,0
package.loaded.socket={gettime=function() return time end}
local sample_env=setmetatable({self={},windower={ffxi={}},synced_actions={snapshot=function()
    samples=samples+1;return {sample=samples}
end}},{__index=_G})
local sample=assert(load(source:sub(start,finish-1),'sampling','t',sample_env))
sample();time=.1;sample();time=.24;sample();assert(samples==1)
time=.25;sample();assert(samples==2 and sample_env.self.sync_availability.sample==2)
time=0;sample();assert(samples==3,'Clock reset should not retain stale availability')
print('UI availability sampling is shared, throttled and recovers from clock resets.')

assert(not source:find('slot_icon[i]:color(shade, shade, shade)',1,true) or
    source:find('slot_icon[i]:color(shade, shade, shade)',1,true)>a,
    'Do not restore white before applying availability grey')
local before=icon.calls;env.shade=205;draw()
assert(icon.calls==before+1 and icon.rgb[1]==205,'Menu shade must remain supported')
