local now,wall,raw,busy,ack_ok=0,100,nil,false,true
local acks,unloads={},0
local b=require('libs/controller/install_bridge').new({clock=function()return now end,wallclock=function()return wall end,
    read=function()return raw end,busy=function()return busy end,
    ack=function(id,state)acks[#acks+1]={id,state};return ack_ok end,
    unload=function()unloads=unloads+1 end})
local id=string.rep('a',32)
local function request(action,expires)
    return '[Installer]\nprotocol=1\nid='..id..'\naction='..(action or 'unload')..'\nexpires='..(expires or 160)..'\nEND\n'
end
for _,invalid in ipairs({request('execute'),request(nil,99),request(nil,221),request():sub(1,-3),string.rep('x',513)})do
    raw=invalid;b:poll();now=now+1.1
end
assert(unloads==0 and #acks==0)
raw=request();busy=true;b:poll();assert(acks[#acks][2]=='busy' and unloads==0)
busy=false;now=now+1.1;ack_ok=false;b:poll();assert(unloads==0)
now=now+1.1;ack_ok=true;raw=request():gsub('\n','\r\n');b:poll();assert(unloads==1 and acks[#acks][2]=='unloading')
now=now+1.1;b:poll();assert(unloads==1,'request unloaded twice')
id=string.rep('b',32);raw=request();now=now+1.1;b:poll();assert(unloads==2)
print('Local install bridge: strict unload-only requests, expiry/bounds, busy editors, ack failure, CRLF and once-only graceful dispatch passed.')
