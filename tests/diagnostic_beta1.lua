local clock=100
local writes,requests,created={},{},{}
local stage='data/staging'
local directory='data/diagnostics'
local output={}
local fake_feed
local recorder=require('diagnostic_session').new({
    clock=function()return clock end,date=function()return '20261025-052000' end,
    directory=directory,staging=stage,
    mkdir=function(path)created[path]=true end,
    request=function(line)requests[#requests+1]=line;return true end,
    read=function()return fake_feed end,
    write=function(path,body) assert(not output[path]);output[path]=body;writes[#writes+1]=path;return true end,
    remove=function()end,
    render_lines=function()
        return {'101.000000\t14\tnative.text\t1|text|bar|caption|rev=2|Fresh name\tVisible'},
            3,{frames=16}
    end,
    render_stop=function()end,
})
assert(not recorder.active)
local filename=assert(recorder:start('Franklet',{profile='ps5',ready=true}))
assert(filename:find('Franklet') and #requests==1 and requests[1]:find('on ',1,true)==1)
recorder:record('DIRECTLINK','seq=11 kind=down button=11')
recorder:mark('L2 felt delayed')
fake_feed='# diagnostic-feed '..recorder.id..'\nstate=stopped\ndropped=0\n101010 poll mask=000000000011\n101014 DirectLink seq=11 down button=11\n'
clock=101.5
assert(recorder:stop('manual',{ready=true}))
assert(recorder.pending and not recorder.active and #writes==0)
assert(requests[2]:find('off ',1,true)==1)
clock=102.3;recorder:tick()
assert(#writes==1 and output[filename], 'one final result')
local body=output[filename]
for _,text in ipairs({'[SESSION]','[STATE]','[DIRECTLINK]','[MARK]','[RENDER]','[AHK]',
    'DirectLink seq=11','L2 felt delayed','render overwritten: 3'}) do
    assert(body:find(text,1,true),'Missing combined event: '..text)
end
clock=103
local second=assert(recorder:start('Franklet',{profile='ps5'}))
assert(second~=filename and #writes==1,'new session must not overwrite previous log')
recorder:force('unload',{ready=false})
assert(#writes==2 and output[filename] and output[second],'unload must flush its own capture')
print('Unified diagnostic: per-request files, AHK merge, render events, boundaries, save grace, unload and overwrite prevention passed.')

-- Exercise actual render recorder and resource proxy without native getter changes.
-- CI has no LuaSocket: inject a monotonic clock as the Windower test harness does.
package.loaded.socket={gettime=function()return clock end}
local trace=require('ui/render_trace')
local calls,extents=0,0
local function object()
    return setmetatable({}, {__index=function(_,method)
        return function(...)
            calls=calls+1
            if method=='extents' then extents=extents+1;return 32,14 end
        end
    end})
end
local api={new=function()return object()end}
texts,images=api,api
local resources=require('ui/resources')
local first=resources.text({})
first:text('First')
local w,h=first:extents()
assert(w==32 and h==14 and extents==1)
first:destroy()
local without=calls
assert(trace.start())
local second_obj=resources.text({})
second_obj:text('Second')
local w2,h2=second_obj:extents()
assert(w2==32 and h2==14 and extents==2)
second_obj:destroy()
trace.stop()
assert(calls==without*2,'render tracing must preserve native call count')
local lines,dropped=trace.lines()
assert(dropped==0 and #lines>2)
local joined=table.concat(lines,'\n')
for _,event in ipairs({'create','native.text','extents','destroy'}) do
    assert(joined:find(event,1,true),'missing render event: '..event)
end
print('Render trace: resource proxy call parity, existing extents, caption and lifecycle passed.')

local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local root=read('xivcrossbar.lua')
local ahk=read('ffxi_directinput.ahk')
local controller=read('controller_diagnostics.ahk')
assert(root:find("command == 'diagnose'",1,true))
assert(root:find("diagnostic:tick(input_context())",1,true))
assert(ahk:find('DiagTick()',1,true) and ahk:find('DiagSample(states,active,phase)',1,true))
assert(controller:find('GetSystemTimeAsFileTime',1,true))
assert(not root:find('require(\"libs/banks',1,true))
print('Beta 1 diagnostics integration and isolation checks passed.')
