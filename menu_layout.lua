-- A: menu coordinates are independent of crossbar Style offsets.
local M = {}
function M.fit(screen_width, screen_height)
    local width = math.max(1, math.min(1100, screen_width - 32))
    local height = math.max(1, math.min(700, screen_height - 32))
    return (screen_width - width) / 2, (screen_height - height) / 2, width, height
end
return M
