-- Native getters/setters are observed, never added or reordered by tracing.
local now,clock_reads=100,0
package.loaded.socket={gettime=function()clock_reads=clock_reads+1;return now end}
local trace=require('ui/render_trace')
local resources=require('ui/resources')
local measure=require('ui/text_measure')
local native_calls={}
local widths={0,24,72,72}
texts={new=function()
    local state={caption='',width_index=0,size_value=12}
    return setmetatable(state,{__index=function(_,key)
        return function(self,...)
            local args={...};native_calls[#native_calls+1]=key..':'..table.concat(args,',')
            if key=='extents' then self.width_index=self.width_index+1;return widths[self.width_index] or 72,14
            elseif key=='text' then if #args==0 then return self.caption end;self.caption=args[1]
            elseif key=='size' then if #args==0 then return self.size_value end;self.size_value=args[1]
            elseif key=='special' then return 'one',nil,'three' end
        end
    end})
end}
local function draw(enabled)
    native_calls={}
    measure.clear_cache()
    if enabled then trace.start() end
    local text=resources.text({})
    local g=require('ui/geometry').new('test-panel')
    local proxy=g:surface(text,'text')
    trace.track(proxy,nil,'test-panel','heading')
    proxy:text('Short');proxy:size(12);proxy:center(150,20);proxy:show()
    proxy:text('Longer label')
    for _=1,5 do
        now=now+.016;measure.begin_frame();trace.begin_frame(now);g:tick()
    end
    local a,b,c=text:special();assert(a=='one' and b==nil and c=='three','proxy return arity changed')
    proxy:hide();proxy:destroy();g:shutdown()
    return table.concat(native_calls,'\n')
end
trace.event('disabled');trace.context('disabled');trace.begin_frame(100)
local off=draw(false)
assert(clock_reads==0 and trace.status().count==0,'disabled diagnostics read a clock')
local on=draw(true)
assert(off==on,'trace changed native calls, getter count or positioning')
local dump=trace.dump()
assert(dump:find('test-panel|heading',1,true) and dump:find('rev=2|Longer label',1,true))
for _,event in ipairs({'native.text','extents','native.pos','center-measure','destroy'}) do assert(dump:find(event,1,true),event) end
assert(dump:find('0|1',1,true) or dump:find('0|',1,true),'zero extents not captured')
trace.context('bar1','Main');trace.context('bar1','Main');trace.context('bar2','Main')
assert(select(2,trace.dump():gsub('\tcontext\t',''))==2,'unchanged context logged repeatedly')
local old_count=trace.status().count
assert(not trace.start() and trace.status().count==old_count,'on erased running history')
local report={};local function say(s)report[#report+1]=s end
trace.command('mark','unused',say);assert(trace.dump():find('\tMARK\t',1,true))
local previous_backend=package.loaded['libs/windows_file']
local writes,files=0,{}
package.loaded['libs/windows_file']={new=function()return {replace=function(path,body)
    writes=writes+1;files[#files+1]=path
    assert(body:find('render trace v1',1,true));return true
end}end}
assert(writes==0,'capture wrote to disk')
trace.command('save','data/render-trace-Franklet.log',say)
trace.command('off','data/render-trace-Lionstag.log',say)
assert(writes==2 and files[1]~=files[2] and not trace.enabled)
local dump_fn=trace.dump;trace.dump=function()error('assembly failed')end
assert(not trace.save('existing-capture') and writes==2,'failed assembly touched a destination')
trace.dump=dump_fn
assert(not trace.save('existing-capture',function()return false,'disk full'end))
assert(not trace.save('existing-capture',function()error('backend error')end))
package.loaded['libs/windows_file']={new=function()return {replace=function()return false,'denied'end}end}
trace.command('save','denied',say);assert(report[#report]:find('denied',1,true))
package.loaded['libs/windows_file']=previous_backend
trace.start();trace.capacity=20
for i=1,50 do now=now+.01;trace.event('sequence',nil,i) end
assert(trace.status().count==20 and trace.status().dropped==31)
local recent=trace.dump();assert(not recent:find('\tsequence\t-\t30\n',1,true))
assert(recent:find('\tsequence\t-\t31\n',1,true) and recent:find('\tsequence\t-\t50\n',1,true))
trace.begin_frame(now);now=now+.2;trace.begin_frame(now)
assert(trace.status().max_gap>.19 and trace.dump():find('frame-gap',1,true))
trace.stop();local retained=trace.status().count;clock_reads=0
trace.event('disabled');trace.context('disabled');trace.begin_frame(now+1)
assert(trace.status().count==retained and clock_reads==0)
-- Weak registration must not keep the objects alive after their owner releases them.
local weak=setmetatable({},{__mode='v'})
do local o={};trace.track(o,'text');weak[1]=o end
collectgarbage();collectgarbage();assert(weak[1]==nil)
print('Render trace: native call parity on/off, stale/zero/current widths, shared IDs/revisions, context dedup, bounded chronological ring, markers, no capture-time disk I/O, per-character saves/errors and weak lifetime passed.')
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local first=assert(source:find("    elseif command == 'rendertrace' then",1,true))
local last=assert(source:find("    elseif command == 'bank' or command == 'l1' or",first,true))
local routed
local env=setmetatable({player={name='Franklet'},windower={addon_path='addon/',add_to_chat=function()end},
    render_trace={command=function(mode,path)routed={mode,path}end}},{__index=_G})
local dispatch=assert(load('return function(command,...) if false then\n'..source:sub(first,last-1)..'end end',
    'actual render command dispatch','t',env))()
dispatch('rendertrace','on');assert(routed[1]=='on' and routed[2]=='addon/data/render-trace-Franklet.log')
env.player.name=nil;dispatch('rendertrace');assert(routed[2]=='addon/data/render-trace-prelogin.log')
