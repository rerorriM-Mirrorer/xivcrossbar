-- A: catalog identity is independent of the slot label. Snapshot fields let
-- catalog edits update owned values while retaining intentional slot overrides.
local M={}
local fields={'action','alias','icon','linked_action','linked_type'}
local function value(v) return v or '' end
function M.values(record)
    local alias=record.alias and record.alias~='' and record.alias or record.name
    return {action=record.command and record.command~='' and record.command or alias,
        alias=alias,icon=record.icon,linked_action=record.linked_action,linked_type=record.linked_type}
end
function M.find(records,id)
    for _,record in pairs(records or {}) do if record.id==id then return record end end
end
function M.attach(slot,record,scope)
    slot.catalog_scope,slot.catalog_id,slot.catalog_name=scope,record.id,record.name
    local values=M.values(record)
    for _,field in ipairs(fields) do slot['catalog_last_'..field]=value(values[field]) end
end
function M.apply(slot,record)
    local changed=false
    local values=M.values(record)
    for _,field in ipairs(fields) do
        local last='catalog_last_'..field
        if value(slot[field])==value(slot[last]) and value(slot[field])~=value(values[field]) then
            slot[field]=values[field];changed=true
        end
        slot[last]=value(values[field])
    end
    slot.catalog_name=record.name
    return changed
end
function M.legacy_match(slot,sources)
    if slot.type~='ex' then return nil end
    local found,scope
    for source,records in pairs(sources or {}) do
        for _,record in pairs(records) do
            if record.deleted~='true' then
                local values=M.values(record);local matches=true
                for _,field in ipairs(fields) do if value(slot[field])~=value(values[field]) then matches=false end end
                if matches then
                    if found then return nil end -- ambiguous copies remain independent
                    found,scope=record,source
                end
            end
        end
    end
    return found,scope
end
return M
