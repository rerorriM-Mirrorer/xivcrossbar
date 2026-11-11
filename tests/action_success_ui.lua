dofile('tests/compact.lua')
local now=0
package.loaded.socket={gettime=function()return now end}
local options=require('theme').apply(require('defaults'))
options.button_layout='playstation';options.fade_enabled=false
local ui=require('ui');ui:setup(options,{})
ui.pulse_visible_bars[1]=true
ui:flash_action_success(1,1)
local views=ui.success_views[1]
assert(views.center:visible() and views.border:visible())
assert(views.center:alpha()==184 and views.border:alpha()==156)
assert(ui.geometry.surfaces[views.border].path:find('images/assets/recast-glow.png',1,true))
local m=ui.geometry.surfaces[views.center]
assert(m.bank==ui.geometry.banks[1] and m.width==40)
ui:observe_recast(1,1,{},60)
assert(views.center:visible(),'new cooldown cannot cancel confirmation')
now=.2;ui:tick_action_success();assert(views.center:alpha()==46 and views.border:alpha()==39)
now=.41;ui:tick_action_success();assert(not views.center:visible())
ui:flash_action_success(1,1);ui.pulse_visible_bars[1]=false;ui:tick_action_success()
assert(not views.center:visible(),'hidden bank must discard confirmation')
ui.pulse_visible_bars[1]=true;ui:flash_action_success(1,1);ui:clear_slot(1,1)
assert(not views.center:visible(),'rebound slots cannot keep old confirmation')
print('action success UI: layers, duration, cooldown independence and cleanup passed')
