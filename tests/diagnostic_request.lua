local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('local function capture_request(mode,id)',1,true))
local b=assert(source:find('\ndiagnostic_capture=',a,true))
local status={running=true,diagnostic_protocol='1',input_trace='0'}
local requests={};local ok=true
local env=setmetatable({controller_status=function()return status end,
 windower={addon_path='addon/'},bank_backend={replace=function(path,body)
 assert(path=='addon/data/controller-trace.request');requests[#requests+1]=body;return ok,'write failed'end}}, {__index=_G})
local request=assert(load(source:sub(a,b-1)..'\nreturn capture_request','actual capture request','t',env))()
assert(request('on','Test-123') and requests[1]=='on\nTest-123')
status.input_trace='1';assert(not request('on','Other') and #requests==1)
assert(request('off','Test-123') and requests[2]=='off\nTest-123')
status.diagnostic_protocol=nil;assert(not request('on','Old'))
status.running=false;assert(not request('on','Stopped'))
status.running=true;status.diagnostic_protocol='1';status.input_trace='0';ok=false
assert(not request('on','Failure'))
print('Actual unified request: atomic ID-scoped payload, updated-wrapper protocol, busy/running guards and failed-write propagation passed.')
