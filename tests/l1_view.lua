local alive,created={},0
local function object()
    local o={};alive[o]=true;created=created+1
    return setmetatable(o,{__index=function(_,key)return function(self,...)
        assert(alive[self],'disposed surface reused')
        if key=='extents' then return 42,10 end
        if key=='destroy' then alive[self]=nil end
    end end})
end
local resources={text=object,image=object,clear=function(list)for _,o in ipairs(list)do o:destroy()end end}
local now=5;local settings={L1=require('l1_bank').defaults()}
local bank=require('l1_bank').new({settings=settings,clock=function()return now end})
local view=require('l1_view').new({bank=bank,resources=resources,path=''})
view:tick(true,960,540);assert(created==0,'hidden companion allocated surfaces')
bank:event('show');view:tick(true,960,540);local fixed=created
assert(fixed==26)
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
view:destroy();view:destroy();assert(next(alive)==nil)
bank.held=true;view:tick(true,960,540);assert(created==fixed*2)
view:destroy();assert(next(alive)==nil)
print('L1 companion: 26 fixed surfaces, 24 scale/resolution clamps, 300 reveal/hide cycles and idempotent teardown passed.')
