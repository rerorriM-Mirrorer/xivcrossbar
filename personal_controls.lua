-- A: private per-character context lease for the optional PS5 extended wrapper.
-- AHK still reads hardware and sends keys; Lua reports when menu/text owns input.
local M={}
function M.new(options)
    options=options or {}
    local self={clock=options.clock or require('socket').gettime,open=options.open or io.open,
        remove=options.remove or os.remove,create_dir=options.create_dir or windower.create_dir}
    function self:close()
        if self.path then self.remove(self.path) end
        self.path,self.mode,self.next_write=nil,nil,nil
    end
    function self:update(directory,name,profile,mode)
        if profile~='ps5-extended' or type(name)~='string' or not name:match('^%a+$') then
            self:close();return false
        end
        local path=directory..name..'.ini'
        if self.path~=path then self:close();self.create_dir(directory);self.path=path end
        local now=self.clock()
        if self.mode==mode and self.next_write and now<self.next_write then return true end
        self.next_write=now+.25
        -- Partial reads are safe: AHK requires name/mode/timestamp before use.
        local f=self.open(path,'w')
        if not f then self.remove(path);self.mode=nil;return false end
        local ok=f:write('[Personal]\nname='..name..'\nmode='..mode..'\ntimestamp='..math.floor(now)..'\n')
        f:close();self.mode=ok and mode or nil
        if not ok then self.remove(path) end
        return ok~=nil
    end
    return self
end
return M
