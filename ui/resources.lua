-- A: ownership for this addon's Windower text/image objects only. Windower's
-- libraries retain hidden objects until destroy; dropping a Lua list is not cleanup.
local M = {version='public-cleanup1-settled'}
local trace=require('ui/render_trace')
local measure=require('ui/text_measure')
local measured_fields={'text','font','size','pad','bold','italic','right_justified','stroke_width'}
local measured_setters={text=true,font=true,size=true,pad=true,bold=true,italic=true,right_justified=true,stroke_width=true}
local opacity_fields={'alpha','bg_alpha','stroke_alpha'}
local function encode(...)
    local parts={}
    for i=1,select('#',...) do parts[i]=string.format('%q',tostring(select(i,...))) end
    return table.concat(parts,',')
end
local live = {}
local disposed_objects = setmetatable({}, {__mode='k'})
local created = {text=0,image=0}
local destroyed = {text=0,image=0}

local function new(kind, library, ...)
    local api = _G[library] or require(library)
    local object = api.new(...)
    local proxy, methods, disposed = {}, {}, false
    local style,intended,measurement,style_key={},{},nil,nil
    local held_transparent=false
    -- Temporarily suppress text while its native width may describe the
    -- preceding glyphs. Preserve caller-requested fade opacity separately.
    local function hold_opacity(hold)
        if held_transparent==hold then return end
        held_transparent=hold
        for _,name in ipairs(opacity_fields) do
            if intended[name]==nil then intended[name]=object[name](object) or 0 end
            local actual=hold and 0 or intended[name]
            object[name](object,actual)
            if trace.enabled then trace.call(proxy,'native.'..name,actual) end
        end
    end
    created[kind] = created[kind] + 1
    live[proxy] = kind
    trace.track(proxy,kind,'public-resource',kind)
    if trace.enabled then trace.event('create',proxy) end
    function methods:destroy()
        if disposed then return end
        if trace.enabled then trace.event('destroy',proxy) end
        object:destroy()
        disposed = true
        live[proxy] = nil
        disposed_objects[proxy] = true
        destroyed[kind] = destroyed[kind] + 1
    end
    if kind=='text' then
        -- The geometry's requested alpha/stroke/background continue updating
        -- while the native object is held transparent until it is centered.
        for _,name in ipairs(opacity_fields) do
            methods[name]=function(_,value)
                assert(not disposed,'UI object used after disposal: text.'..name)
                if value==nil then
                    if intended[name]~=nil then return intended[name] end
                    return object[name](object)
                end
                intended[name]=value
                local actual=held_transparent and 0 or value
                if trace.enabled then trace.call(proxy,'native.'..name,actual) end
                return object[name](object,actual)
            end
        end
        function methods:measure_width()
            assert(not disposed,'UI object used after disposal: text.measure_width')
            if not measurement then measurement={} end
            if not style_key then
                local parts={}
                for i,field in ipairs(measured_fields) do
                    if style[field]==nil then style[field]=encode(object[field](object)) end
                    parts[i]=style[field]
                end
                style_key=table.concat(parts,'|')
            end
            local width,phase=measure.width(measurement,style_key,function()
                local w,h=object:extents()
                if trace.enabled then trace.call(proxy,'extents',w,h) end
                return w
            end,style.text==encode(''))
            if phase=='pending' then hold_opacity(true) end
            if trace.enabled then trace.call(proxy,'text-settle',phase,width or '-') end
            return width
        end
        function methods:commit_measurement()
            if measurement and measurement.phase~='pending' then hold_opacity(false) end
        end
        function methods:hide()
            assert(not disposed,'UI object used after disposal: text.hide')
            if trace.enabled then trace.call(proxy,'native.hide') end
            object:hide()
            measurement=nil;hold_opacity(false)
        end
        function methods:visible(value)
            assert(not disposed,'UI object used after disposal: text.visible')
            if value==nil then return object:visible() end
            if trace.enabled then trace.call(proxy,'native.visible',value) end
            object:visible(value)
            if not value then measurement=nil;hold_opacity(false) end
        end
    end
    return setmetatable(proxy, {__index=function(_, key)
        if methods[key] then return methods[key] end
        local value = object[key]
        if type(value) ~= 'function' then return value end
        local method = function(_, ...)
            assert(not disposed, 'UI object used after disposal: ' .. kind .. '.' .. key)
            -- A new caption/font/size invalidates an old native width
            -- before rendering can flash it in the wrong position.
            if kind=='text' and measured_setters[key] and select('#',...)>0 then
                local signature=encode(...)
                if style[key]~=signature then
                    style[key]=signature;style_key=nil
                    if measurement then
                        measure.invalidate(measurement)
                        if measure.enabled then hold_opacity(true) end
                    end
                end
            end
            if trace.enabled then
                if kind=='text' and key=='extents' then
                    -- Observe the requested getter's actual return. Never add
                    -- another native extents call merely for tracing.
                    local w,h=value(object,...)
                    trace.call(proxy,'extents',w,h)
                    return w,h
                end
                if select('#',...)>0 or key=='hide' or key=='show' then
                    if key=='text' and select('#',...)>0 then trace.caption(proxy,(...)) end
                    trace.call(proxy,'native.'..key,...)
                end
            end
            return value(object, ...)
        end
        methods[key] = method
        return method
    end})
end

function M.text(...) return new('text', 'texts', ...) end
function M.image(...) return new('image', 'images', ...) end

function M.clear(objects)
    if not objects then return end
    -- Read indexed entries directly: collection metadata/iterator adapters are
    -- not drawing objects. Only this registry may release the objects it owns.
    local count = rawget(objects, 'n') or #objects
    for index=1,count do
        local object = rawget(objects, index)
        if live[object] then object:destroy() end
    end
end

function M.is_disposed(object) return disposed_objects[object] == true end

function M.snapshot()
    local result = {text=0,image=0,created_text=created.text,created_image=created.image,
        destroyed_text=destroyed.text,destroyed_image=destroyed.image}
    for _, kind in pairs(live) do result[kind] = result[kind] + 1 end
    return result
end

function M.destroy_all()
    local objects = {}
    for object in pairs(live) do objects[#objects+1] = object end
    M.clear(objects)
end

return M
