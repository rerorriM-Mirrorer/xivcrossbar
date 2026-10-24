-- On-demand snapshots keep transport internals available without filling chat.
-- Assemble completely before asking the shared replacement helper to save.
local M={}
function M.render(snapshot)
    local lines={'XIVcrossbar diagnostic snapshot'}
    local seen={}
    local function visit(value,path,depth)
        if type(value)~='table' then lines[#lines+1]=path..' = '..tostring(value);return end
        if seen[value] or depth>8 then lines[#lines+1]=path..' = [reference]';return end
        seen[value]=true
        local keys={};for key in pairs(value) do keys[#keys+1]=key end
        table.sort(keys,function(a,b)return tostring(a)<tostring(b) end)
        for _,key in ipairs(keys) do visit(value[key],path=='' and tostring(key) or path..'.'..tostring(key),depth+1) end
    end
    visit(snapshot,'',0)
    return table.concat(lines,'\n')..'\n'
end
function M.save(path,snapshot,replace)
    local ok,body=pcall(M.render,snapshot)
    if not ok then return false,body end
    local called,saved,err=pcall(function()
        return (replace or require('libs/windows_file').new().replace)(path,body)
    end)
    if not called then return false,saved end
    return saved,err
end
return M
