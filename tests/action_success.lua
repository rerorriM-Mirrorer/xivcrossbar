local now,env,events=0,'basic',{}
local tracker=require('libs/action_success').new({
    clock=function()return now end,context=function()return env end,
    resources={spells={[1]={id=1,en='Cure'}},weapon_skills={[2]={id=2,en='Fast Blade'}},
        job_abilities={[3]={id=3,en='Provoke'}}},
    resolve=function(a)return a end,
    emit=function(bar,slot)events[#events+1]={bar,slot}end,
})
local state={player={id=100},engaged=false,pet=true,pet_id=200,pet_engaged=false,trust={trusts={kupipi='Kupipi'}}}
local function request(kind,name,extra)
    local a=extra or {};a.type,a.action=kind,name
    tracker:request(a,state,1,3,env)
end
request('ma','Cure')
tracker:action({actor_id=101,category=4,param=1});assert(#events==0)
tracker:action({actor_id=100,category=8,param=24931});assert(#events==0)
tracker:action({actor_id=100,category=8,param=28787})
tracker:action({actor_id=100,category=4,param=1});assert(#events==0,'interrupted casts cannot succeed')
request('ma','Cure');tracker:action({actor_id=100,category=4,param=1})
assert(#events==1 and events[1][2]==3)
tracker:action({actor_id=100,category=4,param=1});assert(#events==1,'duplicate completion')
request('ws','Fast Blade');tracker:action({actor_id=100,category=3,param=2,targets={}})
assert(#events==2,'executed WS does not require a hit')
request('ja','Provoke');tracker:action({actor_id=100,category=6,param=3});assert(#events==3)
request('ma','Cure');now=31;tracker:action({actor_id=100,category=4,param=1});assert(#events==3)
request('ma','Cure');env='other';tracker:action({actor_id=100,category=4,param=1});assert(#events==3)
request('a','attack');tracker:tick(state);assert(#events==3)
local after={};for k,v in pairs(state)do after[k]=v end
after.engaged=true;tracker:tick(after);assert(#events==4)
request('pet','Assault');after.pet_engaged=true;tracker:tick(after);assert(#events==5)
request('pet','Release');after.pet=false;tracker:tick(after);assert(#events==6)
request('ct','refa "Kupipi"',{trust_dismiss=true,trust_spell_name='Kupipi'})
after.trust={trusts={}};tracker:tick(after);assert(#events==7)
request('ct','echo test');assert(not tracker.pending,'custom commands cannot claim success')
print('action success: actor/identity/interrupt/expiry/context/state confirmations passed')
