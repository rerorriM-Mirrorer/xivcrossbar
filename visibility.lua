-- A: hiding is presentation only; action execution never consults this.
local M = {}
-- A cutscene preference only affects Show. Auto must never be downgraded
-- by FFXI's Event status (which is also used for death and NPC interaction).
-- Windower has no reliable cutscene-only flag: conservatively classify only
-- living Event status with no open chat or native menu. Any ambiguous state
-- remains visible, and this condition never gates input or client switching.
function M.cutscene_hidden(mode, enabled, in_event, hp, info)
    return mode == 'always' and enabled == true and in_event == true
        and tonumber(hp) ~= nil and tonumber(hp) > 0
        and not (info and (info.chat_open or info.menu_open))
end
-- Preserve the old helper for clients/tests; events no longer alter the
-- visibility mode itself.
function M.event_mode(mode)
    return mode
end

function M.update_hold(state, held, seconds, now, enabled)
    if not enabled or seconds <= 0 or held then
        state.deadline = nil
    elseif state.held then
        state.deadline = now + seconds
    end
    state.held = enabled and held
    if state.deadline and now < state.deadline then return true end
    state.deadline = nil
    return false
end

function M.should_show(mode, trigger_held, cutscene, startup_reveal)
    if mode == 'hidden' then return false end
    if mode == 'oninput' then
        return trigger_held == true or startup_reveal == true
    end
    if cutscene then return false end
    return true
end
return M
