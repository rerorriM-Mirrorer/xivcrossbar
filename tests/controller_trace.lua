local f=assert(io.open('xivcrossbar.lua'));local text=f:read('*a');f:close()
local start=assert(text:find('local function request_controller_trace(mode)',1,true))
local stop=assert(text:find('\ncontroller_switcher =',start,true))
local running,writes,mode=true,0,nil
local write_ok=true
local env=setmetatable({controller_status=function()return {running=running}end,
    windower={addon_path='addon/',add_to_chat=function()end},
    io={open=function(path,access)
        assert(path=='addon/data/controller-trace.request' and access=='w')
        return {write=function(_,s)writes=writes+1;mode=s;return write_ok end,close=function()return true end}
    end}}, {__index=_G})
local request=assert(load(text:sub(start,stop-1)..'\nreturn request_controller_trace','actual trace command','t',env))()
assert(not request(nil) and not request('bad') and writes==0)
running=false;assert(not request('on') and writes==0)
running=true;assert(request('on') and mode=='on')
assert(request('off') and mode=='off')
write_ok=false;assert(not request('on'))
print('Actual controller trace command: explicit modes, running-wrapper guard and failed-write reporting passed.')
