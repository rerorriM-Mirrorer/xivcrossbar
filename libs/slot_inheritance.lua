-- Saved XML can contain metadata-only slot tables. They are empty slots, not
-- bindings: skip them when choosing a default so display and dispatch agree.
local M={}
function M.fallback(hotbar, environment, bar, slot)
    if environment == 'shared' then return nil end
    local layers={}
    if environment ~= 'default' and environment ~= 'job-default' and environment ~= 'all-jobs-default' then
        layers[#layers+1]='default'
    end
    if environment ~= 'job-default' and environment ~= 'all-jobs-default' then
        layers[#layers+1]='job-default'
    end
    if environment ~= 'all-jobs-default' then layers[#layers+1]='all-jobs-default' end
    for _,layer in ipairs(layers) do
        local row=hotbar[layer] and hotbar[layer]['hotbar_'..bar]
        local action=row and row['slot_'..slot]
        if action and action.action ~= nil then return action,layer end
    end
    return nil
end
return M
