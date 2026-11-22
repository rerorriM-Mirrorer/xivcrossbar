-- A (2026-11-21): appearance pass. The slot dim eases (menu entry/exit, set
-- switch, availability), covers fade in after the dim starts, and an
-- all-slots glow wave plays on menu open and on a real set change.
dofile('tests/compact.lua')
local now = 0
package.loaded.socket = {gettime=function() return now end}

-- fade_track: snap on first sight, ease-out, reverse from where it is.
local track = require('ui/fade_track').new(function() return now end)
assert(track:value('a', 255, .15) == 255, 'first value snaps')
assert(not track:busy())
assert(track:value('a', 205, .15) == 255, 'ease starts at the current value')
assert(track:busy())
now = .075
local mid = track:value('a', 205, .15)
assert(mid < 255 and mid > 205 and mid < 230, 'ease-out is past halfway at half time: ' .. mid)
local back = track:value('a', 255, .1)
assert(math.abs(back - mid) < 1e-9, 'reversal starts from the current value')
now = .2
assert(track:value('a', 255, .1) == 255 and not track:busy(), 'settles on the target')
assert(track:value('d', 0, .1) == 0); now = .25
assert(track:value('d', 1, .1, .04) == 0, 'delay holds the start value'); now = .30
local delayed = track:value('d', 1, .1, .04)
assert(delayed > 0 and delayed < 1, 'delayed ease moving: ' .. delayed)
assert(track:value('s', 3) == 3 and track:value('s', 9, 0) == 9, 'no duration snaps')
now = 0

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
    ['all-jobs-default']={hotbar_1={slot_2={type='ct',action='echo All'}}},
}
local function draw(menu)
    ui:check_recasts(hotbar, {mp=50,tp=0}, 'basic', {}, {active_bar=1}, skills, consumables,
        menu, false, menu, nil, nil, 1, nil)
    ui:tick_slot_wave()
end
local bar = ui.hotbars[1]
local function level(i) local r = bar.slot_icon[i]:color(); return r end

draw(false)
assert(level(1) == 255, 'resting brightness')
assert(not ui:has_dim_fade(), 'nothing moving at rest')
assert(ui.slot_wave == nil, 'first frame does not wave')

-- Menu opens: slots ease toward the menu dim, covers fade in after a delay,
-- the wave lights every drawn slot.
draw(true)
assert(level(1) == 255, 'dim starts from where it was, no snap')
assert(ui.slot_wave ~= nil, 'menu open starts the wave')
local view = ui.wave_views[1]
assert(view and view:visible(), 'wave view on slot 1')
local frame = ui.geometry.surfaces[view]
assert(frame.path:find('images/assets/slot-glow.png',1,true), 'same image as the pressed-slot glow')
assert(frame.width == 48 and frame.height == 48)
assert(ui.wave_views[2]:visible() and ui.wave_views[8]:visible(), 'all slots, empty ones too')
local start_alpha = view:alpha()
assert(start_alpha >= 240, 'occupied slot starts bright: ' .. start_alpha)
assert(ui.wave_views[8]:alpha() <= 145, 'empty slot is dimmer')
assert(ui:has_dim_fade(), 'redraw requested while easing')
local text = bar.slot_recast_text[2]
assert(text:text() == 'ALL', 'cover drawn')
assert(text:alpha() == 0, 'cover still waiting on its delay')

now = .1; draw(true)
local l = level(1)
assert(l < 255 and l > 205, 'dim part way: ' .. l)
local a = text:alpha()
assert(a > 0 and a < 200, 'cover fading in: ' .. a)
assert(view:alpha() < start_alpha, 'wave fading')

now = .25; draw(true)
assert(level(1) == 205, 'menu dim reached')
assert(text:alpha() == 200, 'cover at full strength')
assert(not ui:has_dim_fade(), 'settled')
now = .41; draw(true)
assert(ui.slot_wave == nil and not view:visible(), 'wave ends after 0.4 s')

-- A one-frame flip of the target (set reload) cannot blink: it only moves a little.
ui:clear_slot(1, 1)
local r = bar.slot_icon[1]:color()
assert(r == 205, 'clear_slot leaves the colour to check_recasts: ' .. r)

-- Menu closes: quicker exit.
now = 1; draw(false)
now = 1.05; draw(false)
l = level(1); assert(l > 205 and l < 255, 'brightening: ' .. l)
now = 1.11; draw(false)
assert(level(1) == 255, 'exit done within 0.1 s')
assert(ui.slot_wave == nil, 'closing does not wave')

-- Set change (Share) waves; switch off stops it.
ui:cue_set_switch()
assert(ui.slot_wave ~= nil, 'set switch waves')
ui.slot_wave_enabled = false
ui:tick_slot_wave()
assert(ui.slot_wave == nil and not view:visible(), 'turning it off clears the wave')
ui:cue_set_switch()
assert(ui.slot_wave == nil, 'off: no wave')
ui.slot_wave_enabled = true

-- Dim fade off: old instant writes.
ui.dim_fade_enabled = false
now = 2; draw(true)
assert(level(1) == 205, 'instant dim when off')
now = 2.01; draw(false)
assert(level(1) == 255, 'instant brighten when off')
ui.dim_fade_enabled = true

-- A bank that leaves and returns snaps (no fade on a trigger hold).
now = 3; draw(false)
ui:check_recasts(hotbar, {mp=50,tp=0}, 'basic', {}, {active_bar=2}, skills, consumables,
    true, false, true, 2, nil, 2, nil)
ui:check_recasts(hotbar, {mp=50,tp=0}, 'basic', {}, {active_bar=2}, skills, consumables,
    true, false, true, 2, nil, 2, nil)
local main = io.open('xivcrossbar.lua'):read('*a')
assert(main:find("command == 'dimfade' or command == 'slotwave'",1,true), 'commands wired')
assert(main:find('ui:tick_slot_wave()',1,true) and main:find('ui:has_dim_fade()',1,true), 'prerender wired')
print('Edit transition: eased dim (enter/exit/reverse), delayed cover fade, all-slots wave on open and set switch, switches.')
