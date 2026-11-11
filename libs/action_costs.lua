-- Generated legacy ability metadata sets MP to zero. Resolve pact MP from the
-- installed Windower resources so existing caches work without regeneration.
local M={}
function M.mp(action,abilities)
    local ability=action and action.res_key=='job_abilities' and abilities and abilities[action.id]
    if ability and (ability.type=='BloodPactRage' or ability.type=='BloodPactWard') then
        return tonumber(ability.mp_cost) or 0
    end
    return tonumber(action and action.mp_cost) or 0
end
return M
