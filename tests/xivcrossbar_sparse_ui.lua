local stub = dofile('tests/helpers/windower_stub.lua')
images = require('images')
package.loaded.ui = nil
local ui = require('ui')
ui.is_compact = true
ui.theme = {hotbar_number=4, hide_empty_slots=true, hide_battle_notice=true}
ui.hotbars = {}
for h=1,6 do
    ui.hotbars[h] = {}
    for _, field in ipairs({'slot_background','slot_icon','slot_frame','slot_recast',
        'slot_warmup','slot_element','slot_text','slot_cost','slot_recast_text'}) do
        ui.hotbars[h][field] = {}
        for i=1,10 do ui.hotbars[h][field][i] = stub.surface() end
    end
end

-- Legacy/sparse page with no LR bar, while the renderer is configured for 4.
-- Previously both show and MP/TP updates indexed nil, including ui.lua:732.
local bars = {
    basic = {hotbar_1={}, hotbar_2={}, hotbar_3={}},
    ['all-jobs-default'] = {hotbar_4={slot_1={type='ex',action='input /echo fallback'}}},
    shared = {hotbar_1={}},
}
for _, count in ipairs({3,4,6}) do
    ui.theme.hotbar_number = count
    for _, env in ipairs({'basic','shared','missing'}) do
        for h=1,6 do
            for i=1,8 do ui.hotbars[h].slot_frame[i]._show = false end
        end
        ui:show(bars,env)
        ui:check_vitals(bars,{mp=100,tp=0},env)
        if count >= 4 then
            assert((ui.hotbars[4].slot_frame[1]._show ~= false) == (env ~= 'shared'))
        end
    end
end
assert(bars.basic.hotbar_4 == nil and bars.shared.hotbar_4 == nil)
print('PASS: sparse/missing UI pages with 3/4/6 bars, fallback, isolated Shared and no data mutation')
