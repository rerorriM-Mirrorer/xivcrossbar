-- Input activity and release grace use elapsed wall time, not frame count.
local visibility = {}
visibility.__index = visibility

function visibility.new(clock)
    return setmetatable({clock = clock}, visibility)
end

function visibility:reset()
    self.last_active = nil
    self.was_active = false
end

function visibility:visible(mode, grace, active)
    if mode ~= 'OnInput' then return true end
    local now = self.clock()
    if active then self.last_active = now; self.was_active = true; return true end
    if self.was_active then self.last_active = now; self.was_active = false end
    return self.last_active ~= nil and now - self.last_active <= grace
end

return visibility
