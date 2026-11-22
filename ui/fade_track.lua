-- A (2026-11-21): eased values for the crossbar's appearance pass.
-- Each key holds one number. Asking for a new target starts an ease-out from
-- wherever the value is now, so a change partway through reverses smoothly
-- and a one-frame flip of the target never shows as a blink. Clock-driven
-- (socket.gettime), never frame-counted, so it looks the same at any FPS.
-- A key seen for the first time, or asked with no duration, snaps.
local M = {}

local function ease_out(k)
    k = 1 - k
    return 1 - k*k*k
end

function M.new(clock)
    local self = {items={}}

    local function current(item, now)
        if item.dur <= 0 then return item.to end
        local k = (now - item.started) / item.dur
        if k <= 0 then return item.from end
        if k >= 1 then return item.to end
        return item.from + (item.to - item.from) * ease_out(k)
    end

    -- value(key, target, seconds[, delay]) -> current value
    function self:value(key, target, duration, delay)
        local now = clock()
        local item = self.items[key]
        if not item or not duration or duration <= 0 then
            self.items[key] = {from=target, to=target, started=now, dur=0}
            return target
        end
        if item.to ~= target then
            item.from = current(item, now)
            item.to, item.started, item.dur = target, now + (delay or 0), duration
        end
        return current(item, now)
    end

    function self:set(key, value)
        self.items[key] = {from=value, to=value, started=clock(), dur=0}
    end

    function self:forget(key) self.items[key] = nil end
    function self:clear() self.items = {} end

    -- True while any value is still moving (callers keep redrawing).
    function self:busy()
        local now = clock()
        for _, item in pairs(self.items) do
            if item.dur > 0 and now < item.started + item.dur then return true end
        end
        return false
    end

    return self
end

return M
