-- A: ordered physical-button messages. The existing router owns their meaning.
-- Complete, acknowledged snapshots retain taps between frames; session tokens
-- prevent another client or an old focus session from replaying those taps.
local M={version='buttons1',diks={59,60,61,62,63,64,65,66,67,68,87,88}}
function M.command(settings,mode,save,say)
    mode=type(mode)=='string' and mode:lower() or nil
    if mode and mode~='on' and mode~='off' and mode~='status' then
        say('Use //xb messages [on|off|status].');return false
    end
    if mode~='status' then
        settings.ControllerMessages=mode and mode=='on' or mode==nil and not settings.ControllerMessages
        save()
    end
    say('Controller messages '..(settings.ControllerMessages and 'ON' or 'OFF')..
        '. PS5 Extended; return controls to neutral for handoff.')
    return mode~='status'
end
function M.new(options)
    local self={token=nil,key=nil,epoch=0,ack=0,received=0,rejected=0,held={},captured=false,last_seen=0}
    local function cancel()
        self.held={};self.captured=false
        options.cancel()
    end
    function self:reset(reason)
        if options.trace then options.trace('receiver reset reason='..tostring(reason)..' ack='..self.ack) end
        local active=self.token~=nil
        self.recover_key=(reason=='heartbeat' or reason=='stall' or reason=='output-stall') and self.key or nil
        if options.can_recover and not options.can_recover() then self.recover_key=nil end
        self.recovering=false
        if reason then self.last_reason=reason end
        self.token,self.key=nil,nil;self.ack=0;self.last_seen=0;self.last_beat=nil
        if active then cancel() end
    end
    function self:context(key,enabled)
        if not enabled then self:reset('context-disabled');return end
        if self.key~=key then
            local active=self.token~=nil
            local recovering=self.recover_key==key
            if recovering then self:reset() else self:reset('context-change') end
            -- Initial activation also releases keys owned by the legacy route.
            if not active then cancel() end
            self.epoch=self.epoch+1;self.key=key
            self.token=options.session..'-buttons-'..self.epoch
            self.recovering=recovering
        end
    end
    function self:watchdog()
        if self.captured and options.clock()-self.last_seen>.35 then
            self:reset('heartbeat');return true
        end
        return false
    end
    function self:accept(contents)
        if not self.token or type(contents)~='string' or #contents>8192 then return false end
        contents=contents:gsub('\r\n','\n')
        local token,stamp,beat,body=contents:match('^token=([%w%-]+)\nstamp=(%d+)\nbeat=(%d+)\n(.*)$')
        if token~=self.token or body:sub(-4)~='END\n' then return false end
        local age=options.wallclock()-tonumber(stamp)
        if age< -1 or age>1 then self.rejected=self.rejected+1;return false end
        local events,next_seq,last_cancel={},self.ack+1,0
        for line in body:sub(1,-5):gmatch('[^\n]+') do
            local seq,kind,button=line:match('^(%d+),(%a+),(%d+)$')
            seq,button=tonumber(seq),tonumber(button)
            if not seq or not button or not ((kind=='down' or kind=='up') and button>=1 and button<=(options.physical and 14 or 12) or
                (kind=='cancel' or kind=='stall') and button==0 or kind=='rmenu' and (button==6 or button==8) and type(options.menu)=='function'
                    or kind=='resume' and button>=11 and button<=14 and self.recovering and type(options.resume)=='function'
                    or kind=='banks' and button==0 and type(options.ready)=='function'
                    or kind=='keyack' and button>=0 and button<=2147483647 and type(options.key_ack)=='function') then self.rejected=self.rejected+1;return false end
            if seq>self.ack then
                if seq~=next_seq then self.rejected=self.rejected+1;return false end
                events[#events+1]={seq,kind,button};next_seq=next_seq+1
                if kind=='cancel' or kind=='stall' then last_cancel=#events end
            end
        end
        beat=tonumber(beat)
        if self.last_beat and beat<self.last_beat then return false end
        if beat~=self.last_beat then self.last_seen=options.clock();self.last_beat=beat end
        for index,event in ipairs(events) do
            if options.trace then options.trace('receiver seq='..event[1]..' kind='..event[2]..' button='..event[3]..' writer_beat='..beat..' execute='..tostring(index>=last_cancel)) end
            self.ack=event[1];self.received=self.received+1
            -- Cancellation invalidates queued actions too. Never briefly execute
            -- earlier downs from the same snapshot before seeing its cancel.
            if index>=last_cancel then
                local kind,button=event[2],event[3]
                if kind=='cancel' then cancel()
                elseif kind=='stall' then self:reset('output-stall')
                elseif kind=='rmenu' then options.menu(button)
                elseif kind=='banks' then options.ready()
                elseif kind=='keyack' then options.key_ack(button)
                elseif kind=='resume' and not self.held[button] then
                    if not self.captured then self.captured=true;options.capture(true) end
                    self.held[button]=true;options.resume(button)
                elseif kind=='down' and not self.held[button] then
                    if not self.captured then self.captured=true;options.capture(true) end
                    self.held[button]=true
                    if options.physical then options.physical(button,true) else options.event(M.diks[button],true) end
                elseif kind=='up' and self.held[button] then
                    self.held[button]=nil
                    if options.physical then options.physical(button,false) else options.event(M.diks[button],false) end
                    if not next(self.held) then self.captured=false;options.capture(false) end
                end
            end
            -- An executed command can unload or change the route mid-batch.
            if self.token~=token then break end
        end
        return #events>0
    end
    return self
end
return M
