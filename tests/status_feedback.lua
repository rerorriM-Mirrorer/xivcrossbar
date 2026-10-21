-- State and feedback checks: a single edit must not dump unrelated bindings;
-- diagnostics must distinguish configured input from the running wrapper.
local Banks=require('libs/banks/banks')
local lines,saves={},0
local b=Banks.new({settings={},clock=function()return 1 end,context=function()return true,false end,
    save=function()saves=saves+1 end,execute=function()error('feedback executed action')end,
    ordinary=function()end,say=function(s)lines[#lines+1]=s end,help=function()end})
for _,cmd in ipairs({{'r1','menus','on'},{'l1','menuactions','off'},
    {'l1l2','cross','Quests','input /quest'},{'r1','pos','100','200'},
    {'r1r2','hide'},{'r1','edit','on'},{'r1','edit','off'},
    {'swap','l1','r1'},{'l1','menu','clear','up'}}) do
    lines={};assert(b:command(cmd));assert(#lines==1,'setting dumped status: '..table.concat(cmd,' '))
    assert(not lines[1]:find('native ack',1,true) and not lines[1]:find('Closed:',1,true))
end
assert(saves==9)
lines={};b:command({'l1','status'});assert(#lines==5)
assert(not table.concat(lines,'\n'):find('Menu bindings',1,true))
lines={};b:command({'l1','status','details'});assert(#lines>16)
assert(table.concat(lines,'\n'):find('Menu bindings',1,true))
local fmt=require('libs/chat_status')
local o={settings={ControllerProfile='ps5-extended',ControllerDevice=1,ControllerMessages=true},
    bridge={received=0,rejected=0},modifier='apps'}
local s=table.concat(fmt.controller(o),'\n')
assert(s:find('active unknown | requested messages',1,true),'stopped wrapper presented as active route')
o.status={running=true,profile='ps5-extended',device='1',connected='0',state='waiting-neutral',button_route='neutral'}
s=table.concat(fmt.controller(o),'\n')
assert(s:find('connected OFF',1,true) and s:find('active neutral',1,true))
assert(s:find('Restart the updated AHK wrapper for messages, banks, hold recovery, Trust menu.',1,true))
local original=string.color
string.color=function(value,id)return '['..id..']'..value end
assert(fmt.heading('Status')=='[140]--- [167]Status[140] ---')
assert(fmt.row('Mode','Ready')=='[207]  Mode[200] -> [0]Ready')
assert(fmt.notice('Saved')=='[200]//xb[200] -> [0]Saved')
string.color=original
print('Status feedback: single-line edits/swaps, explicit full bindings, stopped/neutral route truth and help palette passed.')
