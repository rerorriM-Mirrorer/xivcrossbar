-- A: native extents can describe an earlier caption until rendering catches up.
-- Count rendered frames, not repeated getters in one frame. Only known caption/
-- font/style combinations can bypass settling. No clocks, timers or UI objects.
local M={enabled=true,frame=0,capacity=512,max_frames=8}
local cache,order,next_slot={},{},1

function M.begin_frame() M.frame=M.frame+1 end
function M.clear_cache() cache,order,next_slot={},{},1 end

function M.command(settings,mode,save,say)
    mode=type(mode)=='string' and mode:lower() or nil
    if mode and mode~='on' and mode~='off' and mode~='status' then
        say('Use //xb textsettle [on|off|status].');return false
    end
    local enabled=settings.TextSettling~=false
    if mode~='status' then enabled=mode and mode=='on' or mode==nil and not enabled end
    local changed=enabled~=(settings.TextSettling~=false)
    if changed then settings.TextSettling=enabled;save() end
    M.enabled=enabled
    say('Text settling '..(enabled and 'ON' or 'OFF')..'. New centered captions settle before reveal; known widths reuse the cache.')
    return changed
end

function M.invalidate(state)
    state.key=nil;state.phase='pending';state.changed=M.frame
    state.sample_frame=nil;state.candidate=nil;state.matches=0
end

local function remember(key,width)
    if cache[key]~=nil then return end
    local old=order[next_slot]
    if old then cache[old]=nil end
    order[next_slot]=key;cache[key]=width
    next_slot=next_slot%M.capacity+1
end

-- nil means keep transparent. Zero is a bounded, fixed-position fallback;
-- callers still position before committing opacity. A fallback is not cached.
function M.width(state,key,read,blank)
    if not M.enabled then
        state.phase='bypass';state.key=nil
        return read() or 0,'bypass'
    end
    if state.key~=key then
        M.invalidate(state);state.key=key
        local known=blank and 0 or cache[key]
        if known~=nil then state.width=known;state.phase='ready' end
    end
    if state.phase=='ready' or state.phase=='fallback' then return state.width,state.phase end
    if M.frame>state.changed and state.sample_frame~=M.frame then
        state.sample_frame=M.frame
        local width=read()
        if type(width)=='number' and width>0 and width<math.huge then
            if width==state.candidate then state.matches=state.matches+1
            else state.candidate=width;state.matches=1 end
            if state.matches>=2 then
                state.width=width;state.phase='ready';remember(key,width)
                return width,state.phase
            end
        else state.candidate=nil;state.matches=0 end
    end
    if M.frame-state.changed>=M.max_frames then
        state.width=0;state.phase='fallback';return 0,state.phase
    end
    return nil,'pending'
end

return M
