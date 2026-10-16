local alive,created,calls={},0,0
local measurement_ready=true
local function object()
    local o={};alive[o]=true;created=created+1
    return setmetatable(o,{__index=function(_,key)return function(self,...)
        assert(alive[self],'disposed surface reused')
        calls=calls+1
        if key=='extents' then return measurement_ready and 42 or 0,10 end
        if key=='destroy' then alive[self]=nil end
    end end})
end
local resources={text=object,image=object,clear=function(list)for _,o in ipairs(list)do o:destroy()end end}
local now=5;local settings={L1=require('l1_bank').defaults()}
local bank=require('l1_bank').new({settings=settings,clock=function()return now end})
local view=require('l1_view').new({bank=bank,resources=resources,path=''})
view:tick(true,960,540);assert(created==0,'hidden companion allocated surfaces')
bank:event('show');view:tick(true,960,540);local fixed=created
assert(fixed==42)
assert(view.slots[1].background and view.slots[1].frame)
assert(view:bounds().width==292*.8 and view:bounds().height==182*.8)
for _,res in ipairs({{960,540},{1280,720},{1600,900},{1920,1080},{2560,1440},{3840,2160}})do
    for _,scale in ipairs({.4,.8,1,2})do
        settings.L1.Scale=scale;settings.L1.X=10000;settings.L1.Y=-500
        view:tick(true,res[1],res[2]);local b=view:bounds()
        assert(b.x>=0 and b.y>=0 and b.x+b.width<=res[1] and b.y+b.height<=res[2])
    end
end
for i=1,300 do
    view:tick(false,960,540);view:tick(true,960,540)
    assert(created==fixed,'per-frame surfaces allocated')
end
local idle=calls
view:tick(true,960,540);view:tick(true,960,540)
assert(calls==idle,'static companion repeats native draw calls')
settings.L1.Mode='bank';view:tick(true,960,540);local before=calls
settings.L1.Slot1.Alias='New label';view:tick(true,960,540)
assert(calls>before,'alias edit did not invalidate render cache')
view:destroy();view:destroy();assert(next(alive)==nil)
measurement_ready=false
bank.held=true;view:tick(true,960,540);assert(created==fixed*2 and view.needs_measurement)
measurement_ready=true;view:tick(true,960,540);assert(not view.needs_measurement)
local settled=calls;view:tick(true,960,540);assert(calls==settled)
view:destroy();assert(next(alive)==nil)
print('L1 companion: 42 fixed slot/icon/frame/text surfaces, tighter compact geometry, 24 scale/resolution clamps, 300 reveal/hide cycles and idempotent teardown passed.')
