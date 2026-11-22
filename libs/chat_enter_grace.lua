-- A (2026-11-21): Enter while FFXI chat is open belongs to chat, even with an
-- XIV Crossbar menu open. A (2026-11-22): Esc too (it closes chat), and the
-- grace is a little longer after live bleed-through. After that Enter, a short grace swallows further
-- Enter presses (a held key's repeats or an accidental double press), so
-- they neither confirm a menu row nor reopen chat in the game. Each swallowed
-- press extends the grace, so holding Enter never leaks into the menu.
-- Tunable: grace (seconds, default .45).
local M = {grace = .45}

function M.new(clock)
    local self = {until_at = 0}
    -- Returns 'pass' (let the game have it), 'swallow' (block it everywhere)
    -- or nil (normal handling).
    function self:edge(is_enter, pressed, menu_open, chat_open)
        if not is_enter or not menu_open then return nil end
        local now = clock()
        if chat_open then
            if pressed then self.until_at = now + M.grace end
            return 'pass'
        end
        if now < self.until_at then
            if pressed then
                self.until_at = now + M.grace
                return 'swallow'
            end
            return 'pass' -- key-up of the Enter that sent the chat line
        end
        return nil
    end
    return self
end

return M
