local now,saved=10,0
local sent,messages={},{}
local settings={L1=require('l1_bank').defaults()}
local bank=require('l1_bank').new({settings=settings,clock=function()return now end,
    save=function()saved=saved+1 end,execute=function(s)sent[#sent+1]=s end,
    say=function(s)messages[#messages+1]=s end,help=function()end})
assert(bank:mode()=='keyboard' and bank:opacity(true)==0)
bank:event('show');assert(bank:opacity(true)==1 and bank.held)
bank:event('slot',1);assert(#sent==0)
bank:event('release');now=12;assert(bank:opacity(true)==0)
bank:event('tap');assert(bank:mode()=='bank' and saved==1)
assert(bank:opacity(true)==1 and bank:opacity(false)==0)
assert(bank:command({'1','Hello','input','/echo','L1 one'}))
assert(bank:command({'append','1','input','/echo','L1 two'}))
assert(settings.L1.Slot1.Command=='input /echo "L1 one"; input /echo "L1 two"')
assert(require('l1_bank').command_text({'6','Heal','input','/ma','Cure III','<p1>'},3)=='input /ma "Cure III" <p1>')
assert(require('l1_bank').command_text({'6','Heal','input /ma "Cure III" <p1>'},3)=='input /ma "Cure III" <p1>')
bank:event('slot',1);assert(#sent==0,'must not execute without a fresh hold')
bank:event('show');bank:event('slot',1);assert(#sent==1 and sent[1]==settings.L1.Slot1.Command)
bank:event('slot',8);assert(#sent==1 and bank.empty==1)
bank:cancel();bank:event('slot',1);assert(#sent==1)
local count=saved
for _,args in ipairs({{'0','bad','echo'},{'9','bad','echo'},{'1.5','bad','echo'},
    {'clear','1','unexpected'},{'scale','nan'},{'scale','3'},{'pos','inf','0'},
    {'mode','unknown'},{'append','1'}}) do assert(bank:command(args)==false) end
assert(saved==count)
assert(bank:command({'clear','1'}));assert(settings.L1.Slot1.Alias=='' and settings.L1.Slot1.Command=='')
assert(bank:command({'mode','keyboard'}));assert(bank:mode()=='keyboard')
local other=require('l1_bank').new({settings=settings,clock=function()return now end})
assert(other:mode()=='keyboard' and other:settings().Slot1.Command=='')
bank:command({'preview'});assert(bank:opacity(true)==1)
bank:cancel();assert(bank:opacity(true)==0)
settings.L1.Scale=0/0;settings.L1.X=math.huge;settings.L1.Slot2='broken'
assert(bank:settings().Scale==.8 and bank:settings().X==24 and bank:settings().Slot2.Command=='')
print('L1 bank: modes, held-only dispatch, empty slots, command chains, invalid input, saved settings and visibility passed.')
