-- Exercise the actual startup choice with pages that caused the regression.
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('    local default_active_environment =',1,true))
local b=assert(source:find('    if not default_active_environment then',a,true))
local calls=0
local hotbar={['all-switch']={name='Switch'},['all-trust']={name='Trust'},
 ['all-jobs-default']={name='All Jobs Default'},basic={name='Basic'}}
local env=setmetatable({player={hotbar=hotbar},env_chooser={get_default_active_environment=function()
 calls=calls+1;return 'all-switch'end}}, {__index=_G})
local choose=assert(load(source:sub(a,b-1)..'return default_active_environment','actual startup choice','t',env))
assert(choose()=='all-jobs-default' and calls==0)
hotbar['all-jobs-default']=nil;assert(choose()=='all-switch' and calls==1)
hotbar['all-jobs-default']={};assert(choose()=='all-jobs-default')
print('Actual startup selection: All Jobs Default wins over alphabetical utility/Basic pages; legacy missing-page fallback preserved.')
