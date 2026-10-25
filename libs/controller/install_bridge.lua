-- A: local installer may request only graceful unload. No command execution
-- protocol; a stale request or an open editor cannot silently unload a client.
local M={}
function M.new(options)
    local self={next_poll=0,last_id=nil}
    function self:poll()
        local now=options.clock()
        if now<self.next_poll then return end
        self.next_poll=now+1
        local raw=options.read()
        if type(raw)~='string' or #raw>512 then return end
        raw=raw:gsub('\r\n','\n')
        local id,expires=raw:match('^%[Installer%]\nprotocol=1\nid=([a-f0-9]+)\naction=unload\nexpires=(%d+)\nEND\n$')
        expires=tonumber(expires)
        if not id or #id~=32 or not expires or expires<options.wallclock() or expires>options.wallclock()+120 then return end
        if id==self.last_id then return end
        local busy=options.busy()
        -- Acknowledge before scheduling unload; the installer separately verifies
        -- that owner handles and the shared wrapper actually released.
        if options.ack(id,busy and 'busy' or 'unloading')==false then return end
        if busy then return end
        self.last_id=id
        options.unload()
    end
    return self
end
return M
