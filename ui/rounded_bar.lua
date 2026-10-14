-- A: thin rounded bars, following Skillchains' inset endcap approach.
-- Three persistent primitives share color/visibility. Child caps are kept out
-- of geometry's logical registry so scaling/dragging never moves them twice.
local bar = {}
bar.__index = bar

function bar.new(name, api)
    local self = setmetatable({api=api, visible=false, parts={}}, bar)
    for _, suffix in ipairs({'', '_left_cap', '_right_cap'}) do
        local part = {name=name .. suffix}
        api.create(part.name)
        api.set_visibility(part.name, false)
        self.parts[#self.parts+1] = part
    end
    return self
end

local function visible(self, part)
    local show = self.visible and (part.width or 0)>0 and (part.height or 0)>0
    if part.visible ~= show then
        self.api.set_visibility(part.name, show)
        part.visible = show
    end
end

local function bounds(self, part, x, y, width, height)
    width, height = math.max(0,width), math.max(0,height)
    if part.x ~= x or part.y ~= y then
        self.api.set_position(part.name, x, y)
        part.x, part.y = x, y
    end
    if part.width ~= width or part.height ~= height then
        self.api.set_size(part.name, width, height)
        part.width, part.height = width, height
    end
    visible(self, part)
end

function bar:layout(x, y, width, height, corner, left, right)
    width, height = math.max(0,width), math.max(0,height)
    local inset = math.min(corner or 1, width/2, height/2)
    local l, r = left ~= false and inset or 0, right ~= false and inset or 0
    bounds(self,self.parts[1], x+l,y, width-l-r,height)
    bounds(self,self.parts[2], x,y+inset, l,height-2*inset)
    bounds(self,self.parts[3], x+width-r,y+inset, r,height-2*inset)
end

function bar:color(alpha, red, green, blue)
    local value = {alpha,red,green,blue}
    for _, part in ipairs(self.parts) do
        local old = part.color
        if not old or old[1]~=alpha or old[2]~=red or old[3]~=green or old[4]~=blue then
            self.api.set_color(part.name,alpha,red,green,blue)
            part.color = value
        end
    end
end

function bar:show(show)
    self.visible = show
    for _, part in ipairs(self.parts) do visible(self,part) end
end

function bar:destroy()
    for _, part in ipairs(self.parts) do self.api.delete(part.name) end
end

return bar
