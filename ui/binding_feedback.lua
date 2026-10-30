-- Human-readable locations use the same slot order as the XML serializer.
local feedback = {}
local bars = {'L2', 'R2', 'R2 > L2', 'L2 > R2', 'L2 twice', 'R2 twice'}
local buttons = {'Left', 'Down', 'Right', 'Up', 'Square', 'Cross', 'Circle', 'Triangle'}
function feedback.set_name(hotbars, key)
    local set=hotbars and hotbars[key]
    local name=set and set.name
    return type(name)=='string' and name:find('%S') and name or tostring(key)
end
function feedback.location(bar, slot)
    return (bars[tonumber(bar)] or ('Bar ' .. tostring(bar))) .. ' + ' ..
        (buttons[tonumber(slot)] or ('Slot ' .. tostring(slot)))
end
function feedback.bound(label, set, bar, slot)
    return require('libs/chat_status').notice('Bound "' .. tostring(label) .. '" to ' .. feedback.location(bar, slot) .. ' - ' .. tostring(set) .. ' Crossbar.')
end
function feedback.cleared(set, bar, slot)
    return require('libs/chat_status').notice('Cleared ' .. feedback.location(bar, slot) .. ' - ' .. tostring(set) .. ' Crossbar.')
end
return feedback
