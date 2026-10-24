-- A: explicit Party/NPC template. Never applied on login or migration.
-- It changes bank bindings/policies only; panel coordinates and job bars stay put.
local M={}
function M.cioara(bank)
    local Banks=require('libs/banks/banks')
    for layer,name in pairs({l1='L1',l1l2='L1L2',r1='R1',r1r2='R1R2'}) do
        local b=bank:settings()[name]
        b.Enabled=layer=='l1' or layer=='r1'
        b.Display='held';b.Visible=true;b.ShowOnMenu=true;b.MenuActions=false;b.Title=''
        for _,context in ipairs({'Closed','Menu'}) do for i=1,8 do
            b[context]['Slot'..i]=Banks.factory(layer,i,context=='Menu')
        end end
    end
    bank:settings().Preset='cioara'
end
return M
