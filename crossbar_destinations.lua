-- A: labels are presentation; saved switch actions use the actual environment
-- key, including fallback sets and custom sets with renamed display labels.
local M = {}
function M.build(hotbar)
    local entries = {}
    for key, bar in pairs(hotbar or {}) do
        if type(bar) == 'table' then entries[#entries+1]={key=key,name=bar.name or key} end
    end
    local rank={default=1,['job-default']=2,['all-jobs-default']=3}
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
