-- Execute the real preset command branch, including save/reload and feedback.
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local a=assert(source:find("    if command == 'legacy' or command == 'default'",1,true))
local b=assert(source:find("    elseif command == 'rendertrace'",a,true))
local lines,saves,reloads={},0,0
local settings={ControllerProfile='ps5-directinput',ControllerDevice=2}
local env=setmetatable({settings=settings,config={save=function(s)assert(s==settings);saves=saves+1 end},
    graceful_restart=function(unload)assert(unload==false);reloads=reloads+1 end,
    chat_format={say=function(_,s)lines[#lines+1]=s end}},{__index=_G})
local command=assert(load('return function(command,...)\n'..source:sub(a,b-1)..'\nend\nend','preset command','t',env))()
for _,name in ipairs({'default','legacy','me'})do command(name) end
assert(lines[1]=='[XIVCrossbar] Default reloading')
assert(lines[2]=='[XIVCrossbar] Legacy reloading')
assert(lines[3]=='[XIVCrossbar] Me reloading')
assert(saves==3 and reloads==3 and settings.ControllerDevice==2)
for _,line in ipairs(lines)do assert(not line:find('[\128-\255]'),'preset feedback must stay ASCII')end
command('me','extra');assert(saves==3 and reloads==3,'invalid syntax cannot reload')
print('Preset commands: exact capitalized ASCII feedback, preserved device and single save/reload passed.')
