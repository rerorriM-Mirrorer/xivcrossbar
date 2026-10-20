local now,writes,notices=100,{},{}
local trace=require('libs/controller/timing_trace').new({clock=function()return now end,
 write=function(path,body)writes[#writes+1]={path,body};return true end,
 say=function(s)notices[#notices+1]=s end})
trace:record('inactive');assert(#writes==0)
trace:start('trace.log','test');trace:tick('gameplay');now=100.2;trace:tick('menu:1')
trace:record('receiver seq=1 kind=up');assert(#writes==0,'trace did I/O on input')
now=132;trace:tick('gameplay');assert(not trace.active and #writes==1)
assert(writes[1][2]:find('update_gap_ms=200.0',1,true) and writes[1][2]:find('receiver seq=1',1,true))
trace:stop();assert(#writes==1,'stopped twice')
trace:start('trace.log','test');trace:record(string.rep('x',262145));assert(not trace.active and #writes==2)
local failed=require('libs/controller/timing_trace').new({clock=function()return now end,
 write=function()return nil,'disk error' end,say=function(s)notices[#notices+1]=s end})
failed:start('bad','test');assert(not failed:stop() and not failed.active and #notices==1)
print('Input timing: quiet buffered recording, gap timing, deadline, idempotent stop, bound and failed-save handling passed.')
