local now,saved=10,0
local sent,messages={},{}
local settings={L1=require('libs/banks/legacy').defaults()}
local bank=require('libs/banks/legacy').new({settings=settings,clock=function()return now end,
    save=function()saved=saved+1 end,execute=function(s)sent[#sent+1]=s end,
    say=function(s)messages[#messages+1]=s end,help=function()end})
assert(bank:mode()=='keyboard' and bank:opacity(true)==0)
bank:event('show');assert(bank:opacity(true)==1 and bank.held)
bank:event('slot',1);assert(#sent==0)
bank:event('release');assert(bank:opacity(true)==0)
bank:event('tap');assert(bank:mode()=='keyboard' and saved==0,'retired tap toggled mode')
bank:event('bank');assert(bank:mode()=='bank' and saved==0)
assert(bank:opacity(true)==1 and bank:opacity(false)==0)
bank:event('release');assert(bank:opacity(true)==0,'bank remained visible after release')
assert(bank:command({'1','Hello','input','/echo','L1 one'}))
assert(bank:command({'append','1','input','/echo','L1 two'}))
assert(settings.L1.Slot1.Command=='input /echo "L1 one"; input /echo "L1 two"')
assert(require('libs/banks/legacy').command_text({'6','Heal','input','/ma','Cure III','<p1>'},3)=='input /ma "Cure III" <p1>')
assert(require('libs/banks/legacy').command_text({'6','Heal','input /ma "Cure III" <p1>'},3)=='input /ma "Cure III" <p1>')
bank:event('slot',1);assert(#sent==0,'must not execute without a fresh hold')
bank:event('bank');bank:event('slot',1);assert(#sent==1 and sent[1]==settings.L1.Slot1.Command)
bank:event('slot',8);assert(#sent==1 and bank.empty==1)
bank:cancel();bank:event('slot',1);assert(#sent==1)
local count=saved
for _,args in ipairs({{'0','bad','echo'},{'9','bad','echo'},{'1.5','bad','echo'},
    {'clear','1','unexpected'},{'scale','nan'},{'scale','3'},{'pos','inf','0'},
    {'mode','unknown'},{'append','1'}}) do assert(bank:command(args)==false) end
assert(saved==count)
assert(bank:command({'clear','1'}));assert(settings.L1.Slot1.Alias=='' and settings.L1.Slot1.Command=='')
bank:event('show');assert(bank:mode()=='keyboard');bank:event('slot',1);assert(#sent==1)
assert(bank:command({'mode','keyboard'})==false,'retired mode command accepted')
bank:cancel()
local other=require('libs/banks/legacy').new({settings=settings,clock=function()return now end})
assert(other:mode()=='keyboard' and other:settings().Slot1.Command=='')
bank:command({'preview'});assert(bank:opacity(true)==1)
bank:cancel();assert(bank:opacity(true)==0)
settings.L1.Scale=0/0;settings.L1.X=math.huge;settings.L1.Slot2='broken'
assert(bank:settings().Scale==1 and bank:settings().X==24 and bank:settings().Slot2.Command=='')
assert(bank:command({'scale','0.8'}) and not settings.L1.FollowCrossbar)
assert(bank:command({'scale','crossbar'}) and settings.L1.FollowCrossbar)
print('L1 bank: momentary layers, retired toggle, held-only dispatch, command compatibility and scale following passed.')
