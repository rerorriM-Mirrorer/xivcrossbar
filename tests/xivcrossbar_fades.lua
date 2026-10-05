-- Contributing author: Awake — native opacity/state are tested separately
-- from visibility preferences, using the same real geometry as the addon.
local stub = dofile('tests/helpers/windower_stub.lua')
local now = 0
package.loaded.socket = {gettime=function() return now end}
local Fade = require('ui_fade')
local f = Fade.new(function() return now end, 0)
f:to(1, .2); now=.1; assert(math.abs(f:step()-.5) < .001)
f:to(0, .2); assert(math.abs(f.value-.5) < .001)
now=.2; assert(math.abs(f:step()-.25) < .001)
now=.3; assert(f:step() < .001)
f:to(1, 0); assert(f:step() == 1 and not f.active)

local g = require('ui_geometry').new()
g:configure_fade(true, .2, .2)
local raw = stub.surface()
local surface = g:surface(raw, 'text')
surface:alpha(200); surface:bg_alpha(100); surface:stroke_transparency(80)
surface:show()
local prim = g:prim()
prim.set_color('fade-test',150,10,20,30); prim.set_visibility('fade-test',true)
g:transition(false); surface:hide(); prim.set_visibility('fade-test',false)
assert(raw._visible and not surface:visible()) -- input hides immediately; drawing fades
now=.4; g:tick()
assert(math.abs(raw._alpha-100) <= 1 and math.abs(raw._bg_alpha-50) <= 1)
assert(math.abs(raw._stroke_transparency-40) <= 1)
assert(math.abs(stub.primitives['fade-test'].set_color[1]-75) <= 1)
g:transition(true); surface:show(); prim.set_visibility('fade-test',true)
assert(math.abs(raw._alpha-100) <= 1) -- reversal has no opacity jump
now=.6; g:tick(); assert(raw._alpha==200 and surface:visible())
g:transition(false); surface:hide(); surface:destroy()
assert(not raw._destroyed and #g.retired == 1)
now=.8; g:tick(); assert(raw._destroyed and #g.retired == 0)
assert(stub.primitives['fade-test'].set_color[1] == 0)

-- Reconfiguring a freshly loaded panel must not flash at full alpha.
g:configure_fade(true,.1,.1); g:set_opacity(0)
local fresh = stub.surface(); local p = g:surface(fresh,'image')
p:show(); g:transition(false); assert(fresh._alpha == 0)
g:transition(true); now=.85; g:tick(); assert(fresh._alpha>0 and fresh._alpha<255)
now=.9; g:tick(); assert(fresh._alpha==255)
print('PASS: elapsed-time fade/reversal, text/background/stroke/primitive opacity, closing resource release and flash-free load')

-- Closing the real binder retires its consumed selector rows through the fade.
local binder = stub.binder()
binder.theme_options.fade_enabled = true
binder.menu_geometry:configure_fade(true,.1,.1)
binder:show()
local image = binder.selector.images[1]
binder:hide(); binder:reset_state()
assert(not image._destroyed and #binder.menu_geometry.retired>0)
now=1.01; binder.menu_geometry:tick()
assert(image._destroyed and #binder.menu_geometry.retired==0)
print('PASS: whole-menu close survives selector reset and releases retired images')
