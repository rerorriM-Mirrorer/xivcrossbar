-- Resolve display names without guessing when two sets share a label.
local M={}
function M.key(name)return tostring(name or ''):lower():gsub("'",''):gsub('%s+','-')end
function M.resolve(hotbar,name)
    local normalized=M.key(name)
    if hotbar[normalized] then return normalized end
    local found={}
    for key,bar in pairs(hotbar)do
        if type(bar)=='table' and M.key(require('ui/set_labels').display(key,bar.name))==normalized then found[#found+1]=key end
    end
    table.sort(found)
    if #found==1 then return found[1] end
    if #found>1 then return nil,'More than one set has that label. Use its saved key: '..table.concat(found,', ')..'.' end
    local category=require('libs/job_crossbars').category_key(name)
    if category and hotbar[category] then return category end
    return nil,'No crossbar set named "'..tostring(name)..'" found in the current job.'
end
return M
