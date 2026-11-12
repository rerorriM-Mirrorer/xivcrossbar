local messages=require('controller_messages')
local delivered={}
local receiver=messages.new({session='extra',clock=function()return 10 end,wallclock=function()return 10 end,
    cancel=function()end,capture=function()end,event=function(down,pressed) delivered[#delivered+1]={down,pressed} end})
receiver:context('extended',true,true,true)
local function packet(body)return 'token='..receiver.token..'\nstamp=10\nbeat=10\n'..body..'END\n'end
assert(receiver:accept(packet('buttons=23\n1,down,18\n2,up,18\n3,down,20\n4,up,20\n')))
assert(delivered[1][1]==203 and delivered[3][1]==205 and not delivered[4][2])
assert(not receiver:accept(packet('buttons=23\n5,down,24\n')),'unknown extra rejected')
receiver:context('old',true,true,false)
assert(not receiver:accept(packet('buttons=23\n1,down,18\n')),'capability must be negotiated')
print('Extra controls: negotiated 23-button messages, touchpad/right-stick identities and bounds passed.')
