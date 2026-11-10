-- A: physical keyboard navigation for custom actions and modal fields.
-- Own dispatched presses through release, even if Enter/Back changes screens.
local M={}
local actions={[200]='dpad_up',[208]='dpad_down',[203]='dpad_left',[205]='dpad_right',
    [28]='submit_selected_option',[156]='submit_selected_option',[1]='go_back'}
function M.new()
    local self={held={},owned={}}
    function self:reset()
        self.held, self.owned = {}, {}
    end
    function self:has_owned_key()
        return next(self.owned) ~= nil
    end
    function self:edge(dik,pressed,binder,allowed,modal_action)
        local action=actions[dik]
        if not action then return false end
        local was_held=self.held[dik]
        self.held[dik]=pressed or nil
        if self.owned[dik] then
            if not pressed then self.owned[dik]=nil end
            return true
        end
        local active=allowed and (modal_action or (binder.is_keyboard_review and binder:is_keyboard_review()))
        if not pressed or not active then return false end
        -- A key held before entering review may repeat, but must not select an
        -- option there. Its original native release still belongs to the game.
        if was_held then return true end
        self.owned[dik]=true
        if modal_action then modal_action(); return true end
        binder[action](binder,true)
        -- Keyboard navigation is one step per press. The controller repeat
        -- timer is only for D-pad holds that deliver their own release.
        if action:sub(1,5) == 'dpad_' then binder[action](binder,false) end
        return true
    end
    return self
end
return M
