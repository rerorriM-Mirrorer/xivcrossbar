-- A: receipt feedback, not confirmation that the game executed an action.
-- A short minimum pulse keeps taps visible even between two rendered frames.
local M={}
local function held_alpha(p,now)
    return 72+108*math.max(0,math.min(1,1-(now-p.started-.06)/.08))
end
function M.new(clock)
    local self={presses={}}
    function self:press(button,layer,slot)
        self.presses[button]={layer=layer,slot=slot,started=clock()}
    end
    function self:release(button)
        local p=self.presses[button]
        if p then p.released=clock();p.release_alpha=held_alpha(p,p.released) end
    end
    function self:cancel() self.presses={} end
    function self:alpha(layer,slot)
        local now=clock()
        for button,p in pairs(self.presses) do
            if p.layer==layer and p.slot==slot then
                local pulse_end=p.started+.06
                if now<pulse_end then return 180 end
                if not p.released then
                    return math.floor(held_alpha(p,now)+.5)
                end
                local remaining=1-(now-math.max(p.released,pulse_end))/.14
                if remaining<=0 then self.presses[button]=nil;return 0 end
                return math.floor(p.release_alpha*remaining+.5)
            end
        end
        return 0
    end
    return self
end
return M
