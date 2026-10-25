-- Beta 1 focused-client context lease. Only the PS5 reader consumes it.
-- Per-character filename matches the focused FFXI window title on the AHK side.
local M={}
function M.new(opts)
    local self={clock=opts.clock,create_dir=opts.create_dir or windower.create_dir}
    function self:close()
        if self.path then
            os.remove(self.path)
            os.remove(self.path..'.tmp')
            os.remove((self.path:gsub('%.ini$','.buttons')))
            os.remove((self.path:gsub('%.ini$','.buttons'))..'.tmp')
        end
        self.path=nil;self.next_write=nil;self.payload=nil
    end
    function self:update(directory,name,mode,token,ack)
        if type(name)~='string' or not name:match('^%a+$') then self:close();return false end
        local path=directory..name..'.ini'
        if self.path~=path then self:close();self.create_dir(directory);self.path=path end
        local now=self.clock()
        local payload='mode='..mode..'\nbutton_mode='..(token and 'messages' or 'keys')..
            '\nbutton_token='..(token or '')..'\nbutton_ack='..tostring(ack or 0)..'\n'
        if self.payload==payload and self.next_write and now<self.next_write then return true end
        self.next_write=now+.10
        local temporary=path..'.tmp'
        local f=io.open(temporary,'wb')
        if not f then os.remove(path);self.payload=nil;return false end
        local ok=f:write('[Controller]\nname='..name..'\ntimestamp='..math.floor(now)..'\n'..payload..'END\n')
        local closed=f:close()
        if not ok or not closed then os.remove(temporary);os.remove(path);self.payload=nil;return false end
        os.remove(path)
        if not os.rename(temporary,path) then os.remove(temporary);self.payload=nil;return false end
        self.payload=payload
        return true
    end
    return self
end
return M
