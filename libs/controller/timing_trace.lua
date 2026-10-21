-- A: opt-in receiver diagnostics. No routing changes; bounded in-memory buffer.
local M={}
function M.new(options)
    local self={active=false,lines={},bytes=0}
    function self:record(message)
        if not self.active then return end
        local line=string.format('%.6f %s\n',options.clock(),message)
        if self.bytes+#line>262144 then self:stop('buffer-limit');return end
        self.lines[#self.lines+1]=line;self.bytes=self.bytes+#line
    end
    function self:state(message)
        if not self.active or self.last_state==message then return end
        self.last_state=message
        self:record('state '..message)
    end
    function self:stop(reason)
        if not self.active then return true end
        -- Deactivate before I/O; a failed save must not leave tracing running.
        self.active=false
        self.lines[#self.lines+1]=string.format('%.6f stop %s\n',options.clock(),reason or 'manual')
        local ok,err=options.write(self.path,table.concat(self.lines))
        self.lines={};self.bytes=0
        if not ok then options.say('Lua trace save failed: '..tostring(err)) end
        return ok
    end
    function self:start(path,build)
        if self.active then self:stop('restart') end
        self.path=path;self.lines={};self.bytes=0;self.active=true
        self.deadline=options.clock()+31;self.previous=nil;self.last_state=nil
        self:record('start build='..build..' utc='..os.date('!%Y%m%d%H%M%S'))
    end
    function self:tick(context)
        if not self.active then return end
        local now=options.clock()
        if now>=self.deadline then self:stop('deadline');return end
        if self.previous and now-self.previous>.03 then
            self:record(string.format('lua update_gap_ms=%.1f context=%s',(now-self.previous)*1000,context))
        end
        self.previous=now
    end
    return self
end
return M
