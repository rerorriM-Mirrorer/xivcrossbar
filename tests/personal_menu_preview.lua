-- Personal in-menu display preview and trigger-neutral ownership.
local f=assert(io.open('ui/action_binder.lua','rb'));local b=f:read('*a');f:close()
local a=assert(b:find('function action_binder:get_binding_preview_bank()',1,true))
local e=assert(b:find('function action_binder:is_in_selector_state()',a+1,true))
local states={SELECT_BUTTON_ASSIGNMENT=3,CONFIRM_BUTTON_ASSIGNMENT=4}
local binder={is_hidden=false,chooser_active=false,state=3,active_crossbar=4,theme_options={combined_trigger_bank=true}}
assert(load(b:sub(a,e-1),'actual personal binder preview','t',setmetatable({action_binder=binder,states=states},{__index=_G})))()
assert(binder:get_binding_preview_bank()==3)
binder.theme_options.combined_trigger_bank=false;assert(binder:get_binding_preview_bank()==4)
binder.state=4;assert(binder:get_binding_preview_bank()==4)
binder.state=0;assert(binder:get_binding_preview_bank()==nil)
binder.state=3;binder.chooser_active=true;assert(binder:get_binding_preview_bank()==nil)
local file=assert(io.open('ui/crossbar.lua','rb'));local ui=file:read('*a');file:close()
file=assert(io.open('xivcrossbar.lua','rb'));local root=file:read('*a');file:close()
for _,needle in ipairs({'local active_bar=menu_open and (preview_bank or 0)','gamepad_state.menu_trigger_hold and 0 or gamepad_state.active_bar','field:color(255,216,112)','self.hotbars[h].slot_icon[i]:color(shade,shade,shade)'}) do assert(ui:find(needle,1,true),'UI missing '..needle) end
for _,needle in ipairs({'local menu_open = crossbar_menu_open()','action_binder:get_binding_preview_bank()','if gamepad_state.menu_trigger_hold or crossbar_menu_open() then return true end','gamepad_state.menu_trigger_hold=true'}) do assert(root:find(needle,1,true),'root missing '..needle) end
print('Personal menu preview binder/five-bank/source ownership checks passed.')
