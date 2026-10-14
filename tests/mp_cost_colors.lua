-- Real affordability/rendering path for ordinary and linked spells; TP and
-- recast dimming stay independent of the new MP-specific color.
dofile('tests/compact.lua')
local ui=require('ui')
local spells=package.loaded['resources/crossbar_spells']
local abilities=package.loaded['resources/crossbar_abilities']
spells.Cure={mp_cost=35,tp_cost=0}
abilities.TestWS={mp_cost=0,tp_cost=1000}
ui.theme.hotbar_number=1
ui.disabled_slots={actions={},no_vitals={},on_cooldown={},on_warmup={}}
local hotbar={test={hotbar_1={slot_1={type='ma',action='Cure'},
    slot_2={type='ex',action='echo linked',linked_type='ma',linked_action='Cure'},
    slot_3={type='ws',action='TestWS'}}}}
local function color(slot,red,green,blue)
    local object=ui.geometry.surfaces[ui.hotbars[1].slot_cost[slot]].object
    local c=object.values.color
    assert(c and c[1]==red and c[2]==green and c[3]==blue,'wrong cost color, slot '..slot)
end
ui.hotbars[1].slot_cost[3]:color(254,222,0)
ui:check_vitals(hotbar,{mp=10,tp=1000},'test')
color(1,255,149,151);color(2,255,149,151);color(3,254,222,0)
assert(ui.hotbars[1].slot_icon[1]:alpha()==100 and ui.hotbars[1].slot_icon[2]:alpha()==100)
ui.disabled_slots.on_cooldown.Cure=true
ui:check_vitals(hotbar,{mp=50,tp=1000},'test')
color(1,194,253,195);color(2,194,253,195)
assert(ui.hotbars[1].slot_icon[1]:alpha()==100,'MP recovery incorrectly ended recast dimming')
assert(ui.hotbars[1].slot_icon[2]:alpha()==255,'linked spell did not recover')
ui.disabled_slots.on_cooldown.Cure=nil
ui:check_vitals(hotbar,{mp=50,tp=0},'test')
assert(ui.hotbars[1].slot_icon[1]:alpha()==255)
color(3,254,222,0)
ui.theme.mp_cost_color_red,ui.theme.mp_cost_color_green,ui.theme.mp_cost_color_blue=12,34,56
ui:check_vitals(hotbar,{mp=50,tp=0},'test');color(1,12,34,56)
print('MP shortage/recovery colors, linked metadata, cooldown independence and TP preservation passed.')
