-- Visual availability only: keep bindings and dispatch unchanged. The game's
-- current lists handle skill caps, unlocks and equipped-weapon WS rules.
local M={}
local function index(values)
    if type(values)~='table' then return nil end
    local result={}
    for _,id in pairs(values) do if type(id)=='number' then result[id]=true end end
    return result
end
function M.snapshot(ffxi)
    if not ffxi.get_abilities then return {} end
    local abilities=ffxi.get_abilities()
    if type(abilities)~='table' then return {} end
    return {job_abilities=index(abilities.job_abilities),weapon_skills=index(abilities.weapon_skills)}
end
function M.unavailable(action,state,abilities)
    if not action or action.trust_dismiss then return false end
    local kind=action.linked_type or action.type
    if kind~='ja' and kind~='pet' and kind~='ws' then return false end
    local name=action.linked_action or action.action
    local metadata=abilities[require('libs/kebab_casify')(name or '')]
    if not metadata or not metadata.id then return false end
    local group=kind=='ws' and 'weapon_skills' or 'job_abilities'
    -- Pet commands such as Assault/Release are not learned job abilities.
    if metadata.res_key~=group then return false end
    return state[group]~=nil and not state[group][metadata.id]
end
return M
