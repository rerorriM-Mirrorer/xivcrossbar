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

local label_block=assert(source:match("(    if command == 'banklabels'.-)    if command == 'textfade'"))
settings.Texts={BankLabels=true,SlotLabelStroke='black'}
ui.set_bank_labels_visible=function(self,visible) self.labels=visible end
ui.set_slot_label_stroke=function(self,stroke) self.stroke=stroke end
local function label_command(command,...)
    local handler=assert(load('local command, args = ...\n'..label_block,'label commands','t',env))
    handler(command,{...})
end
local before=saves
label_command('banklabels')
assert(not settings.Texts.BankLabels and not theme_options.bank_labels_visible and not ui.labels)
label_command('banklabels','status')
assert(saves==before+1)
label_command('banklabels','on')
assert(settings.Texts.BankLabels and theme_options.bank_labels_visible and ui.labels)
label_command('slotlabelstroke','amber')
assert(settings.Texts.SlotLabelStroke=='amber' and theme_options.slot_label_stroke=='amber' and ui.stroke=='amber')
label_command('slotlabelstroke','invalid')
assert(saves==before+3 and ui.stroke=='amber')
print('Bank label visibility and slot outline commands save and validate independently.')

ui.set_bank_label_offset=function(self,x,y) self.bank_x,self.bank_y=x,y end
ui.set_bank_label_opacity=function(self,opacity) self.bank_opacity=opacity end
ui.set_slot_label_layout=function(self,align,x,y) self.slot_align,self.slot_x,self.slot_y=align,x,y end
before=saves
label_command('banklabeloffset','3','-9')
assert(settings.Texts.BankLabelOffsetX==3 and settings.Texts.BankLabelOffsetY==-9 and ui.bank_y==-9)
label_command('slotlabeloffset','0','6')
label_command('slotlabelalign','center')
assert(settings.Texts.SlotLabelAlign=='center' and ui.slot_align=='center' and ui.slot_y==6)
label_command('banklabelopacity','160')
assert(settings.Texts.BankLabelOpacity==160 and ui.bank_opacity==160)
label_command('banklabelopacity','256')
label_command('slotlabeloffset','invalid','4')
assert(saves==before+4 and ui.slot_y==6 and ui.bank_opacity==160)
print('Label layout and opacity commands save and validate independently.')
