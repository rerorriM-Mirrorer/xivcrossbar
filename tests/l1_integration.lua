-- Execute the actual root context/receive/publish function with mocked I/O.
local now=10
local files={}
local settings={ControllerProfile='ps5-extended',L1=require('libs/banks/legacy').defaults()}
local sent={}
local bank=require('libs/banks/legacy').new({settings=settings,clock=function()return now end,
    save=function()end,say=function()end,execute=function(s)sent[#sent+1]=s end})
local bridge=require('libs/banks/legacy_transport').new({session='integration',wallclock=function()return 100 end,
    event=function(kind,slot)bank:event(kind,slot)end,cancel=function()bank.held=false end})
local context,focused='gameplay',true
local info={logged_in=true};local character={status=0}
local env=setmetatable({input_timing={tick=function()end},settings=settings,l1_clock=function()return now end,l1_bank=bank,l1_bridge=bridge,
    message_epoch=0,controller_message_bridge=require('libs/controller/messages').new({session='buttons-test',
        clock=function()return now end,wallclock=function()return 100 end,
        cancel=function()end,capture=function()end,event=function()end}),
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
packet('1,show,0\n2,bank,0\n3,slot,1\n4,release,0\n');step()
assert(bank:mode()=='bank' and bridge.token==keyboard_token and #sent==0)
assert(env_lease.mode=='bank' and env_lease.token==bridge.token and env_lease.ack==4)
assert(bank:command({'1','Test','input','/echo','hello'}))
packet('5,bank,0\n6,slot,1\n7,release,0\n');step();assert(#sent==1 and not bank.held)
step();assert(#sent==1,'same mailbox replayed')
local prior=bridge.token
packet('8,bank,0\n9,slot,1\n');info.menu_open=true;step()
assert(bridge.token==nil and #sent==1)
info.menu_open=false;step();assert(bridge.token~=prior and #sent==1)
prior=bridge.token
packet('1,bank,0\n2,slot,1\n');focused=false;step()
focused=true;step();assert(bridge.token~=prior and #sent==1)
prior=bridge.token
packet('1,bank,0\n2,slot,1\n');now=now+1;step()
assert(bridge.token~=prior and #sent==1,'render stall replayed pending input')
prior=bridge.token
files[path]=nil;context='crossbar';step();assert(bridge.token==prior,'ordinary trigger transition reset session')
context='gameplay';step();assert(bridge.token==prior)
packet('1,bank,0\n2,slot,1\n');character.status=4;step()
assert(bridge.token==nil and #sent==1)
info.chat_open=true;context='gameplay';character.status=0;step()
assert(env_context=='text' and bridge.token==nil)
-- The ordinary message stream has its own token: native menus suppress the
-- companion but must not disable controller menu navigation or trigger releases.
settings.ControllerMessages=true;info.chat_open=false;info.menu_open=false;character.status=0
step();local messages=env.controller_message_bridge;local message_token=messages.token
assert(env_lease.messages and env_lease.button_token==message_token)
info.menu_open=true;step();assert(bridge.token==nil and messages.token==message_token)
assert(env_lease.r1_menus,'native menu revoked direct R1 permission')
files['addon/data/personal-controls/Test.buttons']='token='..message_token..'\nstamp=100\nbeat=10\n1,down,11\nEND\n'
step();assert(messages.captured and env_lease.button_ack==1)
focused=false;step();assert(messages.token==nil and not messages.captured)
focused=true;step();assert(messages.token~=message_token and not messages.captured)
message_token=messages.token;now=now+1;step();assert(messages.token~=message_token and messages.ack==0)
settings.ControllerMessages=false;step();assert(not env_lease.messages and messages.token==nil)
settings.ControllerRealKeys=true;settings.GameplayDPad='ijkl';settings.InputTest=false
step();assert(not env_lease.realkeys,'real output without message session')
settings.ControllerMessages=true;step();assert(env_lease.realkeys)
info.menu_open=true;step();assert(bridge.token==nil and env_lease.realkeys,'native menu disabled IJKL')
settings.InputTest=true;step();assert(not env_lease.realkeys)
assert(not env_lease.r1_menus,'input test authorized real R1 commands')
settings.InputTest=false;settings.GameplayDPad='arrows';step();assert(not env_lease.realkeys)
settings.GameplayDPad='ijkl';focused=false;step();assert(not env_lease.realkeys)
focused=true;character.status=4;step();assert(not env_lease.realkeys)
character.status=0;step();assert(env_lease.realkeys)
settings.ControllerRealKeys=false;step();assert(not env_lease.realkeys)
print('Actual root L1 bridge: ordered layers, stable ordinary-trigger sessions, once-only dispatch and menu/chat/focus/cutscene/stall guards passed.')
-- Feed the full bank receiver through that same actual publish/read/lease path.
settings.ControllerMessages=true;settings.InputTest=false;character.status=0;focused=true;info.menu_open=false;context='gameplay'
local banks=require('libs/banks/banks').new({settings=settings,clock=function()return now end,
    context=function()return context=='gameplay',info.menu_open,character.status==4 end,ordinary=function()end,
    execute=function(s)sent[#sent+1]=s end,save=function()end,say=function()end,help=function()end})
require('tests/fixtures/bank_legacy')(banks)
env.companion_banks=banks
env.controller_message_bridge=require('libs/controller/messages').new({session='bank-root-test',clock=function()return now end,
    wallclock=function()return 100 end,cancel=function()banks:cancel()end,capture=function()end,
    physical=function(b,p)banks:edge(b,p)end,ready=function()banks.active=true end,key_ack=function(a)banks.output:accept(a)end})
step();messages=env.controller_message_bridge;message_token=messages.token
local function buttons(body,beat)
    files['addon/data/personal-controls/Test.buttons']='token='..messages.token..'\nstamp=100\nbeat='..beat..'\n'..body..'END\n'
    step()
end
buttons('1,banks,0\n2,down,13\n3,down,1\n4,up,1\n5,up,13\n',20)
assert(env_lease.banks and env_lease.native:find('d,ctrl+i',1,true) and env_lease.native:find('u,ctrl+i',1,true))
assert(env_lease.native_base==0 and env_lease.button_ack==5)
local output_token=env_lease.native_token
info.menu_open=true;step();assert(messages.token==message_token and env_lease.native_token~=output_token)
assert(env_lease.native=='' and env_lease.native_base==2 and env_lease.banks)
buttons('6,down,13\n7,down,1\n8,up,1\n9,up,13\n',21)
assert(env_lease.native:find('d,ctrl+left',1,true),'native-menu context did not reach the leased executor')
buttons('10,keyack,4\n',22);assert(env_lease.native=='' and env_lease.native_base==4)
info.menu_open=false;step();buttons('11,down,14\n12,down,1\n',23)
assert(env_lease.native:find('d,up',1,true))
now=now+.36;step();assert(messages.token~=message_token and env_lease.button_recover and banks.layer=='' and env_lease.native=='','native backlog did not replace and clear session')
print('Actual root bank pipeline: ordered mailbox -> Lua map -> native lease, menu-context generation change, output acknowledgment and overdue-session cancellation passed.')

-- The root must keep the negotiated stream alive only for opted-in scene banks.
settings.ControllerMessages=true;character.status=4;step();assert(not env_lease.messages)
assert(banks:command({'r1r2','cutscenes','on'}));step()
assert(env_lease.messages and env_context=='cutscene' and env_lease.banks)
local before=#sent
buttons('1,banks,0\n2,down,14\n3,down,12\n4,down,8\n5,up,8\n6,up,12\n7,up,14\n',100)
assert(#sent==before+1 and sent[#sent]=='npcmirror interact')
buttons('8,down,11\n9,down,5\n10,up,5\n11,up,11\n',101)
assert(#sent==before+1 and env_lease.native=='','ordinary native output leaked in a scene')
assert(banks:command({'r1r2','cutscenes','off'}));step();assert(not env_lease.messages)
character.status=0
print('Actual root cutscene lease: opt-in message lifetime, restricted context, NPC dispatch and off transition passed.')
local previous_token=messages.token
settings.ControllerProfile='xinput-extended';settings.ControllerRealKeys=true
settings.GameplayDPad='ijkl';step()
assert(env_lease.messages and env_lease.banks and env_lease.realkeys,'Xbox Extended did not negotiate the full stream')
assert(messages.token~=previous_token,'profile change reused old hardware session')
buttons('1,banks,0\n2,down,14\n3,down,8\n4,up,8\n5,up,14\n',200)
assert(sent[#sent]=='trust menu open','Xbox Extended bank failed through actual root publisher/receiver')
previous_token=messages.token;settings.ControllerDevice=2;step()
assert(messages.token~=previous_token,'device change reused old hardware session')
settings.ControllerProfile='xinput';step()
assert(messages.token==nil,'ordinary XInput retained message receiver')

-- Actual root Trust lease reader, wrapper-context publication and physical
-- callback. The old native output queue must remain empty for menu navigation.
info.server=1;info.chat_open=false;character.id=42;character.status=0;focused=true
settings.ControllerMessages=true;settings.ControllerProfile='ps5-extended';settings.InputTest=false
settings.ControllerRealKeys=true;settings.GameplayDPad='ijkl'
env.windower.windower_path='windower/'
env.action_binder={is_hidden=true};env.env_chooser={capturing=false,is_showing=function()return false end}
env.gamepad_mapper={is_showing=false}
local direct={}
env.buttonmapping={confirm_button='cross',cancel_button='circle'}
env.trust_menu=require('libs/controller/trust_menu').new({clock=function()return now end,
    execute=function(command)direct[#direct+1]=command end})
env.input_context=function()return env.trust_menu.token and 'trust' or 'gameplay' end
local callback=assert(source:match('(physical=function%(button,pressed%).-\n    end,)'))
callback=assert(load('return {'..callback..'}','actual Trust physical callback','t',env))().physical
env.controller_message_bridge=require('libs/controller/messages').new({session='trust-root-test',clock=function()return now end,
    wallclock=function()return 100 end,cancel=function()env.trust_menu:reset();banks:cancel()end,
    capture=function()end,physical=callback,ready=function()banks.active=true end})
local leasepath='windower/addons/trust/data/controller-menu-1-42.txt'
files[leasepath]=string.format('trust-menu1\n42\ntrust-root-1\nnavigation\n%.6f\nEND\n',now)
step();assert(env_context=='trust' and not env_lease.realkeys and env_lease.messages)
callback(1,true);callback(1,false);callback(5,true);callback(5,false)
assert(#direct==2 and direct[1]:find(' up$') and direct[2]:find(' confirm$'))
assert(#banks.output.pending==0,'Trust navigation requested a native key')
callback(14,true);callback(6,true);callback(6,false);callback(14,false)
assert(#direct==3 and direct[3]:find(' close$'))
info.chat_open=true
files[leasepath]=string.format('trust-menu1\n42\ntrust-root-2\npaused\n%.6f\nEND\n',now)
step();assert(env_context=='text');callback(1,true);callback(1,false);assert(#direct==3)
focused=false;step();assert(not env.trust_menu.token and not env_lease.messages)
print('Actual root Trust integration: character/server lease path, direct physical dispatch, wrapper context, no native output, R1 close and chat/focus guards passed.')
