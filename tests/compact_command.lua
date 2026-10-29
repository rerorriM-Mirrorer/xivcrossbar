-- Run the real root command handler with dependency spies. Drafts, bindings,
-- chooser state and input state must remain untouched by a layout-only command.
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local block=assert(source:match('(local function set_compact_mode%(mode%).-\nend)\n'))
local settings={iscompact=false,VisibilityMode='oninput',CrossbarScale=.6,Style={OffsetX=13,OffsetY=17}}
local draft={name='Preserve me',command='input /echo untouched'}
local bindings={Basic={slot='Bow'}}
local chooser={capturing=true,selected='Basic'}
local gamepad={left_trigger=true,right_trigger=false}
local saves,moves,messages,dirty=0,0,{},false
local ui={is_setup=true,set_compact=function(self,value) self.compact=value end,
    get_set_chooser_anchor=function() return 51,61 end}
local theme_options={is_compact=false}
local env_chooser={set_anchor=function(_,x,y) chooser.x,chooser.y=x,y end}
local windower={add_to_chat=function(_,message) messages[#messages+1]=message end}
local config={save=function(value) assert(value==settings);saves=saves+1 end}
local crossbar_drag={finish=function() moves=moves+1 end}
local env=setmetatable({settings=settings,theme_options=theme_options,ui=ui,
    env_chooser=env_chooser,windower=windower,config=config,crossbar_drag=crossbar_drag,chat_format={say=function(_,message) messages[#messages+1]=message end}}, {__index=_G})
local handler=assert(load(block..'\nreturn set_compact_mode','compact handler','t',env))()
handler(nil);assert(settings.iscompact and theme_options.is_compact and ui.compact)
handler('ON');assert(settings.iscompact)
handler('off');assert(not settings.iscompact)
handler('invalid');assert(not settings.iscompact and saves==3 and moves==3)
assert(messages[4]:find('//xb compact',1,true))
assert(settings.VisibilityMode=='oninput' and settings.CrossbarScale==.6)
assert(settings.Style.OffsetX==13 and settings.Style.OffsetY==17)
assert(draft.name=='Preserve me' and draft.command=='input /echo untouched')
assert(bindings.Basic.slot=='Bow' and chooser.capturing and chooser.selected=='Basic')
assert(gamepad.left_trigger and not gamepad.right_trigger)
assert(chooser.x==51 and chooser.y==61 and env.ui_dirty==true)
ui.is_setup=false
handler(nil);assert(settings.iscompact)
print('Compact command toggle, explicit states, validation and state-preservation checks passed.')
