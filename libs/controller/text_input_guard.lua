-- A: block native game input only while an addon text field owns typing.
-- Lua keeps handling field keys; no user keybindings are replaced.
local guard = {active=false}
-- Keep ownership through key-up even when committing closes the field.
-- Suppress typematic repeats so one held Enter cannot submit another screen.
function guard:enter_edge(pressed, capturing)
    if self.enter_down then
        if not pressed then self.enter_down = false end
        return true, false
    end
    if pressed and capturing then
        self.enter_down = true
        return true, true
    end
    return false, false
end
function guard:reset_confirmation() self.enter_down = false end
function guard:update(wants_input, send)
    -- Closing the field during Enter down must not unblock that same native
    -- input. Retain the block through release; prerender restores it afterward.
    wants_input = wants_input == true or self.enter_down == true
    if self.active == wants_input then return end
    self.active = wants_input
    send('keyboard_blockinput ' .. (wants_input and '1' or '0'))
end
function guard:release(send) self:update(false,send) end
return guard
