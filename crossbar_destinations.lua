-- A: labels are presentation; saved switch actions use the actual environment
-- key, including fallback sets and custom sets with renamed display labels.
local M = {}
function M.xi_label(key, name, main_job, sub_job)
    if key == 'all-jobs-default' then return 'ALL' end
    if key == 'basic' then return 'Main' end
    if not main_job or main_job == '' then return name end
    if key == 'job-default' then return main_job end
    if key == 'default' then
        if not sub_job or sub_job == '' or sub_job == 'NON' or sub_job == 'NOSUB' then return main_job end
        return main_job .. '/' .. sub_job
    end
    return name
end

-- options.hide_shared / hide_basic: leave Shared or Basic out (UseSharedSet /
-- UseBasicSet off).
function M.build(hotbar, label, options)
    local entries = {}
    local hide_shared = options and options.hide_shared
    local hide_basic = options and options.hide_basic
    for key, bar in pairs(hotbar or {}) do
        if type(bar) == 'table' and not (hide_shared and key == 'shared')
            and not (hide_basic and key == 'basic') then
            local name = bar.name or key
            entries[#entries+1] = {key=key, name=label and label(key, name) or name}
        end
    end
    -- A: ALL first, then JOB, then JOB/SUB, then the player's own sets.
    local rank={['all-jobs-default']=1,['job-default']=2,default=3}
    table.sort(entries,function(a,b)
        local ar,br=rank[a.key] or 4,rank[b.key] or 4
        if ar~=br then return ar<br end
        local an,bn=a.name:lower(),b.name:lower()
        if an~=bn then return an<bn end
        return a.key<b.key
    end)
    return entries
end
return M
