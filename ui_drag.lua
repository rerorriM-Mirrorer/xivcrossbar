-- Contributing author: A — mouse capture and position persistence.
-- Mouse capture is limited to the visible unlock strip. Positions remain
-- Style.OffsetX/Y; this module owns only the transient drag gesture.
local drag = {}
drag.__index = drag

function drag.new(options)
    return setmetatable({options = options}, drag)
end

function drag:finish()
    if self.gesture then
        self.gesture = nil
        self.options.save()
    end
end

function drag:mouse(kind, x, y, blocked)
    if blocked or not self.options.enabled() then
        self:finish()
        return false
    end
    if self.gesture then
        if kind == 0 or kind == 2 then
            local g = self.gesture
            self.options.move(g.offset_x + x - g.x, g.offset_y + y - g.y)
            if kind == 2 then self:finish() end
            return true
        end
        return kind == 1 or kind == 3
    end
    if kind ~= 1 and kind ~= 3 then return false end
    local bounds = self.options.bounds()
    if not bounds or x < bounds.x or x > bounds.x + bounds.width or
        y < bounds.y or y > bounds.y + bounds.height then return false end
    local offset_x, offset_y = self.options.offsets()
    self.gesture = {x = x, y = y, offset_x = offset_x, offset_y = offset_y}
    return true
end

return drag
