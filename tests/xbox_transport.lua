-- Profile capability and status are independent of the cosmetic button layout.
local profiles=require('libs/controller/profiles')
assert(profiles.validate('xbox',4)=='xinput-extended')
assert(not profiles.validate('xbox',5))
assert(profiles.validate('x',2)=='ps5-extended' and profiles.validate('xinput',1)=='xinput')
assert(profiles.is_extended('xinput-extended') and profiles.is_extended('ps5-extended'))
assert(not profiles.is_extended('xinput') and not profiles.is_extended('xinput-r1-chooser'))
local status=require('libs/chat_status').controller({status={running=true,profile='xinput-extended',device=1,
    button_route='messages',guide_touchpad='unavailable'},settings={ControllerProfile='xinput-extended',
    ControllerMessages=true,ControllerDevice=1},bridge={},modifier='apps'},true)
local report=table.concat(status,'\n')
assert(report:find('active messages | requested messages',1,true))
assert(report:find('touchpad unavailable',1,true))
print('Actual extended profile bounds and honest message/Guide status passed.')
