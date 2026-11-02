local Q=require('libs/quick_bind')
local C=require('libs/controller/gamepad_converter');C:setup('playstation',true)
local saved,bound=0,0
local p={identity_confirmed=true,hotbar_load_ok=true,catalog_sources={global={}},hotbar_settings={active_environment='summoning'}}
function p:refresh_custom_catalogs()return true end
function p:save_catalog_edit(_,record)assert(record._scope=='global');saved=saved+1;record.id='id'..saved;self.catalog_sources.global[record.name]=record;return true end
local function bind(bar,slot,kind,name,target,command,icon,la,lt,alias,origin)
 bound=bound+1;assert(kind=='ex' and name==alias and command=='input /echo hello there' and icon=='custom_actions' and origin.scope=='global')
 assert(p.hotbar_settings.active_environment=='summoning');return true
end
for _,t in ipairs({'l','r','ll','rr','lr','rl'})do assert(Q.bind(t,{'cross','Hello','input /echo hello there'},p,C,6,bind))end
assert(saved==1 and bound==6,'identical shorthand duplicated global action')
assert(not Q.bind('l',{'cross','Hello','input /echo changed'},p,C,6,bind));assert(saved==1 and bound==6,'conflict changed catalog or slot')
assert(not Q.bind('rr',{'cross','New','input /echo hello there'},p,C,4,bind));assert(saved==1)
assert(not Q.bind('l',{'invalid','New','input /echo hello there'},p,C,6,bind));assert(saved==1)
assert(not Q.bind('l',{'cross','New'},p,C,6,bind));assert(saved==1)
p.hotbar_load_ok=false;assert(not Q.bind('l',{'cross','New','input /echo hello there'},p,C,6,bind))
p.hotbar_load_ok=true;p.refresh_custom_catalogs=function()return false,'unreadable'end
assert(not Q.bind('l',{'cross','New','input /echo hello there'},p,C,6,bind))
for _,combined in ipairs({false,true})do C:setup('playstation',combined);assert(C:convert_to_crossbar('lr')==(combined and 3 or 4))end
C:setup('playstation',false)
local seen
assert(Q.bind('lr',{'cross','Hello','input /echo hello there'},setmetatable({refresh_custom_catalogs=function()return true end},{__index=p}),C,3,function(bar)seen=bar end))
assert(seen==3,'three-bank LR did not share RL')
print('Quick binding: all six aliases, current-set scope, quoted command retention, one global reusable gear action, conflicts/invalid bounds/load/catalog failures and combined trigger mapping passed.')
