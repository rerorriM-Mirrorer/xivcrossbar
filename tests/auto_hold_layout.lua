-- Exercise the production visibility/display selection block across input edges.
local f=assert(io.open('xivcrossbar.lua'))
local source=f:read('*a');f:close()
local first=assert(source:find('    local held = gamepad_state.left_trigger',1,true))
local last=assert(source:find('    if ui.is_setup and ui.public_visible',first,true))
local clock=0
local env=setmetatable({
 visibility=require('visibility'),visibility_mode='oninput',focused=true,menu_open=false,
 settings={AutoHold=1.5,Animation={TriggerScale=false,SmallScale=.95}},
 gamepad_state={active_bar=0},xivcrossbar={hide_hotbars=false},
 profile_clock=function()return clock end,
 windower={ffxi={get_info=function()return{chat_open=false}end}},
 action_binder={is_moving_crossbars=function()return false end},
 env_chooser={is_showing=function()return false end},
 crossbar_drag={finish=function()end},
 ui={is_setup=true,auto_hold={},display_bank=0,
 geometry={is_startup_reveal_pending=function()return false end},
 select_display_bank=function(self,bank)self.display_bank=bank;return bank end,
 update_trigger_scale=function()end},
},{__index=_G})
local draw=assert(load(source:sub(first,last-1)..'return visible,display_bank','Auto hold layout','t',env))
for _, bank in ipairs({1,2,3,4,5,6,7,8,9}) do
 env.ui.auto_hold={}
 env.gamepad_state={active_bar=bank,left_trigger=bank<7,shoulder_display=bank>=7 and bank or nil}
 local visible,selected=draw()
 assert(visible and selected==bank)
 clock=clock+.1
 env.gamepad_state={active_bar=0}
 visible,selected=draw()
 assert(visible and selected==0,'release must restore ordinary idle bars during Auto hold')
 clock=clock+.5
 env.gamepad_state={active_bar=2,right_trigger=true}
 visible,selected=draw()
 assert(visible and selected==2,'fresh input must override the idle hold')
 clock=clock+.1;env.gamepad_state={active_bar=0};draw()
 clock=clock+1.51
 visible,selected=draw()
 assert(not visible and selected==0)
end
print('Auto hold restores idle layout for all nine banks, accepts fresh input, and expires.')
