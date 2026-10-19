-- A: private per-character context lease for the optional PS5 extended wrapper.
-- AHK reads hardware; Lua publishes context and the selected button transport.
local M={}
function M.new(options)
    options=options or {}
    local self={clock=options.clock or require('socket').gettime,open=options.open or io.open,
        remove=options.remove or os.remove,create_dir=options.create_dir or windower.create_dir}
    function self:close()
        if self.path then
            self.remove(self.path)
            self.remove(self.path:gsub('%.ini$','.l1'))
            self.remove((self.path:gsub('%.ini$','.l1'))..'.tmp')
            self.remove(self.path:gsub('%.ini$','.buttons'))
            self.remove((self.path:gsub('%.ini$','.buttons'))..'.tmp')
            self.remove(self.path..'.tmp')
        end
        self.path,self.mode,self.next_write,self.payload=nil,nil,nil,nil
    end
    function self:update(directory,name,profile,mode,l1)
        if profile~='ps5-extended' or type(name)~='string' or not name:match('^%a+$') then
            self:close();return false
        end
        local path=directory..name..'.ini'
        if self.path~=path then self:close();self.create_dir(directory);self.path=path end
        local now=self.clock()
        l1=l1 or {}
        local payload='\nbank_protocol='..(l1.banks and '1' or '0')..'\nbank_native_token='..(l1.native_token or '')..'\nbank_native_base='..(l1.native_base or 0)..'\nbank_native='..(l1.native or '')..
            '\nr1_menus='..(l1.r1_menus and '1' or '0')..'\ndpad_output='..(l1.realkeys and 'ahk' or 'lua')..'\nl1token='..(l1.token or '')..'\nl1mode='..(l1.mode or 'keyboard')..'\nl1ack='..(l1.ack or 0)..
            '\ntarget_r2='..(l1.target_r2 and '1' or '0')..'\ntarget_r3='..(l1.target_r3 and '1' or '0')..'\nbutton_mode='..(l1.messages and 'messages' or 'keys')..'\nbutton_token='..(l1.button_token or '')..
            '\nbutton_ack='..(l1.button_ack or 0)..'\nbutton_recover='..(l1.button_recover and '1' or '0')..
            '\nbutton_reason='..(l1.button_reason or 'context')..'\nEND\n'
        if self.mode==mode and self.payload==payload and self.next_write and now<self.next_write then return true end
        self.next_write=now+.25
        -- AHK validates the name/mode/timestamp and complete END trailer.
        -- Its bounded uncertain-read pause handles the Windows swap gap below.
        -- Publish complete leases, not a half-written gameplay/menu context.
        local temporary=path..'.tmp'
        local f=self.open(temporary,'w')
        if not f then self.remove(path);self.mode=nil;return false end
        local ok=f:write('[Personal]\nname='..name..'\nmode='..mode..'\ntimestamp='..math.floor(now)..payload)
        local closed=f:close();ok=ok and closed
        if ok then
            self.remove(path)
            ok=(options.rename or os.rename)(temporary,path)
        end
        self.mode=ok and mode or nil;self.payload=ok and payload or nil
        if not ok then self.remove(path);self.remove(temporary) end
        return ok~=nil and ok~=false
    end
    return self
end
return M
