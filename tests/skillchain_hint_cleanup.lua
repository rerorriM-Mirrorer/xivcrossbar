-- Exercise the actual recast renderer with persistent drawing surfaces across
-- action/set changes. Tracker results are controlled, not the rendering logic.
dofile('tests/compact.lua')
local ui=require('ui/crossbar')
local abilities=package.loaded['resources/crossbar_abilities']
local spells=package.loaded['resources/crossbar_spells']
abilities.TestWS={id=1,recast_id=1}
abilities.TestJA={id=2,recast_id=2}
spells.TestSpell={id=3,recast_id=3,category='black magic'}
windower.ffxi.get_ability_recasts=function() return {} end
windower.ffxi.get_mob_by_target=function() return nil end
local recasts={}
windower.ffxi.get_spell_recasts=function() return recasts end
ui.theme.hotbar_number=1
ui.theme.hide_recast_animation=false
ui.theme.hide_recast_text=false
ui.autoattack:set_enabled(false)
ui.disabled_slots={actions={},no_vitals={},on_cooldown={},on_warmup={}}
local prop,kind='Light','skillchain'
local tracker={get_skillchain_window=function()return 0,0 end,
    get_skillchain_result=function()return prop,kind end}
local bar={test={hotbar_1={}}}
local action={type='ws',action='TestWS',source_environment='test'}
local vitals={mp=100,tp=500}
local function draw(a)
    bar.test.hotbar_1.slot_1=a
    ui:check_recasts(bar,vitals,'test',{}, {active_bar=1},tracker,{},false,false)
end
local surfaces=ui.hotbars[1]
local function visible(name)return ui.geometry.surfaces[surfaces[name][1]].visible end
local function ordinary()
    assert(surfaces.slot_frame[1]:path()==ui.frame_image_path,'stale animated frame')
    assert(surfaces.slot_frame[1]:alpha()==255,'stale hint frame alpha')
    assert(not visible('slot_warmup'),'stale skillchain icon')
end
for _,replacement in ipairs({{type='ex',action='echo test'},
    {type='ja',action='TestJA'},{type='ma',action='Missing'},
    {type='ws',action='Missing'}}) do
    prop,kind='Light','skillchain';draw(action)
    assert(visible('slot_warmup') and surfaces.slot_frame[1]:alpha()==150)
    prop,kind=nil,nil;draw(replacement);ordinary()
end
prop,kind='Light','skillchain';draw(action)
prop,kind=nil,nil;draw(nil);ordinary()
-- Same action, expired window: restore artwork, cost and icon visibility.
prop,kind='Light','skillchain';vitals.tp=1500;draw(action)
assert(not visible('slot_cost'))
prop,kind=nil,nil;draw(action);ordinary()
assert(visible('slot_cost') and visible('slot_icon'))
-- A burst animates only the frame; never reuse the old SC property texture.
prop,kind='Light','skillchain';draw(action)
prop,kind='Fire','burst';draw({type='ma',action='TestSpell'})
assert(not visible('slot_warmup') and visible('slot_icon'))
assert(surfaces.slot_frame[1]:alpha()==255)
-- Existing item warmup survives cleanup and subsequent frames.
prop,kind=nil,nil
local cooling=false
ui.enchanted_items={get_warmup_fraction=function()return .5 end,
    get_warmup_time=function()return 10 end,
    get_cooldown_fraction=function()return cooling and .5 or 0 end,
    get_cooldown_time=function()return 60 end}
for _=1,2 do
    draw({type='enchanteditem',action='TestRing'})
    assert(visible('slot_warmup'))
    assert(surfaces.slot_warmup[1]:path():find('blue-square.png',1,true))
    assert(ui.geometry.surfaces[surfaces.slot_warmup[1]].height==20)
    assert(surfaces.slot_frame[1]:path()==ui.frame_image_path)
end
cooling=true;draw({type='enchanteditem',action='TestRing'})
assert(not visible('slot_warmup') and visible('slot_recast'))
assert(ui.geometry.surfaces[surfaces.slot_recast[1]].height==20)
-- Replacement cleanup must also work before check_recasts runs again.
prop,kind='Light','skillchain';draw(action)
ui:clear_slot(1,1);ordinary()
assert(not visible('slot_recast') and surfaces.slot_recast_text[1]:text()=='')
print('Actual hint renderer: replacement types, empty/expired slots, SC-to-burst, frame alpha, item warmup/cooldown and immediate clear passed.')
