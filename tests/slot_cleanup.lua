dofile('tests/mp_cost_colors.lua')
local ui=require('ui/crossbar')
local spells=package.loaded['resources/crossbar_spells']
spells.Cure={mp_cost=35,tp_cost=0}
local hotbar={test={hotbar_1={slot_1={type='ma',action='Cure'},slot_2={type='ma',action='Cure'}}}}
ui.disabled_slots={actions={},no_vitals={},on_cooldown={},on_warmup={}}
ui:check_vitals(hotbar,{mp=1,tp=0},'test')
assert(ui.hotbars[1].slot_icon[1]:alpha()==100 and ui.hotbars[1].slot_icon[2]:alpha()==100)
ui:check_vitals(hotbar,{mp=99,tp=0},'test')
assert(ui.hotbars[1].slot_icon[1]:alpha()==255 and ui.hotbars[1].slot_icon[2]:alpha()==255)
ui.disabled_slots.on_cooldown['1:2']=5
ui:check_vitals(hotbar,{mp=99,tp=0},'test')
ui:toggle_slot(1,2,false)
ui:check_vitals(hotbar,{mp=1,tp=0},'test')
ui:check_vitals(hotbar,{mp=99,tp=0},'test')
assert(ui.hotbars[1].slot_icon[1]:alpha()==255 and ui.hotbars[1].slot_icon[2]:alpha()==100)
ui.feedback.max_opacity=150;ui.feedback.current_opacity=15;ui.feedback.speed=30;ui.feedback.is_active=true
ui:show_feedback()
assert(not ui.feedback.is_active and not ui.feedback_icon:visible())
assert(ui.feedback_icon:alpha()==0)
ui:trigger_feedback(1,1);ui:show_feedback();ui:trigger_feedback(1,2)
assert(ui.feedback.current_opacity==150)
for i=1,6 do ui:show_feedback() end
assert(not ui.feedback.is_active)
print('Duplicate affordability/recovery and slot-independent cooldown state; feedback overshoot/retrigger passed.')
