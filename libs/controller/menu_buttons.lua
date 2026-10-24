-- A: one preference per addon installation, shared by all character clients.
-- Physical messages remain unchanged; only their menu roles and hints swap.
local M={swapped=false}
function M.hint(role,layout)
    local plus=(role=='chooser')~=M.swapped
    return 'ui/binding_icons/'..(plus and 'plus_' or 'minus_')..layout..'.png'
end
function M.new(options)
    local self={wanted=false,next_read=0}
    local function read()
        local raw,err=options.read(options.path)
        if raw==nil then return nil,err end
        raw=raw:gsub('\r\n','\n')
        if raw=='menu_swap=on\n' then return true end
        if raw=='menu_swap=off\n' then return false end
        return nil,'Invalid shared menu-button preference; previous setting retained.'
    end
    function self:poll(allowed,force)
        local now=options.clock()
        if force or now>=self.next_read then
            self.next_read=now+.5
            local value=read()
            if value~=nil then self.wanted=value end
        end
        if allowed and M.swapped~=self.wanted then M.swapped=self.wanted;return true end
        return false
    end
    function self:command(mode,allowed)
        mode=type(mode)=='string' and mode:lower() or 'status'
        if mode~='on' and mode~='off' and mode~='status' then
            return false,'Use //xb controller menuswap on|off|status.'
        end
        if mode~='status' then
            local unlock,err=options.lock(options.path)
            if not unlock then return false,err end
            local ok,message=options.replace(options.path,'menu_swap='..mode..'\n')
            unlock()
            if not ok then return false,message end
            self.wanted=mode=='on'
        end
        self:poll(allowed,true)
        return true,'Share/Options Swap: '..require('libs/chat_status').toggle(self.wanted)..
            ' | All Characters (This Installation)'..
            (self.wanted~=M.swapped and ' | Pending: release controls and close XIVcrossbar menus.' or '')
    end
    return self
end
return M
