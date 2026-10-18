local files={};local now=1;local writes=0
local function open(path)
    local value=''
    return {write=function(_,s)value=s;writes=writes+1;return true end,
        close=function()files[path]=value;return true end}
end
local fail=false
local lease=require('personal_controls').new({clock=function()return now end,open=open,
    create_dir=function()end,remove=function(p)files[p]=nil;return true end,
    rename=function(a,b)if fail then return nil end;files[b]=files[a];files[a]=nil;return true end})
local path='data/Test.ini'
assert(lease:update('data/','Test','ps5-extended','gameplay',{token='one',mode='keyboard',ack=0}))
assert(files[path]:find('l1token=one',1,true) and files[path]:find('l1ack=0',1,true))
assert(files[path]:find('dpad_output=lua\n',1,true))
assert(files[path]:find('r1_menus=0\n',1,true))
assert(not files[path..'.tmp'])
assert(files[path]:find('target_r2=0\ntarget_r3=0\nbutton_mode=keys\n',1,true))
assert(lease:update('data/','Test','ps5-extended','gameplay',{token='one',mode='keyboard',ack=0}) and writes==1)
assert(lease:update('data/','Test','ps5-extended','gameplay',{token='one',mode='keyboard',ack=2}) and writes==2)
assert(lease:update('data/','Test','ps5-extended','gameplay',{token='one',mode='keyboard',ack=2,target_r2=true,target_r3=true}) and writes==3)
assert(files[path]:find('target_r2=1\ntarget_r3=1\nbutton_mode=keys\n',1,true))
assert(lease:update('data/','Test','ps5-extended','gameplay',{token='one',mode='keyboard',ack=2,
    messages=true,button_token='buttons-1',button_ack=17}))
assert(files[path]:find('button_mode=messages\nbutton_token=buttons-1\nbutton_ack=17\nEND\n',1,true))
assert(lease:update('data/','Test','ps5-extended','gameplay',{token='one',mode='keyboard',ack=2,
    messages=true,button_token='buttons-1',button_ack=17,realkeys=true}))
assert(files[path]:find('dpad_output=ahk\n',1,true),'permission change must publish immediately')
assert(lease:update('data/','Test','ps5-extended','gameplay',{r1_menus=true}))
assert(files[path]:find('r1_menus=1\n',1,true))
fail=true
assert(not lease:update('data/','Test','ps5-extended','text',{token='two',mode='bank',ack=0}))
assert(not files[path] and not files[path..'.tmp'])
files['data/Test.l1']='stale';files['data/Test.buttons']='stale';files['data/Test.buttons.tmp']='partial'
lease:close();assert(not files['data/Test.l1'] and not files['data/Test.buttons'] and not files['data/Test.buttons.tmp'])
assert(not lease:update('data/','../Bad','ps5-extended','gameplay'))
print('Personal lease: complete publication, immediate ack updates, write throttling, failed-swap safety and mailbox cleanup passed.')
