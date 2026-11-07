-- Windower loads the bridge through its Lua C-module interface on opt-in.
local M = {}
function M.open(path)
    local loader, err = package.loadlib(path:gsub('\\', '/'), 'luaopen_xb_gamepad_messages')
    if not loader then error('Cannot load xb_gamepad_messages.dll: ' .. tostring(err), 0) end
    local dll = loader()
    if type(dll) ~= 'table' then
        error('Native bridge loaded, but the Windower Lua 5.1 API could not be initialized.', 0)
    end
    if type(dll.process_id) ~= 'number' or dll.process_id <= 0 then
        error('Native bridge loaded without a valid process ID. Install the complete matching test build.', 0)
    end
    local status = {0, 0, 0, 0, 0, 0, 0, 0}
    local hooks = 'hook state unknown | DLL loaded'
    return {
        begin = function(...)
            local result = dll.begin(...)
            if result == 1 then hooks = 'hooks attached | DLL resident' end
            return result
        end,
        process_id = dll.process_id,
        stop = dll.off,
        detach = function()
            local detached = dll.detach and dll.detach() == 1
            hooks = detached and 'hooks detached | DLL resident' or 'detach failed | DLL resident'
            return detached
        end,
        hook_status = function() return hooks end,
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
        armed = function() return status[8] == 1 end,
        poll_count = function() return status[2] end,
        status = function()
            return ('polls=%d raw=0x%03x masked=0x%03x buffered=%d unsupported-size=%d overflow=%d')
                :format(status[2], status[3], status[4], status[5], status[6], status[7])
        end,
    }
end
return M
