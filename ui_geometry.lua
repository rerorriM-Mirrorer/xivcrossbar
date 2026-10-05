-- Contributing author: A — uniform drawing scale and stable texture reuse.
-- Keep layout calculations in the original 40-pixel units. Only the final
-- drawing calls change scale, so recast crops, controller hints and labels
-- follow exactly the same transform. Other addons' Windower objects are untouched.
local geometry = {}
geometry.__index = geometry

function geometry.new()
    return setmetatable({scale = 1, x = 0, y = 0, screen_x = 0, screen_y = 0,
        surfaces = setmetatable({}, {__mode = 'k'}), primitives = {}}, geometry)
end

function geometry:point(x, y, right)
    local width = right and windower.get_windower_settings().ui_x_res or 0
    return self.screen_x + (x + width - self.x) * self.scale - width,
        self.screen_y + (y - self.y) * self.scale
end

function geometry:rect(x, y, width, height)
    local sx, sy = self:point(x, y)
    return {x = sx, y = sy, width = width * self.scale, height = height * self.scale}
end

local function draw_surface(g, object, m)
    if m.x then object:pos(g:point(m.x, m.y, m.right)) end
    if m.width then object:size(m.width * g.scale, m.height * g.scale)
    elseif m.font_size then object:size(math.max(1, math.floor(m.font_size * g.scale + .5))) end
    if m.stroke then object:stroke_width(m.stroke * g.scale) end
    if m.padding then object:pad(m.padding * g.scale) end
end

function geometry:refresh()
    for proxy, m in pairs(self.surfaces) do draw_surface(self, m.object, m) end
    for name, p in pairs(self.primitives) do
        if p.x then windower.prim.set_position(name, self:point(p.x, p.y)) end
        if p.width then windower.prim.set_size(name, p.width * self.scale, p.height * self.scale) end
    end
end

function geometry:set_scale(scale)
    self.scale = scale
    self:refresh()
end

function geometry:set_origin(x, y, screen_x, screen_y, move_contents)
    if move_contents then
        local dx, dy = x - self.x, y - self.y
        for _, m in pairs(self.surfaces) do
            if m.x then m.x, m.y = m.x + dx, m.y + dy end
        end
        for _, p in pairs(self.primitives) do
            if p.x then p.x, p.y = p.x + dx, p.y + dy end
        end
    end
    self.x, self.y, self.screen_x, self.screen_y = x, y, screen_x, screen_y
    self:refresh()
end

function geometry:surface(object, kind, options)
    local g = self
    local m = {object = object, right = options and options.flags and options.flags.right}
    local proxy = {}
    local methods = {}
    function methods:pos(x, y)
        if x == nil then return m.x, m.y end
        m.x, m.y = x, y
        object:pos(g:point(x, y, m.right))
    end
    function methods:size(width, height)
        if width == nil then return m.width or m.font_size, m.height end
        if kind == 'image' then m.width, m.height = width, height
        else m.font_size = width end
        draw_surface(g, object, m)
    end
    function methods:stroke_width(width)
        if width == nil then return m.stroke end
        m.stroke = width
        object:stroke_width(width * g.scale)
    end
    function methods:pad(padding)
        if padding == nil then return m.padding end
        m.padding = padding
        object:pad(padding * g.scale)
    end
    function methods:path(path)
        if path == nil then return m.path end
        -- Windower's path setter reassigns the texture even when unchanged.
        -- Reuse it across reveals/recast checks, without caching mutable bindings.
        if path ~= m.path then object:path(path); m.path = path end
    end
    function methods:fit(fit)
        if fit == nil then return false end
        -- Explicit sizes win over native PNG dimensions (including 76px icons).
        object:fit(false)
    end
    function methods:extents()
        local width, height = object:extents()
        return width / g.scale, height / g.scale
    end
    function methods:destroy()
        g.surfaces[proxy] = nil
        object:destroy()
    end
    setmetatable(proxy, {__index = function(_, key)
        if methods[key] then return methods[key] end
        local value = object[key]
        if type(value) ~= 'function' then return value end
        local method = function(_, ...) return value(object, ...) end
        methods[key] = method
        return method
    end})
    self.surfaces[proxy] = m
    if kind == 'image' then proxy:fit(false); proxy:size(40, 40) end
    return proxy
end

function geometry:prim()
    local g = self
    return setmetatable({
        set_position = function(name, x, y)
            local p = g.primitives[name] or {}; g.primitives[name] = p
            p.x, p.y = x, y
            windower.prim.set_position(name, g:point(x, y))
        end,
        set_size = function(name, width, height)
            local p = g.primitives[name] or {}; g.primitives[name] = p
            p.width, p.height = width, height
            windower.prim.set_size(name, width * g.scale, height * g.scale)
        end,
    }, {__index = windower.prim})
end

return geometry
