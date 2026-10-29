-- Source formatting tests: app sends assembled chat lines, not console output.
local logs={}
windower={add_to_chat=function(channel,line)
    assert(channel==0,'Always emit colored chat on channel 0')
    logs[#logs+1]=line
end}
-- Windower chat library installs string.color; supply a visible marker here.
string.color=function(self,number)
    return string.format('{%d}%s',number,tostring(self))
end
local status=require('libs/chat_status')
local help=require('libs/chat_help')
help.heading('XIVCrossbar | Commands')
assert(logs[#logs]:find('{200}XIVcrossbar',1,true),'Heading title missing purple')
help.command('compact [on|off]','Toggle compact layout')
local h=logs[#logs]
assert(h:find('{200}//xb',1,true) and h:find('{207} compact [on|off]',1,true)
    and h:find('{200} -> ',1,true) and h:find('{0}Toggle compact layout',1,true))
status.say(207,'[XIVCrossbar] Fades: ON')
assert(logs[#logs]:find('{200}[XIVcrossbar]',1,true))
assert(logs[#logs]:find('{207}Fades:',1,true))
assert(logs[#logs]:find('{158}ON',1,true))
status.say(123,'[XIVCrossbar] Cannot save crossbar data')
assert(logs[#logs]:find('{167}Cannot save',1,true))
status.say(207,'[XIVCrossbar] Bound "Cure" to R2 + Cross - Basic Crossbar.')
assert(logs[#logs]:find('{0}"Cure"',1,true) and logs[#logs]:find('{0}R2 + Cross',1,true))
status.say(123,'XIVCROSSBAR: Invalid slot.')
assert(logs[#logs]:find('{167}Invalid slot.',1,true))
status.say(0,status.row('Set','Basic'))
assert(logs[#logs]:find('{207}  Set:',1,true) and logs[#logs]:find('{0}Basic',1,true))
-- Keep console-only errors out of production; debug/test logging is separate.
for _,path in ipairs({'xivcrossbar.lua','action_binder.lua','player.lua','gamepad_converter.lua'}) do
    local file=assert(io.open(path,'rb'))
    local source=file:read('*a');file:close()
    assert(not source:find("print('XIVCROSSBAR:",1,true),'Console-only user error in '..path)
end
for _,path in ipairs({'action_binder.lua','player.lua'}) do
    local file=assert(io.open(path,'rb'))
    local source=file:read('*a');file:close()
    assert(source:find("require('libs/chat_status')",1,true),'No shared formatter in '..path)
end
print('Color formatting: headings, command syntax, values, green ON, error, binding, field rows and chat-only output passed.')
