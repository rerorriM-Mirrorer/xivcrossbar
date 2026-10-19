local identity = require('libs/character_identity')
local servers = {[1]={en='Asura'},[2]={en='Fenrir'}}
local player = {name='Franklet',main_job='BST'}
assert(identity.resolve({logged_in=false,server=1},player,servers)==nil)
assert(identity.resolve({logged_in=true,server=2},nil,servers)==nil)
assert(identity.resolve({logged_in=true,server=99},player,servers)==nil)
assert(identity.resolve({logged_in=true,server=2},player,servers)=='Fenrir')
assert(identity.resolve({logged_in=true,server=1},player,servers)=='Asura')
local storage=require('libs/storage')
local writes=0
local target={exists=function() return true end,write=function() writes=writes+1 end}
assert(not pcall(function() storage:write_file(target,'test') end))
assert(writes==0)
assert(not pcall(function() storage:setup(player) end))
print('Pre-login/default-server identities rejected; valid servers accepted; unconfirmed writes blocked.')
