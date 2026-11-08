local bridge = require('controller_bridge')
local settings = require('defaults')
local now, sent, reports, saves = 10, {}, {}, 0
local function save() saves = saves+1 end
local menu = bridge.new(function() return now end,function(cmd) sent[#sent+1]=cmd end,
    function(msg) reports[#reports+1]=msg end)
assert(bridge.mode(settings,'movement')=='off')
bridge.command(settings,'all','test',save,function() end)
assert(saves==1 and bridge.mode(settings,'ps')=='test')
bridge.command(settings,'menu','on',save,function() end)
settings.InputTest=true
assert(bridge.mode(settings,'menu')=='test')
settings.InputTest=false

local path=os.tmpname()
local function lease(token,state,stamp,id)
    local f=assert(io.open(path,'wb'))
    f:write(('trust-menu1\n%d\n%s\n%s\n%.6f\nEND\n'):format(id or 7,token,state,stamp or now))
    f:close()
end
local buttons={button_layout='playstation',confirm_button='cross',cancel_button='circle'}
lease('token-1','navigation')
menu:update('test',path,7)
assert(menu:mask(buttons)==0)
assert(not menu:edge(59,true,buttons,false))
assert(#reports==1 and #sent==0 and reports[1]=='Would route up to Trust')
menu:edge(59,false,buttons,false)
menu:update('on',path,7)
assert(menu:mask(buttons)==95)
assert(menu:edge(63,true,buttons,true) and #sent==1 and sent[1]:match(' 1 .* confirm$'))
assert(menu:edge(63,false,buttons,true))
assert(not menu:edge(64,true,buttons,true))
assert(menu:edge(59,true,buttons,true))
now=10.41
lease('token-1','navigation');menu:update('on',path,7);menu:tick(true)
assert(#sent==3 and sent[3]:match(' 3 .* up$'))
menu:update('test',path,7);menu:tick(false)
assert(#sent==3 and menu:edge(59,false,buttons,false))
menu:update('on',path,7)
assert(menu:edge(65,true,buttons,true) and sent[4]:match(' 4 .* back$'))
now=11
menu:update('on',path,7)
assert(not menu.token and menu:mask(buttons)==0 and menu:edge(65,false,buttons,false))
lease('token-2','text')
now=11.1
menu:update('on',path,7)
assert(menu:edge(61,true,buttons,true) and #sent==4)
assert(menu:edge(63,true,buttons,true) and sent[5]:match('token%-2 1 .* confirm$'))
os.remove(path)
print('Bridge modes, dry-run routing, face mapping, stale leases, held ownership and text policy passed.')
