-- A: menu rows and bound slots share one ID-based item cache. A fresh
-- directory leaves older, potentially corrupted images untouched and unused.
local extractor = require('ui/icon_extractor')
local M = {}
local directory = 'images/extracted_items_v5'

function M.is_extracted(path)
    return type(path) == 'string' and path:match('^/?images/extracted_[^/]+/.*%.bmp$') ~= nil
end

function M.resolve(id)
    if type(id) ~= 'number' or id ~= math.floor(id) then return nil end
    local relative = directory .. '/' .. id .. '.bmp'
    local absolute = windower.addon_path .. relative
    if not windower.file_exists(absolute) then
        local folder = windower.addon_path .. directory
        if not windower.dir_exists(folder) then windower.create_dir(folder) end
        if not extractor.safe_item_by_id(id, absolute) then return nil end
    end
    if windower.file_exists(absolute) then return relative end
end

return M
