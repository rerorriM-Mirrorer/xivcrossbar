-- A: capture a drag on the visible crossbar; save once on release.
local M = {}; M.__index = M
function M.new(options) return setmetatable({options=options},M) end
function M:finish()
    if self.gesture then self.gesture=nil; self.options.save() end
end
function M:mouse(kind,x,y,blocked)
    if blocked or not self.options.enabled() then self:finish(); return false end
    if self.gesture then
        if kind==0 or kind==2 then
            local g=self.gesture
            self.options.move(g.offset_x+x-g.x,g.offset_y+y-g.y)
            if kind==2 then self:finish() end
            return true
        end
        return kind==1 or kind==3
    end
    if kind~=1 and kind~=3 then return false end
    local b=self.options.bounds()
    if not b or x<b.x or x>b.x+b.width or y<b.y or y>b.y+b.height then return false end
    local ox,oy=self.options.offsets()
    self.gesture={x=x,y=y,offset_x=ox,offset_y=oy}
    return true
end
return M
