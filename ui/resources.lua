-- A: ownership for this addon's Windower text/image objects only. Windower's
-- libraries retain hidden objects until destroy; dropping a Lua list is not cleanup.
local M = {}
local live = {}
local disposed_objects = setmetatable({}, {__mode='k'})
local created = {text=0,image=0}
local destroyed = {text=0,image=0}

local function new(kind, library, ...)
    local api = _G[library] or require(library)
    local object = api.new(...)
    local proxy, methods, disposed = {}, {}, false
    created[kind] = created[kind] + 1
    live[proxy] = kind
    function methods:destroy()
        if disposed then return end
        object:destroy()
        disposed = true
        live[proxy] = nil
        disposed_objects[proxy] = true
        destroyed[kind] = destroyed[kind] + 1
    end
    return setmetatable(proxy, {__index=function(_, key)
        if methods[key] then return methods[key] end
        local value = object[key]
        if type(value) ~= 'function' then return value end
        local method = function(_, ...)
            assert(not disposed, 'UI object used after disposal: ' .. kind .. '.' .. key)
            return value(object, ...)
        end
        methods[key] = method
        return method
    end})
end

function M.text(...) return new('text', 'texts', ...) end
function M.image(...) return new('image', 'images', ...) end

function M.clear(objects)
    for _, object in pairs(objects or {}) do object:destroy() end
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
