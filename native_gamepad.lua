-- Windower loads the bridge through its Lua C-module interface on opt-in.
local M = {}
function M.open(path)
    local loader, err = package.loadlib(path:gsub('\\', '/'), 'luaopen_xb_gamepad')
    if not loader then error(err) end
    local dll = loader()
    if type(dll) ~= 'table' then error('Native bridge could not resolve the Windower LuaCore.dll API.') end
    local status = {0, 0, 0, 0, 0, 0, 0}
    return {
        begin = dll.begin,
        stop = dll.off,
        detach = dll.detach,
        poll = function(context, reset, deliver, previous)
            local edges
            edges, status = dll.poll(context)
            local generation = status[1]
            if generation ~= previous then reset() end
            for _, edge in ipairs(edges) do
                deliver(math.abs(edge), edge > 0)
            end
            return generation
        end,
        poll_count = function() return status[2] end,
        status = function()
            return ('polls=%d raw=0x%03x masked=0x%03x buffered=%d unsupported-size=%d overflow=%d')
                :format(status[2], status[3], status[4], status[5], status[6], status[7])
        end,
    }
end
return M
