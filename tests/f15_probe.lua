local events, sent, chat = {}, {}, {}
_addon={}
windower={register_event=function(name,fn) events[name]=fn end,
    add_to_chat=function(_,message) chat[#chat+1]=message end,
    send_command=function(command) sent[#sent+1]=command end}
dofile('tools/keyprobe/xbkeyprobe/xbkeyprobe.lua')
local command,key=events['addon command'],events.keyboard
command('on')
assert(key(102,true,0,false)==nil and #sent==0,'observer does not act')
key(102,false,0,false)
command('f15','input','/echo','F15 received')
assert(key(102,true,0,false)==true)
key(102,true,0,false)
assert(#sent==1 and sent[1]=='input /echo F15 received','repeat is not another action')
key(102,false,0,false)
key(102,true,0,true)
assert(#sent==1,'already-blocked event stays blocked')
key(102,false,0,false)
command('f15','echo','Another test')
key(102,true,0,false)
assert(#sent==2 and sent[2]=='echo Another test')
key(102,false,0,false)
command('f15','off')
assert(key(102,true,0,false)==nil and #sent==2,'test is removable')
assert(key(101,true,0,false)==nil,'other spare keys are untouched')
print('Optional F15 routing, repeat suppression, blocked events and removal passed.')
