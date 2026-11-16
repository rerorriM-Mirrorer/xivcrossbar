-- Optional cues for the separate GripRumble addon. XIVCrossbar appends one
-- event name per line to GripRumble/events.txt; GripRumble decides what each
-- event feels like. Every cue is off by default and silent when GripRumble is
-- not installed. `slotpress`, `setswitch` and `binding` are cue names the
-- GripRumble helper already knows; `triggerpull` is new and is ignored by a
-- helper that has no pattern for it.
local M = {}

M.order = {'slot', 'trigger', 'set', 'bind'}
M.events = {slot = 'slotpress', trigger = 'triggerpull', set = 'setswitch', bind = 'binding'}
M.keys = {slot = 'SlotPress', trigger = 'TriggerPull', set = 'SetSwitch', bind = 'Binding'}
M.labels = {
    slot = 'slot press (accepted action)',
    trigger = 'trigger pull (L2/R2, enabled L1/R1 banks)',
    set = 'set switch (active crossbar set changes)',
    bind = 'binding (a slot is bound)',
}

-- host: {path=function, exists=function(path), open=function(path, mode), focused=function}
function M.new(settings, host)
    local self = {session_slot = nil}

    -- GripRumble re-syncs `//xb slotrumble on|off` each time it loads. That is
    -- a session-only override of the saved slot-press setting, never saved.
    function self:enabled(feature)
        if feature == 'slot' and self.session_slot ~= nil then return self.session_slot end
        local group = settings.GripRumble
        return type(group) == 'table' and group[M.keys[feature]] == true
    end

    -- Slot presses reach only the controlled client. Set, bind and trigger cues
    -- also require focus so several clients never stack the same cue.
    function self:emit(feature, any_client)
        if not M.events[feature] or not self:enabled(feature) then return false end
        if not any_client and not host.focused() then return false end
        local path = host.path()
        if not host.exists(path) then return false end
        local ok, file = pcall(host.open, path, 'a')
        if not ok or not file then return false end
        file:write(M.events[feature] .. '\n')
        file:close()
        return true
    end

    function self:status(say)
        for _, feature in ipairs(M.order) do
            local override = feature == 'slot' and self.session_slot ~= nil
            say(('%s: %s%s'):format(M.labels[feature], self:enabled(feature) and 'ON' or 'OFF',
                override and ' (GripRumble override for this load)' or ''))
        end
    end

    -- //xb rumble [status] | //xb rumble <slot|trigger|set|bind|all> <on|off>
    function self:command(feature, mode, save, say)
        if feature == nil or feature == 'status' then return self:status(say) end
        feature = feature:lower()
        mode = mode and mode:lower()
        if (feature ~= 'all' and not M.events[feature]) or (mode ~= 'on' and mode ~= 'off') then
            say('//xb rumble status | //xb rumble <slot|trigger|set|bind|all> <on|off>')
            return false
        end
        if type(settings.GripRumble) ~= 'table' then settings.GripRumble = {} end
        local changed = false
        for _, name in ipairs(M.order) do
            if feature == 'all' or feature == name then
                local value = mode == 'on'
                if settings.GripRumble[M.keys[name]] ~= value then
                    settings.GripRumble[M.keys[name]] = value
                    changed = true
                end
                if name == 'slot' then self.session_slot = nil end
            end
        end
        if changed then save() end
        self:status(say)
        return true
    end

    -- The pre-existing session-only command, kept for GripRumble's sync.
    function self:session_command(mode, say)
        if mode == 'on' then self.session_slot = true
        elseif mode == 'off' then self.session_slot = false
        elseif mode ~= nil then
            say('//xb slotrumble [on|off] (this load only; use //xb rumble slot on|off to save)')
            return false
        end
        say('Slot rumble ' .. (self:enabled('slot') and 'ON' or 'OFF'))
        return true
    end

    return self
end

return M
