-- A: profile changes advance on observed wrapper status, never a blocking sleep.
local profiles = require('controller_profiles')
local M = {}
function M.new(options)
    local self = {options=options}
    function self:finish(ok, detail)
        local pending = self.pending
        self.pending = nil
        if pending and pending.done then pending.done(ok, detail) end
    end
    function self:cancel(reason)
        self:finish(false, reason or 'Controller change cancelled.')
    end
    function self:request(profile, device, modifier, done)
        local name, number = profiles.validate(profile, device)
        if not name or (modifier ~= 'apps' and modifier ~= 'ctrl') then
            if done then done(false, 'Invalid controller selection.') end
            return false
        end
        local previous = self.pending
        local shutdown_pending = previous and (previous.phase == 'stopping' or previous.phase == 'exit-buffer')
            or (self.options.stop_pending and self.options.stop_pending())
        self:cancel('Replaced by another controller selection.')
        local now = self.options.clock()
        local status = self.options.status()
        self.pending = {profile=name, device=number, modifier=modifier, done=done,
            deadline=now+12, next_check=now, original_pid=status and status.pid}
        if profiles.matches(status, name, number, modifier) and not shutdown_pending then
            if status.state == 'starting' then
                self.pending.phase, self.pending.retry_after = 'verifying', now+1
            else self:finish(true, status) end
        elseif (status and status.running) or shutdown_pending then
            self.pending.phase = 'stopping'
            if self.options.stop() == false then self:finish(false, 'Could not stop the shared wrapper.') end
        else
            self.pending.phase = 'starting'
        end
        return true
    end
    function self:step()
        local pending = self.pending
        if not pending then return end
        local now = self.options.clock()
        if now < pending.next_check then return end
        pending.next_check = now + .1
        local status = self.options.status()
        if profiles.matches(status, pending.profile, pending.device, pending.modifier) and status.state ~= 'starting'
            and ((pending.phase ~= 'stopping' and pending.phase ~= 'exit-buffer')
                or (status.pid ~= pending.original_pid and not (self.options.stop_pending and self.options.stop_pending()))) then
            self:finish(true, status)
            return
        end
        if now >= pending.deadline then
            self:finish(false, 'Controller switch timed out. Check //xb controller status.')
            return
        end
        if pending.phase == 'stopping' then
            -- A different PID is another client's launch; do not keep stopping it.
            if status and status.running and status.pid ~= pending.original_pid then
                self:finish(false, 'Another client started a different controller profile. Check status.')
            elseif status and status.fresh and status.state == 'stopped' then
                -- Exit status is written just before ExitApp. Leave a short exit buffer.
                pending.phase, pending.exit_after = 'exit-buffer', now+.25
            end
        elseif pending.phase == 'exit-buffer' then
            if now >= pending.exit_after then pending.phase = 'starting' end
        elseif pending.phase == 'starting' then
            if self.options.start(pending.profile, pending.device, pending.modifier) == false then
                self:finish(false, 'Could not start the selected reader. Check status and retry.')
            else
                pending.phase, pending.retry_after = 'verifying', now+1
            end
        elseif pending.phase == 'verifying' then
            if status and status.running and status.pid ~= pending.original_pid
                and not profiles.matches(status, pending.profile, pending.device, pending.modifier) then
                self:finish(false, 'A different reader started. Check //xb controller status.')
            elseif now >= pending.retry_after and status and status.fresh and status.state == 'stopped' then
                -- SingleInstance may briefly reject a launch while the old process exits.
                pending.phase = 'starting'
            end
        end
    end
    return self
end
return M
