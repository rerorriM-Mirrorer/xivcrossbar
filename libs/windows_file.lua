-- A: Windower uses stock Lua, not LuaJIT. Reserve a local UDP port only while
-- saving a catalog; no packets are sent. All clients hash the canonical path
-- alike. A collision serializes unrelated catalogs rather than losing edits.
-- LuaSocket closes sockets when the Lua state ends, including client crashes.
local M = {}
local cached
local raise = (_raw and _raw.error) or error
function M.lock_port(path)
    local hash = 0
    for byte in path:lower():gsub('\\', '/'):gmatch('.') do
        hash = (hash * 33 + byte:byte()) % 16384
    end
    return 49152 + hash
end
function M.new(options)
    if not options and cached then return cached end
    options = options or {}
    local socket = options.socket or require('socket')
    local open = options.open or io.open
    local rename = options.rename or os.rename
    local remove = options.remove or os.remove
    local clock = options.clock or socket.gettime
    -- An unconnected TCP socket reserves a unique session number without
    -- listening, sending data, or needing the game's process ID.
    local identity = assert(socket.tcp())
    local bound, bind_error = identity:bind('127.0.0.1', 0)
    if not bound then identity:close(); raise(bind_error) end
    local _, port = identity:getsockname()
    if not port then identity:close(); raise('Could not identify this addon session.') end
    local id = string.format('%.0f', clock() * 1000000) .. '-' .. port
    local counter = 0
    local function exists(path)
        local f = open(path, 'rb')
        if not f then return false end
        f:close(); return true
    end
    local backend = {session_id=id, token=id, clock=clock, identity=identity}
    function backend.lock(path)
        local udp, err = (socket.udp4 or socket.udp)()
        if not udp then return nil, err end
        local supported, configured = pcall(udp.setoption, udp, 'reuseaddr', false)
        if not supported or not configured then
            udp:close(); return nil, 'Could not reserve the catalog save lock; draft retained.'
        end
        local locked = udp:setsockname('127.0.0.1', M.lock_port(path))
        if not locked then
            udp:close(); return nil, 'Catalog is busy or inaccessible; draft retained. Retry saving.'
        end
        local released = false
        return function()
            if not released then released=true; udp:close() end
        end
    end
    function backend.hold_owner(path)
        if not exists(path) then
            local f, err = open(path, 'wb')
            if not f then return nil, err end
            local ok, close_error = f:close()
            if not ok then return nil, close_error end
        end
        -- AHK probes this open file exclusively. Windows closes the handle on
        -- unload/crash; a minimized or pre-login client's handle stays open.
        return open(path, 'rb')
    end
    function backend.replace(path, contents)
        counter = counter + 1
        local temp = path .. '.tmp.' .. id .. '.' .. counter
        local pending = path .. '.pending'
        -- Recover an interrupted swap before publishing another revision.
        if exists(pending) then
            local recovered, recovery_error
            if exists(path) then recovered, recovery_error = remove(pending)
            else recovered, recovery_error = rename(pending, path) end
            if not recovered then return false, recovery_error end
        end
        local f, err = open(temp, 'wb')
        if not f then return false, err end
        local written, write_error = f:write(contents)
        local closed, close_error = f:close()
        if not written or not closed then remove(temp); return false, write_error or close_error end
        local had_old = exists(path)
        if had_old then
            local moved, move_error = rename(path, pending)
            if not moved then remove(temp); return false, move_error end
        end
        local replaced, replace_error = rename(temp, path)
        if not replaced then
            local restored, restore_error = true, nil
            if had_old then restored, restore_error = rename(pending, path) end
            remove(temp)
            if not restored then
                return false, tostring(replace_error)..'; prior contents retained at '..pending..': '..tostring(restore_error)
            end
            return false, replace_error
        end
        if had_old then remove(pending) end
        return true
    end
    if not options.socket then cached = backend end
    return backend
end
return M
