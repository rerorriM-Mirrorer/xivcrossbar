local Bridge=require('libs/controller/trust_menu')
local now=100
local commands={}
local mapping={confirm_button='cross',cancel_button='circle'}
local bridge=Bridge.new({clock=function()return now end,execute=function(c)commands[#commands+1]=c end})
local function lease(token,mode,stamp,id)
    return string.format('trust-menu1\n%d\n%s\n%s\n%.6f\nEND\n',id or 42,token or 'session-1',mode or 'navigation',stamp or now)
end
bridge:update(lease(),42)
assert(bridge:edge(1,true,mapping) and #commands==1)
assert(commands[1]:find('lua c trust __controller session%-1 1 100%.000000 up'))
assert(bridge:edge(1,true,mapping) and #commands==1,'duplicate physical down repeated')
now=100.39;bridge:update(lease(),42);bridge:tick();assert(#commands==1)
now=100.4;bridge:update(lease(),42);bridge:tick();assert(#commands==2)
now=110;bridge:update(lease(),42);bridge:tick();assert(#commands==3,'overdue repeats replayed')
bridge:update(lease('session-2'),42);bridge:tick();assert(#commands==3)
assert(bridge:edge(1,true,mapping) and #commands==3,'hold transferred into new context')
assert(bridge:edge(1,false,mapping));assert(bridge:edge(1,true,mapping));assert(#commands==4)
bridge:edge(1,false,mapping)
bridge:update(nil,42);assert(bridge.token=='session-2','rename gap lost fresh lease')
bridge:update('partial file',42);assert(bridge.token=='session-2')
now=111;bridge:update(nil,42);assert(not bridge.token,'expired lease retained ownership')
assert(not bridge:edge(1,true,mapping))
bridge:update(lease(nil,nil,nil,43),42);assert(not bridge.token,'other client accepted')
bridge:update(lease(nil,nil,now+2),42);assert(not bridge.token,'future lease accepted')
bridge:update(lease('text-1','text'),42)
local before=#commands
bridge:edge(2,true,mapping);bridge:edge(2,false,mapping);assert(#commands==before)
bridge:edge(5,true,mapping);bridge:edge(5,false,mapping);assert(commands[#commands]:find(' confirm$'))
bridge:edge(7,true,mapping);bridge:edge(7,false,mapping);assert(commands[#commands]:find(' back$'))
bridge:edge(6,true,mapping,true);bridge:edge(6,false,mapping);assert(commands[#commands]:find(' close$'))
bridge:edge(14,true,mapping);bridge:update(lease('text-2','text'),42)
bridge:edge(6,true,mapping);bridge:edge(6,false,mapping);assert(commands[#commands]:find(' close$'),'held R1 lost across a focus change')
bridge:edge(14,false,mapping)
bridge:update(lease('pause-1','paused'),42);before=#commands
for b=1,8 do assert(bridge:edge(b,true,mapping));bridge:edge(b,false,mapping) end
assert(#commands==before,'paused controller input leaked')
bridge:update(lease('nav-3'),42);bridge:edge(1,true,mapping)
bridge:reset();before=#commands;bridge:edge(1,true,mapping);assert(#commands==before+1,'receiver neutral reset left a stuck block')
bridge:update(lease('nav-3','closed'),42);assert(not bridge.token)
assert(bridge:edge(1,false,mapping),'owned release escaped after close')
for _,command in ipairs(commands) do assert(not command:find('setkey') and not command:find('input /')) end
print('Trust controller bridge: directional repeat, ownership through close/focus changes, complete/fresh/character-scoped leases, text/chat masking, direct command delivery and neutral recovery passed.')
