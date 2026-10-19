-- A: acknowledged Lua -> AHK key edges. Retain complete quick taps between
-- render frames. A new generation cancels old output without replaying it.
local M={}
function M.new(options)
    local self={epoch=0,seq=0,ack=0,pending={},held={}}
    function self:cancel()
        self.epoch=self.epoch+1;self.ack=self.seq;self.pending={};self.held={}
    end
    function self:edge(key,pressed)
        local _,_,canonical=require('libs/banks/keys').parse(key)
        if not canonical or (not not self.held[canonical])==pressed then return end
        self.held[canonical]=pressed or nil
        self.seq=self.seq+1
        self.pending[#self.pending+1]={seq=self.seq,kind=pressed and 'd' or 'u',key=canonical,time=options.clock()}
    end
    function self:pulse(key) self:edge(key,true);self:edge(key,false) end
    function self:release()
        local keys={};for key in pairs(self.held) do keys[#keys+1]=key end
        table.sort(keys);for _,key in ipairs(keys) do self:edge(key,false) end
    end
    function self:accept(ack)
        if ack<self.ack or ack>self.seq then return false end
        self.ack=ack
        local retained={};for _,e in ipairs(self.pending) do if e.seq>ack then retained[#retained+1]=e end end
        self.pending=retained;return true
    end
    function self:stale()
        return #self.pending>64 or self.pending[1] and options.clock()-self.pending[1].time>.35
    end
    function self:payload(token)
        if not token then return nil,'',self.ack end
        local parts={}
        for _,e in ipairs(self.pending) do parts[#parts+1]=e.seq..','..e.kind..','..e.key end
        return token..'-native-'..self.epoch,table.concat(parts,'|'),self.ack
    end
    return self
end
return M
