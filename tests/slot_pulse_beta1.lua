-- Public prototype: the personal companion pulse is layered above legacy flash.
local now=10
local p=require('slot_pulse').new(function()return now end)
p:press(1,2,1);assert(p:alpha(2,1)==180)
p:press(2,2,2);assert(p:alpha(2,2)==180,'independent second press')
now=10.07;assert(p:alpha(2,1)>72 and p:alpha(2,1)<180,'pressed settling')
p:release(1);now=10.10
local release=p:alpha(2,1);assert(release>0 and release<180,'first slot fades separately')
assert(p:alpha(2,2)>0,'second held slot unaffected')
now=10.25;assert(p:alpha(2,1)==0,'released slot expires')
assert(p:alpha(2,2)==72,'held slot settles')
p:cancel();assert(p:alpha(2,2)==0,'cancellation clears all')
local f=assert(io.open('ui.lua','rb'));local ui=f:read('*a');f:close()
f=assert(io.open('xivcrossbar.lua','rb'));local root=f:read('*a');f:close()
local defs=require('defaults');local theme=require('theme')
assert(defs.SlotPulse.Enabled==true and theme.apply(defs).slot_pulse_enabled==true)
for _,token in ipairs({'function ui:press_slot_pulse(hotbar,slot)','function ui:release_slot_pulse(slot)','function ui:show_slot_pulse()','self.pulse_visible_bars[h]=shouldDrawThisBar','function ui:set_slot_pulse_enabled(enabled)','self.slot_pulse:cancel()'}) do assert(ui:find(token,1,true),'ui missing '..token) end
for _,token in ipairs({'ui:press_slot_pulse(player.hotbar_settings.active_hotbar,slot)','ui:release_slot_pulse(released_slot)','ui:show_slot_pulse()','if command == \'slotpulse\' then'}) do assert(root:find(token,1,true),'root missing '..token) end
print('Public layered slot pulse: independent simultaneous buttons, press, release, cancel, setup and command wired.')
