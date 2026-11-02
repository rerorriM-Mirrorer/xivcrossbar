-- A: shared pet availability and typed-action toggles for drawing/dispatch.
-- Arbitrary macro text stays untouched; saved bindings are never rewritten.
local M={}
local function key(value) return tostring(value or ''):lower():gsub('[^%w]','') end
local avatars={}
for _,name in ipairs({'Carbuncle','Ifrit','Titan','Leviathan','Garuda','Shiva','Ramuh',
    'Fenrir','Diabolos','Cait Sith','Siren','Odin','Alexander','Atomos'}) do avatars[key(name)]=true end
local spirits={}
for _,element in ipairs({'Fire','Ice','Air','Earth','Thunder','Water','Light','Dark'}) do spirits[key(element..' Spirit')]=true end
function M.snapshot(ffxi)
    ffxi=ffxi or {}
    local pet=ffxi.get_mob_by_target and ffxi.get_mob_by_target('pet')
    local alive=pet~=nil and (pet.hpp==nil or pet.hpp>0)
    local name=alive and key(pet.name) or ''
    local player=ffxi.get_player and ffxi.get_player()
    return {pet=alive,avatar=alive and avatars[name]==true,summon=alive and (avatars[name]==true or spirits[name]==true),
        trust=require('libs/trust_actions').snapshot(ffxi),pet_name=name,pet_engaged=alive and pet.status==1,engaged=player and (player.status==1 or player.status==3),player=player}
end
-- Resolve transient display/dispatch values without changing the saved slot.
-- Either standard SMN command can be used as the same stateful pet toggle.
function M.pet_toggle(action,state)
    if not action or action.type~='pet' then return end
    local name=key(action.action)
    if name~='assault' and name~='retreat' then return end
    local resolved={};for field,value in pairs(action) do resolved[field]=value end
    resolved.icon=action.icon or ''
    resolved.action=state.pet_engaged and 'Retreat' or 'Assault'
    local label=key(action.alias)
    if not action.alias or label=='assault' or label=='retreat' then resolved.alias=resolved.action end
    if state.pet_engaged then resolved.target='me'
    elseif name=='retreat' or action.target=='me' or not action.target then resolved.target='t' end
    return resolved
end
-- Only the matching summon slot becomes Release. Other summons remain spells,
-- so switching pets stays an explicit choice and saved artwork stays intact.
function M.summon_toggle(action,state)
    if not action or action.type~='ma' or not state.summon then return end
    local name=key(action.action)
    if (not avatars[name] and not spirits[name]) or name~=state.pet_name then return end
    local resolved={};for field,value in pairs(action) do resolved[field]=value end
    resolved.type,resolved.action,resolved.alias,resolved.target='pet','Release','Release','me'
    resolved.icon,resolved.linked_type,resolved.linked_action='',nil,nil
    return resolved
end
function M.resolve(action,state,spells)
    return M.summon_toggle(action,state) or M.pet_toggle(action,state)
        or require('libs/trust_actions').resolve(action,state.trust or {},spells)
end
function M.is_release(action)
    return action and (action.trust_dismiss or ((action.type=='pet' or action.type=='ja') and key(action.action)=='release'))
end
function M.requirement(action,abilities)
    if not action or (action.type~='pet' and action.type~='ja') then return end
    local name=key(action.action)
    local metadata=abilities and abilities[require('libs/kebab_casify')(action.action or '')]
    local category=metadata and metadata.category or ''
    if category:match('^blood%-pacts') or name=='bloodpactrage' or name=='bloodpactward' or name=='avatarsfavor' then return 'avatar' end
    if name=='release' or name=='assault' or name=='retreat' then return 'summon' end
    if action.type=='pet' or metadata and (metadata.type=='pet' or category=='ready') then return 'pet' end
end
function M.unavailable(action,state,abilities)
    local needs=M.requirement(action,abilities)
    if needs and not state[needs] then
        return needs=='avatar' and 'No avatar summoned.' or needs=='summon' and 'No avatar or spirit summoned.' or 'No pet summoned.'
    end
end
function M.combat_commands(action,state)
    if not state.summon or not action or action.type~='a' then return end
    local name=key(action.action)
    if name~='a' and name~='attack' and name~='on' and name~='off' then return end
    local disengage=name=='off' or (name~='on' and state.engaged)
    if disengage then return {'input /pet "Retreat" <me>','input /attack off'} end
    local target=action.target or 't'
    -- Preserve selector-style attacks: do not send Assault before a user has
    -- confirmed <st*>. Concrete current/battle/numeric targets can pair now.
    if target~='t' and target~='bt' and not tostring(target):match('^%d+$') then return end
    return {'input /pet "Assault" <'..target..'>','input /attack on <'..target..'>'}
end
return M
