-- Block the native keyboard while an addon text field or modal menu owns it.
-- Lua keeps handling field keys; no user keybindings are replaced.
local guard = {active=false}
function guard:update(wants_input, send, navigation)
    if navigation ~= nil then self.navigation = navigation end
    -- Navigation remains blocked while the router owns a held key.
    wants_input = wants_input == true or self.navigation == true
    if self.active == wants_input then return end
    self.active = wants_input
    send('keyboard_blockinput ' .. (wants_input and '1' or '0'))
end
function guard:release(send) self:update(false,send) end
return guard
