-- Logical DIKs used internally by the controller router.
local M = {down = {}}
M.signals = {
    [59] = {name='D-pad Up', logical=59, arrow='up'},
    [60] = {name='D-pad Right', logical=60, arrow='right'},
    [61] = {name='D-pad Down', logical=61, arrow='down'},
    [62] = {name='D-pad Left', logical=62, arrow='left'},
    [63] = {name='Cross', logical=63, button='cross'},
    [64] = {name='Square', logical=64, button='square'},
    [65] = {name='Circle', logical=65, button='circle'},
    [66] = {name='Triangle', logical=66, button='triangle'},
    [67] = {name='Share', logical=67},
    [68] = {name='Options', logical=68},
    [87] = {name='L2', logical=87},
    [88] = {name='R2', logical=88},
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
return M
