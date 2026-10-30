-- A: one bounded diagnostic capture owns its files and saves one report.
-- Runtime leases/owner records stay in their original locations.
local M={}
function M.new(o)
    local self={active=false,count=0}
    function self:finish(reason)
        if not self.active then return true end
        self.active=false
        o.stop(reason)
        local assembled,body=pcall(function()
        local parts={'XIVcrossbar unified diagnostics v1\nCapture: '..self.id..'\nReason: '..reason..'\n',
            '\n=== Status at start ===\n'..self.initial,
            '\n=== Status at finish ===\n'..o.snapshot(),
            '\n=== Lua input ===\n'..(o.read(self.lua) or '[unavailable]\n'),
            '\n=== AHK input ===\n'..(o.read(self.ahk) or '[unavailable: wrapper missing, not updated, or not yet flushed]\n'),
            '\n=== Rendering ===\n'..o.render()}
        return table.concat(parts)
        end)
        if not assembled then o.report('Diagnostics assembly failed: '..tostring(body),167);return false,body end
        local called,ok,err=pcall(o.write,self.path,body)
        if not called then err=ok;ok=false end
        if ok then o.remove(self.lua);o.remove(self.ahk) end
        o.report(ok and ('Diagnostics saved: '..self.path) or ('Diagnostics save failed: '..tostring(err)),ok and 207 or 167)
        return ok,err
    end
    function self:start()
        if self.active then o.report('Diagnostics already recording: '..self.id,140);return true end
        self.count=self.count+1
        self.id=o.identity()..'-'..self.count
        self.path=o.directory..self.id..'.log'
        self.lua=o.directory..self.id..'-lua.log';self.ahk=o.directory..self.id..'-ahk.log'
        o.mkdir(o.directory)
        self.initial=o.snapshot()
        local ok,err=o.begin(self.id,self.lua)
        if not ok then o.report('Diagnostics could not start: '..tostring(err),167);return false end
        self.active=true;self.finish_at=nil;self.deadline=o.clock()+32
        o.report('Diagnostics recording for 30 seconds. Output: '..self.path,140)
        return true
    end
    function self:tick()
        if self.active and o.clock()>=(self.finish_at or self.deadline) then
            self.finish_at=nil;return self:finish('complete')
        end
    end
    function self:command(mode)
        mode=mode or 'on'
        if mode=='on' then return self:start()
        elseif mode=='off' or mode=='save' then
            if self.active then
                o.request_stop(self.id);self.finish_at=o.clock()+.75
                o.report('Finishing diagnostics; waiting for wrapper flush.')
            else o.report('Diagnostics are OFF.') end
            return true
        elseif mode=='mark' then if self.active then o.mark() end;return true
        elseif mode=='status' then o.report(self.active and ('Diagnostics recording: '..self.id) or 'Diagnostics are OFF.');return true
        end
        o.report('Use //xb diagnostics on|off|mark|status.');return false
    end
    return self
end
return M
