-- Only XIVCrossbar may classify a controller face button as bare or banked.
-- NPCMirror observes the resulting intent; it never re-deciphers raw buttons1
-- in the owned route. No new key injection: native input is still handled by
-- the existing companion bank/ordinary controller pipeline.
local M={}
function M.new(options)
    local self={emitted=0,suppressed=0}
    function self:edge(button,pressed,owner,cutscene,token,sequence)
        if not pressed or (button~=5 and button~=7) then return false end
        if owner~='ordinary' or not cutscene then
            self.suppressed=self.suppressed+1
            return false
        end
        if type(token)~='string' or not token:match('^[%w%-]+$')
            or type(sequence)~='number' or sequence<1 or sequence%1~=0 then return false end
        local action=button==5 and 'enter' or 'esc'
        if options.emit then options.emit(action,sequence,token) end
        self.emitted=self.emitted+1
        return true
    end
    return self
end
return M
