-- A: an Attack slot pressed with nothing targeted only targets (/targetnpc);
-- the next press attacks. Applies to every Attack slot whose target is the
-- current or battle target (<t>, <bt>, or none). Selector targets (<st*>) and
-- disengaging (/attack off, or Attack while engaged) are unchanged.
local M={}
local function key(s) return tostring(s or ''):lower():gsub('[^%w]','') end
local attack_names={a=true,attack=true,on=true}
function M.is_attack(action)
    return action ~= nil and action.type == 'a' and attack_names[key(action.action)] == true
end
-- Returns the command to send instead of attacking, or nil to attack normally.
function M.redirect(action, ffxi)
    if not M.is_attack(action) then return end
    local target = action.target
    if target ~= nil and target ~= 't' and target ~= 'bt' then return end
    ffxi = ffxi or {}
    local player = ffxi.get_player and ffxi.get_player()
    if player and (player.status == 1 or player.status == 3) then return end -- engaged: Attack disengages
    local current = ffxi.get_mob_by_target and ffxi.get_mob_by_target('t')
    if current then return end
    return 'input /targetnpc'
end
return M
