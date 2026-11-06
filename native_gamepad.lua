-- Loaded only on explicit opt-in. A pinned DLL keeps dormant callbacks valid
-- if Windower unloads this Lua state.
local M = {}
function M.open(path)
    local ffi = require('ffi')
    ffi.cdef[[
        unsigned int __cdecl xb_begin(unsigned int, unsigned int, unsigned int, unsigned int, const char*);
        void __cdecl xb_off(void);
        unsigned int __cdecl xb_poll(unsigned int, int*, unsigned int, unsigned int*);
    ]]
    local dll = ffi.load(path)
    local events = ffi.new('int[256]')
    local status = ffi.new('unsigned int[7]')
    return {
        begin = function(...) return tonumber(dll.xb_begin(...)) end,
        stop = function() dll.xb_off() end,
        poll = function(context, reset, deliver, previous)
            local count = dll.xb_poll(context, events, 256, status)
            local generation = tonumber(status[0])
            if generation ~= previous then reset() end
            for i = 0, count - 1 do
                local edge = tonumber(events[i])
                deliver(math.abs(edge), edge > 0)
            end
            return generation
        end,
        status = function()
            return ('polls=%d raw=0x%03x masked=0x%03x buffered=%d unsupported-size=%d overflow=%d')
                :format(tonumber(status[1]), tonumber(status[2]), tonumber(status[3]),
                    tonumber(status[4]), tonumber(status[5]), tonumber(status[6]))
        end,
    }
end
return M
