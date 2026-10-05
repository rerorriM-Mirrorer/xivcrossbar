-- Contributing author: Awake — geometry, texture reuse and whole-panel opacity.
-- Keep layout calculations in the original 40-pixel units. Only the final
-- drawing calls change scale, so recast crops, controller hints and labels
-- follow exactly the same transform. Other addons' Windower objects are untouched.
local geometry = {}
geometry.__index = geometry

function geometry.new()
    return setmetatable({scale = 1, x = 0, y = 0, screen_x = 0, screen_y = 0,
        opacity=1, retired={}, surfaces = setmetatable({}, {__mode = 'k'}), primitives = {}}, geometry)
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
    if m.x and not m.center_x then object:pos(g:point(m.x, m.y, m.right)) end
    if m.width then object:size(m.width * g.scale, m.height * g.scale)
    elseif m.font_size then object:size(math.max(1, math.floor(m.font_size * g.scale + .5))) end
    if m.stroke then object:stroke_width(m.stroke * g.scale) end
    if m.padding then object:pad(m.padding * g.scale) end
    if m.center_x then
        local width = object:extents()
        m.x, m.y = m.center_x - width / g.scale / 2, m.center_y
        object:pos(g:point(m.x, m.y))
    end
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

local function rounded_alpha(alpha, opacity)
    return math.floor((alpha or 255)*opacity + .5)
end

local function draw_opacity(g, m)
    m.object:alpha(rounded_alpha(m.alpha, g.opacity))
    if m.bg_alpha then m.object:bg_alpha(rounded_alpha(m.bg_alpha, g.opacity)) end
    if m.stroke_alpha then m.object:stroke_transparency(rounded_alpha(m.stroke_alpha, g.opacity)) end
    if g.opacity == 0 and m.defer_visible then
        m.object:hide(); m.defer_visible = nil
    end
end

function geometry:set_opacity(opacity)
    self.opacity = math.max(0, math.min(1, opacity))
    if self.fade and not self.fade.active then
        self.fade.value, self.fade.target = self.opacity, self.opacity
    end
    for _, m in pairs(self.surfaces) do draw_opacity(self, m) end
    for _, m in ipairs(self.retired) do draw_opacity(self, m) end
    for name, p in pairs(self.primitives) do
        if p.color then
            windower.prim.set_color(name, rounded_alpha(p.color[1], self.opacity),
                p.color[2], p.color[3], p.color[4])
        end
        if self.opacity == 0 and p.defer_visible then
            windower.prim.set_visibility(name, false); p.defer_visible = nil
        end
    end
    if self.opacity == 0 then
        for _, m in ipairs(self.retired) do m.object:destroy() end
        self.retired, self.deferring_hide = {}, false
    end
end

function geometry:configure_fade(enabled, fade_in, fade_out)
    self.fade_enabled = enabled == true
    self.fade_in, self.fade_out = fade_in or .12, fade_out or .18
    self.fade = require('ui_fade').new(require('socket').gettime, self.opacity)
end

function geometry:transition(show)
    if not self.fade_enabled then return end
    self.fade:to(show and 1 or 0, show and self.fade_in or self.fade_out)
    self.deferring_hide = not show and self.fade.active
    if show then
        -- A reversed close must not resurrect rows destroyed by a menu reset.
        for _, m in ipairs(self.retired) do m.object:destroy() end
        self.retired = {}
        for _, m in pairs(self.surfaces) do
            if m.defer_visible then m.object:hide(); m.defer_visible = nil end
        end
        for name, p in pairs(self.primitives) do
            if p.defer_visible then windower.prim.set_visibility(name, false); p.defer_visible = nil end
        end
    end
    self:set_opacity(self.fade.value)
end

function geometry:tick()
    if self.fade and self.fade.active then self:set_opacity(self.fade:step()) end
end

function geometry:set_origin(x, y, screen_x, screen_y, move_contents)
    if move_contents then
        local dx, dy = x - self.x, y - self.y
        for _, m in pairs(self.surfaces) do
            if m.x then m.x, m.y = m.x + dx, m.y + dy end
            if m.center_x then m.center_x, m.center_y = m.center_x + dx, m.center_y + dy end
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
    local m = {object = object, visible=false, alpha=255,
        right = options and options.flags and options.flags.right}
    local proxy = {}
    local methods = {}
    function methods:alpha(value)
        if value == nil then return m.alpha end
        m.alpha = value; object:alpha(rounded_alpha(value, g.opacity))
    end
    function methods:bg_alpha(value)
        if value == nil then return m.bg_alpha end
        m.bg_alpha = value; object:bg_alpha(rounded_alpha(value, g.opacity))
    end
    function methods:stroke_transparency(value)
        if value == nil then return m.stroke_alpha end
        m.stroke_alpha = value; object:stroke_transparency(rounded_alpha(value, g.opacity))
    end
    function methods:show()
        m.visible, m.defer_visible = true, nil
        object:show()
    end
    function methods:hide()
        local was_visible = m.visible or m.defer_visible
        m.visible = false
        if g.deferring_hide and was_visible then m.defer_visible = true
        else m.defer_visible = nil; object:hide() end
    end
    function methods:visible(value)
        if value == nil then return m.visible end
        if value then self:show() else self:hide() end
    end
    function methods:pos(x, y)
        if x == nil then return m.x, m.y end
        m.x, m.y = x, y
        object:pos(g:point(x, y, m.right))
    end
    -- Store the tile center, not a fixed left edge. Recalculate after font or
    -- caption changes so short and long aliases share the same visual center.
    function methods:center(x, y)
        m.center_x, m.center_y = x, y
        draw_surface(g, object, m)
    end
    function methods:text(value)
        if value == nil then return object:text() end
        object:text(value)
        draw_surface(g, object, m)
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
        if g.deferring_hide and (m.visible or m.defer_visible) then
            -- Keep a closing menu's visible rows alive just through the fade.
            -- Ordinary page changes still release their objects immediately.
            g.retired[#g.retired+1] = m
        else object:destroy() end
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
    draw_opacity(self, m)
    if kind == 'image' then proxy:fit(false); proxy:size(40, 40) end
    return proxy
end

function geometry:prim()
    local g = self
    return setmetatable({
        set_color = function(name, alpha, red, green, blue)
            local p = g.primitives[name] or {}; g.primitives[name] = p
            p.color = {alpha, red, green, blue}
            windower.prim.set_color(name, rounded_alpha(alpha, g.opacity), red, green, blue)
        end,
        set_visibility = function(name, visible)
            local p = g.primitives[name] or {}; g.primitives[name] = p
            local was_visible = p.visible or p.defer_visible
            p.visible = visible
            if not visible and g.deferring_hide and was_visible then p.defer_visible = true
            else p.defer_visible = nil; windower.prim.set_visibility(name, visible) end
        end,
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
