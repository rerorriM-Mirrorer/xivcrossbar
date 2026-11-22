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
ui.chooser_open = false
ui.display_skillchain_indicator=function() end
ui.display_aa_indicator=function() end
local skills = {get_skillchain_window=function() return 0,0 end, get_skillchain_result=function() end}
local consumables = {get_item_count_by_name=function() return 0 end}
local hotbar = {
    basic={hotbar_1={slot_1={type='ct',action='echo Local',source_environment='basic'}}},
    ['all-jobs-default']={hotbar_1={slot_2={type='ct',action='echo All'}}},
}
local function draw(menu, destination)
    ui:check_recasts(hotbar, {mp=50,tp=0}, 'basic', {}, {active_bar=1}, skills, consumables,
        menu, false, menu, nil, nil, 1, destination)
    ui:tick_slot_wave()
end
local bar = ui.hotbars[1]
local function level(i) local r = bar.slot_icon[i]:color(); return r end

assert(ui.dim_fade_enter == .9 and ui.dim_fade_exit == .6 and ui.dim_fade_change == .15, 'A 2026-11-22 defaults')
-- Wave and edit-glow views exist from setup with their texture (no white
-- square from a view created and shown in the same frame).
assert(ui.wave_views[1] and ui.edit_glow_views[1] and not ui.wave_views[1]:visible())
assert(ui.geometry.surfaces[ui.edit_glow_views[1]].path:find('images/assets/slot-glow.png',1,true))
local r,g,b = ui.edit_glow_views[1]:color(); assert(r==190 and g==120 and b==40, 'dark amber tint')

draw(false)
assert(level(1) == 255, 'resting brightness')
assert(not ui:has_dim_fade(), 'nothing moving at rest')
assert(ui.slot_wave == nil, 'first frame does not wave')

-- Menu opens: slots ease toward the menu dim over 0.9 s, covers fade in after
-- a delay, labels lift, the amber edit glow eases in. No wave.
draw(true)
assert(level(1) == 255, 'dim starts from where it was, no snap')
assert(ui.slot_wave == nil, 'menu open does not wave (A 2026-11-22)')
local text = bar.cover_text[2]
assert(text:text() == 'ALL', 'cover drawn')
assert(text:alpha() == 0, 'cover still waiting on its delay')
local labels_before = ui:label_alpha()
local glow = ui.edit_glow_views[1]
assert(not glow:visible() or glow:alpha() == 0, 'edit glow starts at zero')

now = .3; draw(true)
local l = level(1)
assert(l < 255 and l > 205, 'dim part way: ' .. l)
local a = text:alpha()
assert(a > 0 and a < 85, 'cover fading in (ALL on Basic is three layers down): ' .. a)
assert(ui:label_alpha() > labels_before or labels_before == 255, 'labels brightening')
local ga = glow:alpha()
assert(glow:visible() and ga > 0 and ga < 70, 'edit glow easing in: ' .. ga)
assert(ui.edit_glow_views[8]:visible(), 'every drawn slot, empty ones too')

now = 1; draw(true)
assert(level(1) == 205, 'menu dim reached')
assert(text:alpha() == 85, 'cover at full strength for its depth')
assert(ui:label_alpha() == math.min(255, ui.bank_label_opacity + 50), 'labels lifted by 50')
assert(glow:alpha() == 70, 'edit glow at full strength')
assert(not ui:has_dim_fade(), 'settled')

-- Selecting a slot: the amber tint fades in with the press (0.06 s); a new
-- slot fades in again; deselecting fades it out (0.14 s) where it was.
local tint = ui.destination_tint
draw(true, {bank=1, slot=3})
assert(tint:visible() and tint:alpha() == 0, 'tint starts clear')
now = 1.03; draw(true, {bank=1, slot=3})
local ta = tint:alpha(); assert(ta > 0 and ta < 120, 'tint fading in: ' .. ta)
now = 1.07; draw(true, {bank=1, slot=3})
assert(tint:alpha() == 120, 'tint in after 0.06 s')
draw(true, {bank=1, slot=4})
assert(tint:alpha() == 0 and tint:pos() == ui:get_slot_x(1, 4), 'new slot fades in again')
now = 1.2; draw(true, {bank=1, slot=4})
draw(true, nil)
assert(tint:visible() and tint:alpha() == 120, 'deselect starts from full')
now = 1.27; draw(true, nil)
ta = tint:alpha(); assert(ta > 0 and ta < 120 and tint:pos() == ui:get_slot_x(1, 4), 'fading out in place: ' .. ta)
now = 1.35; draw(true, nil)
assert(not tint:visible(), 'tint gone after 0.14 s')

-- A one-frame flip of the target (set reload) cannot blink: clear_slot no
-- longer resets the colour.
ui:clear_slot(1, 1)
local rr = bar.slot_icon[1]:color()
assert(rr == 205, 'clear_slot leaves the colour to check_recasts: ' .. rr)

-- Menu closes: 0.6 s exit; covers fade out over 0.06 s; edit glow eases out.
now = 2; draw(false)
assert(text:visible() and text:alpha() > 0, 'cover fading out, not cut')
now = 2.07; draw(false)
assert(not text:visible() and not ui.default_covers[2], 'cover gone after its fade-out')
now = 2.3; draw(false)
l = level(1); assert(l > 205 and l < 255, 'brightening: ' .. l)
assert(glow:alpha() > 0 and glow:alpha() < 70, 'edit glow easing out')
now = 2.61; draw(false)
assert(level(1) == 255, 'exit done within 0.6 s')
assert(not glow:visible(), 'edit glow gone')
assert(ui:label_alpha() == ui.bank_label_opacity or ui.bank_label_opacity <= 0, 'labels back')
assert(ui.slot_wave == nil, 'closing does not wave')

-- Set change waves (0.9 s, 80% peak); the chooser opening does not.
ui.chooser_open = true
now = 3; draw(true)
assert(ui.slot_wave == nil, 'chooser open: no wave')
ui:cue_set_switch(); ui:tick_slot_wave()
local view = ui.wave_views[1]
assert(ui.slot_wave ~= nil and view:visible(), 'set switch waves')
assert(view:alpha() == 200 and ui.wave_views[8]:alpha() == 116, '80% of the press-glow levels')
now = 3.5; ui:tick_slot_wave()
assert(ui.slot_wave ~= nil, 'still fading at 0.5 s')
now = 3.91; ui:tick_slot_wave()
assert(ui.slot_wave == nil and not view:visible(), 'wave ends after 0.9 s')
ui.chooser_open = false
now = 4; draw(false)

-- Wave switch off.
ui.slot_wave_enabled = false
ui:cue_set_switch()
assert(ui.slot_wave == nil, 'off: no wave')
ui.slot_wave_enabled = true

-- A set switch while the menu is open fades new covers in over dimchange.
now = 5; draw(true)
now = 7; draw(true)
assert(text:alpha() == 85)
hotbar['all-jobs-default'].hotbar_1.slot_2 = nil
hotbar['job-default'] = {hotbar_1={slot_2={type='ct',action='echo Job'}}}
now = 8; draw(true)
assert(text:visible(), 'label change keeps a cover')
now = 8.1; draw(true)
local mid_cover = text:alpha()
now = 8.25; draw(true)
assert(text:text() == 'JOB' and text:alpha() == 135 and mid_cover < 135, 'set-switch cover in over 0.15 s after the delay')
now = 9; draw(false); now = 10; draw(false)

-- Dim fade off: old instant writes.
ui.dim_fade_enabled = false
now = 11; draw(true)
assert(level(1) == 205, 'instant dim when off')
now = 11.01; draw(false)
assert(level(1) == 255, 'instant brighten when off')
ui.dim_fade_enabled = true

-- A bank that leaves and returns snaps (no fade on a trigger hold).
now = 12; draw(false)
ui:check_recasts(hotbar, {mp=50,tp=0}, 'basic', {}, {active_bar=2}, skills, consumables,
    true, false, true, 2, nil, 2, nil)
local main = io.open('xivcrossbar.lua'):read('*a')
assert(main:find("command == 'dimfade' or command == 'slotwave'",1,true) and main:find("command == 'dimchange'",1,true), 'commands wired')
assert(main:find('ui:tick_slot_wave()',1,true) and main:find('ui:has_dim_fade()',1,true), 'prerender wired')
assert(main:find('action_binder.edit_press_hook = function',1,true), 'edit-mode press animation wired')
print('Edit transition: 0.9/0.6 s menu dim, delayed cover fades, label lift, amber edit glow, selection tint fade, set-switch-only wave, switches.')
