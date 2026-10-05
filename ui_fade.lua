-- Contributing author: Awake — elapsed-time fades that reverse without jumping.
local fade = {}
fade.__index = fade

function fade.new(clock, initial)
    return setmetatable({clock=clock, value=initial or 1, target=initial or 1,
        active=false}, fade)
end

function fade:step()
    if not self.active then return self.value end
    local t = math.max(0, math.min(1, (self.clock()-self.started)/self.duration))
    -- Smooth start/end, with no frame-count dependence or waiting in an event.
    local eased = t*t*(3-2*t)
    self.value = self.from + (self.target-self.from)*eased
    if t == 1 then self.value, self.active = self.target, false end
    return self.value
end

function fade:to(target, duration)
    self:step()
    target = math.max(0, math.min(1, target))
    if self.target == target and self.active then return end
    self.from, self.target = self.value, target
    self.started, self.duration = self.clock(), math.max(0, duration or 0)
    self.active = self.duration > 0 and self.from ~= target
    if not self.active then self.value = target end
end

return fade
