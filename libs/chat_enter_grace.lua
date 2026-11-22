-- A (2026-11-21): Enter while FFXI chat is open belongs to chat, even with an
-- XIV Crossbar menu open. A (2026-11-22): Esc too (it closes chat), and the
-- grace is a little longer after live bleed-through. After that Enter, a short grace swallows further
-- Enter presses (a held key's repeats or an accidental double press), so
-- they neither confirm a menu row nor reopen chat in the game. Each swallowed
-- press extends the grace, so holding Enter never leaks into the menu.
-- A (2026-11-22, Test4 log): after a client refocus some Enter presses reached
-- the addon only after FFXI had already closed chat, so chat read "closed",
-- no grace was running, and the press confirmed a menu row. The prerender
-- now reports chat each frame (observe); a press within `recent` of chat
-- last being seen open still counts as a chat key.
-- Tunables: grace (seconds, default .45); recent (seconds, default .25).
local M = {grace = .45, recent = .25}

function M.new(clock)
    local self = {until_at = 0, seen_at = -1e9}
    -- Called once per frame with FFXI's chat state.
    function self:observe(chat_open)
        if chat_open then self.seen_at = clock() end
    end
    -- True when chat was open within the last `recent` seconds.
    function self:recently_open()
        return clock() - self.seen_at < M.recent
    end
    -- Returns 'pass' (let the game have it), 'swallow' (block it everywhere)
    -- or nil (normal handling).
    function self:edge(is_enter, pressed, menu_open, chat_open)
        if not is_enter or not menu_open then return nil end
        local now = clock()
        -- A late press (chat already closed, no grace yet) still belongs to chat.
        if not chat_open and pressed and now >= self.until_at and self:recently_open() then
            chat_open = true
        end
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
