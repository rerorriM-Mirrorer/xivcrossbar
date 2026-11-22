-- A (2026-11-21): default-set covers are amber text (ALL, JOB, JOB/SUB) with
-- a black outline over a light wash, so the inherited icon stays visible.
dofile('tests/compact.lua')
local now, remaining = 0, 0
package.loaded.socket = {gettime=function() return now end}
windower.ffxi.get_spell_recasts=function() return {[24]=remaining} end
package.loaded['resources/crossbar_spells'].Cure={id=24,recast_id=24}
local options = require('theme').apply(require('defaults'))
options.button_layout = 'playstation'
options.fade_enabled = false
local ui = require('ui')
ui:setup(options, {})
ui.geometry:set_opacity(1)
ui.display_skillchain_indicator=function() end
ui.display_aa_indicator=function() end
local skills = {get_skillchain_window=function() return 0,0 end, get_skillchain_result=function() end}
local consumables = {get_item_count_by_name=function() return 0 end}
local hotbar = {
    basic={hotbar_1={slot_1={type='ct',action='echo Local',source_environment='basic'}}},
    ['all-jobs-default']={hotbar_1={slot_2={type='ct',action='echo All'},
        slot_5={type='ma',action='Cure'}}},
    ['job-default']={hotbar_1={slot_3={type='ct',action='echo Job'}}},
    default={hotbar_1={slot_4={type='ct',action='echo JobSub'}}},
}
local function draw(menu)
    ui:check_recasts(hotbar, {mp=50,tp=0}, 'basic', {}, {active_bar=1}, skills, consumables,
        menu, false, menu, nil, nil, 0, nil)
end
local bar = ui.hotbars[1]
local function surface(view) return ui.geometry.surfaces[view] end
-- A (2026-11-21): covers live on their own surfaces (cover_wash, cover_text)
-- and fade; this test checks the settled look, so the fades are off here
-- (tests/edit_transition.lua covers the timing).
ui.dim_fade_enabled = false
local function cover(i, label, depth)
    depth = depth or 1
    local text, wash = bar.cover_text[i], bar.cover_wash[i]
    assert(text:visible() and text:text() == label, i..': '..tostring(text:text()))
    local r,g,b = text:color()
    if label == 'ALL' then assert(r==222 and g==178 and b==86, 'ALL in the darker amber')
    -- A (2026-11-22): JOB and /SUB a little brighter than the usual amber.
    else assert(r==255 and g==232 and b==150, 'job layers in the brighter amber') end
    r,g,b = text:stroke_color(); assert(r==0 and g==0 and b==0, 'black outline')
    assert(text:bold() == true)
    assert(text:size() == 10, 'one size for every label')
    assert(ui.cover_states[i].cx == ui:get_slot_x(1, i) + 20 + ui.cover_offset_x, 'centred on the slot (x+20) plus offset')
    assert(text:alpha() == ({200,135,85})[depth], i..' text alpha depth '..depth..': '..text:alpha())
    assert(wash:visible() and wash:path():find('ui/black-square.png',1,true), 'wash, not a cover image')
    assert(wash:alpha() == ({110,148,185})[depth], i..' wash depth '..depth..': '..wash:alpha())
    assert(bar.slot_icon[i]:visible(), 'icon visible underneath')
    assert(not bar.slot_cost[i]:visible(), 'cost hidden')
    assert(not bar.slot_recast_text[i]:visible(), 'timer text not used by the cover')
end
local function plain(i)
    assert(not ui.default_covers[i], 'cover state cleared')
    assert(not bar.cover_text[i]:visible() and not bar.cover_wash[i]:visible(), 'cover hidden')
end

-- Edit mode on Basic: JOB/SUB one layer down, JOB two, ALL three.
draw(true)
cover(2, 'ALL', 3); cover(3, 'JOB', 2); cover(4, '/SUB', 1); cover(5, 'ALL', 3)
assert(not ui.default_covers[1] and not bar.cover_text[1]:visible(), 'local slot has no cover')

-- The cover label offset nudges every label the same way.
assert(ui.cover_offset_x == 1 and ui.cover_offset_y == -3, 'A live default 1, -3')
local base_cy = ui.cover_states[3].cy
ui.cover_offset_x, ui.cover_offset_y = 0, 0
draw(true)
assert(ui.cover_states[3].cx == ui:get_slot_x(1, 3) + 20 and ui.cover_states[3].cy == base_cy + 3, 'offset applied')
ui.cover_offset_x, ui.cover_offset_y = 1, -3
draw(true)

-- Real job names once the jobs are known.
ui.cover_main_job, ui.cover_sub_job = 'WHM', 'SCH'
draw(true)
cover(3, 'WHM', 2); cover(4, '/SCH', 1); cover(2, 'ALL', 3)
ui.cover_sub_job = 'NON'
draw(true)
cover(4, 'WHM', 1)
ui.cover_sub_job = 'SCH'

-- Depth follows the active set: on the JOB/SUB set (default), JOB is one
-- layer down and ALL two.
local function draw_on(env, menu)
    ui:check_recasts(hotbar, {mp=50,tp=0}, env, {}, {active_bar=1}, skills, consumables,
        menu, false, menu, nil, nil, 0, nil)
end
hotbar.default.hotbar_1.slot_3 = {type='ct',action='echo Job',source_environment='job-default'}
hotbar.default.hotbar_1.slot_2 = {type='ct',action='echo All',source_environment='all-jobs-default'}
local saved_basic = hotbar.basic
hotbar.default.hotbar_1.slot_1 = {type='ct',action='echo Local',source_environment='default'}
draw_on('default', true)
cover(3, 'WHM', 1); cover(2, 'ALL', 2)
ui.cover_depth_enabled = false
draw_on('default', true)
cover(2, 'ALL', 1)
ui.cover_depth_enabled = true
hotbar.default.hotbar_1.slot_3, hotbar.default.hotbar_1.slot_2, hotbar.default.hotbar_1.slot_1 = nil, nil, nil
draw(true)

-- Binding a slot locally clears its cover on the next draw.
hotbar.basic.hotbar_1.slot_2 = {type='ct',action='echo Mine',source_environment='basic'}
draw(true)
plain(2)
cover(3, 'WHM', 2)

-- A slot that inherited a spell, then goes on cooldown as a local slot,
-- shows a normal white timer.
hotbar.basic.hotbar_1.slot_5 = {type='ma',action='Cure',source_environment='basic'}
remaining = 60
draw(true)
plain(5)
assert(bar.slot_recast_text[5]:visible() and bar.slot_recast_text[5]:text() ~= 'ALL', 'its own timer shows')
remaining = 0

-- Leaving the menu clears every cover.
draw(false)
for _, i in ipairs({3,4}) do plain(i) end
assert(not next(ui.default_covers))

-- Unknown environments draw nothing.
ui:mark_default_set_action(1, 6, 'shared', 'basic')
assert(not ui.default_covers[6])
print('Default-set covers: ALL / WHM / /SCH text over a light wash on their own surfaces, depth by inheritance, centred with offset, cleared on local bind, cooldown and menu close.')
