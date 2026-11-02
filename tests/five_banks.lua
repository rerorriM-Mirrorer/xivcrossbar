-- Real theme, binder selection/hints and command conversion, no OS delivery.
local defaults=require('libs/defaults')
local original=defaults.Hotbar.Number
local converter=require('libs/controller/gamepad_converter')
local f=assert(io.open('ui/action_binder.lua'));local source=f:read('*a');f:close()
local binder={width=600,height=300,base_x=0,base_y=0,button_layout='playstation'}
local env=setmetatable({action_binder=binder,ui_resources={clear=function()end},L=function(t)
 return setmetatable(t,{__index={append=function(self,v)self[#self+1]=v end}})
end},{__index=_G})
local function method(name,nextname)
 local a=assert(source:find('function action_binder:'..name..'(',1,true))
 local b=assert(source:find('function action_binder:'..nextname..'(',a+1,true))
 assert(load(source:sub(a,b-1),'actual binder '..name,'t',env))()
end
method('update_active_crossbar','dpad_left')
method('show_pressed_buttons','confirm_buttons')
method('confirm_buttons','show_hint')
function binder:show_control_hints()end
local icons={};function binder:show_icon(path)icons[#icons+1]=path end
for _,count in ipairs({3,4,5,6}) do
 defaults.Hotbar.Number=count
 local options=require('ui/theme').apply(defaults)
 assert(options.hotbar_number==(count==5 and 6 or count))
 assert(options.combined_trigger_bank==(count==5))
 binder.theme_options=options;converter:setup('playstation',options.combined_trigger_bank)
 for _,order in ipairs({'left','right'}) do
  binder.trigger_left_pressed=true;binder.trigger_right_pressed=true
  binder:update_active_crossbar(order=='left',order=='right')
  assert(binder.active_crossbar==((count==3 or count==5 or order=='left') and 3 or 4))
 end
 for _,left in ipairs({true,false}) do
  binder.trigger_left_pressed=left;binder.trigger_right_pressed=not left
  binder.trigger_left_doublepressed=true;binder.trigger_right_doublepressed=true
  binder:update_active_crossbar(left,not left)
  assert(binder.active_crossbar==(count>=5 and (left and 5 or 6) or (left and 1 or 2)))
 end
 assert(converter:convert_to_crossbar('l2r2')==(count==5 and 3 or 4))
 assert(converter:convert_to_crossbar('r2l2')==3)
 assert(converter:convert_to_crossbar('ll')==5 and converter:convert_to_crossbar('rr')==6)
 assert(converter:convert_to_crossbar('4')==4,'explicit saved-bank ID must stay addressable')
 binder.active_crossbar=3
 for _,name in ipairs({'show_pressed_buttons','confirm_buttons'}) do
  icons={};binder[name](binder)
  assert(icons[2]=='ui/binding_icons/'..(count==5 and 'plus' or count>3 and 'arrow_right' or 'plus')..'.png')
 end
end
defaults.Hotbar.Number=original;converter:setup('playstation')
assert(converter:convert_to_crossbar('lr')==4,'switching to six banks retained shared command alias')
print('Five-bank theme/storage capacity, binder selection and hints, both trigger aliases, numeric ID preservation and mode roundtrips passed.')
