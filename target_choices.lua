-- A: prefer the current target without offering targets unsupported by an action.
local M = {}
function M.build(targets, allow_self_stpc, icon)
    targets = targets or {}
    local choices = {}
    local function add(id, name) choices[#choices+1]={id=id,name=name,icon=icon} end
    local other = targets.Party or targets.Ally or targets.Player or targets.NPC or targets.Enemy or targets.Corpse
    if other then add('CURRENT_TARGET','Current Target (<t>)') end
    if targets.Self then add('SELF','Self (<me>)') end
    if targets.Party or targets.Corpse then add('SELECT_PARTY','Select Party (<stpt>)') end
    if targets.Ally or targets.Corpse then add('SELECT_ALLIANCE','Select Ally (<stal>)') end
    if targets.Player or targets.Corpse then add('SELECT_PLAYER','Select Player (<stpc>)') end
    if targets.NPC or targets.Enemy then add('SELECT_NPC','Select NPC (<stnpc>)') end
    if targets.Enemy then
        add('SELECT_TARGET','Select Target (<st>)')
        add('BATTLE_TARGET','Battle Target (<bt>)')
    end
    if targets.Self and not other and allow_self_stpc then add('SELECT_PLAYER','Select Player (<stpc>)') end
    return choices
end
return M
