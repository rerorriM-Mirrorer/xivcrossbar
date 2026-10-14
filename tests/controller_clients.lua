local M=require('controller_clients')
local files,writes={},0
local now=100
local held=0
local backend={session_id='session-123',token='1:2',hold_owner=function()held=held+1;return{close=function()held=held-1 end}end,replace=function(p,data)files[p]=data;writes=writes+1;return true end}
local client=M.new{directory='clients/',backend=backend,clock=function()return now end,create_dir=function()end}
assert(client:register(true) and held==1)
assert(files['clients/session-123.ini']:find('state=loaded',1,true))
assert(client:register(true) and writes==1,'unchanged settings rewrote registration')
assert(client:register(false) and writes==2)
now=102;assert(client:close(false))
assert(files['clients/session-123.ini']:find('state=closing',1,true) and files['clients/session-123.ini']:find('kill=false',1,true))
assert(client:close(false) and held==0 and writes==3,'unload dispatched twice')
assert(client:register(true) and writes==4,'reload did not re-register')
backend.replace=function()return false,'failure'end
local ok=client:close(true);assert(not ok and client.loaded and held==1,'failed close falsely unregistered client')
print('Pre-login process registration, unchanged-setting suppression, unload once, reload and failed-close preservation passed.')
