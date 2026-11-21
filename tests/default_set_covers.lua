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
local function cover(i, label)
    local text, wash = bar.slot_recast_text[i], bar.slot_recast[i]
    assert(text:visible() and text:text() == label, i..': '..tostring(text:text()))
    local r,g,b = text:color(); assert(r==255 and g==216 and b==112, 'amber')
    r,g,b = text:stroke_color(); assert(r==0 and g==0 and b==0, 'black outline')
    assert(text:bold() == true)
    assert(text:size() == (#label > 3 and 9 or 10), 'size')
    assert(wash:visible() and wash:path():find('ui/black-square.png',1,true), 'wash, not a cover image')
    assert(wash:alpha() == 110, 'light wash')
    assert(bar.slot_icon[i]:visible(), 'icon visible underneath')
    assert(not bar.slot_cost[i]:visible(), 'cost hidden')
end
local function plain(i)
    local text = bar.slot_recast_text[i]
    assert(not ui.default_covers[i], 'cover state cleared')
    assert(text:bold() == false and text:size() == 10)
    local r,g,b = text:color(); assert(r==255 and g==255 and b==255, 'timer colour back')
end

-- Edit mode: inherited slots show their set's text cover; local slots none.
draw(true)
cover(2, 'ALL'); cover(3, 'JOB'); cover(4, 'JOB/SUB'); cover(5, 'ALL')
assert(not ui.default_covers[1] and not bar.slot_recast_text[1]:visible(), 'local slot has no cover')
for _, i in ipairs({2,3,4,5}) do
    assert(not bar.slot_recast[i]:path():find('default.png',1,true), 'old cover image unused')
end

-- Binding a slot locally clears its cover on the next draw.
hotbar.basic.hotbar_1.slot_2 = {type='ct',action='echo Mine',source_environment='basic'}
draw(true)
plain(2); assert(not bar.slot_recast_text[2]:visible() and not bar.slot_recast[2]:visible())
cover(3, 'JOB')

-- A slot that inherited a spell, then goes on cooldown as a local slot,
-- shows a normal white timer.
hotbar.basic.hotbar_1.slot_5 = {type='ma',action='Cure',source_environment='basic'}
remaining = 60
draw(true)
plain(5)
remaining = 0

-- Leaving the menu clears every cover.
draw(false)
for _, i in ipairs({3,4}) do plain(i); assert(not bar.slot_recast_text[i]:visible()) end
assert(not next(ui.default_covers))

-- Unknown environments draw nothing.
ui:mark_default_set_action(1, 6, 'shared')
assert(not ui.default_covers[6])
print('Default-set covers: ALL/JOB/JOBSUB text over a light wash, cleared on local bind, cooldown and menu close.')
