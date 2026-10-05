local stub = dofile('tests/helpers/windower_stub.lua')
local now = 0
local Visibility = require('ui_visibility')
local v = Visibility.new(function() return now end)
assert(not v:visible('OnInput', .25, false))
assert(v:visible('Always', .25, false))
assert(v:visible('OnInput', .25, true))
now = 3
assert(v:visible('OnInput', .25, false)) -- grace starts at release
now = 3.24; assert(v:visible('OnInput', .25, false))
now = 3.26; assert(not v:visible('OnInput', .25, false))
assert(v:visible('OnInput', .25, true)) -- immediate re-press
v:reset(); assert(not v:visible('OnInput', .25, false))

-- Run the actual main event handlers, with rendering/FFXI services stubbed.
local settings = {Style={OffsetX=0,OffsetY=0}, UILocked=true,
    VisibilityMode='OnInput', VisibilityGrace=.25}
package.loaded.defaults = settings
package.loaded.socket = {gettime=function() return now end}
package.loaded.theme = {apply=function() return {frame_skip=10,hotbar_number=6} end}
package.loaded.resource_generator = {generate_outdated_resources=function() end}
local counts = {hide=0,show=0,load=0,vitals=0,recasts=0}
local ui = {is_setup=true,feedback={is_active=false}}
for _, name in ipairs({'hide','show','check_vitals','check_recasts','load_player_hotbar'}) do
    local key = ({check_vitals='vitals',check_recasts='recasts',load_player_hotbar='load'})[name] or name
    ui[name] = function() counts[key]=counts[key]+1 end
end
ui.show_drag_handle=function() end
ui.set_scale=function() end
ui.trigger_feedback=function() end
local chooser = {showing=false}
chooser.is_showing=function(self) return self.showing end
chooser.show_player_environments=function(self) self.showing=true end
chooser.hide_player_environments=function(self) self.showing=false end
chooser.get_player_environments=function() return {} end
local player = {hotbar={},vitals={},current_spells={},hotbar_settings={active_environment='basic'}}
player.change_active_hotbar=function(self,h) self.hotbar_settings.active_hotbar=h end
player.set_is_in_battle=function() end
player.execute_action=function() end
local control = {ready=true,hide_hotbars=false,in_battle=false}
package.loaded.ui=ui
package.loaded.player=player
package.loaded.environment_chooser=chooser
package.loaded.variables=control
package.loaded.action_binder={is_hidden=true,is_capturing_text=function() return false end}
package.loaded['libs/skillchain/skillchains']={prerender=function() end,logout=function() end}
for _,name in ipairs({'libs/xml2','buttonmapping','enchanted_items','consumables',
    'gamepad_mapper','gamepad_converter','function_key_bindings'}) do package.loaded[name]={} end
package.loaded.gamepad=nil
package.loaded.keyboard_mapper=nil
aa_set_engaged=function() end
coroutine.schedule=function() end
dofile('./xivcrossbar.lua')
stub.emit('prerender')
assert(ui.suspended and counts.hide==1 and counts.recasts==0)
stub.emit('mp change',5,0)
assert(player.vitals.mp==5 and counts.vitals==0)
stub.emit('keyboard',29,true,0,false) -- Ctrl
stub.emit('keyboard',87,true,0,false) -- L2, immediate despite frame skip
assert(not ui.suspended and counts.show==1 and counts.load==1 and counts.vitals==1)
stub.emit('keyboard',87,false,0,false)
now=now+.20; stub.emit('prerender'); assert(not ui.suspended)
now=now+.10; stub.emit('prerender'); assert(ui.suspended)
stub.emit('keyboard',68,true,0,false) -- Options
assert(not ui.suspended and chooser.showing)
stub.emit('keyboard',68,false,0,false)
chooser.capturing=true
now=now+2; stub.emit('prerender'); assert(not ui.suspended)
chooser.capturing=false
stub.emit('prerender'); now=now+.30; stub.emit('prerender'); assert(ui.suspended)
stub.emit('keyboard',88,true,0,false) -- R2
stub.emit('keyboard',87,true,0,false) -- R2 then L2
assert(not ui.suspended and player.hotbar_settings.active_hotbar==3)
stub.emit('status change',4); assert(ui.suspended) -- preserve cutscene hide
stub.emit('status change',0); assert(not ui.suspended)
stub.emit('addon command','ui','visibility','Always')
assert(settings.VisibilityMode=='Always')
stub.emit('keyboard',87,false,0,false)
stub.emit('keyboard',88,false,0,false)
now=now+10; stub.emit('prerender'); assert(not ui.suspended)
stub.emit('addon command','ui','hide')
assert(ui.suspended and settings.VisibilityMode=='Always')
stub.emit('keyboard',87,true,0,false)
assert(ui.suspended) -- manual hide wins over input
stub.emit('addon command','ui','show'); assert(not ui.suspended)
stub.emit('status change',4); assert(not ui.suspended) -- explicit show wins in cutscenes
stub.emit('addon command','ui','auto'); assert(ui.suspended) -- automatic mode still follows cutscene hiding
stub.emit('addon command','ui','show'); assert(not ui.suspended)
stub.emit('status change',0); assert(not ui.suspended)
stub.emit('keyboard',87,false,0,false)
stub.emit('addon command','ui','visibility','OnInput'); assert(ui.suspended)
stub.emit('addon command','ui','show'); assert(not ui.suspended)
stub.emit('addon command','ui','auto'); assert(ui.suspended and settings.VisibilityMode=='OnInput')
stub.emit('addon command','ui','hide')
stub.emit('addon command','ui','unlock'); assert(ui.suspended) -- unlocking respects explicit Hide
stub.emit('addon command','ui'); assert(not ui.suspended) -- bare UI toggles actual drawing
stub.emit('addon command','ui'); assert(ui.suspended)
stub.emit('addon command','ui','show'); assert(not ui.suspended)
stub.emit('addon command','ui','lock')
stub.emit('addon command','autohide','off'); assert(settings.VisibilityMode=='Always' and not ui.suspended)
stub.emit('addon command','autohide'); assert(settings.VisibilityMode=='OnInput' and ui.suspended)
stub.emit('addon command','ui','visibility'); assert(settings.VisibilityMode=='Always' and not ui.suspended)
stub.emit('addon command','autohide','on'); assert(settings.VisibilityMode=='OnInput')
stub.emit('addon command','ui','grace','30'); assert(settings.VisibilityGrace==30)
stub.emit('keyboard',87,true,0,false); assert(not ui.suspended)
stub.emit('keyboard',87,false,0,false)
now=now+29; stub.emit('prerender'); assert(not ui.suspended)
now=now+2; stub.emit('prerender'); assert(ui.suspended)
for _, invalid in ipairs({'-1','nan','inf','1e309','nope'}) do
    stub.emit('addon command','ui','grace',invalid); assert(settings.VisibilityGrace==30)
end
-- Scale preview temporarily overrides Hide, then restores it without changing
-- the stored visibility preference; an explicit Hide cancels a pending preview.
stub.emit('addon command','ui','hide'); assert(ui.suspended)
stub.emit('addon command','ui','scale','.75'); assert(not ui.suspended)
assert(settings.VisibilityMode=='OnInput')
now=now+31; stub.emit('prerender'); assert(ui.suspended)
stub.emit('addon command','ui','scale','1'); assert(not ui.suspended)
stub.emit('addon command','ui','hide'); assert(ui.suspended)
stub.emit('logout'); stub.emit('prerender')
assert(not control.ready and ui.suspended)
print('PASS: release grace, input/menu events, sequential triggers, hidden render work, manual overrides, cutscenes, unlock and logout')
