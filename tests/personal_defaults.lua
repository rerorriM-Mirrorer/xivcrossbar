local defaults=require('defaults')
assert(defaults.ControllerProfile=='ps5-extended')
assert(defaults.GameplayDPad=='ijkl' and defaults.VisibilityMode=='oninput')
assert(defaults.iscompact and defaults.enable_superwarp_all and defaults.on_unload_killahk)
local profiles=require('controller_profiles')
assert(profiles.validate(defaults.ControllerProfile,defaults.ControllerDevice)=='ps5-extended')
for _,id in ipairs(profiles.order) do assert(id~='ps5-extended') end
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
assert(not source:find('settings.on_unload_killahk = false',1,true),'preference overwritten')
assert(source:find('default_profile=defaults.ControllerProfile',1,true),'wizard default missing')
assert(not source:match("register_event%('unload'.-on_unload_killahk"),'new shutdown behavior not authorized here')
local function text()
 return setmetatable({},{__index=function(_,key)
  return function(self,...)
   if select('#',...)>0 then self[key..'_value']={...} end
  end
 end})
end
package.loaded.texts={new=text}
windower={register_event=function() end,prim=setmetatable({},{__index=function() return function() end end})}
local mapper=require('gamepad_mapper')
mapper.width=800;mapper.base_x=0;mapper.base_y=0;mapper.profile_buttons={}
mapper.title=text();mapper.subtitle=text();mapper.profile_status=text()
mapper.hide_text=function() end;mapper.hide_images=function() end;mapper.create_text=function() return text() end
mapper.profile_options={default_profile=defaults.ControllerProfile}
mapper:display_profile_selector()
assert(mapper.profile_buttons[1].id=='ps5-extended')
assert(mapper.profile_buttons[2].id=='xinput')
mapper.profile_options.default_profile='ps5-directinput'
mapper:display_profile_selector()
assert(mapper.profile_buttons[1].id=='ps5-directinput','public selection changed or old ID retained')
print('Fresh personal defaults, persistent shutdown preference and private/public setup choices passed.')
