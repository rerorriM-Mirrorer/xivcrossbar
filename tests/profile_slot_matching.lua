local profiles=require('controller_profiles')
local status={running=true,profile='ps5-directinput',device='2',modifier='messages',state='ready',pid=10}
assert(profiles.matches(status,'ps5-directinput',2,'messages'))
assert(not profiles.matches(status,'ps5-directinput',1,'messages'),'Old readers retain device matching')
status.scan_mode='all-profile-slots'
assert(profiles.matches(status,'ps5-directinput',1,'messages'))
assert(profiles.matches(status,'ps5-directinput',16,'messages'))
assert(not profiles.matches(status,'xinput',1,'messages'),'Profile mapping remains exclusive')
assert(not profiles.matches(status,'ps5-directinput',1,'wrong'),'Protocol must still match')
local stops,starts,complete=0,0,false
local switch=require('controller_switch').new({clock=function()return 0 end,status=function()return status end,
 stop=function()stops=stops+1 end,start=function()starts=starts+1 end})
assert(switch:request('ps5-directinput',1,'messages',function(ok)complete=ok end))
assert(complete and stops==0 and starts==0,'Device-only selection must preserve all-slot reader')
status.running=false
assert(not profiles.matches(status,'ps5-directinput',1,'messages'),'Stopped readers cannot match')
print('All-slot reader matches every device number of its own profile; device-only changes retain process; legacy readers remain scoped.')
