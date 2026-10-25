-- Beta 1: twelve ordinary PS5 edges, one ordered acknowledged stream.
-- The same router handles Apps-key and message events; companion banks are absent.
local M={diks={59,60,61,62,63,64,65,66,67,68,87,88}}
function M.new(opts)
    local self={token=nil,key=nil,epoch=0,ack=0,held={},captured=false,last_seen=0,received=0,rejected=0}
    local function cancel()
        self.held={}
        if self.captured then self.captured=false;opts.capture(false) end
        opts.cancel()
    end
    function self:reset(reason)
        if self.token then cancel() end
        self.token=nil;self.key=nil;self.ack=0;self.last_beat=nil;self.last_seen=0
        self.reason=reason or 'reset'
    end
    function self:context(key,enabled)
        if not enabled then
            if self.token then self:reset('inactive') end
            return
        end
        if self.key~=key then
            self:reset('new-context')
            self.epoch=self.epoch+1
            self.key=key
            self.token=opts.session..'-buttons-'..self.epoch
        end
    end
    function self:watchdog()
        if self.captured and opts.clock()-self.last_seen>.35 then
            self:reset('heartbeat')
            return true
        end
        return false
    end
    function self:accept(contents)
        if not self.token or type(contents)~='string' or #contents>8192 then return false end
        contents=contents:gsub('\r\n','\n')
        local token,stamp,beat,body=contents:match('^token=([%w%-]+)\nstamp=(%d+)\nbeat=(%d+)\n(.*)$')
        if token~=self.token or not body or body:sub(-4)~='END\n' then return false end
        local age=opts.wallclock()-tonumber(stamp)
        if age< -1 or age>2 then self.rejected=self.rejected+1;return false end
        local events,next_seq,last_cancel={},self.ack+1,0
        for line in body:sub(1,-5):gmatch('[^\n]+') do
            local seq,kind,button=line:match('^(%d+),(%a+),(%d+)$')
            seq,button=tonumber(seq),tonumber(button)
            if not seq or not button or not (((kind=='down' or kind=='up') and button>=1 and button<=12)
                or ((kind=='cancel' or kind=='stall') and button==0)) then
                self.rejected=self.rejected+1;return false
            end
            if seq>self.ack then
                if seq~=next_seq then self.rejected=self.rejected+1;return false end
                events[#events+1]={seq,kind,button};next_seq=next_seq+1
                if kind=='cancel' or kind=='stall' then last_cancel=#events end
            end
        end
        beat=tonumber(beat)
        if self.last_beat and beat<self.last_beat then return false end
        if beat~=self.last_beat then self.last_seen=opts.clock();self.last_beat=beat end
        for index,event in ipairs(events) do
            -- Never replay an earlier action before a later cancel in one snapshot.
            self.ack=event[1];self.received=self.received+1
            if index>=last_cancel then
                local kind,button=event[2],event[3]
                if kind=='cancel' then cancel()
                elseif kind=='stall' then self:reset('output-stall')
                elseif kind=='down' and not self.held[button] then
                    if not self.captured then self.captured=true;opts.capture(true) end
                    self.held[button]=true
                    opts.event(M.diks[button],true)
                elseif kind=='up' and self.held[button] then
                    self.held[button]=nil
                    opts.event(M.diks[button],false)
                    if not next(self.held) then self.captured=false;opts.capture(false) end
                end
            end
            if self.token~=token then break end
        end
        return #events>0
    end
    return self
end
return M
