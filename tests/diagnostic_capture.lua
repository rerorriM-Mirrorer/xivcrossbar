local clock,files,removed,reports,marks,stops,requests=0,{},{},{},0,0,0
local write_ok,begin_ok,render_ok=true,true,true
local C=require('libs/controller/capture').new({directory='diagnostics/',clock=function()return clock end,
 identity=function()return 'Test-session'end,mkdir=function()end,
 snapshot=function()return 'status=ready\n'end,
 begin=function(id,path)files[path]='Lua data\n';files['diagnostics/'..id..'-ahk.log']='AHK data\n';return begin_ok,'not ready'end,
 stop=function()stops=stops+1 end,request_stop=function()requests=requests+1 end,
 render=function()if not render_ok then error('render assembly failure') end;return 'Render data\n'end,mark=function()marks=marks+1 end,
 read=function(p)return files[p]end,remove=function(p)removed[p]=true;files[p]=nil end,
 write=function(p,s)if write_ok then files[p]=s end;return write_ok,'disk full'end,
 report=function(s)reports[#reports+1]=s end})
assert(C:command() and C.active);local path=C.path
assert(C:command('on') and C.path==path,'duplicate start replaced capture')
C:command('mark');assert(marks==1)
clock=31;C:tick();assert(C.active)
clock=32;C:tick();assert(not C.active and stops==1)
local body=assert(files[path]);for _,s in ipairs({'Status at start','Status at finish','Lua data','AHK data','Render data'})do assert(body:find(s,1,true))end
assert(removed[C.lua] and removed[C.ahk])
assert(C:command('on'));local second=C.path;assert(second~=path)
C:command('off');assert(C.active and requests==1)
clock=32.7;C:tick();assert(C.active)
clock=33;C:tick();assert(not C.active and files[second])
assert(C:command('on'));write_ok=false;C:finish('manual')
assert(not C.active and files[C.lua] and files[C.ahk],'failed report deleted source logs')
begin_ok=false;assert(not C:command('on') and not C.active)
begin_ok=true;render_ok=false;assert(C:command('on'))
assert(not C:finish('test') and files[C.lua] and files[C.ahk],'assembly failure destroyed source logs')
assert(not C:command('bad'))
print('Unified diagnostics: start/end status, same-session Lua/AHK/render, deadline, aliases, flush grace, unique reports and failed-save source preservation passed.')
