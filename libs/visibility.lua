-- A: hiding is presentation only; action execution never consults this.
local M = {}
function M.should_show(mode, trigger_held, cutscene, startup_reveal)
    if mode == 'hidden' then return false end
    if mode == 'oninput' then
        return trigger_held == true or (startup_reveal == true and not cutscene)
    end
    if cutscene then return false end
    return true
end
return M
