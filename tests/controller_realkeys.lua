local m=require('libs/controller/realkeys')
local s={ControllerProfile='ps5-extended',ControllerMessages=true,GameplayDPad='ijkl',InputTest=false}
local saves=0;local lines={}
local function command(mode)return m.command(s,mode,function()saves=saves+1 end,function(v)lines[#lines+1]=v end)end
assert(not m.enabled(s,'session') and not command('status') and saves==0)
assert(command('on') and s.ControllerRealKeys and saves==1 and m.enabled(s,'session'))
assert(not command('on') and saves==1,'explicit on must be idempotent')
assert(not command('invalid') and saves==1 and s.ControllerRealKeys)
assert(not command('status') and saves==1)
for key,value in pairs({ControllerProfile='ps5-directinput',ControllerMessages=false,GameplayDPad='arrows',InputTest=true}) do
    local old=s[key];s[key]=value;assert(not m.enabled(s,'session'),key);s[key]=old
end
assert(not m.enabled(s,nil))
assert(command() and not s.ControllerRealKeys and saves==2)
assert(not command('off') and saves==2)
assert(command('ON') and command('off') and saves==4)
print('Real IJKL command: opt-in default, idempotent settings, invalid/status/toggle and profile/message/mapping/inputtest/token guards passed.')
