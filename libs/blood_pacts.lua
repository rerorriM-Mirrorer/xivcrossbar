-- Binding lists follow SMN level and learned summon spells, independently of
-- the temporary native pet-command list. Execution guards stay separate.
local M={}
function M.available(resources,player,spells,known,category)
    player=player or {}
    local level=math.max(player.main_job_id==15 and (player.main_job_level or 0) or 0,
        player.sub_job_id==15 and (player.sub_job_level or 0) or 0)
    local summons,out={},{}
    for id,spell in pairs(spells or {}) do
        if spell.type=='SummonerPact' and (known or {})[id]==true
                and spell.levels and spell.levels[15] and spell.levels[15]<=level then
            summons[spell.en or spell.name]=true
        end
    end
    for id,entry in pairs(require('libs/blood_pact_levels')) do
        local ability=resources[id]
        if ability and ability.type==category and level>=entry.level and summons[entry.summon] then
            out[#out+1]=ability
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
