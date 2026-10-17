-- A: acknowledged mailbox protocol, separate from Apps/F-key gameplay input.
-- A fresh token invalidates queued input on focus/context/identity changes.
-- Complete snapshots retain unacknowledged edges, including quick tap sequences.
local M={version='l1-mailbox2'}
local valid={show=true,bank=true,release=true,cancel=true,slot=true}
function M.new(options)
    local self={options=options,ack=0,epoch=0,received=0,rejected=0,key=nil,token=nil}
    function self:reset()
        self.key=nil;self.token=nil;self.ack=0
        self.options.cancel()
    end
    function self:context(key,enabled)
        if not enabled then self:reset();return end
        if self.key~=key then
            self.epoch=self.epoch+1;self.key=key
            self.token=self.options.session..'-'..self.epoch;self.ack=0
            self.options.cancel()
        end
    end
    function self:accept(contents)
        if not self.token or type(contents)~='string' or #contents>4096 then return false end
        contents=contents:gsub('\r\n','\n') -- AHK FileAppend can publish CRLF.
        local token,stamp,body=contents:match('^token=([%w%-]+)\nstamp=(%d+)\n(.*)$')
        if token~=self.token or body:sub(-4)~='END\n' then return false end
        local age=(self.options.wallclock or os.time)()-tonumber(stamp)
        if age< -1 or age>1 then self.rejected=self.rejected+1;return false end
        local events={};local next_seq=self.ack+1
        for line in body:sub(1,-5):gmatch('[^\n]+') do
            local seq,kind,slot=line:match('^(%d+),(%a+),(%d+)$')
            seq,slot=tonumber(seq),tonumber(slot)
            if not seq or not valid[kind] or not slot or (kind=='slot' and (slot<1 or slot>8))
                or (kind~='slot' and slot~=0) then self.rejected=self.rejected+1;return false end
            if seq>self.ack then
                if seq~=next_seq then self.rejected=self.rejected+1;return false end
                events[#events+1]={seq,kind,slot};next_seq=next_seq+1
            end
        end
        for _,event in ipairs(events) do
            -- Advance before executing: a command that restarts the addon must
            -- never cause this event to run twice in the current session.
            self.ack=event[1];self.received=self.received+1
            self.options.event(event[2],event[3])
        end
        return #events>0
    end
    return self
end
return M
