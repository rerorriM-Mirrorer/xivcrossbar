-- A: optional swing estimate, independent of drawing and real game attacks.
-- Timed pauses expire during an enabled update, so disabling needs no pending
-- coroutine cancellation. One shared action handler still serves other UI work.
local autoattack = {}
autoattack.__index = autoattack

local pausing_buffs = {
    [2]='sleep', [6]='petrify', [10]='stun',
    [17]='terror', [19]='sleep2', [28]='charm',
}

function autoattack.new(clock)
    local self = setmetatable({clock=clock or os.clock, enabled=false}, autoattack)
    self:reset()
    return self
end

function autoattack:reset()
    self.engaged, self.have_swing = false, false
    self.last_swing_time, self.estimate = nil, nil
    self.intervals, self.pause_sources = {}, {}
    self.pause_start, self.accumulated_pause = nil, 0
end

function autoattack:set_enabled(enabled)
    enabled = enabled == true
    if self.enabled == enabled then return false end
    self.enabled = enabled
    self:reset()
    return true
end

function autoattack:set_engaged(engaged, buffs)
    if not self.enabled or self.engaged == engaged then return end
    self:reset()
    self.engaged = engaged == true
    if self.engaged then
        self.last_swing_time = self.clock()
        for _,id in ipairs(buffs or {}) do self:gain_buff(id) end
    end
end

function autoattack:expire_pauses(now)
    if not self.enabled then return end
    local ended
    for src,deadline in pairs(self.pause_sources) do
        if type(deadline)=='number' and deadline<=now then
            self.pause_sources[src]=nil
            ended=math.max(ended or deadline,deadline)
        end
    end
    if ended and not next(self.pause_sources) and self.pause_start then
        self.accumulated_pause=self.accumulated_pause+math.max(0,ended-self.pause_start)
        self.pause_start=nil
    end
end

function autoattack:add_pause(src, duration)
    if not self.enabled or not self.engaged then return end
    local now=self.clock()
    self:expire_pauses(now)
    if not next(self.pause_sources) then self.pause_start=now end
    self.pause_sources[src]=duration and now+duration or true
end

function autoattack:remove_pause(src)
    if not self.enabled or not self.engaged then return end
    local now=self.clock()
    self:expire_pauses(now)
    if not self.pause_sources[src] then return end
    self.pause_sources[src]=nil
    if not next(self.pause_sources) then
        self.accumulated_pause=self.accumulated_pause+math.max(0,now-self.pause_start)
        self.pause_start=nil
    end
end

function autoattack:gain_buff(id)
    if not self.enabled then return end
    local src=pausing_buffs[id]
    if src then self:add_pause(src) end
end

function autoattack:lose_buff(id)
    if not self.enabled then return end
    local src=pausing_buffs[id]
    if src then self:remove_pause(src) end
end

function autoattack:is_paused()
    return self.enabled and next(self.pause_sources)~=nil
end

function autoattack:record_swing()
    if not self.enabled or not self.engaged then return end
    local now=self.clock()
    self:expire_pauses(now)
    local pause=self.accumulated_pause+(self.pause_start and now-self.pause_start or 0)
    -- Engagement-to-first-hit is not an attack interval. Learn from two hits.
    if self.have_swing then
        local interval=now-self.last_swing_time-pause
        if interval>0 then
            self.intervals[#self.intervals+1]=interval
            if #self.intervals>10 then table.remove(self.intervals,1) end
            local sum=0
            for _,v in ipairs(self.intervals) do sum=sum+v end
            self.estimate=sum/#self.intervals
        end
    end
    self.have_swing,self.last_swing_time=true,now
    self.accumulated_pause=0
    if self.pause_start then self.pause_start=now end
end

function autoattack:elapsed()
    if not self.enabled or not self.engaged then return nil end
    local now=self.clock()
    self:expire_pauses(now)
    local pause=self.accumulated_pause+(self.pause_start and now-self.pause_start or 0)
    return math.max(0,now-self.last_swing_time-pause)
end

return autoattack
