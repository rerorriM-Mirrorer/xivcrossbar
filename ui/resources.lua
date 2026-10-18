-- A: ownership for this addon's Windower text/image objects only. Windower's
-- libraries retain hidden objects until destroy; dropping a Lua list is not cleanup.
local M = {version='cleanup6'}
local live = {}
local disposed_objects = setmetatable({}, {__mode='k'})
local created = {text=0,image=0}
local destroyed = {text=0,image=0}
local trace = require('ui/render_trace')
local measure = require('ui/text_measure')
local measured_fields={'text','font','size','pad','bold','italic','right','stroke_width'}
local measured_setters={text=true,font=true,size=true,pad=true,bold=true,italic=true,right=true,stroke_width=true}
local opacity_fields={alpha=true,bg_alpha=true,stroke_alpha=true}
local function encode(...)
    local parts={}
    for i=1,select('#',...) do parts[i]=string.format('%q',tostring(select(i,...))) end
    return table.concat(parts,',')
end
local observed = {text=true,font=true,size=true,pos=true,pos_x=true,pos_y=true,color=true,
    alpha=true,bg_alpha=true,bg_visible=true,stroke_alpha=true,stroke_color=true,
    stroke_width=true,pad=true,show=true,hide=true,visible=true,bold=true,italic=true,flags=true}

local function new(kind, library, ...)
    local api = _G[library] or require(library)
    local object = api.new(...)
    local proxy, methods, disposed = {}, {}, false
    local style,intended,measurement,style_key={},{},nil,nil
    local held_transparent=false
    local function opacity(hold)
        if hold==held_transparent then return end
        held_transparent=hold
        for field in pairs(opacity_fields) do
            if intended[field]==nil then intended[field]=object[field](object) or 0 end
            object[field](object,hold and 0 or intended[field])
            if trace.enabled then trace.call(proxy,'native.'..field,hold and 0 or intended[field]) end
        end
    end
    created[kind] = created[kind] + 1
    live[proxy] = kind
    trace.track(proxy,kind)
    if trace.enabled then trace.event('create',proxy) end
    function methods:destroy()
        if disposed then return end
        object:destroy()
        disposed = true
        live[proxy] = nil
        disposed_objects[proxy] = true
        destroyed[kind] = destroyed[kind] + 1
        if trace.enabled then trace.event('destroy',proxy) end
    end
    if kind=='text' then
        -- Keep requested alpha separate from temporary measurement alpha. Fade
        -- and chooser updates can continue while the native object is transparent.
        for field in pairs(opacity_fields) do
            local name=field
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
            -- Positioning and optional font fitting must finish before reveal.
            if phase=='pending' then opacity(true) end
            if trace.enabled then trace.call(proxy,'text-settle',phase,width or '-') end
            return width,phase
        end
        function methods:commit_measurement()
            if measurement and measurement.phase~='pending' then opacity(false) end
        end
        function methods:hide()
            assert(not disposed,'UI object used after disposal: text.hide')
            if trace.enabled then trace.call(proxy,'native.hide') end
            object:hide()
            -- A menu may reuse this object as ordinary text after hiding it.
            -- Its old centering owner must not leave that future text gated.
            measurement=nil;opacity(false)
        end
        function methods:visible(value)
            assert(not disposed,'UI object used after disposal: text.visible')
            if value==nil then return object:visible() end
            if trace.enabled then trace.call(proxy,'native.visible',value) end
            object:visible(value)
            if not value then measurement=nil;opacity(false) end
        end
    end
    return setmetatable(proxy, {__index=function(_, key)
        if methods[key] then return methods[key] end
        local value = object[key]
        if type(value) ~= 'function' then return value end
        local method = function(_, ...)
            assert(not disposed, 'UI object used after disposal: ' .. kind .. '.' .. key)
            if kind=='text' and measured_setters[key] and select('#',...)>0 then
                local signature=encode(...)
                if signature~=style[key] then
                    style[key]=signature;style_key=nil
                    if measurement then
                        measure.invalidate(measurement)
                        if measure.enabled then opacity(true) end
                    end
                end
            end
            if kind=='text' and key=='text' and select('#',...)>0 then trace.caption(proxy,(...)) end
            if trace.enabled then
                if kind=='text' and key=='extents' then
                    local width,height=value(object,...)
                    trace.call(proxy,'extents',width,height)
                    return width,height
                end
                if kind=='text' and observed[key] and (select('#',...)>0 or key=='show' or key=='hide') then
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
