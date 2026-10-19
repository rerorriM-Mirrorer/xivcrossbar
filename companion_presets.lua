-- A: explicit personal template derived from Cioara-L1s.zip, ALL-JOBS-DEFAULT.
-- Never applied by migration/login. Existing ordinary/job crossbars are untouched.
local M={}
local names={l1='L1',l1l2='L1L2',r1='R1',r1r2='R1R2'}
local function command(label,text)
    return {Alias=label,Kind='command',Command=text,Key='',Hold=false}
end
function M.cioara(bank)
    -- Materialize the user's current L1 entries before replacing L1. Subsequent
    -- edits to either bank cannot mutate the other or re-resolve the old factory.
    local inventory={Closed={},Menu={}}
    for _,context in ipairs({'Closed','Menu'}) do for i=1,8 do
        local source=bank:entry(bank:settings().Preset=='cioara' and 'l1l2' or 'l1',i,context=='Menu');local e={}
        for k,v in pairs(source) do e[k]=v end
        inventory[context][i]=e
    end end
    local npc={command('Call party','npcmirror call'),command('Slow Enter','slowenter'),
        command('NPC status','npcmirror status'),command('Stop NPC','npcmirror stop'),
        command('Target','send @all input /targetnpc; wait 1; sat alltargetreport'),
        command('All Confirm','se all once; wait 2; slowenter on'),
        command('All Cancel','all slowenter off; wait 0.1; slowenter all once esc'),
        command('NPC Interact','npcmirror interact')}
    local trust={command('Myrr','switch to Myrr'),command('Killala','switch to Killala'),
        command('Clairvaux','switch to Clairvaux'),command('Cioara','switch to Cioara'),
        command('Open Trust','trust menu open'),
        command('Ready','send @others trust start; input /echo Asked party to stand ready!'),
        command('Stand Down','send @all trust stop; input /echo Asked party to stand down!'),
        command('Toggle','trust toggle')}
    local Banks=require('companion_banks')
    local navigation={}
    for i=1,8 do navigation[i]=Banks.factory('r1',i,false) end
    for layer,name in pairs(names) do
        local b=bank:settings()[name]
        b.Visible=layer~='r1r2';b.ShowOnMenu=layer=='r1';b.MenuActions=false
        b.Title=({l1='L1  NPC / Tests',l1l2='L1 + L2  Inventory',r1='R1  Party',r1r2='R1 + R2  Trust Menu'})[layer]
        for _,context in ipairs({'Closed','Menu'}) do for i=1,8 do
            local source=layer=='l1l2' and inventory[context][i] or layer=='l1' and npc[i] or layer=='r1' and trust[i] or navigation[i]
            local e={};for k,v in pairs(source) do e[k]=v end
            b[context]['Slot'..i]=e
        end end
    end
    bank:settings().Preset='cioara'
    bank:swap('l1','r1')
    for _,context in ipairs({'Closed','Menu'}) do
        bank:settings().L1L2[context].Slot6=command('Quests','input /quest')
    end
end
return M
