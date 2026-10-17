-- Repeatable source-level cost comparison, not a Windows/FFXI frame-rate test.
package.loaded.socket={gettime=os.clock}
local calls=0
texts={new=function()
    return setmetatable({value='caption'}, {__index=function(_,key)
        return function(self,...)
            calls=calls+1
            if key=='extents' then return #self.value*6,12
            elseif key=='text' then if select('#',...)==0 then return self.value end;self.value=(...) end
        end
    end})
end}
local trace=require('ui/render_trace')
local resources=require('ui/resources')
local geometry=require('ui_geometry').new('benchmark')
local labels={}
for i=1,48 do
    local t=geometry:surface(resources.text({}),'text')
    t:text('caption');t:center(i*10,20);t:show();labels[i]=t
end
local function run(enabled)
    for _,t in ipairs(labels) do t:text('caption') end
    if enabled then trace.start() end
    calls=0;local started=os.clock()
    for frame=1,600 do
        if trace.enabled then trace.begin_frame(frame/60) end
        if frame%20==0 then
            for _,t in ipairs(labels) do t:text(frame%40==0 and 'caption' or 'longer caption') end
        end
        geometry:tick()
    end
    return os.clock()-started,calls
end
local off,native_off=run(false)
local on,native_on=run(true)
assert(native_off==native_on,'benchmark observer changed native call count')
local s=trace.status()
assert(s.count<=trace.capacity)
print(string.format('Simulated 600-frame/48-label workload: off=%.6fs on=%.6fs; native calls each=%d; retained=%d overwritten=%d. Native Windows performance remains unmeasured.',
    off,on,native_on,s.count,s.dropped))
trace.stop();geometry:shutdown();resources.destroy_all()
