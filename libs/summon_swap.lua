-- A: wait for observed Release completion before casting a different summon.
-- One request per player; stale callbacks cannot revive cancelled requests.
local M={}
function M.new(options)
    local self={}
    function self:cancel(reason)
        if not self.pending then return end
        self.pending=nil
        if reason then options.notice(reason) end
    end
    function self:request(action,state)
        if self.pending and self.pending.action.action==action.action then return end
        self:cancel()
        local p={action={},pet_name=state.pet_name,pet_id=state.pet_id,context=options.context(),deadline=options.clock()+5}
        for k,v in pairs(action) do p.action[k]=v end
        self.pending=p
        options.send('input /pet "Release" <me>')
        local function poll()
            if self.pending~=p then return end
            if options.context()~=p.context then self:cancel('Summon switch cancelled: player, zone or job changed.');return end
            if options.clock()>=p.deadline then
                self:cancel('Summon switch stopped: Release did not complete in time.');return
            end
            local current=options.snapshot()
            if current.player and (current.player.status==2 or current.player.status==3) then
                self:cancel('Summon switch cancelled: player is defeated.');return
            end
            if current.pet then
                if current.pet_name~=p.pet_name or current.pet_id~=p.pet_id then
                    self:cancel('Summon switch cancelled: another pet appeared.');return
                end
                options.schedule(poll,.1);return
            end
            self.pending=nil
            options.cast(p.action)
        end
        options.schedule(poll,.1)
        return true
    end
    return self
end
return M
