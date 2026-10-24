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
assert(not table.concat(lines,'\n'):find('Menu Bindings',1,true))
lines={};b:command({'l1','status','details'});assert(#lines>16)
assert(table.concat(lines,'\n'):find('Menu Bindings',1,true))
local fmt=require('libs/chat_status')
local o={settings={ControllerProfile='ps5-extended',ControllerDevice=1,ControllerMessages=true},
    bridge={received=0,rejected=0},modifier='apps'}
local s=table.concat(fmt.controller(o),'\n')
assert(s:find('Input: Unavailable',1,true),'stopped wrapper presented as active route')
o.status={running=true,profile='ps5-extended',device='1',connected='0',state='waiting-neutral',button_route='neutral'}
s=table.concat(fmt.controller(o),'\n')
assert(s:find('Connected: OFF',1,true) and s:find('Waiting for Messages',1,true))
assert(s:find('Restart the updated AHK wrapper for messages.',1,true))
assert(not s:find('Recovery',1,true) and not s:find('Trace',1,true) and not s:find('requested',1,true))
local original=string.color
string.color=function(value,id)return '['..id..']'..value end
assert(fmt.heading('Status')=='[140]=== [200]Status[140] ===')
assert(fmt.row('Mode','Ready')=='[207]  Mode: [0]Ready')
assert(fmt.notice('Saved')=='[200][XIVcrossbar] [207]Saved')
assert(fmt.notice('Restarting.',140)=='[200][XIVcrossbar] [140]Restarting.')
assert(fmt.state('ready')=='[158]Ready' and fmt.toggle(true)=='[158]ON')
assert(fmt.legacy(123,'[XIVCrossbar] Failed')=='[200][XIVcrossbar] [167]Failed')
assert(fmt.row('Position','//xb pos 1 2'):find('[200]//xb',1,true))
string.color=original
local alias={'l2','cross','Alias test','input /echo alias'}
assert(b:command(alias));assert(alias[1]=='l2','bank alias mutated caller arguments')
assert(b:entry('l1l2',6,false).Alias=='Alias test')
assert(b:command({'r2','hide'}) and not b:settings().R1R2.Visible)
lines={};b:summary('l1l2');local summary=table.concat(lines,'\n')
assert(summary:find('Draw in Menus:',1,true) and summary:find('Menu Input: ON',1,true) and summary:find('Bindings in Menus:',1,true))
print('Status feedback: single-line edits/swaps, explicit full bindings, stopped/neutral route truth and help palette passed.')
