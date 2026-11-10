-- A: hiding is presentation only; action execution never consults this.
local M = {}
function M.event_mode(mode, in_event, event_bars)
    if in_event and event_bars and mode == 'always' then return 'oninput' end
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
        return trigger_held == true or (startup_reveal == true and not cutscene)
    end
    if cutscene then return false end
    return true
end
return M
