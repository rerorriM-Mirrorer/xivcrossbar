-- Contributing author: A — geometry, texture reuse and whole-panel opacity.
-- Keep layout calculations in the original 40-pixel units. Only the final
-- drawing calls change scale, so recast crops, controller hints and labels
-- follow exactly the same transform. Other addons' Windower objects are untouched.
local geometry = {}
geometry.__index = geometry
local rounded_bar = require('ui/rounded_bar')

local function draw_primitive(g, name, p)
    if p.rounded then
        if p.x and p.width then
            local x,y = g:point(p.x,p.y)
            p.rounded:layout(x,y,p.width*g.scale,p.height*g.scale,g.scale,p.round_left,p.round_right)
        end
    else
        if p.x then windower.prim.set_position(name,g:point(p.x,p.y)) end
        if p.width then windower.prim.set_size(name,p.width*g.scale,p.height*g.scale) end
    end
end

local function primitive_visibility(name, p, show)
    if p.rounded then p.rounded:show(show)
    else windower.prim.set_visibility(name,show) end
end

local function primitive_color(g, name, p)
    if not p.color then return end
    local c = p.color
    local alpha = math.floor((c[1] or 255)*g.opacity+.5)
    if p.rounded then p.rounded:color(alpha,c[2],c[3],c[4])
    else windower.prim.set_color(name,alpha,c[2],c[3],c[4]) end
end

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

local draw_opacity
local function draw_position(g, object, m, x, y)
    local sx, sy = g:point(x, y, m.right)
    if sx ~= m.draw_x or sy ~= m.draw_y then
        object:pos(sx, sy)
        m.draw_x, m.draw_y = sx, sy
        m.draw_alpha=nil
    end
end

local function draw_surface(g, object, m)
    if m.width then
        local width, height = m.width*g.scale, m.height*g.scale
        if width ~= m.draw_width or height ~= m.draw_height then
            object:size(width,height);m.draw_width,m.draw_height=width,height;m.draw_alpha=nil
        end
    elseif m.font_size then
        local size=math.max(1,math.floor(m.font_size*g.scale+.5))
        if size ~= m.draw_font_size then object:size(size);m.draw_font_size=size;m.draw_alpha=nil end
    end
    if m.stroke then
        local stroke=m.stroke*g.scale
        if stroke ~= m.draw_stroke then object:stroke_width(stroke);m.draw_stroke=stroke end
    end
    if m.padding then
        local padding=m.padding*g.scale
        if padding ~= m.draw_padding then object:pad(padding);m.draw_padding=padding end
    end
    if m.center_x then
        local width=object:extents()
        if width and width>0 then
            m.x,m.y=m.center_x-width/g.scale/2,m.center_y
            draw_position(g,object,m,m.x,m.y)
        end
    elseif m.x then draw_position(g,object,m,m.x,m.y) end
    draw_opacity(g,m)
end

function geometry:refresh()
    for proxy, m in pairs(self.surfaces) do draw_surface(self, m.object, m) end
    for name, p in pairs(self.primitives) do
        draw_primitive(self,name,p)
    end
end

-- A: relayout a single existing surface without changing its texture, crop,
-- visibility or ownership. Labels with a stored center move by the same delta.
function geometry:move_surface(surface, dx, dy)
    local m = self.surfaces[surface]
    if not m then return end
    if m.x then m.x, m.y = m.x + dx, m.y + dy end
    if m.center_x then m.center_x, m.center_y = m.center_x + dx, m.center_y + dy end
    draw_surface(self, m.object, m)
end

function geometry:set_scale(scale)
    self.scale = scale
    self:refresh()
end

local function rounded_alpha(alpha, opacity)
    return math.floor((alpha or 255)*opacity + .5)
end

draw_opacity = function(g, m)
    -- A: endpoint text is the default. The optional comparison lets glyphs,
    -- backgrounds and strokes follow the same opacity as the crossbar images.
    local opacity=g.opacity
    local animated_text = g.fade_enabled or g.startup_reveal
    if m.kind=='text' and animated_text and not g.text_fade then
        opacity=(g.opacity==1 and g.fade and g.fade.target==1) and 1 or 0
    end
    local alpha=rounded_alpha(m.alpha,opacity)
    if alpha ~= m.draw_alpha then m.object:alpha(alpha);m.draw_alpha=alpha end
    if m.bg_alpha then
        local bg=rounded_alpha(m.bg_alpha,opacity)
        if bg ~= m.draw_bg_alpha then m.object:bg_alpha(bg);m.draw_bg_alpha=bg end
    end
    if m.stroke_alpha then
        local stroke=rounded_alpha(m.stroke_alpha,opacity)
        if stroke ~= m.draw_stroke_alpha then m.object:stroke_alpha(stroke);m.draw_stroke_alpha=stroke end
    end
    if m.kind=='text' then
        local visible=(m.visible or m.defer_visible) and (not animated_text or opacity>0)
        if visible and not m.draw_visible then m.object:show();m.draw_visible=true
        elseif not visible and m.draw_visible then m.object:hide();m.draw_visible=false end
    end
    if g.opacity == 0 and m.defer_visible then
        m.object:hide();m.draw_visible=false;m.defer_visible=nil
    end
end

function geometry:set_text_fade(enabled)
    self.text_fade = enabled == true
    for _, m in pairs(self.surfaces) do
        if m.kind=='text' then draw_opacity(self, m) end
    end
    for _, m in ipairs(self.retired) do
        if m.kind=='text' then draw_opacity(self, m) end
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
        primitive_color(self,name,p)
        if self.opacity == 0 and p.defer_visible then
            primitive_visibility(name,p,false); p.defer_visible = nil
        end
    end
    if self.opacity == 0 then
        for _, m in ipairs(self.retired) do m.object:destroy() end
        self.retired, self.deferring_hide = {}, false
    end
end

function geometry:configure_fade(enabled, fade_in, fade_out, load_fade_in, load_fade_state)
    local startup = self.startup_reveal and self.fade
    self.fade_enabled = enabled == true
    self.fade_in, self.fade_out = fade_in or .12, fade_out or .18
    if load_fade_state then
        self.load_fade_in, self.load_fade_state = load_fade_in, load_fade_state
        self.startup_reveal, startup = false, nil
    end
    -- Changing regular fades does not cancel or replay the startup phase.
    self.fade = startup or require('ui_fade').new(require('socket').gettime, self.opacity)
end

-- Autohide waits for the startup reveal, including one fully visible frame.
-- Explicit hiding and cutscenes still take precedence in the visibility policy.
function geometry:is_startup_reveal_pending()
    if not self.load_fade_state then return false end
    if not self.load_fade_state.claimed then return true end
    if not self.startup_reveal or self.fade.target ~= 1 then return false end
    if not self.fade.active then self.startup_reveal = false end
    return true
end

function geometry:interrupt_startup_reveal()
    if not self.load_fade_state then return end
    if self.load_fade_state.claimed and not self.startup_reveal then return end
    -- Gameplay input takes priority over the longer welcome animation.
    -- Preserve the current opacity and use the normal reveal duration once.
    self.load_fade_state.claimed = true
    self.startup_reveal = false
    self.fade:step()
    self.fade.active = false
    self:transition(true)
end

function geometry:transition(show)
    local duration = self.fade_enabled and (show and self.fade_in or self.fade_out) or 0
    if show and self.load_fade_state and not self.load_fade_state.claimed then
        -- Begin once the loaded bar can actually render, even without input.
        self.load_fade_state.claimed = true
        self.startup_reveal = true
        duration = self.load_fade_in or duration
    end
    if not show then self.startup_reveal = false end
    self.fade:to(show and 1 or 0, duration)
    self.deferring_hide = not show and self.fade.active
    if show then
        -- A reversed close must not resurrect rows destroyed by a menu reset.
        for _, m in ipairs(self.retired) do m.object:destroy() end
        self.retired = {}
        for _, m in pairs(self.surfaces) do
            if m.defer_visible then m.object:hide();m.draw_visible=false; m.defer_visible = nil end
        end
        for name, p in pairs(self.primitives) do
            if p.defer_visible then primitive_visibility(name,p,false); p.defer_visible = nil end
        end
    end
    self:set_opacity(self.fade.value)
end

function geometry:tick()
    for _,m in pairs(self.surfaces) do
        if m.center_x and m.visible then draw_surface(self,m.object,m) end
    end
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
    local m = {object = object, kind=kind, visible=false, alpha=255,
        right = options and options.flags and options.flags.right}
    local proxy = {}
    local methods = {}
    function methods:alpha(value)
        if value == nil then return m.alpha end
        m.alpha = value; draw_opacity(g,m)
    end
    function methods:bg_alpha(value)
        if value == nil then return m.bg_alpha end
        m.bg_alpha = value; draw_opacity(g,m)
    end
    function methods:stroke_alpha(value)
        if value == nil then return m.stroke_alpha end
        m.stroke_alpha = value; draw_opacity(g,m)
    end
    -- Windower transparency uses 0..1; keep base alpha in 0..255 internally.
    function methods:stroke_transparency(value)
        if value == nil then return 1 - (m.stroke_alpha or 255)/255 end
        self:stroke_alpha(math.floor(255*(1-value)))
    end
    function methods:show()
        m.visible, m.defer_visible = true, nil
        if m.kind=='text' and (g.fade_enabled or g.startup_reveal) then draw_opacity(g,m); return end
        if not m.draw_visible then object:show();m.draw_visible=true;m.draw_alpha=nil end
        draw_opacity(g, m)
    end
    function methods:hide()
        local was_visible = m.visible or m.defer_visible
        m.visible = false
        if g.deferring_hide and was_visible then m.defer_visible = true
        else m.defer_visible = nil; if m.draw_visible then object:hide();m.draw_visible=false end end
    end
    function methods:visible(value)
        if value == nil then return m.visible end
        if value then self:show() else self:hide() end
    end
    function methods:pos(x, y)
        if x == nil then return m.x, m.y end
        m.x, m.y = x, y
        draw_position(g,object,m,x,y)
        draw_opacity(g,m)
    end
    -- Store the tile center, not a fixed left edge. Recalculate after font or
    -- caption changes so short and long aliases share the same visual center.
    function methods:center(x, y)
        m.center_x, m.center_y = x, y
        draw_surface(g, object, m)
    end
    function methods:text(value)
        if value == nil then return object:text() end
        if m.text == value then return end
        object:text(value);m.text=value;m.draw_alpha=nil
        draw_surface(g,object,m)
    end
    function methods:color(red,green,blue)
        if red == nil then return object:color() end
        if red==m.red and green==m.green and blue==m.blue then return end
        object:color(red,green,blue);m.red,m.green,m.blue=red,green,blue;m.draw_alpha=nil
        draw_opacity(g,m)
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
        draw_surface(g,object,m)
    end
    function methods:pad(padding)
        if padding == nil then return m.padding end
        m.padding = padding
        draw_surface(g,object,m)
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
        create_rounded = function(name)
            local previous = g.primitives[name]
            if previous and previous.rounded then previous.rounded:destroy() end
            g.primitives[name] = {rounded=rounded_bar.new(name,windower.prim)}
        end,
        set_rounding = function(name, left, right)
            local p = g.primitives[name]
            if not p or not p.rounded then return end
            p.round_left,p.round_right = left,right
            draw_primitive(g,name,p)
        end,
        set_color = function(name, alpha, red, green, blue)
            local p = g.primitives[name] or {}; g.primitives[name] = p
            p.color = {alpha, red, green, blue}
            primitive_color(g,name,p)
        end,
        set_visibility = function(name, visible, immediate)
            local p = g.primitives[name] or {}; g.primitives[name] = p
            local was_visible = p.visible or p.defer_visible
            p.visible = visible
            if not visible and not immediate and g.deferring_hide and was_visible then p.defer_visible = true
            else p.defer_visible = nil; primitive_visibility(name,p,visible) end
        end,
        set_position = function(name, x, y)
            local p = g.primitives[name] or {}; g.primitives[name] = p
            p.x, p.y = x, y
            draw_primitive(g,name,p)
        end,
        set_size = function(name, width, height)
            local p = g.primitives[name] or {}; g.primitives[name] = p
            p.width, p.height = width, height
            draw_primitive(g,name,p)
        end,
    }, {__index = windower.prim})
end

return geometry
