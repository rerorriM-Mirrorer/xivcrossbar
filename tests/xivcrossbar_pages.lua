local stub = dofile('tests/helpers/windower_stub.lua')
package.loaded.player = nil
local p = require('player')
p.hotbar = {
    basic={hotbar_1={slot_1={type='switch',action='Travel'}}},
    travel={hotbar_1={slot_1={type='ex',action='input /echo travel'},slot_2={type='switch',action='Nested'}}},
    nested={hotbar_1={slot_1={type='ex',action='input /echo nested'}}},
    shared={hotbar_1={slot_1={type='ex',action='input /echo shared'}}},
}
p.hotbar_settings.active_hotbar=1
local function apply_pending()
    local target=p.pending_env_switch
    p.pending_env_switch=nil
    if target then p:set_active_environment(target,true) end
end
p:set_active_environment('Basic')
p:execute_action(1); apply_pending()
assert(p.hotbar_settings.active_environment=='travel' and #stub.commands==0)
p:execute_action(8); apply_pending() -- empty slot must not count as an action
assert(p.hotbar_settings.active_environment=='travel')
p:execute_action(1); apply_pending()
assert(p.hotbar_settings.active_environment=='basic' and #stub.commands==1)
p:set_active_environment('Travel') -- normal switch stays after action
p:execute_action(1); apply_pending()
assert(p.hotbar_settings.active_environment=='travel' and #stub.commands==2)
p:set_active_environment('Basic'); p:execute_action(1); apply_pending()
p:execute_action(2); apply_pending(); p:execute_action(1); apply_pending()
assert(p.hotbar_settings.active_environment=='basic') -- nested retains original return
p:execute_action(1); apply_pending()
p:set_active_environment('Shared') -- manual choice cancels quick return
p:execute_action(1); apply_pending()
assert(p.hotbar_settings.active_environment=='shared' and p.temp_switch_previous_env==nil)
p.hotbar.basic.hotbar_1.slot_1.action='Missing'
p:set_active_environment('Basic'); p:execute_action(1)
assert(not p.pending_env_switch and not p.temp_switch_previous_env)
p.temp_switch_previous_env='basic'; p:reset_hotbar()
assert(not p.temp_switch_previous_env and not p.pending_env_switch)
print('PASS: real Quick XB Switch single dispatch/return, normal stay, empty/missing/nested pages and manual/reload cancellation')
