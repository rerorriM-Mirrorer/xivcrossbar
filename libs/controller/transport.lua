-- A: logical controller identifiers shared by message and Apps/F-key routes.
-- The keyboard route gates these with Apps; ordinary keyboard F-keys pass through.
local M = {down = {}}
M.signals = {
    [59] = {name='D-pad Up', logical=59, arrow='up'},       -- F-key transport
    [60] = {name='D-pad Right', logical=60, arrow='right'}, -- F-key transport
    [61] = {name='D-pad Down', logical=61, arrow='down'},   -- F-key transport
    [62] = {name='D-pad Left', logical=62, arrow='left'},   -- F-key transport
    [63] = {name='Cross', logical=63, button='cross'},     -- F-key transport
    [64] = {name='Square', logical=64, button='square'},   -- F-key transport
    [65] = {name='Circle', logical=65, button='circle'},   -- F-key transport
    [66] = {name='Triangle', logical=66, button='triangle'}, -- F-key transport
    [67] = {name='Share', logical=67},                    -- F-key transport
    [68] = {name='Options', logical=68},                  -- F-key transport
    [87] = {name='L2', logical=87},                       -- F-key transport
    [88] = {name='R2', logical=88},                       -- F-key transport
}
function M:edge(dik, pressed, context)
    local signal = self.signals[dik]
    if not signal then return nil end
    if pressed then
        if self.down[dik] then return signal, 'repeat', self.down[dik] end
        self.down[dik] = context
        return signal, 'down', context
    end
    local owner = self.down[dik]
    self.down[dik] = nil
    return signal, 'up', owner
end
function M:reset() self.down = {} end
function M:gameplay_key(signal, mapping, dpad_mode)
    if signal.arrow then
        if dpad_mode == 'ijkl' then
            return ({up='i',left='j',down='k',right='l'})[signal.arrow]
        end
        return signal.arrow
    end
    local b = signal.button
    if not b then return nil end
    if b == mapping.confirm_button then return 'enter' end
    if b == mapping.cancel_button then return 'escape' end
    if b == mapping.mainmenu_button then return 'numpad-' end
    if b == mapping.activewindow_button then return 'numpad+' end
end
function M:login_key(signal,mapping)
    -- Before character settings are available, use ordinary menu arrows.
    local defaults={confirm_button='cross',cancel_button='circle',mainmenu_button='triangle',activewindow_button='square'}
    local selected={}
    for key,fallback in pairs(defaults) do selected[key]=mapping[key] or fallback end
    return self:gameplay_key(signal,selected,'arrows')
end
return M
