local N=require('libs/set_names')
assert(N.resolve({['all-switch']={name='Switch'}},'switch')=='all-switch')
assert(N.resolve({trusts={name='Trusts'}},'Trust')=='trusts')
assert(N.resolve({a={name='Same'},b={name='Same'}},'Same')==nil,'ambiguous label picked a set')
assert(N.resolve({same={name='Exact'},other={name='same'}},'same')=='same','explicit key lost priority')
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('function delete_environment_command(args)',1,true));local b=assert(source:find('-- command to rerun the setup dialog',a,true))
local J=require('libs/job_crossbars')
local settings={};local persisted
local p={identity_confirmed=true,hotbar_load_ok=true,name='Cioara',server='Fenrir',main_job='WHM',sub_job='SMN',hotbar_settings={active_environment='trusts'}}
local spells={[1]={type='Trust',levels={[3]=1}}}
local current={main_job_id=3,main_job_level=30}
local function copy(t)local out={};for k,v in pairs(t)do out[k]=type(v)=='table' and copy(v)or v end;return out end
local messages,saves,reloads={},0,0
function p:save_hotbar()saves=saves+1 end
local env=setmetatable({player=p,settings=settings,PROTECTED_ENV_KEYS={default=true,['all-jobs-default']=true,shared=true,['job-default']=true},
 windower={add_to_chat=function(_,m)messages[#messages+1]=m end},config={save=function(t)persisted=copy(t)end},
 set_active_environment=function(key)p.hotbar_settings.active_environment=key end,
 env_chooser={get_default_active_environment=function()return'default'end},count_switch_references=function()return 1 end,
 reload_hotbar=function()reloads=reloads+1;J.ensure(p.hotbar,current,spells,{[1]=true},6,J.hidden(settings,p))end}, {__index=_G})
assert(load(source:sub(a,b-1),'actual delete/restore handlers','t',env))()
p.hotbar={default={name='Default'},trusts={name='Trusts'},['all-switch']={name='Switch'}}
env.delete_environment_command({'trust'})
assert(not p.hotbar.trusts and J.hidden(settings,p).trusts and persisted and J.hidden(persisted,p).trusts,'generated Trusts returned or suppression not persisted')
assert(p.hotbar_settings.active_environment=='default' and messages[#messages]:find('quick%-switch'))
env.restore_environment_command({'Trusts'})
assert(p.hotbar.trusts and not J.hidden(settings,p).trusts,'restore did not re-enable category')
env.delete_environment_command({'Switch'});assert(not p.hotbar['all-switch'],'display name failed to delete custom saved key')
local before=saves;env.delete_environment_command({'default'});assert(p.hotbar.default and saves==before,'protected set deleted')
p.hotbar.a={name='Duplicate'};p.hotbar.b={name='Duplicate'};env.delete_environment_command({'Duplicate'});assert(p.hotbar.a and p.hotbar.b and saves==before)
p.hotbar_load_ok=false;env.delete_environment_command({'Trusts'});assert(p.hotbar.trusts and saves==before)
p.hotbar_load_ok=true;p.save_hotbar=function()error('test write failure')end
local previous=p.hotbar.trusts;env.delete_environment_command({'Trusts'})
assert(p.hotbar.trusts==previous and not J.hidden(settings,p).trusts,'failed save discarded set/suppression')
print('Actual delete/restore: keys/display names/Trust alias, ambiguity/protection/login guards, persisted scoped suppression, fallback, orphan notice, custom Switch deletion and failed-save rollback passed.')
