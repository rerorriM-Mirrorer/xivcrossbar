local now, polls, attached, stopped, detached, route, generation = 0, 0, 0, 0, 0, 0, 1
local status = {running=true,state='ready',profile='ps5-extended',device=1,modifier='apps',pid=42}
local guard=require('libs/controller/native_guard').new({
    clock=function() return now end,
    status=function() return status end,
    modifier='apps', notice=error,
    open=function()
        return {
            begin=function(backend,device,mode,layout,module)
                assert(backend==2 and device==0 and mode==3 and layout==3 and module=='dinput8.dll')
                attached=attached+1
                return 1
            end,
            stop=function() stopped=stopped+1 end,
            detach=function() detached=detached+1; return true end,
            poll=function(ctx,reset,_,old)
                route=ctx
                if old~=generation then reset() end
                return generation
            end,
            poll_count=function() return polls end,
            armed=function() return polls>0 end,
        }
    end,
})
local config={ControllerProfile='ps5-extended',ControllerDevice=1}
guard:poll(config,true,5,false)
assert(attached==1 and route==4 and not guard.filtering)
polls=1
guard:poll(config,true,5,false)
assert(guard.receiving and not guard.filtering)
guard:poll(config,true,5,true)
assert(route==5 and guard.filtering)
guard:poll(config,false,5,true)
assert(route==0 and not guard.filtering and not guard.receiving)
polls=2
guard:poll(config,true,2,false)
assert(route==4 and guard.receiving)
guard:poll(config,true,2,true)
assert(route==2 and guard.filtering)
generation=2;polls=3
guard:poll(config,true,2,true)
assert(guard.reset_input)
now=.7
guard:poll(config,true,2,true)
assert(not guard.receiving and not guard.filtering)
status=nil;now=1
guard:poll(config,true,2,true)
assert(stopped==1 and detached==1 and not guard.selection)
print('Personal native guard: observation handshake, Trust context, focus, generation change, stale polls and detach passed.')
