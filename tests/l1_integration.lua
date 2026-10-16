-- Execute the actual root context/receive/publish function with mocked I/O.
local now=10
local files={}
local settings={ControllerProfile='ps5-extended',L1=require('l1_bank').defaults()}
local sent={}
local bank=require('l1_bank').new({settings=settings,clock=function()return now end,
    save=function()end,say=function()end,execute=function(s)sent[#sent+1]=s end})
local bridge=require('l1_transport').new({session='integration',wallclock=function()return 100 end,
    event=function(kind,slot)bank:event(kind,slot)end,cancel=function()bank.held=false end})
local context,focused='gameplay',true
local info={logged_in=true};local character={status=0}
local env=setmetatable({settings=settings,l1_clock=function()return now end,l1_bank=bank,l1_bridge=bridge,
    l1_epoch=0,l1_last_tick=0,l1_next_read=0,restart_pending=false,xivcrossbar={ready=true},
    player={server='Fenrir',name='Test'},input_context=function()return context end,
    personal_controls={close=function()end,update=function(_,directory,name,profile,mode,l1)env_lease=l1;env_context=mode end},
    windower={addon_path='addon/',has_focus=function()return focused end,
        ffxi={get_info=function()return info end,get_player=function()return character end}},
    io={open=function(path)
        if files[path] then return {read=function()return files[path]end,close=function()end} end
    end}}, {__index=_G})
local f=assert(io.open('xivcrossbar.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('publish_personal_context = function()',1,true))
local b=assert(source:find("windower.register_event('keyboard'",a,true))
assert(load(source:sub(a,b-1),'actual root L1 bridge','t',env))()
local path='addon/data/personal-controls/Test.l1'
local function step()now=now+.03;env.publish_personal_context()end
local function packet(body,token)
    files[path]='token='..(token or bridge.token)..'\nstamp=100\n'..body..'END\n'
end
step();local keyboard_token=bridge.token
packet('1,show,0\n2,release,0\n3,tap,0\n4,slot,1\n');step()
assert(bank:mode()=='bank' and bridge.token~=keyboard_token and #sent==0)
assert(env_lease.mode=='bank' and env_lease.token==bridge.token and env_lease.ack==0)
assert(bank:command({'1','Test','input','/echo','hello'}))
packet('1,show,0\n2,slot,1\n3,release,0\n');step();assert(#sent==1 and not bank.held)
step();assert(#sent==1,'same mailbox replayed')
local prior=bridge.token
packet('4,show,0\n5,slot,1\n');info.menu_open=true;step()
assert(bridge.token==nil and #sent==1)
info.menu_open=false;step();assert(bridge.token~=prior and #sent==1)
prior=bridge.token
packet('1,show,0\n2,slot,1\n');focused=false;step()
focused=true;step();assert(bridge.token~=prior and #sent==1)
prior=bridge.token
packet('1,show,0\n2,slot,1\n');now=now+1;step()
assert(bridge.token~=prior and #sent==1,'render stall replayed pending input')
context='crossbar';step();assert(bridge.token==nil)
context='gameplay';step();packet('1,show,0\n2,slot,1\n');character.status=4;step()
assert(bridge.token==nil and #sent==1)
info.chat_open=true;context='gameplay';character.status=0;step()
assert(env_context=='text' and bridge.token==nil)
print('Actual root L1 bridge: mode acknowledgments, once-only dispatch, menu/chat/focus/cutscene/trigger guards and render-stall invalidation passed.')
