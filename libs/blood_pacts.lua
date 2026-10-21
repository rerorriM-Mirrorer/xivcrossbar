-- A: chooser availability comes from the client's ability list, which already
-- accounts for its current job/unlocks. Do not invent a second level database.
local M={}
function M.available(resources,available,category)
    local seen,out={},{}
    for _,group in ipairs({'job_abilities','pet_commands'}) do
        for _,id in pairs((available or {})[group] or {}) do
            if type(id)=='number' and not seen[id] then
                seen[id]=true
                local ability=resources[id]
                if ability and ability.type==category then out[#out+1]=ability end
            end
        end
    end
    table.sort(out,function(a,b)return (a.name or a.en)<(b.name or b.en) end)
    return out
end
function M.icon(ability,metadata,pathbase,exists)
    local ward=ability.type=='BloodPactWard'
    local category=ward and 'ward' or 'rage'
    local candidates={}
    local function add(path,custom) if path then candidates[#candidates+1]={path,custom} end end
    if metadata and metadata.custom_icon then add('images/'..pathbase..'/'..metadata.custom_icon,true) end
    -- Specific overrides win; a pack may supply a generic pact icon explicitly.
    add('images/'..pathbase..'/blood-pacts/'..category..'/bloodpact.png',true)
    add('images/'..pathbase..'/blood-pacts/bloodpact.png',true)
    add('images/'..pathbase..'/bloodpact.png',true)
    add('images/'..pathbase..'/blood-pacts/'..category..'.png',true)
    if metadata then add(metadata.default_icon,false) end
    local shipped='images/icons/default/fallback/abilities/'..(ward and '00174' or '00173')..'.png'
    add(shipped,false)
    for _,candidate in ipairs(candidates) do if exists(candidate[1]) then return candidate[1],candidate[2] end end
    return shipped,false
end
return M
