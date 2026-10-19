local profiles=require('libs/controller/profiles')
for _,name in ipairs({'x','X','ps5extended','ps5-extended'}) do
    local canonical,device=profiles.validate(name,2)
    assert(canonical=='ps5-extended' and device==2)
end
assert(profiles.validate('ps5',1)=='ps5-directinput')
assert(profiles.validate('xinput',1)=='xinput')
assert(profiles.short_name('ps5-extended')=='x')
assert(not profiles.validate('x',17))
for i=1,100 do assert(profiles.short_name('ps5-extended')=='x') end
print('x resolves deterministically to PS5 Extended; old aliases, PS5 base, XInput and device validation remain intact.')
