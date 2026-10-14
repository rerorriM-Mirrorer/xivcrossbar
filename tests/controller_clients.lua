local M=require('controller_clients')
local files,writes={},0
local now=100
local backend={pid=123,token='1:2',replace=function(p,data)files[p]=data;writes=writes+1;return true end}
local client=M.new{directory='clients/',backend=backend,clock=function()return now end,create_dir=function()end}
assert(client:register(true))
assert(files['clients/123.ini']:find('state=loaded',1,true))
assert(client:register(true) and writes==1,'unchanged settings rewrote registration')
assert(client:register(false) and writes==2)
now=102;assert(client:close(false))
assert(files['clients/123.ini']:find('state=closing',1,true) and files['clients/123.ini']:find('kill=false',1,true))
assert(client:close(false) and writes==3,'unload dispatched twice')
assert(client:register(true) and writes==4,'reload did not re-register')
backend.replace=function()return false,'failure'end
local ok=client:close(true);assert(not ok and client.loaded,'failed close falsely unregistered client')
print('Pre-login process registration, unchanged-setting suppression, unload once, reload and failed-close preservation passed.')
