for _,name in ipairs({'luau','pack','actions','texts'})do package.loaded[name]={}end
unpack=table.unpack
function S(t)local s={};for _,v in ipairs(t)do s[v]=true end;return setmetatable(s,{__index={contains=function(self,v)return self[v]==true end}})end
local lm={__add=function(a,b)local c={};for _,v in ipairs(a)do c[#c+1]=v end;for _,v in ipairs(b)do c[#c+1]=v end;return c end}
function L(t)return setmetatable(t,lm)end
local now=100
os.clock=function()return now end
windower={ffxi={get_info=function()return{logged_in=true}end,get_player=function()return{main_job='SMN',id=1}end,get_mob_by_target=function()return{id=99,hpp=100}end}}
res={job_abilities={[518]={name='Searing Light'},[513]={name='Poison Nails'}}}
local listener
ActionPacket={open_listener=function(f)listener=f end,new=function(a)return a end}
local function pact(id)
 local action={get_message_id=function()return 110 end,get_add_effect=function()end,get_spell=function()return nil,'job_abilities',id end}
 local target={id=99,get_actions=function()return function()return action end end}
 return {param=1,get_category_string=function()return'avatar_tp_finish'end,get_id=function()return 2 end,get_targets=function()return function()return target end end}
end
local tracker=require('libs/skillchain/skillchains')
listener(pact(518));tracker.prerender()
local delay,window=tracker.get_skillchain_window();assert(delay==0 and window==0,'Searing Light opened invalid resonance')
assert(not check_sc_props(nil,{'Light'}) and not check_burst_props(nil,{'Light'}))
assert(not check_sc_props({'Unknown'},{'Light'}) and not check_burst_props({'Unknown'},{'Light'}))
apply_properties(99,'job_abilities',513,{'Transfixion'},0,1)
listener(pact(518));tracker.prerender()
local d,w=tracker.get_skillchain_window();assert(w>0,'elemental-only attack destroyed valid opener')
assert(check_sc_props({'Liquefaction'},{'Impaction'})==2,'normal skillchain changed')
apply_properties(99,'job_abilities',513,nil,0,1);tracker.prerender()
apply_properties(99,'job_abilities',513,{'Light'},0,2)
tracker.prerender();assert(tracker.get_skillchain_result(518,'job_abilities')==true,'Searing Light lost burst hint')
apply_properties(99,'job_abilities',513,{'Light'},0,1,false,2)
tracker.prerender()
print('Actual skillchain module: Searing Light event creates no nil resonance, preserves valid chain, safe missing/unknown properties, ordinary SC/MB and Chainbound rendering passed.')
