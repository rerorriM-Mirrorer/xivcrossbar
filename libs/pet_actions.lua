-- A: one availability policy for drawing and dispatch. It only governs typed
-- pet/JA bindings; arbitrary macros and linked display metadata stay untouched.
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
        engaged=player and (player.status==1 or player.status==3),player=player}
end
function M.is_release(action)
    return action and (action.type=='pet' or action.type=='ja') and key(action.action)=='release'
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
